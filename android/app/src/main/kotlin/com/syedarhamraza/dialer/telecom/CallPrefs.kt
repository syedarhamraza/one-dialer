package com.syedarhamraza.dialer.telecom

import android.content.Context
import android.media.AudioDeviceInfo
import android.telecom.Call

/**
 * Settings › Incoming call reminders and Answer/End calls, in plain SharedPreferences so
 * Telecom's callbacks can read them without Flutter.
 */
object CallPrefs {
    private const val FILE = "call_settings"

    /** Every setting with its default; the Dart side reads and writes these keys. */
    val DEFAULTS: Map<String, Any> = mapOf(
        "incomingStyle" to "banner", // or "full": the call screen opens while unlocked
        "vibrateAnswerEnd" to true,
        "speakerDefault" to false,
        "autoAnswer" to false,
        "autoAnswerDelay" to 5, // seconds
        "announceCalls" to "off", // "always", or "headset" (only with headphones)
    )

    fun read(context: Context): Map<String, Any> {
        val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
        return DEFAULTS.mapValues { (key, default) ->
            when (default) {
                is Boolean -> prefs.getBoolean(key, default)
                is Int -> prefs.getInt(key, default)
                else -> prefs.getString(key, default as String) ?: default
            }
        }
    }

    fun write(context: Context, key: String, value: Any?) {
        val edit = context.getSharedPreferences(FILE, Context.MODE_PRIVATE).edit()
        when (DEFAULTS[key]) {
            is Boolean -> edit.putBoolean(key, value == true)
            is Int -> edit.putInt(key, (value as? Number)?.toInt() ?: return)
            is String -> edit.putString(key, value as? String ?: return)
            else -> return
        }
        edit.apply()
    }

    /** "Vibrate when your calls are answered/ended": a call going live, or a live call ending. */
    fun buzzes(from: Int?, to: Int): Boolean = when (to) {
        Call.STATE_ACTIVE -> from != null && from != Call.STATE_ACTIVE && from != Call.STATE_HOLDING
        Call.STATE_DISCONNECTED -> from == Call.STATE_ACTIVE || from == Call.STATE_HOLDING
        else -> false
    }

    /** "Calls default to speaker" acts once, when a call first goes live (not coming off hold). */
    fun goesLive(from: Int?, to: Int): Boolean = buzzes(from, to) && to == Call.STATE_ACTIVE

    /** Earbuds, headphones or a car kit: what auto-answer counts as an external audio device. */
    fun isHeadset(type: Int): Boolean = type in HEADSETS

    private val HEADSETS = setOf(
        AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
        AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
        AudioDeviceInfo.TYPE_WIRED_HEADSET,
        AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
        AudioDeviceInfo.TYPE_USB_HEADSET,
        26, // AudioDeviceInfo.TYPE_BLE_HEADSET, API 31
    )
}
