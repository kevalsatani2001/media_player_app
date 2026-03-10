import '../services/ads_service.dart';
import '../utils/app_imports.dart';

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
    _selectedLangCode = HiveService.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final Box settingsBox = Hive.box('settings');
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return WillPopScope(
      onWillPop: () async{
        if(!widget.isSettingPage){
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
              // âœ¨ Sticky Banner Ad
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
            // _buildHeader àª¨à«€ àª…àª‚àª¦àª° GestureDetector àª¨àª¾ onTap àª®àª¾àª‚:
            onTap: _selectedLangCode == null
                ? null
                : () {
              // --- Interstitial Ad àª²à«‹àªœàª¿àª• ---
              if(widget.isSettingPage){
                AdHelper.showInterstitialAd((){_onTapDone();});
              }else{
                _onTapDone();
              }

            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: AppImage(
                key: ValueKey(_selectedLangCode),
                src: _selectedLangCode == null
                    ? AppSvg.doneUnSelect
                    : AppSvg.doneSelect,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _onTapDone(){
    // àª† àª•à«‹àª¡ àªàª¡ àª¬àª‚àª§ àª¥àª¯àª¾ àªªàª›à«€ àªœ àª°àª¨ àª¥àª¶à«‡
    HiveService.languageCode = _selectedLangCode!;
    context.read<LocaleBloc>().add(
      ChangeLocale(Locale(_selectedLangCode!)),
    );

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
    final langCodes = AppStrings.translations.keys
        .toList();
    const int adInterval = 6; // àª¦àª° 6 àª­àª¾àª·àª¾ àªªàª›à«€ àªàª• àªàª¡

    int totalCount = langCodes.length + (langCodes.length ~/ adInterval);

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          // àªàª¡ àªªà«‹àªàª¿àª¶àª¨ àªšà«‡àª•
          if (index != 0 && (index + 1) % (adInterval + 1) == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AdHelper.bannerAdWidget(size: AdSize.largeBanner),
            );
          }

          // àª¸àª¾àªšà«‹ àª¡à«‡àªŸàª¾ àª‡àª¨à«àª¡à«‡àª•à«àª¸
          final int actualIndex = index - (index ~/ (adInterval + 1));
          if (actualIndex >= langCodes.length) return const SizedBox.shrink();

          final langCode = langCodes[actualIndex];
          final langName =
              AppStrings.translations[langCode]?['language'] ?? langCode;
          final langNameEnglish =
              AppStrings.translations[langCode]?['languageName'] ?? '';
          final isSelected = _selectedLangCode == langCode;
          print(langCode);
          // --- Entrance Animation ---
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
                      AppText(
                        '$langName ($langNameEnglish)',
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? colors.primary
                            : colors.textFieldBorder,
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
    );
  }

  void _onLanguageSelect(String langCode, Box settingsBox) {
    setState(() {
      _selectedLangCode = langCode;

    });
  }
}

/*
"renamePlaylist_en":"Rename Playlist",
"renamePlaylist_ar":"Ã˜Â¥Ã˜Â¹Ã˜Â§Ã˜Â¯Ã˜Â© Ã˜ÂªÃ˜Â³Ã™â€¦Ã™Å Ã˜Â© Ã™â€šÃ˜Â§Ã˜Â¦Ã™â€¦Ã˜Â© Ã˜Â§Ã™â€žÃ˜ÂªÃ˜Â´Ã˜ÂºÃ™Å Ã™â€ž",
"renamePlaylist_my":"Ã¡â‚¬â€¢Ã¡â‚¬Å“Ã¡â‚¬Â±Ã¡â‚¬Â¸Ã¡â‚¬Å“Ã¡â‚¬â€¦Ã¡â‚¬ÂºÃ¡â‚¬Â¡Ã¡â‚¬â„¢Ã¡â‚¬Å Ã¡â‚¬ÂºÃ¡â‚¬â€¢Ã¡â‚¬Â¼Ã¡â‚¬Â±Ã¡â‚¬Â¬Ã¡â‚¬â€žÃ¡â‚¬ÂºÃ¡â‚¬Â¸Ã¡â‚¬â€ºÃ¡â‚¬â€Ã¡â‚¬Âº",
"renamePlaylist_fil":"Palitan ang pangalan ng Playlist",
"renamePlaylist_fr":"Renommer la liste de lecture",
"renamePlaylist_de":"Playlist umbenennen",
"renamePlaylist_gu":"Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ¨Ã Â«ÂÃ Âªâ€š Ã ÂªÂ¨Ã ÂªÂ¾Ã ÂªÂ® Ã ÂªÂ¬Ã ÂªÂ¦Ã ÂªÂ²Ã Â«â€¹",
"renamePlaylist_hi":"Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â²Ã Â¥â€¡Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸ Ã Â¤â€¢Ã Â¤Â¾ Ã Â¤Â¨Ã Â¤Â¾Ã Â¤Â® Ã Â¤Â¬Ã Â¤Â¦Ã Â¤Â²Ã Â¥â€¡Ã Â¤â€š",
"renamePlaylist_id":"Ubah Nama Daftar Putar",
"renamePlaylist_it":"Rinomina playlist",
"renamePlaylist_ja":"Ã£Æ’â€”Ã£Æ’Â¬Ã£â€šÂ¤Ã£Æ’ÂªÃ£â€šÂ¹Ã£Æ’Ë†Ã¥ÂÂÃ£â€šâ€™Ã¥Â¤â€°Ã¦â€ºÂ´",
"renamePlaylist_ko":"Ã¬Å¾Â¬Ã¬Æ’ÂÃ«ÂªÂ©Ã«Â¡Â Ã¬ÂÂ´Ã«Â¦â€ž Ã«Â°â€ÃªÂ¾Â¸ÃªÂ¸Â°",
"renamePlaylist_ms":"Namakan semula Senarai Main",
"renamePlaylist_mr":"Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â²Ã Â¥â€¡Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¤Å¡Ã Â¥â€¡ Ã Â¤Â¨Ã Â¤Â¾Ã Â¤Âµ Ã Â¤Â¬Ã Â¤Â¦Ã Â¤Â²Ã Â¤Â¾",
"renamePlaylist_fa":"Ã˜ÂªÃ˜ÂºÃ›Å’Ã›Å’Ã˜Â± Ã™â€ Ã˜Â§Ã™â€¦ Ã™â€žÃ›Å’Ã˜Â³Ã˜Âª Ã™Â¾Ã˜Â®Ã˜Â´",
"renamePlaylist_pl":"ZmieÃ…â€ž nazwÃ„â„¢ playlisty",
"renamePlaylist_pt":"Renomear Playlist",
"renamePlaylist_es":"Cambiar nombre de la lista",
"renamePlaylist_sv":"Byt namn pÃƒÂ¥ spellista",
"renamePlaylist_ta":"Ã Â®ÂªÃ Â®Â¿Ã Â®Â³Ã Â¯â€¡Ã ÂªÂ²Ã Â«â‚¬Ã Â®Â¸Ã Â¯ÂÃ Â®Å¸Ã Â¯ÂÃ Â®Å¸Ã Â¯Ë† Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®ÂªÃ Â¯â€ Ã Â®Â¯Ã Â®Â°Ã Â®Â¿Ã Â®Å¸Ã Â¯Â",
"renamePlaylist_ur":"Ã™Â¾Ã™â€žÃ›â€™ Ã™â€žÃ˜Â³Ã™Â¹ ÃšÂ©Ã˜Â§ Ã™â€ Ã˜Â§Ã™â€¦ Ã˜ÂªÃ˜Â¨Ã˜Â¯Ã›Å’Ã™â€ž ÃšÂ©Ã˜Â±Ã›Å’ÃšÂº"
 */