package com.syedarhamraza.recorder

/** A recording's file name is its index: `<startMillis>_<number>.m4a` ("unknown" for no number). */
data class RecordingFile(val startMillis: Long, val number: String?) {
    val name: String get() = "${startMillis}_${number?.takeIf { it.isNotEmpty() } ?: UNKNOWN}.m4a"

    companion object {
        private const val UNKNOWN = "unknown"

        /** Keeps only dial characters, so a number can never make a path. */
        fun of(startMillis: Long, number: String?) =
            RecordingFile(startMillis, number?.filter { it.isDigit() || it in "+*#" }?.takeIf { it.isNotEmpty() })

        fun parse(name: String): RecordingFile? {
            val match = Regex("""(\d+)_([0-9+*#]+|$UNKNOWN)\.m4a""").matchEntire(name) ?: return null
            val (start, number) = match.destructured
            return RecordingFile(start.toLong(), number.takeIf { it != UNKNOWN })
        }
    }
}
