package com.syedarhamraza.recorder

import kotlin.math.sqrt

/** Picks the mic source that hears the call best, from each source's measured level. */
object SourcePicker {
    /** RMS on the 16-bit scale below which a source counts as silent (blocked during calls). */
    const val SILENCE_RMS = 30.0

    // shortcut: the loudest source may be loud because of your own voice, not the caller's; a manual pick overrides it.
    fun best(levels: Map<Int, Double>): Int? = levels.filterValues { it > SILENCE_RMS }.maxByOrNull { it.value }?.key

    fun rms(sumOfSquares: Double, samples: Long): Double = if (samples == 0L) 0.0 else sqrt(sumOfSquares / samples)
}
