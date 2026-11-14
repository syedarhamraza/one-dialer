pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        // libadb-android and its SPAKE2 and certificate helpers are published there only.
        maven("https://jitpack.io") { content { includeGroupByRegex("com\\.github\\.MuntashirAkon.*") } }
    }
}

rootProject.name = "onedialer-recorder"
include(":app")
