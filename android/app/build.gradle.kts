import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun keystoreValue(key: String): String? =
    keystoreProperties.getProperty(key)?.takeIf { it.isNotBlank() }

val hasReleaseKeystore =
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all {
        keystoreValue(it) != null
    }

android {
    namespace = "com.ivra.refill"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.ivra.refill"
        // Android 7.0 (Nougat) is the floor we support. Below this, the
        // Supabase TLS stack and several Flutter plugins (notably share_plus
        // and printing) are not validated.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                storeFile = rootProject.file(keystoreValue("storeFile")!!)
                storePassword = keystoreValue("storePassword")
                keyAlias = keystoreValue("keyAlias")
                keyPassword = keystoreValue("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                gradle.taskGraph.whenReady {
                    if (allTasks.any { it.name.contains("Release", ignoreCase = true) }) {
                        logger.warn(
                            "WARNING: android/key.properties is missing or " +
                                "incomplete. Falling back to debug signing " +
                                "for the release build type. The resulting " +
                                "APK is debuggable, signed with the Android " +
                                "debug key, and will be rejected by the Play " +
                                "Store. Run scripts/setup_android_signing.ps1 " +
                                "to provision a real release keystore."
                        )
                    }
                }
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
