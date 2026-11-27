package com.syedarhamraza.recorder

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import com.syedarhamraza.recorder.shell.ShellHelper
import java.io.File

/**
 * The Logs page's report: versions, phone, setup state, then One Recorder's log and the helper's
 * ([RecLog]). It leaves the phone only through the email, share or GitHub the user picks.
 * Nothing personal: the logs carry no numbers or names.
 */
object Diagnostics {
    /** Where Email sends reports. */
    const val REPORT_EMAIL = "arhamraza399@gmail.com"
    private const val ISSUES_URL = "https://github.com/syedarhamraza/one-dialer/issues/new"
    // shortcut: the clipboard rides one binder transaction (~1 MB), so GitHub gets the newest 200 KB; the file has all of it.
    private const val CLIP_CHARS = 200_000

    fun summary(context: Context): String {
        val dialer = runCatching { context.packageManager.getPackageInfo(TrustedDialer.PACKAGE, 0).versionName }.getOrNull()
        val last = RecorderSettings.lastCall(context)
        return listOf(
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
            "Last call: ${last?.let { "${RecLog.stamp(it.at)}, ${it.seconds} s, ${it.result}" } ?: "none"}",
        ).joinToString("\n")
    }

    /** Blocks (pings the helper, reads its log): call it off the main thread. */
    fun report(context: Context): String {
        if (ShellHelper.running(context)) ShellHelper.fetchHelperLog(context)
        val helper = RecLog.helperFile(context).takeIf { it.exists() }?.readText()
        return summary(context) +
            "\n\nOne Recorder log:\n" + RecLog.read(context).ifBlank { "(empty)\n" } +
            "\nHelper log:\n" + (helper?.ifBlank { null } ?: "(not fetched yet)\n")
    }

    /** The report as a file other apps can open. */
    private fun uri(context: Context, report: String): Uri {
        val file = File(RecLog.logDir(context), "one-recorder-report.txt").apply { writeText(report) }
        return FileProvider.getUriForFile(context, "${context.packageName}.files", file)
    }

    private fun send(subject: String, uri: Uri) = Intent(Intent.ACTION_SEND).setType("text/plain")
        .putExtra(Intent.EXTRA_SUBJECT, subject)
        .putExtra(Intent.EXTRA_STREAM, uri)
        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

    fun share(context: Context, report: String, subject: String) =
        context.startActivity(Intent.createChooser(send(subject, uri(context, report)), null))

    /** An email app only (the mailto: selector), with the report attached and the summary as the text. */
    fun email(context: Context, report: String, summary: String, subject: String) {
        val uri = uri(context, report)
        val intent = send(subject, uri)
            .putExtra(Intent.EXTRA_TEXT, summary)
            .apply { if (REPORT_EMAIL.isNotEmpty()) putExtra(Intent.EXTRA_EMAIL, arrayOf(REPORT_EMAIL)) }
        // The email apps (the manifest's <queries> lets One Recorder see them): one opens straight away,
        // several get a chooser of just those, none falls back to the share sheet.
        val apps = context.packageManager.queryIntentActivities(Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:")), 0)
            .map { it.activityInfo.packageName }.distinct()
        val targets = apps.map { Intent(intent).setPackage(it) }
        val start = when (targets.size) {
            0 -> Intent.createChooser(intent, null)
            1 -> targets[0]
            else -> Intent.createChooser(targets[0], null).putExtra(Intent.EXTRA_INITIAL_INTENTS, targets.drop(1).toTypedArray())
        }
        try {
            context.startActivity(start)
        } catch (e: ActivityNotFoundException) {
            RecLog.w("email: no app took the report", e)
            context.startActivity(Intent.createChooser(intent, null))
        }
    }

    /** Copies the report (a link can't hold it), then opens a new issue that already has the summary. */
    fun github(context: Context, report: String, summary: String, title: String, pasteHere: String) {
        context.getSystemService(ClipboardManager::class.java)
            .setPrimaryClip(ClipData.newPlainText(title, report.takeLast(CLIP_CHARS)))
        val body = "$pasteHere\n\n```\n$summary\n```\n"
        val url = Uri.parse(ISSUES_URL).buildUpon()
            .appendQueryParameter("title", title)
            .appendQueryParameter("body", body)
            .build()
        context.startActivity(Intent(Intent.ACTION_VIEW, url))
    }
}
