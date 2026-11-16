package com.syedarhamraza.dialer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class SettingsBackupTest {
    @Test
    fun keepsOnlyOurFiles() {
        assertEquals(
            "files/datastore/FlutterSharedPreferences.preferences_pb",
            SettingsBackup.targetOf("datastore/FlutterSharedPreferences.preferences_pb"),
        )
        assertEquals("shared_prefs/quick_replies.xml", SettingsBackup.targetOf("shared_prefs/quick_replies.xml"))
        assertEquals("files/call_bg/all-1700000000000.jpg", SettingsBackup.targetOf("call_bg/all-1700000000000.jpg"))
        // A contact's photo, kept while another background is in use, travels too.
        assertEquals("files/call_bg/1234-1700000000000.jpg", SettingsBackup.targetOf("call_bg/1234-1700000000000.jpg"))
        assertNull(SettingsBackup.targetOf("shared_prefs/device_tier.xml"))
        assertNull(SettingsBackup.targetOf("shared_prefs/other.xml"))
        assertNull(SettingsBackup.targetOf("databases/x.db"))
    }

    @Test
    fun neverLeavesTheAppsFolders() {
        assertNull(SettingsBackup.targetOf("call_bg/../shared_prefs/x.xml"))
        assertNull(SettingsBackup.targetOf("call_bg/.."))
        assertNull(SettingsBackup.targetOf("call_bg/a/b.jpg"))
        assertNull(SettingsBackup.targetOf("call_bg/"))
        assertNull(SettingsBackup.targetOf("/data/data/x"))
        assertNull(SettingsBackup.targetOf("shared_prefs/../quick_replies.xml"))
    }
}
