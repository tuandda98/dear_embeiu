import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

val hasReleaseSigning = keystoreProperties.getProperty("storeFile")?.let {
    rootProject.file(it).exists()
} ?: false

android {
    namespace = "com.tony.dearembeiu"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tony.dearembeiu"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        // 36 (Android 16) — Google Play target-API policy deadline 2026-08-31
        // ("không thể cập nhật ứng dụng" past that date if still 35). Ships with
        // the first release AFTER 1.4.2+17 (which is in review targeting 35 —
        // still compliant until the deadline). compileSdk is already 36; the app
        // has no windowOptOutEdgeToEdgeEnforcement (removed at target 36).
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Default app label; overridden per build type below (Dev gets " Dev").
        manifestPlaceholders["appName"] = "Dear Embeiu"
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Side-by-side dev install: every non-release build (debug, profile) gets a
    // `.dev` applicationId + "Dev" label so a `flutter run` build sits ALONGSIDE
    // the Play Store app on a real device instead of overwriting it. Release
    // keeps the production id (store builds unaffected). configureEach also
    // covers the Flutter-created `profile` build type regardless of order.
    // Pairs with src/{debug,profile}/google-services.json being registered for
    // `com.tony.dearembeiu.dev` in the DEV Firebase project.
    buildTypes.configureEach {
        if (name == "release") {
            manifestPlaceholders["appName"] = "Dear Embeiu"
        } else {
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            manifestPlaceholders["appName"] = "Dear Embeiu Dev"
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
