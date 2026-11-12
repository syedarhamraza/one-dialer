package com.syedarhamraza.recorder

import android.animation.TimeInterpolator
import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.LinearGradient
import android.graphics.Outline
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.util.LruCache
import android.view.Choreographer
import android.widget.TextView
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * One Dialer's look and motion, ported from its Flutter source for the companion's plain views:
 * lib/theme/one_ui_theme.dart (colours), lib/app/layout.dart (DesignWidth), call_controls.dart
 * (TintedCallBody, GlassSpringCurve), squircle.dart. Every size is in One Dialer's design dp.
 */
object OneLook {
    const val PAGE = Color.BLACK
    val CARD = Color.rgb(0x1C, 0x1C, 0x1E) // surfaceCard
    val TEXT2 = Color.rgb(0x9E, 0x9E, 0xA4) // textSecondary
    const val DIVIDER = 0x1AFFFFFF
    val RED = Color.rgb(0xF0, 0x71, 0x67) // accentRed
    val CALL_GREEN = Color.rgb(0x00, 0xC2, 0x16) // callGreen, GlowButton's default
    const val RADIUS_CARD = 26f
    const val MAIN_GLASS_GLOW = .6f // kMainGlassGlow

    /** DesignWidth: the app is designed 420 dp wide and scaled to the screen, up to 1.15x; landscape unscaled. */
    fun scale(context: Context): Float {
        val c = context.resources.configuration
        if (c.orientation == Configuration.ORIENTATION_LANDSCAPE) return 1f
        return min(c.screenWidthDp / 420f, 1.15f)
    }

    /** Design dp to pixels. */
    fun px(context: Context, dp: Float) = dp * context.resources.displayMetrics.density * scale(context)

    /** Flutter's TextStyle on a TextView: size and letter spacing in design px, a weight, an optional line height. */
    fun style(view: TextView, size: Float, color: Int, weight: Int = 400, spacing: Float = 0f, height: Float = 0f) {
        val ctx = view.context
        val px = px(ctx, size) * ctx.resources.configuration.fontScale
        view.setTextSize(android.util.TypedValue.COMPLEX_UNIT_PX, px)
        view.setTextColor(color)
        view.typeface = Typeface.create(Typeface.DEFAULT, weight, false)
        view.letterSpacing = spacing / size
        view.includeFontPadding = false
        if (height > 0f) view.setLineHeight((px * height).toInt())
    }

    fun withAlpha(color: Int, alpha: Float) = (color and 0xFFFFFF) or ((alpha.coerceIn(0f, 1f) * 255).toInt() shl 24)

    fun mix(a: Int, b: Int, t: Float) = Color.argb(
        (Color.alpha(a) + (Color.alpha(b) - Color.alpha(a)) * t).toInt(),
        (Color.red(a) + (Color.red(b) - Color.red(a)) * t).toInt(),
        (Color.green(a) + (Color.green(b) - Color.green(a)) * t).toInt(),
        (Color.blue(a) + (Color.blue(b) - Color.blue(a)) * t).toInt(),
    )

    /** Flutter's MaskFilter.blur / BoxShadow sigma as Android's blur radius. */
    fun blurRadius(sigma: Float) = max(.01f, (sigma - .5f) / .57735f)

    /** Curves.easeIn / easeOut / easeInOutSine. */
    val easeIn = TimeInterpolator { cubic(it, .42f, 0f, 1f, 1f) }
    val easeOut = TimeInterpolator { cubic(it, 0f, 0f, .58f, 1f) }

    private fun cubic(t: Float, a: Float, b: Float, c: Float, d: Float): Float {
        if (t <= 0f) return 0f
        if (t >= 1f) return 1f
        var lo = 0f
        var hi = 1f
        repeat(24) {
            val m = (lo + hi) / 2
            val x = 3 * a * m * (1 - m) * (1 - m) + 3 * c * m * m * (1 - m) + m * m * m
            if (x < t) lo = m else hi = m
        }
        val m = (lo + hi) / 2
        return 3 * b * m * (1 - m) * (1 - m) + 3 * d * m * m * (1 - m) + m * m * m
    }
}

/** Flutter's SpringSimulation: [mass], [stiffness] and a damping ratio. */
class Spring(val mass: Float, val stiffness: Float, val ratio: Float) {
    private val w0 = sqrt(stiffness / mass)

    /** Displacement from the target and its velocity at [t] s, starting [d0] away at [v0]. */
    fun at(d0: Float, v0: Float, t: Float): Pair<Float, Float> {
        val z = ratio
        return when {
            z < 1f -> {
                val wd = w0 * sqrt(1 - z * z)
                val a = d0
                val b = (v0 + z * w0 * d0) / wd
                val e = exp(-z * w0 * t)
                val c = cos(wd * t)
                val s = sin(wd * t)
                e * (a * c + b * s) to e * ((-z * w0) * (a * c + b * s) + (-a * wd * s + b * wd * c))
            }
            z == 1f -> {
                val e = exp(-w0 * t)
                val b = v0 + w0 * d0
                e * (d0 + b * t) to e * (b - w0 * (d0 + b * t))
            }
            else -> {
                val q = w0 * sqrt(z * z - 1)
                val r1 = -z * w0 + q
                val r2 = -z * w0 - q
                val c2 = (v0 - r1 * d0) / (r2 - r1)
                val c1 = d0 - c2
                c1 * exp(r1 * t) + c2 * exp(r2 * t) to c1 * r1 * exp(r1 * t) + c2 * r2 * exp(r2 * t)
            }
        }
    }

    companion object {
        /** SpringDescription.withDurationAndBounce (GlassSpring's presets). */
        fun of(durationMs: Int, bounce: Float): Spring {
            val d = durationMs / 1000f
            return Spring(1f, (2 * PI.toFloat() / d).let { it * it }, 1f - bounce)
        }

        fun withRatio(mass: Float, stiffness: Float, ratio: Float) = Spring(mass, stiffness, ratio)
    }
}

/** GlassSpringCurve: a 0 → 1 spring as a curve over a fixed [durationMs]. */
class SpringCurve(private val spring: Spring, private val durationMs: Int) : TimeInterpolator {
    override fun getInterpolation(input: Float) = 1f + spring.at(-1f, 0f, input * durationMs / 1000f).first
}

/** A value that springs to its target with its velocity carried over, like SpringBuilder. */
class SpringValue(initial: Float, private val onChange: (Float) -> Unit) : Choreographer.FrameCallback {
    var value = initial
        private set
    private var velocity = 0f
    private var target = initial
    private var spring = Spring.of(300, 0f)
    private var d0 = 0f
    private var v0 = 0f
    private var start = 0L
    private var running = false

    fun animateTo(to: Float, with: Spring) {
        target = to
        spring = with
        d0 = value - to
        v0 = velocity
        start = 0L
        if (!running) {
            running = true
            Choreographer.getInstance().postFrameCallback(this)
        }
    }

    fun snapTo(to: Float) {
        stop(); target = to; value = to; velocity = 0f; onChange(value)
    }

    /** Starts from [from] moving at [speed] per second (a fling hitting the end). */
    fun animateFrom(from: Float, speed: Float, to: Float, with: Spring) {
        value = from; velocity = speed
        animateTo(to, with)
    }

    fun stop() {
        if (running) Choreographer.getInstance().removeFrameCallback(this)
        running = false; velocity = 0f
    }

    override fun doFrame(frameTimeNanos: Long) {
        if (start == 0L) start = frameTimeNanos
        val (d, v) = spring.at(d0, v0, (frameTimeNanos - start) / 1e9f)
        value = target + d
        velocity = v
        if (kotlin.math.abs(d) < 1e-3f && kotlin.math.abs(v) < 1e-2f) {
            value = target; velocity = 0f; running = false
        } else {
            Choreographer.getInstance().postFrameCallback(this)
        }
        onChange(value)
    }
}

/** Shapes: SquircleBorder (round stays round) and call_controls' bodyPath (a superellipse even as a pill). */
object Shapes {
    /** A squircle over [r] with corner [radius]; with [keepRound] a circle or stadium stays exactly round. */
    fun path(r: RectF, radius: Float?, keepRound: Boolean): Path {
        val p = Path()
        if (radius == null) {
            p.addOval(r, Path.Direction.CW)
            return p
        }
        val half = min(r.width(), r.height()) / 2
        if (keepRound && radius >= half - .5f) {
            p.addRoundRect(r, half, half, Path.Direction.CW)
            return p
        }
        continuous(p, r, radius)
        return p
    }

    /** Continuous corners easing in over 1.53 r each (the iOS / ColorOS squircle curve). */
    private fun continuous(p: Path, b: RectF, radius: Float) {
        val r = min(radius, min(b.width(), b.height()) / 2 / 1.52866f)
        val l = b.left
        val t = b.top
        val rt = b.right
        val bt = b.bottom
        p.moveTo(l + 1.52866f * r, t)
        p.lineTo(rt - 1.52866f * r, t)
        p.cubicTo(rt - 1.08849f * r, t, rt - .86841f * r, t, rt - .63149f * r, t + .07491f * r)
        p.cubicTo(rt - .37282f * r, t + .16732f * r, rt - .16732f * r, t + .37282f * r, rt - .07491f * r, t + .63149f * r)
        p.cubicTo(rt, t + .86841f * r, rt, t + 1.08849f * r, rt, t + 1.52866f * r)
        p.lineTo(rt, bt - 1.52866f * r)
        p.cubicTo(rt, bt - 1.08849f * r, rt, bt - .86841f * r, rt - .07491f * r, bt - .63149f * r)
        p.cubicTo(rt - .16732f * r, bt - .37282f * r, rt - .37282f * r, bt - .16732f * r, rt - .63149f * r, bt - .07491f * r)
        p.cubicTo(rt - .86841f * r, bt, rt - 1.08849f * r, bt, rt - 1.52866f * r, bt)
        p.lineTo(l + 1.52866f * r, bt)
        p.cubicTo(l + 1.08849f * r, bt, l + .86841f * r, bt, l + .63149f * r, bt - .07491f * r)
        p.cubicTo(l + .37282f * r, bt - .16732f * r, l + .16732f * r, bt - .37282f * r, l + .07491f * r, bt - .63149f * r)
        p.cubicTo(l, bt - .86841f * r, l, bt - 1.08849f * r, l, bt - 1.52866f * r)
        p.lineTo(l, t + 1.52866f * r)
        p.cubicTo(l, t + 1.08849f * r, l, t + .86841f * r, l + .07491f * r, t + .63149f * r)
        p.cubicTo(l + .16732f * r, t + .37282f * r, l + .37282f * r, t + .16732f * r, l + .63149f * r, t + .07491f * r)
        p.cubicTo(l + .86841f * r, t, l + 1.08849f * r, t, l + 1.52866f * r, t)
        p.close()
    }
}

/** A flat fill in a shape (cards, the menu highlight), with an outline for clipping and shadows. */
class ShapeFill(private val color: Int, private val radius: Float?, private val keepRound: Boolean = true) : Drawable() {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = this@ShapeFill.color }
    private var path = Path()

    override fun onBoundsChange(bounds: android.graphics.Rect) {
        path = Shapes.path(RectF(bounds), radius, keepRound)
    }

    override fun draw(canvas: Canvas) = canvas.drawPath(path, paint)

    override fun getOutline(outline: Outline) {
        if (android.os.Build.VERSION.SDK_INT >= 33) outline.setPath(path)
        else outline.setRoundRect(bounds, radius ?: (min(bounds.width(), bounds.height()) / 2f))
    }

    override fun setAlpha(alpha: Int) { paint.alpha = alpha }
    override fun setColorFilter(colorFilter: ColorFilter?) { paint.colorFilter = colorFilter }
    @Deprecated("Deprecated in Java") override fun getOpacity() = PixelFormat.TRANSLUCENT
}

/**
 * The call glass body (CallBodyArtwork over TintedCallBody), at the main app's dark-mode default
 * (Settings › Dark mode edge glow › Soft: half opacity, 2x edges, glow 0.6): the milky wash, the
 * soft edge glow, the brighter border glow and the 3D lips. Rasterized once per size and cached,
 * as One Dialer does, and drawn at [opacity].
 */
class GlassBody(
    private val context: Context,
    private val radius: Float?, // design dp; null is a circle
    private val glow: Float = OneLook.MAIN_GLASS_GLOW,
    private val opacity: Float = .5f,
    private val strength: Float = 2f,
    private val bottomLip: Float = 1f,
    private val lip: Float = 1f,
) : Drawable() {
    private val paint = Paint(Paint.FILTER_BITMAP_FLAG).apply { alpha = (opacity * 255).toInt() }
    private var image: Bitmap? = null

    override fun onBoundsChange(bounds: android.graphics.Rect) {
        if (bounds.isEmpty) return
        val key = "${bounds.width()}x${bounds.height()}|$radius|$glow|$strength|$bottomLip|$lip"
        image = cache.get(key) ?: paint(bounds.width(), bounds.height()).also { cache.put(key, it) }
    }

    override fun draw(canvas: Canvas) {
        image?.let { canvas.drawBitmap(it, bounds.left.toFloat(), bounds.top.toFloat(), paint) }
    }

    override fun getOutline(outline: Outline) {
        val path = Shapes.path(RectF(bounds), radius?.let { OneLook.px(context, it) }, keepRound = false)
        if (android.os.Build.VERSION.SDK_INT >= 33) outline.setPath(path) else if (radius == null) outline.setOval(bounds) else outline.setRoundRect(bounds, min(OneLook.px(context, radius), min(bounds.width(), bounds.height()) / 2f))
    }

    private fun d(v: Float) = OneLook.px(context, v)
    private fun g(argb: Long) = OneLook.withAlpha(argb.toInt(), ((argb ushr 24) / 255f) * glow)
    private fun e(c: Int, by: Float = strength) = OneLook.withAlpha(c, Color.alpha(c) / 255f * by)

    private fun paint(w: Int, h: Int): Bitmap {
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp) // software: BlurMaskFilter needs it
        val rect = RectF(0f, 0f, w.toFloat(), h.toFloat())
        val r = radius?.let { d(it) }
        val shape = Shapes.path(rect, r, keepRound = false)
        fun vertical(colors: IntArray, stops: FloatArray) =
            LinearGradient(0f, 0f, 0f, h.toFloat(), colors, stops, Shader.TileMode.CLAMP)

        // An even milky wash, a little lighter toward the bottom.
        c.drawPath(shape, Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = vertical(intArrayOf(0x33FFFFFF, 0x2BFFFFFF, 0x3DFFFFFF), floatArrayOf(0f, .5f, 1f))
        })
        // The soft glow hugging every edge, weaker along the top.
        c.save(); c.clipPath(shape)
        c.drawPath(shape, Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE; strokeWidth = d(10.5f)
            maskFilter = BlurMaskFilter(OneLook.blurRadius(d(7f)), BlurMaskFilter.Blur.NORMAL)
            shader = vertical(intArrayOf(g(0x10FFFFFF), g(0x2BFFFFFF), e(g(0x3DFFFFFF))), floatArrayOf(0f, .5f, 1f))
        })
        c.restore()
        // A brighter glow right on the border, strongest along the bottom.
        c.save(); c.clipPath(shape)
        c.drawPath(shape, Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE; strokeWidth = d(3f)
            maskFilter = BlurMaskFilter(OneLook.blurRadius(d(1.5f)), BlurMaskFilter.Blur.NORMAL)
            shader = vertical(
                intArrayOf(g(0x33FFFFFF), g(0x26FFFFFF), g(0x26FFFFFF), e(g(0x6EFFFFFF))),
                floatArrayOf(0f, .25f, .75f, 1f),
            )
        })
        c.restore()
        // The 3D lips: clearer along the top, fainter along the bottom, faded toward the sides.
        val lipPx = d(lip)
        c.saveLayer(rect, null)
        val inner = RectF(rect).apply { inset(lipPx / 2, lipPx / 2) }
        c.drawPath(Shapes.path(inner, r?.let { it - lipPx / 2 }, keepRound = false), Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE; strokeWidth = lipPx
            shader = vertical(
                intArrayOf(e(0x3BFFFFFF), 0x00FFFFFF, 0x00FFFFFF, e(0x1FFFFFFF, bottomLip)),
                floatArrayOf(0f, .3f, .7f, 1f),
            )
        })
        c.drawRect(rect, Paint().apply {
            xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_IN)
            shader = LinearGradient(0f, 0f, w.toFloat(), 0f,
                intArrayOf(0, Color.BLACK, Color.BLACK, 0), floatArrayOf(.12f, .32f, .68f, .88f), Shader.TileMode.CLAMP)
        })
        c.restore()
        return bmp
    }

    override fun setAlpha(alpha: Int) {}
    override fun setColorFilter(colorFilter: ColorFilter?) {}
    @Deprecated("Deprecated in Java") override fun getOpacity() = PixelFormat.TRANSLUCENT

    private companion object {
        val cache = object : LruCache<String, Bitmap>(16 * 1024 * 1024) {
            override fun sizeOf(key: String, value: Bitmap) = value.byteCount
        }
    }
}

/** Material Symbols' rounded glyphs One Dialer uses, drawn on their 24-unit grid. */
class Glyph(private val color: Int, private val draw: (Canvas, Paint) -> Unit) : Drawable() {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)

    override fun draw(canvas: Canvas) {
        canvas.save()
        canvas.translate(bounds.left.toFloat(), bounds.top.toFloat())
        canvas.scale(bounds.width() / 24f, bounds.height() / 24f)
        paint.reset(); paint.isAntiAlias = true; paint.color = color
        draw(canvas, paint)
        canvas.restore()
    }

    override fun setAlpha(alpha: Int) { paint.alpha = alpha }
    override fun setColorFilter(colorFilter: ColorFilter?) { paint.colorFilter = colorFilter }
    @Deprecated("Deprecated in Java") override fun getOpacity() = PixelFormat.TRANSLUCENT

    companion object {
        private fun stroke(p: Paint, w: Float) {
            p.style = Paint.Style.STROKE; p.strokeWidth = w; p.strokeCap = Paint.Cap.ROUND; p.strokeJoin = Paint.Join.ROUND
        }

        /** Icons.chevron_right_rounded. */
        fun chevron(color: Int) = Glyph(color) { c, p ->
            stroke(p, 2f)
            c.drawPath(Path().apply { moveTo(9.7f, 7.3f); lineTo(14.4f, 12f); lineTo(9.7f, 16.7f) }, p)
        }

        /** Icons.arrow_back_rounded. */
        fun back(color: Int) = Glyph(color) { c, p ->
            stroke(p, 2f)
            c.drawPath(Path().apply { moveTo(19f, 12f); lineTo(5.4f, 12f); moveTo(11.3f, 5.7f); lineTo(5f, 12f); lineTo(11.3f, 18.3f) }, p)
        }

        /** Icons.radio_button_checked_rounded / _unchecked_rounded. */
        fun radio(color: Int, checked: Boolean) = Glyph(color) { c, p ->
            stroke(p, 2f)
            c.drawCircle(12f, 12f, 9f, p)
            if (checked) {
                p.style = Paint.Style.FILL
                c.drawCircle(12f, 12f, 5f, p)
            }
        }
    }
}
