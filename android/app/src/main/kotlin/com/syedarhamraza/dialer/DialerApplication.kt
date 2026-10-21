package com.syedarhamraza.dialer

import android.app.Application
import android.os.Build
import io.flutter.FlutterInjector

class DialerApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        // Impeller's Vulkan path on Adreno splits the render pass at every backdrop blur, and
        // the app's glass is all blurs: on a Galaxy S25 that was most frames over budget. Its
        // OpenGL ES path draws the same frames in about half the time. Mali (the vivo) keeps
        // Vulkan. Process-wide, so both engines (main and in-call) get it; set before either starts.
        if (isAdreno()) {
            FlutterInjector.instance().flutterLoader().run {
                startInitialization(this@DialerApplication)
                ensureInitializationComplete(this@DialerApplication, arrayOf("--impeller-backend=opengles"))
            }
        }
    }

    /** Snapdragon SoCs carry Adreno GPUs. */
    private fun isAdreno(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) Build.SOC_MANUFACTURER.equals("QTI", ignoreCase = true)
        else Build.HARDWARE.equals("qcom", ignoreCase = true)
}
