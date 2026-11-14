package com.syedarhamraza.recorder

import android.content.Context
import android.media.MediaRecorder

/** The companion's own settings, also shown and changed from One Dialer › Settings › Call recording. */
object RecorderSettings {
    private const val PREFS = "recorder"

    /** Every setting with its default; One Dialer reads and writes these keys. */
    val DEFAULTS: Map<String, Any> = mapOf(
        "retentionDays" to 0, // 0 keeps recordings forever
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
        edit.apply()
    }

    private const val CONSENT = "consentAccepted"

    /** The first-run "Before you record" page was agreed to. Not in [DEFAULTS]: One Dialer doesn't change it. */
    fun consentAccepted(context: Context) = prefs(context).getBoolean(CONSENT, false)

    fun acceptConsent(context: Context) = prefs(context).edit().putBoolean(CONSENT, true).apply()

    private const val THEME = "theme"

    /** "system", "light" or "dark". Not in [DEFAULTS]: only the Recorder's own page shows it. */
    fun theme(context: Context) = prefs(context).getString(THEME, "system") ?: "system"

    fun setTheme(context: Context, theme: String) = prefs(context).edit().putString(THEME, theme).apply()
}
