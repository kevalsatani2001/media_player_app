import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:media_player/core/constants.dart';
import 'package:media_player/screens/setting_screen.dart';
import 'package:media_player/widgets/app_button.dart';
import 'package:media_player/widgets/image_widget.dart';
import 'package:media_player/widgets/text_widget.dart';

import '../services/ads_service.dart';
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
        'image':AppSvg.icOnboarding1,
        'title': context.tr("watchWithoutLimits"),
        'subtitle': context.tr("smoothPlayback"),
      },
      {
        'image':AppSvg.icOnboarding2,
        'title': context.tr("yourUltimateMediaHub"),
        // 'title': AppStrings.get(context, 'video'),
        'subtitle': context.tr("enjoyVideosMusic"),
      },
      {
        'image':AppSvg.icOnboarding3,
        'title': context.tr("instantPlayback"),
        // 'title': AppStrings.get(context, 'audio'),
        'subtitle': context.tr("enjoyUltraHDVideos"),
      },
      {
        'image':AppSvg.icOnboarding4,
        'title': context.tr("wtachPlayEnjoy"),
        // 'title': AppStrings.get(context, 'organize'),
        'subtitle': context.tr("smoothPlaybackForEvery"),
      },
    ];
    return WillPopScope(
      onWillPop: () async{
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
                      // mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            height: 299,
                            child: AppImage(src: page['image']!,fit: BoxFit.contain,)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 34),
                          child: AppText(
                            page['title']!,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            align: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 58),
                          child: AppText(
                            page['subtitle']!,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            align: TextAlign.center,
                            color: colors.textFieldBorder,
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
                  child: TextButton(
                    onPressed: _finishOnboarding,
                    child: AppText('skip', color: colors.primary),
                  ),
                ),

              /// ---------------- DOTS + BUTTON ----------------
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

                      const SizedBox(width: 20), // જગ્યા થોડી ઓછી કરી છે જેથી રિસ્પોન્સિવ રહે

                      /// Next / Done Button
                      // અહી ConstrainedBox અથવા ફક્ત width કાઢી નાખવાથી બટન ટેક્સ્ટ મુજબ સાઈઝ લેશે
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 85, // ઓછામાં ઓછી આટલી વિડ્થ
                        ),
                        child: IntrinsicWidth(
                          child: AppButton(
                            height: 40, // હાઈટ થોડી વધારી છે જેથી ગુજરાતી જેવા ફોન્ટ પ્રોપર સમાય
                            // width: null, // જો તમારા વિજેટમાં width ઓપ્શનલ હોય તો null આપો અથવા કાઢી નાખો
                            // padding: const EdgeInsets.symmetric(horizontal: 20), // સાઈડમાં જગ્યા આપો
                            title: _currentPage == _pages.length - 1
                                ? context.tr("done") // Localization વાપરવું
                                : context.tr("next"),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFontFamily.roboto,
                            borderRadius: 50,
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
