package com.syedarhamraza.recorder

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import com.syedarhamraza.recorder.shell.ShellHelper
import java.io.File

/**
 * Records one call, both sides, from the shell helper ([ShellHelper]) while it runs as a
 * foreground service. Started and stopped by One Dialer through [RecordingsProvider]; never
 * exported itself.
 */
class RecordingService : Service() {
    companion object {
        private const val ACTION_STOP = "stop"
        private const val EXTRA_NUMBER = "number"
        private const val EXTRA_START = "startMillis"
        private const val CHANNEL = "recording"
        private const val NOTIFICATION_ID = 1
        private const val EXTRA_DIRECTION = "direction"
        private const val EXTRA_SIM = "simId"
        private const val CHECK_MS = 5000L
        private const val DAY_MS = 86_400_000L

        @Volatile var current: RecordingFile? = null
            private set

        /** Why the last start failed: "helper" (not running or won't record) or "start"; null after a good start. */
        @Volatile var lastError: String? = null
            private set

        fun dir(context: Context) = File(context.filesDir, "recordings").apply { mkdirs() }

        /** Auto-delete (Settings › Call recording): drops recordings older than the kept days, never starred ones. */
        fun prune(context: Context) {
            val days = RecorderSettings.read(context)["retentionDays"] as Int
            if (days <= 0) return
            val cutoff = System.currentTimeMillis() - days * DAY_MS
            val starred = RecordingIndex.starred(context)
            dir(context).listFiles().orEmpty().forEach { f ->
                val entry = RecordingFile.parse(f.name) ?: return@forEach
                if (entry.startMillis < cutoff && f.name !in starred && f.name != current?.name) f.delete()
            }
        }

        /** Whether a recording can start: the helper is up. */
        fun canRecord(context: Context) = ShellHelper.supported() && ShellHelper.running(context)

        fun start(context: Context, extras: android.os.Bundle?) {
            lastError = if (canRecord(context)) null else "helper"
            android.util.Log.i("OneRecorder", "start: error=$lastError")
            if (lastError != null) return RecordingsProvider.notifyStatus(context)
            context.startForegroundService(Intent(context, RecordingService::class.java).apply { extras?.let(::putExtras) })
        }

        fun stop(context: Context) {
            if (current != null) context.startService(Intent(context, RecordingService::class.java).setAction(ACTION_STOP))
        }
    }

    private var pipeline: AudioPipeline? = null
    private val handler = Handler(Looper.getMainLooper())
    private var idleChecks = 0

    // If One Dialer dies mid-call, nobody sends Stop: end once the phone has left the call.
    private val watchCall = object : Runnable {
        override fun run() {
            val mode = getSystemService(AudioManager::class.java).mode
            idleChecks = if (mode == AudioManager.MODE_IN_CALL || mode == AudioManager.MODE_IN_COMMUNICATION) 0 else idleChecks + 1
            if (idleChecks >= 2) finish() else handler.postDelayed(this, CHECK_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            finish()
            return START_NOT_STICKY
        }
        try {
            // The helper records, not this app's mic, so it's a special use, not a microphone service.
            if (Build.VERSION.SDK_INT >= 34) startForeground(NOTIFICATION_ID, notification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            else startForeground(NOTIFICATION_ID, notification())
        } catch (e: Exception) {
            android.util.Log.w("OneRecorder", "startForeground refused", e)
            lastError = "start"
            stopSelf()
            RecordingsProvider.notifyStatus(this)
            return START_NOT_STICKY
        }
        if (current == null) begin(intent)
        return START_NOT_STICKY
    }

    private fun begin(intent: Intent?) {
        val entry = RecordingFile.free(
            intent?.getLongExtra(EXTRA_START, 0L)?.takeIf { it > 0 } ?: System.currentTimeMillis(),
            intent?.getStringExtra(EXTRA_NUMBER),
        ) { File(dir(this), it).exists() }
        val target = File(dir(this), entry.name)
        pipeline = ShellHelper.openPcm(this)?.let { pcm -> AudioPipeline(target, pcm).also { it.start() } }
        android.util.Log.i("OneRecorder", "begin: recording=${pipeline != null}")
        if (pipeline == null) {
            lastError = "helper"
            finish()
            return
        }
        current = entry
        RecordingIndex.update(this, entry.name) {
            it.put("direction", intent?.getStringExtra(EXTRA_DIRECTION) ?: "")
            it.put("simId", intent?.getStringExtra(EXTRA_SIM) ?: "")
        }
        lastError = null
        idleChecks = 0
        handler.postDelayed(watchCall, CHECK_MS)
        RecordingsProvider.notifyStatus(this)
    }

    private fun finish() {
        handler.removeCallbacks(watchCall)
        pipeline?.stop()
        pipeline = null
        current = null
        prune(this)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        RecordingsProvider.notifyStatus(this)
    }

    override fun onDestroy() {
        if (pipeline != null) finish()
        super.onDestroy()
    }

    private fun notification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, getString(R.string.channel_recording), NotificationManager.IMPORTANCE_LOW),
        )
        val stop = PendingIntent.getService(
            this, 0, Intent(this, RecordingService::class.java).setAction(ACTION_STOP), PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_record)
            .setContentTitle(getString(R.string.recording_call))
            .setUsesChronometer(true)
            .setWhen(System.currentTimeMillis())
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .addAction(Notification.Action.Builder(null, getString(R.string.stop), stop).build())
            .build()
    }
}
