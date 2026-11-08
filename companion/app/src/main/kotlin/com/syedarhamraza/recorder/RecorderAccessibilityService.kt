package com.syedarhamraza.recorder

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

/**
 * Does nothing and reads nothing. Android 10+ lets an app with an enabled accessibility
 * service hear the microphone during a call; that is this service's only purpose.
 */
class RecorderAccessibilityService : AccessibilityService() {
    override fun onServiceConnected() = RecordingsProvider.notifyStatus(this)
    override fun onAccessibilityEvent(event: AccessibilityEvent?) = Unit
    override fun onInterrupt() = Unit
    override fun onUnbind(intent: android.content.Intent?): Boolean {
        RecordingsProvider.notifyStatus(this)
        return super.onUnbind(intent)
    }
}
