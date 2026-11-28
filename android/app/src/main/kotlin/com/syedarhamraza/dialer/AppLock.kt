package com.syedarhamraza.dialer

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.hardware.biometrics.BiometricManager
import android.hardware.biometrics.BiometricPrompt
import android.os.Build
import android.os.CancellationSignal
import android.view.WindowManager

/**
 * Settings › Privacy & security › App lock and the private vault: the phone's own fingerprint,
 * face or screen lock, so the app keeps no secret of its own. When to lock is decided in Dart
 * (`lib/core/security/app_lock.dart`); this side tells it when going to the background isn't
 * leaving the app.
 */
object AppLock {

    /** Set while one of our own pickers or the unlock prompt covers the app: that's not leaving it. */
    var expectReturn = false

    /** App lock needs a screen lock: without one, the prompt would have nothing to ask. */
    fun available(context: Context): Boolean =
        context.getSystemService(KeyguardManager::class.java).isDeviceSecure

    /** Hides the app from the recents thumbnail (and, before Android 13, from screenshots). */
    fun setSecure(activity: Activity, on: Boolean) {
        if (Build.VERSION.SDK_INT >= 33) {
            activity.setRecentsScreenshotEnabled(!on)
        } else if (on) {
            activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    /** Fingerprint or face, with the phone's PIN, pattern or password as the fallback. */
    fun authenticate(activity: Activity, title: String, done: (Boolean) -> Unit) {
        if (!available(activity)) return done(false)
        val builder = BiometricPrompt.Builder(activity).setTitle(title)
        if (Build.VERSION.SDK_INT >= 30) {
            builder.setAllowedAuthenticators(
                BiometricManager.Authenticators.BIOMETRIC_WEAK or BiometricManager.Authenticators.DEVICE_CREDENTIAL,
            )
        } else {
            @Suppress("DEPRECATION")
            builder.setDeviceCredentialAllowed(true)
        }
        expectReturn = true
        var answered = false
        fun answer(ok: Boolean) {
            if (answered) return
            answered = true
            expectReturn = false
            done(ok)
        }
        runCatching {
            builder.build().authenticate(
                CancellationSignal(),
                activity.mainExecutor,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) = answer(true)

                    // Cancelled, too many tries, or no way to ask; a single wrong finger only retries.
                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        android.util.Log.i("AppLock", "Unlock prompt closed: $errorCode $errString")
                        answer(false)
                    }
                },
            )
        }.onFailure {
            android.util.Log.w("AppLock", "Couldn't show the unlock prompt", it)
            answer(false)
        }
    }
}
