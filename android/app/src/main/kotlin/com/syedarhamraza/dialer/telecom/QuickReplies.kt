package com.syedarhamraza.dialer.telecom

import android.content.Context
import org.json.JSONArray

/** "Decline with message" texts, editable in Settings. Native prefs so both Flutter engines see the same list. */
object QuickReplies {
    private const val FILE = "quick_replies"

    /** Android's default quick responses. */
    private val DEFAULTS = listOf(
        "Can't talk now. What's up?",
        "I'll call you right back.",
        "I'll call you later.",
        "Can't talk now. Call me later?",
    )

    fun read(context: Context): List<String> {
        val raw = context.getSharedPreferences(FILE, Context.MODE_PRIVATE).getString("list", null) ?: return DEFAULTS
        return runCatching { JSONArray(raw).let { a -> List(a.length()) { a.getString(it) } } }.getOrDefault(DEFAULTS)
    }

    fun write(context: Context, replies: List<String>) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE).edit()
            .putString("list", JSONArray(replies).toString()).apply()
    }
}
