import 'dart:io';
import 'package:flutter/services.dart';

class SecurityService {
  static const MethodChannel _channel = MethodChannel('media_player/security');

  /// Returns true if Developer Options is enabled on the device (Android only).
  static Future<bool> isDevModeEnabled() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? enabled = await _channel.invokeMethod<bool>('isDevModeEnabled');
      return enabled ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Opens the device's Developer Options settings screen (Android only).
  static Future<bool> openDevSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? success = await _channel.invokeMethod<bool>('openDevSettings');
      return success ?? false;
    } catch (e) {
      return false;
    }
  }
}
