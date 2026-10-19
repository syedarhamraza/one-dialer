package com.syedarhamraza.dialer.telecom

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.syedarhamraza.dialer.MainActivity
import com.syedarhamraza.dialer.R

/**
 * Telecom asks the default dialer to show missed-call notifications (and to restore them
 * after a reboot) with [android.telecom.TelecomManager.ACTION_SHOW_MISSED_CALLS_NOTIFICATION].
 * The notification is built from the call log itself, never from the broadcast's extras,
 * because this receiver is exported and any app could send it.
 */
class MissedCallReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val result = goAsync()
        Thread {
            try {
                MissedCallNotifier.update(context)
            } finally {
                result.finish()
            }
        }.start()
    }
}

object MissedCallNotifier {
    private const val CHANNEL = "missed_calls"
    private const val ID = 2

    /** Shows (or clears) the notification to match the unseen missed calls in the call log. */
    fun update(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java)
        val missed = runCatching { CallLogSource.unseenMissed(context) }.getOrDefault(emptyList())
        if (missed.isEmpty()) return manager.cancel(ID)

        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, "Missed calls", NotificationManager.IMPORTANCE_DEFAULT)
        )
        val (number, name) = missed.first()
        val caller = name?.takeIf { it.isNotBlank() } ?: number.ifBlank { "Unknown" }
        val open = PendingIntent.getActivity(
            context, 0, MainActivity.openRecentsIntent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = Notification.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_missed_call)
            .setCategory(Notification.CATEGORY_MISSED_CALL)
            .setContentIntent(open)
            .setAutoCancel(true)
            .setNumber(missed.size)

        if (missed.size == 1) {
            builder.setContentTitle("Missed call").setContentText(caller)
            if (number.isNotBlank()) {
                builder.addAction(action(context, "Call back", Intent(Intent.ACTION_CALL, Uri.fromParts("tel", number, null)), 1))
                builder.addAction(action(context, "Message", Intent(Intent.ACTION_SENDTO, Uri.fromParts("smsto", number, null)), 2))
            }
        } else {
            builder.setContentTitle("${missed.size} missed calls").setContentText("Latest: $caller")
        }
        manager.notify(ID, builder.build())
    }

    fun cancel(context: Context) = context.getSystemService(NotificationManager::class.java).cancel(ID)

    private fun action(context: Context, title: String, intent: Intent, requestCode: Int): Notification.Action {
        val pending = PendingIntent.getActivity(
            context, requestCode, intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Action.Builder(null, title, pending).build()
    }
}
