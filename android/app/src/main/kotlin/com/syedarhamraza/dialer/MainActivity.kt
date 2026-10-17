package com.syedarhamraza.dialer

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var bridge: CallBridge? = null
    private var pendingRoleResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = CallBridge(applicationContext, flutterEngine.dartExecutor.binaryMessenger).also {
            it.roleRequester = ::requestRole
            it.pendingDialNumber = dialNumberFrom(intent)
            it.pendingOpenRecents = intent.getBooleanExtra(EXTRA_OPEN_RECENTS, false)
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

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_ROLE) {
            pendingRoleResult?.success(resultCode == RESULT_OK)
            pendingRoleResult = null
        }
    }

    private fun dialNumberFrom(intent: Intent?): String? =
        intent?.data?.takeIf { it.scheme == "tel" }?.schemeSpecificPart

    companion object {
        private const val REQUEST_ROLE = 1001
        private const val EXTRA_OPEN_RECENTS = "open_recents"

        fun openRecentsIntent(context: Context): Intent =
            Intent(context, MainActivity::class.java)
                .putExtra(EXTRA_OPEN_RECENTS, true)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
    }
}
