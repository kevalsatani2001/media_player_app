import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Android Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÅ¸Ã Âªâ€¦Ã ÂªÂª: 'app_icon' Ã ÂªÂ¤Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â‚¬ res/drawable Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂµÃ Â«â€¹ Ã ÂªÅ“Ã Â«â€¹Ã ÂªË†Ã ÂªÂ
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÅ¸Ã Âªâ€¦Ã ÂªÂª
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  static Future<void> showNoInternetNotification({
    required String title,
    required String bodyTitle,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'network_error_channel', // Channel ID
      'Network Alerts', // Channel Name
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      body: bodyTitle, // Body
      notificationDetails: platformDetails,
      id: 0,
      title: title, // Title
    );
  }

  static Future<void> showVideoBackgroundNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'video_bg_playback_channel',
      'Video Background Playback',
      channelDescription: 'Shows notification while video plays in background',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      onlyAlertOnce: true,
      showWhen: false,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: false, presentSound: false),
    );

    await _notificationsPlugin.show(
      id: 9011,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  static Future<void> cancelVideoBackgroundNotification() async {
    await _notificationsPlugin.cancel(id: 9011);
  }

  // notification_service.dart Ã ÂªÂ¨Ã Â«â‚¬ Ã Âªâ€¦Ã Âªâ€šÃ ÂªÂ¦Ã ÂªÂ° Ã Âªâ€°Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ°Ã Â«â€¹
  static Future<void> requestPermissions() async {
    // Android 13+ Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    // iOS Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
    >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
}

/*

 */

/*
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
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.kkmedia.media_player"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            //
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
 */

/*
flutter_local_notifications
 */