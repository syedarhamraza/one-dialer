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
    implementation("androidx.core:core:1.19.1")
    testImplementation("junit:junit:4.13.2")
}
