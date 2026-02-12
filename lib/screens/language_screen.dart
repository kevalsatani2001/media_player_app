import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_player/screens/setting_screen.dart';
import 'package:media_player/widgets/image_widget.dart';
import 'package:media_player/widgets/text_widget.dart';

import '../blocs/local/local_bloc.dart';
import '../blocs/local/local_event.dart';
import '../core/constants.dart';
import '../services/hive_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_string.dart';

class LanguageScreen extends StatefulWidget {
  bool isSettingPage;

  LanguageScreen({super.key, this.isSettingPage = false});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? _selectedLangCode;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    final currentLocale = Localizations.localeOf(context);

    _selectedLangCode = currentLocale.languageCode;
  }

  @override
  void initState() {
    super.initState();
    _selectedLangCode = HiveService.languageCode ?? 'en';
  }


  @override
  Widget build(BuildContext context) {
    final Box settingsBox = Hive.box('settings');
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final loc = AppStrings(Localizations.localeOf(context));
    return Scaffold(
      // appBar: CommonAppBar(
      //   title: AppStrings.get(context, 'chooseLanguage'),
      // ),
      body: Column(
        children: [
          _buildHeader(context, colors),
          const SizedBox(height: 8),
          _buildLanguageList(settingsBox, colors),
        ],
      ),
    );
  }

  /// Header Section
  Widget _buildHeader(BuildContext context, AppThemeColors colors) {

    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  widget.isSettingPage ? context.tr("home") : "Select Language",
                  // AppStrings.get(context, 'chooseLanguage'),
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
                const SizedBox(height: 5),
                AppText(
                  AppStrings.get(context, 'selectPreferredLanguage'),
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: colors.subTextColor.withOpacity(0.50),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _selectedLangCode == null
                ? null
                : () {
                    !widget.isSettingPage
                        ? Navigator.pushReplacementNamed(context, '/onboarding')
                        : Navigator.pop(context);
                  },
            child: AppImage(
              src: _selectedLangCode == null
                  ? AppSvg.doneUnSelect
                  : AppSvg.doneSelect,
            ),
          ),
        ],
      ),
    );
  }

  /// Language List
  Widget _buildLanguageList(Box settingsBox, AppThemeColors colors) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        children: AppStrings.translations.keys.map((langCode) {
          final langName =
              AppStrings.translations[langCode]?['language'] ?? langCode;
          final langNameEnglish =
              AppStrings.translations[langCode]?['languageName'] ?? '';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7.5),
            child: GestureDetector(
              onTap: () => _onLanguageSelect(langCode, settingsBox),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedLangCode == langCode
                        ? colors.primary
                        : colors.textFieldBorder,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 15,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      '$langName ($langNameEnglish)',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.textFieldBorder,
                    ),
                    AppImage(
                      src: _selectedLangCode == langCode
                          ? AppSvg.radioSelect
                          : AppSvg.radioUnSelect,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Language Selection Logic
  void _onLanguageSelect(String langCode, Box settingsBox) {
    setState(() {
      _selectedLangCode = langCode;
    });

    // Save language
    settingsBox.put('setLocale', langCode);

    // Update locale immediately
    context.read<LocaleBloc>().add(ChangeLocale(Locale(langCode)));
  }
}
