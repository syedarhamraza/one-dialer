package com.syedarhamraza.recorder

import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.pow

/**
 * Volume boost: lifts quiet sound (the caller, heard only through the earpiece) and holds loud
 * sound (your own voice) down, so both sides end up closer. A feed-forward compressor with
 * makeup gain, a gate so the noise floor isn't boosted, and a hard limit so nothing clips.
 */
class Compressor(private val level: Level, sampleRate: Int) {
    enum class Level(val thresholdDb: Float, val ratio: Float, val makeupDb: Float) {
        OFF(0f, 1f, 0f),
        NORMAL(-30f, 3f, 12f),
        STRONG(-40f, 5f, 20f);

        companion object {
            fun of(name: String?) = entries.firstOrNull { it.name.equals(name, ignoreCase = true) } ?: OFF
        }
    }

    private val attack = coefficient(0.005, sampleRate)
    private val release = coefficient(0.150, sampleRate)
    private var envelope = 0.0

    fun process(buffer: ShortArray, count: Int) {
        if (level == Level.OFF) return
        for (i in 0 until count) {
            val x = buffer[i] / 32768.0
            val a = abs(x)
            envelope = if (a > envelope) attack * envelope + (1 - attack) * a else release * envelope + (1 - release) * a
            val envelopeDb = 20 * log10(max(envelope, 1e-6))
            val gainDb = if (envelopeDb < GATE_DB) {
                0.0 // background hiss stays where it was
            } else {
                val over = envelopeDb - level.thresholdDb
                (if (over > 0) -over * (1 - 1 / level.ratio) else 0.0) + level.makeupDb
            }
            val y = (x * 10.0.pow(gainDb / 20)).coerceIn(-LIMIT, LIMIT)
            buffer[i] = (y * 32767).toInt().toShort()
        }
    }

    private companion object {
        const val GATE_DB = -60.0
        const val LIMIT = 0.98

        fun coefficient(seconds: Double, sampleRate: Int) = exp(-1.0 / (seconds * sampleRate))
    }
}
