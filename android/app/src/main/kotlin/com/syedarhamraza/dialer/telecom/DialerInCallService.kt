package com.syedarhamraza.dialer.telecom

import android.app.KeyguardManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.telecom.Call
import android.telecom.CallAudioState
import android.telecom.InCallService
import android.telecom.VideoProfile
import android.speech.tts.TextToSpeech
import java.util.concurrent.Executors
import com.syedarhamraza.dialer.AppLanguage
import com.syedarhamraza.dialer.InCallActivity
import com.syedarhamraza.dialer.InCallEngine
import com.syedarhamraza.dialer.R

/**
 * Telecom binds to this service for every call once the app holds the default dialer role.
 * It tracks calls, keeps the call notifications and the proximity sensor in sync, and
 * surfaces the UI; the screens themselves live in Flutter.
 */
class DialerInCallService : InCallService() {
    private companion object {
        const val ANNOUNCE_EVERY_MS = 6000L
    }


    private var proximityLock: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())
    private val onCallsChanged = {
        CallNotifications.updateOngoing(this, CallManager.all())
        updateProximity()
        RecorderCompanion.onCallsChanged(this)
    }

    override fun onCreate() {
        super.onCreate()
        CallManager.service = this
        CallManager.addListener(onCallsChanged)
        RecorderCompanion.watch(this)
        val power = getSystemService(PowerManager::class.java)
        if (power.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK)) {
            proximityLock = power.newWakeLock(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK, "dialer:proximity")
        }
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        onTts { shutdown() }
        ttsThread.shutdown()
        CallManager.removeListener(onCallsChanged)
        RecorderCompanion.unwatch(this)
        CallManager.service = null
        CallNotifications.cancelIncoming(this)
        CallNotifications.cancelOngoing(this)
        proximityLock?.takeIf { it.isHeld }?.release()
        super.onDestroy()
    }

    override fun onCallAdded(call: Call) {
        val id = CallManager.onCallAdded(call)
        if (CallManager.stateOf(call) == Call.STATE_RINGING) {
            val prefs = CallPrefs.read(this)
            // Incoming: a full-screen notification is the only reliable way to open UI from the background.
            // Settings › Full screen opens the call screen while unlocked too, instead of a banner.
            val openScreen = prefs["incomingStyle"] == "full" && !InCallActivity.isFullScreen &&
                getSystemService(PowerManager::class.java).isInteractive &&
                !getSystemService(KeyguardManager::class.java).isKeyguardLocked
            CallNotifications.showIncoming(this, id, call, screenOpening = openScreen)
            if (openScreen) {
                InCallActivity.start(this)
                // If Android blocked the start, ring with the banner after all rather than silently.
                handler.postDelayed({
                    if (!InCallActivity.isFullScreen && CallManager.idOf(call) != null &&
                        CallManager.stateOf(call) == Call.STATE_RINGING
                    ) CallNotifications.showIncoming(this, id, call)
                }, 1500)
            }
            val announce = prefs["announceCalls"]
            if (announce == "always" || (announce == "headset" && headsetConnected())) announce(call)
            if (prefs["autoAnswer"] == true && CallManager.all().size == 1 && headsetConnected()) {
                handler.postDelayed({
                    if (CallManager.idOf(call) != null && CallManager.stateOf(call) == Call.STATE_RINGING) {
                        call.answer(VideoProfile.STATE_AUDIO_ONLY)
                    }
                }, (prefs["autoAnswerDelay"] as Int) * 1000L)
            }
        } else {
            InCallActivity.start(this)
        }
        // Warm the call screen's Flutter engine only now: building it (~0.5 s on a cold start) used
        // to hold up the ringing notification while vivo's flash and edge glow already ran.
        InCallEngine.ensure(this)
    }

    override fun onCallRemoved(call: Call) {
        CallManager.onCallRemoved(call)
        if (!CallManager.hasCalls) CallNotifications.cancelIncoming(this)
    }

    /** Settings › Answer/End calls: a buzz on answer and hang-up, and the speaker on answer. */
    fun onStateChanged(call: Call, from: Int?, to: Int) {
        if (from == Call.STATE_RINGING) onTts { stop() }
        if (!CallPrefs.buzzes(from, to)) return
        val prefs = CallPrefs.read(this)
        if (prefs["vibrateAnswerEnd"] == true) {
            getSystemService(Vibrator::class.java)?.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK))
        }
        // Not with a headset or car kit connected, as ColorOS.
        @Suppress("DEPRECATION")
        if (CallPrefs.goesLive(from, to) && prefs["speakerDefault"] == true &&
            callAudioState?.route == CallAudioState.ROUTE_EARPIECE
        ) setAudioRoute(CallAudioState.ROUTE_SPEAKER)
    }

    @Volatile private var tts: TextToSpeech? = null

    // TextToSpeech calls block on the speech engine (3 s seen on a MediaTek OPPO), so never on the main thread.
    private val ttsThread = Executors.newSingleThreadExecutor()

    /** Called from the main thread only, so the shutdown check can't race. */
    private fun onTts(action: TextToSpeech.() -> Unit) {
        if (!ttsThread.isShutdown) ttsThread.execute { tts?.action() }
    }

    /** Settings › Announce incoming calls: says who's calling, every few seconds while it rings. */
    private fun announce(call: Call) {
        val details = call.details
        val res = AppLanguage.localized(this).resources
        val text = res.getString(
            R.string.announce_calling,
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) details.contactDisplayName else null)
                ?: details.callerDisplayName?.takeIf { it.isNotBlank() }
                // Digit by digit, not "three billion…".
                ?: details.handle?.schemeSpecificPart?.takeIf { it.isNotBlank() }?.toList()?.joinToString(" ")
                ?: res.getString(R.string.unknown_caller),
        )
        val ringing = { CallManager.idOf(call) != null && CallManager.stateOf(call) == Call.STATE_RINGING }
        val speak = object : Runnable {
            override fun run() {
                if (!ringing()) return
                onTts { speak(text, TextToSpeech.QUEUE_FLUSH, null, "announce") }
                handler.postDelayed(this, ANNOUNCE_EVERY_MS)
            }
        }
        tts?.let { return speak.run() }
        tts = TextToSpeech(this) { status ->
            if (status != TextToSpeech.SUCCESS) return@TextToSpeech
            tts?.setAudioAttributes(
                AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ASSISTANCE_ACCESSIBILITY)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
            )
            speak.run()
        }
    }

    private fun headsetConnected() = getSystemService(AudioManager::class.java)
        .getDevices(AudioManager.GET_DEVICES_OUTPUTS).any { CallPrefs.isHeadset(it.type) }

    /** TelecomManager.showInCallScreen (the return-to-call banner) lands here; without it nothing opens. */
    override fun onBringToForeground(showDialpad: Boolean) {
        if (CallManager.all().isNotEmpty()) InCallActivity.start(this)
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
