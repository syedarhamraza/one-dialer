package com.syedarhamraza.dialer

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ContactAccountsTest {
    @Test
    fun phoneSimAndGoogleAreSaveTargets() {
        assertTrue(ContactExtras.isSaveTarget(null)) // the phone itself
        assertTrue(ContactExtras.isSaveTarget("USIM Account")) // vivo's SIM
        assertTrue(ContactExtras.isSaveTarget("com.android.contacts.sim"))
        assertTrue(ContactExtras.isSaveTarget("vnd.sec.contact.phone")) // Samsung's phone
        assertTrue(ContactExtras.isSaveTarget("com.google"))
    }

    @Test
    fun appAccountsAndServiceNumbersAreNot() {
        assertFalse(ContactExtras.isSaveTarget("com.whatsapp"))
        assertFalse(ContactExtras.isSaveTarget("com.google.android.apps.tachyon")) // Meet
        assertFalse(ContactExtras.isSaveTarget("SDN Account"))
    }
}
