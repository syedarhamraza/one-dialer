package com.syedarhamraza.recorder

import org.junit.Assert.assertEquals
import org.junit.Test

class RecLogTest {
    @Test fun masksPhoneNumbers() {
        assertEquals("call ############", RecLog.mask("call 0300 1234567"))
        assertEquals("from #############", RecLog.mask("from +923001234567"))
        assertEquals("to (#############", RecLog.mask("to (030) 012-3456"))
    }

    @Test fun keepsShortNumbers() {
        assertEquals("finish: 185 s, peak 4312", RecLog.mask("finish: 185 s, peak 4312"))
        assertEquals("port 43210, SDK 35", RecLog.mask("port 43210, SDK 35"))
        assertEquals("at Adb.kt:117", RecLog.mask("at Adb.kt:117"))
    }
}
