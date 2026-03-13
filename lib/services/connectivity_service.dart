/*
  connectivity_plus:
  app_settings:
 */


import 'dart:async';
import 'package:app_settings/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

import '../screens/setting_screen.dart';
import '../utils/app_colors.dart';
import '../widgets/text_widget.dart';
import 'ads_service.dart';

// Ã Â«Â§. Ã Âªâ€¡Ã ÂªÂ¨Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ°Ã ÂªÂ¨Ã Â«â€¡Ã ÂªÅ¸ Ã ÂªÅ¡Ã Â«â€¡Ã Âªâ€¢ Ã Âªâ€¢Ã ÂªÂ°Ã ÂªÂµÃ ÂªÂ¾ Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡
class NetworkInfo {
  static Future<bool> isConnected() async {
    final List<ConnectivityResult> result = await Connectivity()
        .checkConnectivity();
    return !result.contains(ConnectivityResult.none);
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
      bool currentStatus = results.contains(ConnectivityResult.none);

      if (currentStatus) {
        // à«§. àªœà«‹ àª‡àª¨à«àªŸàª°àª¨à«‡àªŸ àªœàª¾àª¯, àª¤à«‹ àªªà«àª²à«‡àª¯àª° àªªà«‹àª àª•àª°à«‹
        _pauseMedia();
      }

      if (!currentStatus && _isOffline) {
        _startConnectingAnimation();
        // à«¨. àªœà«‹ àª¨à«‡àªŸ àªªàª¾àª›à«àª‚ àª†àªµà«‡, àª¤à«‹ àªªà«àª²à«‡àª¯àª° àª°àª¿àªà«àª¯à«‚àª® àª•àª°à«‹
        _resumeMedia();
      } else {
        setState(() => _isOffline = currentStatus);
      }
    });
  }

// àªµà«€àª¡àª¿àª¯à«‹/àª“àª¡àª¿àª¯à«‹ àª°à«‹àª•àªµàª¾ àª®àª¾àªŸà«‡
  void _pauseMedia() {
    // àªœà«‹ àª¤àª®à«‡ Bloc àªµàª¾àªªàª°àª¤àª¾ àª¹à«‹àªµ:
    // context.read<VideoBloc>().add(PauseVideo());

    // àª…àª¥àªµàª¾ àªœà«‹ àª¤àª®àª¾àª°à«€ àªªàª¾àª¸à«‡ àª•à«‹àªˆ àª—à«àª²à«‹àª¬àª² àªªà«àª²à«‡àª¯àª° àª¸àª°à«àªµàª¿àª¸ àª¹à«‹àª¯:
    // AudioService.pause();

    debugPrint("Internet lost: Pausing Media...");
  }

// àªµà«€àª¡àª¿àª¯à«‹/àª“àª¡àª¿àª¯à«‹ àª«àª°à«€ àª¶àª°à«‚ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡
  void _resumeMedia() {
    // context.read<VideoBloc>().add(PlayVideo());
    debugPrint("Internet restored: Resuming Media...");
  }

  void _startConnectingAnimation() {
    setState(() {
      _isConnecting = true;
      _isOffline = false;
    });

    // Ã Â«Â¨ Ã ÂªÂ¸Ã Â«â€¡Ã Âªâ€¢Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¡Ã ÂªÂ¨Ã Â«â€¹ Ã ÂªÂ«Ã Â«â€¹Ã ÂªÂ°Ã Â«ÂÃ ÂªÂ¸Ã Â«ÂÃ ÂªÂ¡ Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ²Ã Â«ÂÃ ÂªÂ¡ (Ã ÂªÅ“Ã Â«â€¡Ã ÂªÂ¥Ã Â«â‚¬ "Connecting..." Ã ÂªÂ¦Ã Â«â€¡Ã Âªâ€“Ã ÂªÂ¾Ã ÂªÂ¯)
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
          // Key Ã Âªâ€°Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ°Ã ÂªÂµÃ ÂªÂ¾Ã ÂªÂ¥Ã Â«â‚¬ Ã Âªâ€ Ã Âªâ€“Ã Â«ÂÃ Âªâ€š Ã ÂªÂµÃ ÂªÂ¿Ã ÂªÅ“Ã Â«â€¡Ã ÂªÅ¸ Ã ÂªÅ¸Ã Â«ÂÃ ÂªÂ°Ã Â«â‚¬ Ã ÂªÂ°Ã ÂªÂ¿Ã ÂªÂ«Ã Â«ÂÃ ÂªÂ°Ã Â«â€¡Ã ÂªÂ¶ Ã ÂªÂ¥Ã ÂªÂ¶Ã Â«â€¡ Ã ÂªÅ“Ã Â«â€¡Ã ÂªÂµÃ Â«ÂÃ Âªâ€š Ã ÂªÂ¨Ã Â«â€¡Ã ÂªÅ¸ Ã Âªâ€ Ã ÂªÂµÃ ÂªÂ¶Ã Â«â€¡
          KeyedSubtree(key: ValueKey(_isConnecting), child: widget.child),

          if (_isOffline && !_isConnecting) _buildLockScreen(colors),
          if (_isConnecting) _buildConnectingScreen(colors),
        ],
      ),
    );
  }

  // --- Ã ÂªÂ²Ã Â«â€¹Ã Âªâ€¢ Ã ÂªÂ¸Ã Â«ÂÃ Âªâ€¢Ã Â«ÂÃ ÂªÂ°Ã Â«â‚¬Ã ÂªÂ¨ UI (Ã ÂªÂ¤Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â‚¬ Ã ÂªÂªÃ Â«ÂÃ ÂªÂ°Ã ÂªÂ¾Ã Âªâ€¡Ã ÂªÂµÃ ÂªÂ¸Ã Â«â‚¬ Ã ÂªÂªÃ Â«â€¹Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«â‚¬ Ã ÂªÅ“Ã Â«â€¡Ã ÂªÂµÃ Â«â‚¬ Ã ÂªÂ¡Ã ÂªÂ¿Ã ÂªÂÃ ÂªÂ¾Ã ÂªË†Ã ÂªÂ¨) ---
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

  // --- Ã Âªâ€¢Ã ÂªÂ¨Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ¿Ã Âªâ€šÃ Âªâ€” Ã ÂªÂÃ ÂªÂ¨Ã ÂªÂ¿Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ¶Ã ÂªÂ¨ UI ---
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

  // Ã Âªâ€¢Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ® Ã ÂªÂ¬Ã ÂªÅ¸Ã ÂªÂ¨ Ã ÂªÂµÃ ÂªÂ¿Ã ÂªÅ“Ã Â«â€¡Ã ÂªÅ¸
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