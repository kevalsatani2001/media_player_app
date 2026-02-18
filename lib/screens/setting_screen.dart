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

                      Row(
                        children: [
                          Text('${AppStrings.get(context, 'language')}: '),
                          const SizedBox(width: 16),
                          DropdownButton<Locale>(
                            value: localeState.locale,
                            items: AppStrings.translations.keys.map((langCode) {
                              // get the display name of the language from translations
                              final langName =
                                  AppStrings.translations[langCode]?['language'] ??
                                      langCode;
                              return DropdownMenuItem<Locale>(
                                value: Locale(langCode),
                                child: Text(langName),
                              );
                            }).toList(),
                            onChanged: (locale) {
                              if (locale != null) {
                                context.read<LocaleBloc>().add(ChangeLocale(locale));
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      );
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
                  _buildSettingTab((){
                    showDialog(
                      context: context,
                      barrierDismissible: true, // set to false if you want to force a rating
                      builder: (context) => RatingDialog(
                        initialRating: 1.0,
                        // your app's name?
                        title:
                        Text(
                            context.tr('rateTheApp'),
                            textAlign: TextAlign.center,
                            style:TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.appBarTitleColor,
                              fontFamily: "Inter",
                            )
                        ),
                        // encourage your user to leave a high rating?
                        message:  Text(
                          'Tap a star to set your rating. Add more description here if you want.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: colors.appBarTitleColor,
                            fontFamily: "Inter",
                          ),
                        ),
                        // your app's logo?
                        submitButtonText: 'Submit',
                        commentHint: 'Set your custom comment hint',
                        onCancelled: () => print('cancelled'),
                        onSubmitted: (response) async{
                          print('rating: ${response.rating}, comment: ${response.comment}');

                          // TODO: add your own logic
                          if (response.rating < 3.0) {
                            // ઈમેલ માટેની વિગતો તૈયાર કરો
                            final Uri emailLaunchUri = Uri(
                              scheme: 'mailto',
                              path: 'your-email@example.com', // તમારી સપોર્ટ ઈમેલ આઈડી
                              queryParameters: {
                                'subject': 'App Feedback - Low Rating',
                                'body': 'Rating: ${response.rating}\nComment: ${response.comment}\n\n(Please tell us how we can improve!)',
                              },
                            );

                            // ઈમેલ એપ ખોલવાનો ટ્રાય કરો
                            if (await canLaunchUrl(emailLaunchUri)) {
                              await launchUrl(emailLaunchUri);
                            } else {
                              // જો ઈમેલ એપ ન ખુલે તો મેસેજ બતાવો
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open email app')),
                              );
                            }
                          } else {
                            _rateAndReviewApp();
                          }
                        },
                      ),
                    );
                  },"rateTheApp",AppSvg.rateAppIcon),
                  Divider(color: colors.dividerColor,),
                  _buildSettingTab((){},"privacyPolicy",AppSvg.privacyPolicyIcon),


                ],
              ),
            ),
          ),
          // const SizedBox(height: 20),
          // BlocBuilder<LocaleBloc, LocaleState>(
          //   builder: (context, localeState) {
          //     return Row(
          //       children: [
          //         Text('${AppStrings.get(context, 'language')}: '),
          //         const SizedBox(width: 16),
          //         DropdownButton<Locale>(
          //           value: localeState.locale,
          //           items: AppStrings.translations.keys.map((langCode) {
          //             // get the display name of the language from translations
          //             final langName =
          //                 AppStrings.translations[langCode]?['language'] ??
          //                     langCode;
          //             return DropdownMenuItem<Locale>(
          //               value: Locale(langCode),
          //               child: Text(langName),
          //             );
          //           }).toList(),
          //           onChanged: (locale) {
          //             if (locale != null) {
          //               context.read<LocaleBloc>().add(ChangeLocale(locale));
          //               setState(() {});
          //             }
          //           },
          //         ),
          //       ],
          //     );
          //   },
          // ),
        ],
      ),
    );
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
