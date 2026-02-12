import 'dart:ui';

abstract class LocaleEvent {}
class ChangeLocale extends LocaleEvent {
  final Locale locale;
  ChangeLocale(this.locale);
}