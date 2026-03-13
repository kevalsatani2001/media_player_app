import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Android àª¸à«‡àªŸàª…àªª: 'app_icon' àª¤àª®àª¾àª°à«€ res/drawable àª®àª¾àª‚ àª¹à«‹àªµà«‹ àªœà«‹àªˆàª
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS àª¸à«‡àªŸàª…àªª
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  static Future<void> showNoInternetNotification({required String title, required String bodyTitle}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'network_error_channel', // Channel ID
      'Network Alerts',        // Channel Name
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
        notificationDetails: platformDetails, id: 0,title: title // Title
    );
  }

// notification_service.dart àª¨à«€ àª…àª‚àª¦àª° àª‰àª®à«‡àª°à«‹
  static Future<void> requestPermissions() async {
    // Android 13+ àª®àª¾àªŸà«‡
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }


    final Map<String, Map<String, String>> localizedStrings = {
      'en': {

      },
      'ar': {
        'noInternetTitle': 'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø¥Ù†ØªØ±Ù†Øª',
        'noInternetBody': 'ÙŠØ±Ø¬Ù‰ Ø§Ù„ØªØ­Ù‚Ù‚ Ù…Ù† Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ø´Ø¨ÙƒØ© Ø§Ù„Ø®Ø§ØµØ© Ø¨Ùƒ.'
      },
      'my': {
        'noInternetTitle': 'á€¡á€„á€ºá€á€¬á€”á€€á€ºá€á€»á€­á€á€ºá€†á€€á€ºá€™á€¾á€¯á€™á€›á€¾á€­á€•á€«',
        'noInternetBody': 'á€žá€„á€ºáá€€á€½á€”á€ºá€›á€€á€ºá€†á€€á€ºá€á€„á€ºá€™á€»á€¬á€¸á€€á€­á€¯ á€…á€…á€ºá€†á€±á€¸á€•á€«á‹'
      },
      'fil': {
        'noInternetTitle': 'Walang Koneksyon sa Internet',
        'noInternetBody': 'Pakisuri ang iyong mga setting ng network.'
      },
      'fr': {
        'noInternetTitle': 'Pas de connexion Internet',
        'noInternetBody': 'Veuillez vÃ©rifier vos paramÃ¨tres rÃ©seau.'
      },
      'de': {
        'noInternetTitle': 'Keine Internetverbindung',
        'noInternetBody': 'Bitte Ã¼berprÃ¼fen Sie Ihre Netzwerkeinstellungen.'
      },
      'gu': {
        'noInternetTitle': 'àª‡àª¨à«àªŸàª°àª¨à«‡àªŸ àª•àª¨à«‡àª•à«àª¶àª¨ àª¨àª¥à«€',
        'noInternetBody': 'àª®àª¹à«‡àª°àª¬àª¾àª¨à«€ àª•àª°à«€àª¨à«‡ àª¤àª®àª¾àª°àª¾ àª¨à«‡àªŸàªµàª°à«àª• àª¸à«‡àªŸàª¿àª‚àª—à«àª¸ àª¤àªªàª¾àª¸à«‹.'
      },
      'hi': {
        'noInternetTitle': 'à¤•à¥‹à¤ˆ à¤‡à¤‚à¤Ÿà¤°à¤¨à¥‡à¤Ÿ à¤•à¤¨à¥‡à¤•à¥à¤¶à¤¨ à¤¨à¤¹à¥€à¤‚',
        'noInternetBody': 'à¤•à¥ƒà¤ªà¤¯à¤¾ à¤…à¤ªà¤¨à¥€ à¤¨à¥‡à¤Ÿà¤µà¤°à¥à¤• à¤¸à¥‡à¤Ÿà¤¿à¤‚à¤—à¥à¤¸ à¤œà¤¾à¤‚à¤šà¥‡à¤‚à¥¤'
      },
      'id': {
        'noInternetTitle': 'Tidak Ada Koneksi Internet',
        'noInternetBody': 'Silakan periksa pengaturan jaringan Anda.'
      },
      'it': {
        'noInternetTitle': 'Nessuna connessione Internet',
        'noInternetBody': 'Controlla le impostazioni di rete.'
      },
      'ja': {
        'noInternetTitle': 'ã‚¤ãƒ³ã‚¿ãƒ¼ãƒãƒƒãƒˆæŽ¥ç¶šãŒã‚ã‚Šã¾ã›ã‚“',
        'noInternetBody': 'ãƒãƒƒãƒˆãƒ¯ãƒ¼ã‚¯è¨­å®šã‚’ç¢ºèªã—ã¦ãã ã•ã„à¥¤'
      },
      'ko': {
        'noInternetTitle': 'ì¸í„°ë„· ì—°ê²° ì—†ìŒ',
        'noInternetBody': 'ë„¤íŠ¸ì›Œí¬ ì„¤ì •ì„ í™•ì¸í•´ ì£¼ì„¸ìš”.'
      },
      'ms': {
        'noInternetTitle': 'Tiada Sambungan Internet',
        'noInternetBody': 'Sila semak tetapan rangkaian anda.'
      },
      'mr': {
        'noInternetTitle': 'à¤‡à¤‚à¤Ÿà¤°à¤¨à¥‡à¤Ÿ à¤•à¤¨à¥‡à¤•à¥à¤¶à¤¨ à¤¨à¤¾à¤¹à¥€',
        'noInternetBody': 'à¤•à¥ƒà¤ªà¤¯à¤¾ à¤¤à¥à¤®à¤šà¥‡ à¤¨à¥‡à¤Ÿà¤µà¤°à¥à¤• à¤¸à¥‡à¤Ÿà¤¿à¤‚à¤—à¥à¤œ à¤¤à¤ªà¤¾à¤¸à¤¾.'
      },
      'fa': {
        'noInternetTitle': 'Ø§ØªØµØ§Ù„ Ø§ÛŒÙ†ØªØ±Ù†Øª Ø¨Ø±Ù‚Ø±Ø§Ø± Ù†ÛŒØ³Øª',
        'noInternetBody': 'Ù„Ø·ÙØ§Ù‹ ØªÙ†Ø¸ÛŒÙ…Ø§Øª Ø´Ø¨Ú©Ù‡ Ø®ÙˆØ¯ Ø±Ø§ Ø¨Ø±Ø±Ø³ÛŒ Ú©Ù†ÛŒØ¯.'
      },
      'pl': {
        'noInternetTitle': 'Brak poÅ‚Ä…czenia z Internetem',
        'noInternetBody': 'SprawdÅº ustawienia sieciowe.'
      },
      'pt': {
        'noInternetTitle': 'Sem ConexÃ£o com a Internet',
        'noInternetBody': 'Por favor, verifique suas configuraÃ§Ãµes de rede.'
      },
      'es': {
        'noInternetTitle': 'Sin conexiÃ³n a Internet',
        'noInternetBody': 'Por favor, comprueba tu configuraciÃ³n de red.'
      },
      'sv': {
        'noInternetTitle': 'Ingen internetanslutning',
        'noInternetBody': 'Kontrollera dina nÃ¤tverksinstÃ¤llningar.'
      },
      'ta': {
        'noInternetTitle': 'à®‡à®£à¯ˆà®¯ à®‡à®£à¯ˆà®ªà¯à®ªà¯ à®‡à®²à¯à®²à¯ˆ',
        'noInternetBody': 'à®‰à®™à¯à®•à®³à¯ à®¨à¯†à®Ÿà¯à®µàª°à«àª• à®…à®®à¯ˆà®ªà¯à®ªà¯à®•à®³à¯ˆà®šà¯ à®šà®°à®¿à®ªà®¾à®°à¯à®•à¯à®•à®µà¯à®®à¯.'
      },
      'ur': {
        'noInternetTitle': 'Ø§Ù†Ù¹Ø±Ù†ÛŒÙ¹ Ú©Ù†Ú©Ø´Ù† Ù†ÛÛŒÚº ÛÛ’',
        'noInternetBody': 'Ø¨Ø±Ø§Û Ú©Ø±Ù… Ø§Ù¾Ù†Û’ Ù†ÛŒÙ¹ ÙˆØ±Ú© Ú©ÛŒ ØªØ±ØªÛŒØ¨Ø§Øª Ú†ÛŒÚ© Ú©Ø±ÛŒÚºÛ”'
      },
    };
/*
DarwinFlutterLocalNotificationsPlugin
 */
    // iOS àª®àª¾àªŸà«‡
    // final iosPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<>();
    // if (iosPlugin != null) {
    //   await iosPlugin.requestPermissions(
    //     alert: true,
    //     badge: true,
    //     sound: true,
    //   );
    // }
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