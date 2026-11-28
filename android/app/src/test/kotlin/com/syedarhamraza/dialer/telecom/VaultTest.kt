package com.syedarhamraza.dialer.telecom

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class VaultTest {
    private val keys = setOf(ContactsSource.numberKey("0300 1234567"))

    @Test
    fun matchesTheSameNumberWrittenAnotherWay() {
        assertTrue(Vault.isVaultNumber(keys, "+92 300 1234567"))
        assertTrue(Vault.isVaultNumber(keys, "03001234567"))
    }

    @Test
    fun leavesOtherAndHiddenNumbersAlone() {
        assertFalse(Vault.isVaultNumber(keys, "0300 7654321"))
        assertFalse(Vault.isVaultNumber(keys, ""))
        assertFalse(Vault.isVaultNumber(keys, null))
        assertFalse(Vault.isVaultNumber(emptySet(), "0300 1234567"))
    }
}
