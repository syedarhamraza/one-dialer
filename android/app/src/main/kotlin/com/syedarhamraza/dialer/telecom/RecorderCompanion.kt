package com.syedarhamraza.dialer.telecom

import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.telecom.Call
import org.json.JSONArray

/**
 * Talks to the sideloaded One Dialer Recorder (`companion/`), which holds the mic and the
 * accessibility service, so this Play app carries neither. Everything goes through its
 * provider's `call()`, which checks our signing certificate. Without the companion, all of
 * this returns null and the UI hides recording.
 */
object RecorderCompanion {
    private const val AUTHORITY = "com.syedarhamraza.onedialer.recorder.recordings"
    private const val PACKAGE = "com.syedarhamraza.onedialer.recorder"
    private val URI: Uri = Uri.parse("content://$AUTHORITY")

    /** The companion's last status, for the call snapshot (no IPC on every change). */
    @Volatile private var cached: Map<String, Any?>? = null
    private var observer: ContentObserver? = null

    /** This call session already started a recording (auto or by hand); auto never restarts one. */
    private var sessionStarted = false

    fun installed(context: Context) = context.packageManager.resolveContentProvider(AUTHORITY, 0) != null

    private fun call(context: Context, method: String, arg: String? = null, extras: Bundle? = null): Bundle? = try {
        context.contentResolver.call(URI, method, arg, extras)
    } catch (_: Exception) {
        null // not installed, or it doesn't trust this build's certificate
    }

    /** `{ready, recording, startMillis, accessibilityOn, micGranted, notificationsOn, consented, autoRecord, trusted, error}`, null when not installed. */
    fun status(context: Context): Map<String, Any?>? {
        if (!installed(context)) return null
        val b = call(context, "status") ?: return mapOf("trusted" to false, "ready" to false, "recording" to false)
        val accessibility = b.getBoolean("accessibilityOn")
        val mic = b.getBoolean("micGranted")
        val prefs = CallPrefs.read(context)
        return mapOf(
            "trusted" to true,
            // Recording also waits for the user to accept the consent notice (Settings › Call recording).
            "ready" to (accessibility && mic && prefs["recordingConsent"] == true),
            "consented" to prefs["recordingConsent"],
            "autoRecordMode" to prefs["autoRecordMode"],
            "bytes" to b.getLong("bytes"),
            "accessibilityOn" to accessibility,
            "micGranted" to mic,
            "notificationsOn" to b.getBoolean("notificationsOn"),
            "recording" to b.getBoolean("recording"),
            "startMillis" to b.getLong("startMillis"),
            "error" to b.getString("error"),
        )
    }

    fun snapshot(): Map<String, Any?>? = cached

    /** Called while calls exist: refreshes the cached status and follows the companion's changes. */
    fun watch(context: Context) {
        cached = status(context)
        if (cached == null || observer != null) return
        observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                cached = status(context)
                CallManager.notifyChanged()
            }
        }.also { context.contentResolver.registerContentObserver(Uri.parse("content://$AUTHORITY/status"), false, it) }
    }

    fun unwatch(context: Context) {
        observer?.let(context.contentResolver::unregisterContentObserver)
        observer = null
        cached = null
    }

    /** Auto-record (Settings › Call recording) once a call is answered; stop when no call is left. */
    fun onCallsChanged(context: Context) {
        val calls = CallManager.all().map { it.second }
        val live = calls.filter { CallManager.stateOf(it).let { s -> s == Call.STATE_ACTIVE || s == Call.STATE_HOLDING } }
        if (live.isEmpty()) {
            if (cached?.get("recording") == true) call(context, "stop")
            if (calls.isEmpty()) sessionStarted = false
            return
        }
        val active = live.firstOrNull { CallManager.stateOf(it) == Call.STATE_ACTIVE } ?: return
        if (!sessionStarted && cached?.get("ready") == true &&
            RecordRules.shouldRecord(context, active.details.handle?.schemeSpecificPart)
        ) start(context, active)
    }

    /** The call screen's Record / Stop. False when there's nothing to record or no companion. */
    fun toggle(context: Context): Boolean {
        if (cached?.get("recording") == true || status(context)?.get("recording") == true) return call(context, "stop") != null
        if (status(context)?.get("ready") != true) return false
        val active = CallManager.all().map { it.second }.firstOrNull { CallManager.stateOf(it) == Call.STATE_ACTIVE } ?: return false
        return start(context, active)
    }

    private fun start(context: Context, call: Call): Boolean {
        sessionStarted = true
        val details = call.details
        val extras = Bundle().apply {
            putString("number", details.handle?.schemeSpecificPart)
            putLong("startMillis", details.connectTimeMillis.takeIf { it > 0 } ?: System.currentTimeMillis())
            putString("direction", if (details.callDirection == Call.Details.DIRECTION_INCOMING) "in" else "out")
            putString("simId", details.accountHandle?.let { "${it.componentName.flattenToString()}|${it.id}" })
        }
        return call(context, "start", extras = extras) != null
    }

    /** `[{name, number, startMillis, durationMs, bytes}]`, newest first. */
    fun list(context: Context): List<Map<String, Any?>> {
        val json = call(context, "list")?.getString("json") ?: return emptyList()
        val array = JSONArray(json)
        return List(array.length()) { i ->
            val o = array.getJSONObject(i)
            mapOf(
                "name" to o.getString("name"),
                "number" to (if (o.isNull("number")) null else o.getString("number")),
                "startMillis" to o.getLong("startMillis"),
                "durationMs" to o.getLong("durationMs"),
                "bytes" to o.getLong("bytes"),
                "direction" to o.optString("direction"),
                "simId" to o.optString("simId"),
                "starred" to o.optBoolean("starred"),
                "title" to o.optString("title"),
            )
        }
    }

    fun delete(context: Context, name: String?) = call(context, "delete", name)

    fun star(context: Context, name: String?, starred: Boolean) =
        call(context, "setStar", name, Bundle().apply { putBoolean("starred", starred) })

    fun rename(context: Context, name: String?, title: String?) =
        call(context, "rename", name, Bundle().apply { putString("title", title) })

    /** Save to phone (shared Recordings/One Dialer); [displayName] names the copy. */
    fun export(context: Context, name: String?, displayName: String?): Boolean =
        call(context, "export", name, Bundle().apply { putString("displayName", displayName) })?.getBoolean("ok") == true

    /** The companion's own settings: `{sourceMode, boost, retentionDays}`. */
    fun settings(context: Context): Map<String, Any?> {
        val json = call(context, "settings")?.getString("json") ?: return emptyMap()
        val o = org.json.JSONObject(json)
        return o.keys().asSequence().associateWith { o.get(it) }
    }

    fun setSetting(context: Context, key: String?, value: Any?) = call(context, "setSetting", key, Bundle().apply {
        when (value) {
            is Number -> putInt("value", value.toInt())
            is String -> putString("value", value)
        }
    })

    fun deleteAll(context: Context) = call(context, "deleteAll")

    /** Plays one recording, or shares one or more (names joined by '|'); the companion's intent carries the URI grant. */
    fun open(context: Context, name: String?, share: Boolean): Boolean {
        val intent = call(context, if (share) "share" else "open", name)?.let {
            @Suppress("DEPRECATION") it.getParcelable<PendingIntent>("intent")
        } ?: return false
        // Android 14+: the companion is in the background, so we lend it our (foreground) right to start activities.
        val options = if (Build.VERSION.SDK_INT >= 34) {
            ActivityOptions.makeBasic()
                .setPendingIntentBackgroundActivityStartMode(ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED).toBundle()
        } else null
        return runCatching { intent.send(context, 0, null, null, null, null, options) }.isSuccess
    }

    fun openSetup(context: Context): Boolean {
        val intent = context.packageManager.getLaunchIntentForPackage(PACKAGE) ?: return false
        return runCatching { context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }.isSuccess
    }
}
