import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

enum ToastType { success, error, info }

class AppToast {
  static void show(BuildContext context, String message, {ToastType type = ToastType.success}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () {},
      ),
    );

    overlay.insert(overlayEntry);

    // à«¨.à«« àª¸à«‡àª•àª¨à«àª¡ àªªàª›à«€ àªŸà«‹àª¸à«àªŸ àª•àª¾àª¢à«€ àª¨àª¾àª–àªµà«‹
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

// àªàª¨àª¿àª®à«‡àª¶àª¨ àª®àª¾àªŸà«‡ àª…àª²àª— àª¸à«àªŸà«‡àªŸàª«à«àª² àªµàª¿àªœà«‡àªŸ
class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _ToastWidget({required this.message, required this.type, required this.onDismiss});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // àªàª¨àª¿àª®à«‡àª¶àª¨àª¨à«€ àªàª¡àªª
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // àª¨à«€àªšà«‡àª¥à«€ àª‰àªªàª° àª†àªµàª¤à«àª‚ àªàª¨àª¿àª®à«‡àª¶àª¨ (Slide up)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward(); // àªàª¨àª¿àª®à«‡àª¶àª¨ àª¶àª°à«‚ àª•àª°à«‹

    // à«¨ àª¸à«‡àª•àª¨à«àª¡ àªªàª›à«€ àª°àª¿àªµàª°à«àª¸ àªàª¨àª¿àª®à«‡àª¶àª¨ (àªàªŸàª²à«‡ àª•à«‡ àªàª•à«àªàª¿àªŸ àªàª¨àª¿àª®à«‡àª¶àª¨)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    IconData icon;
    Color iconColor;
    switch (widget.type) {
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

    return Positioned(
      bottom: 70, // àª¥à«‹àª¡à«àª‚ àª‰àªªàª° àª°àª¾àª–à«àª¯à«àª‚ àª›à«‡
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.blackColor, // àª¡àª¾àª°à«àª• àª®à«‹àª¡ àª®à«àªœàª¬ àª•àª²àª°
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(color: colors.whiteColor, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}