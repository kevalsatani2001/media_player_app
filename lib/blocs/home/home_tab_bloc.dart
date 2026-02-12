import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_tab_event.dart';
import 'home_tab_state.dart';

class HomeTabBloc extends Bloc<HomeTabEvent, HomeTabState> {
  HomeTabBloc() : super(const HomeTabState(0)) {
    on<SelectTab>((event, emit) {
      emit(HomeTabState(event.index));
    });
  }
}
