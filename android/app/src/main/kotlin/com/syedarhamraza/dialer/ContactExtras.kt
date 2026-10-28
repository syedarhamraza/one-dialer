package com.syedarhamraza.dialer

import android.content.ContentProviderOperation
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.provider.ContactsContract.AggregationExceptions
import android.provider.ContactsContract.Contacts
import android.provider.ContactsContract.Data
import android.provider.ContactsContract.RawContacts
import java.io.ByteArrayOutputStream

/** Contact details the contacts package doesn't cover: messaging apps, linked accounts, unlink, ringtone. */
object ContactExtras {

    /** Messaging apps that add rows to contacts, shown on the contact page like Samsung. */
    private val APPS = listOf(
        // (label, package, mimetype of the "Message" row)
        Triple("WhatsApp", "com.whatsapp", "vnd.android.cursor.item/vnd.com.whatsapp.profile"),
        Triple("WhatsApp Business", "com.whatsapp.w4b", "vnd.android.cursor.item/vnd.com.whatsapp.w4b.profile"),
        // Google Meet's video-call row: the contact page shows it as the Video tile, not a chat app.
        Triple("Meet", "com.google.android.apps.tachyon", MEET_VIDEO),
    )

    const val MEET_VIDEO = "vnd.android.cursor.item/com.google.android.apps.tachyon.phone.meet"

    /** One row per installed app with a chat entry for this contact: label, dataId, mimeType, icon (PNG). */
    fun messagingApps(context: Context, contactId: String): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        for ((label, pkg, mime) in APPS) {
            val dataId = context.contentResolver.query(
                Data.CONTENT_URI, arrayOf(Data._ID),
                "${Data.CONTACT_ID} = ? AND ${Data.MIMETYPE} = ?", arrayOf(contactId, mime), null,
            )?.use { c -> if (c.moveToFirst()) c.getLong(0) else null } ?: continue
            out += mapOf("label" to label, "dataId" to dataId, "mimeType" to mime, "icon" to appIcon(context, pkg))
        }
        return out
    }

    /** Opens a contact data row (e.g. WhatsApp's chat) the way Contacts apps do. */
    fun openData(context: Context, dataId: Long, mimeType: String) {
        val uri = ContentUris.withAppendedId(Data.CONTENT_URI, dataId)
        context.startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, mimeType).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    /** The raw contacts (one per account) linked into this contact: id, name, account type and name. */
    fun rawContacts(context: Context, contactId: String): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        context.contentResolver.query(
            RawContacts.CONTENT_URI,
            arrayOf(RawContacts._ID, RawContacts.DISPLAY_NAME_PRIMARY, RawContacts.ACCOUNT_TYPE, RawContacts.ACCOUNT_NAME),
            "${RawContacts.CONTACT_ID} = ? AND ${RawContacts.DELETED} = 0", arrayOf(contactId), null,
        )?.use { c ->
            while (c.moveToNext()) {
                out += mapOf(
                    "id" to c.getLong(0),
                    "name" to c.getString(1),
                    "accountType" to c.getString(2),
                    "accountName" to c.getString(3),
                )
            }
        }
        return out
    }

    /** Keeps each raw contact in [rawIds] separate from every other raw contact of the same contact. */
    fun unlink(context: Context, contactId: String, rawIds: List<Long>) {
        val all = rawContacts(context, contactId).map { it["id"] as Long }
        val ops = ArrayList<ContentProviderOperation>()
        for (a in rawIds) for (b in all) {
            if (a == b) continue
            ops += ContentProviderOperation.newUpdate(AggregationExceptions.CONTENT_URI)
                .withValue(AggregationExceptions.TYPE, AggregationExceptions.TYPE_KEEP_SEPARATE)
                .withValue(AggregationExceptions.RAW_CONTACT_ID1, a)
                .withValue(AggregationExceptions.RAW_CONTACT_ID2, b)
                .build()
        }
        if (ops.isNotEmpty()) context.contentResolver.applyBatch(android.provider.ContactsContract.AUTHORITY, ops)
    }

    /** Manage contacts › Merge duplicates: joins every raw contact of [contactIds] into one contact. */
    fun merge(context: Context, contactIds: List<String>) {
        val raws = contactIds.flatMap { id -> rawContacts(context, id).map { it["id"] as Long } }
        val first = raws.firstOrNull() ?: return
        val ops = ArrayList<ContentProviderOperation>()
        for (other in raws.drop(1)) {
            ops += ContentProviderOperation.newUpdate(AggregationExceptions.CONTENT_URI)
                .withValue(AggregationExceptions.TYPE, AggregationExceptions.TYPE_KEEP_TOGETHER)
                .withValue(AggregationExceptions.RAW_CONTACT_ID1, first)
                .withValue(AggregationExceptions.RAW_CONTACT_ID2, other)
                .build()
        }
        if (ops.isNotEmpty()) context.contentResolver.applyBatch(android.provider.ContactsContract.AUTHORITY, ops)
    }

    /**
     * Where a new contact can be saved, as ColorOS offers: the phone itself (the NULL account,
     * type and name null), SIM accounts, and Google accounts. Read from the accounts contacts
     * already use plus the signed-in Google accounts; app accounts (WhatsApp, Meet) are left out.
     */
    fun contactAccounts(context: Context): List<Map<String, String?>> {
        val seen = linkedSetOf<Pair<String?, String?>>(null to null) // the phone, always first
        context.contentResolver.query(
            RawContacts.CONTENT_URI, arrayOf(RawContacts.ACCOUNT_TYPE, RawContacts.ACCOUNT_NAME),
            "${RawContacts.DELETED} = 0", null, null,
        )?.use { c -> while (c.moveToNext()) seen += c.getString(0) to c.getString(1) }
        for (a in android.accounts.AccountManager.get(context).getAccountsByType("com.google")) seen += a.type to a.name
        return seen.filter { (type, _) -> isSaveTarget(type) }.map { (type, name) -> mapOf("type" to type, "name" to name) }
    }

    /** A contact can be saved to the phone (null or an OEM local type), a SIM, or Google; not app accounts. */
    fun isSaveTarget(type: String?): Boolean {
        val t = type?.lowercase() ?: return true
        if ("sdn" in t) return false // the carrier's read-only service numbers
        return t == "com.google" || "sim" in t || "local" in t || "phone" in t
    }

    /**
     * An empty contact on the phone itself (the NULL account), which the contacts package can't
     * create; it then fills it in with update. Returns the contact id.
     */
    fun createLocalContact(context: Context): String {
        val values = ContentValues().apply {
            putNull(RawContacts.ACCOUNT_TYPE)
            putNull(RawContacts.ACCOUNT_NAME)
        }
        val raw = context.contentResolver.insert(RawContacts.CONTENT_URI, values)!!
        return context.contentResolver.query(raw, arrayOf(RawContacts.CONTACT_ID), null, null, null)!!
            .use { c -> c.moveToFirst(); c.getLong(0).toString() }
    }

    fun ringtone(context: Context, contactId: String): String? =
        context.contentResolver.query(
            ContentUris.withAppendedId(Contacts.CONTENT_URI, contactId.toLong()),
            arrayOf(Contacts.CUSTOM_RINGTONE), null, null, null,
        )?.use { c -> if (c.moveToFirst()) c.getString(0) else null }

    /** Sets (or with null, clears back to the default) the contact's ringtone. */
    fun setRingtone(context: Context, contactId: String, uri: String?) {
        val values = ContentValues().apply { put(Contacts.CUSTOM_RINGTONE, uri) }
        context.contentResolver.update(ContentUris.withAppendedId(Contacts.CONTENT_URI, contactId.toLong()), values, null, null)
    }

    fun appIcon(context: Context, pkg: String): ByteArray? = runCatching {
        val drawable = context.packageManager.getApplicationIcon(pkg)
        val size = 96
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(Canvas(bitmap))
        ByteArrayOutputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it); it.toByteArray() }
    }.getOrNull()
}
