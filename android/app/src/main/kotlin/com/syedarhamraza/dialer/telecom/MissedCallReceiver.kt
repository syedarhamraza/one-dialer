package com.syedarhamraza.dialer.telecom

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.text.format.DateUtils
import com.syedarhamraza.dialer.MainActivity
import com.syedarhamraza.dialer.AppLanguage
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

        val res = AppLanguage.localized(context).resources
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, res.getString(R.string.channel_missed), NotificationManager.IMPORTANCE_DEFAULT)
        )
        val (number, name, date) = missed.first()
        val caller = name?.takeIf { it.isNotBlank() } ?: number.ifBlank { res.getString(R.string.unknown) }
        val open = PendingIntent.getActivity(
            context, 0, MainActivity.openRecentsIntent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = Notification.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_missed_call)
            .setColor(0xFFD2463A.toInt()) // endRed in lib/features/in_call/call_controls.dart
            .setCategory(Notification.CATEGORY_MISSED_CALL)
            .setContentIntent(open)
            .setDeleteIntent(
                PendingIntent.getBroadcast(
                    context, 3,
                    Intent(context, CallActionReceiver::class.java).setAction(CallActionReceiver.ACTION_MISSED_DISMISSED),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            )
            .setAutoCancel(true)
            .setNumber(missed.size)
            .setWhen(date)
            .setShowWhen(true)

        if (missed.size == 1) {
            builder.setContentTitle(res.getString(R.string.missed_call)).setContentText("$caller · ${time(context, date)}")
            if (number.isNotBlank()) {
                builder.addAction(action(context, res.getString(R.string.call_back), Intent(Intent.ACTION_CALL, Uri.fromParts("tel", number, null)), 1))
                builder.addAction(action(context, res.getString(R.string.message), Intent(Intent.ACTION_SENDTO, Uri.fromParts("smsto", number, null)), 2))
            }
        } else {
            builder.setContentTitle(res.getQuantityString(R.plurals.missed_calls, missed.size, missed.size))
                .setContentText(res.getString(R.string.missed_latest, "$caller · ${time(context, date)}"))
        }
        manager.notify(ID, builder.build())
    }

    /** When the call came in, in the text too: vivo's shade hides the notification's own time. */
    private fun time(context: Context, date: Long): String = DateUtils.formatDateTime(
        context, date,
        if (DateUtils.isToday(date)) DateUtils.FORMAT_SHOW_TIME
        else DateUtils.FORMAT_SHOW_TIME or DateUtils.FORMAT_SHOW_DATE or DateUtils.FORMAT_ABBREV_MONTH,
    )

    fun cancel(context: Context) = context.getSystemService(NotificationManager::class.java).cancel(ID)

    private fun action(context: Context, title: String, intent: Intent, requestCode: Int): Notification.Action {
        val pending = PendingIntent.getActivity(
            context, requestCode, intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Action.Builder(null, title, pending).build()
    }
}
