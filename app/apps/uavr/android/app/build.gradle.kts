import java.util.Properties

// Release signing: hackathon/android-key.properties at the repo root (git-ignored; android/key.properties
// also works) points at the upload keystore kept outside the repo.
val keyProps = Properties().apply {
    val f = listOf("../../../../hackathon/android-key.properties", "key.properties")
        .map { rootProject.file(it) }
        .firstOrNull { it.exists() }
    f?.inputStream()?.use { load(it) }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "tw.reporting.uavr"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "tw.reporting.app"
        minSdk = 24 // uavr_native (Remote ID scanning) needs API 24+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // One codebase, separate apps: never ship each other's screens (see lib/main_*.dart).
    flavorDimensions += "build"
    productFlavors {
        create("informant") {
            dimension = "build"
            applicationId = "tw.reporting.app"
        }
        create("field") {
            dimension = "build"
            applicationId = "tw.reporting.field"
        }
    }

    signingConfigs {
        if (keyProps.isNotEmpty()) {
            create("release") {
                storeFile = file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Upload key from key.properties; Play App Signing re-signs the informant app, MDM distributes field.
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
