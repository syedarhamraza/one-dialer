package com.syedarhamraza.recorder

import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.min

/**
 * Automatic gain for the call's PCM, in place. Phones mix the far side into the call capture
 * quieter than you (on the vivo it was hard to hear), so quiet speech is lifted towards [TARGET],
 * up to [MAX_GAIN], while loud speech isn't lifted and never clips. Silence and line hiss below
 * [FLOOR] are left as they are rather than boosted. Keeps its state across chunks.
 */
class Leveler(rate: Int) {
    private val attack = coefficient(rate, 0.005) // the level rises fast, so a loud start isn't over-boosted
    private val release = coefficient(rate, 0.4) // and falls slowly, so the gain doesn't pump between words
    private val glide = coefficient(rate, 0.05) // the gain itself moves smoothly, with no clicks
    private var level = 0.0
    private var gain = 1.0

    fun process(pcm: ShortArray, count: Int) {
        for (i in 0 until count) {
            val x = pcm[i].toDouble()
            val a = abs(x)
            level = if (a > level) attack * level + (1 - attack) * a else release * level + (1 - release) * a
            val want = if (level < FLOOR) 1.0 else (TARGET / level).coerceIn(1.0, MAX_GAIN)
            gain = glide * gain + (1 - glide) * want
            pcm[i] = limit(x * gain)
        }
    }

    private companion object {
        const val TARGET = 3000.0 // average speech level, about -21 dBFS
        const val MAX_GAIN = 6.0 // about +16 dB
        const val FLOOR = 60.0 // about -55 dBFS: quieter is silence or hiss

        fun coefficient(rate: Int, seconds: Double) = exp(-1.0 / (rate * seconds))

        /** Soft above 24000, so peaks the gain pushed up round off instead of clipping. */
        fun limit(y: Double): Short {
            val knee = 24_000.0
            val a = abs(y)
            if (a <= knee) return y.toInt().toShort()
            val over = a - knee
            val soft = knee + (Short.MAX_VALUE - knee) * over / (over + (Short.MAX_VALUE - knee))
            return (min(soft, Short.MAX_VALUE.toDouble()) * if (y < 0) -1 else 1).toInt().toShort()
        }
    }
}
