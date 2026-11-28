package com.syedarhamraza.dialer.telecom

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentValues
import android.content.Context
import android.provider.CallLog.Calls
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import com.syedarhamraza.dialer.AppLanguage
import com.syedarhamraza.dialer.MainActivity
import com.syedarhamraza.dialer.R
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * The private vault: contacts moved out of Android's contacts (so no other app sees them) and
 * their calls, moved out of Android's call log after each call. One AES-GCM file under a
 * Keystore key, in `noBackupFilesDir`: never in Android's backup or ours (`SettingsBackup`
 * copies shared prefs only). The key isn't bound to unlocking, so a ringing call can show the
 * name while the phone is locked; App lock and the vault page's own prompt guard the UI.
 *
 * Each contact keeps its vCard (written and read by Dart's flutter_contacts), plus its name and
 * numbers for lookups here.
 */
object Vault {
    private const val ALIAS = "one_dialer_vault"
    private const val FILE = "vault.bin"
    private const val CHANNEL = "missed_calls" // MissedCallNotifier's channel
    private const val MISSED_ID = 4

    /** The decrypted vault, read once; null until then. */
    private var doc: JSONObject? = null

    /** Number keys ([ContactsSource.numberKey]) → name. */
    private var names: Map<String, String> = emptyMap()

    // --- Storage --------------------------------------------------------------------------

    private fun file(context: Context) = AtomicFile(File(context.noBackupFilesDir, FILE))

    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    /**
     * The vault, read on first use. A file that can't be decrypted throws, and nothing is ever
     * written over it: losing the vault is the one thing this must never do.
     */
    @Synchronized
    private fun load(context: Context): JSONObject {
        doc?.let { return it }
        val atomic = file(context)
        val loaded = if (!atomic.baseFile.exists()) {
            JSONObject().put("contacts", JSONArray()).put("calls", JSONArray())
        } else {
            val bytes = atomic.readFully()
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, bytes, 0, 12))
            JSONObject(String(cipher.doFinal(bytes, 12, bytes.size - 12), Charsets.UTF_8))
        }
        doc = loaded
        index(loaded)
        return loaded
    }

    @Synchronized
    private fun save(context: Context, value: JSONObject) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val sealed = cipher.iv + cipher.doFinal(value.toString().toByteArray(Charsets.UTF_8))
        val atomic = file(context)
        val out = atomic.startWrite()
        try {
            out.write(sealed)
            atomic.finishWrite(out)
        } catch (e: Exception) {
            atomic.failWrite(out)
            throw e
        }
        doc = value
        index(value)
    }

    private fun index(value: JSONObject) {
        val map = mutableMapOf<String, String>()
        val contacts = value.getJSONArray("contacts")
        for (i in 0 until contacts.length()) {
            val contact = contacts.getJSONObject(i)
            val numbers = contact.getJSONArray("numbers")
            for (j in 0 until numbers.length()) {
                val key = ContactsSource.numberKey(numbers.getString(j))
                if (key.isNotEmpty()) map[key] = contact.optString("name")
            }
        }
        names = map
    }

    // --- Lookups ------------------------------------------------------------------------

    /** The vault contact's name for [number], or null; never throws (it runs while ringing). */
    fun nameFor(context: Context, number: String?): String? {
        if (number.isNullOrBlank()) return null
        runCatching { load(context) }.onFailure { return null }
        return names[ContactsSource.numberKey(number)]
    }

    /** Everything, for the vault page: `contacts` (id, name, numbers, vcard) and `calls`, newest first. */
    @Synchronized
    fun read(context: Context): Map<String, Any?> {
        val value = load(context)
        val contacts = value.getJSONArray("contacts")
        val calls = value.getJSONArray("calls")
        return mapOf(
            "contacts" to (0 until contacts.length()).map { i ->
                val c = contacts.getJSONObject(i)
                val numbers = c.getJSONArray("numbers")
                mapOf(
                    "id" to c.getString("id"),
                    "name" to c.optString("name"),
                    "numbers" to (0 until numbers.length()).map(numbers::getString),
                    "vcard" to c.getString("vcard"),
                )
            },
            "calls" to (0 until calls.length()).map { i ->
                val c = calls.getJSONObject(i)
                mapOf(
                    "number" to c.getString("number"),
                    "date" to c.getLong("date"),
                    "duration" to c.getLong("duration"),
                    "type" to c.getInt("type"),
                )
            }.sortedByDescending { it["date"] as Long },
        )
    }

    // --- Changes ------------------------------------------------------------------------

    /** Adds a contact; its calls already in the call log move in with it. Returns its id. */
    @Synchronized
    fun add(context: Context, name: String, numbers: List<String>, vcard: String): String {
        val value = JSONObject(load(context).toString()) // a copy: the cache only changes once saved
        val id = "v${System.currentTimeMillis()}"
        value.getJSONArray("contacts").put(
            JSONObject().put("id", id).put("name", name).put("numbers", JSONArray(numbers)).put("vcard", vcard),
        )
        save(context, value)
        sweepCallLog(context, all = true)
        return id
    }

    /**
     * Takes a contact out of the vault (after Dart saved it back to Android's contacts). Its
     * calls go back into the call log when [restoreCalls], else they're dropped with it.
     */
    @Synchronized
    fun remove(context: Context, id: String, restoreCalls: Boolean) {
        val value = JSONObject(load(context).toString())
        val contacts = value.getJSONArray("contacts")
        val index = (0 until contacts.length()).firstOrNull { contacts.getJSONObject(it).getString("id") == id } ?: return
        val numbers = contacts.getJSONObject(index).getJSONArray("numbers")
        contacts.remove(index)
        val keys = (0 until numbers.length()).map { ContactsSource.numberKey(numbers.getString(it)) }.filter { it.isNotEmpty() }.toSet()
        // A number another vault contact still has keeps its calls here.
        val stillHere = mutableSetOf<String>()
        for (i in 0 until contacts.length()) {
            val other = contacts.getJSONObject(i).getJSONArray("numbers")
            for (j in 0 until other.length()) stillHere += ContactsSource.numberKey(other.getString(j))
        }
        val leaving = keys - stillHere
        val calls = value.getJSONArray("calls")
        val kept = JSONArray()
        val out = mutableListOf<JSONObject>()
        for (i in 0 until calls.length()) {
            val call = calls.getJSONObject(i)
            if (ContactsSource.numberKey(call.getString("number")) in leaving) out += call else kept.put(call)
        }
        value.put("calls", kept)
        save(context, value)
        // After the save: a failed save leaves them in the vault rather than in both places.
        if (restoreCalls) out.forEach { restore(context, it) }
    }

    private fun restore(context: Context, call: JSONObject) {
        val values = ContentValues().apply {
            put(Calls.NUMBER, call.getString("number"))
            put(Calls.DATE, call.getLong("date"))
            put(Calls.DURATION, call.getLong("duration"))
            put(Calls.TYPE, call.getInt("type"))
            put(Calls.FEATURES, call.optInt("features"))
            call.optString("component").takeIf { it.isNotEmpty() }?.let { put(Calls.PHONE_ACCOUNT_COMPONENT_NAME, it) }
            call.optString("account").takeIf { it.isNotEmpty() }?.let { put(Calls.PHONE_ACCOUNT_ID, it) }
            put(Calls.NEW, 0)
            put(Calls.IS_READ, 1)
        }
        runCatching { context.contentResolver.insert(Calls.CONTENT_URI, values) }
    }

    /** The call log's highest `_ID` already swept (ids only grow), in `noBackupFilesDir`: another phone's log has other ids. */
    private fun markFile(context: Context) = File(context.noBackupFilesDir, "vault_swept")

    private var swept: Long? = null

    private fun sweptUpTo(context: Context): Long =
        swept ?: (runCatching { markFile(context).readText().trim().toLong() }.getOrDefault(0L)).also { swept = it }

    private fun markSwept(context: Context, id: Long) {
        if (id <= sweptUpTo(context)) return
        runCatching { markFile(context).writeText("$id") }
        swept = id
    }

    /** The call log's highest `_ID`, 0 when it's empty. */
    private fun newestId(context: Context): Long {
        val args = android.os.Bundle().apply {
            putStringArray(android.content.ContentResolver.QUERY_ARG_SORT_COLUMNS, arrayOf(Calls._ID))
            putInt(android.content.ContentResolver.QUERY_ARG_SORT_DIRECTION, android.content.ContentResolver.QUERY_SORT_DIRECTION_DESCENDING)
            putInt(android.content.ContentResolver.QUERY_ARG_LIMIT, 1)
        }
        return context.contentResolver.query(Calls.CONTENT_URI, arrayOf(Calls._ID), args, null)
            ?.use { c -> if (c.moveToFirst()) c.getLong(0) else 0L } ?: 0L
    }

    /**
     * Moves the call log's calls with vault numbers into the vault: copied and saved first, and
     * only then deleted from the call log. Runs where the blocked-call fix runs (reading the log,
     * the missed-call notification) and shortly after each call. Never throws.
     *
     * Only calls logged since the last sweep are read, and the vault is only decrypted when there
     * are some: a whole-log scan before every Recents read made it open seconds late. [all]
     * re-reads the whole log, for a number just added to the vault.
     */
    @Synchronized
    fun sweepCallLog(context: Context, all: Boolean = false) {
        runCatching {
            if (!file(context).baseFile.exists()) return
            val fresh = mutableListOf<JSONObject>()
            var newest = 0L
            context.contentResolver.query(
                Calls.CONTENT_URI,
                arrayOf(
                    Calls._ID, Calls.NUMBER, Calls.DATE, Calls.DURATION, Calls.TYPE, Calls.FEATURES,
                    Calls.PHONE_ACCOUNT_COMPONENT_NAME, Calls.PHONE_ACCOUNT_ID, Calls.NEW,
                ),
                "${Calls._ID} > ?", arrayOf("${if (all) 0 else sweptUpTo(context)}"), null,
            )?.use { c ->
                while (c.moveToNext()) {
                    newest = maxOf(newest, c.getLong(0))
                    fresh += JSONObject()
                        .put("id", c.getLong(0))
                        .put("number", c.getString(1).orEmpty())
                        .put("date", c.getLong(2))
                        .put("duration", c.getLong(3))
                        .put("type", c.getInt(4))
                        .put("features", c.getInt(5))
                        .put("component", c.getString(6).orEmpty())
                        .put("account", c.getString(7).orEmpty())
                        .put("new", c.getInt(8))
                }
            }
            if (fresh.isEmpty()) {
                // A wiped call log (cleared storage) numbers from 1 again: start over below the mark.
                if (!all && sweptUpTo(context) > 0 && newestId(context) < sweptUpTo(context)) {
                    runCatching { markFile(context).delete() }
                    swept = 0
                    sweepCallLog(context)
                }
                return
            }
            load(context)
            val rows = fresh.filter { isVaultNumber(names.keys, it.getString("number")) }
            if (rows.isEmpty()) return markSwept(context, newest)
            val value = JSONObject(load(context).toString())
            val calls = value.getJSONArray("calls")
            rows.forEach { row -> calls.put(JSONObject(row.toString()).apply { remove("id"); remove("new") }) }
            save(context, value)
            val ids = rows.joinToString(",") { it.getLong("id").toString() }
            context.contentResolver.delete(Calls.CONTENT_URI, "${Calls._ID} IN ($ids)", null)
            val missed = rows.count { it.getInt("type") == Calls.MISSED_TYPE && it.getInt("new") == 1 }
            if (missed > 0) notifyMissed(context, missed)
            // Only once they're out of the log: a failed move is tried again next time.
            markSwept(context, newest)
        }
    }

    /** True when [number]'s key is one of the vault's [keys]. */
    internal fun isVaultNumber(keys: Set<String>, number: String?): Boolean {
        if (number.isNullOrBlank()) return false
        val key = ContactsSource.numberKey(number)
        return key.isNotEmpty() && key in keys
    }

    /** "Missed call · Private contact": no name or number, even unlocked; tapping opens the app. */
    private fun notifyMissed(context: Context, count: Int) {
        val manager = context.getSystemService(NotificationManager::class.java)
        val res = AppLanguage.localized(context).resources
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, res.getString(R.string.channel_missed), NotificationManager.IMPORTANCE_DEFAULT),
        )
        val open = PendingIntent.getActivity(
            context, 5, android.content.Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        manager.notify(
            MISSED_ID,
            Notification.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_stat_missed_call)
                .setColor(0xFFD2463A.toInt())
                .setCategory(Notification.CATEGORY_MISSED_CALL)
                .setContentTitle(res.getString(R.string.missed_call))
                .setContentText(res.getString(R.string.private_contact))
                .setNumber(count)
                .setContentIntent(open)
                .setAutoCancel(true)
                .build(),
        )
    }
}
