package com.syedarhamraza.recorder

import android.animation.ValueAnimator
import android.graphics.Canvas
import android.graphics.ColorFilter
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.drawable.Drawable
import android.view.MotionEvent
import android.view.View
import kotlin.math.max
import kotlin.math.min

/**
 * One Dialer's PressGlow (the glass package's GlassButton press with no body): while held the
 * button inflates by 17 dp along its longest side on a snappy spring and springs back with one
 * undershoot on release; its surface lifts by 14% white, and a soft light follows the finger.
 */
class PressGlow private constructor(private val view: View, radiusDp: Float?, keepRound: Boolean) {
    // The finger light goes on top; the lift goes under the button's own body, as GlassButton's
    // ambient overlay sits under its content (so an opaque body, like the menu's base, hides it).
    private val overlay = Overlay(view, radiusDp, keepRound)
    private val under = Overlay(view, radiusDp, keepRound)
    private val growth = OneLook.px(view.context, 17f) // LiquidStretch.nativePressGrowth
    private val press = SpringValue(0f) { p ->
        val longest = max(view.width, view.height).toFloat()
        val s = if (longest > 0) 1f + p * growth / longest else 1f
        view.scaleX = s; view.scaleY = s
    }
    private val glowAlpha = SpringValue(0f) { overlay.glow = it; view.invalidate() }
    private val glowX = SpringValue(0f) { overlay.x = it; view.invalidate() }
    private val glowY = SpringValue(0f) { overlay.y = it; view.invalidate() }
    private var lift: ValueAnimator? = null

    init {
        view.foreground = overlay
        val body = view.background
        when {
            body != null -> view.background = android.graphics.drawable.LayerDrawable(arrayOf(under, body))
            view is android.view.ViewGroup -> view.addView(View(view.context).apply { background = under }, 0,
                android.view.ViewGroup.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT))
        }
        view.setOnTouchListener { _, e -> onTouch(e); false }
    }

    /** For views that read the touch themselves (the floating menu's rows). */
    fun onTouch(e: MotionEvent) {
        when (e.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                press.animateTo(1f, PRESS_IN)
                glowX.snapTo(e.x); glowY.snapTo(e.y)
                glowAlpha.animateTo(1f, INTERACTIVE)
                ambient(true)
            }
            MotionEvent.ACTION_MOVE -> {
                glowX.animateTo(e.x, FOLLOW); glowY.animateTo(e.y, FOLLOW)
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                press.animateTo(0f, PRESS_OUT)
                glowAlpha.animateTo(0f, INTERACTIVE)
                ambient(false)
            }
        }
    }

    private fun ambient(on: Boolean) {
        lift?.cancel()
        lift = ValueAnimator.ofFloat(under.lift, if (on) 1f else 0f).apply {
            duration = if (on) 150 else 60
            interpolator = OneLook.easeOut
            addUpdateListener { under.lift = it.animatedValue as Float; under.invalidateSelf(); view.invalidate() }
            start()
        }
    }

    /** The lift and the finger light, clipped to the button's shape, under nothing (foreground). */
    private class Overlay(private val view: View, private val radiusDp: Float?, private val keepRound: Boolean) : Drawable() {
        var lift = 0f
        var glow = 0f
        var x = 0f
        var y = 0f
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val light = OneLook.palette(view.context).light

        override fun draw(canvas: Canvas) {
            if (lift <= 0f && glow <= 0f) return
            val rect = RectF(bounds)
            val shape = Shapes.path(rect, radiusDp?.let { OneLook.px(view.context, it) }, keepRound)
            // Filled in the shape (no clip): a clipped rect leaked out as a grey square on the vivo.
            if (lift > 0f) {
                paint.shader = null
                paint.color = OneLook.withAlpha(0xFFFFFF, (if (light) .3f else .14f) * lift) // ambientBaseLight(Light|Dark)
                canvas.drawPath(shape, paint)
            }
            if (glow > .001f) {
                val r = 1.6f * min(rect.width(), rect.height()) * glow.coerceAtLeast(.01f)
                paint.color = 0xFFFFFFFF.toInt()
                paint.shader = RadialGradient(x, y, r, if (light) OneLook.withAlpha(0x000000, (0x0F / 255f) * glow.coerceIn(0f, 1f))
                    else OneLook.withAlpha(0xFFFFFF, (0x12 / 255f) * glow.coerceIn(0f, 1f)), 0, Shader.TileMode.CLAMP)
                canvas.drawPath(shape, paint)
                paint.shader = null
            }
        }

        // No outline of its own: under a body in a LayerDrawable, the body's outline is the view's.
        override fun getOutline(outline: android.graphics.Outline) = outline.setEmpty()
        override fun setAlpha(alpha: Int) {}
        override fun setColorFilter(colorFilter: ColorFilter?) {}
        @Deprecated("Deprecated in Java") override fun getOpacity() = PixelFormat.TRANSLUCENT
    }

    companion object {
        private val PRESS_IN = Spring.of(250, .25f) // GlassSpring.snappy(250 ms, +0.1)
        private val PRESS_OUT = Spring.of(280, .45f) // GlassSpring.bouncy(280 ms, +0.15)
        private val INTERACTIVE = Spring.of(150, .14f)
        private val FOLLOW = Spring.of(100, 0f)

        /** [radiusDp] in design dp, null for a circle; [keepRound] as SquircleBorder. */
        fun attach(view: View, radiusDp: Float?, keepRound: Boolean = true) = PressGlow(view, radiusDp, keepRound)
    }
}
