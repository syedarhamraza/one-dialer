package com.syedarhamraza.dialer.telecom

import android.content.Context
import android.media.AudioManager
import android.net.Uri
import android.provider.ContactsContract.PhoneLookup
import org.json.JSONArray

/**
 * Settings › VIP calls: a VIP's call rings even on Silent or Vibrate. Telecom plays the ringtone
 * and skips it on Silent, so [onIncoming] (from the screening service, which Telecom waits on
 * before it rings) turns the ringer to Normal, and [restore] puts it back once nothing rings.
 * Leaving Silent needs Do Not Disturb access (Android treats it as a DND change).
 */
object VipRing {
    private const val FILE = "vip_ring"
    private const val RESTORE = "restore"

    /** A saved contact the user listed, or any favourite when [favourites] is on. */
    fun isVip(contactId: String?, starred: Boolean, listed: Set<String>, favourites: Boolean): Boolean =
        contactId != null && (contactId in listed || (favourites && starred))

    fun onIncoming(context: Context, number: String) {
        val prefs = CallPrefs.read(context)
        if (prefs["vipRing"] != true || number.isBlank()) return
        val (id, starred) = lookup(context, number) ?: return
        if (!isVip(id, starred, ids(prefs["vipContacts"]), prefs["vipFavourites"] == true)) return
        val audio = context.getSystemService(AudioManager::class.java)
        val mode = audio.ringerMode
        if (mode == AudioManager.RINGER_MODE_NORMAL) return
        val saved = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
        // No DND access: the call stays silent, and Settings' health check says why.
        runCatching { audio.ringerMode = AudioManager.RINGER_MODE_NORMAL }.onSuccess {
            // A second VIP call while the first rings keeps the user's own mode to go back to.
            if (!saved.contains(RESTORE)) saved.edit().putInt(RESTORE, mode).apply()
        }
    }

    /** Back to Silent/Vibrate after a VIP call stops ringing (answered, declined or missed). */
    fun restore(context: Context) {
        val saved = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
        if (!saved.contains(RESTORE)) return
        val mode = saved.getInt(RESTORE, AudioManager.RINGER_MODE_NORMAL)
        runCatching { context.getSystemService(AudioManager::class.java).ringerMode = mode }
        saved.edit().remove(RESTORE).apply()
    }

    private fun ids(json: Any?): Set<String> = try {
        JSONArray(json as String).let { a -> List(a.length()) { a.getString(it) }.toSet() }
    } catch (_: Exception) {
        emptySet()
    }

    /** The saved contact's id (as the Flutter side's contacts) and whether it's a favourite. */
    private fun lookup(context: Context, number: String): Pair<String, Boolean>? = try {
        val uri = Uri.withAppendedPath(PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number))
        context.contentResolver.query(uri, arrayOf(PhoneLookup.CONTACT_ID, PhoneLookup.STARRED), null, null, null)?.use {
            if (it.moveToFirst()) it.getLong(0).toString() to (it.getInt(1) == 1) else null
        }
    } catch (_: SecurityException) {
        null
    }
}
