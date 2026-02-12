import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_player/blocs/bottom_nav/bottom_nav_state.dart';

import 'bottom_nav_event.dart';

class BottomNavBloc extends Bloc<BottomNavEvent, BottomNavState> {
  BottomNavBloc() : super(BottomNavState(0)) {
    on<SelectBottomTab>((event, emit) => emit(BottomNavState(event.index)));
  }
}
