package com.syedarhamraza.recorder.shell

import android.annotation.SuppressLint
import android.app.Application
import android.content.AttributionSource
import android.content.Context
import android.content.ContextWrapper
import android.content.pm.ApplicationInfo
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.Looper
import android.os.Process
import java.io.File
import java.io.IOException
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.security.MessageDigest
import kotlin.concurrent.thread
import kotlin.system.exitProcess

/**
 * The both-sides helper. [Adb.launchHelper] starts it as Android's shell user (uid 2000) over
 * Wireless debugging, from One Recorder's own APK:
 *
 *     CLASSPATH=<base.apk> app_process /system/bin com.syedarhamraza.recorder.shell.ShellMain <port> <token> <base.apk>
 *
 * Shell may record [MediaRecorder.AudioSource.VOICE_CALL] (both sides, straight from the call),
 * which installed apps can't. That's all it does: on 127.0.0.1:<port>, a connection that opens
 * with the secret token gets the call's raw PCM, and nothing else is understood. It exits when
 * One Recorder is uninstalled or updated (the APK it runs from goes away).
 *
 * Runs outside any app, so it may only use framework classes and the Kotlin standard library.
 */
object ShellMain {
    const val RATE = 48_000
    private const val SHELL = "com.android.shell"
    private const val CHUNK_BYTES = 2048 // ~21 ms of 16-bit mono

    enum class Request { PING, PCM, QUIT }

    /** `<token> ping|pcm|quit`: the only lines the helper answers; anything else, or a wrong token, is dropped. */
    fun parse(line: String?, token: String): Request? {
        val parts = line?.trim()?.split(' ') ?: return null
        if (parts.size != 2 || !MessageDigest.isEqual(parts[0].toByteArray(), token.toByteArray())) return null
        return when (parts[1]) {
            "ping" -> Request.PING
            "pcm" -> Request.PCM
            "quit" -> Request.QUIT
            else -> null
        }
    }

    @JvmStatic
    fun main(args: Array<String>) {
        val port = args.getOrNull(0)?.toIntOrNull() ?: return
        val token = args.getOrNull(1)?.takeIf { it.length >= 32 } ?: return
        val apk = args.getOrNull(2)?.let(::File) ?: return
        val server = try {
            ServerSocket(port, 4, InetAddress.getLoopbackAddress())
        } catch (_: IOException) {
            return // the port is taken: One Recorder picks another and starts it again
        }
        thread(isDaemon = true) {
            while (apk.exists()) Thread.sleep(10_000)
            exitProcess(0)
        }
        val context = shellContext()
        while (true) {
            val socket = try { server.accept() } catch (_: IOException) { continue }
            thread { serve(socket, token, context) }
        }
    }

    private fun serve(socket: Socket, token: String, context: Context?) = socket.use {
        it.soTimeout = 2000 // for the request line only
        when (parse(readLine(it), token)) {
            Request.PING -> it.getOutputStream().write("ok\n".toByteArray())
            Request.PCM -> {
                it.soTimeout = 0
                stream(it, context)
            }
            Request.QUIT -> exitProcess(0)
            null -> {}
        }
    }

    private fun readLine(socket: Socket): String? = try {
        val input = socket.getInputStream()
        val line = StringBuilder()
        while (line.length < 256) {
            val b = input.read()
            if (b < 0 || b == '\n'.code) break
            line.append(b.toChar())
        }
        line.toString()
    } catch (_: IOException) {
        null
    }

    /** One status byte (1 recording, 0 refused), then 48 kHz 16-bit mono little-endian PCM until One Recorder hangs up. */
    private fun stream(socket: Socket, context: Context?) {
        val out = socket.getOutputStream()
        val record = open(context)
        if (record == null) {
            out.write(0)
            return
        }
        try {
            out.write(1)
            val buffer = ByteArray(CHUNK_BYTES)
            while (true) {
                val n = record.read(buffer, 0, buffer.size)
                if (n < 0) break
                if (n > 0) out.write(buffer, 0, n)
            }
        } catch (_: IOException) {
            // One Recorder closed the connection: the recording is over.
        } finally {
            runCatching { record.stop() }
            record.release()
        }
    }

    @SuppressLint("MissingPermission") // the shell user holds RECORD_AUDIO and CAPTURE_AUDIO_OUTPUT
    private fun open(context: Context?): AudioRecord? {
        val min = AudioRecord.getMinBufferSize(RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        if (min <= 0) return null
        val record = try {
            AudioRecord.Builder()
                .setAudioSource(MediaRecorder.AudioSource.VOICE_CALL)
                .setAudioFormat(
                    AudioFormat.Builder().setSampleRate(RATE).setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT).build(),
                )
                .setBufferSizeInBytes(maxOf(min, CHUNK_BYTES * 4))
                .apply { if (context != null && Build.VERSION.SDK_INT >= 31) setContext(context) }
                .build()
        } catch (_: Exception) {
            return null
        }
        if (record.state != AudioRecord.STATE_INITIALIZED) return record.release().let { null }
        try {
            record.startRecording()
        } catch (_: Exception) {
            return record.release().let { null }
        }
        if (record.recordingState != AudioRecord.RECORDSTATE_RECORDING) return record.release().let { null }
        return record
    }

    /**
     * A context that says it's the shell app, so the audio system attributes the recording to
     * com.android.shell (whose uid this is). Adapted from scrcpy's FakeContext and Workarounds
     * (Apache-2.0, github.com/Genymobile/scrcpy), which record audio from app_process the same way.
     */
    @SuppressLint("PrivateApi", "DiscouragedPrivateApi")
    private fun shellContext(): Context? = runCatching {
        Looper.prepareMainLooper()
        val activityThreadClass = Class.forName("android.app.ActivityThread")
        val activityThread = activityThreadClass.getDeclaredConstructor().apply { isAccessible = true }.newInstance()
        activityThreadClass.getDeclaredField("sCurrentActivityThread").apply { isAccessible = true }.set(null, activityThread)
        // Some audio policy paths read the current app's ApplicationInfo.
        runCatching {
            val bindClass = Class.forName("android.app.ActivityThread\$AppBindData")
            val bind = bindClass.getDeclaredConstructor().apply { isAccessible = true }.newInstance()
            bindClass.getDeclaredField("appInfo").apply { isAccessible = true }.set(bind, ApplicationInfo().apply { packageName = SHELL })
            activityThreadClass.getDeclaredField("mBoundApplication").apply { isAccessible = true }.set(activityThread, bind)
        }
        val system = activityThreadClass.getDeclaredMethod("getSystemContext").invoke(activityThread) as Context
        val shell = ShellContext(system)
        runCatching {
            val app = Application()
            ContextWrapper::class.java.getDeclaredMethod("attachBaseContext", Context::class.java)
                .apply { isAccessible = true }.invoke(app, shell)
            activityThreadClass.getDeclaredField("mInitialApplication").apply { isAccessible = true }.set(activityThread, app)
        }
        shell
    }.getOrNull()

    private class ShellContext(base: Context) : ContextWrapper(base) {
        override fun getPackageName() = SHELL
        override fun getOpPackageName() = SHELL
        override fun getApplicationContext(): Context = this

        override fun getAttributionSource(): AttributionSource =
            AttributionSource.Builder(Process.myUid()).setPackageName(SHELL).build()
    }
}
