package com.syedarhamraza.recorder

/** How a call is recorded: [BOTH_SIDES] through the shell helper, [MICROPHONE] through the accessibility service. */
enum class RecordMethod(val key: String) {
    BOTH_SIDES("shell"),
    MICROPHONE("mic");

    companion object {
        /**
         * The method for the next recording. [setting] is "auto" (both sides when the helper runs,
         * else the microphone), "shell" or "mic" (only that one); null when it can't record.
         */
        fun choose(setting: String, helperRunning: Boolean, accessibilityOn: Boolean, micGranted: Boolean): RecordMethod? {
            val microphone = accessibilityOn && micGranted
            return when (setting) {
                "shell" -> BOTH_SIDES.takeIf { helperRunning }
                "mic" -> MICROPHONE.takeIf { microphone }
                else -> if (helperRunning) BOTH_SIDES else MICROPHONE.takeIf { microphone }
            }
        }
    }
}
