package com.syedarhamraza.dialer.telecom

import android.telecom.Call
import org.junit.Assert.assertEquals
import org.junit.Test

class OngoingIndexTest {
    @Test
    fun activeBeatsHoldingAndDialing() {
        assertEquals(2, ongoingIndex(listOf(Call.STATE_HOLDING, Call.STATE_DIALING, Call.STATE_ACTIVE)))
    }

    @Test
    fun dialingBeatsHolding() {
        assertEquals(1, ongoingIndex(listOf(Call.STATE_HOLDING, Call.STATE_DIALING)))
    }

    @Test
    fun noneWhenOnlyRingingOrEnding() {
        assertEquals(null, ongoingIndex(listOf(Call.STATE_RINGING, Call.STATE_DISCONNECTING)))
        assertEquals(null, ongoingIndex(emptyList()))
    }
}
