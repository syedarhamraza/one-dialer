package com.syedarhamraza.recorder

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.media.AudioManager
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import java.io.File

/**
 * Records one call from the mic while it runs as a microphone foreground service. Android 10+
 * only lets it hear the mic during a call because [RecorderAccessibilityService] is enabled.
 * Started and stopped by One Dialer through [RecordingsProvider]; never exported itself.
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

        /** Why the last start failed: "accessibility", "microphone" or "start"; null after a good start. */
        @Volatile var lastError: String? = null
            private set

        fun dir(context: Context) = File(context.filesDir, "recordings").apply { mkdirs() }

        fun micGranted(context: Context) =
            context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

        fun accessibilityOn(context: Context): Boolean {
            val me = ComponentName(context, RecorderAccessibilityService::class.java)
            // AccessibilityManager first: vivo hides the secure setting from apps, so it alone read as off.
            val running = context.getSystemService(android.view.accessibility.AccessibilityManager::class.java)
                .getEnabledAccessibilityServiceList(android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
                .any { ComponentName.unflattenFromString(it.id) == me }
            if (running) return true
            val enabled = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
                ?: return false
            return enabled.split(':').any { ComponentName.unflattenFromString(it) == me }
        }

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

        fun start(context: Context, extras: android.os.Bundle?) {
            lastError = when {
                !accessibilityOn(context) -> "accessibility"
                !micGranted(context) -> "microphone"
                else -> null
            }
            if (lastError != null) return RecordingsProvider.notifyStatus(context)
            context.startForegroundService(Intent(context, RecordingService::class.java).apply { extras?.let(::putExtras) })
        }

        fun stop(context: Context) {
            if (current != null) context.startService(Intent(context, RecordingService::class.java).setAction(ACTION_STOP))
        }
    }

    private var pipeline: AudioPipeline? = null
    private var recorder: MediaRecorder? = null
    private var file: File? = null
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
            startForeground(NOTIFICATION_ID, notification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
        } catch (e: Exception) {
            // Android 14+ refuses a microphone service started while nothing of ours or One Dialer's shows.
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
        val sources = RecorderSettings.sourcesToTry(this)
        pipeline = AudioPipeline(
            target, sources, Compressor.Level.of(RecorderSettings.read(this)["boost"] as String),
            onSourceChosen = { RecorderSettings.saveSource(this, it) },
            onSilent = { RecorderSettings.forgetSource(this) },
        ).takeIf { it.start() }
        // The plain MediaRecorder path, for phones where AudioRecord won't open during a call.
        if (pipeline == null) recorder = open(target, sources)
        if (pipeline == null && recorder == null) {
            lastError = "start"
            finish()
            return
        }
        file = target
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

    private fun open(target: File, sources: List<Int>): MediaRecorder? {
        for (source in sources) {
            val r = if (Build.VERSION.SDK_INT >= 31) MediaRecorder(this) else @Suppress("DEPRECATION") MediaRecorder()
            try {
                r.setAudioSource(source)
                r.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                r.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                r.setAudioChannels(1)
                r.setAudioSamplingRate(16000)
                r.setAudioEncodingBitRate(32000)
                r.setOutputFile(target.path)
                r.prepare()
                r.start()
                return r
            } catch (_: Exception) {
                r.release()
                target.delete()
            }
        }
        return null
    }

    private fun finish() {
        handler.removeCallbacks(watchCall)
        pipeline?.stop()
        pipeline = null
        recorder?.let {
            try {
                it.stop()
            } catch (_: RuntimeException) {
                file?.delete() // stopped before any audio was written
            }
            it.release()
        }
        recorder = null
        file = null
        current = null
        prune(this)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        RecordingsProvider.notifyStatus(this)
    }

    override fun onDestroy() {
        if (recorder != null || pipeline != null) finish()
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
