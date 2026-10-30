package com.syedarhamraza.dialer

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun onResume() {
        super.onResume()
        LagDiagnostics.foreground("main", true)
    }

    override fun onPause() {
        LagDiagnostics.foreground("main", false)
        super.onPause()
    }

    private var bridge: CallBridge? = null
    private var pendingRoleResult: MethodChannel.Result? = null
    private var pendingPhotoResult: MethodChannel.Result? = null
    private var pendingRingtoneResult: MethodChannel.Result? = null
    private var pendingVcfResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Android 15 forces edge-to-edge for SDK 35; opting in on older versions too keeps them the same.
        WindowCompat.enableEdgeToEdge(window)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = CallBridge(applicationContext, flutterEngine.dartExecutor.binaryMessenger).also {
            it.roleRequester = ::requestRole
            it.photoPicker = ::pickPhoto
            it.photoTaker = ::takePhoto
            it.vcfPicker = ::pickVcf
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
    private fun pickPhoto(result: MethodChannel.Result) {
        pendingPhotoResult?.success(null)
        pendingPhotoResult = result
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
                val bytes = runCatching { scaledJpeg(uri) }.getOrNull()
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

    /** Decodes [uri] at most [PHOTO_MAX] px on its long side (contacts store small photos anyway). */
    private fun scaledJpeg(uri: android.net.Uri): ByteArray {
        val source = android.graphics.ImageDecoder.createSource(contentResolver, uri)
        val bitmap = android.graphics.ImageDecoder.decodeBitmap(source) { decoder, info, _ ->
            val longSide = maxOf(info.size.width, info.size.height)
            if (longSide > PHOTO_MAX) {
                val scale = PHOTO_MAX.toFloat() / longSide
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
     * What the Contacts icon or another app asked for: the Contacts tab, a contact to show or
     * edit (`id`), or a new contact (`phone`, `name` from the insert extras). Null otherwise.
     */
    private fun contactActionFrom(intent: Intent?): Map<String, String?>? {
        intent ?: return null
        val fromContactsIcon = intent.component?.className?.endsWith(".ContactsLauncher") == true
        return when (intent.action) {
            Intent.ACTION_VIEW, Intent.ACTION_EDIT, Intent.ACTION_INSERT_OR_EDIT -> {
                val id = intent.data?.let(::contactIdOf)
                when {
                    id != null -> mapOf("kind" to if (intent.action == Intent.ACTION_VIEW) "view" else "edit", "id" to id)
                    intent.action == Intent.ACTION_INSERT_OR_EDIT -> insertAction(intent)
                    fromContactsIcon -> mapOf("kind" to "tab")
                    else -> null
                }
            }
            Intent.ACTION_INSERT -> insertAction(intent)
            else -> if (fromContactsIcon) mapOf("kind" to "tab") else null
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
        private const val PHOTO_MAX = 720
        private const val EXTRA_OPEN_RECENTS = "open_recents"

        fun openRecentsIntent(context: Context): Intent =
            Intent(context, MainActivity::class.java)
                .putExtra(EXTRA_OPEN_RECENTS, true)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
    }
}
