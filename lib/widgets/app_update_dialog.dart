import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ads_service.dart';
import '../utils/app_colors.dart';
import '../widgets/text_widget.dart';
import '../widgets/app_button.dart';

class AppUpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final bool isForced;
  final String updateUrl;

  const AppUpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.isForced,
    required this.updateUrl,
  });

  static Future<void> checkAndShow(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final latestVersion = AdHelper.latestAppVersion;
      final minVersion = AdHelper.minRequiredAppVersion;
      final forceUpdate = AdHelper.forceUpdateEnabled;

      if (_compareVersions(latestVersion, currentVersion) > 0) {
        final bool isForced =
            forceUpdate || _compareVersions(minVersion, currentVersion) > 0;
        if (!context.mounted) return;

        showDialog(
          context: context,
          barrierDismissible: !isForced,
          builder: (ctx) => PopScope(
            canPop: !isForced,
            child: AppUpdateDialog(
              currentVersion: currentVersion,
              latestVersion: latestVersion,
              isForced: isForced,
              updateUrl: AdHelper.appUpdateUrl,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking app update: $e');
    }
  }

  static int _compareVersions(String v1, String v2) {
    final List<int> v1Parts =
        v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final List<int> v2Parts =
        v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final int maxLength =
        v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
    for (int i = 0; i < maxLength; i++) {
      final int p1 = i < v1Parts.length ? v1Parts[i] : 0;
      final int p2 = i < v2Parts.length ? v2Parts[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: colors.cardBackground,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.system_update_rounded,
              size: 48,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          AppText(
            'newUpdateAvailable',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.blackColor,
            align: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.textFieldFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'v$currentVersion',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.blackColor.withOpacity(0.6),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'v$latestVersion',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppText(
            isForced
                ? 'forceUpdateMessage'
                : 'flexibleUpdateMessage',
            fontSize: 14,
            color: colors.blackColor.withOpacity(0.7),
            align: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (!isForced) ...[
                Expanded(
                  child: AppButton(
                    title: 'cancel',
                    textColor: colors.blackColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    backgroundColor: colors.textFieldFill,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: AppButton(
                  title: 'updateNow',
                  textColor: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  backgroundColor: colors.primary,
                  onTap: () async {
                    final uri = Uri.parse(updateUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
