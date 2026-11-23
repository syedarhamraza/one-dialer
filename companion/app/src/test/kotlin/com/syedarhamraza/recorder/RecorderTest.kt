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

    @Test
    fun pairingCodeIsTheSixDigitsInTheDialog() {
        val code = com.syedarhamraza.recorder.shell.PairingAccessibilityService::pairingCode
        assertEquals("482913", code(listOf("Pair with device", "Wi-Fi pairing code", "482913", "192.168.1.20:37415")))
        assertEquals("482913", code(listOf(" 482 913 ")))
        assertNull(code(listOf("37415", "1234567", "Wireless debugging", "12345a")))
        assertNull(code(emptyList()))
    }
}
