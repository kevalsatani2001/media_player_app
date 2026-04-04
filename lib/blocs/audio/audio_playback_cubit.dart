import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import '../../services/global_player.dart';

/// Playback controls for the audio queue (shuffle / loop). Mirrors [GlobalPlayer]
/// and [AudioPlayer] streams so the UI stays in sync with just_audio.
class AudioPlaybackState extends Equatable {
  final bool isShuffle;
  final LoopMode loopMode;

  const AudioPlaybackState({
    required this.isShuffle,
    required this.loopMode,
  });

  factory AudioPlaybackState.fromPlayer(GlobalPlayer p) => AudioPlaybackState(
        isShuffle: p.isShuffle,
        loopMode: p.loopMode,
      );

  AudioPlaybackState copyWith({
    bool? isShuffle,
    LoopMode? loopMode,
  }) =>
      AudioPlaybackState(
        isShuffle: isShuffle ?? this.isShuffle,
        loopMode: loopMode ?? this.loopMode,
      );

  @override
  List<Object?> get props => [isShuffle, loopMode];
}

class AudioPlaybackCubit extends Cubit<AudioPlaybackState> {
  AudioPlaybackCubit(this._player)
      : super(AudioPlaybackState.fromPlayer(_player)) {
    _shuffleSub = _player.audioPlayer.shuffleModeEnabledStream.listen((enabled) {
      if (isClosed) return;
      emit(state.copyWith(isShuffle: enabled));
    });
    _loopSub = _player.audioPlayer.loopModeStream.listen((mode) {
      if (isClosed) return;
      emit(state.copyWith(loopMode: mode));
    });
  }

  final GlobalPlayer _player;
  StreamSubscription<bool>? _shuffleSub;
  StreamSubscription<LoopMode>? _loopSub;

  Future<void> toggleShuffle() async {
    await _player.toggleShuffle();
    emit(AudioPlaybackState.fromPlayer(_player));
  }

  Future<void> toggleLoop() async {
    await _player.toggleLoopMode();
    emit(AudioPlaybackState.fromPlayer(_player));
  }

  @override
  Future<void> close() {
    _shuffleSub?.cancel();
    _loopSub?.cancel();
    return super.close();
  }
}
