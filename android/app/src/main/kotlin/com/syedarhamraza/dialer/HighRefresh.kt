package com.syedarhamraza.dialer

import android.app.Activity
import android.os.Build
import android.provider.Settings
import android.view.Display

/**
 * Asks for the screen's fastest refresh rate the user allows. Flutter doesn't vote, so ColorOS
 * and OxygenOS left the app at 60 Hz even with 120 Hz picked in display settings.
 */
object HighRefresh {
    fun apply(activity: Activity) {
        val display = (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) activity.display else null)
            ?: @Suppress("DEPRECATION") activity.windowManager.defaultDisplay
            ?: return
        val modeId = pick(display.mode, display.supportedModes.toList(), userPeak(activity)) ?: return
        val attributes = activity.window.attributes
        if (attributes.preferredDisplayModeId == modeId) return
        activity.window.attributes = attributes.apply { preferredDisplayModeId = modeId }
    }

    /**
     * Android's "peak_refresh_rate", the cap from the user's display setting; unset means no cap.
     * Android caps app requests at the user's choice itself, so a phone set to 60 Hz stays there.
     */
    private fun userPeak(activity: Activity): Float =
        runCatching { Settings.System.getFloat(activity.contentResolver, "peak_refresh_rate") }
            .getOrNull()?.takeIf { it > 0f } ?: Float.MAX_VALUE

    /** The fastest mode at [current]'s resolution not above [peak], or null when there's none. */
    internal fun pick(current: Display.Mode, modes: List<Display.Mode>, peak: Float): Int? =
        modes.filter {
            it.physicalWidth == current.physicalWidth && it.physicalHeight == current.physicalHeight &&
                it.refreshRate <= peak + 0.5f
        }.maxByOrNull { it.refreshRate }?.modeId
}
