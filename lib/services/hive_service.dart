
// flutter_secure_storage:

/*

 */

import 'dart:convert';
import 'dart:ui';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/media_item.dart';

class HiveService {
  static late Box settingsBox;
  static const _storage = FlutterSecureStorage();
  static List<int>? _encryptionKey;

  /// Initializes all Hive boxes and sets up encryption
  static Future<void> init() async {
    // 1. Retrieve or generate the encryption key from secure hardware storage
    _encryptionKey = await _getEncryptionKey();

    // 2. Open general settings box (stored in plain text for quick access)
    await _openSettingsBox();

    // 3. Open sensitive data boxes using AES-256 encryption
    await _openSecureBox('videos');
    await _openSecureBox('audios');
    await _openSecureBox('favourites');
    await _openSecureBox('recents');
    await _openSecureBox('playlists');
  }

  /// Fetches a secure key from Android Keystore or iOS Keychain.
  /// If no key exists, it generates a new 256-bit key and saves it.
  static Future<List<int>> _getEncryptionKey() async {
    var key = await _storage.read(key: 'hive_key');
    if (key == null) {
      // Generate a cryptographically strong random key
      var newKey = Hive.generateSecureKey();
      await _storage.write(key: 'hive_key', value: base64UrlEncode(newKey));
      return newKey;
    }
    return base64Url.decode(key);
  }

  /// Opens the settings box without encryption
  static Future<void> _openSettingsBox() async {
    settingsBox = await Hive.openBox('settings');
  }

  /// Opens a box with AES encryption.
  /// If opening fails (e.g., due to key mismatch), it resets the box to prevent app crashes.
  static Future<void> _openSecureBox(String name) async {
    try {
      await Hive.openBox(
        name,
        encryptionCipher: HiveAesCipher(_encryptionKey!),
      );
    } catch (e) {
      // Handle corrupted boxes or key errors by clearing local data
      if (Hive.isBoxOpen(name)) await Hive.box(name).close();
      await Hive.deleteBoxFromDisk(name);
      await Hive.openBox(
        name,
        encryptionCipher: HiveAesCipher(_encryptionKey!),
      );
    }
  }

  // ---------------- DATA HELPERS ----------------

  /// Stores a recently played media item in the encrypted box
  static void addRecent(MediaItem item) {
    final box = Hive.box('recents');
    box.add(item.toMap());
  }

  /// Adds or removes an item from the encrypted favourites box
  static void toggleFavourite(MediaItem item) {
    final box = Hive.box('favourites');
    box.containsKey(item.path)
        ? box.delete(item.path)
        : box.put(item.path, item.toMap());
  }

  /// Checks if a specific file path is marked as a favourite
  static bool isFavourite(String path) {
    return Hive.box('favourites').containsKey(path);
  }

  // ---------------- SETTINGS (Unencrypted) ----------------

  /// UI Theme settings (Dark Mode)
  static bool get isDark => settingsBox.get('isDark', defaultValue: true);
  static set isDark(bool value) => settingsBox.put('isDark', value);

  /// Theme mode (System, Light, or Dark)
  static String get themeMode => settingsBox.get('themeMode', defaultValue: 'system');
  static set themeMode(String value) => settingsBox.put('themeMode', value);

  /// Application localization settings
  static String get languageCode => settingsBox.get('languageCode', defaultValue: 'en');
  static set languageCode(String value) => settingsBox.put('languageCode', value);

  /// Persists the selected locale
  static Future<void> saveLocale(String localeCode) async {
    await settingsBox.put('languageCode', localeCode);
  }

  /// Loads the saved locale or defaults to English
  static Future<Locale> loadLocale() async {
    final code = settingsBox.get('languageCode', defaultValue: 'en');
    return Locale(code);
  }

  /// Updates the language settings in the box
  static Future<void> saveLanguage(String code) async {
    await settingsBox.put('language', code);
  }
}