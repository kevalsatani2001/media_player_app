// import 'package:media_player/screens/privacy_poimport '
import 'package:media_player/screens/privacy_policy_screen.dart';
// package:media_player/screens/privacy_policy_screen.dart';

import '../services/ads_service.dart';
import '../utils/app_imports.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final GlobalPlayer player = GlobalPlayer();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (player.currentType == "video" && player.isPlaying) {
        player.pause();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return  Column(
      children: [
        CommonAppBar(title: "videMusicPlayer", subTitle: "mediaPlayer"),
        Divider(color: colors.dividerColor),
        Expanded(child: _buildSettingsTab()),
      ],
    );
  }

  Widget _buildSettingsTab() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return SingleChildScrollView( // ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â¢ Scrollable rakho jethi nani screen ma ad dhankay nahi
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdHelper.adaptiveBannerWidget(context),
          const SizedBox(height: 15),

          AppText(
            "settings",
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: colors.lightThemePrimary,
          ),
          const SizedBox(height: 10),

          // --- First Settings Box (Theme/Language) ---
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17.03),
              border: Border.all(width: 1.06, color: colors.dividerColor),
            ),
            child: Column(
              children: [
                _buildSettingTab(() {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ThemeScreen()));
                }, "appTheme", AppSvg.appThemeIcon, 0),
                Divider(color: colors.dividerColor),
                BlocBuilder<LocaleBloc, LocaleState>(
                  builder: (context, localeState) {
                    return _buildSettingTab(() {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => LanguageScreen(isSettingPage: true)));
                    }, "preferredLanguage", AppSvg.languageIcon, 1);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AdHelper.bannerAdWidget(size: AdSize.mediumRectangle),
            ),
          ),
          const SizedBox(height: 25),

          AppText(
            "otherSettings",
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: colors.lightThemePrimary,
          ),
          const SizedBox(height: 15),

          // --- Second Settings Box (Share/Rate/Privacy) ---
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17.03),
              border: Border.all(width: 1.06, color: colors.dividerColor),
            ),
            child: Column(
              children: [
                _buildSettingTab(() => shareApp(), "shareTheApp", AppSvg.shareAppIcon, 2),
                Divider(color: colors.dividerColor),
                _buildSettingTab(() {
                  showDialog(context: context, builder: (context) => _buildCustomRatingDialog(context));
                }, "rateTheApp", AppSvg.rateAppIcon, 3),
                Divider(color: colors.dividerColor),
                _buildSettingTab(() {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyPolicyScreen()));
                }, "privacyPolicy", AppSvg.privacyPolicyIcon, 4),
              ],
            ),
          ),

          const SizedBox(height: 100), // Bottom MiniPlayer mate space
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
          backgroundColor: colors.dropdownBg,
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
                      double starWidth = 40;
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
        "${context.tr("checkOutThisAmazing")}\n\n"
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
              AppImage(src: AppSvg.rightArrow,color: colors.blackColor,),
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
      icon = AppImage(src: AppSvg.starFill, width: 40);
    } else if (diff >= 0.50) {
      icon = AppImage(src: AppSvg.starHalf, width: 40);
    } else if (diff >= 0.25) {
      icon = AppImage(src: AppSvg.starHalfHalf, width: 40);
    } else {
      icon = AppImage(src: AppSvg.startEmpty, width: 40);
    }

    bool isSelected = rating >= starIndex - 0.75;

    return AnimatedScale(
      scale: isSelected ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.elasticOut,
      child: icon,
    );
  }
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

extension LocalizationExtension on BuildContext {
  String tr(String key) {
    final locale = Localizations.localeOf(this).languageCode;
    return AppStrings.translations[locale]?[key] ??
        AppStrings.translations['en']![key] ??
        key;
  }
}

enum AppThemeMode { light, dark}

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
    final isDark = _tempSelectedTheme == AppThemeMode.dark.name;

    final previewTheme = isDark ? AppTheme.dark() : AppTheme.light();

    return Theme(
      data: previewTheme,
      child: Builder(
        builder: (context) {
          final colors = Theme.of(context).extension<AppThemeColors>()!;

          return Scaffold(
            // backgroundColor: colors.scaffoldBackground,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, colors),
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

                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        AppText(
                          "Advertisement",
                          fontSize: 10,
                          color: colors.subTextColor.withOpacity(0.4),
                        ),
                        const SizedBox(height: 5),
                        KeyedSubtree(
                          key: ValueKey(_tempSelectedTheme),
                          child: AdHelper.bannerAdWidget(size: AdSize.mediumRectangle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  bool _isAdLoading = false;
  Widget _buildHeader(BuildContext context, AppThemeColors colors) {

    return Container(
      padding: const EdgeInsets.only(top: 0, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: AppText(
                          "appearance",
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 5),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: AppText(
                          "selectAppTheme",
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
            onTap: _tempSelectedTheme == HiveService.themeMode
                ? null
                : () async {
              setState(() => _isAdLoading = true);
              AdHelper.showInterstitialAd(() {
                context.read<ThemeBloc>().add(UpdateThemeMode(_tempSelectedTheme));

                AppToast.show(
                  context,
                  "${context.tr("themeUpdatesSuccessfully")}",
                  type: ToastType.success,
                );
                Navigator.pop(context);
              });

              // if (mounted) setState(() => _isAdLoading = false); // stop loader
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
                src: _tempSelectedTheme == HiveService.themeMode
                    ? AppSvg.doneUnSelect
                    : AppSvg.doneSelect,
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 15),
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