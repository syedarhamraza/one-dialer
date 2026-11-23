package com.syedarhamraza.recorder

import com.syedarhamraza.recorder.shell.ShellHelper
import com.syedarhamraza.recorder.shell.ShellMain
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class BothSidesTest {
    private val token = "0123456789abcdef0123456789abcdef0123456789abcdef"

    @Test
    fun theHelperAnswersOnlyItsRequestsWithTheRightToken() {
        assertEquals(ShellMain.Request.PING, ShellMain.parse("$token ping", token))
        assertEquals(ShellMain.Request.PCM, ShellMain.parse("$token pcm\r", token))
        assertEquals(ShellMain.Request.QUIT, ShellMain.parse("$token quit", token))
        assertEquals(ShellMain.Request.HIDE, ShellMain.parse("$token hide", token))
        assertEquals(ShellMain.Request.SHOW, ShellMain.parse("$token show", token))
    }

    @Test
    fun aFailedStartSaysWhatToFix() {
        fun p(onWifi: Boolean, wirelessOn: Boolean, canSwitch: Boolean) = ShellHelper.problem(onWifi, wirelessOn, canSwitch)
        assertEquals(ShellHelper.Problem.WIFI, p(false, true, true))
        assertEquals(ShellHelper.Problem.WIFI, p(false, false, false))
        assertEquals(ShellHelper.Problem.DEBUGGING, p(true, false, false))
        assertEquals(ShellHelper.Problem.CONNECT, p(true, false, true)) // One Recorder switches it on itself
        assertEquals(ShellHelper.Problem.CONNECT, p(true, true, false))
    }

    @Test
    fun itCarriesOneDialersVersion() {
        // build.gradle.kts reads pubspec.yaml; the old fixed 1.0.0 (1) can't come back.
        val pubspec = java.io.File("../../pubspec.yaml").readText()
        val version = Regex("(?m)^version:\\s*([^+\\s]+)\\+(\\d+)").find(pubspec)!!
        assertEquals(version.groupValues[2].toInt(), BuildConfig.VERSION_CODE)
        assert(BuildConfig.VERSION_NAME.matches(Regex(Regex.escape(version.groupValues[1]) + "(-debug)? [(][0-9a-f]+[+]?[)]"))) { BuildConfig.VERSION_NAME }
    }

    @Test
    fun theHelperDropsEverythingElse() {
        assertNull(ShellMain.parse(null, token))
        assertNull(ShellMain.parse("", token))
        assertNull(ShellMain.parse("pcm", token))
        assertNull(ShellMain.parse("wrong pcm", token))
        assertNull(ShellMain.parse("${token}x pcm", token))
        assertNull(ShellMain.parse("$token sh -c id", token))
        assertNull(ShellMain.parse("$token pcm extra", token))
        assertNull(ShellMain.parse("$token PCM", token))
        assertNull(ShellMain.parse("hide", token))
        assertNull(ShellMain.parse("$token hide adb_enabled", token))
    }
}
