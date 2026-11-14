package com.syedarhamraza.dialer

import android.content.Context
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

/**
 * Settings › Export / Import settings: a zip of the app's settings (Flutter's preferences, the
 * native ones the call screen and screening service read) and the call background photos.
 */
object SettingsBackup {
    private const val MARKER = "one-dialer-settings"
    private const val VERSION = "1"

    // Settings only: not device_tier (this phone's GPU) or blocked_pending (this phone's call log).
    private val PREFS = setOf("app_language", "call_settings", "blocking", "quick_replies")
    private const val DATASTORE = "datastore/FlutterSharedPreferences.preferences_pb"
    private const val BACKGROUNDS = "call_bg"
    private const val MAX_BYTES = 64L shl 20

    fun export(context: Context, out: OutputStream) {
        ZipOutputStream(out).use { zip ->
            zip.putNextEntry(ZipEntry(MARKER))
            zip.write(VERSION.toByteArray())
            zip.closeEntry()
            for ((name, file) in sources(context)) {
                if (!file.isFile) continue
                zip.putNextEntry(ZipEntry(name))
                file.inputStream().use { it.copyTo(zip) }
                zip.closeEntry()
            }
        }
    }

    /**
     * Replaces the settings with [input]'s, read in full first. False (nothing changed) when it
     * isn't a settings file. The caller must restart the process: every preference is cached.
     */
    fun import(context: Context, input: InputStream): Boolean {
        val stage = File(context.cacheDir, "settings-import").apply { deleteRecursively(); mkdirs() }
        try {
            var marker = false
            var total = 0L
            val buffer = ByteArray(8192)
            ZipInputStream(input).use { zip ->
                while (true) {
                    val entry = zip.nextEntry ?: break
                    if (entry.isDirectory) continue
                    if (entry.name == MARKER) {
                        marker = true
                        continue
                    }
                    val target = targetOf(entry.name) ?: continue
                    val file = File(stage, target).apply { parentFile!!.mkdirs() }
                    file.outputStream().use { out ->
                        while (true) {
                            val n = zip.read(buffer)
                            if (n < 0) break
                            total += n
                            if (total > MAX_BYTES) throw IOException("settings file too large")
                            out.write(buffer, 0, n)
                        }
                    }
                }
            }
            if (!marker) return false
            for ((_, file) in sources(context)) file.delete()
            File(context.filesDir, BACKGROUNDS).deleteRecursively()
            stage.walkTopDown().filter { it.isFile }.forEach {
                it.copyTo(destination(context, it.relativeTo(stage).invariantSeparatorsPath), overwrite = true)
            }
            return true
        } finally {
            stage.deleteRecursively()
        }
    }

    /**
     * Where a zip entry goes ("files/..." or "shared_prefs/..."), or null for anything that isn't
     * ours: a name can never reach outside these files.
     */
    fun targetOf(name: String): String? {
        if (name == DATASTORE) return "files/$DATASTORE"
        val pref = name.removePrefix("shared_prefs/").removeSuffix(".xml")
        if (name == "shared_prefs/$pref.xml" && pref in PREFS) return name
        val photo = name.removePrefix("$BACKGROUNDS/")
        if (name.startsWith("$BACKGROUNDS/") && photo.matches(Regex("[A-Za-z0-9_-]+(\\.[A-Za-z0-9]+)?"))) {
            return "files/$BACKGROUNDS/$photo"
        }
        return null
    }

    private fun sources(context: Context): List<Pair<String, File>> {
        val prefs = File(context.applicationInfo.dataDir, "shared_prefs")
        val photos = File(context.filesDir, BACKGROUNDS).listFiles().orEmpty()
        return PREFS.map { "shared_prefs/$it.xml" to File(prefs, "$it.xml") } +
            (DATASTORE to File(context.filesDir, DATASTORE)) +
            photos.map { "$BACKGROUNDS/${it.name}" to it }
    }

    private fun destination(context: Context, target: String): File =
        if (target.startsWith("files/")) File(context.filesDir, target.removePrefix("files/"))
        else File(context.applicationInfo.dataDir, target)
}
