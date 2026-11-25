package com.syedarhamraza.dialer.debug

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraManager
import android.graphics.Paint
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.HandlerThread
import android.view.Surface
import android.telecom.Conference
import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.DisconnectCause
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.telecom.VideoProfile
import android.util.Log

/**
 * DEBUG BUILDS ONLY: a fake phone line so incoming calls can be tested without a second phone.
 * Telecom routes its calls to our InCallService like real SIM calls (ringtone, lock screen,
 * notifications); there's just no audio.
 *
 * Ring the phone:
 *   adb shell am broadcast -n com.syedarhamraza.onedialer/com.syedarhamraza.dialer.debug.FakeCallReceiver --es number 03001234567
 * (`--ez private true` for a hidden number, `--ez video true` for a carrier-style video call with a
 * moving test pattern, `--ez ask_video true` alone to have the latest call ask to switch to video.)
 * The first broadcast registers the line; enable it once with
 *   adb shell telecom set-phone-account-enabled com.syedarhamraza.onedialer/com.syedarhamraza.dialer.debug.FakeCallService fake 0
 */
class FakeCallService : ConnectionService() {

    override fun onCreateIncomingConnection(manager: PhoneAccountHandle?, request: ConnectionRequest): Connection {
        // A hidden caller arrives with no number (Telecom doesn't pass our own extras through).
        val private = request.address?.schemeSpecificPart.isNullOrEmpty()
        return FakeConnection().apply {
            setAddress(
                request.address,
                if (private) TelecomManager.PRESENTATION_RESTRICTED else TelecomManager.PRESENTATION_ALLOWED,
            )
            connectionCapabilities = Connection.CAPABILITY_HOLD or Connection.CAPABILITY_SUPPORT_HOLD or
                Connection.CAPABILITY_MUTE or Connection.CAPABILITY_SUPPORTS_VT_LOCAL_BIDIRECTIONAL or
                Connection.CAPABILITY_SUPPORTS_VT_REMOTE_BIDIRECTIONAL
            videoState = request.videoState
            videoProvider = video
            askVideo = { video.receiveSessionModifyRequest(VideoProfile(VideoProfile.STATE_BIDIRECTIONAL)) }
            setInitializing()
            setRinging()
            live += this
            linkConferenceable()
        }
    }

    override fun onCreateIncomingConnectionFailed(manager: PhoneAccountHandle?, request: ConnectionRequest?) {
        Log.w(TAG, "Telecom rejected the fake incoming call (is the account enabled?)")
    }

    // Two test calls can merge, so the call screen's Merge and conference look can be tested.
    private val live = mutableListOf<FakeConnection>()

    private fun linkConferenceable() =
        live.forEach { c -> c.setConferenceableConnections(live.filter { it !== c && it.conference == null }) }

    override fun onConference(a: Connection, b: Connection) {
        addConference(FakeConference(handle(this)).apply {
            addConnection(a)
            addConnection(b)
            setActive()
        })
        a.setActive()
        b.setActive()
        linkConferenceable()
    }

    // shortcut: no Separate, and a conference left with one call stays a conference; enough to see the look.
    private class FakeConference(handle: PhoneAccountHandle) : Conference(handle) {
        init {
            connectionCapabilities = Connection.CAPABILITY_HOLD or Connection.CAPABILITY_SUPPORT_HOLD or
                Connection.CAPABILITY_MUTE
        }

        override fun onDisconnect() {
            connections.toList().forEach { it.onDisconnect() }
            setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
            destroy()
        }
        override fun onHold() = setOnHold()
        override fun onUnhold() = setActive()
    }

    private inner class FakeConnection : Connection() {
        val video = FakeVideo(this@FakeCallService, this)
        // Telecom answers audio-only with this one (no video state), as a carrier call goes to voice.
        override fun onAnswer() = onAnswer(VideoProfile.STATE_AUDIO_ONLY)
        override fun onAnswer(videoState: Int) {
            setVideoState(videoState)
            setActive()
        }
        override fun onReject() = end(DisconnectCause.REJECTED)
        override fun onReject(replyMessage: String?) {
            Log.i(TAG, "Declined with message: $replyMessage")
            end(DisconnectCause.REJECTED)
        }
        override fun onDisconnect() = end(DisconnectCause.LOCAL)
        override fun onAbort() = end(DisconnectCause.OTHER)
        override fun onHold() = setOnHold()
        override fun onUnhold() = setActive()

        private fun end(cause: Int) {
            video.stop()
            setDisconnected(DisconnectCause(cause))
            destroy()
            live -= this
            linkConferenceable()
        }
    }

    /**
     * Draws a moving test pattern as "their" video, streams the real camera into our preview (as the
     * IMS stack does), and agrees to every switch.
     */
    private class FakeVideo(context: Context, private val connection: Connection) : Connection.VideoProvider() {
        private val cameras = context.getSystemService(CameraManager::class.java)
        private var cameraId: String? = null
        private var device: CameraDevice? = null
        private var session: CameraCaptureSession? = null
        @Volatile private var display: Surface? = null
        @Volatile private var preview: Surface? = null
        private val thread = HandlerThread("fake-video").apply { start() }
        private val handler = Handler(thread.looper)
        private val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textSize = 56f
        }
        private var frame = 0

        private val draw = object : Runnable {
            override fun run() {
                paint(display, "Test line", 0f)
                frame++
                handler.postDelayed(this, 66)
            }
        }

        init {
            handler.post(draw)
        }

        private fun paint(surface: Surface?, label: String, hue: Float) {
            surface ?: return
            runCatching {
                val canvas = surface.lockHardwareCanvas()
                try {
                    canvas.drawColor(Color.HSVToColor(floatArrayOf((hue + frame * 2) % 360, .55f, .55f)))
                    val x = canvas.width / 2f + canvas.width / 3f * kotlin.math.sin(frame / 10.0).toFloat()
                    canvas.drawCircle(x, canvas.height / 2f, canvas.width / 8f, text)
                    canvas.drawText(label, 32f, 96f, text)
                } finally {
                    surface.unlockCanvasAndPost(canvas)
                }
            }
        }

        fun stop() {
            handler.removeCallbacksAndMessages(null)
            handler.post {
                session?.close()
                device?.close()
            }
            thread.quitSafely()
        }

        override fun onSetCamera(cameraId: String?) {
            handler.post {
                this.cameraId = cameraId
                restartCamera()
            }
            // The camera's own frame (landscape), as a real IMS stack reports it.
            if (cameraId != null) changeCameraCapabilities(VideoProfile.CameraCapabilities(640, 480))
        }

        override fun onSetPreviewSurface(surface: Surface?) {
            preview = surface
            handler.post { restartCamera() }
        }

        /** The camera into the preview surface while both are set; closed otherwise. */
        private fun restartCamera() {
            session?.close()
            session = null
            val id = cameraId
            val surface = preview
            if (id == null || surface == null) {
                device?.close()
                device = null
                return
            }
            device?.takeIf { it.id == id }?.let { return startSession(it, surface) }
            device?.close()
            device = null
            try {
                cameras.openCamera(id, object : CameraDevice.StateCallback() {
                    override fun onOpened(camera: CameraDevice) {
                        device = camera
                        preview?.let { startSession(camera, it) }
                    }

                    override fun onDisconnected(camera: CameraDevice) = camera.close()
                    override fun onError(camera: CameraDevice, error: Int) {
                        Log.w(TAG, "Camera $id error $error")
                        camera.close()
                    }
                }, handler)
            } catch (e: Exception) {
                Log.w(TAG, "Couldn't open camera $id", e)
            }
        }

        @Suppress("DEPRECATION") // the List<Surface> form keeps minSdk 29 simple
        private fun startSession(camera: CameraDevice, surface: Surface) {
            runCatching {
                camera.createCaptureSession(listOf(surface), object : CameraCaptureSession.StateCallback() {
                    override fun onConfigured(s: CameraCaptureSession) {
                        session = s
                        val request = camera.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW).apply { addTarget(surface) }
                        runCatching { s.setRepeatingRequest(request.build(), null, handler) }
                    }

                    override fun onConfigureFailed(s: CameraCaptureSession) {
                        Log.w(TAG, "Camera session failed")
                    }
                }, handler)
            }.onFailure { Log.w(TAG, "Couldn't start the camera", it) }
        }

        override fun onSetDisplaySurface(surface: Surface?) {
            display = surface
            if (surface != null) changePeerDimensions(480, 640)
        }

        override fun onSetDeviceOrientation(rotation: Int) = Unit
        override fun onSetZoom(value: Float) = Unit

        override fun onSendSessionModifyRequest(fromProfile: VideoProfile?, toProfile: VideoProfile?) {
            toProfile ?: return
            receiveSessionModifyResponse(SESSION_MODIFY_REQUEST_SUCCESS, toProfile, toProfile)
            connection.setVideoState(toProfile.videoState)
        }

        override fun onSendSessionModifyResponse(responseProfile: VideoProfile?) {
            responseProfile?.let { connection.setVideoState(it.videoState) }
        }

        override fun onRequestCameraCapabilities() = changeCameraCapabilities(VideoProfile.CameraCapabilities(640, 480))
        override fun onRequestConnectionDataUsage() = Unit
        override fun onSetPauseImage(uri: Uri?) = Unit
    }

    companion object {
        const val TAG = "FakeCalls"

        /** The latest fake call asks to switch to video (`--ez ask_video true`). */
        var askVideo: (() -> Unit)? = null
        const val ACCOUNT_ID = "fake"

        fun handle(context: Context) =
            PhoneAccountHandle(ComponentName(context, FakeCallService::class.java), ACCOUNT_ID)
    }
}

/** `adb shell am broadcast` target that rings the phone from the fake line. */
class FakeCallReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.getBooleanExtra("ask_video", false)) {
            FakeCallService.askVideo?.invoke() ?: Log.w(FakeCallService.TAG, "No fake call to ask from")
            return
        }
        val telecom = context.getSystemService(TelecomManager::class.java)
        val handle = FakeCallService.handle(context)
        telecom.registerPhoneAccount(
            PhoneAccount.builder(handle, "Test line")
                .setCapabilities(
                    PhoneAccount.CAPABILITY_CALL_PROVIDER or PhoneAccount.CAPABILITY_VIDEO_CALLING or
                        PhoneAccount.CAPABILITY_SUPPORTS_VIDEO_CALLING,
                )
                .addSupportedUriScheme(PhoneAccount.SCHEME_TEL)
                .build()
        )
        val number = if (intent.getBooleanExtra("private", false)) "" else intent.getStringExtra("number") ?: "03001234567"
        val extras = Bundle().apply {
            putParcelable(TelecomManager.EXTRA_INCOMING_CALL_ADDRESS, Uri.fromParts(PhoneAccount.SCHEME_TEL, number, null))
            if (intent.getBooleanExtra("video", false)) {
                putInt(TelecomManager.EXTRA_INCOMING_VIDEO_STATE, VideoProfile.STATE_BIDIRECTIONAL)
            }
        }
        runCatching { telecom.addNewIncomingCall(handle, extras) }
            .onSuccess { Log.i(FakeCallService.TAG, "Fake incoming call requested") }
            .onFailure { Log.w(FakeCallService.TAG, "addNewIncomingCall failed: ${it.message}") }
    }
}
