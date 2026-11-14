package com.syedarhamraza.recorder

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.View
import com.syedarhamraza.recorder.shell.ShellHelper
import kotlin.concurrent.thread

/**
 * The companion's setup, laid out like One Dialer › Settings › Call recording (a ColorOS 17
 * subpage): what recording needs, each fixable from its row, the recorder's settings, and the
 * consent notice, which [ConsentActivity] shows first until it's agreed to. Recordings live in One Dialer.
 */
class SetupActivity : Activity() {
    private lateinit var page: Subpage

    override fun attachBaseContext(base: android.content.Context) = super.attachBaseContext(OneLook.themed(base))

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        page = Subpage(this, getString(R.string.app_name)) { finish() }
        if (!RecorderSettings.consentAccepted(this)) {
            startActivity(Intent(this, ConsentActivity::class.java).putExtra(ConsentActivity.FIRST_RUN, true))
            @Suppress("DEPRECATION") overridePendingTransition(0, 0)
        }
    }

    override fun onResume() {
        super.onResume()
        render()
        RecordingsProvider.notifyStatus(this)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        render()
        RecordingsProvider.notifyStatus(this)
    }

    private fun render() {
        val scroll = page.scroll.scrollY
        page.content.removeAllViews()

        val bothSides = ShellHelper.supported()
        val helperUp = bothSides && ShellHelper.running(this)
        if (bothSides) {
            val paired = ShellHelper.paired(this)
            val helper = when {
                helperUp -> page.row(getString(R.string.setup_helper), getString(R.string.setup_done))
                starting -> page.row(getString(R.string.setup_helper), getString(R.string.setup_helper_starting))
                else -> page.row(getString(R.string.setup_helper), getString(R.string.setup_helper_detail), OneLook.RED,
                    getString(R.string.setup_helper_start)) { startHelper() }
            }
            page.group(listOf(
                page.row(getString(R.string.section_both_sides), getString(R.string.both_sides_intro)),
                need(getString(R.string.setup_dev_options), getString(R.string.setup_dev_options_detail), ShellHelper.developerOptionsOn(this)) {
                    startActivity(Intent(Settings.ACTION_DEVICE_INFO_SETTINGS))
                },
                need(getString(R.string.setup_pair), getString(R.string.setup_pair_detail), paired, done = R.string.setup_paired) {
                    ShellHelper.askForPairingCode(this)
                    startActivity(ShellHelper.wirelessDebuggingIntent())
                },
            ) + (if (paired) listOf(
                helper,
                page.row(
                    getString(R.string.setup_restart),
                    getString(if (ShellHelper.canRestart(this)) R.string.setup_restart_ready else R.string.setup_restart_detail),
                ),
            ) else emptyList()), header = getString(R.string.section_both_sides))
        }

        page.group(listOf(
            need(getString(R.string.setup_mic), getString(R.string.setup_mic_detail), RecordingService.micGranted(this)) {
                requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 1)
            },
            need(getString(R.string.setup_accessibility), accessibilityDetail(), RecordingService.accessibilityOn(this)) {
                startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
            },
        ), header = getString(if (helperUp) R.string.section_microphone_optional else R.string.section_microphone))

        page.group(listOf(
            need(
                getString(R.string.setup_notifications), getString(R.string.setup_notifications_detail),
                getSystemService(NotificationManager::class.java).areNotificationsEnabled(),
            ) {
                if (Build.VERSION.SDK_INT >= 33) requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 2)
                else startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
            },
            // vivo and other OEM battery managers stop idle apps, which switches the accessibility service off.
            need(
                getString(R.string.setup_battery), getString(R.string.setup_battery_detail),
                getSystemService(android.os.PowerManager::class.java).isIgnoringBatteryOptimizations(packageName),
            ) {
                startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName")))
            },
        ), header = getString(R.string.section_permissions))

        // Android 13+ greys out a sideloaded app's accessibility switch until restricted settings are allowed.
        if (Build.VERSION.SDK_INT >= 33 && !RecordingService.accessibilityOn(this)) {
            page.group(listOf(page.row(getString(R.string.setup_open_app_info), getString(R.string.setup_restricted)) {
                startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null)))
            }))
        }

        page.group((if (bothSides) listOf(
            setting(getString(R.string.setting_method), "method", listOf(
                "auto" to getString(R.string.method_auto),
                "shell" to getString(R.string.method_shell),
                "mic" to getString(R.string.method_mic),
            )),
        ) else emptyList()) + listOf(
            setting(getString(R.string.setting_source), "sourceMode", listOf(
                "auto" to getString(R.string.source_auto),
                "recognition" to getString(R.string.source_recognition),
                "communication" to getString(R.string.source_communication),
                "mic" to getString(R.string.source_mic),
            )),
            setting(getString(R.string.setting_boost), "boost", listOf(
                "off" to getString(R.string.boost_off),
                "normal" to getString(R.string.boost_normal),
                "strong" to getString(R.string.boost_strong),
            )),
        ), header = getString(R.string.section_recording))

        val themes = listOf(
            "system" to getString(R.string.theme_system),
            "light" to getString(R.string.theme_light),
            "dark" to getString(R.string.theme_dark),
        )
        page.group(listOf(
            choice(getString(R.string.setting_theme), RecorderSettings.theme(this), themes) { value ->
                RecorderSettings.setTheme(this, value)
                window.decorView.postDelayed({ recreate() }, 200) // after the menu has closed (170 ms)
            },
        ), header = getString(R.string.section_appearance))

        page.group(listOf(page.row(getString(R.string.consent_title), getString(R.string.setup_consent)) {
            startActivity(Intent(this, ConsentActivity::class.java))
        }), header = getString(R.string.section_law))

        page.scroll.post { page.scroll.scrollTo(0, scroll) }
    }

    private fun accessibilityDetail() = getString(R.string.setup_accessibility_detail)

    /** As One Dialer's Recorder row: the status, red with "Fix" and a chevron until it's done. */
    private fun need(title: String, detail: String, ok: Boolean, done: Int = R.string.setup_done, fix: () -> Unit): View =
        if (ok) page.row(title, getString(done))
        else page.row(title, detail, OneLook.RED, getString(R.string.fix), onTap = fix)

    private var starting = false

    /** Starts the helper over Wireless debugging (several seconds of network work), then redraws. */
    private fun startHelper() {
        starting = true
        render()
        thread {
            ShellHelper.start(applicationContext)
            runOnUiThread {
                starting = false
                if (!isDestroyed) render()
            }
        }
    }

    /** choiceRow: the current choice in grey before a chevron; tap opens the floating menu from it. */
    private fun setting(title: String, key: String, options: List<Pair<String, String>>) =
        choice(title, RecorderSettings.read(this)[key], options) { value ->
            RecorderSettings.write(this, key, value)
            render()
            RecordingsProvider.notifyStatus(this)
        }

    private fun choice(title: String, current: Any?, options: List<Pair<String, String>>, onPick: (String) -> Unit): View {
        val selected = options.indexOfFirst { it.first == current }.coerceAtLeast(0)
        var anchor: View? = null
        return page.row(title, value = options[selected].second, anchor = { anchor = it }) {
            FloatingMenu(this, anchor!!, options.map { it.second }, selected) { i -> onPick(options[i].first) }.show()
        }
    }
}
