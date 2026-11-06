package com.syedarhamraza.dialer

/**
 * The visual effects level a phone starts on (Settings › Reduce visual effects and Call screen
 * effects, until the user picks one): `off` for budget GPUs, `reduced` for midrange, `full` above.
 * Built from docs/research/device-tiers/report.md.
 *
 * shortcut: the tiers come from GPU benchmarks, not measured blur frame times; if Reduced still
 * lags on Mali-G57 MC2 phones (MT6835, MT6789), move that row to OFF.
 */
object DeviceTier {
    data class Pick(val tier: String, val source: String)

    /** Low-RAM phones go flat whatever the chip. */
    fun ram(totalBytes: Long, lowRam: Boolean): Pick? =
        if (lowRam || totalBytes < 3_500_000_000L) Pick("off", "ram") else null

    /** Today's rule for a chip nothing recognises: 4 GB or less reduced, more full. */
    fun ramFallback(totalBytes: Long) = Pick(if (totalBytes < 5_000_000_000L) "reduced" else "full", "ram")

    /**
     * From `Build.SOC_MODEL` (API 31+, with its manufacturer: "QTI SM6225", "MT6853V/TNZA",
     * "Spreadtrum UMS9230E"), else `ro.board.platform` ("mt6765", "bengal"), else `Build.HARDWARE`.
     * Null when none of them is a chip in the table.
     */
    fun chip(soc: String?, platform: String?, hardware: String?): Pick? {
        for ((value, source) in listOf(soc to "soc", platform to "platform", hardware to "platform")) {
            val token = token(value) ?: continue
            tier(token, CHIP_FULL, CHIP_REDUCED, CHIP_OFF)?.let { return Pick(it, source) }
        }
        return null
    }

    /** From the GL renderer string ("Mali-G57 MC2", "PowerVR Rogue GE8320", "Adreno (TM) 610"). */
    fun gpu(renderer: String?): Pick? {
        val name = renderer?.trim()?.uppercase()?.takeIf { it.isNotEmpty() } ?: return null
        // Budget first: "Mali-G57 MC1" must not fall into the G57 MC2+ row.
        return when {
            GPU_OFF.containsMatchIn(name) -> Pick("off", "gpu")
            GPU_REDUCED.containsMatchIn(name) -> Pick("reduced", "gpu")
            GPU_FULL.containsMatchIn(name) -> Pick("full", "gpu")
            else -> null
        }
    }

    /** The chip's part number or platform codename, upper case without spaces; null if there's none. */
    internal fun token(value: String?): String? {
        val text = value?.trim()?.uppercase()?.takeIf { it.isNotEmpty() && it != "UNKNOWN" } ?: return null
        PART.find(text)?.let { return it.value.replace(" ", "") }
        return text.takeIf { it in CODENAMES }
    }

    private fun tier(token: String, full: Regex, reduced: Regex, off: Regex) = when {
        full.matches(token) -> "full"
        reduced.matches(token) -> "reduced"
        off.matches(token) -> "off"
        else -> null
    }

    private val PART = Regex(
        """MT\d{4}|SDM\d{3}|MSM\d{4}|SM\d{4}|UMS\d{3,4}|S[CP]\d{4}A?|S5E\d{4}|EXYNOS ?\d{3,4}|GS\d{3}|TENSOR|ZUMA|(?<![A-Z])T\d{3,4}(?!\d)"""
    )

    // Board platforms that are codenames, not part numbers (Qualcomm); each maps to one GPU class.
    private val CODENAMES = setOf(
        "BENGAL", "KHAJE", "TRINKET", "HOLI", "ATOLL", "LITO", "SDMMAGPIE", "PITTI", "PARROT",
        "CROW", "VOLCANO", "MILOS", "KALAMA", "PINEAPPLE",
    )

    private val CHIP_FULL = Regex(
        "MT(689\\d|698\\d|699\\d|879\\d)|SM(7475|7550|7635|6650|7675|7750|8\\d{3})|S5E(8855|99\\d\\d)|" +
            "EXYNOS(1580|2\\d{3}|99\\d)|GS\\d{3}|TENSOR|ZUMA|CROW|VOLCANO|MILOS|KALAMA|PINEAPPLE"
    )

    private val CHIP_REDUCED = Regex(
        "MT(6781|6785|6789|6833|6835|6853|6855|6873|6875|6877|6878|6886|8755|8775|8781)|" +
            "UMS962[01]|T(750|760|765|770|820|8200)|" +
            "SM(4350|4375|4450|4635|6350|6375|6450|6475|7125|7150|7225|7250|7325|7350|7435|7450)|" +
            "SDM(67\\d|71\\d|73\\d|8\\d\\d)|MSM899\\d|S5E(8535|8825|8835|8845)|EXYNOS(1280|1330|1380|1480|98\\d\\d)|" +
            "HOLI|ATOLL|LITO|SDMMAGPIE|PITTI|PARROT"
    )

    private val CHIP_OFF = Regex(
        "MT(65\\d\\d|67[0-7]\\d|87[0-6]\\d|8786)|S[CP]\\d{4}A?|UMS(312|512|9230)|T(310|606|610|612|616|618|700|7200|7250)|" +
            "MSM89[0-5]\\d|SDM4\\d\\d|SDM6[0-6]\\d|SM(4250|6115|6125|6150|6225)|S5E3830|EXYNOS(850|7\\d{3}|961\\d)|" +
            "BENGAL|KHAJE|TRINKET"
    )

    private val GPU_OFF = Regex(
        """ROGUE|GE8\d|GM9\d|GX6\d|MALI-T|MALI-G(31|51|52|71|72)\b|MALI-G57 M[CP]1\b|ADRENO \(TM\) ([3-5]\d\d|61[02])\b"""
    )
    private val GPU_REDUCED = Regex(
        """MALI-G(57|68|76|77|78)\b|MALI-G615 M[CP][12]\b|MALI-G610 M[CP][1-4]\b|BXM|BXE|ADRENO \(TM\) (61[3-9]|6[2-5]\d|7[01]\d)\b"""
    )
    private val GPU_FULL = Regex(
        """MALI-G(6[1-9]\d|7[1-9]\d|9\d\d)|IMMORTALIS|XCLIPSE|DXT|CXT|ADRENO \(TM\) (6[6-9]\d|7[2-9]\d|8\d\d)\b"""
    )
}
