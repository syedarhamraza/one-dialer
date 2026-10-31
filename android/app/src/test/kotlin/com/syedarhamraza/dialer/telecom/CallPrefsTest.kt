package com.syedarhamraza.dialer.telecom

import android.media.AudioDeviceInfo
import android.telecom.Call
import org.junit.Assert.assertEquals
import org.junit.Test

class CallPrefsTest {
    @Test
    fun buzzesOnAnswerAndOnEndingALiveCall() {
        assertEquals(true, CallPrefs.buzzes(Call.STATE_RINGING, Call.STATE_ACTIVE))
        assertEquals(true, CallPrefs.buzzes(Call.STATE_DIALING, Call.STATE_ACTIVE))
        assertEquals(true, CallPrefs.buzzes(Call.STATE_ACTIVE, Call.STATE_DISCONNECTED))
        assertEquals(true, CallPrefs.buzzes(Call.STATE_HOLDING, Call.STATE_DISCONNECTED))
    }

    @Test
    fun quietForHoldAndCallsThatNeverConnected() {
        assertEquals(false, CallPrefs.buzzes(Call.STATE_HOLDING, Call.STATE_ACTIVE))
        assertEquals(false, CallPrefs.buzzes(Call.STATE_ACTIVE, Call.STATE_HOLDING))
        assertEquals(false, CallPrefs.buzzes(Call.STATE_RINGING, Call.STATE_DISCONNECTED))
        assertEquals(false, CallPrefs.buzzes(null, Call.STATE_ACTIVE))
    }

    @Test
    fun speakerOnlyWhenACallFirstGoesLive() {
        assertEquals(true, CallPrefs.goesLive(Call.STATE_RINGING, Call.STATE_ACTIVE))
        assertEquals(false, CallPrefs.goesLive(Call.STATE_HOLDING, Call.STATE_ACTIVE))
        assertEquals(false, CallPrefs.goesLive(Call.STATE_ACTIVE, Call.STATE_DISCONNECTED))
    }

    @Test
    fun headsetsButNotTheBuiltInSpeaker() {
        assertEquals(true, CallPrefs.isHeadset(AudioDeviceInfo.TYPE_BLUETOOTH_SCO))
        assertEquals(true, CallPrefs.isHeadset(AudioDeviceInfo.TYPE_WIRED_HEADPHONES))
        assertEquals(false, CallPrefs.isHeadset(AudioDeviceInfo.TYPE_BUILTIN_SPEAKER))
    }
}
