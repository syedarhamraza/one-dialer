package com.syedarhamraza.recorder

import android.app.Activity
import android.os.Bundle
import android.view.View
import android.widget.LinearLayout

/**
 * "Before you record": recording is the user's own choice and responsibility under their local
 * law. Shown on the first launch until agreed to (Back or Not now closes the app), and again
 * from setup's "Recording and the law" row.
 */
class ConsentActivity : Activity() {
    private val firstRun get() = intent.getBooleanExtra(FIRST_RUN, false) && !RecorderSettings.consentAccepted(this)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val page = Subpage(this, getString(R.string.consent_title)) { leave() }
        page.content.addView(android.widget.TextView(this).apply {
            text = getString(R.string.consent_intro)
            OneLook.style(this, 15f, OneLook.TEXT2, 400, 0f, 1.3f)
            val p = OneLook.px(this@ConsentActivity, 18f).toInt()
            setPadding(p, 0, p, OneLook.px(this@ConsentActivity, 16f).toInt())
        })
        page.group(listOf(
            page.row(getString(R.string.consent_choice_title), getString(R.string.consent_choice)),
            page.row(getString(R.string.consent_law_title), getString(R.string.consent_law)),
            page.row(getString(R.string.consent_tell_title), getString(R.string.consent_tell)),
            page.row(getString(R.string.consent_private_title), getString(R.string.consent_private)),
        ))
        page.content.addView(page.glowButton(getString(R.string.consent_accept), lit = true) {
            RecorderSettings.acceptConsent(this)
            RecordingsProvider.notifyStatus(this)
            finish()
        })
        if (firstRun) {
            page.content.addView(View(this), LinearLayout.LayoutParams(1, OneLook.px(this, 12f).toInt()))
            page.content.addView(page.glowButton(getString(R.string.consent_later), lit = false) { leave() })
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() = leave()

    /** Not agreed yet: nothing to set up, so the app closes. */
    private fun leave() = if (firstRun) finishAffinity() else finish()

    companion object {
        const val FIRST_RUN = "firstRun"
    }
}
