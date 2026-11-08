package com.syedarhamraza.recorder

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/** The companion's only screen: what recording needs, each with a Fix button. Recordings live in One Dialer. */
class SetupActivity : Activity() {
    private lateinit var rows: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.BLACK
        rows = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(dp(20), dp(48), dp(20), dp(24)) }
        setContentView(ScrollView(this).apply { setBackgroundColor(Color.BLACK); addView(rows) })
    }

    override fun onResume() {
        super.onResume()
        render()
        RecordingsProvider.notifyStatus(this)
    }

    private fun render() {
        rows.removeAllViews()
        rows.addView(text(getString(R.string.app_name), 30f, Color.WHITE))
        rows.addView(text(getString(R.string.setup_intro), 15f, GREY).apply { setPadding(0, dp(8), 0, dp(24)) })

        row(
            getString(R.string.setup_mic), getString(R.string.setup_mic_detail), RecordingService.micGranted(this),
        ) { requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 1) }
        row(
            getString(R.string.setup_accessibility), getString(R.string.setup_accessibility_detail), RecordingService.accessibilityOn(this),
        ) { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)) }
        if (Build.VERSION.SDK_INT >= 33) {
            rows.addView(text(getString(R.string.setup_restricted), 13f, GREY).apply { setPadding(dp(16), 0, dp(16), dp(16)) })
            rows.addView(Button(this).apply {
                text = getString(R.string.setup_open_app_info)
                setOnClickListener {
                    startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null)))
                }
            })
        }
        row(
            getString(R.string.setup_notifications), getString(R.string.setup_notifications_detail),
            getSystemService(NotificationManager::class.java).areNotificationsEnabled(),
        ) {
            if (Build.VERSION.SDK_INT >= 33) requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 2)
            else startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
        }
        choice(getString(R.string.setting_source), "sourceMode", listOf(
            "auto" to getString(R.string.source_auto),
            "recognition" to getString(R.string.source_recognition),
            "communication" to getString(R.string.source_communication),
            "mic" to getString(R.string.source_mic),
        ))
        choice(getString(R.string.setting_boost), "boost", listOf(
            "off" to getString(R.string.boost_off),
            "normal" to getString(R.string.boost_normal),
            "strong" to getString(R.string.boost_strong),
        ))
        rows.addView(text(getString(R.string.setup_consent), 13f, GREY).apply { setPadding(0, dp(24), 0, 0) })
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        render()
        RecordingsProvider.notifyStatus(this)
    }

    /** A setting row; tapping it lists the options (also changeable from One Dialer's Settings). */
    private fun choice(title: String, key: String, options: List<Pair<String, String>>) {
        val current = RecorderSettings.read(this)[key]
        val selected = options.indexOfFirst { it.first == current }.coerceAtLeast(0)
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(14), dp(16), dp(14))
            background = GradientDrawable().apply { setColor(CARD); cornerRadius = dp(20).toFloat() }
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { bottomMargin = dp(12) }
            addView(text(title, 17f, Color.WHITE))
            addView(text(options[selected].second, 13f, GREY))
            setOnClickListener {
                android.app.AlertDialog.Builder(this@SetupActivity)
                    .setTitle(title)
                    .setSingleChoiceItems(options.map { it.second }.toTypedArray(), selected) { dialog, which ->
                        RecorderSettings.write(this@SetupActivity, key, options[which].first)
                        dialog.dismiss()
                        render()
                    }
                    .show()
            }
        }
        rows.addView(card)
    }

    private fun row(title: String, detail: String, ok: Boolean, fix: () -> Unit) {
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(16), dp(14), dp(12), dp(14))
            background = GradientDrawable().apply { setColor(CARD); cornerRadius = dp(20).toFloat() }
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { bottomMargin = dp(12) }
        }
        val texts = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        texts.addView(text(title, 17f, Color.WHITE))
        texts.addView(text(if (ok) getString(R.string.setup_done) else detail, 13f, if (ok) GREEN else GREY))
        card.addView(texts, LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f))
        if (!ok) card.addView(Button(this).apply { text = getString(R.string.fix); setOnClickListener { fix() } })
        rows.addView(card)
    }

    private fun text(value: String, size: Float, color: Int) = TextView(this).apply {
        text = value
        setTextSize(TypedValue.COMPLEX_UNIT_SP, size)
        setTextColor(color)
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    private companion object {
        val GREY = Color.rgb(0x9A, 0x9A, 0x9F)
        val CARD = Color.rgb(0x1C, 0x1C, 0x1E)
        val GREEN = Color.rgb(0x34, 0xC7, 0x59)
    }
}
