package com.syedarhamraza.dialer.telecom

import org.junit.Assert.assertEquals
import org.junit.Test

class BlockRulesTest {
    private fun block(hidden: Boolean, contact: Boolean, settings: BlockingSettings) =
        BlockRules.shouldBlock(hidden, { contact }, settings)

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
        BlockRules.shouldBlock(false, { lookedUp = true; true }, BlockingSettings(blockHidden = true))
        assertEquals(false, lookedUp)
    }
}
