package com.syedarhamraza.recorder

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ClipData
import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * One Dialer's only way in: `ContentResolver.call(content://AUTHORITY, method, arg, extras)`.
 * Every method checks the caller is One Dialer ([TrustedDialer]). Status changes are announced
 * with `notifyChange(STATUS_URI)`, which One Dialer observes.
 */
class RecordingsProvider : ContentProvider() {
    companion object {
        const val AUTHORITY = "com.syedarhamraza.onedialer.recorder.recordings"
        val STATUS_URI: Uri = Uri.parse("content://$AUTHORITY/status")

        fun notifyStatus(context: Context) = context.contentResolver.notifyChange(STATUS_URI, null)
    }

    override fun onCreate() = true

    override fun call(method: String, arg: String?, extras: Bundle?): Bundle? {
        val context = context ?: return null
        if (!TrustedDialer.isTrusted(context, callingPackage)) throw SecurityException("Only One Dialer may use the recorder")
        return when (method) {
            "status" -> status(context)
            "start" -> {
                RecordingService.start(context, extras)
                status(context)
            }
            "stop" -> {
                RecordingService.stop(context)
                status(context)
            }
            "list" -> {
                RecordingService.prune(context)
                Bundle().apply { putString("json", list(context).toString()) }
            }
            "settings" -> Bundle().apply { putString("json", JSONObject(RecorderSettings.read(context)).toString()) }
            "setSetting" -> {
                @Suppress("DEPRECATION")
                RecorderSettings.write(context, arg ?: return null, extras?.get("value"))
                null
            }
            "setStar" -> {
                fileOf(context, arg)?.let { f -> RecordingIndex.update(context, f.name) { it.put("starred", extras?.getBoolean("starred") == true) } }
                null
            }
            "rename" -> {
                fileOf(context, arg)?.let { f -> RecordingIndex.update(context, f.name) { it.put("title", extras?.getString("title")?.trim().orEmpty()) } }
                null
            }
            "export" -> Bundle().apply { putBoolean("ok", fileOf(context, arg)?.let { export(context, it, extras?.getString("displayName")) } == true) }
            "delete" -> {
                fileOf(context, arg)?.takeIf { RecordingService.current?.name != it.name }?.delete()
                null
            }
            "deleteAll" -> {
                RecordingService.dir(context).listFiles()?.filter { it.name != RecordingService.current?.name }?.forEach { it.delete() }
                null
            }
            "open" -> fileOf(context, arg)?.let { Bundle().apply { putParcelable("intent", viewIntent(context, listOf(it), share = false)) } }
            // Several names joined by '|' (file names never contain one).
            "share" -> arg?.split('|')?.mapNotNull { fileOf(context, it) }?.takeIf { it.isNotEmpty() }
                ?.let { Bundle().apply { putParcelable("intent", viewIntent(context, it, share = true)) } }
            else -> null
        }
    }

    private fun status(context: Context) = Bundle().apply {
        putBoolean("accessibilityOn", RecordingService.accessibilityOn(context))
        putBoolean("micGranted", RecordingService.micGranted(context))
        putBoolean("notificationsOn", context.getSystemService(NotificationManager::class.java).areNotificationsEnabled())
        putBoolean("recording", RecordingService.current != null)
        putLong("startMillis", RecordingService.current?.startMillis ?: 0L)
        putString("error", RecordingService.lastError)
        putLong("bytes", RecordingService.dir(context).listFiles().orEmpty().filter { it.name.endsWith(".m4a") }.sumOf { it.length() })
        putLong("versionCode", context.packageManager.getPackageInfo(context.packageName, 0).longVersionCode)
    }

    private fun list(context: Context): JSONArray {
        val rows = RecordingService.dir(context).listFiles().orEmpty()
            .filter { it.name != RecordingService.current?.name }
            .mapNotNull { f -> RecordingFile.parse(f.name)?.let { f to it } }
            .sortedByDescending { it.second.startMillis }
        val index = RecordingIndex.read(context)
        return JSONArray(rows.map { (f, entry) ->
            val meta = index.optJSONObject(f.name) ?: JSONObject()
            JSONObject().put("name", f.name).put("number", entry.number ?: JSONObject.NULL)
                .put("startMillis", entry.startMillis).put("durationMs", duration(f)).put("bytes", f.length())
                .put("direction", meta.optString("direction")).put("simId", meta.optString("simId"))
                .put("starred", meta.optBoolean("starred")).put("title", meta.optString("title"))
        })
    }

    private fun duration(file: File): Long = try {
        MediaMetadataRetriever().use { it.setDataSource(file.path); it.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLong() ?: 0L }
    } catch (_: Exception) {
        0L
    }

    /** Only names [RecordingFile] produced, so `arg` can never point outside the folder. */
    private fun fileOf(context: Context, name: String?): File? =
        name?.takeIf { RecordingFile.parse(it) != null }?.let { File(RecordingService.dir(context), it) }?.takeIf { it.exists() }

    /** A PendingIntent One Dialer fires while it's in front; the content URI grant comes from us. */
    private fun viewIntent(context: Context, files: List<File>, share: Boolean): PendingIntent {
        val uris = files.map { FileProvider.getUriForFile(context, "${context.packageName}.files", it) }
        val clip = ClipData.newRawUri(null, uris[0]).apply { uris.drop(1).forEach { addItem(ClipData.Item(it)) } }
        val target = when {
            !share -> Intent(Intent.ACTION_VIEW).setDataAndType(uris[0], "audio/mp4")
            uris.size == 1 -> Intent.createChooser(
                Intent(Intent.ACTION_SEND).setType("audio/mp4").putExtra(Intent.EXTRA_STREAM, uris[0])
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION).apply { clipData = clip },
                null,
            )
            else -> Intent.createChooser(
                Intent(Intent.ACTION_SEND_MULTIPLE).setType("audio/mp4").putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(uris))
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION).apply { clipData = clip },
                null,
            )
        }
        val intent = target.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        return PendingIntent.getActivity(
            context, files.joinToString().hashCode() * 2 + (if (share) 1 else 0), intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    /** Save to phone: a copy in the shared Recordings/One Dialer folder (no storage permission on Android 10+). */
    private fun export(context: Context, file: File, displayName: String?): Boolean {
        val start = RecordingFile.parse(file.name)?.startMillis ?: file.lastModified()
        val stamp = java.text.SimpleDateFormat("yyyy-MM-dd HH-mm", java.util.Locale.ROOT).format(java.util.Date(start))
        val title = (displayName?.takeIf { it.isNotBlank() } ?: RecordingFile.parse(file.name)?.number ?: "Call")
            .replace(Regex("[\\\\/:*?\"<>|]"), "_")
        val folder = (if (Build.VERSION.SDK_INT >= 31) Environment.DIRECTORY_RECORDINGS else Environment.DIRECTORY_MUSIC) + "/One Dialer"
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, "$title $stamp.m4a")
            put(MediaStore.Audio.Media.MIME_TYPE, "audio/mp4")
            put(MediaStore.Audio.Media.RELATIVE_PATH, folder)
            put(MediaStore.Audio.Media.IS_PENDING, 1)
        }
        val resolver = context.contentResolver
        val uri = resolver.insert(MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY), values) ?: return false
        return try {
            resolver.openOutputStream(uri)!!.use { out -> file.inputStream().use { it.copyTo(out) } }
            resolver.update(uri, ContentValues().apply { put(MediaStore.Audio.Media.IS_PENDING, 0) }, null, null)
            true
        } catch (_: Exception) {
            resolver.delete(uri, null, null)
            false
        }
    }

    // The provider is only for call(); no table to query.
    override fun query(uri: Uri, p: Array<out String>?, s: String?, a: Array<out String>?, o: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, s: String?, a: Array<out String>?) = 0
    override fun update(uri: Uri, v: ContentValues?, s: String?, a: Array<out String>?) = 0
}
