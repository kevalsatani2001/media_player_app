import 'package:flutter/material.dart';
import 'package:media_player/screens/setting_screen.dart';

import '../services/responsive_helper.dart';
import '../utils/app_colors.dart';

/// Supported font families
enum AppFontFamily { inter, oleoScript, roboto }

class AppText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final TextAlign align;
  final int? maxLines;
  final double? height;
  final double? letterSpacing;
  final FontStyle fontStyle;
  final AppFontFamily fontFamily;

  const AppText(this.text, {
    super.key,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w400,
    this.color,
    this.align = TextAlign.start,
    this.maxLines,
    this.height,
    this.letterSpacing,
    this.fontStyle = FontStyle.normal,
    this.fontFamily = AppFontFamily.inter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Text(
      context.tr(text),
      maxLines: maxLines,
      textAlign: align,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: _textStyle(context, color ?? colors.textPrimary),
    );
  }

  TextStyle _textStyle(BuildContext context, Color color) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    final double fontSizeSp = isLandscape ? fontSize : R.sp(context, fontSize);
    String family;
    switch (fontFamily) {
      case AppFontFamily.oleoScript:
        family = "Olio Script";
        break;
      case AppFontFamily.roboto:
        family = "Roboto";
        break;
      default:
        family = "Inter";
        break;
    }

    return TextStyle(
      fontSize: fontSizeSp,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontFamily: family,
    );
  }
}
