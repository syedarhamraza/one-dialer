package com.syedarhamraza.dialer

import android.Manifest
import android.app.role.RoleManager
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.provider.CallLog
import android.media.AudioManager
import android.media.ToneGenerator
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.telecom.VideoProfile
import com.syedarhamraza.dialer.telecom.BlockingPrefs
import com.syedarhamraza.dialer.telecom.CallLogSource
import com.syedarhamraza.dialer.telecom.CallManager
import com.syedarhamraza.dialer.telecom.MissedCallNotifier
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Platform channels between Flutter and Telecom. One instance per Flutter engine
 * (main UI engine and the pre-warmed in-call engine).
 *
 * Mirrors `lib/core/telecom/telecom_bridge.dart`; keep method names in sync.
 */
class CallBridge(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val methods = MethodChannel(messenger, METHOD_CHANNEL)
    private val events = EventChannel(messenger, EVENT_CHANNEL)
    private var listener: (() -> Unit)? = null
    private var toneGenerator: ToneGenerator? = null
    private val main = Handler(Looper.getMainLooper())

    private val callLogObserver = object : ContentObserver(main) {
        override fun onChange(selfChange: Boolean) {
            methods.invokeMethod("onCallLogChanged", null)
        }
    }

    /** Set by [MainActivity], which owns the activity result for the role request. */
    var roleRequester: ((String, MethodChannel.Result) -> Unit)? = null

    /** A `tel:` number the app was opened with, handed to Flutter once. */
    var pendingDialNumber: String? = null

    /** Opened from the missed-call notification; handed to Flutter once. */
    var pendingOpenRecents = false

    init {
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
        context.contentResolver.registerContentObserver(CallLog.Calls.CONTENT_URI, true, callLogObserver)
    }

    fun dispose() {
        onCancel(null)
        toneGenerator?.release()
        toneGenerator = null
        context.contentResolver.unregisterContentObserver(callLogObserver)
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
    }

    fun sendDialNumber(number: String) = methods.invokeMethod("onDialIntent", number)

    fun sendOpenRecents() = methods.invokeMethod("onOpenRecents", null)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isDefaultDialer" -> result.success(isDefaultDialer())
            "requestDefaultDialer" -> requestRole(RoleManager.ROLE_DIALER, result)
            // Android only lets the call-screening role holder screen calls, even for the default dialer.
            "requestScreeningRole" -> requestRole(RoleManager.ROLE_CALL_SCREENING, result)
            "hasScreeningRole" -> result.success(
                context.getSystemService(RoleManager::class.java).isRoleHeld(RoleManager.ROLE_CALL_SCREENING),
            )
            "consumeDialNumber" -> result.success(pendingDialNumber).also { pendingDialNumber = null }
            "consumeOpenRecents" -> result.success(pendingOpenRecents).also { pendingOpenRecents = false }
            "getCallLog" -> inBackground(result) { CallLogSource.query(context) }
            "deleteCalls" -> {
                val ids = call.argument<List<Number>>("ids").orEmpty().map(Number::toLong)
                inBackground(result) { CallLogSource.delete(context, ids) }
            }
            "markMissedRead" -> inBackground(result) {
                CallLogSource.markMissedRead(context)
                MissedCallNotifier.cancel(context)
            }
            "getState" -> result.success(CallManager.snapshot())
            "placeCall" -> placeCall(call.argument<String>("number"), call.argument<String>("simId"), result)
            "getSims" -> getSims(result)
            "getQuickReplies" -> result.success(com.syedarhamraza.dialer.telecom.QuickReplies.read(context))
            "setQuickReplies" -> {
                com.syedarhamraza.dialer.telecom.QuickReplies.write(context, call.argument<List<String>>("replies").orEmpty())
                result.success(null)
            }
            "getCallHealth" -> result.success(callHealth())
            "openSystemSettings" -> openSystemSettings(call.argument<String>("page"), result)
            "getBlocking" -> BlockingPrefs.read(context).let {
                result.success(mapOf("blockHidden" to it.blockHidden, "blockNonContacts" to it.blockNonContacts))
            }
            "setBlocking" -> {
                BlockingPrefs.write(
                    context,
                    com.syedarhamraza.dialer.telecom.BlockingSettings(
                        blockHidden = call.argument<Boolean>("blockHidden") == true,
                        blockNonContacts = call.argument<Boolean>("blockNonContacts") == true,
                    ),
                )
                result.success(null)
            }
            "openDialer" -> {
                // "Add call": the keypad places the next call and Telecom holds the current one.
                context.startActivity(
                    android.content.Intent(context, MainActivity::class.java)
                        .addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                result.success(null)
            }
            "sendSms" -> {
                val number = call.argument<String>("number").orEmpty()
                val intent = android.content.Intent(android.content.Intent.ACTION_SENDTO, Uri.fromParts("smsto", number, null))
                    .addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                runCatching { context.startActivity(intent) }
                    .onSuccess { result.success(null) }
                    .onFailure { result.error("NO_SMS_APP", it.message, null) }
            }
            "playTone" -> {
                call.argument<String>("digit")?.firstOrNull()?.let(::playTone)
                result.success(null)
            }
            "stopTone" -> {
                toneGenerator?.stopTone()
                result.success(null)
            }
            "setMuted" -> {
                CallManager.service?.setMuted(call.argument<Boolean>("muted") == true)
                result.success(null)
            }
            "setAudioRoute" -> {
                val route = call.argument<String>("route")?.let(CallManager::routeValue)
                @Suppress("DEPRECATION")
                if (route != null) CallManager.service?.setAudioRoute(route)
                result.success(null)
            }
            else -> withCall(call, result)
        }
    }

    /** Methods that act on a single call identified by `id`. */
    private fun withCall(call: MethodCall, result: MethodChannel.Result) {
        val target = call.argument<String>("id")?.let(CallManager::get)
            ?: return result.error("NO_CALL", "Unknown call id", null)
        when (call.method) {
            "answer" -> target.answer(VideoProfile.STATE_AUDIO_ONLY)
            "reject" -> target.reject(false, null)
            "rejectWithMessage" -> target.reject(true, call.argument<String>("message"))
            "hangUp" -> target.disconnect()
            "hold" -> target.hold()
            "unhold" -> target.unhold()
            "playDtmf" -> call.argument<String>("digit")?.firstOrNull()?.let(target::playDtmfTone)
            "stopDtmf" -> target.stopDtmfTone()
            "merge" -> target.conferenceableCalls.firstOrNull()?.let(target::conference)
                ?: target.mergeConference()
            "swap" -> target.swapConference()
            else -> return result.notImplemented()
        }
        result.success(null)
    }

    /** Runs [work] off the main thread; a missing call-log permission becomes a NO_PERMISSION error. */
    private fun inBackground(result: MethodChannel.Result, work: () -> Any?) {
        Thread {
            val outcome = runCatching(work)
            main.post {
                outcome.fold(
                    onSuccess = { result.success(if (it is Unit) null else it) },
                    onFailure = {
                        if (it is SecurityException) result.error("NO_PERMISSION", it.message, null)
                        else result.error("FAILED", it.message, null)
                    },
                )
            }
        }.start()
    }

    private fun requestRole(role: String, result: MethodChannel.Result) = roleRequester?.invoke(role, result)
        ?: result.error("NO_ACTIVITY", "Roles can only be requested from the main screen", null)

    /** What incoming calls need to work, plus the app version for Settings › About. */
    private fun callHealth(): Map<String, Any?> {
        val notifications = context.getSystemService(android.app.NotificationManager::class.java)
        val roles = context.getSystemService(RoleManager::class.java)
        val info = context.packageManager.getPackageInfo(context.packageName, 0)
        return mapOf(
            "isDefaultDialer" to isDefaultDialer(),
            "notificationsEnabled" to notifications.areNotificationsEnabled(),
            // Android 14+ lets users revoke full-screen intents; without it calls only show as a notification.
            "fullScreenAllowed" to if (android.os.Build.VERSION.SDK_INT >= 34) notifications.canUseFullScreenIntent() else true,
            "screensCalls" to roles.isRoleHeld(RoleManager.ROLE_CALL_SCREENING),
            "version" to info.versionName,
            "build" to info.longVersionCode,
        )
    }

    /** Opens the system screen that fixes a [callHealth] problem, or a web page (`url:` prefix). */
    private fun openSystemSettings(page: String?, result: MethodChannel.Result) {
        val pkg = context.packageName
        val intent = when {
            page == "notifications" -> android.content.Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, pkg)
            page == "fullScreen" && android.os.Build.VERSION.SDK_INT >= 34 ->
                android.content.Intent(android.provider.Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, Uri.parse("package:$pkg"))
            page == "defaultApps" -> android.content.Intent(android.provider.Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
            page != null && page.startsWith("url:") -> android.content.Intent(android.content.Intent.ACTION_VIEW, Uri.parse(page.removePrefix("url:")))
            else -> android.content.Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$pkg"))
        }.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        runCatching { context.startActivity(intent) }
            .onSuccess { result.success(null) }
            .onFailure { result.error("NO_ACTIVITY", it.message, null) }
    }

    private fun isDefaultDialer(): Boolean =
        context.getSystemService(RoleManager::class.java).isRoleHeld(RoleManager.ROLE_DIALER)

    private fun placeCall(number: String?, simId: String?, result: MethodChannel.Result) {
        if (number.isNullOrBlank()) return result.error("NO_NUMBER", "Number is empty", null)
        if (context.checkSelfPermission(Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            return result.error("NO_PERMISSION", "CALL_PHONE not granted", null)
        }
        val telecom = context.getSystemService(TelecomManager::class.java)
        val extras = Bundle()
        simId?.let(::simHandle)?.let { extras.putParcelable(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, it) }
        telecom.placeCall(Uri.fromParts("tel", number, null), extras)
        result.success(null)
    }

    /** Call-capable SIMs, in slot order. `id` round-trips back to [placeCall] as `simId`. */
    private fun getSims(result: MethodChannel.Result) {
        if (context.checkSelfPermission(Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
            return result.success(emptyList<Any>())
        }
        val telecom = context.getSystemService(TelecomManager::class.java)
        val default = telecom.getDefaultOutgoingPhoneAccount("tel")
        val sims = telecom.callCapablePhoneAccounts.mapNotNull { handle ->
            val account = telecom.getPhoneAccount(handle) ?: return@mapNotNull null
            // Only real SIM cards; VoIP/SIP calling accounts aren't SIM buttons.
            if (!account.hasCapabilities(android.telecom.PhoneAccount.CAPABILITY_SIM_SUBSCRIPTION)) return@mapNotNull null
            mapOf(
                "id" to "${handle.componentName.flattenToString()}|${handle.id}",
                "label" to account.label?.toString(),
                "color" to account.highlightColor,
                "isDefault" to (handle == default),
            )
        }
        result.success(sims)
    }

    private fun simHandle(id: String): PhoneAccountHandle? {
        val component = ComponentName.unflattenFromString(id.substringBefore('|')) ?: return null
        return PhoneAccountHandle(component, id.substringAfter('|'))
    }

    /** Keypad tone, only when the system "Dial pad tones" setting is on and the ringer isn't silenced. */
    private fun playTone(digit: Char) {
        val tone = TONES[digit] ?: return
        val tonesOn = Settings.System.getInt(context.contentResolver, Settings.System.DTMF_TONE_WHEN_DIALING, 1) == 1
        val ringerNormal = context.getSystemService(AudioManager::class.java).ringerMode == AudioManager.RINGER_MODE_NORMAL
        if (!tonesOn || !ringerNormal) return
        val generator = toneGenerator ?: runCatching { ToneGenerator(AudioManager.STREAM_DTMF, TONE_VOLUME) }
            .getOrNull()?.also { toneGenerator = it } ?: return
        generator.startTone(tone, TONE_LENGTH_MS)
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        val l = { sink.success(CallManager.snapshot()) }
        listener = l
        CallManager.addListener(l)
        l()
    }

    override fun onCancel(arguments: Any?) {
        listener?.let(CallManager::removeListener)
        listener = null
    }

    companion object {
        const val METHOD_CHANNEL = "com.syedarhamraza.dialer/telecom"
        const val EVENT_CHANNEL = "com.syedarhamraza.dialer/call_state"
        private const val TONE_VOLUME = 80
        private const val TONE_LENGTH_MS = 150

        private val TONES = mapOf(
            '0' to ToneGenerator.TONE_DTMF_0, '1' to ToneGenerator.TONE_DTMF_1,
            '2' to ToneGenerator.TONE_DTMF_2, '3' to ToneGenerator.TONE_DTMF_3,
            '4' to ToneGenerator.TONE_DTMF_4, '5' to ToneGenerator.TONE_DTMF_5,
            '6' to ToneGenerator.TONE_DTMF_6, '7' to ToneGenerator.TONE_DTMF_7,
            '8' to ToneGenerator.TONE_DTMF_8, '9' to ToneGenerator.TONE_DTMF_9,
            '*' to ToneGenerator.TONE_DTMF_S, '#' to ToneGenerator.TONE_DTMF_P,
        )
    }
}
