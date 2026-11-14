package com.syedarhamraza.dialer.telecom

import org.junit.Assert.assertEquals
import org.junit.Test

class NumberDisplayTest {
    @Test
    fun domesticNumberIsGroupedWithItsCountry() {
        val display = NumberDisplay.compute("PK", "03001234567")
        assertEquals("0300 1234567", display.formatted)
        // A domestic caller gets their country too, as ColorOS shows a place for every number.
        assertEquals(java.util.Locale("", "PK").displayCountry, display.location)
    }

    @Test
    fun foreignNumberIsInternationalWithCountry() {
        val display = NumberDisplay.compute("PK", "+442071838750")
        assertEquals("+44 20 7183 8750", display.formatted)
        assertEquals(java.util.Locale("", "GB").displayCountry, display.location)
    }

    @Test
    fun keypadGroupsAsYouType() {
        assertEquals("037", NumberDisplay.asYouType("PK", "037"))
        assertEquals("0300 1234567", NumberDisplay.asYouType("PK", "03001234567"))
    }

    @Test
    fun shortCodeStaysAsDialled() {
        assertEquals(NumberDisplay(null, null), NumberDisplay.compute("PK", "1122"))
    }
}
