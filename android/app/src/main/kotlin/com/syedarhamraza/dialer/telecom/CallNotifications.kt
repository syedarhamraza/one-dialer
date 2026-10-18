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
import android.provider.ContactsContract
import android.telecom.Call
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
            .setSmallIcon(android.R.drawable.sym_call_incoming)
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
        if (vivoIsland) builder.addExtras(vivoIslandExtras(context, caller, icon, fullScreen, answer, decline))

        manager.notify(ID_INCOMING, builder.build())
    }

    /**
     * vivo's Atomic Island extras (dev.vivo.com.cn/documentCenter/doc/896): the expanded island card
     * is vivo's basic template with Decline and Answer as its tappable images; the collapsed island
     * reads like vivo's connected-call one. vivo collapses the card after a few seconds itself.
     */
    private fun vivoIslandExtras(
        context: Context, caller: String, icon: Icon,
        open: PendingIntent, answer: PendingIntent, decline: PendingIntent,
    ) = Bundle().apply {
        // The call screen's balls, exported by test/island_buttons_test.dart.
        val answerIcon = Icon.createWithResource(context, R.drawable.island_answer)
        val declineIcon = Icon.createWithResource(context, R.drawable.island_decline)
        putInt("notification.superx.operation", 0) // create
        putBoolean("notification.superx.showNotify", true)
        putBoolean("notification.superx.sound", false) // Telecom rings
        putInt("notification.superx.template", 4) // basic card: the only one with several tappable images
        putString("notification.superx.scene", VIVO_SCENE)
        putParcelable("notification.superx.clickResp", open)
        putBundle("notification.superx.baseInfos", Bundle().apply {
            putParcelable("notification.superx.baseInfos.icon", icon)
            putCharSequence("notification.superx.baseInfos.title", caller)
            putCharSequence("notification.superx.baseInfos.content", "Incoming call")
            putInt("notification.superx.baseInfos.subInfo", 4) // image list, each with its own tap
            putParcelableArrayList("notification.superx.baseInfos.subImageList", arrayListOf(declineIcon, answerIcon))
            putParcelableArrayList("notification.superx.baseInfos.subInfoClickRespList", arrayListOf(decline, answer))
        })
        putBundle("notification.superx.shortInfos", Bundle().apply {
            putParcelable("notification.superx.shortInfos.image", icon)
            putParcelable("notification.superx.shortInfos.imageClickResp", open)
            putString("notification.superx.shortInfos.describeShort", "Incoming call")
            putString("notification.superx.shortInfos.coreInfoShort", caller)
        })
        putBundle("notification.superx.capsule", Bundle().apply {
            putInt("notification.superx.capsule.state", 1)
            putParcelable("notification.superx.capsule.icon", icon)
            putString("notification.superx.capsule.content", caller)
        })
        putBundle("notification.superx.island", Bundle().apply {
            putInt("island.superx.leftTemplate", 1) // image + text
            putBundle("island.superx.leftInfo", Bundle().apply {
                putParcelable("island.superx.leftInfo.icon", Icon.createWithResource(context, R.drawable.island_phone))
            })
            // Like vivo's connected-call island: green glyph left, green text (its timer) right.
            putInt("island.superx.rightTemplate", 4) // text + image; text only here
            putBundle("island.superx.rightInfo", Bundle().apply {
                putCharSequence(
                    "island.superx.rightInfo.content",
                    SpannableString("Incoming").apply {
                        setSpan(ForegroundColorSpan(0xFF2FAE52.toInt()), 0, length, 0) // answerGreen
                    },
                )
            })
            putInt("island.superx.islandClick", 0) // tap opens the card
            putInt("island.superx.template", 4) // supports the large card
            putBoolean("island.superx.forceShowCard", true) // push API's "show card now"; undocumented locally
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
            ?: return manager.cancel(ID_ONGOING)
        if (Call.STATE_RINGING in states) return manager.cancel(ID_ONGOING)

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

        val builder = Notification.Builder(context, CHANNEL_ONGOING)
            // vivo's call island shows this as-is: the same green glyph as the incoming island.
            .setSmallIcon(R.drawable.island_phone)
            .setContentTitle(caller)
            .setContentText(
                when (state) {
                    Call.STATE_ACTIVE -> "Ongoing call"
                    Call.STATE_HOLDING -> "On hold"
                    else -> "Calling…"
                }
            )
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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val person = Person.Builder().setName(caller).setIcon(callerIcon(context, details.handle?.schemeSpecificPart))
                .setImportant(true).build()
            builder.setStyle(Notification.CallStyle.forOngoingCall(person, hangUp))
        } else {
            builder.addAction(Notification.Action.Builder(null, "Hang up", hangUp).build())
        }
        manager.notify(ID_ONGOING, builder.build())
    }

    fun cancelOngoing(context: Context) {
        context.getSystemService(NotificationManager::class.java).cancel(ID_ONGOING)
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
