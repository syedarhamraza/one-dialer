package com.syedarhamraza.recorder

import android.content.Context
import android.media.MediaRecorder

/** The companion's own settings, also shown and changed from One Dialer › Settings › Call recording. */
object RecorderSettings {
    private const val PREFS = "recorder"

    /** Every setting with its default; One Dialer reads and writes these keys. */
    val DEFAULTS: Map<String, Any> = mapOf(
        "sourceMode" to "auto", // or "recognition", "communication", "mic"
        "boost" to "off", // Compressor.Level: off, normal, strong
        "retentionDays" to 0, // 0 keeps recordings forever
    )

    /** Mic sources a normal app may use, best guess first; Auto tests them on the first call. */
    val SOURCES = mapOf(
        "recognition" to MediaRecorder.AudioSource.VOICE_RECOGNITION,
        "communication" to MediaRecorder.AudioSource.VOICE_COMMUNICATION,
        "mic" to MediaRecorder.AudioSource.MIC,
    )

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun read(context: Context): Map<String, Any> {
        val prefs = prefs(context)
        return DEFAULTS.mapValues { (key, default) ->
            if (default is Int) prefs.getInt(key, default) else prefs.getString(key, default as String) ?: default
        }
    }

    fun write(context: Context, key: String, value: Any?) {
        val edit = prefs(context).edit()
        when (DEFAULTS[key]) {
            is Int -> edit.putInt(key, (value as? Number)?.toInt() ?: return)
            is String -> edit.putString(key, value as? String ?: return)
            else -> return
        }
        if (key == "sourceMode") edit.remove(SAVED_SOURCE) // a new choice starts fresh
        edit.apply()
    }

    private const val SAVED_SOURCE = "source"

    /** The sources to try at the start of a recording: one when known, all of them when Auto hasn't tested yet. */
    fun sourcesToTry(context: Context): List<Int> {
        val mode = read(context)["sourceMode"] as String
        SOURCES[mode]?.let { return listOf(it) }
        val saved = prefs(context).getInt(SAVED_SOURCE, -1)
        return if (saved >= 0) listOf(saved) else SOURCES.values.toList()
    }

    fun saveSource(context: Context, source: Int) = prefs(context).edit().putInt(SAVED_SOURCE, source).apply()

    /** The saved source recorded silence: test again on the next call. */
    fun forgetSource(context: Context) = prefs(context).edit().remove(SAVED_SOURCE).apply()
}
