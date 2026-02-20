import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_player/blocs/theme/theme_event.dart';
import 'package:media_player/blocs/theme/theme_state.dart';

import '../../services/hive_service.dart';
import '../../utils/app_colors.dart';

// class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
//   ThemeBloc()
//       : super(
//     ThemeState(
//       themeData: AppTheme.light(),
//     ),
//   ) {
//     on<ToggleTheme>((event, emit) {
//       emit(
//         ThemeState(
//           themeData: AppTheme.light(),
//         ),
//       );
//     });
//   }
// }



class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc()
      : super(
    ThemeState(
      // Hive માંથી મોડ લાવો (dark/light/system)
      themeData: _getThemeData(HiveService.themeMode),
      isDark: HiveService.isDark,
    ),
  ) {

    // નવી ઇવેન્ટ: ચોક્કસ થીમ મોડ સેટ કરવા માટે
    on<UpdateThemeMode>((event, emit) {
      final mode = event.themeMode;

      // ૧. Hive માં સેવ કરો
      HiveService.themeMode = mode;

      // ૨. નવો થીમ ડેટા મેળવો
      final newThemeData = _getThemeData(mode);
      final isDark = mode == 'dark' || (mode == 'system' && PlatformDispatcher.instance.platformBrightness == Brightness.dark);

      // ૩. નવો સ્ટેટ EMIT કરો (આનાથી રન-ટાઇમ અપડેટ થશે)
      emit(ThemeState(
        themeData: newThemeData,
        isDark: isDark,
      ));
    });
  }

  // હેલ્પર મેથડ: મોડ મુજબ થીમ ડેટા આપશે
  static ThemeData _getThemeData(String mode) {
    if (mode == 'dark') return AppTheme.dark();
    if (mode == 'light') return AppTheme.light();

    // જો 'system' હોય તો ફોનની થીમ મુજબ સેટ થશે
    final brightness = PlatformDispatcher.instance.platformBrightness;
    return brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light();
  }
}








