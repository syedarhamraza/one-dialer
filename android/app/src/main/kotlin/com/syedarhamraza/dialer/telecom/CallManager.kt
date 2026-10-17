package com.syedarhamraza.dialer.telecom

import android.os.Build
import android.telecom.Call
import android.telecom.CallAudioState
import java.util.concurrent.CopyOnWriteArraySet

/**
 * Single source of truth for the calls Telecom has handed to [DialerInCallService].
 * Everything runs on the main thread (Telecom delivers callbacks there).
 */
object CallManager {
    private val calls = linkedMapOf<String, Call>()
    private val ids = HashMap<Call, String>()
    private var nextId = 0
    private val listeners = CopyOnWriteArraySet<() -> Unit>()

    var service: DialerInCallService? = null

    private val callback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            if (state != Call.STATE_RINGING) service?.let { CallNotifications.cancelIncoming(it) }
            notifyChanged()
        }

        override fun onDetailsChanged(call: Call, details: Call.Details) = notifyChanged()
        override fun onChildrenChanged(call: Call, children: List<Call>) = notifyChanged()
    }

    val hasCalls: Boolean get() = calls.isNotEmpty()

    fun onCallAdded(call: Call): String {
        val id = "call-${nextId++}"
        calls[id] = call
        ids[call] = id
        call.registerCallback(callback)
        notifyChanged()
        return id
    }

    fun onCallRemoved(call: Call) {
        call.unregisterCallback(callback)
        ids.remove(call)?.let { calls.remove(it) }
        notifyChanged()
    }

    fun get(id: String): Call? = calls[id]

    /** All current calls with their ids, oldest first. */
    fun all(): List<Pair<String, Call>> = calls.map { it.key to it.value }

    fun idOf(call: Call): String? = ids[call]

    fun addListener(listener: () -> Unit) = listeners.add(listener)

    fun removeListener(listener: () -> Unit) = listeners.remove(listener)

    fun notifyChanged() = listeners.forEach { it() }

    /** Serialized for the Flutter side: `{calls: [...], audio: {...}}`. */
    fun snapshot(): Map<String, Any?> = mapOf(
        "calls" to calls.map { (id, call) -> serialize(id, call) },
        "audio" to audioSnapshot(),
    )

    fun stateOf(call: Call): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) call.details.state
        else @Suppress("DEPRECATION") call.state

    private fun serialize(id: String, call: Call): Map<String, Any?> {
        val details = call.details
        val name = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            details.contactDisplayName ?: details.callerDisplayName
        } else {
            details.callerDisplayName
        }
        return mapOf(
            "id" to id,
            "number" to details.handle?.schemeSpecificPart,
            "name" to name,
            "state" to stateName(stateOf(call)),
            "connectTimeMillis" to details.connectTimeMillis,
            "isConference" to details.hasProperty(Call.Details.PROPERTY_CONFERENCE),
            "canHold" to details.can(Call.Details.CAPABILITY_HOLD),
            "canMerge" to (call.conferenceableCalls.isNotEmpty() ||
                details.can(Call.Details.CAPABILITY_MERGE_CONFERENCE)),
            "canSwap" to details.can(Call.Details.CAPABILITY_SWAP_CONFERENCE),
            "simId" to details.accountHandle?.let { "${it.componentName.flattenToString()}|${it.id}" },
            "isHd" to details.hasProperty(Call.Details.PROPERTY_HIGH_DEF_AUDIO),
            "isWifi" to details.hasProperty(Call.Details.PROPERTY_WIFI),
            "isPrivate" to (details.handlePresentation != android.telecom.TelecomManager.PRESENTATION_ALLOWED),
        )
    }

    @Suppress("DEPRECATION") // CallAudioState is replaced by CallEndpoint on API 34+
    private fun audioSnapshot(): Map<String, Any?> {
        val state: CallAudioState = service?.callAudioState ?: return mapOf(
            "muted" to false, "route" to "earpiece", "supportedRoutes" to listOf("earpiece"),
        )
        return mapOf(
            "muted" to state.isMuted,
            "route" to routeName(state.route),
            "supportedRoutes" to ROUTES.filter { (mask, _) -> state.supportedRouteMask and mask != 0 }
                .map { it.second },
        )
    }

    private fun stateName(state: Int): String = when (state) {
        Call.STATE_NEW -> "new"
        Call.STATE_DIALING -> "dialing"
        Call.STATE_CONNECTING -> "connecting"
        Call.STATE_RINGING -> "ringing"
        Call.STATE_ACTIVE -> "active"
        Call.STATE_HOLDING -> "holding"
        Call.STATE_DISCONNECTING -> "disconnecting"
        Call.STATE_DISCONNECTED -> "disconnected"
        Call.STATE_SELECT_PHONE_ACCOUNT -> "selectPhoneAccount"
        Call.STATE_PULLING_CALL -> "pulling"
        Call.STATE_AUDIO_PROCESSING -> "audioProcessing"
        Call.STATE_SIMULATED_RINGING -> "ringing"
        else -> "unknown"
    }

    private val ROUTES = listOf(
        CallAudioState.ROUTE_EARPIECE to "earpiece",
        CallAudioState.ROUTE_SPEAKER to "speaker",
        CallAudioState.ROUTE_BLUETOOTH to "bluetooth",
        CallAudioState.ROUTE_WIRED_HEADSET to "wiredHeadset",
    )

    private fun routeName(route: Int) = ROUTES.firstOrNull { it.first == route }?.second ?: "earpiece"

    fun routeValue(name: String): Int? = ROUTES.firstOrNull { it.second == name }?.first
}
