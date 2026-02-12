import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../core/constants.dart';
import '../utils/app_colors.dart';
import '../widgets/image_widget.dart';
import '../widgets/text_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final Box settingsBox = Hive.box('settings');

  /// typing animation (TEXT ONLY)
  final String _fullText = 'Media Player';
  String _visibleText = '';
  int _index = 0;
  Timer? _timer;
  late AnimationController _sliderController;
  late Animation<double> _sliderAnimation;

  @override
  void initState() {
    super.initState();

    _startTyping();

    _sliderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _sliderAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_sliderController)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              navigateNext(); // 🚀 CALL AFTER SLIDER COMPLETES
            }
          });

    _sliderController.forward(); // start animation
  }

  void _startTyping() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_index < _fullText.length) {
        setState(() {
          _visibleText += _fullText[_index];
          _index++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> navigateNext() async {
    await Future.delayed(const Duration(seconds: 0));

    // Navigator.pushReplacementNamed(context, '/language');
    // return;
    final selectedLang = settingsBox.get('setLocale');
    if (selectedLang == null) {
      Navigator.pushReplacementNamed(context, '/language');
    } else {
      final seenOnboarding = settingsBox.get(
        'seenOnboarding',
        defaultValue: false,
      );
      if (!seenOnboarding) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sliderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(),
            Center(child: AppImage(src: AppSvg.appLogo, height: 120)),

            /// 🔹 Animated text ONLY
            Padding(
              padding: const EdgeInsets.only(top: 13),
              child: AppText(
                _visibleText,
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
                align: TextAlign.center,
              ),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: SizedBox(
                width: 200,
                child: AnimatedBuilder(
                  animation: _sliderAnimation,
                  builder: (context, child) {
                    return SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,

                        // hide thumb
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 0,
                          disabledThumbRadius: 0,
                        ),
                        overlayShape: SliderComponentShape.noOverlay,

                        /// ⭐ IMPORTANT PART
                        disabledActiveTrackColor: colors.primary,
                        disabledInactiveTrackColor: colors.primary.withOpacity(
                          0.5,
                        ),
                      ),
                      child: Slider(
                        value: _sliderAnimation.value,
                        min: 0,
                        max: 1,
                        onChanged: null, // keep disabled (auto animation only)
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}