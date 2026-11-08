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
import android.os.Bundle
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
                RecordingService.start(context, extras?.getString("number"), extras?.getLong("startMillis") ?: 0L)
                status(context)
            }
            "stop" -> {
                RecordingService.stop(context)
                status(context)
            }
            "list" -> Bundle().apply { putString("json", list(context).toString()) }
            "delete" -> {
                fileOf(context, arg)?.takeIf { RecordingService.current?.name != it.name }?.delete()
                null
            }
            "deleteAll" -> {
                RecordingService.dir(context).listFiles()?.filter { it.name != RecordingService.current?.name }?.forEach { it.delete() }
                null
            }
            "open", "share" -> fileOf(context, arg)?.let { Bundle().apply { putParcelable("intent", viewIntent(context, it, method == "share")) } }
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
        putLong("versionCode", context.packageManager.getPackageInfo(context.packageName, 0).longVersionCode)
    }

    private fun list(context: Context): JSONArray {
        val rows = RecordingService.dir(context).listFiles().orEmpty()
            .filter { it.name != RecordingService.current?.name }
            .mapNotNull { f -> RecordingFile.parse(f.name)?.let { f to it } }
            .sortedByDescending { it.second.startMillis }
        return JSONArray(rows.map { (f, entry) ->
            JSONObject().put("name", f.name).put("number", entry.number ?: JSONObject.NULL)
                .put("startMillis", entry.startMillis).put("durationMs", duration(f)).put("bytes", f.length())
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
    private fun viewIntent(context: Context, file: File, share: Boolean): PendingIntent {
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.files", file)
        val target = if (share) {
            Intent.createChooser(
                Intent(Intent.ACTION_SEND).setType("audio/mp4").putExtra(Intent.EXTRA_STREAM, uri)
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION).apply { clipData = ClipData.newRawUri(null, uri) },
                null,
            )
        } else {
            Intent(Intent.ACTION_VIEW).setDataAndType(uri, "audio/mp4")
        }
        val intent = target.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        return PendingIntent.getActivity(
            context, file.name.hashCode() * 2 + (if (share) 1 else 0), intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    // The provider is only for call(); no table to query.
    override fun query(uri: Uri, p: Array<out String>?, s: String?, a: Array<out String>?, o: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, s: String?, a: Array<out String>?) = 0
    override fun update(uri: Uri, v: ContentValues?, s: String?, a: Array<out String>?) = 0
}
