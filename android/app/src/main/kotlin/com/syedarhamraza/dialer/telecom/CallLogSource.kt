package com.syedarhamraza.dialer.telecom

import android.content.ComponentName
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.CallLog.Calls
import android.telecom.TelecomManager

/** Reads and edits the system call log (needs READ/WRITE_CALL_LOG, granted with the dialer role). */
object CallLogSource {
    private const val LIMIT = 500

    private val PROJECTION = arrayOf(
        Calls._ID, Calls.NUMBER, Calls.CACHED_NAME, Calls.TYPE, Calls.DATE, Calls.DURATION,
        Calls.PHONE_ACCOUNT_COMPONENT_NAME, Calls.PHONE_ACCOUNT_ID, Calls.NUMBER_PRESENTATION, Calls.NEW, Calls.FEATURES,
    )

    /**
     * The call log including calls that VoIP apps (WhatsApp...) share with the default dialer:
     * a constant on Android 17, a query parameter on 16.1, nothing before.
     */
    private val readUri: Uri
        get() = when {
            Build.VERSION.SDK_INT >= 37 -> Calls.CONTENT_URI_WITH_VOIP_CALLS
            Build.VERSION.SDK_INT >= 36 && Build.VERSION.SDK_INT_FULL >= Build.VERSION_CODES_FULL.BAKLAVA_1 ->
                Calls.CONTENT_URI.buildUpon().appendQueryParameter("include_voip_calls", "true").build()
            else -> Calls.CONTENT_URI
        }

    /**
     * Ids of the ordinary call log. Android hides apps' shared calls from it, so a row of
     * [readUri] missing here is an app's call; every other row is left as it always was.
     */
    private fun ordinaryIds(context: Context): Set<Long> {
        val ids = mutableSetOf<Long>()
        context.contentResolver.query(Calls.CONTENT_URI, arrayOf(Calls._ID), null, null, null)
            ?.use { c -> while (c.moveToNext()) ids += c.getLong(0) }
        return ids
    }

    /**
     * Asks Telecom to call back a call-log row; for an app's row, that app places the call.
     * Telecom looks the row up by this URI, and plain `calls/<id>` hides apps' rows (Samsung
     * then dials it as an empty number), so it keeps [readUri]'s VoIP flag.
     */
    fun callBack(context: Context, id: Long) {
        context.getSystemService(TelecomManager::class.java)
            .placeCall(ContentUris.withAppendedId(readUri, id), Bundle())
    }

    private const val PENDING_FILE = "blocked_pending"

    /** Notes that we just blocked a call from [number] (blank for hidden callers). */
    fun rememberBlocked(context: Context, number: String) {
        context.getSharedPreferences(PENDING_FILE, Context.MODE_PRIVATE).edit()
            .putLong("${System.currentTimeMillis()}|$number", System.currentTimeMillis()).apply()
    }

    /**
     * Re-labels Telecom's "missed"/"rejected" entries for calls we blocked as blocked calls,
     * so they leave Recents and the missed-call count. Notes older than a day are dropped.
     */
    fun fixBlocked(context: Context) {
        val prefs = context.getSharedPreferences(PENDING_FILE, Context.MODE_PRIVATE)
        val pending = prefs.all.keys.toList()
        if (pending.isEmpty()) return
        val edit = prefs.edit()
        val now = System.currentTimeMillis()
        val values = ContentValues().apply {
            put(Calls.TYPE, Calls.BLOCKED_TYPE)
            put(Calls.BLOCK_REASON, Calls.BLOCK_REASON_CALL_SCREENING_SERVICE)
            put(Calls.NEW, 0)
            put(Calls.IS_READ, 1)
        }
        for (key in pending) {
            val at = key.substringBefore('|').toLongOrNull() ?: continue
            val number = key.substringAfter('|')
            val window = "${Calls.DATE} BETWEEN ? AND ? AND ${Calls.TYPE} IN (${Calls.MISSED_TYPE}, ${Calls.REJECTED_TYPE})"
            val (where, args) = if (number.isBlank()) {
                "$window AND ${Calls.NUMBER_PRESENTATION} != ${Calls.PRESENTATION_ALLOWED}" to arrayOf("${at - 10_000}", "${at + 60_000}")
            } else {
                "$window AND ${Calls.NUMBER} = ?" to arrayOf("${at - 10_000}", "${at + 60_000}", number)
            }
            val fixed = runCatching { context.contentResolver.update(Calls.CONTENT_URI, values, where, args) }.getOrDefault(0)
            if (fixed > 0 || now - at > 86_400_000) edit.remove(key)
        }
        edit.apply()
    }

    /** Newest first. `simId` matches the ids `CallBridge.getSims` returns. */
    fun query(context: Context): List<Map<String, Any?>> {
        fixBlocked(context)
        val args = Bundle().apply {
            putStringArray(android.content.ContentResolver.QUERY_ARG_SORT_COLUMNS, arrayOf(Calls.DATE))
            putInt(
                android.content.ContentResolver.QUERY_ARG_SORT_DIRECTION,
                android.content.ContentResolver.QUERY_SORT_DIRECTION_DESCENDING,
            )
            putInt(android.content.ContentResolver.QUERY_ARG_LIMIT, LIMIT)
        }
        val rows = mutableListOf<Map<String, Any?>>()
        val uri = readUri
        val ordinary = if (uri == Calls.CONTENT_URI) null else ordinaryIds(context)
        val labels = mutableMapOf<String, String?>()
        context.contentResolver.query(uri, PROJECTION, args, null)?.use { c ->
            while (c.moveToNext()) {
                val component = c.getString(6)
                val accountId = c.getString(7)
                val pkg = component?.takeIf { ordinary != null && c.getLong(0) !in ordinary }
                    ?.let { ComponentName.unflattenFromString(it)?.packageName }
                val app = pkg?.let { p ->
                    labels.getOrPut(p) {
                        runCatching {
                            val pm = context.packageManager
                            pm.getApplicationLabel(pm.getApplicationInfo(p, 0)).toString()
                        }.getOrNull()
                    }
                }
                rows += mapOf(
                    "id" to c.getLong(0),
                    "number" to c.getString(1).orEmpty(),
                    "name" to c.getString(2),
                    "type" to typeName(c.getInt(3)),
                    "date" to c.getLong(4),
                    "duration" to c.getLong(5),
                    "simId" to if (component != null && accountId != null) "$component|$accountId" else null,
                    "presentation" to presentationName(c.getInt(8)),
                    "isNew" to (c.getInt(9) == 1),
                    "video" to (c.getInt(10) and Calls.FEATURES_VIDEO != 0),
                    // FEATURES_HD_CALL (API 30) and FEATURES_VOLTE (API 31) by value: minSdk is 29, and
                    // older phones just never set the bits.
                    "hd" to (c.getInt(10) and 0x4 != 0),
                    "volte" to (c.getInt(10) and 0x40 != 0),
                    // Uninstalled apps keep the package name as their label.
                    "appPackage" to pkg,
                    "app" to (app ?: pkg),
                )
            }
        }
        return rows
    }

    fun delete(context: Context, ids: List<Long>) {
        if (ids.isEmpty()) return
        val placeholders = ids.joinToString(",") { "?" }
        context.contentResolver.delete(
            Calls.CONTENT_URI, "${Calls._ID} IN ($placeholders)", ids.map(Long::toString).toTypedArray(),
        )
    }

    /** Marks missed calls as seen, like opening Recents does in Samsung's dialer. */
    fun markMissedRead(context: Context) {
        val values = ContentValues().apply {
            put(Calls.NEW, 0)
            put(Calls.IS_READ, 1)
        }
        context.contentResolver.update(
            Calls.CONTENT_URI, values, "${Calls.TYPE} = ? AND ${Calls.NEW} = 1", arrayOf(Calls.MISSED_TYPE.toString()),
        )
    }

    /** Unseen missed calls, newest first: (number, cached name) pairs. */
    fun unseenMissed(context: Context): List<Triple<String, String?, Long>> {
        fixBlocked(context)
        val out = mutableListOf<Triple<String, String?, Long>>()
        context.contentResolver.query(
            readUri,
            arrayOf(Calls.NUMBER, Calls.CACHED_NAME, Calls.DATE),
            "${Calls.TYPE} = ? AND ${Calls.NEW} = 1",
            arrayOf(Calls.MISSED_TYPE.toString()),
            "${Calls.DATE} DESC",
        )?.use { c -> while (c.moveToNext()) out += Triple(c.getString(0).orEmpty(), c.getString(1), c.getLong(2)) }
        return out
    }

    private fun typeName(type: Int) = when (type) {
        Calls.INCOMING_TYPE -> "incoming"
        Calls.OUTGOING_TYPE -> "outgoing"
        Calls.MISSED_TYPE -> "missed"
        Calls.VOICEMAIL_TYPE -> "voicemail"
        Calls.REJECTED_TYPE -> "rejected"
        Calls.BLOCKED_TYPE -> "blocked"
        Calls.ANSWERED_EXTERNALLY_TYPE -> "answeredExternally"
        else -> "unknown"
    }

    private fun presentationName(p: Int) = when (p) {
        Calls.PRESENTATION_ALLOWED -> "allowed"
        Calls.PRESENTATION_RESTRICTED -> "private"
        Calls.PRESENTATION_PAYPHONE -> "payphone"
        else -> "unknown"
    }
}
