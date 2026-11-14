import java.util.Properties

plugins {
    id("com.android.application")
}

// Same upload key as One Dialer (android/key.properties, never committed); debug key without it.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("../android/key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.syedarhamraza.recorder"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.syedarhamraza.onedialer.recorder"
        minSdk = 29
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
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
        release {
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
