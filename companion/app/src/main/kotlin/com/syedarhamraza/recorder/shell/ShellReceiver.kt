package com.syedarhamraza.recorder.shell

import android.app.RemoteInput
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import kotlin.concurrent.thread

/** Starts the both-sides helper again after a reboot, an update or reaching Wi-Fi, and takes the pairing code. */
class ShellReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_WIFI = "com.syedarhamraza.recorder.WIFI"
        const val ACTION_PAIR = "com.syedarhamraza.recorder.PAIR"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext
        val code = if (intent.action == ACTION_PAIR) RemoteInput.getResultsFromIntent(intent)?.getCharSequence(ShellHelper.KEY_CODE)?.toString() else null
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED, ACTION_WIFI -> Unit
            ACTION_PAIR -> if (code.isNullOrBlank()) return
            else -> return
        }
        // Pairing and starting take several seconds of network work.
        val pending = goAsync()
        thread {
            try {
                if (code != null) ShellHelper.pair(app, code) else ShellHelper.restart(app)
            } finally {
                pending.finish()
            }
        }
    }
}
