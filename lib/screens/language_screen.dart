import '../services/ads_service.dart';
import '../utils/app_imports.dart';

class LanguageScreen extends StatefulWidget {
  bool isSettingPage;

  LanguageScreen({super.key, this.isSettingPage = false});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? _selectedLangCode = "en";
  bool _isAdLoading = false;

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
    // Hive mathi saved language lo (je "system", "en", "gu" etc. hoi shake)
    _selectedLangCode = HiveService.languageCode;
    if (_selectedLangCode == null || _selectedLangCode!.isEmpty) {
      _selectedLangCode = "system";
    }
  }

  @override
  Widget build(BuildContext context) {
    final Box settingsBox = Hive.box('settings');
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return WillPopScope(
      onWillPop: () async {
        if (!widget.isSettingPage) {
          SystemNavigator.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, colors),
              const SizedBox(height: 8),
              _buildLanguageList(settingsBox, colors),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: AdHelper.bannerAdWidget(size: AdSize.banner),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeColors colors) {
    final Box settingsBox = Hive.box('settings');
    final previewStrings = AppStrings.translations[_selectedLangCode];
    final title = previewStrings?['chooseLanguage'] ?? "Choose Language";
    final subTitle =
        previewStrings?['selectPreferredLanguage'] ??
            "Select your preferred language";

    return Container(
      padding: const EdgeInsets.only(top: 0, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (widget.isSettingPage) ...[
                  Padding(
                    padding: const EdgeInsets.all(0),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: AppImage(
                        src: AppSvg.backArrowIcon,
                        height: 25,
                        width: 25,
                        color: colors.blackColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: AppText(
                          title,
                          key: ValueKey(title),
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 5),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: AppText(
                          subTitle,
                          key: ValueKey(subTitle),
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          maxLines: 2,
                          color: colors.subTextColor.withOpacity(0.50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap:
            _selectedLangCode == null ||
                _selectedLangCode == HiveService.languageCode
                ? () {
              if (!widget.isSettingPage) {
                settingsBox.put('isNewApp', false);
                _onTapDone();
                return;
              }
            }
                : () async {
              // Show loader while ad is loading
              setState(() => _isAdLoading = true);

              AdHelper.showInterstitialAd(() {
                _onTapDone();
              });

              // if (mounted) setState(() => _isAdLoading = false);
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: _isAdLoading
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: colors.primary,
                  strokeWidth: 2,
                ),
              )
                  : AppImage(
                key: ValueKey(_selectedLangCode),
                src:
                widget.isSettingPage &&
                    (_selectedLangCode == null ||
                        _selectedLangCode == HiveService.languageCode)
                    ? AppSvg.doneUnSelect
                    : AppSvg.doneSelect,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _onTapDone() {
    String finalToSave = _selectedLangCode!;
    Locale localeToSet;

    if (finalToSave == "system") {
      // 1. System ni current language get karo
      final String sysLang = PlatformDispatcher.instance.locale.languageCode;
      final List<String> supported = AppStrings.translations.keys.toList();

      // 2. Check karo support che ke nahi? Nahitar English.
      String effectiveLang = supported.contains(sysLang) ? sysLang : 'en';
      localeToSet = Locale(effectiveLang);
    } else {
      localeToSet = Locale(finalToSave);
    }

    // Hive ma "system" athva specific code save karo
    HiveService.saveLanguage(finalToSave);
    context.read<LocaleBloc>().add(ChangeLocale(localeToSet));

    AppToast.show(
      context,
      "${context.tr("languageSaved")}",
      type: ToastType.success,
    );

    if (!widget.isSettingPage) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      Navigator.pop(context);
    }
  }

  /// Language List
  Widget _buildLanguageList(Box settingsBox, AppThemeColors colors) {
    // 1. App ma supported languages
    final langCodes = AppStrings.translations.keys.toList();

    // 2. Mobile System ni current language
    final String systemLangCode =
        PlatformDispatcher.instance.locale.languageCode;

    // Check karo ke system language support ma che ke nahi
    final bool isSystemSupported = AppStrings.translations.containsKey(
      systemLangCode,
    );

    const int adInterval = 6;
    int totalCount = langCodes.length + (langCodes.length ~/ adInterval);

    return Expanded(
      child: Column(
        children: [
          if (!isSystemSupported)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1), // Light red background
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppText(
                      "${context.tr("yourSystemLanguage")} $systemLangCode ${context.tr("isNotSupported")}",
                      fontSize: 12,
                      color: Colors.red.shade700,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
              itemCount: totalCount,
              itemBuilder: (context, index) {
                // --- Ad Logic ---
                if (index != 0 && (index + 1) % (adInterval + 1) == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: AdHelper.bannerAdWidget(size: AdSize.largeBanner),
                  );
                }

                final int actualIndex = index - (index ~/ (adInterval + 1));
                if (actualIndex >= langCodes.length)
                  return const SizedBox.shrink();

                final String langCode = langCodes[actualIndex];
                final bool isSelected = _selectedLangCode == langCode;

                // --- Check karo ke aa system language che? ---
                final bool isSystemDefault = (langCode == systemLangCode);

                // Name and UI logic
                final langName =
                    AppStrings.translations[langCode]?['language'] ?? langCode;
                final langNameEnglish =
                    AppStrings.translations[langCode]?['languageName'] ?? '';

                String displayText = '$langName ($langNameEnglish)';
                if (isSystemDefault) {
                  displayText += " ${context.tr("systemDefaults")}";
                }
                print("$langCode");
                return TweenAnimationBuilder(
                  duration: Duration(milliseconds: 400 + (index * 80)),
                  tween: Tween<double>(begin: 0, end: 1),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7.5),
                    child: GestureDetector(
                      onTap: () => _onLanguageSelect(langCode, settingsBox),
                      // --- Selection Animation ---
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary.withOpacity(0.05)
                              : colors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: isSelected ? 1.5 : 1.0,
                            color: isSelected
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
                            Expanded(
                              child: AppText(
                                displayText,
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? colors.primary
                                    : colors.textFieldBorder,
                              ),
                            ),
                            AnimatedScale(
                              scale: isSelected ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: AppImage(
                                src: isSelected
                                    ? AppSvg.radioSelect
                                    : AppSvg.radioUnSelect,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onLanguageSelect(String langCode, Box settingsBox) {
    setState(() {
      _selectedLangCode = langCode;
    });
  }
}