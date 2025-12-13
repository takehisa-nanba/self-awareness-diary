// android/app/build.gradle.kts (最終クリーンアップ版)

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.self_awareness_diary"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.example.self_awareness_diary"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
    // NDK、externalNativeBuild、packaging のブロックはすべて削除されていることを確認
    // ...

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    compileOptions {
        // Javaのソース/ターゲットバージョンをJava 21に設定
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        // KotlinのターゲットJVMバージョンをJava 21に設定
        jvmTarget = "21"
    }
}

flutter {
    source = "../.."
}