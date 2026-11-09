package com.syedarhamraza.recorder

import android.content.Context
import android.content.pm.PackageManager

/**
 * Only One Dialer may start, stop or read recordings. Play re-signs One Dialer with Google's
 * key, so a signature permission can't tie the two apps together: we pin its certificates.
 * A release companion trusts only the Play build; debug companions also trust local builds.
 */
object TrustedDialer {
    const val PACKAGE = "com.syedarhamraza.onedialer"

    /** SHA-256 of One Dialer's signing certificates (hex, no colons). Play app-signing key: Play installs. */
    const val PLAY_CERT = "f2eb6384aa959b7c24455f1c5708e26ddb297e70f174de2505b219b65f5803de"
    private val DEV_CERTS = listOf(
        // Upload key (sideloaded release builds).
        "bed3b0971aa8f61eef04a76331d19c05fb3da960415cefc414dfa0cb0d291261",
        // Android debug key (this PC's debug and profile builds).
        "b11c05d54364c5a210a3a5d809f4c3b19350817aefe8639a3bf515ee17a9a65b",
    )

    fun certs(debug: Boolean): List<String> = if (debug) listOf(PLAY_CERT) + DEV_CERTS else listOf(PLAY_CERT)

    val CERTS = certs(BuildConfig.DEBUG)

    fun isTrusted(packageName: String?, certs: List<String> = CERTS, hasCert: (ByteArray) -> Boolean): Boolean =
        packageName == PACKAGE && certs.any { hasCert(hex(it)) }

    fun isTrusted(context: Context, packageName: String?): Boolean = isTrusted(packageName) {
        try {
            context.packageManager.hasSigningCertificate(PACKAGE, it, PackageManager.CERT_INPUT_SHA256)
        } catch (_: Exception) {
            false
        }
    }

    internal fun hex(s: String): ByteArray = ByteArray(s.length / 2) { s.substring(it * 2, it * 2 + 2).toInt(16).toByte() }
}
