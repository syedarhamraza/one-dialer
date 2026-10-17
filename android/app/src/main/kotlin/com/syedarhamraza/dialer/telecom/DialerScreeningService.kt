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
 * "private/unknown callers" and "callers not in contacts" rules from [BlockingPrefs].
 */
class DialerScreeningService : CallScreeningService() {

    override fun onScreenCall(details: Call.Details) {
        val incoming = details.callDirection == Call.Details.DIRECTION_INCOMING
        val number = details.handle?.schemeSpecificPart.orEmpty()
        val block = incoming && BlockRules.shouldBlock(
            hiddenNumber = details.handlePresentation != TelecomManager.PRESENTATION_ALLOWED || number.isBlank(),
            isContact = { isContact(number) },
            settings = BlockingPrefs.read(this),
        )
        val response = CallResponse.Builder()
        if (block) {
            response.setDisallowCall(true).setRejectCall(true).setSkipNotification(true)
            // Some ROMs (this vivo included) log screened calls as *missed*; remember this one
            // so CallLogSource re-labels Telecom's entry as blocked.
            CallLogSource.rememberBlocked(this, number)
        }
        respondToCall(details, response.build())
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

/** The blocking toggles, in plain SharedPreferences so the screening service can read them without Flutter. */
data class BlockingSettings(val blockHidden: Boolean = false, val blockNonContacts: Boolean = false)

object BlockingPrefs {
    private const val FILE = "blocking"

    fun read(context: Context): BlockingSettings {
        val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
        return BlockingSettings(prefs.getBoolean("blockHidden", false), prefs.getBoolean("blockNonContacts", false))
    }

    fun write(context: Context, settings: BlockingSettings) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE).edit()
            .putBoolean("blockHidden", settings.blockHidden)
            .putBoolean("blockNonContacts", settings.blockNonContacts)
            .apply()
    }
}

object BlockRules {
    /** [isContact] is only evaluated when the non-contacts rule is on (it's a contacts query). */
    fun shouldBlock(hiddenNumber: Boolean, isContact: () -> Boolean, settings: BlockingSettings): Boolean = when {
        hiddenNumber -> settings.blockHidden || settings.blockNonContacts
        settings.blockNonContacts -> !isContact()
        else -> false
    }
}
