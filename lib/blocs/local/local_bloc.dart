import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/hive_service.dart';
import 'local_event.dart';
import 'local_state.dart';

class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  LocaleBloc()
      : super(LocaleState(
    Locale(HiveService.languageCode ?? 'en'),
  )) {
    on<ChangeLocale>((event, emit) async {
      await HiveService.saveLanguage(event.locale.languageCode);
      emit(LocaleState(event.locale));
    });
  }
}