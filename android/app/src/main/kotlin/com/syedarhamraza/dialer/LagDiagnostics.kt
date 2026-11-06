package com.syedarhamraza.dialer

import android.content.Context
import android.os.Build
import android.os.Debug
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.MotionEvent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/** One process-wide worker; neither disk nor Firebase runs on the Telecom/UI thread. */
internal object LagDiagnostics {
    private val worker = Executors.newSingleThreadScheduledExecutor { task ->
        Thread(task, "dialer-diagnostics").apply { isDaemon = true }
    }
    private val main = Handler(Looper.getMainLooper())
    private val pingPending = AtomicBoolean(false)
    @Volatile private var mainBeat = 0L
    private val policy = DiagnosticsPolicy()
    private val session = UUID.randomUUID().toString()
    private val engines = mutableMapOf<String, Engine>()
    private var store: DiagnosticsStore? = null
    private var app: Context? = null
    private var watchdog: ScheduledFuture<*>? = null
    private var lease: Pair<String, Long>? = null
    private var prunedAt = 0L
    private var lastTick = 0L

    private class Engine {
        var enabled = false
        var resumed = false
        var resumedAt = 0L
        var beat = 0L
        var context = JSONObject()
        val history = ArrayDeque<JSONObject>()
        // InputStall: touches Android delivered that Dart has not counted yet.
        var dartDowns = -1L
        var firstUnseenTouchAt = 0L
        var lastTouchAt = 0L
    }

    private val actions = setOf("keypad", "backspace", "tab_calls", "tab_contacts", "contacts_load",
        "call_log_load", "playTone", "stopTone", "answer", "reject", "rejectWithMessage", "hangUp",
        "hold", "unhold", "playDtmf", "stopDtmf", "merge", "swap")
    private val categories = setOf("SevereFrameDelay", "NativeMainStall", "DartStall", "RenderStall", "InputStall", "UserReportedLag")

    private fun safely(work: () -> Unit) { worker.execute { runCatching(work) } }

    fun attach(context: Context, messenger: BinaryMessenger, engine: String): MethodChannel {
        safely {
            app = context.applicationContext
            if (store == null) store = DiagnosticsStore(File(context.noBackupFilesDir, "lag-diagnostics/queue"))
            engines.getOrPut(engine) { Engine() }
            store?.prune(System.currentTimeMillis())
        }
        // The task queue still receives Dart heartbeats when Android's main thread is blocked.
        return MethodChannel(messenger, "com.syedarhamraza.dialer/diagnostics", StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue()).also { channel ->
            channel.setMethodCallHandler { call, result ->
                worker.execute {
                    runCatching {
                        val state = engines.getOrPut(engine) { Engine() }
                        val now = SystemClock.uptimeMillis()
                        when (call.method) {
                            "register" -> {
                                state.enabled = call.argument<Boolean>("enabled") == true
                                state.beat = now
                                state.resumedAt = now
                                scheduleWatchdog()
                                result.success(state.enabled)
                            }
                            "heartbeat" -> {
                                state.beat = now
                                if (state.enabled) updateContext(state, call.arguments as? Map<*, *>)
                                call.argument<Number>("pointerDowns")?.toLong()?.let {
                                    if (it != state.dartDowns) {
                                        state.dartDowns = it
                                        state.firstUnseenTouchAt = 0
                                    }
                                }
                                result.success(null)
                            }
                            "actionFrames" -> {
                                val frames = DiagnosticsPolicy.actionFrames(call.arguments as? Map<*, *>)
                                val name = call.argument<String>("name")
                                if (state.enabled && frames != null) state.history.lastOrNull {
                                    it.optString("action") == name && !it.has("frames")
                                }?.let { entry -> frames.forEach { (key, value) -> entry.put(key, value) } }
                                result.success(null)
                            }
                            "action" -> {
                                if (state.enabled) addAction(state, call.argument<String>("name"),
                                    call.argument<Number>("elapsedMs")?.toLong(), now)
                                result.success(null)
                            }
                            "report" -> result.success(if (state.enabled) report(engine,
                                call.argument<String>("category") ?: "", now) else null)
                            "claim" -> {
                                val held = lease
                                if (!state.enabled || (held != null && now - held.second < 60_000)) result.success(null)
                                else {
                                    val row = store?.pending(System.currentTimeMillis())?.firstOrNull()
                                    lease = row?.let { it.id to now }
                                    result.success(row?.let { mapOf("id" to it.id, "payload" to it.payload) })
                                }
                            }
                            "ack" -> {
                                val id = call.argument<String>("id")
                                if (id != null && lease?.first == id) {
                                    store?.ack(id, System.currentTimeMillis())
                                    lease = null
                                }
                                result.success(null)
                            }
                            "release" -> {
                                if (lease?.first == call.argument<String>("id")) lease = null
                                result.success(null)
                            }
                            // Only reachable in a debuggable APK, never in a Play build.
                            "testNativeStall" -> {
                                if ((app!!.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
                                    main.post { Thread.sleep(4_000) }
                                }
                                result.success(null)
                            }
                            else -> result.notImplemented()
                        }
                    }.onFailure { result.error("DIAGNOSTICS_UNAVAILABLE", "Diagnostics unavailable", null) }
                }
            }
        }
    }

    fun foreground(engine: String, resumed: Boolean) {
        val now = SystemClock.uptimeMillis()
        safely {
            val state = engines.getOrPut(engine) { Engine() }
            state.resumed = resumed
            state.resumedAt = now
            state.beat = now
            mainBeat = now
            scheduleWatchdog()
        }
    }

    private fun scheduleWatchdog() {
        if (engines.values.any { it.enabled && it.resumed }) {
            if (watchdog == null) watchdog = worker.scheduleWithFixedDelay({ runCatching { tick() } }, 1, 1, TimeUnit.SECONDS)
        } else {
            watchdog?.cancel(false)
            watchdog = null
        }
    }

    /** Called from the activities' dispatchTouchEvent; only the moment of a finger going down is kept. */
    fun touch(engine: String, event: MotionEvent) {
        val action = event.actionMasked
        if (action != MotionEvent.ACTION_DOWN && action != MotionEvent.ACTION_POINTER_DOWN) return
        val now = SystemClock.uptimeMillis()
        safely {
            val state = engines[engine] ?: return@safely
            state.lastTouchAt = now
            if (state.firstUnseenTouchAt == 0L) state.firstUnseenTouchAt = now
        }
    }

    fun operation(engine: String, name: String, elapsedMs: Long? = null) {
        if (name !in actions) return
        val now = SystemClock.uptimeMillis()
        safely { engines[engine]?.takeIf { it.enabled }?.let { addAction(it, name, elapsedMs, now) } }
    }

    private fun addAction(state: Engine, name: String?, elapsed: Long?, now: Long) {
        if (name !in actions) return
        state.history.addLast(JSONObject().put("action", name).put("uptimeMs", now)
            .put("elapsedMs", elapsed?.coerceIn(0, 600_000) ?: JSONObject.NULL))
        while (state.history.size > 40) state.history.removeFirst()
    }

    private fun updateContext(state: Engine, values: Map<*, *>?) {
        if (values == null) return
        state.context = JSONObject(DiagnosticsPolicy.context(values))
    }

    private fun tick() {
        val now = SystemClock.uptimeMillis()
        if (now - prunedAt >= 60_000) {
            store?.prune(System.currentTimeMillis())
            prunedAt = now
        }
        if (engines.values.none { it.enabled && it.resumed }) return
        val paused = DiagnosticsPolicy.processPaused(now, lastTick)
        lastTick = now
        if (paused || Debug.isDebuggerConnected() || Debug.waitingForDebugger()) {
            engines.values.forEach { it.resumedAt = now; it.beat = now }
            mainBeat = now
            return
        }
        for ((name, state) in engines) {
            if (!state.enabled) continue
            if (DiagnosticsPolicy.stalled(now, state.resumedAt, mainBeat, state.resumed, false)) {
                report(name, "NativeMainStall", now)
            } else if (DiagnosticsPolicy.stalled(now, state.resumedAt, state.beat, state.resumed, false)) {
                report(name, "DartStall", now)
            } else if (DiagnosticsPolicy.inputStalled(now, state.firstUnseenTouchAt, state.lastTouchAt, state.beat)) {
                report(name, "InputStall", now)
                state.firstUnseenTouchAt = 0
            }
        }
        if (pingPending.compareAndSet(false, true)) main.post {
            mainBeat = SystemClock.uptimeMillis()
            pingPending.set(false)
        }
    }

    private fun report(engine: String, category: String, now: Long): String? {
        if (category !in categories) return null
        val state = engines[engine] ?: return null
        if (category != "UserReportedLag" && (!state.resumed || now - state.resumedAt < 5_000 || Debug.isDebuggerConnected())) return null
        if (!policy.allow(category, now)) return null
        val context = app ?: return null
        val id = UUID.randomUUID().toString()
        val at = System.currentTimeMillis()
        val info = context.packageManager.getPackageInfo(context.packageName, 0)
        val payload = JSONObject().put("reportId", id).put("session", session).put("engine", engine)
            .put("category", category).put("at", at).put("context", state.context)
            .put("lifecycle", if (state.resumed) "resumed" else "background")
            .put("history", JSONArray(state.history.toList())).put("version", info.versionName)
            .put("build", info.longVersionCode).put("manufacturer", Build.MANUFACTURER)
            .put("model", Build.MODEL)
            .put("soc", if (Build.VERSION.SDK_INT >= 31) "${Build.SOC_MANUFACTURER} ${Build.SOC_MODEL}" else Build.HARDWARE)
            .put("android", Build.VERSION.RELEASE).put("sdk", Build.VERSION.SDK_INT)
            .put("mainHeartbeatAgeMs", now - mainBeat).put("dartHeartbeatAgeMs", now - state.beat)
        if (category == "NativeMainStall") payload.put("mainStack",
            Looper.getMainLooper().thread.stackTrace.take(64).joinToString("\n"))
        store?.add(PendingDiagnostic(id, at, payload.toString()), at) ?: return null
        return id
    }
}
