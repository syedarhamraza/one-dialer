package com.syedarhamraza.dialer.telecom

import android.content.Context
import android.net.Uri
import android.provider.ContactsContract.PhoneLookup
import org.json.JSONArray

/** Settings › Call recording › Auto-record: which answered calls start recording by themselves. */
object RecordRules {
    /**
     * [mode] is `off`, `all`, `unknown` (no saved contact) or `contacts` (only [selected]).
     * A contact in [never] is never auto-recorded, whatever the mode.
     */
    fun shouldRecord(mode: String, contactId: String?, selected: Set<String>, never: Set<String>): Boolean {
        if (contactId != null && contactId in never) return false
        return when (mode) {
            "all" -> true
            "unknown" -> contactId == null
            "contacts" -> contactId != null && contactId in selected
            else -> false
        }
    }

    fun shouldRecord(context: Context, number: String?): Boolean {
        val prefs = CallPrefs.read(context)
        val mode = prefs["autoRecordMode"] as String
        if (mode == "off") return false
        return shouldRecord(mode, contactId(context, number), ids(prefs["recordContacts"]), ids(prefs["neverRecord"]))
    }

    private fun ids(json: Any?): Set<String> = try {
        JSONArray(json as String).let { a -> List(a.length()) { a.getString(it) }.toSet() }
    } catch (_: Exception) {
        emptySet()
    }

    /** The saved contact's id (the same id the Flutter side's contacts use), or null. */
    private fun contactId(context: Context, number: String?): String? {
        if (number.isNullOrBlank()) return null
        val uri = Uri.withAppendedPath(PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number))
        return try {
            context.contentResolver.query(uri, arrayOf(PhoneLookup.CONTACT_ID), null, null, null)?.use {
                if (it.moveToFirst()) it.getLong(0).toString() else null
            }
        } catch (_: SecurityException) {
            null // no contacts permission: everyone is unknown
        }
    }
}
