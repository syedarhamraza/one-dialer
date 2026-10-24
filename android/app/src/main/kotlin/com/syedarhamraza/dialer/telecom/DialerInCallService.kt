package com.syedarhamraza.dialer.telecom

import android.os.PowerManager
import android.telecom.Call
import android.telecom.CallAudioState
import android.telecom.InCallService
import com.syedarhamraza.dialer.InCallActivity
import com.syedarhamraza.dialer.InCallEngine

/**
 * Telecom binds to this service for every call once the app holds the default dialer role.
 * It tracks calls, keeps the call notifications and the proximity sensor in sync, and
 * surfaces the UI; the screens themselves live in Flutter.
 */
class DialerInCallService : InCallService() {

    private var proximityLock: PowerManager.WakeLock? = null
    private val onCallsChanged = {
        CallNotifications.updateOngoing(this, CallManager.all())
        updateProximity()
    }

    override fun onCreate() {
        super.onCreate()
        CallManager.service = this
        CallManager.addListener(onCallsChanged)
        val power = getSystemService(PowerManager::class.java)
        if (power.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK)) {
            proximityLock = power.newWakeLock(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK, "dialer:proximity")
        }
        // Warm the in-call Flutter engine so the call screen shows without a cold start.
        InCallEngine.ensure(this)
    }

    override fun onDestroy() {
        CallManager.removeListener(onCallsChanged)
        CallManager.service = null
        CallNotifications.cancelIncoming(this)
        CallNotifications.cancelOngoing(this)
        proximityLock?.takeIf { it.isHeld }?.release()
        super.onDestroy()
    }

    override fun onCallAdded(call: Call) {
        val id = CallManager.onCallAdded(call)
        if (CallManager.stateOf(call) == Call.STATE_RINGING) {
            // Incoming: a full-screen notification is the only reliable way to open UI from the background.
            CallNotifications.showIncoming(this, id, call)
        } else {
            InCallActivity.start(this)
        }
    }

    override fun onCallRemoved(call: Call) {
        CallManager.onCallRemoved(call)
        if (!CallManager.hasCalls) CallNotifications.cancelIncoming(this)
    }

    @Deprecated("Replaced by onCallEndpointChanged on API 34+, still delivered on all versions")
    override fun onCallAudioStateChanged(audioState: CallAudioState) {
        CallManager.notifyChanged()
    }

    /**
     * Screen off at the ear: only for a live call on the earpiece, never while ringing, and only
     * while the full call screen is up (not in vivo's island or a small floating window).
     */
    fun updateProximity() {
        val lock = proximityLock ?: return
        val states = CallManager.all().map { CallManager.stateOf(it.second) }

        @Suppress("DEPRECATION") // CallAudioState still reports the route on API 34+
        val onEarpiece = callAudioState?.route?.let {
            it == CallAudioState.ROUTE_EARPIECE || it == CallAudioState.ROUTE_WIRED_HEADSET
        } ?: true
        val wanted = InCallActivity.isFullScreen && onEarpiece && Call.STATE_RINGING !in states &&
            states.any { it == Call.STATE_ACTIVE || it == Call.STATE_DIALING || it == Call.STATE_CONNECTING }
        if (wanted && !lock.isHeld) lock.acquire()
        if (!wanted && lock.isHeld) lock.release(PowerManager.RELEASE_FLAG_WAIT_FOR_NO_PROXIMITY)
    }
}
