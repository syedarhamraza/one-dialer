package com.syedarhamraza.dialer.telecom

import org.junit.Assert.assertEquals
import org.junit.Test

class RecordRulesTest {
    private fun record(mode: String, contact: String?, selected: Set<String> = emptySet(), never: Set<String> = emptySet()) =
        RecordRules.shouldRecord(mode, contact, selected, never)

    @Test
    fun offRecordsNothingAndAllRecordsEveryone() {
        assertEquals(false, record("off", null))
        assertEquals(false, record("off", "1"))
        assertEquals(true, record("all", null))
        assertEquals(true, record("all", "1"))
    }

    @Test
    fun unknownOnlyRecordsNumbersWithoutAContact() {
        assertEquals(true, record("unknown", null))
        assertEquals(false, record("unknown", "1"))
    }

    @Test
    fun selectedContactsOnly() {
        assertEquals(true, record("contacts", "1", selected = setOf("1")))
        assertEquals(false, record("contacts", "2", selected = setOf("1")))
        assertEquals(false, record("contacts", null, selected = setOf("1")))
    }

    @Test
    fun neverRecordWinsOverEveryMode() {
        for (mode in listOf("all", "contacts")) assertEquals(false, record(mode, "1", selected = setOf("1"), never = setOf("1")))
        assertEquals(true, record("all", "2", never = setOf("1")))
    }
}
