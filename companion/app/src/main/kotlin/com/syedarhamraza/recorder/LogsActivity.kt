package com.syedarhamraza.recorder

import android.app.Activity
import android.graphics.Typeface
import android.os.Bundle
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.widget.TextView
import android.widget.Toast
import kotlin.concurrent.thread

/**
 * Setup › Logs and report: what One Recorder and its helper logged on this phone, and three ways
 * to send it (email, share sheet, a GitHub issue). Nothing leaves the phone otherwise.
 */
class LogsActivity : Activity() {
    private lateinit var page: Subpage
    private val pal get() = OneLook.palette(this)

    override fun attachBaseContext(base: android.content.Context) = super.attachBaseContext(OneLook.themed(base))

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        page = Subpage(this, getString(R.string.logs_title)) { finish() }
        load()
    }

    private fun load() = thread {
        val report = Diagnostics.report(applicationContext)
        val summary = Diagnostics.summary(applicationContext)
        runOnUiThread { if (!isDestroyed) render(report, summary) }
    }

    private fun render(report: String, summary: String) {
        page.content.removeAllViews()
        page.content.addView(TextView(this).apply {
            text = getString(R.string.logs_intro)
            OneLook.style(this, 15f, pal.text2, 400, 0f, 1.3f)
            val p = OneLook.px(this@LogsActivity, 18f).toInt()
            setPadding(p, 0, p, OneLook.px(this@LogsActivity, 16f).toInt())
        })
        val subject = getString(R.string.logs_subject)
        page.group(listOf(
            page.row(getString(R.string.logs_email), getString(R.string.logs_email_detail)) {
                Diagnostics.email(this, report, summary, subject)
            },
            page.row(getString(R.string.logs_share), getString(R.string.logs_share_detail)) {
                Diagnostics.share(this, report, subject)
            },
            page.row(getString(R.string.logs_github), getString(R.string.logs_github_detail)) {
                Diagnostics.github(this, report, summary, subject, getString(R.string.logs_paste_here))
                Toast.makeText(this, R.string.logs_copied, Toast.LENGTH_LONG).show()
            },
        ), header = getString(R.string.logs_send))

        page.group(listOf(TextView(this).apply {
            text = recent(report)
            OneLook.style(this, 12f, pal.text, 400, 0f, 1.35f)
            typeface = Typeface.MONOSPACE
            setTextIsSelectable(true)
            val p = OneLook.px(this@LogsActivity, 16f).toInt()
            setPadding(p, p, p, p)
        }), header = getString(R.string.logs_recent))

        page.group(listOf(page.row(getString(R.string.logs_clear)) {
            RecLog.clear(this)
            load()
        }))
    }

    private val PROBLEM = Regex("crash|fail|refused|error|didn't|not recording|not initialized|no tries", RegexOption.IGNORE_CASE)

    /** The newest 300 lines first, problems in red; the report keeps all of them in order. */
    private fun recent(report: String): CharSequence {
        val lines = report.substringAfter("One Recorder log:\n").lines()
            .filter { it.isNotBlank() && it[0].isDigit() }
            .sortedDescending() // both logs start with the same timestamp format
            .take(300)
        if (lines.isEmpty()) return getString(R.string.logs_empty)
        val out = SpannableStringBuilder()
        for (line in lines) {
            val start = out.length
            out.append(line).append('\n')
            if (PROBLEM.containsMatchIn(line)) {
                out.setSpan(ForegroundColorSpan(OneLook.RED), start, out.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
        }
        return out.trimEnd()
    }
}
