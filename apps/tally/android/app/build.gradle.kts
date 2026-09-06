import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key, read from android/key.properties (gitignored, keystore lives
// outside the repo). Absent on a machine that has never been given the key -
// release builds there fall back to the debug key and are not uploadable,
// which is the correct failure: a missing secret must not silently produce an
// artifact that looks shippable.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasUploadKey = keystorePropertiesFile.exists()
if (hasUploadKey) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.rastovic.lockin"
    // Pinned rather than following flutter.compileSdkVersion: file_picker
    // pulls in flutter_plugin_android_lifecycle, which requires API 36 to
    // compile against. Compiling against a newer SDK does not change which
    // devices the app runs on - minSdk governs that - so nobody is dropped.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications needs this: it uses java.time, which
        // does not exist on the older Android versions this app still
        // supports. Desugaring backports it rather than raising minSdk and
        // dropping those phones - which are exactly the cheap phones this
        // audience owns.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Locked at the first Play upload: the (applicationId, signing key)
        // pair *is* the app on Play and neither half can be changed after.
        // `tally` was the working name; the app ships as lockIn.
        applicationId = "com.rastovic.lockin"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
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
            signingConfig = if (hasUploadKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
