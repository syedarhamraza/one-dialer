package com.syedarhamraza.dialer.telecom

import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telecom.Call
import android.telecom.CallAudioState
import android.telecom.DisconnectCause
import android.telecom.TelecomManager
import android.telephony.TelephonyManager
import java.util.concurrent.CopyOnWriteArraySet

/**
 * Single source of truth for the calls Telecom has handed to [DialerInCallService].
 * Everything runs on the main thread (Telecom delivers callbacks there).
 */
object CallManager {
    private val calls = linkedMapOf<String, Call>()
    private val ids = HashMap<Call, String>()

    /** Each call's last state, so a change knows where it came from (answered, hung up). */
    private val lastState = HashMap<Call, Int>()
    private var nextId = 0
    private val listeners = CopyOnWriteArraySet<() -> Unit>()

    var service: DialerInCallService? = null

    private val callback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            videoSpeaker(call)
            service?.onStateChanged(call, lastState.put(call, state), state)
            // Only once nothing rings: another call ending during call waiting mustn't hide the ringing one.
            if (calls.values.none { stateOf(it) == Call.STATE_RINGING }) service?.let { CallNotifications.cancelIncoming(it) }
            notifyChanged()
        }

        override fun onDetailsChanged(call: Call, details: Call.Details) {
            if (isVonr(details)) vonr += call
            // Back to voice: the camera and video surfaces go (the call screen asks again if video returns).
            if (android.telecom.VideoProfile.isAudioOnly(details.videoState)) VideoCalls.dropSurfaces(call)
            videoSpeaker(call)
            notifyChanged()
        }
        override fun onChildrenChanged(call: Call, children: List<Call>) = notifyChanged()

        override fun onVideoCallChanged(call: Call, videoCall: android.telecom.InCallService.VideoCall?) {
            VideoCalls.track(call)
            notifyChanged()
        }

        // Telecom says which calls can merge here, often after the second call connects.
        override fun onConferenceableCallsChanged(call: Call, conferenceableCalls: List<Call>) = notifyChanged()
    }

    /** Video calls already moved to the speaker: once per video stretch, so the user can move it back. */
    private val speakerForVideo = mutableSetOf<Call>()

    /** A carrier video call that's live goes to the speaker, unless a headset or Bluetooth has it. */
    private fun videoSpeaker(call: Call) {
        if (android.telecom.VideoProfile.isAudioOnly(call.details.videoState)) {
            speakerForVideo.remove(call)
            return
        }
        if (stateOf(call) != Call.STATE_ACTIVE || !speakerForVideo.add(call)) return
        @Suppress("DEPRECATION")
        if (service?.callAudioState?.route == CallAudioState.ROUTE_EARPIECE) service?.setAudioRoute(CallAudioState.ROUTE_SPEAKER)
    }

    /** Calls seen on 5G voice (VoNR) at some point; the call log only marks them from Android 17. */
    private val vonr = mutableSetOf<Call>()

    private fun isVonr(details: Call.Details) =
        details.extras?.getInt(TelecomManager.EXTRA_CALL_NETWORK_TYPE, -1) == TelephonyManager.NETWORK_TYPE_NR

    val hasCalls: Boolean get() = calls.isNotEmpty()

    /** The last call, kept briefly after Telecom removes it so the screen can show why it ended. */
    private var ended: Map<String, Any?>? = null
    private val handler = Handler(Looper.getMainLooper())
    private val clearEnded = Runnable { ended = null; notifyChanged() }

    /** True while the call screen should stay up: live calls or the brief "Call ended" summary. */
    val isShowingCalls: Boolean get() = calls.isNotEmpty() || ended != null

    fun onCallAdded(call: Call): String {
        handler.removeCallbacks(clearEnded)
        ended = null
        val id = "call-${nextId++}"
        calls[id] = call
        ids[call] = id
        lastState[call] = stateOf(call)
        call.registerCallback(callback)
        VideoCalls.track(call)
        notifyChanged()
        return id
    }

    fun onCallRemoved(call: Call) {
        call.unregisterCallback(callback)
        VideoCalls.release(call)
        speakerForVideo.remove(call)
        if (vonr.remove(call) || isVonr(call.details)) service?.let { CallLogSource.rememberVonr(it, call.details.creationTimeMillis) }
        call.details.takeIf { it.callerDisplayNamePresentation == TelecomManager.PRESENTATION_ALLOWED }
            ?.callerDisplayName?.trim()?.takeIf { it.isNotEmpty() }
            ?.let { name -> service?.let { CallLogSource.rememberCnap(it, call.details.creationTimeMillis, name) } }
        lastState.remove(call)
        val id = ids.remove(call)?.also { calls.remove(it) }
        if (id != null && calls.isEmpty()) {
            ended = serialize(id, call) + ("state" to "disconnected")
            handler.removeCallbacks(clearEnded)
            // You hung up yourself: no reason to read, so the screen closes almost at once.
            val local = call.details.disconnectCause?.code == DisconnectCause.LOCAL
            // A video call the network refused stays up for its Voice call button.
            val videoFailed = call.details.disconnectCause?.code == DisconnectCause.ERROR &&
                !android.telecom.VideoProfile.isAudioOnly(call.details.videoState) && call.details.connectTimeMillis == 0L
            handler.postDelayed(
                clearEnded,
                when {
                    local -> LOCAL_ENDED_LINGER_MS
                    videoFailed -> VIDEO_FAILED_LINGER_MS
                    else -> ENDED_LINGER_MS
                },
            )
        }
        notifyChanged()
    }

    fun get(id: String): Call? = calls[id]

    /** All current calls with their ids, oldest first. */
    /** Top-level calls: a conference stands in for its members. */
    fun all(): List<Pair<String, Call>> = calls.filter { it.value.parent == null }.map { it.key to it.value }

    fun idOf(call: Call): String? = ids[call]

    fun addListener(listener: () -> Unit) = listeners.add(listener)

    fun removeListener(listener: () -> Unit) = listeners.remove(listener)

    fun notifyChanged() = listeners.forEach { it() }

    /** Serialized for the Flutter side: `{calls: [...], audio: {...}}`. */
    fun snapshot(): Map<String, Any?> = mapOf(
        // A conference's members stay inside it (hung up with it), so the screen shows one call.
        "calls" to (if (calls.isEmpty()) listOfNotNull(ended) else all().map { (id, call) -> serialize(id, call) }),
        "audio" to audioSnapshot(),
        // The companion recorder's state; null without it (the screen then shows no Record).
        "recording" to RecorderCompanion.snapshot(),
    )

    fun stateOf(call: Call): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) call.details.state
        else @Suppress("DEPRECATION") call.state

    private fun serialize(id: String, call: Call): Map<String, Any?> {
        val details = call.details
        val number = details.handle?.schemeSpecificPart
        // A vault contact isn't in Android's contacts, so Telecom has no name for it.
        val saved = (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) details.contactDisplayName else null)
            ?: service?.let { Vault.nameFor(it, number) }
        val name = saved ?: details.callerDisplayName
        val display = service?.let { NumberDisplay.of(it, number) }
        return mapOf(
            "id" to id,
            "number" to number,
            "formattedNumber" to display?.formatted,
            "location" to display?.location,
            "disconnectCode" to disconnectName(details.disconnectCause?.code),
            "disconnectLabel" to details.disconnectCause?.label?.toString()?.takeIf { it.isNotBlank() },
            // Telephony's own name for it (SERVER_UNREACHABLE...), which the call screen words for people.
            "disconnectReason" to details.disconnectCause?.reason?.takeIf { it.isNotBlank() },
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
            // The network carrying the call right now: 4G (VoLTE) or 5G (VoNR); Wi-Fi and 3G get no mark.
            "isVolte" to (details.extras?.getInt(TelecomManager.EXTRA_CALL_NETWORK_TYPE, -1) == TelephonyManager.NETWORK_TYPE_LTE),
            "isVonr" to isVonr(details),
            "isPrivate" to (details.handlePresentation != android.telecom.TelecomManager.PRESENTATION_ALLOWED),
        ) + VideoCalls.info(call)
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
            "bluetoothDevices" to state.supportedBluetoothDevices.map {
                mapOf("id" to it.address, "name" to bluetoothName(it))
            },
            "activeBluetooth" to state.activeBluetoothDevice?.address,
        )
    }

    /** The name the user gave the device (watch, buds); null without the Nearby devices permission. */
    private fun bluetoothName(device: android.bluetooth.BluetoothDevice): String? = try {
        (if (android.os.Build.VERSION.SDK_INT >= 30) device.alias else null) ?: device.name
    } catch (_: SecurityException) {
        null
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

    private fun disconnectName(code: Int?): String? = when (code) {
        DisconnectCause.BUSY -> "busy"
        DisconnectCause.REJECTED -> "rejected"
        DisconnectCause.MISSED -> "missed"
        DisconnectCause.ERROR -> "error"
        DisconnectCause.LOCAL -> "local"
        DisconnectCause.REMOTE -> "remote"
        DisconnectCause.CANCELED -> "canceled"
        else -> null
    }

    private const val ENDED_LINGER_MS = 2000L
    private const val LOCAL_ENDED_LINGER_MS = 600L
    private const val VIDEO_FAILED_LINGER_MS = 8000L

    private val ROUTES = listOf(
        CallAudioState.ROUTE_EARPIECE to "earpiece",
        CallAudioState.ROUTE_SPEAKER to "speaker",
        CallAudioState.ROUTE_BLUETOOTH to "bluetooth",
        CallAudioState.ROUTE_WIRED_HEADSET to "wiredHeadset",
    )

    private fun routeName(route: Int) = ROUTES.firstOrNull { it.first == route }?.second ?: "earpiece"

    fun routeValue(name: String): Int? = ROUTES.firstOrNull { it.second == name }?.first
}
