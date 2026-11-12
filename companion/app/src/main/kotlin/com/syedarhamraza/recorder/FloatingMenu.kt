package com.syedarhamraza.recorder

import android.animation.ValueAnimator
import android.app.Activity
import android.app.Dialog
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.LayerDrawable
import android.text.TextUtils
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.view.WindowManager
import android.view.animation.LinearInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min

/**
 * One Dialer's OneUIFloatingMenu as a choice picker (choiceRow): a frosted call-glass card beside
 * the value that opened it, below it or above when it sits low. It pops from the point nearest the
 * value (from 20%, fading in over the first 28%, on a spring with a ~1.5% overshoot over 400 ms)
 * and shrinks back there on close (170 ms). Touching it shows a pill highlight under the finger
 * that springs row to row; lifting picks the row, lifting off the card picks nothing.
 */
class FloatingMenu(
    private val activity: Activity,
    private val anchor: View,
    private val labels: List<String>,
    private val selected: Int,
    private val onPick: (Int) -> Unit,
) {
    private fun d(v: Float) = OneLook.px(activity, v)
    private val row = d(48f)
    private val pad = d(6f)
    private var closing = false

    private val dialog = object : Dialog(activity, android.R.style.Theme_Translucent_NoTitleBar) {
        override fun cancel() = close(null) // Back
    }
    private val root = FrameLayout(activity)
    private val pop = FrameLayout(activity).apply { alpha = 0f }

    fun show() {
        val card = Card()
        pop.addView(card, FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))
        root.addView(pop, FrameLayout.LayoutParams(0, 0))
        root.setOnClickListener { close(null) } // tap outside
        dialog.setContentView(root)
        dialog.window?.apply {
            setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
            setLayout(MATCH_PARENT, MATCH_PARENT)
            clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
            addFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)
            setWindowAnimations(0)
        }
        root.post { place(); open() }
        anchor.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY) // Haptics.tap
        dialog.show()
    }

    /** Where OneUIFloatingMenu.show puts it, and the pivot it grows from. */
    private fun place() {
        val r = IntArray(2).also { root.getLocationOnScreen(it) }
        val a = IntArray(2).also { anchor.getLocationOnScreen(it) }
        val aLeft = (a[0] - r[0]).toFloat()
        val aTop = (a[1] - r[1]).toFloat()
        val aRight = aLeft + anchor.width
        val aBottom = aTop + anchor.height
        val screenW = root.width.toFloat()
        val screenH = root.height.toFloat()
        val insets = root.rootWindowInsets
        @Suppress("DEPRECATION") val insetTop = insets?.systemWindowInsetTop ?: 0
        @Suppress("DEPRECATION") val insetBottom = insets?.systemWindowInsetBottom ?: 0
        val edge = d(16f)
        val gap = d(10f)
        val w = min(d(250f), screenW - edge * 2)
        val h = labels.size * row + pad * 2
        val minTop = insetTop + edge
        val maxBottom = screenH - insetBottom - edge
        val roomAbove = aTop - gap - minTop
        val roomBelow = maxBottom - aBottom - gap
        val upwards = if ((aTop + aBottom) / 2 > screenH / 2) roomAbove >= h || roomAbove >= roomBelow
        else roomBelow < h && roomAbove > roomBelow
        val right = aRight.coerceIn(edge + w, screenW - edge)
        val top = (if (upwards) aTop - gap - h else aBottom + gap).coerceIn(minTop, max(minTop, maxBottom - h))
        val left = right - w
        pop.layoutParams = FrameLayout.LayoutParams(w.toInt(), h.toInt()).apply {
            leftMargin = left.toInt(); topMargin = top.toInt()
        }
        pop.pivotX = ((aLeft + aRight) / 2).coerceIn(left, right) - left
        pop.pivotY = if (upwards) h else 0f
    }

    private fun open() {
        val spring = SpringCurve(Spring.withRatio(1f, 320f, .8f), 400)
        animate(0f, 1f, 400) { v ->
            val scale = START + (1 - START) * spring.getInterpolation(v)
            pop.scaleX = scale; pop.scaleY = scale
            pop.alpha = OneLook.easeOut.getInterpolation((v / .28f).coerceIn(0f, 1f))
        }
    }

    private fun close(then: (() -> Unit)?) {
        if (closing) return
        closing = true
        animate(1f, 0f, 170, onEnd = { dialog.dismiss() }) { v ->
            val scale = START + (1 - START) * OneLook.easeIn.getInterpolation(v)
            pop.scaleX = scale; pop.scaleY = scale
            pop.alpha = OneLook.easeOut.getInterpolation(((v - .3f) / .7f).coerceIn(0f, 1f))
        }
        then?.invoke()
    }

    private fun animate(from: Float, to: Float, ms: Long, onEnd: (() -> Unit)? = null, step: (Float) -> Unit) {
        ValueAnimator.ofFloat(from, to).apply {
            duration = ms
            interpolator = LinearInterpolator()
            addUpdateListener { step(it.animatedValue as Float) }
            if (onEnd != null) addListener(object : android.animation.AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: android.animation.Animator) = onEnd()
            })
            start()
        }
    }

    /** The card: a nearly black base under the header pills' call glass, the rows and their highlight. */
    private inner class Card : FrameLayout(activity) {
        private val highlight = View(activity).apply {
            background = ShapeFill(0x3DFFFFFF, row / 2)
            alpha = 0f
        }
        private val press: PressGlow
        private var current = -1
        private var slide: ValueAnimator? = null
        private var fade: ValueAnimator? = null

        init {
            val glass = GlassBody(activity, row / 2 / OneLook.px(activity, 1f) + 6f)
            background = LayerDrawable(arrayOf(ColorDrawable(0xE6000000.toInt()), glass))
            outlineProvider = object : android.view.ViewOutlineProvider() {
                override fun getOutline(view: View, outline: android.graphics.Outline) {
                    glass.bounds = android.graphics.Rect(0, 0, view.width, view.height)
                    glass.getOutline(outline)
                }
            }
            clipToOutline = true
            setPadding(pad.toInt(), pad.toInt(), pad.toInt(), pad.toInt())
            addView(highlight, LayoutParams(MATCH_PARENT, row.toInt()))
            addView(LinearLayout(activity).apply {
                orientation = LinearLayout.VERTICAL
                labels.forEachIndexed { i, label -> addView(rowView(label, i == selected), LinearLayout.LayoutParams(MATCH_PARENT, row.toInt())) }
            }, LayoutParams(MATCH_PARENT, WRAP_CONTENT))
            press = PressGlow.attach(this, row / 2 / OneLook.px(activity, 1f) + 6f, keepRound = false)
        }

        private fun rowView(label: String, checked: Boolean) = LinearLayout(activity).apply {
            gravity = Gravity.CENTER_VERTICAL
            setPadding(d(16f).toInt(), 0, d(16f).toInt(), 0)
            addView(ImageView(activity).apply { setImageDrawable(Glyph.radio(Color.WHITE, checked)) },
                LinearLayout.LayoutParams(d(22f).toInt(), d(22f).toInt()).apply { marginEnd = d(14f).toInt() })
            addView(TextView(activity).apply {
                text = label
                maxLines = 1
                ellipsize = TextUtils.TruncateAt.END
                OneLook.style(this, 16f, Color.WHITE, 500, -.2f)
            }, LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f))
        }

        private fun rowAt(y: Float) = floor(y / row).toInt().coerceIn(0, labels.size - 1)

        private fun show(on: Boolean) {
            fade?.cancel()
            fade = ValueAnimator.ofFloat(highlight.alpha, if (on) 1f else 0f).apply {
                duration = 120
                addUpdateListener { highlight.alpha = it.animatedValue as Float }
                start()
            }
        }

        override fun onTouchEvent(e: MotionEvent): Boolean {
            val y = e.y - pad
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    current = rowAt(y)
                    slide?.cancel()
                    highlight.translationY = current * row // the first touch: straight under the finger
                    show(true)
                }
                MotionEvent.ACTION_MOVE -> {
                    val i = rowAt(y)
                    if (i != current) {
                        current = i
                        slide?.cancel()
                        // FilterTabs.thumbSpring: swings past the row and settles back.
                        slide = ValueAnimator.ofFloat(highlight.translationY, i * row).apply {
                            duration = 600
                            interpolator = THUMB
                            addUpdateListener { highlight.translationY = it.animatedValue as Float }
                            start()
                        }
                    }
                }
                MotionEvent.ACTION_UP -> {
                    show(false)
                    val inside = e.x in 0f..width.toFloat() && y in -pad..(labels.size * row + pad)
                    if (inside) {
                        val i = rowAt(y)
                        performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                        close { onPick(i) }
                    }
                }
                MotionEvent.ACTION_CANCEL -> show(false)
            }
            return true
        }
    }

    private companion object {
        const val START = .2f
        val THUMB = SpringCurve(Spring.withRatio(1f, 260f, .6f), 600)
    }
}
