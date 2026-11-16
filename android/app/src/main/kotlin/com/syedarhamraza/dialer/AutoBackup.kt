package com.syedarhamraza.dialer

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract

/**
 * Settings › Back up & restore: one backup file, `One Dialer/One Dialer backup.zip` in a folder
 * the person picked once (the picker opens on Documents), overwritten on every backup so it never
 * piles up. Auto backup writes it when due, checked whenever the app opens or a call ends: a
 * dialer runs often, and settings only change inside it, so no scheduler is needed.
 *
 * Its own preferences (the folder's permission is this install's only) are neither exported
 * ([SettingsBackup.PREFS]) nor in Android's backup (`backup_rules.xml`).
 */
object AutoBackup {
    const val PREFS = "backup"
    const val FOLDER = "One Dialer"
    const val FILE = "One Dialer backup.zip"
    private const val EXTERNAL = "com.android.externalstorage.documents"

    /** Where the folder picker and the restore file picker open: Documents. */
    val documentsUri: Uri by lazy { DocumentsContract.buildDocumentUri(EXTERNAL, "primary:Documents") }

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun tree(context: Context): Uri? = prefs(context).getString("tree", null)?.let(Uri::parse)

    /** The page's state: `interval` (hours, 0 off), `path` (null: no folder yet), `last` (millis, 0 never), `failed`. */
    fun status(context: Context): Map<String, Any?> {
        val p = prefs(context)
        return mapOf(
            "interval" to p.getInt("interval_h", 0),
            "path" to tree(context)?.let { displayPath(DocumentsContract.getTreeDocumentId(it)) },
            "last" to p.getLong("last", 0L),
            "failed" to p.getBoolean("failed", false),
        )
    }

    fun setInterval(context: Context, hours: Int) = prefs(context).edit().putInt("interval_h", hours).apply()

    /** Keeps the picked folder's permission across restarts, dropping the old folder's. */
    fun setTree(context: Context, uri: Uri) {
        val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        val resolver = context.contentResolver
        tree(context)?.takeIf { it != uri }?.let { old -> runCatching { resolver.releasePersistableUriPermission(old, flags) } }
        resolver.takePersistableUriPermission(uri, flags)
        prefs(context).edit().putString("tree", uri.toString()).putBoolean("failed", false).apply()
    }

    /** Writes the backup over the last one; false (and marked failed) when the folder can't be written. */
    fun write(context: Context): Boolean {
        val tree = tree(context) ?: return false
        val ok = runCatching {
            val resolver = context.contentResolver
            val root = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
            val folder = child(context, tree, root, FOLDER)
                ?: DocumentsContract.createDocument(resolver, root, DocumentsContract.Document.MIME_TYPE_DIR, FOLDER)!!
            val file = child(context, tree, folder, FILE)
                ?: DocumentsContract.createDocument(resolver, folder, "application/zip", FILE)!!
            resolver.openOutputStream(file, "wt")!!.use { SettingsBackup.export(context, it) }
        }.isSuccess
        prefs(context).edit().apply {
            if (ok) putLong("last", System.currentTimeMillis())
            putBoolean("failed", !ok)
        }.apply()
        return ok
    }

    /** Backs up in the background when auto backup is on and the last one is older than its interval. */
    fun runIfDue(context: Context) {
        val p = prefs(context)
        if (!isDue(System.currentTimeMillis(), p.getLong("last", 0L), p.getInt("interval_h", 0)) || tree(context) == null) return
        val app = context.applicationContext
        Thread { write(app) }.start()
    }

    fun isDue(now: Long, last: Long, intervalHours: Int): Boolean =
        intervalHours > 0 && now - last >= intervalHours * 3_600_000L

    /** The named document in [parent], found by its display name (a folder or the backup file). */
    private fun child(context: Context, tree: Uri, parent: Uri, name: String): Uri? {
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getDocumentId(parent))
        val columns = arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME)
        context.contentResolver.query(children, columns, null, null, null)?.use { c ->
            while (c.moveToNext()) {
                if (c.getString(1) == name) return DocumentsContract.buildDocumentUriUsingTree(tree, c.getString(0))
            }
        }
        return null
    }

    /**
     * The backup file's path as the Files app shows it, from the picked folder's document id:
     * `primary:Documents` is the phone's storage, `1A2B-3C4D:Backups` an SD card.
     */
    fun displayPath(treeDocumentId: String): String {
        val volume = treeDocumentId.substringBefore(':')
        val dir = treeDocumentId.substringAfter(':', "").trim('/')
        val root = if (volume == "primary") "/storage/emulated/0" else "/storage/$volume"
        return listOf(root, dir, FOLDER, FILE).filter { it.isNotEmpty() }.joinToString("/")
    }
}
