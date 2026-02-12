import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/local/local_bloc.dart';

class AppStrings {
  final Locale locale;

  AppStrings(this.locale);
  static const Map<String, Map<String, String>> translations = {
    'en': {
      'home': 'Home',
      'languageName': 'English',
      'video': 'Video',
      'videos': 'Videos',
      'audio': 'Audio',
      'settings': 'Settings',
      'theme': 'Theme',
      'language': 'English',
      'chooseLanguage': 'Choose the language',
      'selectPreferredLanguage':
          'Select your preferred language for accurate translation and smooth usage.',
      'welcome': 'Welcome',
      'organize': 'Organize',
      'skip': 'Skip',
    },

    'ar': {
      'home': 'الرئيسية',
      'languageName': 'Arabic',
      'video': 'فيديو',
      'videos': 'فيديوهات',
      'audio': 'صوت',
      'settings': 'الإعدادات',
      'theme': 'السمة',
      'language': 'العربية',
      'chooseLanguage': 'اختر اللغة',
      'selectPreferredLanguage': 'حدد لغتك المفضلة.',
      'welcome': 'مرحبا',
      'organize': 'تنظيم',
      'skip': 'Skip',
    },

    'my': {
      'home': 'ပင်မစာမျက်နှာ',
      'languageName': 'Burmese',
      'video': 'ဗီဒီယို',
      'videos': 'ဗီဒီယိုများ',
      'audio': 'အသံ',
      'settings': 'ဆက်တင်များ',
      'theme': 'အပြင်အဆင်',
      'language': 'မြန်မာ',
      'chooseLanguage': 'ဘာသာစကားရွေးချယ်ပါ',
      'selectPreferredLanguage': 'သင်နှစ်သက်သောဘာသာစကားကိုရွေးပါ',
      'welcome': 'ကြိုဆိုပါသည်',
      'organize': 'စီစဉ်ပါ',
    },

    'fil': {
      'home': 'Home',
      'languageName': 'Filipino',
      'video': 'Video',
      'videos': 'Mga Video',
      'audio': 'Audio',
      'settings': 'Mga Setting',
      'theme': 'Tema',
      'language': 'Filipino',
      'chooseLanguage': 'Pumili ng wika',
      'selectPreferredLanguage': 'Piliin ang nais mong wika.',
      'welcome': 'Maligayang pagdating',
      'organize': 'Ayusin',
    },

    'fr': {
      'home': 'Accueil',
      'languageName': 'French',
      'video': 'Vidéo',
      'videos': 'Vidéos',
      'audio': 'Audio',
      'settings': 'Paramètres',
      'theme': 'Thème',
      'language': 'Français',
      'chooseLanguage': 'Choisir la langue',
      'selectPreferredLanguage': 'Sélectionnez votre langue préférée.',
      'welcome': 'Bienvenue',
      'organize': 'Organiser',
    },

    'de': {
      'home': 'Startseite',
      'languageName': 'German',
      'video': 'Video',
      'videos': 'Videos',
      'audio': 'Audio',
      'settings': 'Einstellungen',
      'theme': 'Thema',
      'language': 'Deutsch',
      'chooseLanguage': 'Sprache wählen',
      'selectPreferredLanguage': 'Bevorzugte Sprache auswählen.',
      'welcome': 'Willkommen',
      'organize': 'Organisieren',
    },

    'gu': {
      'home': 'હોમ',
      'languageName': 'Gujarati',
      'video': 'વિડિયો',
      'videos': 'વિડિઓઝ',
      'audio': 'ઓડિયો',
      'settings': 'સેટિંગ્સ',
      'theme': 'થીમ',
      'language': 'ગુજરાતી',
      'chooseLanguage': 'ભાષા પસંદ કરો',
      'selectPreferredLanguage': 'તમારી પસંદની ભાષા પસંદ કરો.',
      'welcome': 'સ્વાગત છે',
      'organize': 'ગોઠવો',
    },

    'hi': {
      'home': 'होम',
      'languageName': 'Hindi',
      'video': 'वीडियो',
      'videos': 'वीडियो',
      'audio': 'ऑडियो',
      'settings': 'सेटिंग्स',
      'theme': 'थीम',
      'language': 'हिंदी',
      'chooseLanguage': 'भाषा चुनें',
      'selectPreferredLanguage': 'अपनी पसंदीदा भाषा चुनें।',
      'welcome': 'स्वागत है',
      'organize': 'व्यवस्थित करें',
    },

    'id': {
      'home': 'Beranda',
      'languageName': 'Indonesian',
      'video': 'Video',
      'videos': 'Video',
      'audio': 'Audio',
      'settings': 'Pengaturan',
      'theme': 'Tema',
      'language': 'Indonesia',
      'chooseLanguage': 'Pilih bahasa',
      'selectPreferredLanguage': 'Pilih bahasa pilihan Anda.',
      'welcome': 'Selamat datang',
      'organize': 'Atur',
    },

    'it': {
      'home': 'Home',
      'languageName': 'Italian',
      'video': 'Video',
      'videos': 'Video',
      'audio': 'Audio',
      'settings': 'Impostazioni',
      'theme': 'Tema',
      'language': 'Italiano',
      'chooseLanguage': 'Scegli la lingua',
      'selectPreferredLanguage': 'Seleziona la lingua preferita.',
      'welcome': 'Benvenuto',
      'organize': 'Organizza',
    },

    'ja': {
      'home': 'ホーム',
      'languageName': 'Japanese',
      'video': 'ビデオ',
      'videos': 'ビデオ',
      'audio': 'オーディオ',
      'settings': '設定',
      'theme': 'テーマ',
      'language': '日本語',
      'chooseLanguage': '言語を選択',
      'selectPreferredLanguage': '優先言語を選択してください。',
      'welcome': 'ようこそ',
      'organize': '整理',
    },

    'ko': {
      'home': '홈',
      'languageName': 'Korean',
      'video': '비디오',
      'videos': '비디오',
      'audio': '오디오',
      'settings': '설정',
      'theme': '테마',
      'language': '한국어',
      'chooseLanguage': '언어 선택',
      'selectPreferredLanguage': '선호하는 언어를 선택하세요.',
      'welcome': '환영합니다',
      'organize': '정리',
    },

    'ms': {
      'home': 'Laman Utama',
      'languageName': 'Malay',
      'video': 'Video',
      'videos': 'Video',
      'audio': 'Audio',
      'settings': 'Tetapan',
      'theme': 'Tema',
      'language': 'Melayu',
      'chooseLanguage': 'Pilih bahasa',
      'selectPreferredLanguage': 'Pilih bahasa pilihan anda.',
      'welcome': 'Selamat datang',
      'organize': 'Susun',
    },

    'mr': {
      'home': 'मुख्यपृष्ठ',
      'languageName': 'Marathi',
      'video': 'व्हिडिओ',
      'videos': 'व्हिडिओ',
      'audio': 'ऑडिओ',
      'settings': 'सेटिंग्स',
      'theme': 'थीम',
      'language': 'मराठी',
      'chooseLanguage': 'भाषा निवडा',
      'selectPreferredLanguage': 'आपली पसंतीची भाषा निवडा.',
      'welcome': 'स्वागत आहे',
      'organize': 'व्यवस्थित करा',
    },

    'fa': {
      'home': 'خانه',
      'languageName': 'Persian',
      'video': 'ویدیو',
      'videos': 'ویدیوها',
      'audio': 'صدا',
      'settings': 'تنظیمات',
      'theme': 'تم',
      'language': 'فارسی',
      'chooseLanguage': 'انتخاب زبان',
      'selectPreferredLanguage': 'زبان مورد نظر خود را انتخاب کنید.',
      'welcome': 'خوش آمدید',
      'organize': 'سازماندهی',
    },

    'pl': {
      'home': 'Strona główna',
      'languageName': 'Polish',
      'video': 'Wideo',
      'videos': 'Wideo',
      'audio': 'Audio',
      'settings': 'Ustawienia',
      'theme': 'Motyw',
      'language': 'Polski',
      'chooseLanguage': 'Wybierz język',
      'selectPreferredLanguage': 'Wybierz preferowany język.',
      'welcome': 'Witamy',
      'organize': 'Organizuj',
    },

    'pt': {
      'home': 'Início',
      'languageName': 'Portuguese',
      'video': 'Vídeo',
      'videos': 'Vídeos',
      'audio': 'Áudio',
      'settings': 'Configurações',
      'theme': 'Tema',
      'language': 'Português',
      'chooseLanguage': 'Escolher idioma',
      'selectPreferredLanguage': 'Selecione o idioma preferido.',
      'welcome': 'Bem-vindo',
      'organize': 'Organizar',
    },

    'es': {
      'home': 'Inicio',
      'languageName': 'Spanish',
      'video': 'Video',
      'videos': 'Videos',
      'audio': 'Audio',
      'settings': 'Configuración',
      'theme': 'Tema',
      'language': 'Español',
      'chooseLanguage': 'Elegir idioma',
      'selectPreferredLanguage': 'Seleccione su idioma preferido.',
      'welcome': 'Bienvenido',
      'organize': 'Organizar',
    },

    'sv': {
      'home': 'Hem',
      'languageName': 'Swedish',
      'video': 'Video',
      'videos': 'Videor',
      'audio': 'Ljud',
      'settings': 'Inställningar',
      'theme': 'Tema',
      'language': 'Svenska',
      'chooseLanguage': 'Välj språk',
      'selectPreferredLanguage': 'Välj önskat språk.',
      'welcome': 'Välkommen',
      'organize': 'Organisera',
    },

    'ta': {
      'home': 'முகப்பு',
      'languageName': 'Tamil',
      'video': 'வீடியோ',
      'videos': 'வீடியோக்கள்',
      'audio': 'ஆடியோ',
      'settings': 'அமைப்புகள்',
      'theme': 'தீம்',
      'language': 'தமிழ்',
      'chooseLanguage': 'மொழியைத் தேர்ந்தெடுக்கவும்',
      'selectPreferredLanguage': 'உங்கள் விருப்பமான மொழியை தேர்ந்தெடுக்கவும்.',
      'welcome': 'வரவேற்கிறோம்',
      'organize': 'ஒழுங்குபடுத்து',
    },

    'ur': {
      'home': 'ہوم',
      'languageName': 'Urdu',
      'video': 'ویڈیو',
      'videos': 'ویڈیوز',
      'audio': 'آڈیو',
      'settings': 'ترتیبات',
      'theme': 'تھیم',
      'language': 'اردو',
      'chooseLanguage': 'زبان منتخب کریں',
      'selectPreferredLanguage': 'اپنی پسندیدہ زبان منتخب کریں۔',
      'welcome': 'خوش آمدید',
      'organize': 'ترتیب دیں',
    },
  };

  String tr(String key) =>
      translations[locale.languageCode]?[key] ??
          translations['en']![key] ??
          key;

  static const LocalizationsDelegate<AppStrings> delegate = _AppLocDelegate();

  static String get(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return translations[locale]?[key] ?? translations['en']![key] ?? key;
  }
}

class _AppLocDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppLocDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppStrings.translations.keys.contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async {
    return AppStrings(locale);
  }

  @override
  bool shouldReload(_AppLocDelegate old) => false;
}