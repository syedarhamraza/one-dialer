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
        page = Subpage(this, getString(R.string.app_name), onBack = null)
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

    /** One setup step: done once [ok]; [fix] is what tapping it (or the hero's Continue) does. */
    private class Step(val title: String, val detail: String, val ok: Boolean, val done: String, val fix: (() -> Unit)?)

    private fun render() {
        val scroll = page.scroll.scrollY
        page.content.removeAllViews()
        val pal = OneLook.palette(this)

        val notificationsOn = getSystemService(NotificationManager::class.java).areNotificationsEnabled()
        // vivo and other OEM battery managers stop idle apps, which ends the recording or the helper's restart.
        val unrestricted = getSystemService(android.os.PowerManager::class.java).isIgnoringBatteryOptimizations(packageName)
        val notificationsStep = Step(getString(R.string.setup_notifications), getString(R.string.setup_notifications_detail),
            notificationsOn, getString(R.string.setup_done)) {
            if (Build.VERSION.SDK_INT >= 33) requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 2)
            else startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
        }
        val batteryStep = Step(getString(R.string.setup_battery), getString(R.string.setup_battery_detail),
            unrestricted, getString(R.string.setup_done)) {
            startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName")))
        }

        if (!ShellHelper.supported()) {
            page.hero(getString(R.string.status_unsupported), OneLook.RED, getString(R.string.both_sides_unsupported), null)
        } else {
            val paired = ShellHelper.paired(this)
            val steps = listOf(
                Step(getString(R.string.setup_dev_options), getString(R.string.setup_dev_options_detail),
                    ShellHelper.developerOptionsOn(this), getString(R.string.setup_done)) {
                    startActivity(Intent(Settings.ACTION_DEVICE_INFO_SETTINGS))
                },
                Step(getString(R.string.setup_pair), getString(R.string.setup_pair_detail), paired, getString(R.string.setup_paired)) {
                    ShellHelper.askForPairingCode(this)
                    startActivity(ShellHelper.wirelessDebuggingIntent())
                },
                Step(getString(R.string.setup_helper),
                    getString(if (starting) R.string.setup_helper_starting else R.string.setup_helper_detail),
                    ShellHelper.running(this), getString(R.string.setup_done),
                    if (starting) null else ({ startHelper() })),
                notificationsStep,
                batteryStep,
            )
            val next = steps.indexOfFirst { !it.ok }
            if (next < 0) {
                val dialer = packageManager.getLaunchIntentForPackage(TrustedDialer.PACKAGE)
                page.hero(getString(R.string.status_ready), OneLook.CALL_GREEN, getString(R.string.status_ready_detail),
                    dialer?.let { getString(R.string.open_dialer) to { startActivity(it) } })
            } else {
                page.hero(getString(R.string.status_step, next + 1, steps.size, steps[next].title), pal.text,
                    getString(R.string.both_sides_intro), steps[next].fix?.let { getString(R.string.status_continue) to it })
            }
            page.group(steps.mapIndexed { i, step ->
                when {
                    step.ok -> page.row(step.title, step.done, leading = Glyph.check(OneLook.CALL_GREEN))
                    i == next -> page.row(step.title, step.detail, OneLook.RED,
                        if (step.fix != null) getString(R.string.fix) else null,
                        leading = Glyph.step(i + 1, pal.text), onTap = step.fix)
                    else -> page.row(step.title, getString(R.string.step_after, i), leading = Glyph.step(i + 1, pal.text2))
                }
            } + (if (paired) listOf(page.row(
                getString(R.string.setup_restart),
                getString(if (ShellHelper.canRestart(this)) R.string.setup_restart_ready else R.string.setup_restart_detail),
            )) else emptyList()), header = getString(R.string.section_setup))
        }

        if (!ShellHelper.supported()) page.group(listOf(notificationsStep, batteryStep).map {
            if (it.ok) page.row(it.title, it.done, leading = Glyph.check(OneLook.CALL_GREEN))
            else page.row(it.title, it.detail, OneLook.RED, getString(R.string.fix), onTap = it.fix)
        }, header = getString(R.string.section_permissions))

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
