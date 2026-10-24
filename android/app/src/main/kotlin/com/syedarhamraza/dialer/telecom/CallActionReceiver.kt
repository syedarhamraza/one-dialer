package com.syedarhamraza.dialer.telecom

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telecom.CallAudioState
import android.telecom.VideoProfile
import com.syedarhamraza.dialer.InCallActivity

/** Handles the call notifications' buttons (Decline, Hang up, and vivo's island Answer and Speaker). */
class CallActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_MISSED_DISMISSED) {
            // Otherwise the calls stay new and Telecom's next missed-call broadcast (after any call) reposts them.
            val result = goAsync()
            Thread {
                try {
                    CallLogSource.markMissedRead(context)
                } finally {
                    result.finish()
                }
            }.start()
            return
        }
        val call = intent.getStringExtra(EXTRA_CALL_ID)?.let(CallManager::get) ?: return
        when (intent.action) {
            // vivo's island card: the call carries on in the island, no call screen.
            ACTION_ANSWER_IN_ISLAND -> call.answer(VideoProfile.STATE_AUDIO_ONLY)
            ACTION_DECLINE -> call.reject(false, null)
            ACTION_HANG_UP -> call.disconnect()
            ACTION_SPEAKER -> CallManager.service?.let {
                @Suppress("DEPRECATION") // CallAudioState still reports the route on API 34+
                val onSpeaker = it.callAudioState?.route == CallAudioState.ROUTE_SPEAKER
                it.setAudioRoute(if (onSpeaker) CallAudioState.ROUTE_WIRED_OR_EARPIECE else CallAudioState.ROUTE_SPEAKER)
            }
        }
        CallNotifications.cancelIncoming(context)
    }

    companion object {
        const val ACTION_ANSWER = "com.syedarhamraza.dialer.ANSWER"
        const val ACTION_DECLINE = "com.syedarhamraza.dialer.DECLINE"
        const val ACTION_HANG_UP = "com.syedarhamraza.dialer.HANG_UP"
        const val ACTION_ANSWER_IN_ISLAND = "com.syedarhamraza.dialer.ANSWER_IN_ISLAND"
        const val ACTION_SPEAKER = "com.syedarhamraza.dialer.SPEAKER"
        const val ACTION_MISSED_DISMISSED = "com.syedarhamraza.dialer.MISSED_DISMISSED"
        const val EXTRA_CALL_ID = "call_id"

        /**
         * Answer opens the call screen directly: Android 12+ blocks activity starts from a
         * notification's broadcast (a "trampoline"), which left answered calls in the background.
         * [InCallActivity] answers the call when it gets this intent.
         */
        fun answerIntent(context: Context, callId: String): PendingIntent = PendingIntent.getActivity(
            context, ACTION_ANSWER.hashCode(),
            InCallActivity.intent(context).setAction(ACTION_ANSWER).putExtra(EXTRA_CALL_ID, callId),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

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
