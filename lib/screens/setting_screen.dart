import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_player/screens/language_screen.dart';
import 'package:media_player/widgets/text_widget.dart';

import '../blocs/local/local_bloc.dart';
import '../blocs/local/local_event.dart';
import '../blocs/local/local_state.dart';
import '../core/constants.dart';
import '../utils/app_colors.dart';
import '../utils/app_string.dart';
import '../widgets/app_bar.dart';
import '../widgets/image_widget.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Column(
      children: [
        CommonAppBar(
          title: "Video & Music Player",
          subTitle: "MEDIA PLAYER",
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
          AppText("Settings",fontSize: 15,fontWeight: FontWeight.w500,color: colors.lightThemePrimary,),
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
                   _buildSettingTab((){},"App Theme",AppSvg.appThemeIcon),
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
                      },"Preferred Language",AppSvg.languageIcon);

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
                  _buildSettingTab((){},"Share the App",AppSvg.shareAppIcon),
                  Divider(color: colors.dividerColor,),
                  _buildSettingTab((){},"Rate the App",AppSvg.rateAppIcon),
                  Divider(color: colors.dividerColor,),
                  _buildSettingTab((){},"Privacy Policy",AppSvg.privacyPolicyIcon),


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
