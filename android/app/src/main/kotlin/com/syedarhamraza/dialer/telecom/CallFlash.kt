package com.syedarhamraza.dialer.telecom

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.os.Handler
import android.os.Looper

/**
 * Settings › Incoming call reminders › Flash notification: blinks the camera flash while a call
 * rings. setTorchMode needs no CAMERA permission. Off by default; phones with their own flash
 * notification (vivo, OPPO, Samsung...) get a hint in Settings so the two don't both blink.
 */
object CallFlash {
    private const val ON_MS = 250L
    private const val OFF_MS = 450L
    private const val MAX_MS = 60_000L // never blinks longer than a call can ring

    private val handler = Handler(Looper.getMainLooper())
    private var camera: CameraManager? = null
    private var cameraId: String? = null
    private var lit = false
    private var startedAt = 0L

    /** The user's own torch is on (Quick Settings): leave it alone. */
    @Volatile private var torchInUse = false
    private var watching = false
    private val torchWatch = object : CameraManager.TorchCallback() {
        override fun onTorchModeChanged(id: String, enabled: Boolean) {
            if (id == cameraId && !running) torchInUse = enabled
        }
    }

    private val running get() = startedAt != 0L

    fun start(context: Context) {
        if (running || CallPrefs.read(context)["flashOnCall"] != true) return
        // Silent mode means no alerts at all, flash included.
        if (context.getSystemService(AudioManager::class.java)?.ringerMode == AudioManager.RINGER_MODE_SILENT) return
        val manager = context.getSystemService(CameraManager::class.java) ?: return
        val id = cameraId ?: runCatching {
            manager.cameraIdList.firstOrNull {
                val c = manager.getCameraCharacteristics(it)
                c.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true &&
                    c.get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_BACK
            }
        }.getOrNull() ?: return
        camera = manager
        cameraId = id
        // shortcut: the first call after start-up can't know the user's torch is already on (the
        // callback reports it asynchronously), so it may blink over it once; fine for a rare case.
        if (!watching) {
            manager.registerTorchCallback(torchWatch, handler)
            watching = true
        }
        if (torchInUse) return
        startedAt = System.currentTimeMillis()
        blink()
    }

    fun stop() {
        if (!running) return
        startedAt = 0L
        handler.removeCallbacks(blinkStep)
        if (lit) torch(false)
    }

    private val blinkStep = Runnable { blink() }

    private fun blink() {
        if (!running) return
        if (System.currentTimeMillis() - startedAt > MAX_MS) return stop()
        torch(!lit)
        handler.postDelayed(blinkStep, if (lit) ON_MS else OFF_MS)
    }

    private fun torch(on: Boolean) {
        lit = on
        // Another app (the camera) can hold the flash; then just stop.
        runCatching { camera?.setTorchMode(cameraId ?: return, on) }.onFailure {
            lit = false
            startedAt = 0L
            handler.removeCallbacks(blinkStep)
        }
    }
}
