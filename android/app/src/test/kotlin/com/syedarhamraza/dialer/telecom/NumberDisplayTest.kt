package com.syedarhamraza.dialer.telecom

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class NumberDisplayTest {
    @Test
    fun domesticNumberIsGroupedWithoutLocation() {
        val display = NumberDisplay.compute("PK", "03001234567")
        assertEquals("0300 1234567", display.formatted)
        assertNull(display.location)
    }

    @Test
    fun foreignNumberIsInternationalWithCountry() {
        val display = NumberDisplay.compute("PK", "+442071838750")
        assertEquals("+44 20 7183 8750", display.formatted)
        assertEquals(java.util.Locale("", "GB").displayCountry, display.location)
    }

    @Test
    fun shortCodeStaysAsDialled() {
        assertEquals(NumberDisplay(null, null), NumberDisplay.compute("PK", "1122"))
    }
}
