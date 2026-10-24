package com.syedarhamraza.dialer

import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.lifecycle.Lifecycle
import android.telecom.VideoProfile
import com.syedarhamraza.dialer.telecom.CallActionReceiver
import com.syedarhamraza.dialer.telecom.CallManager
import com.syedarhamraza.dialer.telecom.CallNotifications
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import java.util.function.Consumer

/**
 * Hosts the in-call Flutter UI on the cached [InCallEngine]; shows over the lock screen.
 *
 * Its theme (`InCallTheme`) shows the wallpaper behind the window, and on Android 12+ the system
 * blurs it (see [WallpaperBackdrop]); the Flutter view is transparent so it shows through.
 */
class InCallActivity : FlutterActivity() {

    private val closeWhenIdle = { if (!CallManager.isShowingCalls) finish() }

    /** Blur is switched off in battery saver and on some devices; follow it as it changes. */
    private val blurListener = Consumer<Boolean> { enabled ->
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            window.setBackgroundBlurRadius(if (enabled) BLUR_RADIUS else 0)
        }
        WallpaperBackdrop.setBlur(enabled)
    }

    /**
     * Over the lock screen Android shows the lock-screen wallpaper behind us; unlocked, we want
     * the home one. So the window only asks to show when locked while the phone is locked: it asks
     * again the moment the screen goes off (before the keyguard comes up) and lets go on unlock.
     */
    private val lockChanges = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) =
            setShowWhenLocked(intent.action == Intent.ACTION_SCREEN_OFF)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.enableEdgeToEdge(window)
        CallManager.addListener(closeWhenIdle)
        if (!getSystemService(KeyguardManager::class.java).isKeyguardLocked) setShowWhenLocked(false)
        registerReceiver(
            lockChanges,
            IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_USER_PRESENT)
            },
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Called right away with the current state, then on every change.
            windowManager.addCrossWindowBlurEnabledListener(blurListener)
        }
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
        if (WallpaperBackdrop.isLive(this)) {
            WallpaperBackdrop.setCover(true)
            // In case no enter animation runs (onEnterAnimationComplete may not come).
            window.decorView.postDelayed(uncover, UNCOVER_FALLBACK_MS)
        }
    }

    private val uncover = Runnable { WallpaperBackdrop.setCover(false) }

    // The live wallpaper goes black right as the open animation ends, for ~0.2 s while it redraws
    // (seen on vivo's LightShadow); keep the cover a little past that, then Flutter fades it out.
    override fun onEnterAnimationComplete() {
        super.onEnterAnimationComplete()
        window.decorView.removeCallbacks(uncover)
        window.decorView.postDelayed(uncover, UNCOVER_AFTER_ANIMATION_MS)
    }

    override fun onStop() {
        window.decorView.removeCallbacks(uncover)
        WallpaperBackdrop.setCover(false)
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

    override fun onResume() {
        super.onResume()
        // Unlocked again (after a screen-off): back to the home wallpaper.
        if (!getSystemService(KeyguardManager::class.java).isKeyguardLocked) setShowWhenLocked(false)
    }

    override fun onDestroy() {
        unregisterReceiver(lockChanges)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            windowManager.removeCrossWindowBlurEnabledListener(blurListener)
        }
        CallManager.removeListener(closeWhenIdle)
        super.onDestroy()
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine = InCallEngine.ensure(context)

    // The engine outlives the screen so the next call opens instantly.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    // Transparent, so the blurred wallpaper behind the window shows through.
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    // Transparent mode would default to a TextureView (an extra copy every frame); a transparent
    // SurfaceView keeps the fast path.
    override fun getRenderMode(): RenderMode = RenderMode.surface

    companion object {
        /** Whether the call screen is up and full-screen; the ear sensor only runs then. */
        var isFullScreen = false
            private set

        /** Heavy, like ColorOS: only the wallpaper's colours and shapes survive. */
        private const val BLUR_RADIUS = 120

        private const val UNCOVER_AFTER_ANIMATION_MS = 450L
        private const val UNCOVER_FALLBACK_MS = 1500L

        fun intent(context: Context): Intent =
            Intent(context, InCallActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION)

        fun start(context: Context) = context.startActivity(intent(context))
    }
}
