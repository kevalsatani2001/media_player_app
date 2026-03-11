plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kkmedia.media_player"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    bundle {
        language {
            enableSplit = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.kkmedia.media_player"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            // ðŸ‘‡ Proguard enable
            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.gms:play-services-ads:23.0.0")
}


/*
#android/app/proguard-rules.pro
#flutter build apk --release --obfuscate --split-debug-info=debug-info


## Flutter
#-keep class io.flutter.** { *; }
#
## AdMob
#-keep class com.google.android.gms.ads.** { *; }
#-dontwarn com.google.android.gms.ads.**
#
## ExoPlayer
#-keep class com.google.android.exoplayer2.** { *; }
#
## Play Core
#-keep class com.google.android.play.core.** { *; }
#-dontwarn com.google.android.play.core.**
#
## Annotations
#-keepattributes *Annotation*


# ---------------- Flutter ----------------
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ---------------- AdMob ----------------
-keep public class com.google.android.gms.ads.** { *; }
-keep public class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# ---------------- ExoPlayer / Media ----------------
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# ---------------- Google Play Core ----------------
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ---------------- Firebase (future safe) ----------------
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ---------------- Annotations ----------------
-keepattributes *Annotation*

# ---------------- Gson / JSON ----------------
-keepattributes Signature
-keepattributes *Annotation*



 */

/*
Total Cost: â‚¹25,000 | Total Duration: 45 DaysModuleScope of WorkTimelineCost (INR)Module 1: UI/UXMaterial 3 Design, 3-Tab Bottom Nav, Basic Theme Management.8 Daysâ‚¹4,000Module 2: Media EngineLocal file scanning (MP3/MP4), thumbnails, Scoped Storage permissions.10 Daysâ‚¹5,000Module 3: Player SystemVideo Player + Audio Player with Background Service (Notification play).12 Daysâ‚¹7,000Module 4: Data & SearchSimple Favorites (Hive/SharedPref) and Unified Media Search.7 Daysâ‚¹4,500Module 5: Ads & SecurityAdMob (Banner/Interstitial), ProGuard/R8 Rules, and Final APK.8 Daysâ‚¹4,500TotalComplete Professional Lite Media Player45 Daysâ‚¹25,000*/