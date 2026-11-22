package com.syedarhamraza.dialer.telecom

import org.junit.Assert.assertEquals
import org.junit.Test

class VipRingTest {
    @Test
    fun listedContactsAreVips() {
        assertEquals(true, VipRing.isVip("7", starred = false, listed = setOf("7"), favourites = false))
        assertEquals(false, VipRing.isVip("8", starred = false, listed = setOf("7"), favourites = true))
    }

    @Test
    fun favouritesOnlyWhenIncluded() {
        assertEquals(true, VipRing.isVip("8", starred = true, listed = emptySet(), favourites = true))
        assertEquals(false, VipRing.isVip("8", starred = true, listed = emptySet(), favourites = false))
    }

    @Test
    fun unsavedNumbersNeverAre() {
        assertEquals(false, VipRing.isVip(null, starred = true, listed = setOf("7"), favourites = true))
    }
}
