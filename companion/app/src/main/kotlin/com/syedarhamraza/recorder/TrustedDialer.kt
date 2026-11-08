package com.syedarhamraza.recorder

import android.content.Context
import android.content.pm.PackageManager

/**
 * Only One Dialer may start, stop or read recordings. Play re-signs One Dialer with Google's
 * key, so a signature permission can't tie the two apps together: we pin its certificates.
 */
object TrustedDialer {
    const val PACKAGE = "com.syedarhamraza.onedialer"

    /** SHA-256 of One Dialer's signing certificates (hex, no colons). */
    val CERTS = listOf(
        // Upload key (website / sideloaded release builds).
        "bed3b0971aa8f61eef04a76331d19c05fb3da960415cefc414dfa0cb0d291261",
        // Android debug key (this PC's debug and profile builds).
        "b11c05d54364c5a210a3a5d809f4c3b19350817aefe8639a3bf515ee17a9a65b",
        // TODO before release: Play app-signing key, from Play Console › Test and release › App signing.
    )

    fun isTrusted(packageName: String?, hasCert: (ByteArray) -> Boolean): Boolean =
        packageName == PACKAGE && CERTS.any { hasCert(hex(it)) }

    fun isTrusted(context: Context, packageName: String?): Boolean = isTrusted(packageName) {
        try {
            context.packageManager.hasSigningCertificate(PACKAGE, it, PackageManager.CERT_INPUT_SHA256)
        } catch (_: Exception) {
            false
        }
    }

    internal fun hex(s: String): ByteArray = ByteArray(s.length / 2) { s.substring(it * 2, it * 2 + 2).toInt(16).toByte() }
}
