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
import android.util.Log
import com.syedarhamraza.recorder.R
import com.syedarhamraza.recorder.RecorderSettings
import com.syedarhamraza.recorder.RecordingsProvider
import java.io.IOException
import java.io.InputStream
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.security.SecureRandom
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
    private const val APK = "apk"
    private const val CHANNEL = "setup"
    private const val PAIR_NOTIFICATION = 2
    private const val STOPPED_NOTIFICATION = 3
    const val KEY_CODE = "code"
    const val ADB_WIFI = "adb_wifi_enabled"
    private const val DEV_OPTIONS = Settings.Global.DEVELOPMENT_SETTINGS_ENABLED

    /** Both sides needs Android 12+: shell's call capture works there without scrcpy's Android 11 workaround. */
    fun supported() = Build.VERSION.SDK_INT >= 31

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun paired(context: Context) = prefs(context).getBoolean(PAIRED, false)

    fun developerOptionsOn(context: Context) =
        Settings.Global.getInt(context.contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) == 1

    /** Why a start can't work: off Wi-Fi, or Wireless debugging off with no way to switch it on, else the connection itself. */
    enum class Problem { WIFI, DEBUGGING, CONNECT }

    fun problem(onWifi: Boolean, wirelessOn: Boolean, canSwitch: Boolean) = when {
        !onWifi -> Problem.WIFI
        !wirelessOn && !canSwitch -> Problem.DEBUGGING
        else -> Problem.CONNECT
    }

    /** What Setup tells after a failed start, read from the phone as it is now. */
    fun problem(context: Context) = problem(onWifi(context), wirelessOn(context), canRestart(context))

    /** The last [start] didn't bring the helper up; Setup then says why ([problem]). */
    @Volatile var startFailed = false
        private set

    fun wirelessOn(context: Context) = global(context, ADB_WIFI) == 1

    /** One Recorder can switch Wireless debugging on after a reboot (granted by the helper's first start). */
    fun canRestart(context: Context) =
        context.checkSelfPermission(Manifest.permission.WRITE_SECURE_SETTINGS) == PackageManager.PERMISSION_GRANTED

    /** Answers within a fraction of a second: a stopped helper refuses the connection at once. */
    fun running(context: Context): Boolean = ask(context, "ping")

    /**
     * The helper runs an older One Recorder: it quits once its APK is gone, but Android 17 keeps
     * an updated app's old APK while anything still has it open.
     */
    private fun stale(context: Context) = prefs(context).getString(APK, null) != context.applicationInfo.sourceDir

    /** One request to the helper ([ShellMain.Request]); true when it answered ok. */
    private fun ask(context: Context, request: String): Boolean = offMain(false) {
        val (port, token) = endpoint(context) ?: return@offMain false
        try {
            connect(port).use { socket ->
                socket.soTimeout = 3000
                socket.getOutputStream().write("$token $request\n".toByteArray())
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
     * Android refuses sockets on the main thread, even to 127.0.0.1, and a binder call carries the
     * caller's main-thread rule along (One Dialer asks for status from its main thread), so these
     * short loopback calls always run on a fresh thread this one waits for.
     */
    private fun <T> offMain(fallback: T, block: () -> T): T {
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

    private fun global(context: Context, key: String) = Settings.Global.getInt(context.contentResolver, key, 0)

    private fun putGlobal(context: Context, key: String, value: Int) =
        runCatching { Settings.Global.putInt(context.contentResolver, key, value) }.isSuccess

    /**
     * Developer options and debugging go off while the helper runs (Setup's switch, and the phone
     * allows it). Without WRITE_SECURE_SETTINGS (ColorOS refuses shell's pm grant unless Disable
     * system optimization is on) the running helper switches them instead.
     */
    fun hiding(context: Context) =
        RecorderSettings.hideDeveloperOptions(context) && !RecorderSettings.hideUnsupported(context) &&
            (canRestart(context) || running(context))

    /**
     * Starts the helper over Wireless debugging. Switches Wireless debugging on first when it's off
     * and One Recorder may ([canRestart]), and back off afterwards if the helper survives that
     * (all of debugging, while [hiding]). Blocks for up to about 20 s.
     */
    @Synchronized
    fun start(context: Context): Boolean {
        if (!supported() || !paired(context)) return false
        if (running(context)) {
            // Re-pairing turned debugging back on under a running helper: hide it again.
            if (!stale(context)) return !(hiding(context) && exposed(context)) || hideNow(context) || start(context)
            ask(context, "quit") // still the version before an update
        }
        // Developer options were turned off by us: some phones won't run Wireless debugging without them.
        if (hiding(context)) putGlobal(context, DEV_OPTIONS, 1)
        // Before the helper starts: switching USB debugging on may restart adbd.
        if (RecorderSettings.keepRecordingOffWifi(context) && canRestart(context)) putGlobal(context, Settings.Global.ADB_ENABLED, 1)
        val switched = global(context, ADB_WIFI) != 1 && canRestart(context) && putGlobal(context, ADB_WIFI, 1)
        val adb = Adb.get(context)
        val up = try {
            launch(context, adb)
        } finally {
            adb.disconnectQuietly()
        }
        // A failed start mustn't leave Developer options showing for banking apps to see (debugging stays as it was).
        if (!up && hiding(context)) putGlobal(context, DEV_OPTIONS, 0)
        val ok = up && settle(context, switched)
        startFailed = !ok
        if (ok) {
            // The helper ends with Wireless debugging when Wi-Fi goes: start it again when Wi-Fi is back.
            waitForWifi(context)
            context.getSystemService(NotificationManager::class.java).cancel(STOPPED_NOTIFICATION)
        }
        RecordingsProvider.notifyStatus(context)
        return ok
    }

    private fun launch(context: Context, adb: Adb): Boolean {
        // Wireless debugging that was just switched on may refuse a first try before adbd has its keys.
        val deadline = System.currentTimeMillis() + 30_000 // adbd restarted by a hiding step takes a while to advertise Wireless debugging again
        while (!adb.connectNow(context, 5_000)) {
            if (System.currentTimeMillis() > deadline) return false
            Thread.sleep(1000)
        }
        grant(context, adb)
        val random = SecureRandom()
        val token = ByteArray(24).also(random::nextBytes).joinToString("") { "%02x".format(it) }
        val port = 20_000 + random.nextInt(40_000)
        val apk = context.applicationInfo.sourceDir
        prefs(context).edit().putInt(PORT, port).putString(TOKEN, token).putString(APK, apk).commit()
        // adbd kills the shell's process group when a plain shell: command returns, before a
        // background job even starts: setsid moves the helper out, and the sleep lets it get there.
        adb.shell(
            "CLASSPATH='$apk' setsid app_process /system/bin ${ShellMain::class.java.name} $port $token '$apk' " +
                "</dev/null >/dev/null 2>&1 & sleep 1",
        )
        return waitUntilRunning(context)
    }

    /** Lets One Recorder switch Wireless debugging on by itself after a reboot. ColorOS refuses it until Disable system optimization is on. */
    private fun grant(context: Context, adb: Adb) {
        adb.shell("pm grant ${context.packageName} ${Manifest.permission.WRITE_SECURE_SETTINGS}")
    }

    /** Setup's "Start after a reboot" row, once the phone allows the grant: asks for it again over Wireless debugging. */
    @Synchronized
    fun grantAgain(context: Context): Boolean {
        val adb = Adb.get(context)
        try {
            if (adb.connectNow(context, 10_000)) grant(context, adb)
        } finally {
            adb.disconnectQuietly()
        }
        val granted = canRestart(context)
        // Now One Recorder may switch Wireless debugging back on, so all of debugging can go off.
        if (granted && hiding(context) && running(context)) hideNow(context)
        return granted
    }

    /** After a start: switches off what it switched on, or all of debugging while [hiding]. False only if the helper is gone. */
    private fun settle(context: Context, switchedWifi: Boolean): Boolean {
        if (hiding(context)) return hideNow(context) || start(context)
        if (!switchedWifi) return true
        putGlobal(context, ADB_WIFI, 0)
        // Some phones end everything Wireless debugging started when it goes off: then leave it on.
        Thread.sleep(1500)
        if (running(context)) return true
        putGlobal(context, ADB_WIFI, 1)
        return start(context)
    }

    /**
     * Turns Developer options, then USB debugging, then Wireless debugging off, so banking apps
     * that refuse them open, checking after each that the helper still answers. Some phones
     * restart adbd when one goes off, and where shell can't leave adbd's cgroup (Android 17's
     * cgroup v2 is system-only) that kills the helper: that switch is put back and stays on from
     * then on ([RecorderSettings.keepUsbDebugging], [RecorderSettings.keepWirelessDebugging]).
     * If even Developer options end it, stops hiding on this phone.
     */
    fun hideNow(context: Context): Boolean {
        // Only Developer options: with nothing to switch debugging back on, turning it off could end the helper for good.
        if (!canRestart(context)) return ask(context, "hide")
        if (!turnOff(context, DEV_OPTIONS)) {
            RecorderSettings.setHideUnsupported(context, true)
            return false
        }
        val keepUsb = RecorderSettings.keepUsbDebugging(context) || RecorderSettings.keepRecordingOffWifi(context)
        if (!keepUsb && !turnOff(context, Settings.Global.ADB_ENABLED)) {
            RecorderSettings.setKeepUsbDebugging(context, true)
            return false
        }
        if (!RecorderSettings.keepWirelessDebugging(context) && !turnOff(context, ADB_WIFI)) {
            RecorderSettings.setKeepWirelessDebugging(context, true)
            return false
        }
        return true
    }

    /** Something [hideNow] would turn off is on. */
    private fun exposed(context: Context) = global(context, DEV_OPTIONS) == 1 ||
        (!RecorderSettings.keepUsbDebugging(context) && global(context, Settings.Global.ADB_ENABLED) == 1) ||
        (!RecorderSettings.keepWirelessDebugging(context) && global(context, ADB_WIFI) == 1)

    /** Writes [key] = 0 and checks the helper survived it; if not, puts the old value back. */
    private fun turnOff(context: Context, key: String): Boolean {
        val was = global(context, key)
        putGlobal(context, key, 0)
        Thread.sleep(1500)
        val alive = running(context)
        Log.i("OneRecorder", "$key off: helper ${if (alive) "still running" else "ended, turning it back on"}")
        if (alive) return true
        putGlobal(context, key, was)
        return false
    }

    /**
     * Settings' Keep recording away from Wi-Fi: USB debugging keeps adbd, and so the helper,
     * running once Wi-Fi (and with it Wireless debugging) is gone. Switching it on may restart
     * adbd, so a helper that ends with it is started again.
     */
    fun keepUsbDebugging(context: Context, on: Boolean) {
        if (!on) {
            if (hiding(context) && running(context)) hideNow(context)
            return
        }
        if (!canRestart(context) || global(context, Settings.Global.ADB_ENABLED) == 1) return
        val wasRunning = running(context)
        putGlobal(context, Settings.Global.ADB_ENABLED, 1)
        Thread.sleep(1500)
        if (wasRunning && !running(context)) start(context)
    }

    /** Setup's Pair again: back to the pairing steps, keeping the key (pairing it again re-trusts it). */
    fun forgetPairing(context: Context) {
        showDeveloperOptions(context) // Wireless debugging lives there
        prefs(context).edit().putBoolean(PAIRED, false).commit()
        stopWaitingForWifi(context)
        RecordingsProvider.notifyStatus(context)
    }

    fun showDeveloperOptions(context: Context) = putGlobal(context, DEV_OPTIONS, 1) || ask(context, "show")

    /** After a start forced through [NoWifiStart], whose writes may have turned Wireless debugging back on. */
    fun settleForced(context: Context) {
        if (hiding(context)) hideNow(context) else putGlobal(context, ADB_WIFI, 0)
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

    /**
     * After a reboot, an update or on reaching Wi-Fi: starts the helper again when One Recorder
     * may, and keeps waiting for Wi-Fi while paired, since the helper ends whenever Wi-Fi goes.
     * When it can't start by itself, a notification takes the user to Setup.
     */
    fun restart(context: Context, fromBoot: Boolean = false) {
        if (!supported() || !paired(context)) return stopWaitingForWifi(context)
        if (running(context) && !stale(context)) return waitForWifi(context)
        if (!onWifi(context)) {
            // Only from boot or an update: Android allows a foreground service start from there.
            if (fromBoot && canRestart(context) && NoWifiStart.enabled(context)) NoWifiStart.Service.start(context)
            return waitForWifi(context)
        }
        // Without the grant only a Wireless debugging the user left on can start it.
        if ((canRestart(context) || wirelessOn(context)) && start(context)) return
        waitForWifi(context)
        notifyStopped(context)
    }

    private fun notifyStopped(context: Context) {
        val open = PendingIntent.getActivity(
            context, 3, Intent(context, com.syedarhamraza.recorder.SetupActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        context.getSystemService(NotificationManager::class.java).notify(STOPPED_NOTIFICATION, builder(context)
            .setContentTitle(context.getString(R.string.stopped_title))
            .setContentText(context.getString(R.string.stopped_detail))
            .setContentIntent(open).setAutoCancel(true).build())
    }

    fun onWifi(context: Context): Boolean {
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

    internal fun builder(context: Context): Notification.Builder {
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(
            NotificationChannel(CHANNEL, context.getString(R.string.channel_setup), NotificationManager.IMPORTANCE_HIGH),
        )
        return Notification.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_record)
            .setContentTitle(context.getString(R.string.pair_title))
            .setColor(com.syedarhamraza.recorder.OneLook.CALL_GREEN)
            .setStyle(Notification.BigTextStyle())
    }

    private fun post(context: Context, notification: Notification) =
        context.getSystemService(NotificationManager::class.java).notify(PAIR_NOTIFICATION, notification)

    /** Settings › Developer options, scrolled to Wireless debugging. */
    fun wirelessDebuggingIntent(): Intent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
        .putExtra(":settings:fragment_args_key", "toggle_adb_wireless")
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
}
