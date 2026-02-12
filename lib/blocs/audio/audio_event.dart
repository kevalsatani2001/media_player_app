part of 'audio_bloc.dart';

abstract class AudioEvent {}

// class LoadAudios extends AudioEvent {}
class LoadAudios extends AudioEvent {
  bool? showLoading;
  LoadAudios({this.showLoading = true});
}