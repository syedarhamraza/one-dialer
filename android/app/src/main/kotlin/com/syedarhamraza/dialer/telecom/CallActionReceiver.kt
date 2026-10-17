package com.syedarhamraza.dialer.telecom

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telecom.VideoProfile
import com.syedarhamraza.dialer.InCallActivity

/** Handles the Answer / Decline buttons on the incoming-call notification. */
class CallActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val call = intent.getStringExtra(EXTRA_CALL_ID)?.let(CallManager::get) ?: return
        when (intent.action) {
            ACTION_ANSWER -> {
                call.answer(VideoProfile.STATE_AUDIO_ONLY)
                InCallActivity.start(context)
            }
            ACTION_DECLINE -> call.reject(false, null)
            ACTION_HANG_UP -> call.disconnect()
        }
        CallNotifications.cancelIncoming(context)
    }

    companion object {
        const val ACTION_ANSWER = "com.syedarhamraza.dialer.ANSWER"
        const val ACTION_DECLINE = "com.syedarhamraza.dialer.DECLINE"
        const val ACTION_HANG_UP = "com.syedarhamraza.dialer.HANG_UP"
        private const val EXTRA_CALL_ID = "call_id"

        fun pendingIntent(context: Context, action: String, callId: String): PendingIntent {
            val intent = Intent(context, CallActionReceiver::class.java)
                .setAction(action)
                .putExtra(EXTRA_CALL_ID, callId)
            return PendingIntent.getBroadcast(
                context, action.hashCode(), intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
