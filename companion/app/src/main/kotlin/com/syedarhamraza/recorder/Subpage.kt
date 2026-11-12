package com.syedarhamraza.recorder

import android.app.Activity
import android.content.res.ColorStateList
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.graphics.RenderEffect
import android.graphics.Shader
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.Drawable
import android.graphics.drawable.RippleDrawable
import android.os.Build
import android.text.TextUtils
import android.view.Gravity
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

/**
 * One Dialer's OneUISubpage (CosSubpage) as plain views: black, the round call-glass Back button
 * with the title beside it pinned at the top over ColorOS 17's header blur, and the cards
 * scrolling (and bouncing) under it. Build rows into [content] with the helpers below.
 */
class Subpage(private val activity: Activity, title: String, onBack: () -> Unit) {
    val content = LinearLayout(activity).apply {
        orientation = LinearLayout.VERTICAL
        clipChildren = false
        clipToPadding = false
    }
    val scroll = BounceScrollView(activity).apply {
        clipChildren = false
        addView(content)
    }
    // Not clipping children: a pressed button grows 17 dp past its slot (PressGlow), as in One Dialer.
    private val p = OneLook.palette(activity)
    val root = FrameLayout(activity).apply { setBackgroundColor(p.page); clipChildren = false }
    private val scrim = FrameLayout(activity)
    private val mirrors = mutableListOf<View>()

    private fun d(v: Float) = OneLook.px(activity, v)
    private fun di(v: Float) = d(v).toInt()

    init {
        val w = activity.window
        w.statusBarColor = Color.TRANSPARENT
        w.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= 29) w.isNavigationBarContrastEnforced = false
        @Suppress("DEPRECATION")
        w.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            (if (p.light) View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR or View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR else 0)

        // The header blur: the page itself, drawn again behind the header and blurred
        // (shaders/progressive_blur.frag's light blur plus more toward the top, fading out at
        // the bottom). Android has no backdrop blur for views, so it's a blurred copy.
        if (Build.VERSION.SDK_INT >= 31) {
            scrim.addView(fade(mirror(7f), extra = false))
            scrim.addView(fade(mirror(7f + 12f), extra = true))
        }
        scrim.addView(Tint())
        scroll.onMoved = { mirrors.forEach { it.invalidate() } }
        content.addOnLayoutChangeListener { _, _, _, _, _, _, _, _, _ -> mirrors.forEach { it.invalidate() } }

        val header = LinearLayout(activity).apply {
            gravity = Gravity.CENTER_VERTICAL
            clipChildren = false
            clipToPadding = false
            addView(backButton(onBack), LinearLayout.LayoutParams(di(48f), di(48f)))
            addView(TextView(activity).apply {
                text = title
                maxLines = 1
                ellipsize = TextUtils.TruncateAt.END
                OneLook.style(this, 22f, p.text, 600, -.3f)
            }, LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f).apply { marginStart = di(14f) })
        }
        root.addView(scroll, FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))
        root.addView(scrim, FrameLayout.LayoutParams(MATCH_PARENT, 0))
        root.addView(header, FrameLayout.LayoutParams(MATCH_PARENT, di(48f)))
        root.setOnApplyWindowInsetsListener { _, insets ->
            @Suppress("DEPRECATION") val top = insets.systemWindowInsetTop
            @Suppress("DEPRECATION") val bottom = insets.systemWindowInsetBottom
            scrim.layoutParams = (scrim.layoutParams as FrameLayout.LayoutParams).apply { height = top + di(80f) }
            header.layoutParams = (header.layoutParams as FrameLayout.LayoutParams).apply {
                topMargin = top + di(8f); leftMargin = di(16f); rightMargin = di(16f)
            }
            content.setPadding(di(16f), top + di(8f + 48f + 20f), di(16f), bottom + di(32f))
            insets
        }
        activity.setContentView(root)
    }

    /** RoundIconButton: a 48 dp circle of call glass with the 26 dp back arrow. */
    private fun backButton(onBack: () -> Unit): View {
        val button = FrameLayout(activity).apply {
            background = OneLook.glass(activity, null)
            clipToOutline = true
            contentDescription = activity.getString(R.string.back)
            addView(ImageView(activity).apply { setImageDrawable(Glyph.back(p.text)) },
                FrameLayout.LayoutParams(di(26f), di(26f), Gravity.CENTER))
            PressGlow.attach(this, null)
            setOnClickListener { onBack() }
        }
        return withShadow(button, null, keepRound = true)
    }

    /** Light mode's glass shadow under [view], outside its press (CallGlass, unlit GlowButton). */
    private fun withShadow(view: View, radiusDp: Float?, keepRound: Boolean): View {
        if (!p.light) return view
        return FrameLayout(activity).apply {
            clipChildren = false
            addView(ShadowView(activity, radiusDp, keepRound, OneLook.LIGHT_GLASS_SHADOW), FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))
            addView(view, FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))
        }
    }

    /** The page's content drawn where it scrolls under the header, blurred by [sigma]. */
    private fun mirror(sigma: Float): View = object : View(activity) {
        override fun onDraw(canvas: Canvas) {
            canvas.save()
            canvas.translate(0f, content.top + content.translationY - scroll.scrollY)
            content.draw(canvas)
            canvas.restore()
        }
    }.apply {
        if (Build.VERSION.SDK_INT >= 31) {
            val r = OneLook.blurRadius(d(sigma))
            setRenderEffect(RenderEffect.createBlurEffect(r, r, Shader.TileMode.CLAMP))
        }
        mirrors += this
    }

    /** Fades a blurred copy out: the base one over the bottom 40%, the extra one by 70% down. */
    private fun fade(child: View, extra: Boolean) = object : FrameLayout(activity) {
        private val mask = Paint().apply { xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_IN) }

        override fun dispatchDraw(canvas: Canvas) {
            val h = height.toFloat()
            val save = canvas.saveLayer(0f, 0f, width.toFloat(), h, null)
            canvas.drawColor(p.page) // the copy sits on the page colour
            super.dispatchDraw(canvas)
            val stops = FloatArray(11) { it / 10f }
            val alphas = IntArray(11) { i ->
                val t = stops[i]
                val a = (1 - smooth(.6f, 1f, t)) * if (extra) 1 - smooth(0f, .7f, t) else 1f
                OneLook.withAlpha(0, a)
            }
            mask.shader = LinearGradient(0f, 0f, 0f, h, alphas, stops, Shader.TileMode.CLAMP)
            canvas.drawRect(0f, 0f, width.toFloat(), h, mask)
            canvas.restoreToCount(save)
        }
    }.apply {
        setWillNotDraw(false)
        addView(child, FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))
    }

    private fun smooth(a: Float, b: Float, x: Float): Float {
        val t = ((x - a) / (b - a)).coerceIn(0f, 1f)
        return t * t * (3 - 2 * t)
    }

    /** OneUIStatusBarScrim.topGradient in the page colour (palette.tint): strong under the status bar, gone by the bottom. */
    private inner class Tint : View(activity) {
        private val paint = Paint()
        override fun onDraw(canvas: Canvas) {
            paint.shader = LinearGradient(0f, 0f, 0f, height.toFloat(),
                intArrayOf(OneLook.withAlpha(p.page, .8f), OneLook.withAlpha(p.page, .55f), OneLook.withAlpha(p.page, .2f), OneLook.withAlpha(p.page, 0f)),
                floatArrayOf(0f, .4f, .75f, 1f), Shader.TileMode.CLAMP)
            canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        }
    }

    // ---- OneUIGroupCard ----

    /** A flat grey squircle card of [items], split by inset dividers, with an optional grey header. */
    fun group(items: List<View>, header: String? = null) {
        if (header != null) content.addView(TextView(activity).apply {
            text = header
            OneLook.style(this, 15f, p.text2)
            setPadding(di(18f), di(4f), 0, di(8f))
        })
        val card = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            background = ShapeFill(p.card, d(OneLook.RADIUS_CARD))
            clipToOutline = true
        }
        items.forEachIndexed { i, item ->
            card.addView(item)
            if (i < items.size - 1) card.addView(View(activity).apply { setBackgroundColor(p.divider) },
                LinearLayout.LayoutParams(MATCH_PARENT, d(.8f).toInt().coerceAtLeast(1)).apply {
                    marginStart = di(18f); marginEnd = di(18f)
                })
        }
        content.addView(card, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { bottomMargin = di(20f) })
    }

    /**
     * OneUIGroupItemTile: title, optional subtitle, then [value] in grey and a chevron when it
     * opens something. [anchor] receives the value's view (choice rows open their menu from it).
     */
    fun row(
        title: String,
        subtitle: String? = null,
        subtitleColor: Int? = null,
        value: String? = null,
        anchor: ((View) -> Unit)? = null,
        onTap: (() -> Unit)? = null,
    ): View = LinearLayout(activity).apply {
        gravity = Gravity.CENTER_VERTICAL
        setPadding(di(18f), di(17f), di(18f), di(17f))
        addView(LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            addView(TextView(activity).apply {
                text = title
                OneLook.style(this, 17f, p.text, 400, -.2f, 1.25f)
            })
            if (subtitle != null) addView(TextView(activity).apply {
                text = subtitle
                OneLook.style(this, 13.5f, subtitleColor ?: p.text2, 400, 0f, 1.25f)
                setPadding(0, di(1f), 0, 0)
            })
        }, LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f).apply { marginEnd = di(14f) })
        if (value != null) {
            val v = TextView(activity).apply {
                text = value
                maxLines = 1
                ellipsize = TextUtils.TruncateAt.END
                maxWidth = di(180f)
                OneLook.style(this, 15f, p.text2)
            }
            addView(v, LinearLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT).apply { marginEnd = di(4f) })
            anchor?.invoke(v)
        }
        if (onTap != null) {
            addView(ImageView(activity).apply { setImageDrawable(Glyph.chevron(p.text2)) }, LinearLayout.LayoutParams(di(22f), di(22f)))
            // InkWell: the text colour at 6% (white on dark cards, black on light ones).
            background = RippleDrawable(ColorStateList.valueOf(OneLook.withAlpha(p.text, .06f)), null, ColorDrawable(Color.WHITE))
            isClickable = true
            setOnClickListener { onTap() }
        }
    }

    // ---- GlowButton ----

    /**
     * GlowButton, 54 dp: [lit] is the keypad Call button's green (a flat fill, a thin rim light
     * on top and brighter green underneath, two soft green shadows); unlit is call glass.
     */
    fun glowButton(label: String, lit: Boolean, onTap: () -> Unit): View {
        val height = 54f
        val body = TextView(activity).apply {
            text = label
            gravity = Gravity.CENTER
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
            OneLook.style(this, 17f, if (lit) Color.WHITE else p.text, 600)
            setPadding(di(24f), 0, di(24f), 0)
            val look: Drawable = if (lit) LitBody(OneLook.CALL_GREEN) else OneLook.glass(activity, height / 2)
            // Unlit glass is white in light mode: press it dark.
            background = RippleDrawable(ColorStateList.valueOf(OneLook.withAlpha(if (lit) Color.WHITE else p.text, .08f)), look, null)
            clipToOutline = true
            PressGlow.attach(this, 999f)
            setOnClickListener { onTap() }
        }
        val button = if (lit) FrameLayout(activity).apply {
            clipChildren = false
            addView(Shadows(OneLook.CALL_GREEN), FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))
            addView(body, FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))
        } else withShadow(body, 999f, keepRound = true)
        return button.apply { layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, di(height)) }
    }

    /** LitButton's body: the flat colour and its rim (white along the top, brighter colour along the bottom). */
    private inner class LitBody(private val color: Int) : Drawable() {
        private val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = this@LitBody.color }
        private val rim = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }
        private var shape = Path()
        private var edge = Path()

        override fun onBoundsChange(bounds: android.graphics.Rect) {
            val r = RectF(bounds)
            shape = Shapes.path(r, 999f, keepRound = true)
            val w = d(1.5f)
            rim.strokeWidth = w
            edge = Shapes.path(RectF(r).apply { inset(w / 2, w / 2) }, 999f, keepRound = true)
            val light = OneLook.mix(color, Color.WHITE, .12f)
            rim.shader = LinearGradient(0f, r.top, 0f, r.bottom,
                intArrayOf(0x59FFFFFF, 0x00FFFFFF, OneLook.withAlpha(light, 0f), light),
                floatArrayOf(0f, .3f, .6f, 1f), Shader.TileMode.CLAMP)
        }

        override fun draw(canvas: Canvas) {
            canvas.drawPath(shape, fill)
            canvas.drawPath(edge, rim)
        }

        override fun getOutline(outline: android.graphics.Outline) =
            outline.setRoundRect(bounds, bounds.height() / 2f)

        override fun setAlpha(alpha: Int) {}
        override fun setColorFilter(colorFilter: android.graphics.ColorFilter?) {}
        @Deprecated("Deprecated in Java") override fun getOpacity() = android.graphics.PixelFormat.TRANSLUCENT
    }

    /** The lit button's shadows, outside its press (they stay put while it inflates). */
    private inner class Shadows(private val color: Int) : View(activity) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        override fun onDraw(canvas: Canvas) {
            val r = RectF(0f, 0f, width.toFloat(), height.toFloat())
            val path = Shapes.path(r, 999f, keepRound = true)
            paint.color = color
            // solidBody(glow: .22) from PressGlow (light mode: tighter, .28), then LitButton's own.
            if (p.light) paint.setShadowLayer(d(14f), 0f, d(4f), OneLook.withAlpha(color, .28f))
            else paint.setShadowLayer(d(22f), 0f, d(6f), OneLook.withAlpha(color, .22f))
            canvas.drawPath(path, paint)
            paint.setShadowLayer(d(12f), 0f, d(4f), OneLook.withAlpha(color, .25f))
            canvas.drawPath(path, paint)
        }
    }
}
