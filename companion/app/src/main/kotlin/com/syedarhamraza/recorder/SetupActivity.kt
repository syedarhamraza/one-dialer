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

        val helperUp = ShellHelper.supported() && ShellHelper.running(this)
        if (!ShellHelper.supported()) {
            page.group(listOf(page.row(getString(R.string.section_both_sides), getString(R.string.both_sides_unsupported), OneLook.RED)))
        } else {
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
            need(
                getString(R.string.setup_notifications), getString(R.string.setup_notifications_detail),
                getSystemService(NotificationManager::class.java).areNotificationsEnabled(),
            ) {
                if (Build.VERSION.SDK_INT >= 33) requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 2)
                else startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
            },
            // vivo and other OEM battery managers stop idle apps, which ends the recording or the helper's restart.
            need(
                getString(R.string.setup_battery), getString(R.string.setup_battery_detail),
                getSystemService(android.os.PowerManager::class.java).isIgnoringBatteryOptimizations(packageName),
            ) {
                startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName")))
            },
        ), header = getString(R.string.section_permissions))

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

    private fun choice(title: String, current: Any?, options: List<Pair<String, String>>, onPick: (String) -> Unit): View {
        val selected = options.indexOfFirst { it.first == current }.coerceAtLeast(0)
        var anchor: View? = null
        return page.row(title, value = options[selected].second, anchor = { anchor = it }) {
            FloatingMenu(this, anchor!!, options.map { it.second }, selected) { i -> onPick(options[i].first) }.show()
        }
    }
}
