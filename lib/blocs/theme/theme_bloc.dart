import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_player/blocs/theme/theme_event.dart';
import 'package:media_player/blocs/theme/theme_state.dart';

import '../../services/hive_service.dart';
import '../../utils/app_colors.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc()
      : super(
    ThemeState(
      themeData: AppTheme.light(),
    ),
  ) {
    // on<ToggleTheme>((event, emit) {
    //   emit(
    //     ThemeState(
    //       themeData: AppTheme.light(),
    //     ),
    //   );
    // });
  }
}


/*
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc()
      : super(
    ThemeState(
      themeData: HiveService.isDark
          ? AppTheme.dark()
          : AppTheme.light(),
      isDark: HiveService.isDark,
    ),
  ) {
    on<ToggleTheme>((event, emit) {
      final newIsDark = !state.isDark;
      HiveService.isDark = newIsDark;

      emit(
        ThemeState(
          themeData: newIsDark
              ? AppTheme.dark()
              : AppTheme.light(),
          isDark: newIsDark,
        ),
      );
    });
  }
}
 */