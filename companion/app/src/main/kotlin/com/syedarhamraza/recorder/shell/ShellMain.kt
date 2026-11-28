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
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
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
 * Its log is stderr, which [ShellHelper] points at [ShellHelper.HELPER_LOG]: no numbers or names.
 */
object ShellMain {
    const val RATE = 48_000
    private const val SHELL = "com.android.shell"
    private const val CHUNK_BYTES = 2048 // ~21 ms of 16-bit mono

    /** HIDE and SHOW switch Developer options for One Recorder where it couldn't be granted WRITE_SECURE_SETTINGS. */
    /** INSTALL takes One Recorder's own update (Setup › Software update), so it installs with no prompt. */
    /** LOG answers with the helper's own log file, for One Recorder's report. */
    enum class Request { PING, PCM, QUIT, HIDE, SHOW, INSTALL, LOG }

    private const val MAX_APK = 100L * 1024 * 1024

    /** `<token> ping|pcm|quit|hide|show|log`, or `<token> install <bytes>`: anything else, or a wrong token, is dropped. */
    fun parse(line: String?, token: String): Request? {
        val parts = line?.trim()?.split(' ') ?: return null
        if (parts.size !in 2..3 || !MessageDigest.isEqual(parts[0].toByteArray(), token.toByteArray())) return null
        if (parts.size == 3) return Request.INSTALL.takeIf { parts[1] == "install" && size(line) != null }
        return when (parts[1]) {
            "ping" -> Request.PING
            "pcm" -> Request.PCM
            "quit" -> Request.QUIT
            "hide" -> Request.HIDE
            "show" -> Request.SHOW
            "log" -> Request.LOG
            else -> null
        }
    }

    /** An install request's APK size. */
    fun size(line: String) = line.trim().split(' ').getOrNull(2)?.toLongOrNull()?.takeIf { it in 1..MAX_APK }

    @JvmStatic
    fun main(args: Array<String>) {
        val port = args.getOrNull(0)?.toIntOrNull() ?: return
        val token = args.getOrNull(1)?.takeIf { it.length >= 32 } ?: return
        val apk = args.getOrNull(2)?.let(::File) ?: return
        Thread.setDefaultUncaughtExceptionHandler { _, e ->
            log("crash: ${e.stackTraceToString()}")
            exitProcess(1)
        }
        log("started: Android ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT}), pid ${Process.myPid()}")
        leaveAdbdCgroup()
        val server = try {
            ServerSocket(port, 4, InetAddress.getLoopbackAddress())
        } catch (e: IOException) {
            log("port taken: $e")
            return // One Recorder picks another and starts it again
        }
        thread(isDaemon = true) {
            while (apk.exists()) Thread.sleep(10_000)
            log("quit: One Recorder was updated or removed")
            exitProcess(0)
        }
        val context = shellContext()
        if (context == null) log("no shell context: recording uses the plain audio path")
        while (true) {
            val socket = try { server.accept() } catch (_: IOException) { continue }
            // After an update the old APK is gone: quit now, so One Recorder's ping fails and it starts the new one.
            if (!apk.exists()) {
                log("quit: APK gone")
                exitProcess(0)
            }
            thread { serve(socket, token, context) }
        }
    }

    /**
     * When Developer options, USB or Wireless debugging go off, init stops adbd and kills every
     * process in its cgroup; setsid doesn't change the cgroup, so the helper moves to the root
     * ones (as Shizuku's starter does). Paths a phone lacks or refuses are skipped.
     */
    private fun leaveAdbdCgroup() {
        val pid = Process.myPid().toString()
        for (group in listOf("/acct", "/sys/fs/cgroup", "/dev/cg2_bpf", "/dev/memcg/apps")) {
            runCatching { File(group, "cgroup.procs").writeText(pid) }
        }
    }

    private fun serve(socket: Socket, token: String, context: Context?) = socket.use {
        it.soTimeout = 2000 // for the request line only
        val line = readLine(it)
        val request = parse(line, token)
        if (request == null) log("refused a request")
        when (request) {
            Request.INSTALL -> install(it, size(line!!)!!)
            Request.PING -> it.getOutputStream().write("ok\n".toByteArray())
            Request.PCM -> {
                it.soTimeout = 0
                stream(it, context)
            }
            Request.QUIT -> log("quit: asked to").also { exitProcess(0) }
            // Debugging stays on: some phones restart adbd when it goes off, which would end the helper.
            Request.HIDE -> if (settings("development_settings_enabled", 0)) ok(it)
            Request.SHOW -> if (settings("development_settings_enabled", 1)) ok(it)
            Request.LOG -> it.getOutputStream().write(runCatching { File(LOG_PATH).readBytes() }.getOrDefault(ByteArray(0)))
            null -> {}
        }
    }

    /** Where ShellHelper sends stderr; read back for Request.LOG. */
    const val LOG_PATH = "/data/local/tmp/one-recorder.log"

    private fun log(message: String) =
        System.err.println("${SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())} H $message")

    private fun ok(socket: Socket) = socket.getOutputStream().write("ok\n".toByteArray())

    /**
     * `pm install` from the socket, as shell: no install prompt. Android only lets it replace One
     * Recorder with an APK signed by the same key. Installing ends One Recorder's process, so it
     * rarely reads the ok; the new version starts the helper again (MY_PACKAGE_REPLACED).
     */
    private fun install(socket: Socket, size: Long) {
        socket.soTimeout = 30_000
        val pm = try {
            ProcessBuilder("/system/bin/pm", "install", "-r", "-S", size.toString()).redirectErrorStream(true).start()
        } catch (e: IOException) {
            log("install: pm didn't start: $e")
            return
        }
        try {
            pm.outputStream.use { out ->
                val input = socket.getInputStream()
                val buffer = ByteArray(64 * 1024)
                var left = size
                while (left > 0) {
                    val n = input.read(buffer, 0, minOf(buffer.size.toLong(), left).toInt())
                    if (n < 0) throw IOException("short")
                    out.write(buffer, 0, n)
                    left -= n
                }
            }
            val result = pm.inputStream.bufferedReader().readText()
            val done = pm.waitFor() == 0 && "Success" in result
            log("install: ${if (done) "done" else result.trim().take(200)}")
            if (done) ok(socket)
        } catch (e: IOException) {
            log("install failed: $e")
            pm.destroy()
        }
    }

    /** Shell holds WRITE_SECURE_SETTINGS; `settings` runs as this process's uid. */
    private fun settings(key: String, value: Int) = runCatching {
        ProcessBuilder("/system/bin/settings", "put", "global", key, value.toString()).start().waitFor() == 0
    }.getOrDefault(false)

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
            log("recording refused")
            out.write(0)
            return
        }
        try {
            out.write(1)
            log("recording")
            val buffer = ByteArray(CHUNK_BYTES)
            while (true) {
                val n = record.read(buffer, 0, buffer.size)
                if (n < 0) {
                    log("audio read error $n")
                    break
                }
                if (n > 0) out.write(buffer, 0, n)
            }
        } catch (_: IOException) {
            // One Recorder closed the connection: the recording is over.
        } finally {
            log("recording ended")
            runCatching { record.stop() }
            record.release()
        }
    }

    @SuppressLint("MissingPermission") // the shell user holds RECORD_AUDIO and CAPTURE_AUDIO_OUTPUT
    private fun open(context: Context?): AudioRecord? {
        val min = AudioRecord.getMinBufferSize(RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        if (min <= 0) return log("no buffer size: $min").let { null }
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
        } catch (e: Exception) {
            return log("AudioRecord refused: $e").let { null }
        }
        if (record.state != AudioRecord.STATE_INITIALIZED) return log("AudioRecord not initialized").let { record.release(); null }
        try {
            record.startRecording()
        } catch (e: Exception) {
            return log("startRecording refused: $e").let { record.release(); null }
        }
        if (record.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
            return log("not recording (state ${record.recordingState}): another app may hold the call audio").let { record.release(); null }
        }
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
    }.onFailure { log("shell context: $it") }.getOrNull()

    private class ShellContext(base: Context) : ContextWrapper(base) {
        override fun getPackageName() = SHELL
        override fun getOpPackageName() = SHELL
        override fun getApplicationContext(): Context = this

        // Only Android 12+ asks for it, and the helper only runs there (ShellHelper.supported).
        @SuppressLint("NewApi")
        override fun getAttributionSource(): AttributionSource =
            AttributionSource.Builder(Process.myUid()).setPackageName(SHELL).build()
    }
}
