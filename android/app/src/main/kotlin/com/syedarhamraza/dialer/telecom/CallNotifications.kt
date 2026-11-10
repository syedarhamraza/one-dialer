package com.syedarhamraza.dialer.telecom

import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Person
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Shader
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.os.SystemClock
import android.provider.ContactsContract
import android.telecom.Call
import android.telecom.CallAudioState
import android.text.SpannableString
import android.text.style.ForegroundColorSpan
import com.syedarhamraza.dialer.AppLanguage
import com.syedarhamraza.dialer.InCallActivity
import com.syedarhamraza.dialer.R
import org.json.JSONObject

object CallNotifications {
    private const val CHANNEL_INCOMING = "incoming_calls"
    private const val CHANNEL_INCOMING_QUIET = "incoming_calls_quiet"
    // shortcut: vivo has no call scene (sic "METTING" = meetings); switch if vivo adds one.
    private const val VIVO_SCENE = "METTING"
    private const val ID_INCOMING = 1
    private const val ANSWER_GREEN = 0xFF2FAE52.toInt() // answerGreen in lib/features/in_call/call_controls.dart

    /** Whether the ringing notification was last posted without its pop-up for Full screen. */
    private var postedForScreen = false

    /** [screenOpening]: Settings › Incoming call reminders › Full screen is opening the call screen. */
    fun showIncoming(context: Context, callId: String, call: Call, screenOpening: Boolean = false) {
        postedForScreen = screenOpening
        val res = AppLanguage.localized(context).resources
        val manager = context.getSystemService(NotificationManager::class.java)
        // On an unlocked vivo the Atomic Island card is the pop-up, and with the call screen up
        // (call waiting) the screen itself rings; a heads-up banner would double either.
        val unlocked = context.getSystemService(PowerManager::class.java).isInteractive &&
            !context.getSystemService(KeyguardManager::class.java).isKeyguardLocked
        val island = vivoIsland && unlocked
        val quiet = screenOpening || island || InCallActivity.isFullScreen
        val channel = if (quiet) CHANNEL_INCOMING_QUIET else CHANNEL_INCOMING
        ensureChannel(
            manager, channel,
            res.getString(if (quiet) R.string.channel_incoming_quiet else R.string.channel_incoming),
            if (quiet) NotificationManager.IMPORTANCE_DEFAULT else NotificationManager.IMPORTANCE_HIGH,
            legacy = "incoming_calls_island",
        )

        val details = call.details
        // Saved contact name first (Telecom looks it up), like the call screen.
        val caller = (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) details.contactDisplayName else null)
            ?: details.callerDisplayName?.takeIf { it.isNotBlank() }
            ?: details.handle?.schemeSpecificPart?.takeIf { it.isNotBlank() }
            ?: res.getString(R.string.unknown)

        val fullScreen = PendingIntent.getActivity(
            context, 0, InCallActivity.intent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        // Unlocked, answering from the banner keeps you in what you were doing (a game, a video):
        // the ongoing notification carries the call and a tap on it opens the call screen.
        val answer = if (unlocked && !screenOpening) {
            CallActionReceiver.pendingIntent(context, CallActionReceiver.ACTION_ANSWER_IN_ISLAND, callId)
        } else {
            CallActionReceiver.answerIntent(context, callId)
        }
        val decline = CallActionReceiver.pendingIntent(context, CallActionReceiver.ACTION_DECLINE, callId)

        val builder = Notification.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_stat_call)
            .setColor(ANSWER_GREEN)
            .setContentTitle(caller)
            .setContentText(res.getString(R.string.incoming_call))
            .setCategory(Notification.CATEGORY_CALL)
            .setOngoing(true)
            .setContentIntent(fullScreen)
            // CallStyle still needs a full-screen intent; not high priority when the island pops up instead.
            .setFullScreenIntent(fullScreen, !quiet)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val person = Person.Builder().setName(caller).setIcon(callerIcon(context, details.handle?.schemeSpecificPart))
                .setImportant(true).build()
            builder.setStyle(Notification.CallStyle.forIncomingCall(person, decline, answer))
        } else {
            builder.addAction(Notification.Action.Builder(null, res.getString(R.string.decline), decline).build())
            builder.addAction(Notification.Action.Builder(null, res.getString(R.string.answer), answer).build())
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA && !vivoIsland && !quiet && unlocked) {
            // Asks for a Live Update (status bar chip) beside the banner only: with the call screen up
            // (or opening over the lock screen) the chip doubled it. On vivo it'd be a second island.
            builder.addExtras(Bundle().apply { putBoolean(Notification.EXTRA_REQUEST_PROMOTED_ONGOING, true) })
        }
        val icon = callerIcon(context, details.handle?.schemeSpecificPart)
            ?: Icon.createWithResource(context, R.drawable.island_caller) // LetterAvatar's no-photo person
        if (vivoIsland && !screenOpening) {
            // Answering here keeps the call in the island; the full call screen is a tap away.
            val answerHere = CallActionReceiver.pendingIntent(context, CallActionReceiver.ACTION_ANSWER_IN_ISLAND, callId)
            builder.addExtras(
                vivoIslandExtras(
                    create = true, caller, res.getString(R.string.incoming_call), icon, fullScreen,
                    buttons = listOf(
                        Icon.createWithResource(context, R.drawable.island_decline) to decline,
                        Icon.createWithResource(context, R.drawable.island_answer) to answerHere,
                    ),
                    glyph = Icon.createWithResource(context, R.drawable.island_phone),
                    rightTemplate = 4, // text + image; text only here
                    rightInfo = Bundle().apply {
                        // Like vivo's connected-call island: green glyph left, green text (its timer) right.
                        putCharSequence("island.superx.rightInfo.content", green(res.getString(R.string.island_incoming)))
                    },
                )
            )
        }

        manager.notify(ID_INCOMING, builder.build())
    }

    /**
     * The Full screen call screen was left while still ringing (Home, Recents): post the ringing
     * notification as Banner does, so vivo's island card (or a banner) carries the call. Only
     * unlocked: reposting with the screen off would let the full-screen intent turn it back on.
     */
    fun restoreAfterScreen(context: Context) {
        if (!postedForScreen) return
        if (!context.getSystemService(PowerManager::class.java).isInteractive ||
            context.getSystemService(KeyguardManager::class.java).isKeyguardLocked
        ) return
        val (id, call) = CallManager.all().firstOrNull { CallManager.stateOf(it.second) == Call.STATE_RINGING } ?: return
        showIncoming(context, id, call)
    }

    private fun green(text: String) = SpannableString(text).apply {
        setSpan(ForegroundColorSpan(ANSWER_GREEN), 0, length, 0)
    }

    /**
     * vivo's Atomic Island extras (dev.vivo.com.cn/documentCenter/doc/896): the expanded card is
     * vivo's basic template with [buttons] as its tappable images, the collapsed island [glyph] on
     * the left and [rightTemplate]/[rightInfo] on the right. [create] starts an island item and pops
     * its card; later posts update it. vivo collapses the card after a few seconds itself.
     */
    private fun vivoIslandExtras(
        create: Boolean, title: String, content: String, icon: Icon, open: PendingIntent,
        buttons: List<Pair<Icon, PendingIntent>>, glyph: Icon, rightTemplate: Int, rightInfo: Bundle,
    ) = Bundle().apply {
        putInt("notification.superx.operation", if (create) 0 else 1)
        putBoolean("notification.superx.showNotify", true)
        putBoolean("notification.superx.sound", false) // Telecom rings
        putInt("notification.superx.template", 4) // basic card: the only one with several tappable images
        putString("notification.superx.scene", VIVO_SCENE)
        putParcelable("notification.superx.clickResp", open)
        putBundle("notification.superx.baseInfos", Bundle().apply {
            putParcelable("notification.superx.baseInfos.icon", icon)
            putCharSequence("notification.superx.baseInfos.title", title)
            putCharSequence("notification.superx.baseInfos.content", content)
            putInt("notification.superx.baseInfos.subInfo", 4) // image list, each with its own tap
            putParcelableArrayList("notification.superx.baseInfos.subImageList", ArrayList(buttons.map { it.first }))
            putParcelableArrayList("notification.superx.baseInfos.subInfoClickRespList", ArrayList(buttons.map { it.second }))
        })
        putBundle("notification.superx.shortInfos", Bundle().apply {
            putParcelable("notification.superx.shortInfos.image", icon)
            putParcelable("notification.superx.shortInfos.imageClickResp", open)
            putString("notification.superx.shortInfos.describeShort", content)
            putString("notification.superx.shortInfos.coreInfoShort", title)
        })
        putBundle("notification.superx.capsule", Bundle().apply {
            putInt("notification.superx.capsule.state", 1)
            putParcelable("notification.superx.capsule.icon", icon)
            putString("notification.superx.capsule.content", title)
        })
        putBundle("notification.superx.island", Bundle().apply {
            putInt("island.superx.leftTemplate", 1) // image + text
            putBundle("island.superx.leftInfo", Bundle().apply { putParcelable("island.superx.leftInfo.icon", glyph) })
            putInt("island.superx.rightTemplate", rightTemplate)
            putBundle("island.superx.rightInfo", rightInfo)
            putInt("island.superx.islandClick", 0) // tap opens the card
            putInt("island.superx.template", 4) // supports the large card
            putBoolean("island.superx.forceShowCard", create) // push API's "show card now"; undocumented locally
        })
    }

    /**
     * A vivo with Atomic Island (its NotificationManager has vivo's island API). vivo's own
     * getSceneStatus says false for unapproved apps even though the card shows, so it isn't used.
     */
    private val vivoIsland: Boolean by lazy {
        Build.MANUFACTURER.equals("vivo", ignoreCase = true) &&
            NotificationManager::class.java.declaredMethods.any { it.name == "getSceneStatus" }
    }

    /** OPPO, OnePlus and realme share one capsule (Fluid Cloud / Live Alerts), fed by Live Updates. */
    private val oplusCapsule: Boolean by lazy {
        Build.MANUFACTURER.lowercase() in setOf("oppo", "oneplus", "realme")
    }

    fun cancelIncoming(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.cancel(ID_INCOMING)
        manager.cancel("VIVO_SUPERX_TAG", ID_INCOMING) // vivo's tag for ending an atomic notification
    }

    /**
     * Shows the ongoing-call notification (Hang up, live timer) for the current call, or
     * removes it when there's none or an incoming call is ringing (that one has its own).
     */
    fun updateOngoing(context: Context, calls: List<Pair<String, Call>>) {
        val res = AppLanguage.localized(context).resources
        val manager = context.getSystemService(NotificationManager::class.java)
        val (callId, call) = shownOngoing(calls) ?: return removeOngoing(manager)
        if (calls.any { CallManager.stateOf(it.second) == Call.STATE_RINGING }) return removeOngoing(manager)

        // Not IMPORTANCE_LOW: Android 12+ and vivo hide silent notifications on the lock screen,
        // which left no way back to a call there. An existing channel's importance can't change.
        ensureChannel(
            manager, CHANNEL_ONGOING, res.getString(R.string.channel_ongoing), NotificationManager.IMPORTANCE_DEFAULT,
            legacy = "ongoing_calls",
        )
        val state = CallManager.stateOf(call)
        val details = call.details
        val caller = (if (details.hasProperty(Call.Details.PROPERTY_CONFERENCE)) res.getString(R.string.conference_call) else null)
            ?: (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) details.contactDisplayName else null)
            ?: details.callerDisplayName?.takeIf { it.isNotBlank() }
            ?: details.handle?.schemeSpecificPart?.takeIf { it.isNotBlank() }
            ?: res.getString(R.string.unknown)
        val open = PendingIntent.getActivity(
            context, 1, InCallActivity.intent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val hangUp = CallActionReceiver.pendingIntent(context, CallActionReceiver.ACTION_HANG_UP, callId)

        val status = when (state) {
            Call.STATE_ACTIVE -> res.getString(R.string.ongoing_call)
            Call.STATE_HOLDING -> res.getString(R.string.on_hold)
            else -> res.getString(R.string.calling_ellipsis)
        }
        val builder = Notification.Builder(context, CHANNEL_ONGOING)
            // vivo's call island shows this as-is: the same green glyph as the incoming island.
            .setSmallIcon(R.drawable.island_phone)
            .setColor(ANSWER_GREEN)
            .setContentTitle(caller)
            .setContentText(status)
            .setCategory(Notification.CATEGORY_CALL)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setContentIntent(open)
            // CallStyle needs a full-screen intent (or a foreground service); not high priority,
            // so it never interrupts on its own.
            .setFullScreenIntent(open, false)

        if (state == Call.STATE_ACTIVE && details.connectTimeMillis > 0) {
            builder.setUsesChronometer(true).setWhen(details.connectTimeMillis).setShowWhen(true)
        }
        // On vivo a CallStyle call gets vivo's own call island next to ours, so it's a plain action there.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !vivoIsland) {
            val person = Person.Builder().setName(caller).setIcon(callerIcon(context, details.handle?.schemeSpecificPart))
                .setImportant(true).build()
            builder.setStyle(Notification.CallStyle.forOngoingCall(person, hangUp))
        } else {
            builder.addAction(Notification.Action.Builder(null, res.getString(R.string.hang_up), hangUp).build())
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA && !vivoIsland) {
            // Asks for a Live Update: the status bar chip, and the capsule on skins that map Live
            // Updates to their island (ColorOS Fluid Cloud, OxygenOS Live Alerts, realme UI).
            builder.addExtras(Bundle().apply { putBoolean(Notification.EXTRA_REQUEST_PROMOTED_ONGOING, true) })
            // Their capsule shows only the small icon and this text (about 7 characters), never the
            // chronometer. Elsewhere it would replace the chip's live timer, so it's theirs alone.
            if (oplusCapsule) {
                builder.setShortCriticalText(
                    res.getString(
                        when (state) {
                            Call.STATE_ACTIVE -> R.string.island_on_call
                            Call.STATE_HOLDING -> R.string.on_hold
                            else -> R.string.island_calling
                        }
                    )
                )
            }
        }
        if (vivoIsland) {
            @Suppress("DEPRECATION") // CallAudioState still reports the route on API 34+
            val onSpeaker = CallManager.service?.callAudioState?.route == CallAudioState.ROUTE_SPEAKER
            // vivo drops island updates closer than 10 s apart, so only repost when the island changes.
            val key = listOf(callId, state, caller, onSpeaker, details.connectTimeMillis > 0).toString()
            if (key == islandKey) return
            val create = islandKey == null
            islandKey = key
            // vivo's SuperXChronometer ticks text holding this JSON (read from its SystemUI plugin);
            // base is on the elapsedRealtime clock like Chronometer's. Keep the format fields: without
            // them vivo falls back to its own formatters, and the island's timer went back to 0:00 at
            // every whole minute (vivo redraws the island then). Its args: S (s), MS (m, s), HMS (h, m, s).
            val timer = details.connectTimeMillis.takeIf { state == Call.STATE_ACTIVE && it > 0 }?.let {
                JSONObject()
                    .put("base", SystemClock.elapsedRealtime() - (System.currentTimeMillis() - it))
                    .put("started", true)
                    .put("countDown", false)
                    .put("minUnit", "M")
                    .put("elapsedFormatS", "0:%1\$02d")
                    .put("elapsedFormatMS", "%1\$d:%2\$02d")
                    .put("elapsedFormatHMS", "%1\$d:%2\$02d:%3\$02d")
                    .toString()
            }
            builder.addExtras(
                vivoIslandExtras(
                    create, caller, timer ?: status,
                    callerIcon(context, details.handle?.schemeSpecificPart)
                        ?: Icon.createWithResource(context, R.drawable.island_caller),
                    open,
                    buttons = listOf(
                        Icon.createWithResource(
                            context, if (onSpeaker) R.drawable.island_speaker_on else R.drawable.island_speaker,
                        ) to CallActionReceiver.pendingIntent(context, CallActionReceiver.ACTION_SPEAKER, callId),
                        Icon.createWithResource(context, R.drawable.island_decline) to hangUp,
                    ),
                    glyph = Icon.createWithResource(context, R.drawable.island_phone),
                    // Like vivo's own call island: green text, a live timer once the call connects.
                    rightTemplate = 4, // text + image; text only here
                    rightInfo = Bundle().apply {
                        val text = timer ?: res.getString(if (state == Call.STATE_HOLDING) R.string.on_hold else R.string.island_calling)
                        putCharSequence("island.superx.rightInfo.content", green(text))
                    },
                )
            )
        }
        manager.notify(ID_ONGOING, builder.build())
    }

    /** The call the ongoing notification describes, or null when none qualifies. */
    fun shownOngoing(calls: List<Pair<String, Call>>): Pair<String, Call>? =
        ongoingIndex(calls.map { CallManager.stateOf(it.second) })?.let { calls[it] }

    /** The in-call island's last posted look; null until it's created. */
    private var islandKey: String? = null

    private fun removeOngoing(manager: NotificationManager) {
        manager.cancel(ID_ONGOING)
        manager.cancel("VIVO_SUPERX_TAG", ID_ONGOING) // vivo's tag for ending an atomic notification
        islandKey = null
    }

    fun cancelOngoing(context: Context) {
        removeOngoing(context.getSystemService(NotificationManager::class.java))
        photos.clear() // A photo changed between calls is picked up next time.
    }

    /** Channels created in this process, by id and localized name: each create is a binder call. */
    private val channels = HashSet<String>()

    /**
     * Creates a silent channel (Telecom plays the ringtone) once per process and name, deleting its
     * [legacy] predecessor, instead of on every post: this ran before every ringing notification.
     */
    private fun ensureChannel(manager: NotificationManager, id: String, name: String, importance: Int, legacy: String) {
        if (!channels.add("$id|$name")) return
        manager.deleteNotificationChannel(legacy)
        manager.createNotificationChannel(
            NotificationChannel(id, name, importance).apply {
                setSound(null, null)
                enableVibration(false)
            }
        )
    }

    /** Looked up once per number while calls last; the ongoing notification updates often. */
    private val photos = HashMap<String, Icon?>()

    private fun callerIcon(context: Context, number: String?): Icon? {
        if (number.isNullOrBlank()) return null
        return photos.getOrPut(number) { lookupPhoto(context, number) }
    }

    /** Some skins (ColorOS) show a person's icon as-is, so round it like the call screen's avatar. */
    private fun circle(source: Bitmap): Bitmap {
        val size = minOf(source.width, source.height)
        val out = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = BitmapShader(source, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP).apply {
                setLocalMatrix(Matrix().apply {
                    setTranslate(-(source.width - size) / 2f, -(source.height - size) / 2f)
                })
            }
        }
        Canvas(out).drawCircle(size / 2f, size / 2f, size / 2f, paint)
        return out
    }

    /** The first contact for [number] that has a photo, matching the call screen's choice. */
    private fun lookupPhoto(context: Context, number: String): Icon? = try {
        val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number))
        val resolver = context.contentResolver
        val photo = resolver.query(uri, arrayOf(ContactsContract.PhoneLookup.PHOTO_THUMBNAIL_URI), null, null, null)
            ?.use { rows -> generateSequence { if (rows.moveToNext()) rows else null }.firstNotNullOfOrNull { it.getString(0) } }
        photo?.let { resolver.openInputStream(Uri.parse(it))?.use(BitmapFactory::decodeStream) }
            ?.let { Icon.createWithBitmap(circle(it)) }
    } catch (_: Exception) {
        null // No photo is better than no notification (e.g. contacts permission revoked).
    }

    private const val CHANNEL_ONGOING = "ongoing_calls_v2"
    private const val ID_ONGOING = 3
}

/** Which call states the ongoing notification describes, best first. */
private val ONGOING_PRIORITY = listOf(
    Call.STATE_ACTIVE, Call.STATE_DIALING, Call.STATE_CONNECTING, Call.STATE_HOLDING,
)

/** Index of the call the ongoing notification describes among [states], or null when none qualifies. */
internal fun ongoingIndex(states: List<Int>): Int? =
    states.indices.filter { states[it] in ONGOING_PRIORITY }.minByOrNull { ONGOING_PRIORITY.indexOf(states[it]) }

