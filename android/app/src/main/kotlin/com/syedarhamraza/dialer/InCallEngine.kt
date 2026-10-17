package com.syedarhamraza.dialer

import android.content.Context
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * A Flutter engine running the `inCallMain` entrypoint, created when Telecom binds
 * [com.syedarhamraza.dialer.telecom.DialerInCallService] so the call screen opens instantly.
 */
object InCallEngine {
    const val ID = "in_call"
    private const val ENTRYPOINT = "inCallMain"

    private var bridge: CallBridge? = null

    fun ensure(context: Context): FlutterEngine {
        FlutterEngineCache.getInstance().get(ID)?.let { return it }

        val app = context.applicationContext
        val engine = FlutterEngine(app)
        bridge = CallBridge(app, engine.dartExecutor.binaryMessenger)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                ENTRYPOINT,
            )
        )
        FlutterEngineCache.getInstance().put(ID, engine)
        return engine
    }
}
