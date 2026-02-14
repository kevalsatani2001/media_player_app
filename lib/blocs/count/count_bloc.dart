import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import 'count_event.dart';
import 'count_state.dart';

class HomeCountBloc extends Bloc<HomeCountEvent, HomeCountState> {
  StreamSubscription? _recent;
  StreamSubscription? _videoSub;
  StreamSubscription? _audioSub;
  StreamSubscription? _favSub;
  StreamSubscription? _playlistSub;

  HomeCountBloc() : super(HomeCountState.initial()) {
    on<LoadCounts>((event, emit) {
      _emitCounts(emit);
      _listenHive(); // start listening
    });

    on<RefreshCounts>((event, emit) {
      _emitCounts(emit);
    });
  }

  void _emitCounts(Emitter<HomeCountState> emit) {
    final recentCount = Hive.box('recents').length;
    final videoCount = Hive.box('videos').length;
    final audioCount = Hive.box('audios').length;
    final favouriteCount = Hive.box('favourites').length;
    final playlistCount = Hive.box('playlists').length;

    emit(HomeCountState(
        videoCount: videoCount,
        audioCount: audioCount,
        favouriteCount: favouriteCount,
        playlistCount: playlistCount,
        recentCount: recentCount

    ));
  }

  void _listenHive() {
    _videoSub = Hive.box('videos').watch().listen((_) {
      add(RefreshCounts());
    });

    _audioSub = Hive.box('audios').watch().listen((_) {
      add(RefreshCounts());
    });

    _favSub = Hive.box('favourites').watch().listen((_) {
      add(RefreshCounts());
    });

    _playlistSub = Hive.box('playlists').watch().listen((_) {
      add(RefreshCounts());
    });
  }

  @override
  Future<void> close() {
    _videoSub?.cancel();
    _audioSub?.cancel();
    _favSub?.cancel();
    _playlistSub?.cancel();
    return super.close();
  }
}


////////////////////////////



////////////////////////////////////



