// // EVENTS
// abstract class ThemeEvent {}
//
// // class ToggleTheme extends ThemeEvent {}


// EVENTS
abstract class ThemeEvent {}

class ToggleTheme extends ThemeEvent {}
class UpdateThemeMode extends ThemeEvent {
  final String themeMode; // 'light', 'dark', અથવા 'system'
  UpdateThemeMode(this.themeMode);
}