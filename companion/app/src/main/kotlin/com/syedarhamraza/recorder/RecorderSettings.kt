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

    private const val HIDE_DEV = "hideDeveloperOptions"
    private const val HIDE_UNSUPPORTED = "hideUnsupported"
    private const val NO_WIFI = "startWithoutWifi"
    private const val KEEP_WIRELESS = "keepWirelessDebugging"
    private const val KEEP_USB = "keepUsbDebugging"
    private const val OFF_WIFI = "keepRecordingOffWifi"

    /** This phone ends the helper when USB debugging goes off, so hiding leaves it on. */
    fun keepUsbDebugging(context: Context) = prefs(context).getBoolean(KEEP_USB, false)

    fun setKeepUsbDebugging(context: Context, value: Boolean) = prefs(context).edit().putBoolean(KEEP_USB, value).apply()

    /** This phone ends the helper when Wireless debugging goes off, so hiding leaves it on. */
    fun keepWirelessDebugging(context: Context) = prefs(context).getBoolean(KEEP_WIRELESS, false)

    fun setKeepWirelessDebugging(context: Context, value: Boolean) = prefs(context).edit().putBoolean(KEEP_WIRELESS, value).apply()

    /** Setup's Keep recording away from Wi-Fi: USB debugging stays on so the helper outlives Wi-Fi. Off by default. */
    fun keepRecordingOffWifi(context: Context) = prefs(context).getBoolean(OFF_WIFI, false)

    fun setKeepRecordingOffWifi(context: Context, on: Boolean) = prefs(context).edit().putBoolean(OFF_WIFI, on).apply()

    /** Turn Developer options, USB and Wireless debugging off once the helper runs, for banking apps. */
    fun hideDeveloperOptions(context: Context) = prefs(context).getBoolean(HIDE_DEV, true)

    fun setHideDeveloperOptions(context: Context, on: Boolean) = prefs(context).edit().putBoolean(HIDE_DEV, on).apply()

    /** This phone ended the helper when debugging went off, so hiding is skipped here. */
    fun hideUnsupported(context: Context) = prefs(context).getBoolean(HIDE_UNSUPPORTED, false)

    fun setHideUnsupported(context: Context, value: Boolean) = prefs(context).edit().putBoolean(HIDE_UNSUPPORTED, value).apply()

    /** Experimental: after a reboot away from Wi-Fi, force Wireless debugging on over a local-only hotspot. */
    fun startWithoutWifi(context: Context) = prefs(context).getBoolean(NO_WIFI, false)

    fun setStartWithoutWifi(context: Context, on: Boolean) = prefs(context).edit().putBoolean(NO_WIFI, on).apply()
}
