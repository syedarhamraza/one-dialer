package com.syedarhamraza.dialer.debug

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.telecom.Conference
import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.DisconnectCause
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.util.Log

/**
 * DEBUG BUILDS ONLY: a fake phone line so incoming calls can be tested without a second phone.
 * Telecom routes its calls to our InCallService like real SIM calls (ringtone, lock screen,
 * notifications); there's just no audio.
 *
 * Ring the phone:
 *   adb shell am broadcast -n com.syedarhamraza.onedialer/com.syedarhamraza.dialer.debug.FakeCallReceiver --es number 03001234567
 * (`--ez private true` for a hidden number.) The first broadcast registers the line; enable it once with
 *   adb shell telecom set-phone-account-enabled com.syedarhamraza.onedialer/com.syedarhamraza.dialer.debug.FakeCallService fake 0
 */
class FakeCallService : ConnectionService() {

    override fun onCreateIncomingConnection(manager: PhoneAccountHandle?, request: ConnectionRequest): Connection {
        // A hidden caller arrives with no number (Telecom doesn't pass our own extras through).
        val private = request.address?.schemeSpecificPart.isNullOrEmpty()
        return FakeConnection().apply {
            setAddress(
                request.address,
                if (private) TelecomManager.PRESENTATION_RESTRICTED else TelecomManager.PRESENTATION_ALLOWED,
            )
            connectionCapabilities = Connection.CAPABILITY_HOLD or Connection.CAPABILITY_SUPPORT_HOLD or
                Connection.CAPABILITY_MUTE
            setInitializing()
            setRinging()
            live += this
            linkConferenceable()
        }
    }

    override fun onCreateIncomingConnectionFailed(manager: PhoneAccountHandle?, request: ConnectionRequest?) {
        Log.w(TAG, "Telecom rejected the fake incoming call (is the account enabled?)")
    }

    // Two test calls can merge, so the call screen's Merge and conference look can be tested.
    private val live = mutableListOf<FakeConnection>()

    private fun linkConferenceable() =
        live.forEach { c -> c.setConferenceableConnections(live.filter { it !== c && it.conference == null }) }

    override fun onConference(a: Connection, b: Connection) {
        addConference(FakeConference(handle(this)).apply {
            addConnection(a)
            addConnection(b)
            setActive()
        })
        a.setActive()
        b.setActive()
        linkConferenceable()
    }

    // shortcut: no Separate, and a conference left with one call stays a conference; enough to see the look.
    private class FakeConference(handle: PhoneAccountHandle) : Conference(handle) {
        init {
            connectionCapabilities = Connection.CAPABILITY_HOLD or Connection.CAPABILITY_SUPPORT_HOLD or
                Connection.CAPABILITY_MUTE
        }

        override fun onDisconnect() {
            connections.toList().forEach { it.onDisconnect() }
            setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
            destroy()
        }
        override fun onHold() = setOnHold()
        override fun onUnhold() = setActive()
    }

    private inner class FakeConnection : Connection() {
        override fun onAnswer() = setActive()
        override fun onAnswer(videoState: Int) = setActive()
        override fun onReject() = end(DisconnectCause.REJECTED)
        override fun onReject(replyMessage: String?) {
            Log.i(TAG, "Declined with message: $replyMessage")
            end(DisconnectCause.REJECTED)
        }
        override fun onDisconnect() = end(DisconnectCause.LOCAL)
        override fun onAbort() = end(DisconnectCause.OTHER)
        override fun onHold() = setOnHold()
        override fun onUnhold() = setActive()

        private fun end(cause: Int) {
            setDisconnected(DisconnectCause(cause))
            destroy()
            live -= this
            linkConferenceable()
        }
    }

    companion object {
        const val TAG = "FakeCalls"
        const val ACCOUNT_ID = "fake"

        fun handle(context: Context) =
            PhoneAccountHandle(ComponentName(context, FakeCallService::class.java), ACCOUNT_ID)
    }
}

/** `adb shell am broadcast` target that rings the phone from the fake line. */
class FakeCallReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val telecom = context.getSystemService(TelecomManager::class.java)
        val handle = FakeCallService.handle(context)
        telecom.registerPhoneAccount(
            PhoneAccount.builder(handle, "Test line")
                .setCapabilities(PhoneAccount.CAPABILITY_CALL_PROVIDER)
                .addSupportedUriScheme(PhoneAccount.SCHEME_TEL)
                .build()
        )
        val number = if (intent.getBooleanExtra("private", false)) "" else intent.getStringExtra("number") ?: "03001234567"
        val extras = Bundle().apply {
            putParcelable(TelecomManager.EXTRA_INCOMING_CALL_ADDRESS, Uri.fromParts(PhoneAccount.SCHEME_TEL, number, null))
        }
        runCatching { telecom.addNewIncomingCall(handle, extras) }
            .onSuccess { Log.i(FakeCallService.TAG, "Fake incoming call requested") }
            .onFailure { Log.w(FakeCallService.TAG, "addNewIncomingCall failed: ${it.message}") }
    }
}
