package com.syedarhamraza.dialer.telecom

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Person
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telecom.Call
import com.syedarhamraza.dialer.InCallActivity

object CallNotifications {
    private const val CHANNEL_INCOMING = "incoming_calls"
    private const val ID_INCOMING = 1

    fun showIncoming(context: Context, callId: String, call: Call) {
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_INCOMING, "Incoming calls", NotificationManager.IMPORTANCE_HIGH).apply {
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

        val builder = Notification.Builder(context, CHANNEL_INCOMING)
            .setSmallIcon(android.R.drawable.sym_call_incoming)
            .setContentTitle(caller)
            .setContentText("Incoming call")
            .setCategory(Notification.CATEGORY_CALL)
            .setOngoing(true)
            .setContentIntent(fullScreen)
            .setFullScreenIntent(fullScreen, true)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val person = Person.Builder().setName(caller).setImportant(true).build()
            builder.setStyle(Notification.CallStyle.forIncomingCall(person, decline, answer))
        } else {
            builder.addAction(Notification.Action.Builder(null, "Decline", decline).build())
            builder.addAction(Notification.Action.Builder(null, "Answer", answer).build())
        }

        manager.notify(ID_INCOMING, builder.build())
    }

    fun cancelIncoming(context: Context) {
        context.getSystemService(NotificationManager::class.java).cancel(ID_INCOMING)
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
            .setSmallIcon(android.R.drawable.sym_action_call)
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
            val person = Person.Builder().setName(caller).setImportant(true).build()
            builder.setStyle(Notification.CallStyle.forOngoingCall(person, hangUp))
        } else {
            builder.addAction(Notification.Action.Builder(null, "Hang up", hangUp).build())
        }
        manager.notify(ID_ONGOING, builder.build())
    }

    fun cancelOngoing(context: Context) {
        context.getSystemService(NotificationManager::class.java).cancel(ID_ONGOING)
    }

    private const val CHANNEL_ONGOING = "ongoing_calls"
    private const val ID_ONGOING = 3

    /** Which call the ongoing notification describes, best first. */
    private val ONGOING_PRIORITY = listOf(
        Call.STATE_ACTIVE, Call.STATE_DIALING, Call.STATE_CONNECTING, Call.STATE_HOLDING,
    )
}
