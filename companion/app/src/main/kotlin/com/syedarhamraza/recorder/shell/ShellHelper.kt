package com.syedarhamraza.recorder.shell

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.RemoteInput
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.provider.Settings
import com.syedarhamraza.recorder.R
import com.syedarhamraza.recorder.RecordingsProvider
import java.io.IOException
import java.io.InputStream
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.security.SecureRandom
import android.os.Looper
import kotlin.concurrent.thread

/**
 * One Recorder's side of the both-sides helper ([ShellMain]): whether it's running, starting it
 * over Wireless debugging, the pairing notification, and starting it again after a reboot.
 */
object ShellHelper {
    private const val PREFS = "shell"
    private const val PAIRED = "paired"
    private const val PORT = "port"
    private const val TOKEN = "token"
    private const val CHANNEL = "setup"
    private const val PAIR_NOTIFICATION = 2
    const val KEY_CODE = "code"
    private const val ADB_WIFI = "adb_wifi_enabled"

    /** Both sides needs Android 12+: shell's call capture works there without scrcpy's Android 11 workaround. */
    fun supported() = Build.VERSION.SDK_INT >= 31

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun paired(context: Context) = prefs(context).getBoolean(PAIRED, false)

    fun developerOptionsOn(context: Context) =
        Settings.Global.getInt(context.contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) == 1

    /** One Recorder can switch Wireless debugging on after a reboot (granted by the helper's first start). */
    fun canRestart(context: Context) =
        context.checkSelfPermission(Manifest.permission.WRITE_SECURE_SETTINGS) == PackageManager.PERMISSION_GRANTED

    /** Answers within a fraction of a second: a stopped helper refuses the connection at once. */
    fun running(context: Context): Boolean = offMain(false) {
        val (port, token) = endpoint(context) ?: return@offMain false
        try {
            connect(port).use { socket ->
                socket.soTimeout = 1000
                socket.getOutputStream().write("$token ping\n".toByteArray())
                socket.getInputStream().bufferedReader().readLine() == "ok"
            }
        } catch (_: IOException) {
            false
        }
    }

    /** The call's audio from both sides as raw PCM ([ShellMain.RATE], mono, 16-bit); null when the helper isn't running or can't record. */
    fun openPcm(context: Context): InputStream? = offMain(null) {
        val (port, token) = endpoint(context) ?: return@offMain null
        val socket = try { connect(port) } catch (_: IOException) { return@offMain null }
        try {
            socket.soTimeout = 3000 // the status byte
            socket.getOutputStream().write("$token pcm\n".toByteArray())
            val input = socket.getInputStream()
            if (input.read() != 1) {
                socket.close()
                return@offMain null
            }
            socket.soTimeout = 0
            input // closing it closes the socket, which ends the helper's recording
        } catch (_: IOException) {
            socket.close()
            null
        }
    }

    /**
     * Android refuses sockets on the main thread, even to 127.0.0.1; the setup screen and the
     * service's start ask from there, so these short loopback calls run on a thread it waits for.
     */
    private fun <T> offMain(fallback: T, block: () -> T): T {
        if (Looper.myLooper() != Looper.getMainLooper()) return block()
        var result = fallback
        thread { result = block() }.join(4000)
        return result
    }

    private fun connect(port: Int) = Socket().apply { connect(InetSocketAddress(InetAddress.getLoopbackAddress(), port), 500) }

    private fun endpoint(context: Context): Pair<Int, String>? {
        val prefs = prefs(context)
        val port = prefs.getInt(PORT, 0)
        val token = prefs.getString(TOKEN, null)
        return if (port > 0 && token != null) port to token else null
    }

    /**
     * Starts the helper over Wireless debugging. Switches Wireless debugging on first when it's off
     * and One Recorder may ([canRestart]), and back off afterwards if the helper survives that.
     * Blocks for up to about 20 s.
     */
    @Synchronized
    fun start(context: Context): Boolean {
        if (!supported() || !paired(context)) return false
        if (running(context)) return true
        val resolver = context.contentResolver
        val wasOn = Settings.Global.getInt(resolver, ADB_WIFI, 0) == 1
        val switched = !wasOn && canRestart(context) && runCatching { Settings.Global.putInt(resolver, ADB_WIFI, 1) }.isSuccess
        val adb = Adb.get(context)
        try {
            if (!adb.connectNow(context, 15_000)) return false
            // Lets One Recorder switch Wireless debugging on by itself after a reboot.
            adb.shell("pm grant ${context.packageName} ${Manifest.permission.WRITE_SECURE_SETTINGS}")
            val random = SecureRandom()
            val token = ByteArray(24).also(random::nextBytes).joinToString("") { "%02x".format(it) }
            val port = 20_000 + random.nextInt(40_000)
            prefs(context).edit().putInt(PORT, port).putString(TOKEN, token).commit()
            val apk = context.applicationInfo.sourceDir
            adb.shell(
                "CLASSPATH='$apk' nohup app_process /system/bin ${ShellMain::class.java.name} $port $token '$apk' " +
                    ">/dev/null 2>&1 &",
            )
            val up = waitUntilRunning(context)
            if (up && switched) {
                Settings.Global.putInt(resolver, ADB_WIFI, 0)
                // Some phones end everything Wireless debugging started when it goes off: then leave it on.
                Thread.sleep(1500)
                if (!running(context)) {
                    Settings.Global.putInt(resolver, ADB_WIFI, 1)
                    return start(context)
                }
            }
            return up
        } finally {
            adb.disconnectQuietly()
            RecordingsProvider.notifyStatus(context)
        }
    }

    private fun waitUntilRunning(context: Context): Boolean {
        repeat(20) {
            if (running(context)) return true
            Thread.sleep(250)
        }
        return false
    }

    /** Pairs with the code from Wireless debugging's pairing dialog (still open), then starts the helper. */
    fun pair(context: Context, code: String): Boolean {
        val service = Adb.findPairingService(context, 8000)
        val ok = service != null && Adb.get(context).pairWith(service.first, service.second, code.trim())
        if (ok) prefs(context).edit().putBoolean(PAIRED, true).commit()
        val started = ok && start(context)
        notifyPairing(context, if (started) R.string.pair_done else if (ok) R.string.pair_paired else R.string.pair_failed)
        return ok
    }

    /** After a reboot, an update or on reaching Wi-Fi: starts the helper again when One Recorder may. */
    fun restart(context: Context) {
        if (!supported() || !paired(context) || running(context)) return stopWaitingForWifi(context)
        if (!canRestart(context)) return
        if (!onWifi(context)) return waitForWifi(context)
        if (start(context)) stopWaitingForWifi(context)
    }

    private fun onWifi(context: Context): Boolean {
        val manager = context.getSystemService(ConnectivityManager::class.java)
        return manager.getNetworkCapabilities(manager.activeNetwork)?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
    }

    private fun wifiIntent(context: Context, flags: Int) = PendingIntent.getBroadcast(
        context, 1, Intent(context, ShellReceiver::class.java).setAction(ShellReceiver.ACTION_WIFI), flags,
    )

    /** The system wakes [ShellReceiver] when Wi-Fi connects, even with One Recorder not running. */
    private fun waitForWifi(context: Context) {
        val request = NetworkRequest.Builder().addTransportType(NetworkCapabilities.TRANSPORT_WIFI).build()
        context.getSystemService(ConnectivityManager::class.java)
            .registerNetworkCallback(request, wifiIntent(context, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE))
    }

    private fun stopWaitingForWifi(context: Context) {
        val pending = wifiIntent(context, PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_MUTABLE) ?: return
        runCatching { context.getSystemService(ConnectivityManager::class.java).releaseNetworkRequest(pending) }
        pending.cancel()
    }

    /** Posts the "enter the pairing code" notification, typed into without leaving Wireless debugging. */
    fun askForPairingCode(context: Context) {
        val reply = PendingIntent.getBroadcast(
            context, 2, Intent(context, ShellReceiver::class.java).setAction(ShellReceiver.ACTION_PAIR),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE, // RemoteInput fills in the code
        )
        val action = Notification.Action.Builder(null, context.getString(R.string.pair_enter), reply)
            .addRemoteInput(RemoteInput.Builder(KEY_CODE).setLabel(context.getString(R.string.pair_code)).build())
            .build()
        post(context, builder(context).setContentText(context.getString(R.string.pair_steps)).addAction(action).build())
    }

    private fun notifyPairing(context: Context, text: Int) =
        post(context, builder(context).setContentText(context.getString(text)).setAutoCancel(true).setTimeoutAfter(15_000).build())

    private fun builder(context: Context): Notification.Builder {
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(
            NotificationChannel(CHANNEL, context.getString(R.string.channel_setup), NotificationManager.IMPORTANCE_HIGH),
        )
        return Notification.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_record)
            .setContentTitle(context.getString(R.string.pair_title))
            .setStyle(Notification.BigTextStyle())
    }

    private fun post(context: Context, notification: Notification) =
        context.getSystemService(NotificationManager::class.java).notify(PAIR_NOTIFICATION, notification)

    /** Settings › Developer options, scrolled to Wireless debugging. */
    fun wirelessDebuggingIntent(): Intent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
        .putExtra(":settings:fragment_args_key", "toggle_adb_wireless")
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
}
