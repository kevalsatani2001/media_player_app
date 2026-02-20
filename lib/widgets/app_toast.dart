import 'package:flutter/material.dart';
import 'package:media_player/widgets/text_widget.dart';

import '../utils/app_colors.dart';

enum ToastType { success, error, info }

class AppToast {
  static void show(BuildContext context, String message, {ToastType type = ToastType.success}) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    IconData icon;
    Color iconColor;

    switch (type) {
      case ToastType.success:
        icon = Icons.check_circle_rounded;
        iconColor = Colors.green;
        break;
      case ToastType.error:
        icon = Icons.error_rounded;
        iconColor = Colors.redAccent;
        break;
      case ToastType.info:
        icon = Icons.info_rounded;
        iconColor = Colors.blueAccent;
        break;
    }

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style:  TextStyle(color: colors.whiteColor, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // ૨ સેકન્ડ પછી ઓટોમેટિક દૂર થઈ જશે
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}