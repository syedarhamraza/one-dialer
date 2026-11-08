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
}
