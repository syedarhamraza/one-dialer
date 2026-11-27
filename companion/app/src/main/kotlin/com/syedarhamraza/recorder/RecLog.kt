package com.syedarhamraza.recorder

import android.content.Context
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * One Recorder's log: every line goes to logcat and to a file in the app's own storage, so a
 * report still has the boot, the pairing and the failed call from days ago (logcat keeps
 * minutes, and some phones hide an app's lines from it). Two files of [MAX_BYTES] each; nothing
 * leaves the phone unless the user sends a report. Lines never carry numbers or names, and
 * [mask] hides any number that slips in.
 */
object RecLog {
    private const val TAG = "OneRecorder"
    private const val MAX_BYTES = 256 * 1024L
    @Volatile private var dir: File? = null

    /** Called first thing in every process start ([RecordingsProvider.onCreate]). */
    fun init(context: Context) {
        if (dir != null) return
        dir = logDir(context)
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, e ->
            runCatching { w("crash in ${thread.name}", e) }
            previous?.uncaughtException(thread, e)
        }
    }

    fun logDir(context: Context) = File(context.filesDir, "logs").apply { mkdirs() }

    fun i(message: String) {
        android.util.Log.i(TAG, message)
        write("I", message, null)
    }

    // Warn in logcat too: some phones (vivo) drop an app's info lines.
    fun w(message: String, e: Throwable? = null) {
        android.util.Log.w(TAG, message, e)
        write("W", message, e)
    }

    @Synchronized
    private fun write(level: String, message: String, e: Throwable?) {
        val dir = dir ?: return
        runCatching {
            val file = File(dir, "log.txt")
            if (file.length() > MAX_BYTES) file.renameTo(File(dir, "log.1.txt"))
            val stack = e?.let { "\n" + it.stackTraceToString().trimEnd() }.orEmpty()
            file.appendText("${stamp(System.currentTimeMillis())} $level ${mask(message + stack)}\n")
        }
    }

    /** Older file first, then the current one. */
    fun read(context: Context): String = listOf("log.1.txt", "log.txt")
        .map { File(logDir(context), it) }.filter { it.exists() }.joinToString("") { it.readText() }

    /** The helper's log as last fetched ([com.syedarhamraza.recorder.shell.ShellHelper.fetchHelperLog]). */
    fun helperFile(context: Context) = File(logDir(context), "helper.txt")

    fun clear(context: Context) = logDir(context).listFiles().orEmpty().forEach { it.delete() }

    fun stamp(at: Long): String = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date(at))

    private val NUMBER = Regex("""\+?\d[\d \-().]{4,}\d""")

    /** Hides anything shaped like a phone number (6 or more digits), keeping shorter ones like ports and sizes. */
    fun mask(text: String): String = NUMBER.replace(text) { m ->
        if (m.value.count(Char::isDigit) >= 6) "#".repeat(m.value.length) else m.value
    }
}
