package com.syedarhamraza.dialer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class DeviceTierTest {
    private fun chip(soc: String?, platform: String? = null, hardware: String? = null) =
        DeviceTier.chip(soc, platform, hardware)?.tier

    @Test fun mediatekPartsAsPhonesReportThem() {
        assertEquals("off", chip("Mediatek MT6765"))
        assertEquals("off", chip("MediaTek MT6765V/CB"))
        assertEquals("off", chip("mediatek MT6769Z"))
        assertEquals("reduced", chip("Mediatek MT6835"))
        assertEquals("reduced", chip("MediaTek MT6853V/TNZA"))
        assertEquals("reduced", chip("MediaTek MT8781V/NA")) // Helio G99 tablet part
        assertEquals("full", chip("Mediatek MT6991")) // the vivo V2413 on the desk
        assertEquals("full", chip("MediaTek MT6895Z_A/TCZA"))
    }

    @Test fun qualcommUnisocAndExynos() {
        assertEquals("off", chip("QTI SM6225"))
        assertEquals("reduced", chip("QTI SM6450"))
        assertEquals("reduced", chip("Qualcomm SM7435"))
        assertEquals("full", chip("QTI SM7550"))
        assertEquals("full", chip("QTI SM8350"))
        assertEquals("off", chip("Spreadtrum UMS9230E"))
        assertEquals("off", chip("Samsung Exynos 850"))
        assertEquals("reduced", chip("Samsung s5e8835"))
    }

    @Test fun beforeAndroid12ThePlatformDecides() {
        assertEquals("off", chip(null, platform = "bengal"))
        assertEquals("reduced", chip(null, platform = "holi"))
        assertEquals("reduced", chip(null, platform = "parrot"))
        assertEquals("off", chip(null, platform = "mt6765", hardware = "mt6765"))
        assertEquals("off", chip("unknown unknown", platform = "ums9230"))
        assertEquals("off", chip(null, platform = null, hardware = "mt6762"))
    }

    @Test fun unknownChipsAreLeftToTheGpuOrRam() {
        assertNull(chip(null, platform = "qcom", hardware = "qcom"))
        assertNull(chip("unknown unknown"))
        assertNull(chip(null, platform = "lahaina")) // covers flagship 888 too: not guessed
    }

    @Test fun gpuNames() {
        fun gpu(name: String) = DeviceTier.gpu(name)?.tier
        assertEquals("off", gpu("PowerVR Rogue GE8320"))
        assertEquals("off", gpu("Mali-G52 MC2"))
        assertEquals("off", gpu("Mali-G57 MC1"))
        assertEquals("off", gpu("Adreno (TM) 610"))
        assertEquals("reduced", gpu("Mali-G57 MC2"))
        assertEquals("reduced", gpu("Mali-G68 MC4"))
        assertEquals("reduced", gpu("PowerVR B-Series BXM-8-256"))
        assertEquals("reduced", gpu("Adreno (TM) 619"))
        assertEquals("reduced", gpu("Adreno (TM) 710"))
        assertEquals("full", gpu("Adreno (TM) 720"))
        assertEquals("full", gpu("Mali-G610 MC6"))
        assertEquals("full", gpu("Mali-G925-Immortalis MC12"))
        assertNull(gpu("Some New GPU"))
        assertNull(DeviceTier.gpu(null))
    }

    @Test fun ramComesFirstAndLast() {
        assertEquals("off", DeviceTier.ram(3_000_000_000L, lowRam = false)?.tier)
        assertEquals("off", DeviceTier.ram(8_000_000_000L, lowRam = true)?.tier)
        assertNull(DeviceTier.ram(3_700_000_000L, lowRam = false)) // a 4 GB phone: the chip decides
        assertEquals("reduced", DeviceTier.ramFallback(3_700_000_000L).tier)
        assertEquals("full", DeviceTier.ramFallback(7_500_000_000L).tier)
    }
}
