package com.syedarhamraza.dialer.telecom

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Handler
import android.os.Looper
import android.telecom.Call
import android.telecom.InCallService
import android.telecom.VideoProfile
import android.view.Surface
import io.flutter.view.TextureRegistry

/**
 * Carrier video (ViLTE/ViNR). Android's IMS stack runs the stream and the camera; the default
 * dialer hands it two surfaces, the other side's video and our camera's preview, which the call
 * screen shows as Flutter `Texture`s. Every call with a `VideoCall` gets a [Session] from the start
 * (so the other side's ask to switch to video reaches us); its surfaces are made only when the call
 * screen shows video, and dropped when the call goes back to voice or ends.
 */
object VideoCalls {
    /** The in-call engine's textures ([com.syedarhamraza.dialer.InCallEngine] sets it). */
    var textures: TextureRegistry? = null

    private val sessions = mutableMapOf<Call, Session>()

    /** Starts listening to [call]'s video (new call, or Telecom replaced its `VideoCall`). */
    fun track(call: Call) {
        sessions.remove(call)?.release()
        val videoCall = call.videoCall ?: return
        sessions[call] = Session(call, videoCall)
    }

    /** Drops [call]'s session and surfaces (the call ended). */
    fun release(call: Call) {
        sessions.remove(call)?.release()
    }

    /** The call's texture ids, made on first ask; null when the call has no video or no engine. */
    fun textures(context: Context, call: Call): Map<String, Long>? {
        val registry = textures ?: return null
        return sessions[call]?.surfaces(context, registry)
    }

    /** Back to voice: the surfaces and camera go, the session keeps listening. */
    fun dropSurfaces(call: Call) = sessions[call]?.dropSurfaces()

    /** What the snapshot says about this call's video (see [CallManager] `serialize`). */
    fun info(call: Call): Map<String, Any?> {
        val s = sessions[call]
        val details = call.details
        return mapOf(
            "video" to videoName(details.videoState),
            "canVideo" to (s != null &&
                details.can(Call.Details.CAPABILITY_SUPPORTS_VT_LOCAL_BIDIRECTIONAL) &&
                details.can(Call.Details.CAPABILITY_SUPPORTS_VT_REMOTE_BIDIRECTIONAL)),
            "videoRequest" to (s?.requested != null),
            "peerWidth" to (s?.peerWidth ?: 0),
            "peerHeight" to (s?.peerHeight ?: 0),
            "previewWidth" to (s?.previewWidth ?: 0),
            "previewHeight" to (s?.previewHeight ?: 0),
            "frontCamera" to (s?.front ?: true),
            "cameraRotation" to (s?.rotation ?: 0),
        )
    }

    /** Asks the network to change this call's video: `bidirectional`, `rx` (camera off) or `audio`. */
    fun request(context: Context, call: Call, state: String) {
        val s = sessions[call] ?: return
        val profile = when (state) {
            "bidirectional" -> VideoProfile.STATE_BIDIRECTIONAL
            "rx" -> VideoProfile.STATE_RX_ENABLED
            else -> VideoProfile.STATE_AUDIO_ONLY
        }
        s.camera(context, on = VideoProfile.isTransmissionEnabled(profile))
        s.videoCall.sendSessionModifyRequest(VideoProfile(profile))
    }

    /** Answers the other side's ask to switch to video. */
    fun respond(context: Context, call: Call, accept: Boolean) {
        val s = sessions[call] ?: return
        val requested = s.requested ?: return
        s.requested = null
        val state = if (accept) requested else call.details.videoState
        s.videoCall.sendSessionModifyResponse(VideoProfile(state))
        if (accept) s.camera(context, on = VideoProfile.isTransmissionEnabled(state))
        CallManager.notifyChanged()
    }

    fun flipCamera(context: Context, call: Call) {
        val s = sessions[call] ?: return
        s.front = !s.front
        s.camera(context, on = VideoProfile.isTransmissionEnabled(call.details.videoState))
        CallManager.notifyChanged()
    }

    private fun videoName(state: Int) = when {
        VideoProfile.isAudioOnly(state) -> "audio"
        VideoProfile.isPaused(state) -> "paused"
        VideoProfile.isBidirectional(state) -> "bidirectional"
        VideoProfile.isTransmissionEnabled(state) -> "tx"
        else -> "rx"
    }

    /** A Flutter texture backed by a SurfaceTexture, and the Surface the IMS stack draws into. */
    private class Texture(private val entry: TextureRegistry.SurfaceTextureEntry) {
        val id get() = entry.id()
        val surface = Surface(entry.surfaceTexture())

        fun size(width: Int, height: Int) = entry.surfaceTexture().setDefaultBufferSize(width, height)

        fun release() {
            surface.release()
            entry.release()
        }
    }

    private class Session(private val call: Call, val videoCall: InCallService.VideoCall) {
        // SurfaceTexture entries, as AOSP's TextureView: they apply the turn the platform marks on each
        // camera frame, which Impeller's SurfaceProducer drops (so the picture is upright on every phone).
        private var remote: Texture? = null
        private var local: Texture? = null
        private var cameraOn = false
        var peerWidth = 0
        var peerHeight = 0
        var previewWidth = 0
        var previewHeight = 0
        var front = true

        /** The camera's sensor angle, reported for diagnosis; the texture turns the frames itself. */
        var rotation = 0
        var requested: Int? = null

        private val callback = object : InCallService.VideoCall.Callback() {
            override fun onSessionModifyRequestReceived(videoProfile: VideoProfile) {
                requested = videoProfile.videoState
                CallManager.notifyChanged()
            }

            override fun onSessionModifyResponseReceived(status: Int, requestedProfile: VideoProfile?, responseProfile: VideoProfile?) =
                CallManager.notifyChanged()

            override fun onCallSessionEvent(event: Int) = CallManager.notifyChanged()

            override fun onPeerDimensionsChanged(width: Int, height: Int) {
                peerWidth = width
                peerHeight = height
                if (width > 0 && height > 0) remote?.size(width, height)
                CallManager.notifyChanged()
            }

            override fun onVideoQualityChanged(videoQuality: Int) = Unit
            override fun onCallDataUsageChanged(dataUsage: Long) = Unit

            override fun onCameraCapabilitiesChanged(cameraCapabilities: VideoProfile.CameraCapabilities) {
                previewWidth = cameraCapabilities.width
                previewHeight = cameraCapabilities.height
                if (previewWidth > 0 && previewHeight > 0) local?.size(previewWidth, previewHeight)
                CallManager.notifyChanged()
            }
        }

        init {
            videoCall.registerCallback(callback, Handler(Looper.getMainLooper()))
        }

        fun surfaces(context: Context, registry: TextureRegistry): Map<String, Long> {
            val remote = remote ?: Texture(registry.createSurfaceTexture()).also { t ->
                remote = t
                t.size(if (peerWidth > 0) peerWidth else 640, if (peerHeight > 0) peerHeight else 480)
                videoCall.setDisplaySurface(t.surface)
                // shortcut: portrait only (the call screen's usual way up); pass the display rotation for landscape video.
                videoCall.setDeviceOrientation(0)
            }
            val local = local ?: Texture(registry.createSurfaceTexture()).also { t ->
                local = t
                t.size(if (previewWidth > 0) previewWidth else 480, if (previewHeight > 0) previewHeight else 640)
            }
            camera(context, on = VideoProfile.isTransmissionEnabled(call.details.videoState))
            return mapOf("remote" to remote.id, "local" to local.id)
        }

        /** Our camera on ([front] or back) with its preview, or off; off too without the camera permission. */
        fun camera(context: Context, on: Boolean) {
            val allowed = context.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
            val id = if (on && allowed) cameraId(context, front) else null
            cameraOn = id != null
            if (id != null) {
                rotation = runCatching {
                    context.getSystemService(CameraManager::class.java)!!.getCameraCharacteristics(id)
                        .get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 0
                }.getOrDefault(0)
            }
            videoCall.setCamera(id)
            videoCall.setPreviewSurface(if (id != null) local?.surface else null)
            if (id != null) videoCall.requestCameraCapabilities()
        }

        fun dropSurfaces() {
            if (remote == null && local == null) return
            cameraOn = false
            videoCall.setCamera(null)
            videoCall.setPreviewSurface(null)
            videoCall.setDisplaySurface(null)
            remote?.release()
            local?.release()
            remote = null
            local = null
        }

        fun release() {
            dropSurfaces()
            videoCall.unregisterCallback(callback)
        }

        private fun cameraId(context: Context, front: Boolean): String? {
            val cameras = context.getSystemService(CameraManager::class.java) ?: return null
            val facing = if (front) CameraCharacteristics.LENS_FACING_FRONT else CameraCharacteristics.LENS_FACING_BACK
            return cameras.cameraIdList.firstOrNull {
                cameras.getCameraCharacteristics(it).get(CameraCharacteristics.LENS_FACING) == facing
            } ?: cameras.cameraIdList.firstOrNull()
        }
    }
}
