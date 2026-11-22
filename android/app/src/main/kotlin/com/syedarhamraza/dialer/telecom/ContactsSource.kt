package com.syedarhamraza.dialer.telecom

import android.content.ContentValues
import android.content.Context
import android.provider.ContactsContract
import android.provider.ContactsContract.CommonDataKinds.Phone
import android.provider.ContactsContract.CommonDataKinds.StructuredName
import android.provider.ContactsContract.Contacts
import android.provider.ContactsContract.Data
import android.provider.ContactsContract.RawContacts

/**
 * Every contact with its names, numbers and accounts, for `ContactsRepository`. Replaces
 * flutter_contacts' getAll, which encoded the whole list on Android's main thread and froze
 * both engines for seconds (after every call, and while ringing). Called on a background
 * task queue, so the query and the encoding both stay off the main thread.
 */
object ContactsSource {
    /** flutter_contacts' PhoneLabel names, so the Dart side reads them as it always did. */
    private val LABELS = mapOf(
        Phone.TYPE_ASSISTANT to "assistant", Phone.TYPE_CALLBACK to "callback", Phone.TYPE_CAR to "car",
        Phone.TYPE_COMPANY_MAIN to "companyMain", Phone.TYPE_FAX_HOME to "homeFax", Phone.TYPE_FAX_WORK to "workFax",
        Phone.TYPE_HOME to "home", Phone.TYPE_ISDN to "isdn", Phone.TYPE_MAIN to "main", Phone.TYPE_MMS to "mms",
        Phone.TYPE_MOBILE to "mobile", Phone.TYPE_OTHER to "other", Phone.TYPE_OTHER_FAX to "otherFax",
        Phone.TYPE_PAGER to "pager", Phone.TYPE_RADIO to "radio", Phone.TYPE_TELEX to "telex",
        Phone.TYPE_TTY_TDD to "ttyTdd", Phone.TYPE_WORK to "work", Phone.TYPE_WORK_MOBILE to "workMobile",
        Phone.TYPE_WORK_PAGER to "workPager",
    )

    fun phoneLabel(type: Int?): String = LABELS[type] ?: "custom"

    private class Row(val id: String, val name: String?, val starred: Boolean) {
        var first: String? = null
        var middle: String? = null
        var last: String? = null
        val phones = mutableListOf<List<Any?>>()

        /** Which of [phones] is the contact-wide default (Google Contacts', Android Auto's). */
        var superPrimary = -1
        val accounts = linkedSetOf<String>()
    }

    /** `[id, displayName, first, middle, last, starred, [[number, label, customLabel, isPrimary]], ["type|name"]]`, by name. */
    fun query(context: Context): List<List<Any?>> {
        val resolver = context.contentResolver
        val rows = LinkedHashMap<String, Row>()
        // The default directory is the set the system Contacts app (and flutter_contacts) shows.
        val contactsUri = Contacts.CONTENT_URI.buildUpon()
            .appendQueryParameter(ContactsContract.DIRECTORY_PARAM_KEY, ContactsContract.Directory.DEFAULT.toString())
            .build()
        resolver.query(
            contactsUri, arrayOf(Contacts._ID, Contacts.DISPLAY_NAME_PRIMARY, Contacts.STARRED),
            null, null, "${Contacts.DISPLAY_NAME_PRIMARY} COLLATE UNICODE ASC",
        )?.use { c ->
            while (c.moveToNext()) {
                val id = c.getLong(0).toString()
                rows[id] = Row(id, c.getString(1), c.getInt(2) != 0)
            }
        }
        if (rows.isEmpty()) return emptyList()

        resolver.query(
            Data.CONTENT_URI,
            arrayOf(
                Data.CONTACT_ID, Data.MIMETYPE, Phone.NUMBER, Phone.TYPE, Phone.LABEL, Data.IS_PRIMARY,
                StructuredName.GIVEN_NAME, StructuredName.MIDDLE_NAME, StructuredName.FAMILY_NAME, Data.IS_SUPER_PRIMARY,
            ),
            "${Data.MIMETYPE} IN (?, ?)", arrayOf(Phone.CONTENT_ITEM_TYPE, StructuredName.CONTENT_ITEM_TYPE),
            null,
        )?.use { c ->
            while (c.moveToNext()) {
                val row = rows[c.getLong(0).toString()] ?: continue
                if (c.getString(1) == Phone.CONTENT_ITEM_TYPE) {
                    val number = c.getString(2)?.takeIf { it.isNotBlank() } ?: continue
                    val type = if (c.isNull(3)) null else c.getInt(3)
                    val label = phoneLabel(type)
                    // Like flutter_contacts: the label text counts only for a custom type.
                    if (c.getInt(9) != 0) row.superPrimary = row.phones.size
                    row.phones += listOf(number, label, if (label == "custom") c.getString(4) else null, c.getInt(5) != 0)
                } else if (row.first == null && row.middle == null && row.last == null) {
                    // Both kinds share the dataN columns; each is read by its own projection index.
                    row.first = c.getString(6)
                    row.middle = c.getString(7)
                    row.last = c.getString(8)
                }
            }
        }

        resolver.query(
            RawContacts.CONTENT_URI, arrayOf(RawContacts.CONTACT_ID, RawContacts.ACCOUNT_TYPE, RawContacts.ACCOUNT_NAME),
            "${RawContacts.DELETED} = 0", null, null,
        )?.use { c ->
            while (c.moveToNext()) {
                val row = rows[c.getLong(0).toString()] ?: continue
                val type = c.getString(1)
                val name = c.getString(2)
                if (!type.isNullOrEmpty() && !name.isNullOrEmpty()) row.accounts += "$type|$name"
            }
        }

        return rows.values.map {
            // A contact joined from several accounts can have a default in each; the contact-wide one wins.
            val phones = if (it.superPrimary < 0) it.phones else it.phones.mapIndexed { i, p -> p.take(3) + (i == it.superPrimary) }
            listOf(it.id, it.name, it.first, it.middle, it.last, it.starred, phones, it.accounts.toList())
        }
    }

    /**
     * Makes [number] (matched like the Dart side's numberKey) [contactId]'s default, or clears the
     * default when [number] is null. Sets IS_SUPER_PRIMARY too: the contact-wide default that
     * Google Contacts and Android Auto use; the provider clears it on the contact's other numbers.
     */
    fun setDefaultNumber(context: Context, contactId: String, number: String?): Boolean {
        val resolver = context.contentResolver
        val phones = mutableListOf<Pair<Long, String>>()
        resolver.query(
            Data.CONTENT_URI, arrayOf(Data._ID, Phone.NUMBER),
            "${Data.CONTACT_ID} = ? AND ${Data.MIMETYPE} = ?", arrayOf(contactId, Phone.CONTENT_ITEM_TYPE), null,
        )?.use { c -> while (c.moveToNext()) phones += c.getLong(0) to c.getString(1).orEmpty() }
        val clear = ContentValues().apply { put(Data.IS_PRIMARY, 0); put(Data.IS_SUPER_PRIMARY, 0) }
        if (number == null) {
            for ((id, _) in phones) resolver.update(Data.CONTENT_URI, clear, "${Data._ID} = ?", arrayOf("$id"))
            return true
        }
        val chosen = phones.firstOrNull { numberKey(it.second) == numberKey(number) } ?: return false
        val set = ContentValues().apply { put(Data.IS_PRIMARY, 1); put(Data.IS_SUPER_PRIMARY, 1) }
        return resolver.update(Data.CONTENT_URI, set, "${Data._ID} = ?", arrayOf("${chosen.first}")) > 0
    }

    /** Digits only, last 10: the Dart side's numberKey (call_log.dart). */
    fun numberKey(number: String): String = number.filter(Char::isDigit).takeLast(10)
}
