package com.syedarhamraza.recorder.shell

import android.accessibilityservice.AccessibilityService
import android.content.ComponentName
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import kotlin.concurrent.thread

/**
 * Optional auto pairing (Setup › Pair automatically): reads the 6-digit code out of Settings'
 * "Pair device with pairing code" dialog and pairs, so nothing is typed. It only reads, never
 * taps, and only Settings' windows (also limited in its config). It switches itself off once
 * paired, or after a few minutes: banking apps refuse enabled accessibility services too.
 * Not the removed microphone accessibility tier.
 */
class PairingAccessibilityService : AccessibilityService() {
    companion object {
        private const val SETTINGS = "com.android.settings"
        private const val TIMEOUT_MS = 5 * 60_000L
        private val CODE = Regex("""^(\d{3}) ?(\d{3})$""")

        /** The pairing code among a dialog's texts: six digits on their own (ports are five, addresses have dots). */
        fun pairingCode(texts: List<String>): String? =
            texts.firstNotNullOfOrNull { CODE.matchEntire(it.trim())?.let { m -> m.groupValues[1] + m.groupValues[2] } }

        fun component(context: Context) = ComponentName(context, PairingAccessibilityService::class.java)

        /** Turns the service on without the Accessibility screen; only once One Recorder holds WRITE_SECURE_SETTINGS. */
        fun enable(context: Context): Boolean = runCatching {
            val resolver = context.contentResolver
            val name = component(context).flattenToString()
            val list = Settings.Secure.getString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES).orEmpty()
            if (name !in list.split(':')) {
                Settings.Secure.putString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                    if (list.isEmpty()) name else "$list:$name")
            }
            Settings.Secure.putInt(resolver, Settings.Secure.ACCESSIBILITY_ENABLED, 1)
        }.isSuccess
    }

    private val handler = Handler(Looper.getMainLooper())
    private var tried: String? = null
    @Volatile private var pairing = false

    override fun onServiceConnected() {
        super.onServiceConnected()
        handler.postDelayed({ disableSelf() }, TIMEOUT_MS)
        if (ShellHelper.paired(this)) return disableSelf()
        // Straight on to the pairing dialog; the notification stays as the fallback.
        ShellHelper.askForPairingCode(this)
        startActivity(ShellHelper.wirelessDebuggingIntent())
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (pairing || event?.packageName != SETTINGS) return
        val texts = mutableListOf<String>()
        for (window in runCatching { windows }.getOrNull().orEmpty()) {
            val root = window.root ?: continue
            if (root.packageName == SETTINGS) collect(root, texts)
        }
        val code = pairingCode(texts)?.takeIf { it != tried } ?: return
        tried = code
        pairing = true
        val app = applicationContext
        thread {
            val ok = ShellHelper.pair(app, code)
            handler.post {
                pairing = false
                if (ok) disableSelf()
            }
        }
    }

    private fun collect(node: AccessibilityNodeInfo, into: MutableList<String>) {
        node.text?.let { into += it.toString() }
        for (i in 0 until node.childCount) node.getChild(i)?.let { collect(it, into) }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}
