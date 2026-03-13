
import '../utils/app_imports.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final Box settingsBox = Hive.box('settings');

  String _fullText = '';
  String _visibleText = '';
  int _index = 0;
  Timer? _timer;
  late AnimationController _sliderController;
  late Animation<double> _sliderAnimation;
  bool _isInitialized = false; // Add this flag

  @override
  void initState() {
    super.initState();

    _sliderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _sliderAnimation =
    Tween<double>(begin: 0.0, end: 1.0).animate(_sliderController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _showAdAndNavigate();
        }
      });

    _sliderController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _fullText = context.tr("mediaPlayerApp");
      _startTyping();
      _isInitialized = true;
    }
  }

  void _showAdAndNavigate() {
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
    final selectedLang = settingsBox.get('languageCode');
    final isNewApp = settingsBox.get('isNewApp', defaultValue: true);
    String route;
    print("isnewapp is ===> $isNewApp");
    if (selectedLang == null || isNewApp) {
      route = '/language';
    } else {
      final seenOnboarding = settingsBox.get(
        'seenOnboarding',
        defaultValue: false,
      );
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
//               navigateNext(); // Ã°Å¸Å¡â‚¬ CALL AFTER SLIDER COMPLETES
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
//             /// Ã°Å¸â€Â¹ Animated text ONLY
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
//                         /// Ã¢Â­Â IMPORTANT PART
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