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
        private const val PREFS = "recorder"
        private const val CHECK_MS = 5000L

        // Mic sources a normal app may use, best first; the one that starts is kept per phone.
        private val SOURCES = listOf(
            MediaRecorder.AudioSource.VOICE_RECOGNITION,
            MediaRecorder.AudioSource.VOICE_COMMUNICATION,
            MediaRecorder.AudioSource.MIC,
        )

        @Volatile var current: RecordingFile? = null
            private set

        /** Why the last start failed: "accessibility", "microphone" or "start"; null after a good start. */
        @Volatile var lastError: String? = null
            private set

        fun dir(context: Context) = File(context.filesDir, "recordings").apply { mkdirs() }

        fun micGranted(context: Context) =
            context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

        fun accessibilityOn(context: Context): Boolean {
            val enabled = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
                ?: return false
            val me = ComponentName(context, RecorderAccessibilityService::class.java)
            return enabled.split(':').any { ComponentName.unflattenFromString(it) == me }
        }

        fun start(context: Context, number: String?, startMillis: Long) {
            lastError = when {
                !accessibilityOn(context) -> "accessibility"
                !micGranted(context) -> "microphone"
                else -> null
            }
            if (lastError != null) return RecordingsProvider.notifyStatus(context)
            context.startForegroundService(
                Intent(context, RecordingService::class.java).putExtra(EXTRA_NUMBER, number).putExtra(EXTRA_START, startMillis),
            )
        }

        fun stop(context: Context) {
            if (current != null) context.startService(Intent(context, RecordingService::class.java).setAction(ACTION_STOP))
        }
    }

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
        val entry = RecordingFile.of(
            intent?.getLongExtra(EXTRA_START, 0L)?.takeIf { it > 0 } ?: System.currentTimeMillis(),
            intent?.getStringExtra(EXTRA_NUMBER),
        )
        val target = File(dir(this), entry.name)
        recorder = open(target)
        if (recorder == null) {
            lastError = "start"
            finish()
            return
        }
        file = target
        current = entry
        lastError = null
        idleChecks = 0
        handler.postDelayed(watchCall, CHECK_MS)
        RecordingsProvider.notifyStatus(this)
    }

    private fun open(target: File): MediaRecorder? {
        val prefs = getSharedPreferences(PREFS, MODE_PRIVATE)
        val saved = prefs.getInt("source", -1)
        // shortcut: a source that starts but records silence stays saved; add a maxAmplitude check if phones show silent files.
        for (source in (listOf(saved) + SOURCES).filter { it >= 0 }.distinct()) {
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
                prefs.edit().putInt("source", source).apply()
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
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        RecordingsProvider.notifyStatus(this)
    }

    override fun onDestroy() {
        if (recorder != null) finish()
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
