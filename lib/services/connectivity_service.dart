import 'dart:async';
import 'package:app_settings/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

import '../screens/setting_screen.dart';
import '../utils/app_colors.dart';
import '../widgets/text_widget.dart';
import 'ads_service.dart';
import 'global_player.dart';

class NetworkInfo {
  /// True if any interface can carry data (not only [ConnectivityResult.none]).
  /// Do not use `contains(ConnectivityResult.none)` — during WiFi/mobile handoff the
  /// list can include both, and the user is still online.
  static bool hasUsableConnection(List<ConnectivityResult> result) {
    if (result.isEmpty) return false;
    return result.any((r) => r != ConnectivityResult.none);
  }

  /// Double-check after a short delay to avoid false offline during radio handoff.
  static Future<bool> isConnected() async {
    final first = await Connectivity().checkConnectivity();
    if (hasUsableConnection(first)) return true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final second = await Connectivity().checkConnectivity();
    return hasUsableConnection(second);
  }
}

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isOffline = false;
  bool _isConnecting = false;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = !NetworkInfo.hasUsableConnection(results);

      if (isOffline) {
        _pauseMedia();
      }

      if (!isOffline && _isOffline) {
        _startConnectingAnimation();
        _resumeMedia();
      } else {
        setState(() => _isOffline = isOffline);
      }
    });
  }

  void _pauseMedia() {
    final player = GlobalPlayerService();

    // નેટ બંધ થાય ત્યારે વિડીયો ચાલુ હતો કે નહિ તે સાચવી લો
    player.wasPlayingBeforeDisconnect = player.isVideoPlaying;

    player.pauseVideo();
    debugPrint("Internet lost: Pausing Media...");
  }

  void _resumeMedia() {
    final player = GlobalPlayerService();

    // જો નેટ ગયા પહેલા વિડીયો ચાલુ હતો, તો જ પ્લે કરો
    if (player.wasPlayingBeforeDisconnect) {
      player.playVideo();
      debugPrint("Internet restored: Resuming Media...");
    } else {
      debugPrint("Internet restored: Video was not playing before, staying paused.");
    }
  }

  void _startConnectingAnimation() {
    setState(() {
      _isConnecting = true;
      _isOffline = false;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Scaffold(
      body: Stack(
        children: [
          KeyedSubtree(key: ValueKey(_isConnecting), child: widget.child),

          if (_isOffline && !_isConnecting) _buildLockScreen(colors),
          if (_isConnecting) _buildConnectingScreen(colors),
        ],
      ),
    );
  }

  Widget _buildLockScreen(AppThemeColors colors) {
    return Container(
      key: const ValueKey('lock'),
      color: colors.background,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 70,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 30),
          AppText(
            context.tr("internetRequired"),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AppText(
              context.tr("mandatoryInternetContent"),
              fontSize: 14,
              color: colors.secondaryText,
              align: TextAlign.center,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _buildButton(colors, context.tr("checkConnection"), () {
            AppSettings.openAppSettings(type: AppSettingsType.wireless);
          }),
        ],
      ),
    );
  }

  Widget _buildConnectingScreen(AppThemeColors colors) {
    return Container(
      key: const ValueKey('connecting'),
      color: colors.background,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colors.primary,
              backgroundColor: colors.primary.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 30),
          AppText(
            context.tr("restoringConnection"), // "Connecting..."
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildButton(AppThemeColors colors, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: AppText(
          text,
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
