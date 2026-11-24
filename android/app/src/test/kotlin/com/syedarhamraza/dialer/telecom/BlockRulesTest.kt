package com.syedarhamraza.dialer.telecom

import org.junit.Assert.assertEquals
import org.junit.Test

class BlockRulesTest {
    private fun block(hidden: Boolean, contact: Boolean, settings: BlockingSettings, number: String = "03001234567") =
        BlockRules.shouldBlock(hidden, if (hidden) "" else number, { contact }, settings)

    @Test
    fun nothingBlockedByDefault() {
        val off = BlockingSettings()
        assertEquals(false, block(hidden = true, contact = false, off))
        assertEquals(false, block(hidden = false, contact = false, off))
    }

    @Test
    fun hiddenRuleBlocksOnlyHiddenNumbers() {
        val s = BlockingSettings(blockHidden = true)
        assertEquals(true, block(hidden = true, contact = false, s))
        assertEquals(false, block(hidden = false, contact = false, s))
    }

    @Test
    fun nonContactsRuleBlocksStrangersAndHiddenButNotContacts() {
        val s = BlockingSettings(blockNonContacts = true)
        assertEquals(true, block(hidden = false, contact = false, s))
        assertEquals(true, block(hidden = true, contact = false, s))
        assertEquals(false, block(hidden = false, contact = true, s))
    }

    @Test
    fun contactsAreNotLookedUpUnlessNeeded() {
        var lookedUp = false
        BlockRules.shouldBlock(false, "03001234567", { lookedUp = true; true }, BlockingSettings(blockHidden = true))
        assertEquals(false, lookedUp)
    }

    @Test
    fun prefixBlocksMatchingNumbersOnly() {
        val s = BlockingSettings(prefixes = setOf("0300"))
        assertEquals(true, block(hidden = false, contact = true, s, "0300 1234567"))
        assertEquals(false, block(hidden = false, contact = false, s, "0311 1234567"))
        val plus = BlockingSettings(prefixes = setOf("+92300"))
        assertEquals(true, block(hidden = false, contact = true, plus, "+92 300 1234567"))
        assertEquals(false, block(hidden = false, contact = true, plus, "92300 1234567"))
    }

    @Test
    fun allowlistBeatsPrefixAndNonContactsRules() {
        val s = BlockingSettings(blockNonContacts = true, prefixes = setOf("0300"), allowed = setOf("+92 300 1234567"))
        assertEquals(false, block(hidden = false, contact = false, s, "0300 1234567"))
        assertEquals(true, block(hidden = false, contact = false, s, "0300 7654321"))
    }

    @Test
    fun allowlistDoesNotLetHiddenNumbersThrough() {
        val s = BlockingSettings(blockHidden = true, allowed = setOf("03001234567"))
        assertEquals(true, block(hidden = true, contact = false, s))
    }
}
