package com.syedarhamraza.recorder

import com.syedarhamraza.recorder.shell.ShellMain
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class BothSidesTest {
    private val token = "0123456789abcdef0123456789abcdef0123456789abcdef"

    @Test
    fun theHelperAnswersOnlyItsThreeRequestsWithTheRightToken() {
        assertEquals(ShellMain.Request.PING, ShellMain.parse("$token ping", token))
        assertEquals(ShellMain.Request.PCM, ShellMain.parse("$token pcm\r", token))
        assertEquals(ShellMain.Request.QUIT, ShellMain.parse("$token quit", token))
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
    }
}
