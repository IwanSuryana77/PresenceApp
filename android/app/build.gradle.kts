plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    // ⚠️ HARUS SAMA DENGAN FIREBASE
    namespace = "com.example.presenceapp"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
    
        jvmTarget = "11"
    }

    defaultConfig {
        // ⚠️ HARUS SAMA DENGAN FIREBASE
        applicationId = "com.example.presenceapp"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BOM
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))

    // 🔥 FIREBASE YANG KAMU PAKAI
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-analytics")

    // ☁️ CLOUDINARY
    implementation("com.cloudinary:cloudinary-android:2.3.1")
}
