package com.syedarhamraza.recorder

import android.content.Context
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/**
 * Setup's Software update: One Recorder isn't on Play, so new versions come from the latest
 * GitHub release's recorder APK (`.github/workflows/release.yml`), installed by the helper
 * ([com.syedarhamraza.recorder.shell.ShellHelper.install]). Every network call blocks.
 */
object Updates {
    private const val API = "https://api.github.com/repos/syedarhamraza/one-dialer/releases/latest"
    private const val ASSET = "one-dialer-recorder.apk"
    private const val PREFS = "updates"
    private const val CHECKED = "checkedAt"
    private const val VERSION = "version"
    private const val URL_KEY = "url"
    private const val EVERY_MS = 6 * 3_600_000L
    private const val MAX_BYTES = 100L * 1024 * 1024

    class Release(val version: String, val url: String)

    /** "1.0.1-beta.1 (5b2133f)" or "1.0.1-beta.1-debug (5b2133f+)" → "1.0.1-beta.1". */
    fun base(versionName: String) = versionName.substringBefore(' ').removeSuffix("-debug")

    /** Semantic versions: 1.0.1-beta.2 < 1.0.1-beta.10 < 1.0.1 < 1.0.2. */
    fun newer(remote: String, local: String): Boolean = compare(remote, local) > 0

    private fun compare(a: String, b: String): Int {
        val (aMain, aPre) = a.split('-', limit = 2).let { it[0] to it.getOrNull(1) }
        val (bMain, bPre) = b.split('-', limit = 2).let { it[0] to it.getOrNull(1) }
        val main = compareParts(aMain.split('.'), bMain.split('.'))
        if (main != 0) return main
        return when {
            aPre == bPre -> 0
            aPre == null -> 1 // a release is newer than its betas
            bPre == null -> -1
            else -> compareParts(aPre.split('.'), bPre.split('.'))
        }
    }

    private fun compareParts(a: List<String>, b: List<String>): Int {
        for (i in 0 until maxOf(a.size, b.size)) {
            val x = a.getOrNull(i) ?: return -1
            val y = b.getOrNull(i) ?: return 1
            val c = when {
                x.toIntOrNull() != null && y.toIntOrNull() != null -> x.toInt().compareTo(y.toInt())
                else -> x.compareTo(y)
            }
            if (c != 0) return c
        }
        return 0
    }

    /** Debug builds are signed with the debug key and can't update to a release one. */
    fun enabled() = !BuildConfig.DEBUG

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** The last check's newer release, if any. */
    fun available(context: Context): Release? {
        val prefs = prefs(context)
        val version = prefs.getString(VERSION, null) ?: return null
        val url = prefs.getString(URL_KEY, null) ?: return null
        return Release(version, url).takeIf { newer(version, base(BuildConfig.VERSION_NAME)) }
    }

    fun due(context: Context) = System.currentTimeMillis() - prefs(context).getLong(CHECKED, 0) > EVERY_MS

    /** Asks GitHub for the latest release; false when it couldn't be reached. */
    fun check(context: Context): Boolean = runCatching {
        val json = JSONObject(get(API).use { it.bufferedReader().readText() })
        val assets = json.getJSONArray("assets")
        val url = (0 until assets.length()).map(assets::getJSONObject)
            .firstOrNull { it.optString("name") == ASSET }?.getString("browser_download_url")
        prefs(context).edit().putLong(CHECKED, System.currentTimeMillis())
            .putString(VERSION, json.getString("tag_name").removePrefix("v")).putString(URL_KEY, url).apply()
        true
    }.getOrElse {
        RecLog.w("update check failed", it)
        false
    }

    /** Downloads [release]'s APK into the cache; null if that failed. Android checks its signature on install. */
    fun download(context: Context, release: Release): File? = runCatching {
        val file = File(context.cacheDir, "update.apk")
        get(release.url).use { input ->
            file.outputStream().use { out ->
                val buffer = ByteArray(64 * 1024)
                var total = 0L
                while (true) {
                    val n = input.read(buffer)
                    if (n < 0) break
                    total += n
                    check(total <= MAX_BYTES) { "too big" }
                    out.write(buffer, 0, n)
                }
            }
        }
        file
    }.getOrElse {
        RecLog.w("update download failed", it)
        null
    }

    private fun get(url: String) = (URL(url).openConnection() as HttpURLConnection).run {
        connectTimeout = 10_000
        readTimeout = 30_000
        setRequestProperty("Accept", if (url == API) "application/vnd.github+json" else "application/octet-stream")
        inputStream
    }
}
