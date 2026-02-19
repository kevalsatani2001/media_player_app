import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_player/screens/language_screen.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:rating_dialog/rating_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../blocs/local/local_bloc.dart';
import '../blocs/local/local_event.dart';
import '../blocs/local/local_state.dart';
import '../core/constants.dart';
import '../utils/app_colors.dart';
import '../utils/app_string.dart';
import '../widgets/app_bar.dart';
import '../widgets/image_widget.dart';
import 'package:in_app_review/in_app_review.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}
void _rateAndReviewApp() async {
  // refer to: https://pub.dev/packages/in_app_review
  final _inAppReview = InAppReview.instance;

  if (await _inAppReview.isAvailable()) {
    print('request actual review from store');
    _inAppReview.requestReview();
  } else {
    print('open actual store listing');
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
        CommonAppBar(
          title: "videMusicPlayer",
          subTitle: "mediaPlayer",
        ),
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
          // BlocBuilder<ThemeBloc, ThemeState>(
          //   builder: (context, themeState) {
          //     return ListTile(
          //       leading: Icon(Icons.light_mode,
          //         // themeState.isDark ? Icons.dark_mode : Icons.light_mode,
          //       ),
          //       title: Text(AppStrings.get(context, 'theme')),
          //       trailing: Switch(
          //         value: themeState.isDark,
          //         onChanged: (_) =>
          //             context.read<ThemeBloc>().add(ToggleTheme()),
          //       ),
          //     );
          //   },
          // ),
          AppText("settings",fontSize: 15,fontWeight: FontWeight.w500,color: colors.lightThemePrimary,),
          SizedBox(height: 10,),
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17.03),
                // color: colors.dividerColor,
                border: Border.all(width: 1.06,color: colors.dividerColor)
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Column(
                children: [
                  _buildSettingTab((){},"appTheme",AppSvg.appThemeIcon),
                  Divider(color: colors.dividerColor,),

                  BlocBuilder<LocaleBloc, LocaleState>(
                    builder: (context, localeState) {
                      return _buildSettingTab((){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>  LanguageScreen(isSettingPage: true),
                          ),
                        );
                      },"preferredLanguage",AppSvg.languageIcon);
                    },
                  ),



                ],
              ),
            ),
          ),
          SizedBox(height: 20,),
          AppText("Other Settings",fontSize: 15,fontWeight: FontWeight.w500,color: colors.lightThemePrimary,),
          SizedBox(height: 20,),
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17.03),
                // color: colors.dividerColor,
                border: Border.all(width: 1.06,color: colors.dividerColor)
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Column(
                children: [
                  _buildSettingTab((){
                    shareApp();
                  },"shareTheApp",AppSvg.shareAppIcon),
                  Divider(color: colors.dividerColor,),
                  _buildSettingTab(() {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => _buildCustomRatingDialog(context),
                    );
                  }, "rateTheApp", AppSvg.rateAppIcon),
                  Divider(color: colors.dividerColor,),
                  _buildSettingTab((){},"privacyPolicy",AppSvg.privacyPolicyIcon),


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

    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        backgroundColor: colors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // એપ આઈકોન અથવા રેટિંગ આઈકોન
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.star_rounded, color: colors.primary, size: 40),
            ),
            const SizedBox(height: 20),
            // ટાઇટલ
            AppText(
              context.tr('rateTheApp'),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.appBarTitleColor,
            ),
            const SizedBox(height: 10),
            // મેસેજ
            AppText(
              "Tap a star to set your rating.",
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colors.secondaryText,
              align: TextAlign.center,
            ),
            const SizedBox(height: 25),
            // સ્ટાર્સ (Rating Stars)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() => currentRating = index + 1.0);
                  },
                  child: Icon(
                    index < currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < currentRating ? Colors.amber : colors.dividerColor,
                    size: 45,
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            // બટન્સ
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
                        child: AppText("Cancel", fontSize: 16, color: colors.secondaryText),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context); // ડાયલોગ બંધ કરો

                      if (currentRating < 3.0) {
                        // લો-રેટિંગ માટે ઈમેલ લોજિક
                        _launchEmailFeedback(currentRating);
                      } else {
                        // હાઈ-રેટિંગ માટે સ્ટોર રિવ્યુ
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
                        child: AppText("Submit", fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    });
  }

// ઈમેલ લોન્ચ કરવા માટેનું ફંક્શન
  void _launchEmailFeedback(double rating) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'your-email@example.com',
      queryParameters: {
        'subject': 'App Feedback - $rating Stars',
        'body': 'Hi, I gave $rating stars. Here is my feedback:\n\n',
      },
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  void shareApp() {
    const String appMessage =
        "Check out this amazing Video & Music Player app! 🎶🎬\n\n"
        "Download it now from Play Store:\n"
        "https://play.google.com/store/apps/details?id=your.package.name";

    // Share.share ફંક્શન સિસ્ટમ ડાયલોગ ઓપન કરશે
    Share.share(appMessage, subject: 'Download Media Player');
  }

  Widget _buildSettingTab(void Function()? onTap, String title, String icon) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AppImage(src:icon),
                SizedBox(width: 15,),
                AppText(title,fontSize: 15,fontWeight: FontWeight.w400,color: colors.secondaryText,)
              ],
            ),
            AppImage(src: AppSvg.rightArrow)
          ],
        ),
      ),
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
