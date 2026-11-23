package com.syedarhamraza.recorder

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class UpdatesTest {
    @Test
    fun theBuildSuffixIsDropped() {
        assertEquals("1.0.1-beta.1", Updates.base("1.0.1-beta.1 (5b2133f)"))
        assertEquals("1.0.1-beta.1", Updates.base("1.0.1-beta.1-debug (5b2133f+)"))
        assertEquals("1.0.0", Updates.base("1.0.0"))
    }

    @Test
    fun versionsCompareLikeReleases() {
        assertTrue(Updates.newer("1.0.2", "1.0.1"))
        assertTrue(Updates.newer("1.0.1", "1.0.1-beta.3"))
        assertTrue(Updates.newer("1.0.1-beta.10", "1.0.1-beta.2"))
        assertTrue(Updates.newer("1.1.0", "1.0.9"))
        assertTrue(Updates.newer("1.0.10", "1.0.9"))
        assertFalse(Updates.newer("1.0.1", "1.0.1"))
        assertFalse(Updates.newer("1.0.1-beta.1", "1.0.1"))
        assertFalse(Updates.newer("1.0.0", "1.0.1-beta.1"))
    }
}
