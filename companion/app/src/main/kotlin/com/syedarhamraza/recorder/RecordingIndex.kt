package com.syedarhamraza.recorder

import android.content.Context
import org.json.JSONObject
import java.io.File

/**
 * What a file name can't say about a recording: `{direction: in|out, simId, starred, title}`,
 * in `recordings/index.json` keyed by file name. Entries for deleted files are dropped on write.
 */
object RecordingIndex {
    private fun file(context: Context) = File(RecordingService.dir(context), "index.json")

    @Synchronized
    fun read(context: Context): JSONObject = try {
        JSONObject(file(context).readText())
    } catch (_: Exception) {
        JSONObject()
    }

    @Synchronized
    fun update(context: Context, name: String, change: (JSONObject) -> Unit) {
        val all = read(context)
        val entry = all.optJSONObject(name) ?: JSONObject()
        change(entry)
        all.put(name, entry)
        val dir = RecordingService.dir(context)
        all.keys().asSequence().toList().filter { !File(dir, it).exists() }.forEach(all::remove)
        file(context).writeText(all.toString())
    }

    fun starred(context: Context): Set<String> {
        val all = read(context)
        return all.keys().asSequence().filter { all.optJSONObject(it)?.optBoolean("starred") == true }.toSet()
    }
}
