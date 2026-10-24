package com.syedarhamraza.dialer

import android.app.WallpaperManager
import android.content.Context
import android.os.Build
import android.view.WindowManager

/**
 * The call screen's backdrop, as on ColorOS 17: the system wallpaper drawn behind [InCallActivity]
 * (its theme shows the wallpaper) and blurred by the compositor when the device allows
 * cross-window blur. When it doesn't (Android < 12, battery saver, unsupported devices), Flutter
 * paints a gradient from the wallpaper's main colours instead.
 *
 * The wallpaper bitmap itself is never read: that needs "All files access" on Android 13+.
 */
object WallpaperBackdrop {
    /** Whether the system is blurring the wallpaper behind the call window right now. */
    var blur = false
        private set

    /** Whether [InCallActivity] has reported [blur] yet. */
    private var reported = false

    private val listeners = mutableSetOf<() -> Unit>()

    fun addListener(listener: () -> Unit) {
        listeners += listener
    }

    fun removeListener(listener: () -> Unit) {
        listeners -= listener
    }

    /** Reported by [InCallActivity] from the window manager's cross-window blur listener. */
    fun setBlur(enabled: Boolean) {
        val first = !reported
        reported = true
        if (blur == enabled && !first) return
        blur = enabled
        notifyChanged()
    }

    private fun systemBlur(context: Context) = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
        context.getSystemService(WindowManager::class.java)?.isCrossWindowBlurEnabled == true

    fun notifyChanged() = listeners.toList().forEach { it() }

    /** `{blur: Boolean, colors: [argb…]}` for Flutter; colours need no permission (API 27+). */
    fun snapshot(context: Context): Map<String, Any> {
        val colors = try {
            WallpaperManager.getInstance(context).getWallpaperColors(WallpaperManager.FLAG_SYSTEM)
        } catch (_: Exception) {
            null
        }
        return mapOf(
            // The engine is warmed before the call window exists; ask the system then, so the
            // first frame doesn't paint the dark fallback and flash black before the wallpaper.
            "blur" to if (reported) blur else systemBlur(context),
            "colors" to listOfNotNull(colors?.primaryColor, colors?.secondaryColor, colors?.tertiaryColor)
                // As unsigned ARGB, which Dart's Color takes as is.
                .map { it.toArgb().toLong() and 0xFFFFFFFFL },
        )
    }
}
