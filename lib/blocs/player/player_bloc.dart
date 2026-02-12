import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/hive_service.dart';
import 'player_event.dart';
import 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc() : super(PlayerState(false)) {
    on<PlayMedia>(_onPlayMedia);
    on<ToggleLike>(_onToggleLike);
  }

  void _onPlayMedia(PlayMedia event, Emitter<PlayerState> emit) {
    HiveService.addRecent(event.item);
    emit(
      PlayerState(
        HiveService.isFavourite(event.item.path),
      ),
    );
  }

  void _onToggleLike(ToggleLike event, Emitter<PlayerState> emit) {
    HiveService.toggleFavourite(event.item);
    emit(
      PlayerState(
        HiveService.isFavourite(event.item.path),
      ),
    );
  }
}
