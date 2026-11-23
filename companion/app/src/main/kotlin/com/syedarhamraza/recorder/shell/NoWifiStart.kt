package com.syedarhamraza.recorder.shell

import android.Manifest
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import com.syedarhamraza.recorder.R
import com.syedarhamraza.recorder.RecorderSettings
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

/**
 * Experimental (Setup › Start without Wi-Fi): starts the helper after a reboot away from Wi-Fi.
 *
 * Without a Wi-Fi network Android starts adbd's wireless server when `adb_wifi_enabled` changes,
 * then stops it again; writing it back every 20 ms sometimes lands in that gap and it stays up
 * (Shizuku Next's ForcedWirelessDebugging, after thedjchi/Shizuku issue 165). mDNS still needs an
 * interface to find the port, so a local-only hotspot is open for the length of the attempt.
 * Best-effort, Android 12–16 only: Android 17's adbd won't run its wireless server offline at all.
 */
object NoWifiStart {
    private const val WINDOW_MS = 120_000L
    private const val INTERVAL_MS = 20L
    private const val NOTIFICATION = 3

    fun supported() = Build.VERSION.SDK_INT in 31..36

    fun enabled(context: Context) = supported() && RecorderSettings.startWithoutWifi(context)

    /** What the local-only hotspot needs, asked for when the switch is turned on. */
    fun permissions(): Array<String> =
        if (Build.VERSION.SDK_INT >= 33) arrayOf(Manifest.permission.NEARBY_WIFI_DEVICES)
        else arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)

    fun hasPermissions(context: Context) =
        permissions().all { context.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED }

    /** Blocks for up to about two minutes. */
    private fun run(context: Context): Boolean {
        val hotspot = openHotspot(context)
        val done = AtomicBoolean(false)
        val resolver = context.contentResolver
        // Reads before it writes: a write of the same value doesn't reach adbd anyway.
        val nudger = thread {
            while (!done.get()) {
                if (Settings.Global.getInt(resolver, ShellHelper.ADB_WIFI, 0) != 1) {
                    runCatching { Settings.Global.putInt(resolver, ShellHelper.ADB_WIFI, 1) }
                }
                Thread.sleep(INTERVAL_MS)
            }
        }
        try {
            val deadline = System.currentTimeMillis() + WINDOW_MS
            while (System.currentTimeMillis() < deadline) {
                if (ShellHelper.start(context)) return true
            }
            return false
        } finally {
            done.set(true)
            nudger.join()
            hotspot?.close()
            if (ShellHelper.running(context)) ShellHelper.settleForced(context)
        }
    }

    @Suppress("MissingPermission") // checked by hasPermissions
    private fun openHotspot(context: Context): WifiManager.LocalOnlyHotspotReservation? {
        if (!hasPermissions(context)) return null
        var reservation: WifiManager.LocalOnlyHotspotReservation? = null
        val latch = CountDownLatch(1)
        runCatching {
            context.getSystemService(WifiManager::class.java).startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
                override fun onStarted(r: WifiManager.LocalOnlyHotspotReservation) {
                    reservation = r
                    latch.countDown()
                }

                override fun onFailed(reason: Int) = latch.countDown()
            }, Handler(Looper.getMainLooper()))
        }.onFailure { return null }
        latch.await(12, TimeUnit.SECONDS)
        return reservation
    }

    /** Holds the attempt in the foreground: a broadcast gets about 10 s, this takes up to two minutes. */
    class Service : android.app.Service() {
        companion object {
            private val busy = AtomicBoolean(false)

            fun start(context: Context) {
                runCatching { context.startForegroundService(Intent(context, Service::class.java)) }
            }
        }

        override fun onBind(intent: Intent?): IBinder? = null

        override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
            val notification = ShellHelper.builder(this).setContentText(getString(R.string.no_wifi_starting)).build()
            try {
                if (Build.VERSION.SDK_INT >= 34) startForeground(NOTIFICATION, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
                else startForeground(NOTIFICATION, notification)
            } catch (_: Exception) {
                stopSelf()
                return START_NOT_STICKY
            }
            if (busy.compareAndSet(false, true)) thread {
                try {
                    run(applicationContext)
                } finally {
                    busy.set(false)
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
            }
            return START_NOT_STICKY
        }
    }
}
