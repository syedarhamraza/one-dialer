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
import com.syedarhamraza.dialer.InCallActivity
import com.syedarhamraza.dialer.R

object CallNotifications {
    private const val CHANNEL_INCOMING = "incoming_calls"
    private const val CHANNEL_INCOMING_ISLAND = "incoming_calls_island"
    // shortcut: vivo has no call scene (sic "METTING" = meetings); switch if vivo adds one.
    private const val VIVO_SCENE = "METTING"
    private const val ID_INCOMING = 1
    private const val ANSWER_GREEN = 0xFF2FAE52.toInt() // answerGreen in lib/features/in_call/call_controls.dart

    fun showIncoming(context: Context, callId: String, call: Call) {
        val manager = context.getSystemService(NotificationManager::class.java)
        // On an unlocked vivo the Atomic Island card is the pop-up; a heads-up banner would double it.
        val island = vivoIsland &&
            context.getSystemService(PowerManager::class.java).isInteractive &&
            !context.getSystemService(KeyguardManager::class.java).isKeyguardLocked
        val channel = if (island) CHANNEL_INCOMING_ISLAND else CHANNEL_INCOMING
        manager.createNotificationChannel(
            NotificationChannel(
                channel,
                if (island) "Incoming calls (Origin Island)" else "Incoming calls",
                if (island) NotificationManager.IMPORTANCE_DEFAULT else NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                // Telecom plays the ringtone; the notification itself stays silent.
                setSound(null, null)
                enableVibration(false)
            }
        )

        val details = call.details
        // Saved contact name first (Telecom looks it up), like the call screen.
        val caller = (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) details.contactDisplayName else null)
            ?: details.callerDisplayName?.takeIf { it.isNotBlank() }
            ?: details.handle?.schemeSpecificPart?.takeIf { it.isNotBlank() }
            ?: "Unknown"

        val fullScreen = PendingIntent.getActivity(
            context, 0, InCallActivity.intent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val answer = CallActionReceiver.pendingIntent(context, CallActionReceiver.ACTION_ANSWER, callId)
        val decline = CallActionReceiver.pendingIntent(context, CallActionReceiver.ACTION_DECLINE, callId)

        val builder = Notification.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_stat_call)
            .setContentTitle(caller)
            .setContentText("Incoming call")
            .setCategory(Notification.CATEGORY_CALL)
            .setOngoing(true)
            .setContentIntent(fullScreen)
            // CallStyle still needs a full-screen intent; not high priority when the island pops up instead.
            .setFullScreenIntent(fullScreen, !island)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val person = Person.Builder().setName(caller).setIcon(callerIcon(context, details.handle?.schemeSpecificPart))
                .setImportant(true).build()
            builder.setStyle(Notification.CallStyle.forIncomingCall(person, decline, answer))
        } else {
            builder.addAction(Notification.Action.Builder(null, "Decline", decline).build())
            builder.addAction(Notification.Action.Builder(null, "Answer", answer).build())
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA && !vivoIsland) {
            // Asks for a Live Update (status bar chip); on vivo it'd be a second island next to the card.
            builder.addExtras(Bundle().apply { putBoolean(Notification.EXTRA_REQUEST_PROMOTED_ONGOING, true) })
        }
        val icon = callerIcon(context, details.handle?.schemeSpecificPart)
            ?: Icon.createWithResource(context, R.drawable.island_caller) // LetterAvatar's no-photo person
        if (vivoIsland) {
            // Answering here keeps the call in the island; the full call screen is a tap away.
            val answerHere = CallActionReceiver.pendingIntent(context, CallActionReceiver.ACTION_ANSWER_IN_ISLAND, callId)
            builder.addExtras(
                vivoIslandExtras(
                    create = true, caller, "Incoming call", icon, fullScreen,
                    buttons = listOf(
                        Icon.createWithResource(context, R.drawable.island_decline) to decline,
                        Icon.createWithResource(context, R.drawable.island_answer) to answerHere,
                    ),
                    glyph = Icon.createWithResource(context, R.drawable.island_phone),
                    rightTemplate = 4, // text + image; text only here
                    rightInfo = Bundle().apply {
                        // Like vivo's connected-call island: green glyph left, green text (its timer) right.
                        putCharSequence("island.superx.rightInfo.content", green("Incoming"))
                    },
                )
            )
        }

        manager.notify(ID_INCOMING, builder.build())
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
        val manager = context.getSystemService(NotificationManager::class.java)
        val states = calls.map { CallManager.stateOf(it.second) }
        val (callId, call) = calls.indices
            .sortedBy { ONGOING_PRIORITY.indexOf(states[it]).let { p -> if (p < 0) Int.MAX_VALUE else p } }
            .firstOrNull { states[it] in ONGOING_PRIORITY }
            ?.let { calls[it] }
            ?: return removeOngoing(manager)
        if (Call.STATE_RINGING in states) return removeOngoing(manager)

        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ONGOING, "Ongoing calls", NotificationManager.IMPORTANCE_LOW)
        )
        val state = CallManager.stateOf(call)
        val details = call.details
        val caller = (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) details.contactDisplayName else null)
            ?: details.callerDisplayName?.takeIf { it.isNotBlank() }
            ?: details.handle?.schemeSpecificPart?.takeIf { it.isNotBlank() }
            ?: "Unknown"
        val open = PendingIntent.getActivity(
            context, 1, InCallActivity.intent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val hangUp = CallActionReceiver.pendingIntent(context, CallActionReceiver.ACTION_HANG_UP, callId)

        val status = when (state) {
            Call.STATE_ACTIVE -> "Ongoing call"
            Call.STATE_HOLDING -> "On hold"
            else -> "Calling…"
        }
        val builder = Notification.Builder(context, CHANNEL_ONGOING)
            // vivo's call island shows this as-is: the same green glyph as the incoming island.
            .setSmallIcon(R.drawable.island_phone)
            .setContentTitle(caller)
            .setContentText(status)
            .setCategory(Notification.CATEGORY_CALL)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
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
            builder.addAction(Notification.Action.Builder(null, "Hang up", hangUp).build())
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
            // base is on the elapsedRealtime clock like Chronometer's.
            val timer = details.connectTimeMillis.takeIf { state == Call.STATE_ACTIVE && it > 0 }?.let {
                val base = SystemClock.elapsedRealtime() - (System.currentTimeMillis() - it)
                """{"base":$base,"started":true,"countDown":false}"""
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
                        val text = timer ?: if (state == Call.STATE_HOLDING) "On hold" else "Calling"
                        putCharSequence("island.superx.rightInfo.content", green(text))
                    },
                )
            )
        }
        manager.notify(ID_ONGOING, builder.build())
    }

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

    private const val CHANNEL_ONGOING = "ongoing_calls"
    private const val ID_ONGOING = 3

    /** Which call the ongoing notification describes, best first. */
    private val ONGOING_PRIORITY = listOf(
        Call.STATE_ACTIVE, Call.STATE_DIALING, Call.STATE_CONNECTING, Call.STATE_HOLDING,
    )
}
