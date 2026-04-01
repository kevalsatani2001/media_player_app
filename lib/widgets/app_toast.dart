import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// 1. Added 'warning' here
enum ToastType { success, error, info, warning }

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

    // Remove the toast after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

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
      duration: const Duration(milliseconds: 400), // Speed of the animation
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Slide up animation (moving from bottom to top)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward(); // Start the animation

    // Reverse animation (Exit animation) after 2 seconds
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

    // 2. Added the warning condition in the switch case here
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
      case ToastType.warning:
        icon = Icons.warning_rounded; // Icon for warning
        iconColor = Colors.orangeAccent; // Orange or yellow color
        break;
    }

    return Positioned(
      bottom: 70, // Kept a bit elevated from the bottom
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
                color: colors.blackColor, // Color based on dark mode
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