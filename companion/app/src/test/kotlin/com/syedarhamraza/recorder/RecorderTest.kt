package com.syedarhamraza.recorder

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class RecorderTest {
    @Test
    fun fileNameRoundTrips() {
        val file = RecordingFile.of(1762600000000, "+92 300-1234567")
        assertEquals("1762600000000_+923001234567.m4a", file.name)
        assertEquals(file, RecordingFile.parse(file.name))
    }

    @Test
    fun aSecondRecordingWithTheSameStartNeverTakesTheFirstOnesName() {
        val saved = setOf("1000_123.m4a", "1001_123.m4a")
        assertEquals("1002_123.m4a", RecordingFile.free(1000, "123", saved::contains).name)
        assertEquals("1000_456.m4a", RecordingFile.free(1000, "456", saved::contains).name)
    }

    @Test
    fun hiddenNumberIsUnknown() {
        val file = RecordingFile.of(5, null)
        assertEquals("5_unknown.m4a", file.name)
        assertNull(RecordingFile.parse(file.name)!!.number)
    }

    @Test
    fun parseRejectsPaths() {
        assertNull(RecordingFile.parse("../5_123.m4a"))
        assertNull(RecordingFile.parse("5_123.m4a/x"))
        assertNull(RecordingFile.parse("note.txt"))
    }

    @Test
    fun onlyOneDialerWithAPinnedCertIsTrusted() {
        val pinned = TrustedDialer.hex(TrustedDialer.CERTS.first())
        assertTrue(TrustedDialer.isTrusted(TrustedDialer.PACKAGE) { it.contentEquals(pinned) })
        assertFalse(TrustedDialer.isTrusted(TrustedDialer.PACKAGE) { false })
        assertFalse(TrustedDialer.isTrusted("com.example.spy") { true })
        assertFalse(TrustedDialer.isTrusted(null) { true })
    }

    @Test
    fun releaseTrustsOnlyThePlayBuild() {
        val release = TrustedDialer.certs(debug = false)
        assertTrue(release == listOf(TrustedDialer.PLAY_CERT))
        assertTrue(TrustedDialer.certs(debug = true).containsAll(release))
        val debugKey = TrustedDialer.hex(TrustedDialer.certs(debug = true).last())
        assertFalse(TrustedDialer.isTrusted(TrustedDialer.PACKAGE, release) { it.contentEquals(debugKey) })
        assertTrue(TrustedDialer.hex(TrustedDialer.PLAY_CERT).size == 32)
    }

    private fun sine(amplitude: Double, n: Int = 48_000) =
        ShortArray(n) { (amplitude * 32767 * kotlin.math.sin(it * 2 * Math.PI * 300 / 48_000)).toInt().toShort() }

    private fun rms(a: ShortArray, from: Int = 24_000) =
        kotlin.math.sqrt(a.drop(from).sumOf { it.toDouble() * it } / (a.size - from))

    @Test
    fun boostOffLeavesAudioUntouched() {
        val input = sine(0.02)
        val out = input.copyOf()
        Compressor(Compressor.Level.OFF, 48_000).process(out, out.size)
        assertTrue(input.contentEquals(out))
    }

    @Test
    fun boostLiftsTheQuietCallerAndNeverClips() {
        val quiet = sine(0.02) // about -34 dBFS, like a voice leaking from the earpiece
        val loud = sine(0.9)
        val before = rms(quiet)
        for (level in listOf(Compressor.Level.NORMAL, Compressor.Level.STRONG)) {
            val q = quiet.copyOf().also { Compressor(level, 48_000).process(it, it.size) }
            val l = loud.copyOf().also { Compressor(level, 48_000).process(it, it.size) }
            assertTrue("$level lifts quiet sound", rms(q) > before * 2)
            assertTrue("$level holds loud sound under the limit", l.all { kotlin.math.abs(it.toInt()) <= 32112 })
        }
    }

    @Test
    fun boostLeavesTheNoiseFloorAlone() {
        val hiss = sine(0.0005) // about -66 dBFS
        val out = hiss.copyOf().also { Compressor(Compressor.Level.STRONG, 48_000).process(it, it.size) }
        assertTrue(rms(out) < rms(hiss) * 1.5)
    }

    @Test
    fun theLoudestWorkingSourceWins() {
        assertEquals(7, SourcePicker.best(mapOf(6 to 120.0, 7 to 900.0, 1 to 400.0)))
        assertEquals(1, SourcePicker.best(mapOf(6 to 0.0, 1 to 50.0)))
        assertNull(SourcePicker.best(mapOf(6 to 0.0, 7 to 5.0))) // all blocked during the call
    }
}
