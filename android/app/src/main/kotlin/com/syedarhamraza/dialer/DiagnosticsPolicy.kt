package com.syedarhamraza.dialer

import java.io.File
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.util.Base64

/** Monotonic time only; wall-clock changes must not trigger a watchdog. */
internal class DiagnosticsPolicy {
    private val last = mutableMapOf<String, Long>()
    private val counts = mutableMapOf<String, Int>()
    fun allow(category: String, now: Long): Boolean {
        val manual = category == "UserReportedLag"
        val gap = if (manual) 60_000 else 600_000
        if (last[category]?.let { now - it < gap } == true) return false
        if (!manual && counts.getOrDefault(category, 0) >= 3) return false
        last[category] = now
        counts[category] = counts.getOrDefault(category, 0) + 1
        return true
    }

    companion object {
        fun context(values: Map<*, *>): Map<String, Any> {
            val result = mutableMapOf<String, Any>()
            val screens = setOf("calls", "contacts", "keypad", "in_call", "subpage", "help_feedback", "setup")
            (values["screen"] as? String)?.takeIf { it in screens }?.let { result["screen"] = it }
            val allowed = mapOf(
                "visualEffects" to setOf("full", "reduced", "off"),
                "callEffects" to setOf("full", "reduced", "off"),
                "glassDark" to setOf("classic", "soft", "bold"),
                "glassLight" to setOf("classic", "soft", "bold"),
                "callGlass" to setOf("classic", "soft", "bold"),
            )
            for ((key, levels) in allowed) {
                (values[key] as? String)?.takeIf { it in levels }?.let { result[key] = it }
            }
            (values["refreshRate"] as? Number)?.toDouble()?.takeIf { it.isFinite() && it in 1.0..1000.0 }
                ?.let { result["refreshRate"] = it }
            result["frames"] = frameSummary(values["frames"] as? Map<*, *>)
            // The tabs' frames as they were when a page first opened over them.
            (values["shellFrames"] as? Map<*, *>)?.let { result["shellFrames"] = frameSummary(it) }
            return result
        }

        private fun frameSummary(metrics: Map<*, *>?): Map<String, Double> {
            val frames = mutableMapOf<String, Double>()
            for (key in listOf("frames", "buildP50Ms", "buildP95Ms", "buildP99Ms", "buildMaxMs",
                "rasterP50Ms", "rasterP95Ms", "rasterP99Ms", "rasterMaxMs")) {
                (metrics?.get(key) as? Number)?.toDouble()?.takeIf { it.isFinite() && it in 0.0..600_000.0 }
                    ?.let { frames[key] = it }
            }
            return frames
        }

        /** The worst frames in the second after a user action; null if any value is invalid. */
        fun actionFrames(values: Map<*, *>?): Map<String, Number>? {
            val frames = (values?.get("frames") as? Number)?.toInt()?.takeIf { it in 0..1_000 } ?: return null
            val result = mutableMapOf<String, Number>("frames" to frames)
            for (key in listOf("buildMaxMs", "rasterMaxMs")) {
                result[key] = (values[key] as? Number)?.toDouble()?.takeIf { it.isFinite() && it in 0.0..600_000.0 }
                    ?: return null
            }
            return result
        }

        fun stalled(now: Long, resumedAt: Long, heartbeat: Long, resumed: Boolean, debugger: Boolean) =
            resumed && !debugger && now - resumedAt >= 5_000 && now - heartbeat >= 3_000

        /** Touches kept arriving for 3 s that Dart never counted, while Dart itself is alive. */
        fun inputStalled(now: Long, firstUnseenTouchAt: Long, lastTouchAt: Long, heartbeat: Long) =
            firstUnseenTouchAt > 0 && lastTouchAt - firstUnseenTouchAt >= 3_000 && now - heartbeat < 3_000
    }
}

internal data class PendingDiagnostic(val id: String, val at: Long, val payload: String)

/** Owned by the diagnostics worker. Acknowledgement is separate from reading so
 * a failed Firebase call or process death cannot silently drain the queue. */
internal class DiagnosticsStore(private val file: File) {
    private fun encode(row: PendingDiagnostic) = "${row.id}\t${row.at}\t" +
        Base64.getEncoder().encodeToString(row.payload.toByteArray(Charsets.UTF_8))

    fun pending(now: Long): List<PendingDiagnostic> {
        if (!file.exists()) return emptyList()
        if (file.length() > 256 * 1024) return emptyList()
        return file.readLines().mapNotNull { line ->
            runCatching {
                val parts = line.split('\t', limit = 3)
                PendingDiagnostic(parts[0], parts[1].toLong(), String(Base64.getDecoder().decode(parts[2]), Charsets.UTF_8))
            }.getOrNull()
        }.filter { now - it.at in 0..86_400_000 }.takeLast(20)
    }

    fun add(row: PendingDiagnostic, now: Long) = save(pending(now) + row)
    fun ack(id: String, now: Long) = save(pending(now).filterNot { it.id == id })
    fun prune(now: Long) = save(pending(now))

    private fun save(rows: List<PendingDiagnostic>) {
        val bounded = rows.takeLast(20).toMutableList()
        var text = bounded.joinToString("\n", transform = ::encode)
        while (text.toByteArray(Charsets.UTF_8).size > 256 * 1024 && bounded.isNotEmpty()) {
            bounded.removeAt(0)
            text = bounded.joinToString("\n", transform = ::encode)
        }
        file.parentFile?.mkdirs()
        val temp = File(file.parentFile, file.name + ".tmp")
        temp.writeText(text)
        Files.move(temp.toPath(), file.toPath(), StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
    }
}
