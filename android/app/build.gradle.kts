plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.udep.panelasys"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    // Configure flavor dimensions for cooperative variants
    flavorDimensions += "cooperative"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = "panela"
            keyPassword = System.getenv("KEY_PASSWORD") ?: ""
            storeFile = file("panela_key.jks")
            storePassword = System.getenv("STORE_PASSWORD") ?: ""
        }
    }

    defaultConfig {
        applicationId = "com.udep.panelasys"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Product flavors for different cooperatives
    productFlavors {
        create("norandino") {
            dimension = "cooperative"
            applicationIdSuffix = ".norandino"
            resValue("string", "app_name", "NORANDINO - Captura UDEP")
        }

        create("caes") {
            dimension = "cooperative"
            applicationIdSuffix = ".caes"
            resValue("string", "app_name", "CAES - Captura UDEP")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
