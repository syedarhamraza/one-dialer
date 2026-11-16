package com.syedarhamraza.dialer

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.MotionEvent
import androidx.core.view.WindowCompat
import com.syedarhamraza.dialer.telecom.CallManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun onResume() {
        super.onResume()
        LagDiagnostics.foreground("main", true)
        // Again on each resume: OPPO resets it, and the user may have changed it in Settings.
        HighRefresh.apply(this)
        AutoBackup.runIfDue(this)
    }

    override fun onPause() {
        LagDiagnostics.foreground("main", false)
        super.onPause()
    }

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        LagDiagnostics.touch("main", event)
        return super.dispatchTouchEvent(event)
    }

    private var bridge: CallBridge? = null
    private var pendingRoleResult: MethodChannel.Result? = null
    private var pendingPhotoResult: MethodChannel.Result? = null
    private var pendingPhotoMax = 720
    private var pendingRingtoneResult: MethodChannel.Result? = null
    private var pendingVcfResult: MethodChannel.Result? = null
    private var pendingBackupResult: MethodChannel.Result? = null

    /** Back up now with no folder yet: picks the folder, then backs up (true) or only picks it (false). */
    private var pendingFolderResult: MethodChannel.Result? = null
    private var backUpAfterFolder = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Android 15 forces edge-to-edge for SDK 35; opting in on older versions too keeps them the same.
        WindowCompat.enableEdgeToEdge(window)
        Thread { AppIcons.repair(applicationContext) }.start()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = CallBridge(applicationContext, flutterEngine.dartExecutor.binaryMessenger).also {
            it.roleRequester = ::requestRole
            it.photoPicker = ::pickPhoto
            it.photoTaker = ::takePhoto
            it.vcfPicker = ::pickVcf
            it.settingsBackup = ::settingsBackup
            it.backupFolderChooser = { result -> chooseBackupFolder(result, backUp = false) }
            it.ringtonePicker = ::pickRingtone
            it.pendingDialNumber = dialNumberFrom(intent)
            it.pendingOpenRecents = intent.getBooleanExtra(EXTRA_OPEN_RECENTS, false)
            it.pendingContactAction = contactActionFrom(intent)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        bridge?.dispose()
        bridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        dialNumberFrom(intent)?.let { bridge?.sendDialNumber(it) }
        if (intent.getBooleanExtra(EXTRA_OPEN_RECENTS, false)) bridge?.sendOpenRecents()
        contactActionFrom(intent)?.let { bridge?.sendContactAction(it) }
    }

    /** Asks for [role] (dialer or call screening); the result is whether it's held afterwards. */
    private fun requestRole(role: String, result: MethodChannel.Result) {
        val roles = getSystemService(RoleManager::class.java)
        if (roles.isRoleHeld(role)) return result.success(true)
        if (!roles.isRoleAvailable(role)) return result.success(false)
        pendingRoleResult?.success(false)
        pendingRoleResult = result
        @Suppress("DEPRECATION") // FlutterActivity is not a ComponentActivity, so no ActivityResult API
        startActivityForResult(roles.createRequestRoleIntent(role), REQUEST_ROLE)
    }

    /** Android's photo picker (no storage permission needed); falls back to "get content". */
    private fun pickPhoto(max: Int, result: MethodChannel.Result) {
        pendingPhotoResult?.success(null)
        pendingPhotoResult = result
        pendingPhotoMax = max
        val intent = if (android.os.Build.VERSION.SDK_INT >= 33) {
            Intent(android.provider.MediaStore.ACTION_PICK_IMAGES)
        } else {
            Intent(Intent.ACTION_GET_CONTENT).setType("image/*")
        }
        @Suppress("DEPRECATION")
        startActivityForResult(intent, REQUEST_PHOTO)
    }

    /** Manage contacts › Import: a .vcf from the files app (no storage permission needed). */
    private fun pickVcf(result: MethodChannel.Result) {
        pendingVcfResult?.success(null)
        pendingVcfResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("*/*")
            .putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("text/x-vcard", "text/vcard", "text/directory"))
        @Suppress("DEPRECATION")
        startActivityForResult(intent, REQUEST_VCF)
    }

    /**
     * Settings › Back up & restore. Back up now ([export]) writes the one backup file in the
     * picked folder (picking it first if there is none); Restore picks the file to read, opening
     * on the backup folder. The result is true when done (a restore restarts the app instead),
     * false for a file that isn't a backup or a folder that can't be written, null when cancelled.
     */
    private fun settingsBackup(export: Boolean, result: MethodChannel.Result) {
        if (export) {
            if (AutoBackup.tree(this) == null) return chooseBackupFolder(result, backUp = true)
            val app = applicationContext
            Thread {
                val ok = AutoBackup.write(app)
                runOnUiThread { result.success(ok) }
            }.start()
            return
        }
        // A restore restarts the process, which would drop the call.
        if (CallManager.all().isNotEmpty()) return result.error("IN_CALL", null, null)
        pendingBackupResult?.success(null)
        pendingBackupResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("*/*")
            .putExtra(android.provider.DocumentsContract.EXTRA_INITIAL_URI, AutoBackup.documentsUri)
        @Suppress("DEPRECATION")
        startActivityForResult(intent, REQUEST_IMPORT)
    }

    /** The folder for backups, picked once in the system picker (opening on Documents). */
    private fun chooseBackupFolder(result: MethodChannel.Result, backUp: Boolean) {
        pendingFolderResult?.success(null)
        pendingFolderResult = result
        backUpAfterFolder = backUp
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
            .putExtra(android.provider.DocumentsContract.EXTRA_INITIAL_URI, AutoBackup.documentsUri)
        @Suppress("DEPRECATION")
        startActivityForResult(intent, REQUEST_BACKUP_FOLDER)
    }

    private fun finishRestore(uri: android.net.Uri, result: MethodChannel.Result) = Thread {
        val outcome = runCatching { contentResolver.openInputStream(uri)!!.use { SettingsBackup.import(this, it) } }
        runOnUiThread {
            val done = outcome.getOrElse { return@runOnUiThread result.error("FAILED", it.message, null) }
            if (!done) return@runOnUiThread result.success(false)
            // Every preference is cached in memory (DataStore, SharedPreferences): start afresh.
            startActivity(Intent.makeRestartActivityTask(android.content.ComponentName(this, MainActivity::class.java)))
            Runtime.getRuntime().exit(0)
        }
    }.start()

    /**
     * The camera app's quick capture: a small preview bitmap, which is plenty for a contact
     * photo and needs no CAMERA permission or FileProvider (the app declares no CAMERA).
     */
    private fun takePhoto(result: MethodChannel.Result) {
        pendingPhotoResult?.success(null)
        pendingPhotoResult = result
        @Suppress("DEPRECATION")
        runCatching { startActivityForResult(Intent(android.provider.MediaStore.ACTION_IMAGE_CAPTURE), REQUEST_CAMERA) }
            .onFailure {
                pendingPhotoResult = null
                result.error("NO_CAMERA", it.message, null)
            }
    }

    /** Android's ringtone picker with the contact's current tone selected; "Default" comes back as "". */
    private fun pickRingtone(current: String?, result: MethodChannel.Result) {
        pendingRingtoneResult?.success(null)
        pendingRingtoneResult = result
        val intent = Intent(android.media.RingtoneManager.ACTION_RINGTONE_PICKER)
            .putExtra(android.media.RingtoneManager.EXTRA_RINGTONE_TYPE, android.media.RingtoneManager.TYPE_RINGTONE)
            .putExtra(android.media.RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            // No "Silent": AOSP Contacts doesn't offer it per contact either.
            .putExtra(android.media.RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            .putExtra(
                android.media.RingtoneManager.EXTRA_RINGTONE_EXISTING_URI,
                current?.let(android.net.Uri::parse) ?: android.provider.Settings.System.DEFAULT_RINGTONE_URI,
            )
        @Suppress("DEPRECATION")
        startActivityForResult(intent, REQUEST_RINGTONE)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_BACKUP_FOLDER) {
            val result = pendingFolderResult ?: return
            pendingFolderResult = null
            val uri = data?.data.takeIf { resultCode == RESULT_OK } ?: return result.success(null)
            val picked = runCatching { AutoBackup.setTree(this, uri) }
            if (picked.isFailure) return result.error("FAILED", picked.exceptionOrNull()?.message, null)
            if (!backUpAfterFolder) return result.success(AutoBackup.status(this))
            val app = applicationContext
            Thread {
                val ok = AutoBackup.write(app)
                runOnUiThread { result.success(ok) }
            }.start()
            return
        }
        if (requestCode == REQUEST_IMPORT) {
            val result = pendingBackupResult ?: return
            pendingBackupResult = null
            val uri = data?.data.takeIf { resultCode == RESULT_OK } ?: return result.success(null)
            // shortcut: a call that starts during the second the import takes still drops; rare enough.
            if (CallManager.all().isNotEmpty()) return result.error("IN_CALL", null, null)
            finishRestore(uri, result)
            return
        }
        if (requestCode == REQUEST_VCF) {
            val result = pendingVcfResult ?: return
            pendingVcfResult = null
            val uri = data?.data.takeIf { resultCode == RESULT_OK } ?: return result.success(null)
            Thread {
                val text = runCatching {
                    contentResolver.openInputStream(uri)?.use { it.readBytes().toString(Charsets.UTF_8) }
                }.getOrNull()
                runOnUiThread { result.success(text) }
            }.start()
            return
        }
        if (requestCode == REQUEST_RINGTONE) {
            val result = pendingRingtoneResult ?: return
            pendingRingtoneResult = null
            if (resultCode != RESULT_OK) return result.success(null)
            @Suppress("DEPRECATION")
            val picked = data?.getParcelableExtra<android.net.Uri>(android.media.RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
            // "Default" comes back as the default-ringtone URI (→ "", meaning clear the custom tone).
            result.success(
                if (picked == null || picked == android.provider.Settings.System.DEFAULT_RINGTONE_URI) "" else picked.toString(),
            )
            return
        }
        if (requestCode == REQUEST_PHOTO) {
            val result = pendingPhotoResult ?: return
            pendingPhotoResult = null
            val uri = data?.data.takeIf { resultCode == RESULT_OK } ?: return result.success(null)
            Thread {
                val bytes = runCatching { scaledJpeg(uri, pendingPhotoMax) }.getOrNull()
                runOnUiThread { result.success(bytes) }
            }.start()
            return
        }
        if (requestCode == REQUEST_CAMERA) {
            val result = pendingPhotoResult ?: return
            pendingPhotoResult = null
            @Suppress("DEPRECATION")
            val bitmap = data?.extras?.get("data") as? android.graphics.Bitmap
            if (resultCode != RESULT_OK || bitmap == null) return result.success(null)
            result.success(
                java.io.ByteArrayOutputStream().use {
                    bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 95, it)
                    it.toByteArray()
                },
            )
            return
        }
        if (requestCode == REQUEST_ROLE) {
            pendingRoleResult?.success(resultCode == RESULT_OK)
            pendingRoleResult = null
        }
    }

    /** Decodes [uri] at most [max] px on its long side (contacts store small photos anyway). */
    private fun scaledJpeg(uri: android.net.Uri, max: Int): ByteArray {
        val source = android.graphics.ImageDecoder.createSource(contentResolver, uri)
        val bitmap = android.graphics.ImageDecoder.decodeBitmap(source) { decoder, info, _ ->
            val longSide = maxOf(info.size.width, info.size.height)
            if (longSide > max) {
                val scale = max.toFloat() / longSide
                decoder.setTargetSize((info.size.width * scale).toInt(), (info.size.height * scale).toInt())
            }
            decoder.allocator = android.graphics.ImageDecoder.ALLOCATOR_SOFTWARE
        }
        return java.io.ByteArrayOutputStream().use {
            bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 90, it)
            it.toByteArray()
        }
    }

    /**
     * What another app asked for: a contact to show or edit (`id`), or a new contact (`phone`,
     * `name` from the insert extras). Null otherwise.
     */
    private fun contactActionFrom(intent: Intent?): Map<String, String?>? {
        intent ?: return null
        return when (intent.action) {
            Intent.ACTION_VIEW, Intent.ACTION_EDIT, Intent.ACTION_INSERT_OR_EDIT -> {
                val id = intent.data?.let(::contactIdOf)
                when {
                    id != null -> mapOf("kind" to if (intent.action == Intent.ACTION_VIEW) "view" else "edit", "id" to id)
                    intent.action == Intent.ACTION_INSERT_OR_EDIT -> insertAction(intent)
                    else -> null
                }
            }
            Intent.ACTION_INSERT -> insertAction(intent)
            else -> null
        }
    }

    /**
     * Another app's "add contact". QR scanners put a card's numbers in PHONE, SECONDARY_PHONE and
     * TERTIARY_PHONE, or in the DATA rows, sometimes as non-String CharSequences; "phone" carries
     * them all, one per line.
     */
    private fun insertAction(intent: Intent): Map<String, String?> {
        fun text(key: String) = intent.getCharSequenceExtra(key)?.toString()?.trim()?.takeIf { it.isNotEmpty() }
        @Suppress("DEPRECATION") // getParcelableArrayListExtra(String, Class) is API 33+
        val rows = runCatching {
            intent.getParcelableArrayListExtra<android.content.ContentValues>(
                android.provider.ContactsContract.Intents.Insert.DATA,
            )
        }.getOrNull().orEmpty()
        fun rowValues(mime: String, column: String) =
            rows.filter { it.getAsString(android.provider.ContactsContract.Data.MIMETYPE) == mime }
                .mapNotNull { it.getAsString(column)?.trim()?.takeIf(String::isNotEmpty) }
        val phones = listOfNotNull(
            text(android.provider.ContactsContract.Intents.Insert.PHONE),
            text(android.provider.ContactsContract.Intents.Insert.SECONDARY_PHONE),
            text(android.provider.ContactsContract.Intents.Insert.TERTIARY_PHONE),
        ) + rowValues(
            android.provider.ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE,
            android.provider.ContactsContract.CommonDataKinds.Phone.NUMBER,
        )
        val name = text(android.provider.ContactsContract.Intents.Insert.NAME) ?: rowValues(
            android.provider.ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE,
            android.provider.ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME,
        ).firstOrNull()
        return mapOf(
            "kind" to "insert",
            "phone" to phones.distinctBy { it.filter { c -> c.isDigit() || c == '+' } }.joinToString("\n").ifEmpty { null },
            "name" to name,
        )
    }

    /** A contact (or lookup, or raw contact) URI's contact id. */
    private fun contactIdOf(uri: android.net.Uri): String? = runCatching {
        val contact = android.provider.ContactsContract.Contacts.lookupContact(contentResolver, uri) ?: uri
        contentResolver.query(contact, arrayOf(android.provider.ContactsContract.Contacts._ID), null, null, null)
            ?.use { c -> if (c.moveToFirst()) c.getLong(0).toString() else null }
    }.getOrNull()

    private fun dialNumberFrom(intent: Intent?): String? =
        intent?.data?.takeIf { it.scheme == "tel" }?.schemeSpecificPart

    companion object {
        private const val REQUEST_ROLE = 1001
        private const val REQUEST_PHOTO = 1002
        private const val REQUEST_RINGTONE = 1003
        private const val REQUEST_CAMERA = 1004
        private const val REQUEST_VCF = 1005
        private const val REQUEST_BACKUP_FOLDER = 1006
        private const val REQUEST_IMPORT = 1007
        private const val EXTRA_OPEN_RECENTS = "open_recents"

        fun openRecentsIntent(context: Context): Intent =
            Intent(context, MainActivity::class.java)
                .putExtra(EXTRA_OPEN_RECENTS, true)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
    }
}
