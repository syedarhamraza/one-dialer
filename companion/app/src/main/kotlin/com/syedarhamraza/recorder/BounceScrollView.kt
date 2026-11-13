package com.syedarhamraza.recorder

import android.content.Context
import android.os.SystemClock
import android.view.MotionEvent
import android.view.ViewConfiguration
import android.widget.ScrollView
import kotlin.math.abs
import kotlin.math.pow
import kotlin.math.sign

/**
 * One Dialer's OneUIScrollPhysics on a ScrollView: every page bounces at its ends, even one with
 * nothing to scroll. The pull past an end follows the finger by 0.32 (1 - f)² (f the overscroll
 * as a share of the page), a fling that hits an end carries on past it, and both come back on a
 * spring of mass 0.5, stiffness 150, damping ratio 1.1.
 */
class BounceScrollView(context: Context) : ScrollView(context) {
    /** How far the content is pulled past an end: positive at the top, negative at the bottom. */
    var pull = 0f
        private set

    /** Called on every scroll or pull, with the content's visible offset (scroll minus pull). */
    var onMoved: (() -> Unit)? = null

    private val slop = ViewConfiguration.get(context).scaledTouchSlop
    private val back = SpringValue(0f) { setPull(it) }
    private var downY = 0f
    private var lastY = 0f
    private var touching = false
    private var lastScrollY = 0
    private var lastScrollTime = 0L
    private var scrollSpeed = 0f

    init {
        overScrollMode = OVER_SCROLL_NEVER
        isVerticalScrollBarEnabled = false
    }

    private fun atTop() = !canScrollVertically(-1)
    private fun atBottom() = !canScrollVertically(1)

    private fun setPull(value: Float) {
        pull = value
        getChildAt(0)?.translationY = value
        onMoved?.invoke()
    }

    override fun onInterceptTouchEvent(e: MotionEvent): Boolean {
        when (e.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downY = e.y; lastY = e.y; touching = true
                if (pull != 0f) { back.stop(); return true } // catch it mid-bounce
            }
            MotionEvent.ACTION_MOVE -> {
                val dy = e.y - downY
                if (abs(dy) > slop && ((dy > 0 && atTop()) || (dy < 0 && atBottom()))) {
                    lastY = e.y
                    return true
                }
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> touching = false
        }
        return super.onInterceptTouchEvent(e)
    }

    override fun onTouchEvent(e: MotionEvent): Boolean {
        when (e.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                touching = true; lastY = e.y; back.stop()
            }
            MotionEvent.ACTION_MOVE -> {
                val dy = e.y - lastY
                lastY = e.y
                if (pull != 0f || (dy > 0 && atTop()) || (dy < 0 && atBottom())) {
                    val f = (abs(pull) / height.coerceAtLeast(1)).coerceIn(0f, 1f)
                    var next = pull + dy * .32f * (1 - f).pow(2)
                    // Pushed back past the edge: the rest scrolls the page as usual.
                    if (pull != 0f && sign(next) != sign(pull)) next = 0f
                    setPull(next)
                    return true
                }
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                touching = false
                if (pull != 0f) {
                    back.animateFrom(pull, 0f, 0f, SPRING)
                    return true
                }
            }
        }
        return super.onTouchEvent(e)
    }

    override fun onScrollChanged(l: Int, t: Int, oldl: Int, oldt: Int) {
        super.onScrollChanged(l, t, oldl, oldt)
        val now = SystemClock.uptimeMillis()
        val dt = (now - lastScrollTime).coerceAtLeast(1)
        scrollSpeed = (t - lastScrollY) * 1000f / dt
        lastScrollY = t; lastScrollTime = now
        // A fling that reaches an end carries on past it and springs back.
        val max = (getChildAt(0)?.height ?: 0) - height
        if (!touching && pull == 0f && abs(scrollSpeed) > 300f && ((t <= 0 && oldt > 0) || (t >= max && oldt < max))) {
            back.animateFrom(0f, -scrollSpeed, 0f, SPRING)
        }
        onMoved?.invoke()
    }

    private companion object {
        val SPRING = Spring.withRatio(.5f, 150f, 1.1f)
    }
}
