package com.syedarhamraza.dialer

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.ContentUris
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.ContactsContract.CommonDataKinds.Phone
import android.provider.ContactsContract.Data
import android.provider.ContactsContract.PhoneLookup

/** Capability-gated contact actions; no private WhatsApp activities or guessed recipient IDs. */
object WhatsAppCalls {
    private val apps = linkedMapOf("com.whatsapp" to "WhatsApp", "com.whatsapp.w4b" to "WhatsApp Business")

    fun discover(context: Context, number: String): Map<String, Any?> {
        val entered = WhatsAppNumbers.clean(number) ?: throw IllegalArgumentException("Enter a phone number")
        val installed = apps.filterKeys { pkg ->
            try { context.packageManager.getPackageInfo(pkg, 0); true }
            catch (_: PackageManager.NameNotFoundException) { false }
        }
        val permitted = context.checkSelfPermission(Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED
        val aliases = mutableSetOf(entered)
        val ids = mutableSetOf<String>()
        if (permitted) {
            context.contentResolver.query(
                Uri.withAppendedPath(PhoneLookup.CONTENT_FILTER_URI, Uri.encode(entered)),
                arrayOf(PhoneLookup._ID), null, null, null,
            )?.use { c -> while (c.moveToNext()) ids += c.getString(0) }
            // PhoneLookup may suffix-match. Only trust normalization from an EXACT phone row.
            for (id in ids) {
                context.contentResolver.query(Phone.CONTENT_URI, arrayOf(Phone.NUMBER, Phone.NORMALIZED_NUMBER),
                    "${Phone.CONTACT_ID} = ?", arrayOf(id), null)?.use { c ->
                    while (c.moveToNext()) {
                        val raw = c.getString(0)?.let(WhatsAppNumbers::clean)
                        val normalized = c.getString(1)?.let(WhatsAppNumbers::international)
                        if (entered == raw || entered == normalized) {
                            if (normalized != null) aliases += normalized
                        }
                    }
                }
            }
        }
        // Ambiguous local numbers must never select between different international recipients.
        val international = aliases.mapNotNull(WhatsAppNumbers::international).distinct()
        val safeAliases = if (international.size <= 1) aliases else setOf(entered)
        val actions = mutableListOf<Map<String, Any?>>()
        if (permitted) for ((pkg, label) in installed) {
            val mime = "vnd.android.cursor.item/vnd.$pkg.voip.call"
            context.contentResolver.query(Data.CONTENT_URI, arrayOf(Data._ID, Data.DATA1),
                "${Data.MIMETYPE} = ?", arrayOf(mime), null)?.use { c ->
                while (c.moveToNext()) {
                    if (!WhatsAppNumbers.matchesAccount(c.getString(1), safeAliases)) continue
                    val id = c.getLong(0)
                    val intent = voiceIntent(pkg, id, mime)
                    if (intent.resolveActivity(context.packageManager) != null) {
                        actions += mapOf("package" to pkg, "label" to label, "dataId" to id, "mimeType" to mime)
                        break
                    }
                }
            }
        }
        return mapOf("apps" to installed.map { mapOf("package" to it.key, "label" to it.value) },
            "actions" to actions, "hasContactsPermission" to permitted,
            "internationalNumber" to (WhatsAppNumbers.international(entered) ?: international.singleOrNull()))
    }

    fun call(context: Context, number: String, pkg: String) {
        // Re-query on launch so stale data cannot route to a different contact.
        val snapshot = discover(context, number)
        @Suppress("UNCHECKED_CAST")
        val action = (snapshot["actions"] as List<Map<String, Any?>>).firstOrNull { it["package"] == pkg }
            ?: throw IllegalStateException("WhatsApp voice calling is unavailable for this number")
        context.startActivity(voiceIntent(pkg, action["dataId"] as Long, action["mimeType"] as String))
    }

    fun chat(context: Context, number: String, pkg: String) {
        require(pkg in apps) { "Unsupported app" }
        val international = WhatsAppNumbers.international(number)
            ?: throw IllegalArgumentException("Include the country code, starting with +")
        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://wa.me/${international.drop(1)}"))
            .setPackage(pkg).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    private fun voiceIntent(pkg: String, id: Long, mime: String) = Intent(Intent.ACTION_VIEW)
        .setDataAndType(ContentUris.withAppendedId(Data.CONTENT_URI, id), mime)
        .setPackage(pkg).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
}
