package com.syedarhamraza.recorder

import android.content.Context
import android.content.Intent
import android.os.Build
import com.syedarhamraza.recorder.shell.ShellHelper

/**
 * Setup's Share diagnostics: a plain-text report for bug reports, handed to the share sheet so
 * the user picks where it goes. Nothing personal: One Recorder's log lines carry no numbers or names.
 */
object Diagnostics {
    /** Blocks (it pings the helper and reads the log): call it off the main thread. */
    fun report(context: Context): String {
        val dialer = runCatching { context.packageManager.getPackageInfo(TrustedDialer.PACKAGE, 0).versionName }.getOrNull()
        val last = RecorderSettings.lastCall(context)
        val lines = listOf(
            "One Recorder ${BuildConfig.VERSION_NAME}",
            "One Dialer ${dialer ?: "not installed"}",
            "${Build.MANUFACTURER} ${Build.MODEL}, Android ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})",
            "",
            "Paired: ${ShellHelper.paired(context)}",
            "Helper running: ${ShellHelper.running(context)}",
            "Start after a reboot (grant): ${ShellHelper.canRestart(context)}",
            "On Wi-Fi: ${ShellHelper.onWifi(context)}, Wireless debugging: ${ShellHelper.wirelessOn(context)}",
            "Developer options: ${ShellHelper.developerOptionsOn(context)}",
            "Hide Developer options: ${RecorderSettings.hideDeveloperOptions(context)}" +
                " (unsupported ${RecorderSettings.hideUnsupported(context)}, keep USB ${RecorderSettings.keepUsbDebugging(context)}," +
                " keep wireless ${RecorderSettings.keepWirelessDebugging(context)})",
            "Keep recording away from Wi-Fi: ${RecorderSettings.keepRecordingOffWifi(context)}",
            "Start without Wi-Fi: ${RecorderSettings.startWithoutWifi(context)}",
            "Last check: ${RecorderSettings.lastCheck(context) ?: "never"}",
            "Last call: ${last?.let { "${java.util.Date(it.at)}, ${it.seconds} s, ${it.result}" } ?: "none"}",
            "",
            "Log:",
            log(),
        )
        return lines.joinToString("\n")
    }

    /** One Recorder's own recent log lines; an app only sees its own process's. */
    private fun log(): String = runCatching {
        val process = ProcessBuilder("logcat", "-d", "-t", "50", "-s", "OneRecorder").redirectErrorStream(true).start()
        process.inputStream.bufferedReader().readText().also { process.waitFor() }
    }.getOrDefault("(unavailable)")

    fun share(context: Context, report: String, subject: String) = context.startActivity(Intent.createChooser(
        Intent(Intent.ACTION_SEND).setType("text/plain")
            .putExtra(Intent.EXTRA_SUBJECT, subject)
            .putExtra(Intent.EXTRA_TEXT, report),
        null,
    ))
}
