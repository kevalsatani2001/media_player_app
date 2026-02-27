import '../utils/app_imports.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

void _rateAndReviewApp() async {
  final _inAppReview = InAppReview.instance;

  if (await _inAppReview.isAvailable()) {
    _inAppReview.requestReview();
  } else {
    // TODO: use your own store ids
    _inAppReview.openStoreListing(
      appStoreId: '<your app store id>',
      microsoftStoreId: '<your microsoft store id>',
    );
  }
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Column(
      children: [
        CommonAppBar(title: "videMusicPlayer", subTitle: "mediaPlayer"),
        Divider(color: colors.dividerColor),
        Expanded(child: _buildSettingsTab()),
      ],
    );
  }

  Widget _buildSettingsTab() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            "settings",
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: colors.lightThemePrimary,
          ),
          SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17.03),
              // color: colors.dividerColor,
              border: Border.all(width: 1.06, color: colors.dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Column(
                children: [
                  _buildSettingTab(() {}, "appTheme", AppSvg.appThemeIcon, 0),
                  Divider(color: colors.dividerColor),

                  BlocBuilder<LocaleBloc, LocaleState>(
                    builder: (context, localeState) {
                      return _buildSettingTab(
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LanguageScreen(isSettingPage: true),
                            ),
                          );
                        },
                        "preferredLanguage",
                        AppSvg.languageIcon,
                        1,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          AppText(
            "otherSettings",
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: colors.lightThemePrimary,
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17.03),
              border: Border.all(width: 1.06, color: colors.dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Column(
                children: [
                  _buildSettingTab(
                        () {
                      shareApp();
                    },
                    "shareTheApp",
                    AppSvg.shareAppIcon,
                    2,
                  ),
                  Divider(color: colors.dividerColor),
                  _buildSettingTab(
                        () {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) => _buildCustomRatingDialog(context),
                      );
                    },
                    "rateTheApp",
                    AppSvg.rateAppIcon,
                    3,
                  ),
                  Divider(color: colors.dividerColor),
                  _buildSettingTab(
                        () {},
                    "privacyPolicy",
                    AppSvg.privacyPolicyIcon,
                    4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRatingDialog(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    double currentRating = 1.0;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: colors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 25,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                context.tr('rateTheApp'),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.appBarTitleColor,
              ),
              const SizedBox(height: 10),
              // àª®à«‡àª¸à«‡àªœ
              AppText(
                "howWouldYouLove",
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: colors.textFieldBorder,
                align: TextAlign.center,
              ),
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  int starIndex = index + 1;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      double starWidth = 45.0;
                      double tapPos = details.localPosition.dx;
                      double percent = tapPos / starWidth;

                      double fineRating;
                      if (percent <= 0.25)
                        fineRating = 0.25;
                      else if (percent <= 0.50)
                        fineRating = 0.50;
                      else if (percent <= 0.75)
                        fineRating = 0.75;
                      else
                        fineRating = 1.0;

                      setState(() => currentRating = index + fineRating);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _getQuarterStarIcon(starIndex, currentRating),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.dividerColor),
                        ),
                        child: Center(
                          child: AppText(
                            "cancel",
                            fontSize: 16,
                            color: colors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);

                        if (currentRating < 3.0) {
                          _launchEmailFeedback(currentRating);
                        } else {
                          _rateAndReviewApp();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: AppText(
                            "submit",
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _launchEmailFeedback(double rating) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'your-email@example.com',
      queryParameters: {
        'subject':
        '${context.tr('appFeedback')} - $rating ${context.tr('stars')}',
        'body':
        '${context.tr("hiIGave")} $rating ${context.tr('stars')}. ${context.tr("hereIsMyFeedback")}\n\n',
      },
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  void shareApp() {
    String appMessage =
        "${context.tr("checkOutThisAmazing")} ðŸŽ¶ðŸŽ¬\n\n"
        "${context.tr("downloadItNowFrom")}\n"
        "https://play.google.com/store/apps/details?id=your.package.name";

    Share.share(appMessage, subject: "${context.tr('downloadMediaPlayer')}");
  }

  Widget _buildSettingTab(
      void Function()? onTap,
      String title,
      String icon,
      int index,
      ) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0.8, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, double scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AppImage(src: icon),
                  const SizedBox(width: 15),
                  AppText(
                    title,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: colors.secondaryText,
                  ),
                ],
              ),
              AppImage(src: AppSvg.rightArrow),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getQuarterStarIcon(int starIndex, double rating) {
    double diff = rating - (starIndex - 1);
    Widget icon;

    if (diff >= 0.75) {
      icon = AppImage(src: AppSvg.starFill, width: 45);
    } else if (diff >= 0.50) {
      icon = AppImage(src: AppSvg.starHalf, width: 45);
    } else if (diff >= 0.25) {
      icon = AppImage(src: AppSvg.starHalfHalf, width: 45);
    } else {
      icon = AppImage(src: AppSvg.startEmpty, width: 45);
    }

    // àªœà«‹ àª† àª¸à«àªŸàª¾àª° àª¸àª¿àª²à«‡àª•à«àªŸà«‡àª¡ àª¹à«‹àª¯ àª¤à«‹ àª¤à«‡ àª¸à«àª•à«‡àª² (àª®à«‹àªŸà«‹) àª¥àª¶à«‡
    bool isSelected = rating >= starIndex - 0.75;

    return AnimatedScale(
      scale: isSelected ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.elasticOut,
      child: icon,
    );
  }
}

extension LocalizationExtension on BuildContext {
  String tr(String key) {
    final locale = Localizations.localeOf(this).languageCode;
    return AppStrings.translations[locale]?[key] ??
        AppStrings.translations['en']![key] ??
        key;
  }
}

enum AppThemeMode { light, dark, system }

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  late String _tempSelectedTheme;

  @override
  void initState() {
    super.initState();

    _tempSelectedTheme = HiveService.themeMode;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        leading: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText("appearance", fontWeight: FontWeight.w600, fontSize: 20),
            AppText(
              "selectAppTheme",
              fontSize: 13,
              color: colors.subTextColor.withOpacity(0.5),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                context.read<ThemeBloc>().add(
                  UpdateThemeMode(_tempSelectedTheme),
                );

                AppToast.show(
                  context,
                  "${context.tr("themeUpdatesSuccessfully")}",
                  type: ToastType.success,
                );

                Navigator.pop(context);
              },
              child: AppImage(
                src: _tempSelectedTheme == HiveService.themeMode
                    ? AppSvg
                    .doneUnSelect // àªœà«‹ àª•àª‚àªˆ àª¬àª¦àª²àª¾àª¯à«àª‚ àª¨àª¾ àª¹à«‹àª¯
                    : AppSvg.doneSelect, // àªœà«‹ àª¬àª¦àª²àª¾àª¯à«àª‚ àª¹à«‹àª¯
                height: 30,
                width: 30,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildOption(
                "lightMode",
                "classicLight",
                AppThemeMode.light.name,
                Icons.wb_sunny_outlined,
                colors,
              ),
              _buildOption(
                "darkMode",
                "modernDark",
                AppThemeMode.dark.name,
                Icons.nightlight_round_outlined,
                colors,
              ),
              _buildOption(
                "systemDefault",
                "followDevice",
                AppThemeMode.system.name,
                Icons.settings_brightness_outlined,
                colors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
      String title,
      String sub,
      String code,
      IconData icon,
      AppThemeColors colors,
      ) {
    bool isSelected = _tempSelectedTheme == code;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tempSelectedTheme = code;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.textFieldBorder.withOpacity(0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? colors.primary : colors.textFieldBorder,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(title, fontSize: 16, fontWeight: FontWeight.w500),
                    AppText(
                      sub,
                      fontSize: 12,
                      color: colors.subTextColor.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
              // Radio Button
              Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.textFieldBorder,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: colors.primary,
                  ),
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}









//
// /////////////////////////////////////////////// 26/02/26 ///////////////////////////////////
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:media_player/screens/language_screen.dart';
// import 'package:media_player/widgets/text_widget.dart';
// import 'package:rating_dialog/rating_dialog.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../blocs/local/local_bloc.dart';
// import '../blocs/local/local_event.dart';
// import '../blocs/local/local_state.dart';
// import '../blocs/theme/theme_bloc.dart';
// import '../blocs/theme/theme_event.dart';
// import '../core/constants.dart';
// import '../services/hive_service.dart';
// import '../utils/app_colors.dart';
// import '../utils/app_string.dart';
// import '../widgets/app_bar.dart';
// import '../widgets/app_toast.dart';
// import '../widgets/image_widget.dart';
// import 'package:in_app_review/in_app_review.dart';
//
// class SettingScreen extends StatefulWidget {
//   const SettingScreen({super.key});
//
//   @override
//   State<SettingScreen> createState() => _SettingScreenState();
// }
// void _rateAndReviewApp() async {
//   // refer to: https://pub.dev/packages/in_app_review
//   final _inAppReview = InAppReview.instance;
//
//   if (await _inAppReview.isAvailable()) {
//     print('request actual review from store');
//     _inAppReview.requestReview();
//   } else {
//     print('open actual store listing');
//     // TODO: use your own store ids
//     _inAppReview.openStoreListing(
//       appStoreId: '<your app store id>',
//       microsoftStoreId: '<your microsoft store id>',
//     );
//   }
// }
// class _SettingScreenState extends State<SettingScreen> {
//
//   @override
//   Widget build(BuildContext context) {
//     final colors = Theme.of(context).extension<AppThemeColors>()!;
//     return Column(
//       children: [
//         CommonAppBar(
//           title: "videMusicPlayer",
//           subTitle: "mediaPlayer",
//         ),
//         Divider(color: colors.dividerColor),
//         Expanded(child: _buildSettingsTab()),
//       ],
//     );
//   }
//
//   Widget _buildSettingsTab() {
//     final colors = Theme.of(context).extension<AppThemeColors>()!;
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // BlocBuilder<ThemeBloc, ThemeState>(
//           //   builder: (context, themeState) {
//           //     return ListTile(
//           //       leading: Icon(Icons.light_mode,
//           //         // themeState.isDark ? Icons.dark_mode : Icons.light_mode,
//           //       ),
//           //       title: Text(AppStrings.get(context, 'theme')),
//           //       trailing: Switch(
//           //         value: themeState.isDark,
//           //         onChanged: (_) =>
//           //             context.read<ThemeBloc>().add(ToggleTheme()),
//           //       ),
//           //     );
//           //   },
//           // ),
//           AppText("settings",fontSize: 15,fontWeight: FontWeight.w500,color: colors.lightThemePrimary,),
//           SizedBox(height: 10,),
//           Container(
//             decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(17.03),
//                 // color: colors.dividerColor,
//                 border: Border.all(width: 1.06,color: colors.dividerColor)
//             ),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 0),
//               child: Column(
//                 children: [
//                   _buildSettingTab((){
//                     // Navigator.push(
//                     //   context,
//                     //   MaterialPageRoute(
//                     //     builder: (_) => ThemeScreen(),
//                     //   ),
//                     // );
//                   },"appTheme",AppSvg.appThemeIcon),
//                   Divider(color: colors.dividerColor,),
//
//                   BlocBuilder<LocaleBloc, LocaleState>(
//                     builder: (context, localeState) {
//                       return _buildSettingTab((){
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) =>  LanguageScreen(isSettingPage: true),
//                           ),
//                         );
//                       },"preferredLanguage",AppSvg.languageIcon);
//                     },
//                   ),
//
//
//
//                 ],
//               ),
//             ),
//           ),
//           SizedBox(height: 20,),
//           AppText("otherSettings",fontSize: 15,fontWeight: FontWeight.w500,color: colors.lightThemePrimary,),
//           SizedBox(height: 20,),
//           Container(
//             decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(17.03),
//                 // color: colors.dividerColor,
//                 border: Border.all(width: 1.06,color: colors.dividerColor)
//             ),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 0),
//               child: Column(
//                 children: [
//                   _buildSettingTab((){
//                     shareApp();
//                   },"shareTheApp",AppSvg.shareAppIcon),
//                   Divider(color: colors.dividerColor,),
//                   _buildSettingTab(() {
//                     showDialog(
//                       context: context,
//                       barrierDismissible: true,
//                       builder: (context) => _buildCustomRatingDialog(context),
//                     );
//                   }, "rateTheApp", AppSvg.rateAppIcon),
//                   Divider(color: colors.dividerColor,),
//                   _buildSettingTab((){},"privacyPolicy",AppSvg.privacyPolicyIcon),
//
//
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//   Widget _buildCustomRatingDialog(BuildContext context) {
//     final colors = Theme.of(context).extension<AppThemeColors>()!;
//     double currentRating = 1.0;
//
//     return StatefulBuilder(builder: (context, setState) {
//       return AlertDialog(
//         backgroundColor: colors.cardBackground,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // // એપ આઈકોન અથવા રેટિંગ આઈકોન
//             // Container(
//             //   padding: const EdgeInsets.all(15),
//             //   decoration: BoxDecoration(
//             //     color: colors.primary.withOpacity(0.1),
//             //     shape: BoxShape.circle,
//             //   ),
//             //   child: Icon(Icons.star_rounded, color: colors.primary, size: 40),
//             // ),
//             // const SizedBox(height: 20),
//             // ટાઇટલ
//             AppText(
//               context.tr('rateTheApp'),
//               fontSize: 18,
//               fontWeight: FontWeight.w700,
//               color: colors.appBarTitleColor,
//             ),
//             const SizedBox(height: 10),
//             // મેસેજ
//             AppText(
//               "howWouldYouLove",
//               fontSize: 16,
//               fontWeight: FontWeight.w400,
//               color: colors.textFieldBorder,
//               align: TextAlign.center,
//             ),
//             const SizedBox(height: 25),
//             // સ્ટાર્સ (Rating Stars)
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(5, (index) {
//                 int starIndex = index + 1;
//                 return GestureDetector(
//                   behavior: HitTestBehavior.opaque, // ક્લિક વ્યવસ્થિત પકડાય તે માટે
//                   onTapDown: (details) {
//                     double starWidth = 45.0;
//                     double tapPos = details.localPosition.dx;
//                     double percent = tapPos / starWidth;
//
//                     double fineRating;
//                     if (percent <= 0.25) fineRating = 0.25;
//                     else if (percent <= 0.50) fineRating = 0.50;
//                     else if (percent <= 0.75) fineRating = 0.75;
//                     else fineRating = 1.0;
//
//                     setState(() => currentRating = index + fineRating);
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 4),
//                     child: _getQuarterStarIcon(starIndex, currentRating),
//                   ),
//                 );
//               }),
//             ),
//             const SizedBox(height: 30),
//             // બટન્સ
//             Row(
//               children: [
//                 Expanded(
//                   child: GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: colors.dividerColor),
//                       ),
//                       child: Center(
//                         child: AppText("cancel", fontSize: 16, color: colors.secondaryText),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: GestureDetector(
//                     onTap: () async {
//                       Navigator.pop(context); // ડાયલોગ બંધ કરો
//
//                       if (currentRating < 3.0) {
//                         // લો-રેટિંગ માટે ઈમેલ લોજિક
//                         _launchEmailFeedback(currentRating);
//                       } else {
//                         // હાઈ-રેટિંગ માટે સ્ટોર રિવ્યુ
//                         _rateAndReviewApp();
//                       }
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       decoration: BoxDecoration(
//                         color: colors.primary,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Center(
//                         child: AppText("submit", fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             )
//           ],
//         ),
//       );
//     });
//   }
//
// // ઈમેલ લોન્ચ કરવા માટેનું ફંક્શન
//   void _launchEmailFeedback(double rating) async {
//     final Uri emailLaunchUri = Uri(
//       scheme: 'mailto',
//       path: 'your-email@example.com',
//       queryParameters: {
//         'subject': '${context.tr('appFeedback')} - $rating ${context.tr('stars')}',
//         'body': '${context.tr("hiIGave")} $rating ${context.tr('stars')}. ${context.tr("hereIsMyFeedback")}\n\n',
//       },
//     );
//     if (await canLaunchUrl(emailLaunchUri)) {
//       await launchUrl(emailLaunchUri);
//     }
//   }
//
//   void shareApp() {
//      String appMessage =
//         "${context.tr("checkOutThisAmazing")} 🎶🎬\n\n"
//         "${context.tr("downloadItNowFrom")}\n"
//         "https://play.google.com/store/apps/details?id=your.package.name";
//
//     // Share.share ફંક્શન સિસ્ટમ ડાયલોગ ઓપન કરશે
//     Share.share(appMessage, subject: "${context.tr('downloadMediaPlayer')}");
//   }
//
//   Widget _buildSettingTab(void Function()? onTap, String title, String icon) {
//     final colors = Theme.of(context).extension<AppThemeColors>()!;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 15),
//       child: GestureDetector(
//         onTap: onTap,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 AppImage(src:icon),
//                 SizedBox(width: 15,),
//                 AppText(title,fontSize: 15,fontWeight: FontWeight.w400,color: colors.secondaryText,)
//               ],
//             ),
//             AppImage(src: AppSvg.rightArrow)
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _getStarIcon(int index, double rating) {
//     if (rating >= index) {
//       // Full Star
//       return AppImage(src: AppSvg.starFill, width: 45);
//     } else if (rating >= index - 0.5) {
//       // Half Star - Ahiya tamare Half Star nu SVG vaparvu padashe
//       return AppImage(src: AppSvg.starHalf, width: 45);
//     } else {
//       // Empty Star
//       return AppImage(src: AppSvg.startEmpty, width: 45);
//     }
//   }
//
//   Widget _buildFineTunedStar(int starIndex, double rating) {
//     double fillPercent = 0.0;
//
//     if (rating >= starIndex) {
//       fillPercent = 1.0; // Akho star bharayelo
//     } else if (rating > starIndex - 1 && rating < starIndex) {
//       fillPercent = rating - (starIndex - 1); // Partial fill (0.25, 0.50, etc.)
//     }
//
//     return Stack(
//       children: [
//         // Background: Khali star
//         AppImage(src: AppSvg.startEmpty, width: 40),
//
//         // Foreground: Bharelo star (ShaderMask sathe)
//         ShaderMask(
//           blendMode: BlendMode.srcIn,
//           shaderCallback: (rect) {
//             return LinearGradient(
//               stops: [fillPercent, fillPercent],
//               colors: [Colors.amber, Colors.transparent], // Amber color jetlo percent fill hoy tetlo
//             ).createShader(rect);
//           },
//           child: AppImage(src: AppSvg.starFill, width: 40),
//         ),
//       ],
//     );
//   }
//
//   Widget _getQuarterStarIcon(int starIndex, double rating) {
//     // આ સ્ટાર માટે કેટલી વેલ્યુ છે તે ચેક કરો (0.0 થી 1.0 વચ્ચે)
//     double diff = rating - (starIndex - 1);
//
//     if (diff >= 1.0) {
//       return AppImage(src: AppSvg.starFill, width: 45); // 100%
//     } else if (diff >= 0.75) {
//       // જો 0.75 આઈકોન ન હોય તો starFill અથવા starHalf વાપરી શકાય
//       return AppImage(src: AppSvg.starFill, width: 45);
//     } else if (diff >= 0.50) {
//       return AppImage(src: AppSvg.starHalf, width: 45); // 50%
//     } else if (diff >= 0.25) {
//       return AppImage(src: AppSvg.starHalfHalf, width: 45); // 25%
//     } else {
//       return AppImage(src: AppSvg.startEmpty, width: 45); // 0%
//     }
//   }
// }
//
// extension LocalizationExtension on BuildContext {
//   String tr(String key) {
//     final locale = Localizations.localeOf(this).languageCode;
//     return AppStrings.translations[locale]?[key] ??
//         AppStrings.translations['en']![key] ??
//         key;
//   }
// }
//
//
// enum AppThemeMode { light, dark, system }
//
// class ThemeScreen extends StatefulWidget {
//   const ThemeScreen({super.key});
//
//   @override
//   State<ThemeScreen> createState() => _ThemeScreenState();
// }
//
// class _ThemeScreenState extends State<ThemeScreen> {
//   late String _tempSelectedTheme;
//
//   @override
//   void initState() {
//     super.initState();
//     // શરૂઆતમાં જે Hive માં હોય તે લોકલ સ્ટેટમાં લો
//     _tempSelectedTheme = HiveService.themeMode;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final colors = Theme.of(context).extension<AppThemeColors>()!;
//
//     return Scaffold(
//       appBar: AppBar(
//         elevation: 0,
//         toolbarHeight: 80,
//         // ✅ બેક બટન: ફક્ત પાછા જવા માટે
//         leading: Padding(
//           padding: const EdgeInsets.all(16),
//           child: GestureDetector(
//             onTap: () => Navigator.pop(context),
//             child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20),
//           ),
//         ),
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             AppText("appearance", fontWeight: FontWeight.w600, fontSize: 20),
//             AppText("selectAppTheme", fontSize: 13, color: colors.subTextColor.withOpacity(0.5)),
//           ],
//         ),
//         actions: [
//           // ✅ ડન બટન: અહીં સાચું લોજિક આવશે
//           Padding(
//             padding: const EdgeInsets.only(right: 16),
//             child: GestureDetector(
//               onTap: () {
//                 // ૧. Bloc ને ઇવેન્ટ મોકલો (આ રન-ટાઇમ અપડેટ કરશે)
//                 // અહીં આપણે Enum ની string વેલ્યુ પાસ કરીએ છીએ
//                 context.read<ThemeBloc>().add(UpdateThemeMode(_tempSelectedTheme));
//
//                 // ૨. સક્સેસ ટોસ્ટ
//                 AppToast.show(context, "${context.tr("themeUpdatesSuccessfully")}", type: ToastType.success);
//
//                 // ૩. સ્ક્રીન બંધ કરો
//                 Navigator.pop(context);
//               },
//               child: AppImage(
//                   src: _tempSelectedTheme == HiveService.themeMode
//                       ? AppSvg.doneUnSelect // જો કંઈ બદલાયું ના હોય
//                       : AppSvg.doneSelect,   // જો બદલાયું હોય
//                   height: 30,
//                   width: 30
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 15),
//           child: Column(
//             children: [
//               const SizedBox(height: 10),
//               // Enum મુજબ જ 'light', 'dark', 'system' કી વાપરો
//               _buildOption("lightMode", "classicLight", AppThemeMode.light.name, Icons.wb_sunny_outlined, colors),
//               _buildOption("darkMode", "modernDark", AppThemeMode.dark.name, Icons.nightlight_round_outlined, colors),
//               _buildOption("systemDefault", "followDevice", AppThemeMode.system.name, Icons.settings_brightness_outlined, colors),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildOption(String title, String sub, String code, IconData icon, AppThemeColors colors) {
//     bool isSelected = _tempSelectedTheme == code;
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: GestureDetector(
//         onTap: () {
//           setState(() {
//             _tempSelectedTheme = code; // ફક્ત લોકલ સ્ટેટ અપડેટ કરો
//           });
//         },
//         child: Container(
//           padding: const EdgeInsets.all(15),
//           decoration: BoxDecoration(
//             color: colors.cardBackground,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: isSelected ? colors.primary : colors.textFieldBorder.withOpacity(0.2),
//               width: isSelected ? 1.5 : 1,
//             ),
//           ),
//           child: Row(
//             children: [
//               Icon(icon, color: isSelected ? colors.primary : colors.textFieldBorder),
//               const SizedBox(width: 15),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     AppText(title, fontSize: 16, fontWeight: FontWeight.w500),
//                     AppText(sub, fontSize: 12, color: colors.subTextColor.withOpacity(0.6)),
//                   ],
//                 ),
//               ),
//               // Radio Button
//               Container(
//                 height: 20, width: 20,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(color: isSelected ? colors.primary : colors.textFieldBorder, width: 2),
//                 ),
//                 child: isSelected ? Center(child: CircleAvatar(radius: 5, backgroundColor: colors.primary)) : null,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// /*
// <svg width="39" height="37" viewBox="0 0 39 37" xmlns="http://www.w3.org/2000/svg">
// <defs>
// <linearGradient id="quarterGradient" x1="0%" y1="0%" x2="100%" y2="0%">
// <stop offset="25%" stop-color="#FFA800"/>
// <stop offset="25%" stop-color="white"/>
// </linearGradient>
// </defs>
//
// <path
// d="M13.0826 11.7654C13.0826 11.7654 5.84685 12.5691 1.01999 13.1064C0.58493 13.1592 0.200247 13.4508 0.0559911 13.894C-0.0882651 14.3371 0.0559908 14.7987 0.37656 15.0903C3.96236 18.3715 9.35021 23.2852 9.35021 23.2852C9.34563 23.2852 7.87101 30.4331 6.89099 35.2022C6.80855 35.6339 6.96426 36.0908 7.33978 36.364C7.71302 36.6373 8.19387 36.6419 8.57169 36.4283C12.794 34.022 19.1184 30.4032 19.1184 30.4032C19.1184 30.4032 25.4451 34.022 29.6606 36.4306C30.0452 36.6419 30.5261 36.6373 30.8993 36.364C31.2749 36.0908 31.4306 35.6339 31.3458 35.2045C30.3658 30.4331 28.8935 23.2852 28.8935 23.2852C28.8935 23.2852 34.2813 18.3715 37.8671 15.0972C38.1877 14.7964 38.3297 14.3348 38.1877 13.894C38.0457 13.4531 37.6611 13.1615 37.226 13.111C32.3991 12.5691 25.1611 11.7654 25.1611 11.7654C25.1611 11.7654 22.1615 5.11122 20.1626 0.675067C19.9748 0.277834 19.581 0 19.1184 0C18.6559 0 18.2597 0.28013 18.0811 0.675067C16.0799 5.11122 13.0826 11.7654 13.0826 11.7654Z"
// fill="url(#quarterGradient)"
// />
// </svg>
//  */
//
//
//
// //// half
//
// /*
// <svg width="39" height="37" viewBox="0 0 39 37" xmlns="http://www.w3.org/2000/svg">
//     <defs>
//         <linearGradient id="halfGradient" x1="0%" y1="0%" x2="100%" y2="0%">
//             <stop offset="50%" stop-color="#FFA800"/>
//             <stop offset="50%" stop-color="white"/>
//         </linearGradient>
//     </defs>
//
//     <path
//         d="M13.0826 11.7654C13.0826 11.7654 5.84685 12.5691 1.01999 13.1064C0.58493 13.1592 0.200247 13.4508 0.0559911 13.894C-0.0882651 14.3371 0.0559908 14.7987 0.37656 15.0903C3.96236 18.3715 9.35021 23.2852 9.35021 23.2852C9.34563 23.2852 7.87101 30.4331 6.89099 35.2022C6.80855 35.6339 6.96426 36.0908 7.33978 36.364C7.71302 36.6373 8.19387 36.6419 8.57169 36.4283C12.794 34.022 19.1184 30.4032 19.1184 30.4032C19.1184 30.4032 25.4451 34.022 29.6606 36.4306C30.0452 36.6419 30.5261 36.6373 30.8993 36.364C31.2749 36.0908 31.4306 35.6339 31.3458 35.2045C30.3658 30.4331 28.8935 23.2852 28.8935 23.2852C28.8935 23.2852 34.2813 18.3715 37.8671 15.0972C38.1877 14.7964 38.3297 14.3348 38.1877 13.894C38.0457 13.4531 37.6611 13.1615 37.226 13.111C32.3991 12.5691 25.1611 11.7654 25.1611 11.7654C25.1611 11.7654 22.1615 5.11122 20.1626 0.675067C19.9748 0.277834 19.581 0 19.1184 0C18.6559 0 18.2597 0.28013 18.0811 0.675067C16.0799 5.11122 13.0826 11.7654 13.0826 11.7654Z"
//         fill="url(#halfGradient)"
//     />
// </svg>
//  */
//
//
//
//
// // import 'package:flutter/cupertino.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:media_player/screens/language_screen.dart';
// // import 'package:media_player/widgets/text_widget.dart';
// // import 'package:rating_dialog/rating_dialog.dart';
// // import 'package:share_plus/share_plus.dart';
// // import 'package:url_launcher/url_launcher.dart';
// // import '../blocs/local/local_bloc.dart';
// // import '../blocs/local/local_event.dart';
// // import '../blocs/local/local_state.dart';
// // import '../blocs/theme/theme_bloc.dart';
// // import '../blocs/theme/theme_event.dart';
// // import '../core/constants.dart';
// // import '../services/hive_service.dart';
// // import '../utils/app_colors.dart';
// // import '../utils/app_string.dart';
// // import '../widgets/app_bar.dart';
// // import '../widgets/app_toast.dart';
// // import '../widgets/image_widget.dart';
// // import 'package:in_app_review/in_app_review.dart';
// //
// // class SettingScreen extends StatefulWidget {
// //   const SettingScreen({super.key});
// //
// //   @override
// //   State<SettingScreen> createState() => _SettingScreenState();
// // }
// // void _rateAndReviewApp() async {
// //   // refer to: https://pub.dev/packages/in_app_review
// //   final _inAppReview = InAppReview.instance;
// //
// //   if (await _inAppReview.isAvailable()) {
// //     print('request actual review from store');
// //     _inAppReview.requestReview();
// //   } else {
// //     print('open actual store listing');
// //     // TODO: use your own store ids
// //     _inAppReview.openStoreListing(
// //       appStoreId: '<your app store id>',
// //       microsoftStoreId: '<your microsoft store id>',
// //     );
// //   }
// // }
// // class _SettingScreenState extends State<SettingScreen> {
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final colors = Theme.of(context).extension<AppThemeColors>()!;
// //     return Column(
// //       children: [
// //         CommonAppBar(
// //           title: "videMusicPlayer",
// //           subTitle: "mediaPlayer",
// //         ),
// //         Divider(color: colors.dividerColor),
// //         Expanded(child: _buildSettingsTab()),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildSettingsTab() {
// //     final colors = Theme.of(context).extension<AppThemeColors>()!;
// //     return Padding(
// //       padding: const EdgeInsets.all(16.0),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // BlocBuilder<ThemeBloc, ThemeState>(
// //           //   builder: (context, themeState) {
// //           //     return ListTile(
// //           //       leading: Icon(Icons.light_mode,
// //           //         // themeState.isDark ? Icons.dark_mode : Icons.light_mode,
// //           //       ),
// //           //       title: Text(AppStrings.get(context, 'theme')),
// //           //       trailing: Switch(
// //           //         value: themeState.isDark,
// //           //         onChanged: (_) =>
// //           //             context.read<ThemeBloc>().add(ToggleTheme()),
// //           //       ),
// //           //     );
// //           //   },
// //           // ),
// //           AppText("settings",fontSize: 15,fontWeight: FontWeight.w500,color: colors.lightThemePrimary,),
// //           SizedBox(height: 10,),
// //           Container(
// //             decoration: BoxDecoration(
// //                 borderRadius: BorderRadius.circular(17.03),
// //                 // color: colors.dividerColor,
// //                 border: Border.all(width: 1.06,color: colors.dividerColor)
// //             ),
// //             child: Padding(
// //               padding: const EdgeInsets.symmetric(vertical: 0),
// //               child: Column(
// //                 children: [
// //                   _buildSettingTab((){
// //                     Navigator.push(
// //                       context,
// //                       MaterialPageRoute(
// //                         builder: (_) => ThemeScreen(),
// //                       ),
// //                     );
// //                   },"appTheme",AppSvg.appThemeIcon),
// //                   Divider(color: colors.dividerColor,),
// //
// //                   BlocBuilder<LocaleBloc, LocaleState>(
// //                     builder: (context, localeState) {
// //                       return _buildSettingTab((){
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (_) =>  LanguageScreen(isSettingPage: true),
// //                           ),
// //                         );
// //                       },"preferredLanguage",AppSvg.languageIcon);
// //                     },
// //                   ),
// //
// //
// //
// //                 ],
// //               ),
// //             ),
// //           ),
// //           SizedBox(height: 20,),
// //           AppText("Other Settings",fontSize: 15,fontWeight: FontWeight.w500,color: colors.lightThemePrimary,),
// //           SizedBox(height: 20,),
// //           Container(
// //             decoration: BoxDecoration(
// //                 borderRadius: BorderRadius.circular(17.03),
// //                 // color: colors.dividerColor,
// //                 border: Border.all(width: 1.06,color: colors.dividerColor)
// //             ),
// //             child: Padding(
// //               padding: const EdgeInsets.symmetric(vertical: 0),
// //               child: Column(
// //                 children: [
// //                   _buildSettingTab((){
// //                     shareApp();
// //                   },"shareTheApp",AppSvg.shareAppIcon),
// //                   Divider(color: colors.dividerColor,),
// //                   _buildSettingTab(() {
// //                     showDialog(
// //                       context: context,
// //                       barrierDismissible: true,
// //                       builder: (context) => _buildCustomRatingDialog(context),
// //                     );
// //                   }, "rateTheApp", AppSvg.rateAppIcon),
// //                   Divider(color: colors.dividerColor,),
// //                   _buildSettingTab((){},"privacyPolicy",AppSvg.privacyPolicyIcon),
// //
// //
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //
// //   Widget _buildCustomRatingDialog(BuildContext context) {
// //     final colors = Theme.of(context).extension<AppThemeColors>()!;
// //     double currentRating = 1.0;
// //
// //     return StatefulBuilder(builder: (context, setState) {
// //       return AlertDialog(
// //         backgroundColor: colors.cardBackground,
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// //         contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             // // એપ આઈકોન અથવા રેટિંગ આઈકોન
// //             // Container(
// //             //   padding: const EdgeInsets.all(15),
// //             //   decoration: BoxDecoration(
// //             //     color: colors.primary.withOpacity(0.1),
// //             //     shape: BoxShape.circle,
// //             //   ),
// //             //   child: Icon(Icons.star_rounded, color: colors.primary, size: 40),
// //             // ),
// //             // const SizedBox(height: 20),
// //             // ટાઇટલ
// //             AppText(
// //               context.tr('rateTheApp'),
// //               fontSize: 18,
// //               fontWeight: FontWeight.w700,
// //               color: colors.appBarTitleColor,
// //             ),
// //             const SizedBox(height: 10),
// //             // મેસેજ
// //             AppText(
// //               "howWouldYouLove",
// //               fontSize: 16,
// //               fontWeight: FontWeight.w400,
// //               color: colors.textFieldBorder,
// //               align: TextAlign.center,
// //             ),
// //             const SizedBox(height: 25),
// //             // સ્ટાર્સ (Rating Stars)
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: List.generate(5, (index) {
// //                 return GestureDetector(
// //                     onTap: () {
// //                       setState(() => currentRating = index + 1.0);
// //                     },
// //                     child: Padding(
// //                       padding: const EdgeInsets.symmetric(horizontal: 4),
// //                       child: AppImage(src: index < currentRating ? AppSvg.starFill:AppSvg.startEmpty),
// //                     )
// //
// //
// //                   // Icon(
// //                   //   index < currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
// //                   //   color: index < currentRating ? Colors.amber : colors.dividerColor,
// //                   //   size: 45,
// //                   // ),
// //                 );
// //               }),
// //             ),
// //             const SizedBox(height: 30),
// //             // બટન્સ
// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: GestureDetector(
// //                     onTap: () => Navigator.pop(context),
// //                     child: Container(
// //                       padding: const EdgeInsets.symmetric(vertical: 12),
// //                       decoration: BoxDecoration(
// //                         borderRadius: BorderRadius.circular(12),
// //                         border: Border.all(color: colors.dividerColor),
// //                       ),
// //                       child: Center(
// //                         child: AppText("cancel", fontSize: 16, color: colors.secondaryText),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(width: 12),
// //                 Expanded(
// //                   child: GestureDetector(
// //                     onTap: () async {
// //                       Navigator.pop(context); // ડાયલોગ બંધ કરો
// //
// //                       if (currentRating < 3.0) {
// //                         // લો-રેટિંગ માટે ઈમેલ લોજિક
// //                         _launchEmailFeedback(currentRating);
// //                       } else {
// //                         // હાઈ-રેટિંગ માટે સ્ટોર રિવ્યુ
// //                         _rateAndReviewApp();
// //                       }
// //                     },
// //                     child: Container(
// //                       padding: const EdgeInsets.symmetric(vertical: 12),
// //                       decoration: BoxDecoration(
// //                         color: colors.primary,
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       child: Center(
// //                         child: AppText("submit", fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             )
// //           ],
// //         ),
// //       );
// //     });
// //   }
// //
// // // ઈમેલ લોન્ચ કરવા માટેનું ફંક્શન
// //   void _launchEmailFeedback(double rating) async {
// //     final Uri emailLaunchUri = Uri(
// //       scheme: 'mailto',
// //       path: 'your-email@example.com',
// //       queryParameters: {
// //         'subject': 'App Feedback - $rating Stars',
// //         'body': 'Hi, I gave $rating stars. Here is my feedback:\n\n',
// //       },
// //     );
// //     if (await canLaunchUrl(emailLaunchUri)) {
// //       await launchUrl(emailLaunchUri);
// //     }
// //   }
// //
// //   void shareApp() {
// //     const String appMessage =
// //         "Check out this amazing Video & Music Player app! 🎶🎬\n\n"
// //         "Download it now from Play Store:\n"
// //         "https://play.google.com/store/apps/details?id=your.package.name";
// //
// //     // Share.share ફંક્શન સિસ્ટમ ડાયલોગ ઓપન કરશે
// //     Share.share(appMessage, subject: 'Download Media Player');
// //   }
// //
// //   Widget _buildSettingTab(void Function()? onTap, String title, String icon) {
// //     final colors = Theme.of(context).extension<AppThemeColors>()!;
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 15),
// //       child: GestureDetector(
// //         onTap: onTap,
// //         child: Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             Row(
// //               children: [
// //                 AppImage(src:icon),
// //                 SizedBox(width: 15,),
// //                 AppText(title,fontSize: 15,fontWeight: FontWeight.w400,color: colors.secondaryText,)
// //               ],
// //             ),
// //             AppImage(src: AppSvg.rightArrow)
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // extension LocalizationExtension on BuildContext {
// //   String tr(String key) {
// //     final locale = Localizations.localeOf(this).languageCode;
// //     return AppStrings.translations[locale]?[key] ??
// //         AppStrings.translations['en']![key] ??
// //         key;
// //   }
// // }
// //
// //
// // enum AppThemeMode { light, dark, system }
// //
// // class ThemeScreen extends StatefulWidget {
// //   const ThemeScreen({super.key});
// //
// //   @override
// //   State<ThemeScreen> createState() => _ThemeScreenState();
// // }
// //
// // class _ThemeScreenState extends State<ThemeScreen> {
// //   late String _tempSelectedTheme;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     // શરૂઆતમાં જે Hive માં હોય તે લોકલ સ્ટેટમાં લો
// //     _tempSelectedTheme = HiveService.themeMode;
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final colors = Theme.of(context).extension<AppThemeColors>()!;
// //
// //     return Scaffold(
// //       appBar: AppBar(
// //         elevation: 0,
// //         toolbarHeight: 80,
// //         // ✅ બેક બટન: ફક્ત પાછા જવા માટે
// //         leading: Padding(
// //           padding: const EdgeInsets.all(16),
// //           child: GestureDetector(
// //             onTap: () => Navigator.pop(context),
// //             child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20),
// //           ),
// //         ),
// //         title: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             AppText("Appearance", fontWeight: FontWeight.w600, fontSize: 20),
// //             AppText("Select app theme", fontSize: 13, color: colors.subTextColor.withOpacity(0.5)),
// //           ],
// //         ),
// //         actions: [
// //           // ✅ ડન બટન: અહીં સાચું લોજિક આવશે
// //           Padding(
// //             padding: const EdgeInsets.only(right: 16),
// //             child: GestureDetector(
// //               onTap: () {
// //                 // ૧. Bloc ને ઇવેન્ટ મોકલો (આ રન-ટાઇમ અપડેટ કરશે)
// //                 // અહીં આપણે Enum ની string વેલ્યુ પાસ કરીએ છીએ
// //                 context.read<ThemeBloc>().add(UpdateThemeMode(_tempSelectedTheme));
// //
// //                 // ૨. સક્સેસ ટોસ્ટ
// //                 AppToast.show(context, "Theme updated successfully", type: ToastType.success);
// //
// //                 // ૩. સ્ક્રીન બંધ કરો
// //                 Navigator.pop(context);
// //               },
// //               child: AppImage(
// //                   src: _tempSelectedTheme == HiveService.themeMode
// //                       ? AppSvg.doneUnSelect // જો કંઈ બદલાયું ના હોય
// //                       : AppSvg.doneSelect,   // જો બદલાયું હોય
// //                   height: 30,
// //                   width: 30
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //       body: SafeArea(
// //         child: Padding(
// //           padding: const EdgeInsets.symmetric(horizontal: 15),
// //           child: Column(
// //             children: [
// //               const SizedBox(height: 10),
// //               // Enum મુજબ જ 'light', 'dark', 'system' કી વાપરો
// //               _buildOption("Light Mode", "classicLight", AppThemeMode.light.name, Icons.wb_sunny_outlined, colors),
// //               _buildOption("Dark Mode", "modernDark", AppThemeMode.dark.name, Icons.nightlight_round_outlined, colors),
// //               _buildOption("System Default", "followDevice", AppThemeMode.system.name, Icons.settings_brightness_outlined, colors),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildOption(String title, String sub, String code, IconData icon, AppThemeColors colors) {
// //     bool isSelected = _tempSelectedTheme == code;
// //
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 8),
// //       child: GestureDetector(
// //         onTap: () {
// //           setState(() {
// //             _tempSelectedTheme = code; // ફક્ત લોકલ સ્ટેટ અપડેટ કરો
// //           });
// //         },
// //         child: Container(
// //           padding: const EdgeInsets.all(15),
// //           decoration: BoxDecoration(
// //             color: colors.cardBackground,
// //             borderRadius: BorderRadius.circular(12),
// //             border: Border.all(
// //               color: isSelected ? colors.primary : colors.textFieldBorder.withOpacity(0.2),
// //               width: isSelected ? 1.5 : 1,
// //             ),
// //           ),
// //           child: Row(
// //             children: [
// //               Icon(icon, color: isSelected ? colors.primary : colors.textFieldBorder),
// //               const SizedBox(width: 15),
// //               Expanded(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     AppText(title, fontSize: 16, fontWeight: FontWeight.w500),
// //                     AppText(sub, fontSize: 12, color: colors.subTextColor.withOpacity(0.6)),
// //                   ],
// //                 ),
// //               ),
// //               // Radio Button
// //               Container(
// //                 height: 20, width: 20,
// //                 decoration: BoxDecoration(
// //                   shape: BoxShape.circle,
// //                   border: Border.all(color: isSelected ? colors.primary : colors.textFieldBorder, width: 2),
// //                 ),
// //                 child: isSelected ? Center(child: CircleAvatar(radius: 5, backgroundColor: colors.primary)) : null,
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }