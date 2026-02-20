import 'dart:ui';

import 'package:hive/hive.dart';
import '../main.dart';
import '../models/media_item.dart';
import '../models/playlist_model.dart';

class HiveService {
  static late Box settingsBox;

  static Future<void> init() async {
    // Close any boxes opened previously (during hot reload)
    // for (var name in ['videos', 'audios', 'favourites', 'playlists']) {
    //   if (Hive.isBoxOpen(name)) await Hive.box(name).close();
    // }

    await _openSettingsBox();
    await _openOrResetBox('videos');
    await _openOrResetBox('audios');
    await _openOrResetBox('favourites');
    await _openOrResetBox('recents');
    await _openOrResetBox('playlists');
    // await Hive.openBox<PlaylistModel>('playlists');
  }

  static Future<void> _openSettingsBox() async {
    settingsBox = await Hive.openBox('settings');
  }

  static Future<void> _openOrResetBox(String name) async {
    try {
      await Hive.openBox(name);
    } catch (e) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).close();
      }

      await Hive.deleteBoxFromDisk(name);
      await Hive.openBox(name);
    }
  }


  // ---------------- DATA HELPERS ----------------

  static void addRecent(MediaItem item) {
    Hive.box('recents').add(item.toMap());
  }

  static void toggleFavourite(MediaItem item) {
    final box = Hive.box('favourites');
    box.containsKey(item.path)
        ? box.delete(item.path)
        : box.put(item.path, item.toMap());
  }

  static bool isFavourite(String path) {
    return Hive.box('favourites').containsKey(path);
  }

  // ---------------- SETTINGS ----------------

  static bool get isDark => settingsBox.get('isDark', defaultValue: true);

  static set isDark(bool value) => settingsBox.put('isDark', value);

  static String get themeMode => settingsBox.get('themeMode', defaultValue: 'system');

  static set themeMode(String value) => settingsBox.put('themeMode', value);

  static String get languageCode =>
      settingsBox.get('languageCode', defaultValue: 'en');

  static set languageCode(String value) =>
      settingsBox.put('languageCode', value);

  static Future<void> saveLocale(String localeCode) async {
    await settingsBox.put('languageCode', localeCode);
  }

  static Future<Locale> loadLocale() async {
    final code = settingsBox.get('languageCode', defaultValue: 'en');
    return Locale(code);
  }

  // static String? get languageCode => settingsBox.get('language');

  static Future<void> saveLanguage(String code) async {
    await settingsBox.put('language', code);
  }
}
