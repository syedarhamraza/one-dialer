package com.syedarhamraza.dialer.telecom

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.ContactsContract.PhoneLookup
import android.telecom.Call
import android.telecom.CallScreeningService
import android.telecom.TelecomManager

/**
 * Bound by Telecom for incoming calls while we're the default dialer. Numbers on Android's
 * block list are already rejected by Telecom before this runs; this adds the
 * "private/unknown callers", "callers not in contacts" and prefix rules from [BlockingPrefs],
 * with the allowlist letting its numbers past them.
 */
class DialerScreeningService : CallScreeningService() {

    override fun onScreenCall(details: Call.Details) {
        val incoming = details.callDirection == Call.Details.DIRECTION_INCOMING
        val number = details.handle?.schemeSpecificPart.orEmpty()
        // A failed contacts lookup lets the call through: without an answer Telecom holds the
        // call back for its 5 s timeout before it rings.
        val block = incoming && runCatching {
            BlockRules.shouldBlock(
                hiddenNumber = details.handlePresentation != TelecomManager.PRESENTATION_ALLOWED || number.isBlank(),
                number = number,
                isContact = { isContact(number) },
                settings = BlockingPrefs.read(this),
            )
        }.getOrDefault(false)
        val response = CallResponse.Builder()
        if (block) {
            response.setDisallowCall(true).setRejectCall(true).setSkipNotification(true)
            // Some ROMs (this vivo included) log screened calls as *missed*; remember this one
            // so CallLogSource re-labels Telecom's entry as blocked.
            CallLogSource.rememberBlocked(this, number)
        }
        respondToCall(details, response.build())
        // Telecom rings once screening answers; a VIP's ringer goes up before that.
        if (incoming && !block) runCatching { VipRing.onIncoming(this, number) }
        // Telecom writes the log entry just after; fix it then too (also done on every read).
        val app = applicationContext
        android.os.Handler(mainLooper).postDelayed({ Thread { CallLogSource.fixBlocked(app) }.start() }, 3_000)
    }

    private fun isContact(number: String): Boolean {
        if (number.isBlank()) return false
        if (checkSelfPermission(Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) return true
        val uri = Uri.withAppendedPath(PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number))
        return contentResolver.query(uri, arrayOf(PhoneLookup._ID), null, null, null)?.use { it.count > 0 } ?: false
    }
}

/**
 * The blocking toggles, prefixes and allowlist, in plain SharedPreferences so the screening
 * service can read them without Flutter.
 */
data class BlockingSettings(
    val blockHidden: Boolean = false,
    val blockNonContacts: Boolean = false,
    val prefixes: Set<String> = emptySet(),
    val allowed: Set<String> = emptySet(),
)

object BlockingPrefs {
    private const val FILE = "blocking"

    fun read(context: Context): BlockingSettings {
        val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
        return BlockingSettings(
            prefs.getBoolean("blockHidden", false),
            prefs.getBoolean("blockNonContacts", false),
            prefs.getStringSet("prefixes", null).orEmpty().toSet(),
            prefs.getStringSet("allowed", null).orEmpty().toSet(),
        )
    }

    fun write(context: Context, settings: BlockingSettings) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE).edit()
            .putBoolean("blockHidden", settings.blockHidden)
            .putBoolean("blockNonContacts", settings.blockNonContacts)
            .putStringSet("prefixes", settings.prefixes)
            .putStringSet("allowed", settings.allowed)
            .apply()
    }
}

object BlockRules {
    /** The last 10 digits, as Dart's `numberKey`: "0300 1234567" and "+92 300 1234567" match. */
    fun numberKey(number: String): String = number.filter { it.isDigit() }.takeLast(10)

    /** Digits with a leading + kept, the form prefixes are typed and compared in. */
    fun prefixForm(number: String): String {
        val digits = number.filter { it.isDigit() }
        return if (number.trimStart().startsWith("+")) "+$digits" else digits
    }

    /**
     * Hidden numbers follow the hidden and non-contacts rules; otherwise an allowed number
     * always rings, then prefixes block, then the non-contacts rule. [isContact] is only
     * evaluated when the non-contacts rule decides (it's a contacts query).
     */
    // shortcut: a prefix is matched against the number as the carrier sends it (+92300... vs
    // 0300...), so "0300" misses an international-form caller; upgrade with libphonenumber
    // if users ask.
    fun shouldBlock(
        hiddenNumber: Boolean,
        number: String,
        isContact: () -> Boolean,
        settings: BlockingSettings,
    ): Boolean {
        if (hiddenNumber) return settings.blockHidden || settings.blockNonContacts
        val key = numberKey(number)
        if (key.isNotEmpty() && settings.allowed.any { numberKey(it) == key }) return false
        val form = prefixForm(number)
        if (settings.prefixes.any { it.isNotEmpty() && form.startsWith(prefixForm(it)) }) return true
        return settings.blockNonContacts && !isContact()
    }
}
