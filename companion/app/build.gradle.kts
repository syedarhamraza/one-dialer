import java.util.Properties

plugins {
    id("com.android.application")
}

// Same upload key as One Dialer (android/key.properties, never committed); debug key without it.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("../android/key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

// One Recorder ships with each One Dialer release (tool/release.ps1 builds it after the version
// bump), so it carries that version: pubspec.yaml's code, and its name plus the commit, which
// tells apart test builds made between releases ("+" when built from uncommitted changes).
val dialerVersion = Regex("(?m)^version:\\s*([^+\\s]+)\\+(\\d+)\\s*$")
    .find(rootProject.file("../pubspec.yaml").readText())
    ?: error("pubspec.yaml has no version: NAME+CODE line")
val commit = providers.exec {
    commandLine("git", "rev-parse", "--short", "HEAD")
    isIgnoreExitValue = true
}.standardOutput.asText.map { it.trim().ifEmpty { "nogit" } }.getOrElse("nogit")
val dirty = providers.exec {
    commandLine("git", "status", "--porcelain", "--untracked-files=no")
    isIgnoreExitValue = true
}.standardOutput.asText.map { it.isNotBlank() }.getOrElse(false)
val build = commit + if (dirty) "+" else ""

android {
    namespace = "com.syedarhamraza.recorder"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.syedarhamraza.onedialer.recorder"
        minSdk = 29
        targetSdk = 36
        versionCode = dialerVersion.groupValues[2].toInt()
        versionName = dialerVersion.groupValues[1]
        // Phones only: the ADB libraries' x86 builds (emulators) would add about 5 MB.
        ndk { abiFilters += listOf("arm64-v8a", "armeabi-v7a") }
    }

    signingConfigs {
        if (keystoreProperties["storeFile"] != null) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        // 1.0.1-beta.1 (5b2133f); 1.0.1-beta.1-debug (5b2133f+) for a debug build of uncommitted changes.
        debug { versionNameSuffix = "-debug ($build)" }
        release {
            versionNameSuffix = " ($build)"
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures { buildConfig = true }
}

dependencies {
    implementation("androidx.core:core:1.18.0")
    // Both sides: pairs with Wireless debugging and starts the shell helper (shell/Adb.kt).
    implementation("com.github.MuntashirAkon:libadb-android:3.1.1")
    implementation("com.github.MuntashirAkon:sun-security-android:1.1") // the pairing certificate
    implementation("org.conscrypt:conscrypt-android:2.5.3") // TLS 1.3 key export for pairing
    testImplementation("junit:junit:4.13.2")
}
