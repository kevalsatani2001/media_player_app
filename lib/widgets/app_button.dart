import 'package:flutter/material.dart';
import 'package:media_player/widgets/text_widget.dart';

import '../services/responsive_helper.dart';
import '../utils/app_colors.dart';

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool loading;

  // Button size
  final double? width;
  final double? height;
  final double borderRadius;

  // Colors
  final Color? backgroundColor;
  final Color? textColor;

  // 👇 Text styling (forwarded to AppText)
  final double? fontSize;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final AppFontFamily fontFamily;
  final double? letterSpacing;
  final double? textHeight;

  const AppButton({
    super.key,
    required this.title,
    required this.onTap,
    this.loading = false,
    this.width,
    this.height,
    this.borderRadius = 14,
    this.backgroundColor,
    this.textColor,

    // Text defaults
    this.fontSize,
    this.fontWeight = FontWeight.w600,
    this.fontStyle = FontStyle.normal,
    this.fontFamily = AppFontFamily.inter,
    this.letterSpacing,
    this.textHeight,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return SizedBox(
      height: height ?? R.h(context, 48),
      width: width,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor ?? colors.primary,
          disabledBackgroundColor:
          (backgroundColor ?? colors.primary).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: loading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Center(
              child: AppText(
                        title,
                        fontSize: fontSize ?? 14,
                        fontWeight: fontWeight,
                        fontStyle: fontStyle,
                        fontFamily: fontFamily,
                        letterSpacing: letterSpacing,
                        height: textHeight,
                        color: textColor ?? Colors.white,
                        align: TextAlign.center,
                      ),
            ),
      ),
    );
  }
}
