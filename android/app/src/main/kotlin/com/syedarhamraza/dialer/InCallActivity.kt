package com.syedarhamraza.dialer

import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.Bundle
import android.view.MotionEvent
import androidx.core.view.WindowCompat
import androidx.lifecycle.Lifecycle
import android.telecom.VideoProfile
import com.syedarhamraza.dialer.telecom.CallActionReceiver
import com.syedarhamraza.dialer.telecom.CallManager
import com.syedarhamraza.dialer.telecom.CallNotifications
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Hosts the in-call Flutter UI on the cached [InCallEngine]; shows over the lock screen. The window
 * is opaque black; Flutter paints the call screen's own gradient backdrop over it.
 */
class InCallActivity : FlutterActivity() {

    override fun onResume() {
        super.onResume()
        LagDiagnostics.foreground("in_call", true)
    }

    override fun onPause() {
        LagDiagnostics.foreground("in_call", false)
        super.onPause()
    }

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        LagDiagnostics.touch("in_call", event)
        return super.dispatchTouchEvent(event)
    }

    private val closeWhenIdle = { if (!CallManager.isShowingCalls) finish() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.enableEdgeToEdge(window)
        CallManager.addListener(closeWhenIdle)
        answerFrom(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        answerFrom(intent)
    }

    /** The incoming notification's Answer opens this screen (see [CallActionReceiver.answerIntent]). */
    private fun answerFrom(intent: Intent) {
        if (intent.action != CallActionReceiver.ACTION_ANSWER) return
        // Once only: a recreated activity gets the same intent again.
        intent.action = null
        intent.getStringExtra(CallActionReceiver.EXTRA_CALL_ID)?.let(CallManager::get)
            ?.answer(VideoProfile.STATE_AUDIO_ONLY)
        CallNotifications.cancelIncoming(this)
    }

    override fun onStart() {
        super.onStart()
        setFullScreen(!isInMultiWindowMode)
    }

    override fun onStop() {
        setFullScreen(false)
        super.onStop()
    }

    // vivo's small floating window and picture-in-picture are multi-window: no ear sensor there.
    override fun onMultiWindowModeChanged(isInMultiWindowMode: Boolean, newConfig: Configuration) {
        super.onMultiWindowModeChanged(isInMultiWindowMode, newConfig)
        if (lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) setFullScreen(!isInMultiWindowMode)
    }

    private fun setFullScreen(shown: Boolean) {
        isFullScreen = shown
        CallManager.service?.updateProximity()
    }

    override fun onDestroy() {
        CallManager.removeListener(closeWhenIdle)
        super.onDestroy()
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine = InCallEngine.ensure(context)

    // The engine outlives the screen so the next call opens instantly.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    companion object {
        /** Whether the call screen is up and full-screen; the ear sensor only runs then. */
        var isFullScreen = false
            private set

        fun intent(context: Context): Intent =
            Intent(context, InCallActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION)

        fun start(context: Context) = context.startActivity(intent(context))
    }
}
