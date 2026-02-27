import '../utils/app_imports.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  final Box settingsBox = Hive.box('settings');

  int _currentPage = 0;

  late List<Map<String, String>> _pages = [];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    settingsBox.put('seenOnboarding', true);
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    _pages = [
      {
        'image': AppSvg.icOnboarding1,
        'title': context.tr("watchWithoutLimits"),
        'subtitle': context.tr("smoothPlayback"),
      },
      {
        'image': AppSvg.icOnboarding2,
        'title': context.tr("yourUltimateMediaHub"),
        'subtitle': context.tr("enjoyVideosMusic"),
      },
      {
        'image': AppSvg.icOnboarding3,
        'title': context.tr("instantPlayback"),
        'subtitle': context.tr("enjoyUltraHDVideos"),
      },
      {
        'image': AppSvg.icOnboarding4,
        'title': context.tr("wtachPlayEnjoy"),
        'subtitle': context.tr("smoothPlaybackForEvery"),
      },
    ];
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              /// ---------------- PAGE VIEW ----------------
              PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];

                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(AppSvg.introBackground),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 299,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: AppImage(
                              key: ValueKey(page['image']),
                              // àª•à«€ àª†àªªàªµàª¾àª¥à«€ àªàª¨àª¿àª®à«‡àª¶àª¨ àª¥àª¶à«‡
                              src: page['image']!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 34),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: AppText(
                              page['title']!,
                              key: ValueKey(page['title']),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              align: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 11),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 58),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: AppText(
                              page['subtitle']!,
                              key: ValueKey(page['subtitle']),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              align: TextAlign.center,
                              color: colors.textFieldBorder,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              /// ---------------- SKIP BUTTON ----------------
              if (_currentPage != _pages.length - 1)
                Align(
                  alignment: Alignment.topRight,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _currentPage == _pages.length - 1 ? 0.0 : 1.0,
                    child: TextButton(
                      onPressed: _currentPage == _pages.length - 1
                          ? null
                          : _finishOnboarding,
                      child: AppText('skip', color: colors.primary),
                    ),
                  ),
                ),

              /// ---------------- DOTS + BUTTON ----------------
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// Dots Indicator
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _pages.length,
                              (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == i ? 32 : 18,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? colors.primary
                                  : colors.textFieldBorder.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(37),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),


                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 85, // àª“àª›àª¾àª®àª¾àª‚ àª“àª›à«€ àª†àªŸàª²à«€ àªµàª¿àª¡à«àª¥
                        ),
                        child: IntrinsicWidth(
                          child: AppButton(
                            height: 40,
                            title: _currentPage == _pages.length - 1
                                ? context.tr("done")
                                : context.tr("next"),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFontFamily.roboto,
                            borderRadius: 50,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: AppText(
                                _currentPage == _pages.length - 1
                                    ? context.tr("done")
                                    : context.tr("next"),
                                key: ValueKey(_currentPage),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            onTap: _nextPage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}