import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:media_player/core/constants.dart';
import 'package:media_player/widgets/app_button.dart';
import 'package:media_player/widgets/image_widget.dart';
import 'package:media_player/widgets/text_widget.dart';

import '../utils/app_colors.dart';
import '../utils/app_string.dart';

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
        'title': 'Scan QR Codes Instantly',
        // 'title': AppStrings.get(context, 'welcome'),
        'subtitle':
            'Use your camera to scan QR codes and unlock info instantly.',
      },
      {
        'title': 'Scan QR Codes Instantly',
        // 'title': AppStrings.get(context, 'video'),
        'subtitle':
            'Use your camera to scan QR codes and unlock info instantly.',
      },
      {
        'title': 'Scan QR Codes Instantly',
        // 'title': AppStrings.get(context, 'audio'),
        'subtitle':
            'Use your camera to scan QR codes and unlock info instantly.',
      },
      {
        'title': 'Scan QR Codes Instantly',
        // 'title': AppStrings.get(context, 'organize'),
        'subtitle':
            'Use your camera to scan QR codes and unlock info instantly.',
      },
    ];
    return Scaffold(
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        page['title']!,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        align: TextAlign.center,
                      ),
                      const SizedBox(height: 11),
                      AppText(
                        page['subtitle']!,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        align: TextAlign.center,
                        color: colors.textFieldBorder,
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
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: AppText('Skip', color: colors.primary),
                ),
              ),

            /// ---------------- DOTS + BUTTON ----------------
            Padding(
              padding: const EdgeInsets.only(top: 170),
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
                          curve: Curves.easeInOut,
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

                    const SizedBox(width: 47),

                    /// Next / Done Button
                    AppButton(
                      height: 34,
                      width: 85,
                      title: _currentPage == _pages.length - 1
                          ? 'Done'
                          : 'Next',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFontFamily.roboto,
                      borderRadius: 50,
                      onTap: _nextPage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
