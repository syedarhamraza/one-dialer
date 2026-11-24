package com.syedarhamraza.dialer

import android.content.ContentProviderOperation
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.media.RingtoneManager
import android.net.Uri
import android.provider.ContactsContract.AggregationExceptions
import android.provider.ContactsContract.CommonDataKinds.Phone
import android.provider.ContactsContract.CommonDataKinds.StructuredName
import android.provider.ContactsContract.Contacts
import android.provider.ContactsContract.Data
import android.provider.ContactsContract.RawContacts
import com.syedarhamraza.dialer.telecom.BlockRules
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
            // A synced row (Meet's, from the Google account) stays when its app is missing or disabled,
            // and tapping it opened nothing (NO_APP on vivo): show only rows the app can open.
            val view = Intent(Intent.ACTION_VIEW).setDataAndType(ContentUris.withAppendedId(Data.CONTENT_URI, dataId), mime)
            if (context.packageManager.queryIntentActivities(view.setPackage(pkg), 0).isEmpty()) continue
            out += mapOf("label" to label, "dataId" to dataId, "mimeType" to mime, "icon" to appIcon(context, pkg))
        }
        return out
    }

    /**
     * Opens a contact data row (e.g. WhatsApp's chat) the way Contacts apps do, in the app that owns
     * it: other apps (SHAREit) claim these links too, and WhatsApp opened from that chooser closed at once.
     * Its exact activity, not just its package: with vivo's App Clone the package matches the clone too,
     * and Android asked which WhatsApp to use.
     */
    fun openData(context: Context, dataId: Long, mimeType: String) {
        val uri = ContentUris.withAppendedId(Data.CONTENT_URI, dataId)
        val intent = Intent(Intent.ACTION_VIEW).setDataAndType(uri, mimeType).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val owner = APPS.firstOrNull { it.third == mimeType }?.second
        val target = Intent(intent).setPackage(owner)
        // Only this user's activities: the clone's copy lives in another profile.
        context.packageManager.queryIntentActivities(target, 0).firstOrNull()?.activityInfo
            ?.let { target.setClassName(it.packageName, it.name) }
        try {
            context.startActivity(target)
        } catch (_: android.content.ActivityNotFoundException) {
            context.startActivity(intent) // the owner can't open it itself; let Android pick
        }
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

    /**
     * Manage contacts › Merge duplicates: joins every raw contact of [contactIds] into one
     * contact, named after [nameContactId]'s name (its name row becomes the super-primary one,
     * which the aggregator prefers), and deletes the phone rows whose number ends like one of
     * [removeNumbers] (the ones left unticked).
     */
    fun merge(context: Context, contactIds: List<String>, nameContactId: String? = null, removeNumbers: List<String> = emptyList()) {
        val ordered = nameContactId?.takeIf { it in contactIds }?.let { listOf(it) + (contactIds - it) } ?: contactIds
        val nameRaws = nameContactId?.let { id -> rawContacts(context, id).map { it["id"] as Long } }.orEmpty().toSet()
        val raws = ordered.flatMap { id -> rawContacts(context, id).map { it["id"] as Long } }.distinct()
        val first = raws.firstOrNull() ?: return
        val ops = ArrayList<ContentProviderOperation>()
        for (other in raws.drop(1)) {
            ops += ContentProviderOperation.newUpdate(AggregationExceptions.CONTENT_URI)
                .withValue(AggregationExceptions.TYPE, AggregationExceptions.TYPE_KEEP_TOGETHER)
                .withValue(AggregationExceptions.RAW_CONTACT_ID1, first)
                .withValue(AggregationExceptions.RAW_CONTACT_ID2, other)
                .build()
        }
        val resolver = context.contentResolver
        if (ops.isNotEmpty()) resolver.applyBatch(android.provider.ContactsContract.AUTHORITY, ops)
        // The name and the unticked numbers: one at a time, so a row another app's account
        // protects (vivo has no is_read_only column to check first) stays without failing the merge.
        val removeKeys = removeNumbers.map(BlockRules::numberKey).filter { it.isNotEmpty() }.toSet()
        val edits = ArrayList<ContentProviderOperation>()
        resolver.query(
            Data.CONTENT_URI, arrayOf(Data._ID, Data.RAW_CONTACT_ID, Data.MIMETYPE, Phone.NUMBER),
            "${Data.RAW_CONTACT_ID} IN (${raws.joinToString(",")}) AND ${Data.MIMETYPE} IN (?, ?)",
            arrayOf(StructuredName.CONTENT_ITEM_TYPE, Phone.CONTENT_ITEM_TYPE), null,
        )?.use { c ->
            while (c.moveToNext()) {
                val row = ContentUris.withAppendedId(Data.CONTENT_URI, c.getLong(0))
                if (c.getString(2) == StructuredName.CONTENT_ITEM_TYPE) {
                    if (nameRaws.isEmpty()) continue
                    val primary = if (c.getLong(1) in nameRaws) 1 else 0
                    edits += ContentProviderOperation.newUpdate(row)
                        .withValue(Data.IS_PRIMARY, primary)
                        .withValue(Data.IS_SUPER_PRIMARY, primary)
                        .build()
                } else if (BlockRules.numberKey(c.getString(3).orEmpty()) in removeKeys) {
                    edits += ContentProviderOperation.newDelete(row).build()
                }
            }
        }
        for (op in edits) {
            runCatching { resolver.applyBatch(android.provider.ContactsContract.AUTHORITY, arrayListOf(op)) }
        }
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

    /** The custom ringtone's name, or null when the contact follows the system (or it's gone). */
    fun ringtoneTitle(context: Context, contactId: String): String? = ringtone(context, contactId)?.let { uri ->
        runCatching { RingtoneManager.getRingtone(context, Uri.parse(uri))?.getTitle(context) }.getOrNull()
    }

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
