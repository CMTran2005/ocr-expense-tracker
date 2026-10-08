pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val localProperties = file("local.properties")
            if (localProperties.exists()) {
                localProperties.inputStream().use { properties.load(it) }
                properties.getProperty("flutter.sdk")?.takeIf { it.isNotBlank() }
            } else null
        } ?: System.getenv("FLUTTER_ROOT") ?: System.getenv("FLUTTER_HOME") ?: System.getenv("FLUTTER_SDK")
        ?: error("flutter.sdk not set in local.properties and FLUTTER_ROOT not set")

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
