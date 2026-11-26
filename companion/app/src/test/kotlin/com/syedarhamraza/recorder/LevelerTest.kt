package com.syedarhamraza.recorder

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs
import kotlin.math.sin

class LevelerTest {
    private val rate = 48_000

    /** Two seconds of a 300 Hz tone at [amplitude], levelled; returns the peak of the last second. */
    private fun levelledPeak(amplitude: Double, leveler: Leveler = Leveler(rate)): Int {
        val pcm = ShortArray(rate * 2) { (amplitude * sin(2 * Math.PI * 300 * it / rate)).toInt().toShort() }
        pcm.asList().chunked(1024).fold(0) { at, chunk ->
            val part = chunk.toShortArray()
            leveler.process(part, part.size)
            part.copyInto(pcm, at)
            at + part.size
        }
        return pcm.drop(rate).maxOf { abs(it.toInt()) }
    }

    @Test
    fun quietSpeechIsLifted() {
        val peak = levelledPeak(800.0)
        assertTrue("peak $peak", peak > 3000)
    }

    @Test
    fun loudSpeechIsntLiftedOrClipped() {
        val peak = levelledPeak(20_000.0)
        assertTrue("peak $peak", peak in 19_000..Short.MAX_VALUE)
        assertTrue("peak $peak", levelledPeak(32_000.0) <= Short.MAX_VALUE)
    }

    @Test
    fun silenceAndHissStayQuiet() {
        assertEquals(0, levelledPeak(0.0))
        assertTrue(levelledPeak(40.0) <= 41)
    }
}
