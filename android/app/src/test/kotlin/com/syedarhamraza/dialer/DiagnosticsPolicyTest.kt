package com.syedarhamraza.dialer

import org.junit.Assert.*
import org.junit.Test
import java.nio.file.Files

class DiagnosticsPolicyTest {
    @Test fun contextRejectsUserDataUnknownFieldsAndInvalidNumbers() {
        val result = DiagnosticsPolicy.context(mapOf("screen" to "contact/123", "phone" to "03001234567",
            "contactName" to "Private name", "visualEffects" to "full", "refreshRate" to Double.NaN,
            "glassDark" to "soft", "glassLight" to "fancy", "callGlass" to "bold", "navStyle" to "liquid", "navGlass" to "shiny",
            "frames" to mapOf("buildP95Ms" to 15, "number" to "03001234567", "rasterMaxMs" to -1)))
        assertEquals(mapOf("visualEffects" to "full", "glassDark" to "soft", "callGlass" to "bold", "navStyle" to "liquid",
            "frames" to mapOf("buildP95Ms" to 15.0)), result)
    }

    @Test fun engineSnapshotsDoNotShareMutableContext() {
        val main = DiagnosticsPolicy.context(mapOf("screen" to "calls"))
        val call = DiagnosticsPolicy.context(mapOf("screen" to "in_call"))
        assertEquals("calls", main["screen"])
        assertEquals("in_call", call["screen"])
    }

    @Test fun stallRequiresForegroundGraceAndMissingHeartbeat() {
        assertFalse(DiagnosticsPolicy.stalled(8000, 0, 0, false, false))
        assertFalse(DiagnosticsPolicy.stalled(4999, 0, 0, true, false))
        assertFalse(DiagnosticsPolicy.stalled(8000, 0, 0, true, true))
        assertFalse(DiagnosticsPolicy.stalled(8000, 0, 6000, true, false))
        assertTrue(DiagnosticsPolicy.stalled(8000, 0, 5000, true, false))
    }

    @Test fun inputStallNeedsThreeSecondsOfUncountedTouchesWhileDartIsAlive() {
        assertFalse(DiagnosticsPolicy.inputStalled(9000, 0, 8000, 8500)) // Dart counted every touch
        assertFalse(DiagnosticsPolicy.inputStalled(9000, 5000, 5000, 8500)) // one tap, then nothing
        assertFalse(DiagnosticsPolicy.inputStalled(9000, 5000, 7999, 8500))
        assertFalse(DiagnosticsPolicy.inputStalled(9000, 5000, 8000, 6000)) // Dart is stuck: DartStall's job
        assertTrue(DiagnosticsPolicy.inputStalled(9000, 5000, 8000, 8500))
    }

    @Test fun actionFramesAndShellFramesKeepOnlyValidNumbers() {
        assertEquals(mapOf("frames" to 12, "buildMaxMs" to 3.0, "rasterMaxMs" to 53.5),
            DiagnosticsPolicy.actionFrames(mapOf("name" to "tab_calls", "frames" to 12, "buildMaxMs" to 3,
                "rasterMaxMs" to 53.5, "number" to "03001234567")))
        assertNull(DiagnosticsPolicy.actionFrames(mapOf("frames" to 12, "buildMaxMs" to Double.NaN, "rasterMaxMs" to 1)))
        assertNull(DiagnosticsPolicy.actionFrames(mapOf("frames" to -1, "buildMaxMs" to 1, "rasterMaxMs" to 1)))
        val context = DiagnosticsPolicy.context(mapOf("shellFrames" to mapOf("rasterMaxMs" to 53.5, "phone" to "1")))
        assertEquals(mapOf("rasterMaxMs" to 53.5), context["shellFrames"])
    }

    @Test fun limitsArePerCategoryAndManualReportsHaveTheirOwnCooldown() {
        val policy = DiagnosticsPolicy()
        assertTrue(policy.allow("DartStall", 0))
        assertFalse(policy.allow("DartStall", 599999))
        assertTrue(policy.allow("NativeMainStall", 1))
        assertTrue(policy.allow("DartStall", 600000))
        assertTrue(policy.allow("DartStall", 1200000))
        assertFalse(policy.allow("DartStall", 1800000))
        assertTrue(policy.allow("UserReportedLag", 0))
        assertFalse(policy.allow("UserReportedLag", 59999))
        assertTrue(policy.allow("UserReportedLag", 60000))
    }

    @Test fun queueSurvivesRestartAndOnlyAcknowledgedRecordsDisappear() {
        val file = Files.createTempDirectory("diagnostics").resolve("queue").toFile()
        val store = DiagnosticsStore(file)
        store.add(PendingDiagnostic("one", 100, "first"), 100)
        store.add(PendingDiagnostic("two", 101, "second"), 101)
        val restarted = DiagnosticsStore(file)
        assertEquals(listOf("one", "two"), restarted.pending(102).map { it.id })
        restarted.ack("one", 102)
        assertEquals(listOf("two"), DiagnosticsStore(file).pending(103).map { it.id })
        assertTrue(restarted.pending(86400102).isEmpty())
    }

    @Test fun queueIsBoundedByCountAndEncodedBytes() {
        val file = Files.createTempDirectory("diagnostics").resolve("queue").toFile()
        val store = DiagnosticsStore(file)
        repeat(30) { store.add(PendingDiagnostic("id$it", 100, "a".repeat(20000)), 100) }
        assertTrue(store.pending(100).size <= 20)
        assertTrue(file.length() <= 256 * 1024)
        assertEquals("id29", store.pending(100).last().id)
    }
}
