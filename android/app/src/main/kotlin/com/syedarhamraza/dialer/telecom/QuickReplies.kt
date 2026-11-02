package com.syedarhamraza.dialer.telecom

import android.content.Context
import com.syedarhamraza.dialer.AppLanguage
import com.syedarhamraza.dialer.R
import org.json.JSONArray

/** "Decline with SMS" texts, editable in Settings. Native prefs so both Flutter engines see the same list. */
object QuickReplies {
    private const val FILE = "quick_replies"

    /** Android's default quick responses, in the app's language until the user edits the list. */
    private fun defaults(context: Context) =
        AppLanguage.localized(context).resources.getStringArray(R.array.quick_replies).toList()

    fun read(context: Context): List<String> {
        val raw = context.getSharedPreferences(FILE, Context.MODE_PRIVATE).getString("list", null)
            ?: return defaults(context)
        return runCatching { JSONArray(raw).let { a -> List(a.length()) { a.getString(it) } } }.getOrDefault(defaults(context))
    }

    fun write(context: Context, replies: List<String>) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE).edit()
            .putString("list", JSONArray(replies).toString()).apply()
    }
}
