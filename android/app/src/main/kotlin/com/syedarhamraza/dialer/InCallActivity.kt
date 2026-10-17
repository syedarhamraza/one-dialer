package com.syedarhamraza.dialer

import android.content.Context
import android.content.Intent
import android.os.Bundle
import com.syedarhamraza.dialer.telecom.CallManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/** Hosts the in-call Flutter UI on the cached [InCallEngine]; shows over the lock screen. */
class InCallActivity : FlutterActivity() {

    private val closeWhenIdle = { if (!CallManager.isShowingCalls) finish() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        CallManager.addListener(closeWhenIdle)
    }

    override fun onDestroy() {
        CallManager.removeListener(closeWhenIdle)
        super.onDestroy()
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine = InCallEngine.ensure(context)

    // The engine outlives the screen so the next call opens instantly.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    companion object {
        fun intent(context: Context): Intent =
            Intent(context, InCallActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION)

        fun start(context: Context) = context.startActivity(intent(context))
    }
}
