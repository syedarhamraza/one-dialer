import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Crashlytics: needs android/app/google-services.json from the Firebase console. Without it the
// app builds and runs with crash reporting off (Firebase.initializeApp fails and is skipped).
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
    apply(plugin = "com.google.firebase.firebase-perf") // beta-only: docs/beta-only.md
}

// Release signing: android/key.properties (never committed) points at the upload keystore.
// Without it, release builds fall back to the debug key, which Google Play rejects.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.syedarhamraza.dialer"
    // permission_handler_android requires compiling against API 37.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Play listing id; differs from the Kotlin namespace, which stays com.syedarhamraza.dialer.
        applicationId = "com.syedarhamraza.onedialer"
        // 29 = Android 10: RoleManager.ROLE_DIALER and the modern Telecom APIs.
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystoreProperties.containsKey("storeFile")) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            // Ships native symbol tables in the .aab so Play can symbolize native crashes.
            ndk { debugSymbolLevel = "SYMBOL_TABLE" }
            // Added to Flutter's own R8 rules (see the file for why).
            proguardFiles("proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // WindowCompat.enableEdgeToEdge (1.17+); the plugins already pull in this version.
    implementation("androidx.core:core:1.18.0")
    // Formats caller numbers and names a foreign caller's country on the call screen.
    implementation("com.googlecode.libphonenumber:libphonenumber:8.13.50")
    testImplementation("junit:junit:4.13.2")
}
