part of 'audio_bloc.dart';

abstract class AudioEvent {}

// class LoadAudios extends AudioEvent {}
class LoadAudios extends AudioEvent {
  bool? showLoading;
  LoadAudios({this.showLoading = true});
}
// audio_event.dart માં ઉમેરો
class UpdateAudioItem extends AudioEvent {
  final AssetEntity entity;
  final int index;
  UpdateAudioItem(this.entity, this.index);
}