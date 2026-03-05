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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, colors),
            const SizedBox(height: 8),
            _buildLanguageList(settingsBox, colors),
          ],
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
            onTap: _selectedLangCode == null
                ? null
                : () {
              // --- Ã Âªâ€¦Ã ÂªÂ¹Ã Â«â‚¬Ã Âªâ€š Ã Âªâ€ Ã Âªâ€“Ã Â«â‚¬ Ã ÂªÂÃ ÂªÂª Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡ Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÂµ Ã ÂªÂ¥Ã ÂªÂ¶Ã Â«â€¡ ---
              HiveService.languageCode = _selectedLangCode!;
              context.read<LocaleBloc>().add(
                ChangeLocale(Locale(_selectedLangCode!)),
              );

              // Ã¢Å“â€¦ Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÂµ Ã ÂªÂ¥Ã ÂªÂ¯Ã ÂªÂ¾ Ã ÂªÂªÃ Âªâ€ºÃ Â«â‚¬ Ã ÂªÅ¸Ã Â«â€¹Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸
              AppToast.show(
                context,
                "${context.tr("languageSaved")}",
                type: ToastType.success,
              );

              !widget.isSettingPage
                  ? Navigator.pushReplacementNamed(context, '/onboarding')
                  : Navigator.pop(context);
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

  /// Language List
  Widget _buildLanguageList(Box settingsBox, AppThemeColors colors) {
    final langCodes = AppStrings.translations.keys
        .toList();

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        itemCount: langCodes.length,
        itemBuilder: (context, index) {
          final langCode = langCodes[index];
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
"renamePlaylist_ar":"Ø¥Ø¹Ø§Ø¯Ø© ØªØ³Ù…ÙŠØ© Ù‚Ø§Ø¦Ù…Ø© Ø§Ù„ØªØ´ØºÙŠÙ„",
"renamePlaylist_my":"á€•á€œá€±á€¸á€œá€…á€ºá€¡á€™á€Šá€ºá€•á€¼á€±á€¬á€„á€ºá€¸á€›á€”á€º",
"renamePlaylist_fil":"Palitan ang pangalan ng Playlist",
"renamePlaylist_fr":"Renommer la liste de lecture",
"renamePlaylist_de":"Playlist umbenennen",
"renamePlaylist_gu":"àªªà«àª²à«‡àª²àª¿àª¸à«àªŸàª¨à«àª‚ àª¨àª¾àª® àª¬àª¦àª²à«‹",
"renamePlaylist_hi":"à¤ªà¥à¤²à¥‡à¤²à¤¿à¤¸à¥à¤Ÿ à¤•à¤¾ à¤¨à¤¾à¤® à¤¬à¤¦à¤²à¥‡à¤‚",
"renamePlaylist_id":"Ubah Nama Daftar Putar",
"renamePlaylist_it":"Rinomina playlist",
"renamePlaylist_ja":"ãƒ—ãƒ¬ã‚¤ãƒªã‚¹ãƒˆåã‚’å¤‰æ›´",
"renamePlaylist_ko":"ìž¬ìƒëª©ë¡ ì´ë¦„ ë°”ê¾¸ê¸°",
"renamePlaylist_ms":"Namakan semula Senarai Main",
"renamePlaylist_mr":"à¤ªà¥à¤²à¥‡à¤²à¤¿à¤¸à¥à¤Ÿà¤šà¥‡ à¤¨à¤¾à¤µ à¤¬à¤¦à¤²à¤¾",
"renamePlaylist_fa":"ØªØºÛŒÛŒØ± Ù†Ø§Ù… Ù„ÛŒØ³Øª Ù¾Ø®Ø´",
"renamePlaylist_pl":"ZmieÅ„ nazwÄ™ playlisty",
"renamePlaylist_pt":"Renomear Playlist",
"renamePlaylist_es":"Cambiar nombre de la lista",
"renamePlaylist_sv":"Byt namn pÃ¥ spellista",
"renamePlaylist_ta":"à®ªà®¿à®³à¯‡àª²à«€à®¸à¯à®Ÿà¯à®Ÿà¯ˆ à®®à®±à¯à®ªà¯†à®¯à®°à®¿à®Ÿà¯",
"renamePlaylist_ur":"Ù¾Ù„Û’ Ù„Ø³Ù¹ Ú©Ø§ Ù†Ø§Ù… ØªØ¨Ø¯ÛŒÙ„ Ú©Ø±ÛŒÚº"
 */