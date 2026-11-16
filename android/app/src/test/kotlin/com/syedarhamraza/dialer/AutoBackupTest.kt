package com.syedarhamraza.dialer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AutoBackupTest {
    @Test
    fun showsThePathAsTheFilesAppDoes() {
        assertEquals(
            "/storage/emulated/0/Documents/One Dialer/One Dialer backup.zip",
            AutoBackup.displayPath("primary:Documents"),
        )
        assertEquals("/storage/emulated/0/One Dialer/One Dialer backup.zip", AutoBackup.displayPath("primary:"))
        assertEquals(
            "/storage/1A2B-3C4D/Backups/Phone/One Dialer/One Dialer backup.zip",
            AutoBackup.displayPath("1A2B-3C4D:Backups/Phone"),
        )
    }

    @Test
    fun isDueOnlyWhenOnAndTheIntervalHasPassed() {
        val day = 24 * 3_600_000L
        assertFalse(AutoBackup.isDue(now = 10 * day, last = 0, intervalHours = 0))
        assertTrue(AutoBackup.isDue(now = 10 * day, last = 0, intervalHours = 24))
        assertFalse(AutoBackup.isDue(now = 10 * day, last = 10 * day - day + 1, intervalHours = 24))
        assertTrue(AutoBackup.isDue(now = 10 * day, last = 7 * day, intervalHours = 72))
        assertFalse(AutoBackup.isDue(now = 10 * day, last = 4 * day, intervalHours = 7 * 24))
    }
}
