import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color icon;
  final Color danger;
  final Color success;
  final Color primary;
  final Color primary2;
  final Color hintText;
  final Color text;
  final Color subTextColor;
  final Color textFieldFill;
  final Color textFieldBorder;
  final Color cardBackground;
  final Color appBarTitleColor;
  final Color blackColor;
  final Color whiteColor;
  final Color dialogueSubTitle;
  final Color dividerColor;
  final Color lightThemePrimary;
  final Color secondaryText;
  final Color grey1;
  // final Color cardBorder;

  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.icon,
    required this.danger,
    required this.success,
    required this.primary,
    required this.primary2,
    required this.hintText,
    required this.text,
    required this.textFieldFill,
    required this.textFieldBorder,
    required this.subTextColor,
    required this.cardBackground,
    required this.appBarTitleColor,
    required this.blackColor,
    required this.whiteColor,
    required this.dialogueSubTitle,
    required this.dividerColor,
    required this.lightThemePrimary,
    required this.secondaryText,
    required this.grey1,
  });

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? icon,
    Color? danger,
    Color? success,
    Color? primary,
    Color? primary2,
    Color? hintText,
    Color? text,
    Color? textFieldFill,
    Color? textFieldBorder,
    Color? subTextColor,
    Color? cardBackground,
    Color? appBarTitleColor,
    Color? blackColor,
    Color? whiteColor,
    Color? dialogueSubTitle,
    Color? dividerColor,
    Color? lightThemePrimary,
    Color? secondaryText,
    Color? grey1,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      icon: icon ?? this.icon,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      primary: primary ?? this.primary,
      primary2: primary2 ?? this.primary2,
      hintText: primary ?? this.hintText,
      text: primary ?? this.text,
      textFieldFill: textFieldFill ?? this.textFieldFill,
      textFieldBorder: textFieldBorder ?? this.textFieldBorder,
      subTextColor: subTextColor ?? this.subTextColor,
      cardBackground: cardBackground ?? this.cardBackground,
      appBarTitleColor: appBarTitleColor ?? this.appBarTitleColor,
      blackColor: appBarTitleColor ?? this.blackColor,
      whiteColor: appBarTitleColor ?? this.whiteColor,
      dialogueSubTitle: dialogueSubTitle ?? this.dialogueSubTitle,
      dividerColor: dividerColor ?? this.dividerColor,
      lightThemePrimary: lightThemePrimary ?? this.lightThemePrimary,
      secondaryText: secondaryText ?? this.secondaryText,
      grey1: grey1 ?? this.grey1,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;

    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primary2: Color.lerp(primary2, other.primary2, t)!,
      hintText: Color.lerp(hintText, other.hintText, t)!,
      text: Color.lerp(text, other.text, t)!,
      textFieldFill: Color.lerp(textFieldFill, other.textFieldFill, t)!,
      textFieldBorder: Color.lerp(textFieldBorder, other.textFieldBorder, t)!,
      subTextColor: Color.lerp(subTextColor, other.subTextColor, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      appBarTitleColor: Color.lerp(appBarTitleColor, other.appBarTitleColor, t)!,
      blackColor: Color.lerp(blackColor, other.blackColor, t)!,
      whiteColor: Color.lerp(whiteColor, other.whiteColor, t)!,
      dialogueSubTitle: Color.lerp(dialogueSubTitle, other.dialogueSubTitle, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      lightThemePrimary: Color.lerp(lightThemePrimary, other.lightThemePrimary, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      grey1: Color.lerp(grey1, other.grey1, t)!,
    );
  }
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      extensions: const [
        AppThemeColors(
          background: Color(0xFFF5F5F5),
          surface: Colors.white,
          textPrimary: Colors.black,
          textSecondary: Colors.black54,
          icon: Colors.black87,
          danger: Colors.red,
          success: Colors.green,
          primary: Color(0XFF3D57F9),
          primary2: Color(0XFF9570FF),
          hintText: Color(0XFF3D57F9),
          text: Color(0XFF3D57F9),
          textFieldFill: Color(0XFFF6F6F6),
          textFieldBorder: Color(0XFFAAAAAA),
          subTextColor: Color(0XFF111723),
          cardBackground: Color(0XFFFAFAFA),
          appBarTitleColor: Color(0XFF222222),
          blackColor: Color(0XFF000000),
          whiteColor: Color(0XFFFFFFFF),
          dialogueSubTitle: Color(0XFF999999),
          dividerColor: Color(0XFFE0E0E0),
          lightThemePrimary: Color(0XFF297AFC),
          secondaryText: Color(0XFF5C5C5C),
          grey1: Color(0XFF333333),
        ),
      ],
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF222222),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extensions: const [
        AppThemeColors(
          background: Color(0xFF121212),
          surface: Color(0xFF1E1E1E),
          textPrimary: Colors.white,
          textSecondary: Colors.white70,
          icon: Colors.white70,
          danger: Colors.green,
          success: Colors.greenAccent,
          primary: Color(0XFF3D57F9),
          primary2: Color(0XFF9570FF),
          hintText: Color(0XFF3D57F9),
          text: Color(0XFF3D57F9),
          textFieldFill: Color(0XFFF6F6F6),
          textFieldBorder: Color(0XFFAAAAAA),
          subTextColor: Color(0XFF111723),
          cardBackground: Color(0XFFFAFAFA),
          appBarTitleColor: Color(0XFF222222),
          blackColor: Color(0XFFFFFFFF),
          whiteColor: Color(0XFF000000),
          dialogueSubTitle: Color(0XFF999999),
          dividerColor: Color(0XFFE0E0E0),
          lightThemePrimary: Color(0XFF297AFC),
          secondaryText: Color(0XFF5C5C5C),
          grey1: Color(0XFF333333),
        ),
      ],
    );
  }
}
