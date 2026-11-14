package com.syedarhamraza.recorder.shell

import android.content.Context
import android.os.Build
import io.github.muntashirakon.adb.AbsAdbConnectionManager
import io.github.muntashirakon.adb.android.AdbMdns
import android.sun.security.x509.AlgorithmId
import android.sun.security.x509.CertificateAlgorithmId
import android.sun.security.x509.CertificateExtensions
import android.sun.security.x509.CertificateIssuerName
import android.sun.security.x509.CertificateSerialNumber
import android.sun.security.x509.CertificateSubjectName
import android.sun.security.x509.CertificateValidity
import android.sun.security.x509.CertificateVersion
import android.sun.security.x509.CertificateX509Key
import android.sun.security.x509.KeyIdentifier
import android.sun.security.x509.SubjectKeyIdentifierExtension
import android.sun.security.x509.X500Name
import android.sun.security.x509.X509CertImpl
import android.sun.security.x509.X509CertInfo
import java.io.File
import java.net.InetAddress
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.PrivateKey
import java.security.SecureRandom
import java.security.cert.Certificate
import java.security.cert.CertificateFactory
import java.security.spec.PKCS8EncodedKeySpec
import java.util.Date
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * One Recorder's own ADB client, over the phone's Wireless debugging (libadb-android). Its key
 * pair lives in the app's private files; once paired, it connects without asking again. Every
 * method blocks: call them off the main thread.
 */
class Adb private constructor(private val files: File) : AbsAdbConnectionManager() {
    companion object {
        private const val DAY_MS = 86_400_000L

        @Volatile private var instance: Adb? = null

        fun get(context: Context): Adb = instance ?: synchronized(this) {
            instance ?: Adb(File(context.filesDir, "adb").apply { mkdirs() }).also { instance = it }
        }

        /** The port Settings › Wireless debugging › Pair device with pairing code is offering, while that dialog shows. */
        fun findPairingService(context: Context, timeoutMs: Long): Pair<InetAddress, Int>? {
            val found = AtomicReference<Pair<InetAddress, Int>?>()
            val latch = CountDownLatch(1)
            val mdns = AdbMdns(context, AdbMdns.SERVICE_TYPE_TLS_PAIRING) { host, port ->
                if (host != null && port > 0) {
                    found.set(host to port)
                    latch.countDown()
                }
            }
            mdns.start()
            try {
                latch.await(timeoutMs, TimeUnit.MILLISECONDS)
            } finally {
                mdns.stop()
            }
            return found.get()
        }
    }

    private val keyFile = File(files, "key")
    private val certFile = File(files, "cert")
    private val privateKey: PrivateKey
    private val certificate: Certificate

    init {
        setApi(Build.VERSION.SDK_INT)
        setTimeout(10, TimeUnit.SECONDS)
        val saved = runCatching {
            KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(keyFile.readBytes())) to
                certFile.inputStream().use { CertificateFactory.getInstance("X.509").generateCertificate(it) }
        }.getOrNull()
        if (saved != null) {
            privateKey = saved.first
            certificate = saved.second
        } else {
            val pair = KeyPairGenerator.getInstance("RSA").apply { initialize(2048, SecureRandom()) }.generateKeyPair()
            privateKey = pair.private
            certificate = selfSigned(pair)
            keyFile.writeBytes(privateKey.encoded)
            certFile.writeBytes(certificate.encoded)
        }
    }

    override fun getPrivateKey() = privateKey
    override fun getCertificate() = certificate
    override fun getDeviceName() = "One Recorder"

    /** Pairs with the code shown in Wireless debugging's pairing dialog. */
    fun pairWith(host: InetAddress, port: Int, code: String): Boolean = try {
        pair(host.hostAddress!!, port, code)
    } catch (_: Exception) {
        false
    }

    /** Connects to Wireless debugging (found over mDNS), or false when it's off or this app isn't paired. */
    fun connectNow(context: Context, timeoutMs: Long): Boolean = try {
        isConnected || autoConnect(context, timeoutMs)
    } catch (_: Exception) {
        false
    }

    /** Runs a shell command and returns what it printed. */
    fun shell(command: String): String? = try {
        openStream("shell:$command").use { stream ->
            stream.openInputStream().use { it.readBytes().toString(Charsets.UTF_8) }
        }
    } catch (_: Exception) {
        null
    }

    fun disconnectQuietly() = runCatching { disconnect() }

    private fun selfSigned(pair: java.security.KeyPair): Certificate {
        val algorithm = "SHA512withRSA"
        val name = X500Name("CN=One Recorder")
        val from = Date()
        val until = Date(from.time + 30 * 365 * DAY_MS)
        val info = X509CertInfo().apply {
            set("version", CertificateVersion(2))
            set("serialNumber", CertificateSerialNumber(SecureRandom().nextInt() and Int.MAX_VALUE))
            set("algorithmID", CertificateAlgorithmId(AlgorithmId.get(algorithm)))
            set("subject", CertificateSubjectName(name))
            set("key", CertificateX509Key(pair.public))
            set("validity", CertificateValidity(from, until))
            set("issuer", CertificateIssuerName(name))
            set("extensions", CertificateExtensions().apply {
                set("SubjectKeyIdentifier", SubjectKeyIdentifierExtension(KeyIdentifier(pair.public).identifier))
            })
        }
        return X509CertImpl(info).apply { sign(pair.private, algorithm) }
    }
}
