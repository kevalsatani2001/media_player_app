import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../core/constants.dart';
import '../services/ads_service.dart';
import '../utils/app_imports.dart'; // Tamari badhi files aama hase j

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final Box settingsBox = Hive.box('settings');

  final String _fullText = 'Media Player';
  String _visibleText = '';
  int _index = 0;
  Timer? _timer;
  late AnimationController _sliderController;
  late Animation<double> _sliderAnimation;

  @override
  void initState() {
    super.initState();

    // ðŸŸ¢ 1. Background ma Ad load àª•àª°àªµàª¾àª¨à«àª‚ àªšàª¾àª²à« àª•àª°à«‹
    AdHelper.loadAppOpenAd();

    _startTyping();

    _sliderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _sliderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_sliderController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // ðŸš€ Slider àªªàª¤à«àª¯àª¾ àªªàª›à«€ Ad àª¬àª¤àª¾àªµà«‹ àª…àª¨à«‡ àªªàª›à«€ Navigate àª•àª°à«‹
          _showAdAndNavigate();
        }
      });

    _sliderController.forward();
  }

  // ðŸŸ¢ 2. Ad àª¬àª¤àª¾àªµà«€àª¨à«‡ àªªàª›à«€ àª†àª—àª³ àªµàª§àªµàª¾àª¨à«àª‚ Logic
  void _showAdAndNavigate() {
    // AdHelper ma jaine check karo ke ad ready che?
    // Jo hoy to batavo, dismiss thaya pachi navigate thase.
    AdHelper.showAppOpenAdIfAvailable();

    // Ad show thava mate thodo samay apiye jethi AppOpenAd handle kari shake
    Future.delayed(const Duration(milliseconds: 500), () {
      navigateNext();
    });
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
    // Jo AppOpenAd screen par chalti hoy (isShowingAd), to navigate na karo
    // Pan apane safer side mate 1 second delayed navigation rakhiye

    final selectedLang = settingsBox.get('languageCode');
    String route;

    if (selectedLang == null) {
      route = '/language';
    } else {
      final seenOnboarding = settingsBox.get('seenOnboarding', defaultValue: false);
      route = !seenOnboarding ? '/onboarding' : '/';
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, route);
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
          children: [
            const Spacer(),
            Center(child: AppImage(src: AppSvg.appLogo, height: 120)),
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
            const Spacer(),
            // Slider UI jem che tem j...
            _buildSlider(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: SizedBox(
        width: 200,
        child: AnimatedBuilder(
          animation: _sliderAnimation,
          builder: (context, child) {
            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                overlayShape: SliderComponentShape.noOverlay,
                disabledActiveTrackColor: colors.primary,
                disabledInactiveTrackColor: colors.primary.withOpacity(0.5),
              ),
              child: Slider(value: _sliderAnimation.value, onChanged: null),
            );
          },
        ),
      ),
    );
  }
}











// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
//
// import '../core/constants.dart';
// import '../utils/app_colors.dart';
// import '../widgets/image_widget.dart';
// import '../widgets/text_widget.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   final Box settingsBox = Hive.box('settings');
//
//   /// typing animation (TEXT ONLY)
//   final String _fullText = 'Media Player';
//   String _visibleText = '';
//   int _index = 0;
//   Timer? _timer;
//   late AnimationController _sliderController;
//   late Animation<double> _sliderAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _startTyping();
//
//     _sliderController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     );
//
//     _sliderAnimation =
//         Tween<double>(begin: 0.0, end: 1.0).animate(_sliderController)
//           ..addStatusListener((status) {
//             if (status == AnimationStatus.completed) {
//               navigateNext(); // 🚀 CALL AFTER SLIDER COMPLETES
//             }
//           });
//
//     _sliderController.forward(); // start animation
//   }
//
//   void _startTyping() {
//     _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
//       if (_index < _fullText.length) {
//         setState(() {
//           _visibleText += _fullText[_index];
//           _index++;
//         });
//       } else {
//         timer.cancel();
//       }
//     });
//   }
//
//   Future<void> navigateNext() async {
//     await Future.delayed(const Duration(seconds: 0));
//
//     // Navigator.pushReplacementNamed(context, '/language');
//     // return;
//     final selectedLang = settingsBox.get('languageCode');
//     if (selectedLang == null) {
//       Navigator.pushReplacementNamed(context, '/language');
//     } else {
//       final seenOnboarding = settingsBox.get(
//         'seenOnboarding',
//         defaultValue: false,
//       );
//       if (!seenOnboarding) {
//         Navigator.pushReplacementNamed(context, '/onboarding');
//       } else {
//         Navigator.pushReplacementNamed(context, '/');
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     _sliderController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final colors = Theme.of(context).extension<AppThemeColors>()!;
//     return Scaffold(
//       backgroundColor: colors.background,
//       body: SafeArea(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Spacer(),
//             Center(child: AppImage(src: AppSvg.appLogo, height: 120)),
//
//             /// 🔹 Animated text ONLY
//             Padding(
//               padding: const EdgeInsets.only(top: 13),
//               child: AppText(
//                 _visibleText,
//                 fontSize: 28,
//                 fontWeight: FontWeight.w500,
//                 color: colors.textSecondary,
//                 align: TextAlign.center,
//               ),
//             ),
//             Spacer(),
//             Padding(
//               padding: const EdgeInsets.only(bottom: 40),
//               child: SizedBox(
//                 width: 200,
//                 child: AnimatedBuilder(
//                   animation: _sliderAnimation,
//                   builder: (context, child) {
//                     return SliderTheme(
//                       data: SliderTheme.of(context).copyWith(
//                         trackHeight: 4,
//
//                         // hide thumb
//                         thumbShape: const RoundSliderThumbShape(
//                           enabledThumbRadius: 0,
//                           disabledThumbRadius: 0,
//                         ),
//                         overlayShape: SliderComponentShape.noOverlay,
//
//                         /// ⭐ IMPORTANT PART
//                         disabledActiveTrackColor: colors.primary,
//                         disabledInactiveTrackColor: colors.primary.withOpacity(
//                           0.5,
//                         ),
//                       ),
//                       child: Slider(
//                         value: _sliderAnimation.value,
//                         min: 0,
//                         max: 1,
//                         onChanged: null, // keep disabled (auto animation only)
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }