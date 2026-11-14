package com.syedarhamraza.dialer.telecom

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
                StructuredName.GIVEN_NAME, StructuredName.MIDDLE_NAME, StructuredName.FAMILY_NAME,
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
            listOf(it.id, it.name, it.first, it.middle, it.last, it.starred, it.phones, it.accounts.toList())
        }
    }
}
