package com.syedarhamraza.dialer

import org.junit.Assert.*
import org.junit.Test

class WhatsAppNumbersTest {
    @Test fun rejectsServiceCodesAndPauseWait() {
        for (value in listOf("", "*123#", "123,4", "123;4", "++923331234567")) {
            assertNull(WhatsAppNumbers.clean(value))
        }
    }
    @Test fun requiresCountryCodeForChat() {
        assertNull(WhatsAppNumbers.international("03331234567"))
        assertEquals("+923331234567", WhatsAppNumbers.international("+92 (333) 123-4567"))
    }
    @Test fun matchesOnlyExactInternationalAccount() {
        val aliases = setOf("03331234567", "+923331234567")
        assertTrue(WhatsAppNumbers.matchesAccount("923331234567@s.whatsapp.net", aliases))
        assertFalse(WhatsAppNumbers.matchesAccount("923331234568@s.whatsapp.net", aliases))
        assertFalse(WhatsAppNumbers.matchesAccount("13331234567", aliases))
        assertFalse(WhatsAppNumbers.matchesAccount("923331234567@unknown", aliases))
        assertFalse(WhatsAppNumbers.matchesAccount("923331234567", setOf("03331234567")))
    }
}
