import '../utils/app_imports.dart';
import 'video_playback_adapter.dart';

/// iOS-dedicated adapter wrapper.
///
/// Stage-3 goal: keep iOS backend evolution isolated from Android/default.
/// Today this delegates to VideoPlayerAdapter, but future native AVPlayer/PiP
/// implementation can be added here without touching PlayerScreen.
class IosVideoPlaybackAdapter implements VideoPlaybackAdapter {
  final VideoPlayerAdapter _delegate = VideoPlayerAdapter();

  @override
  VideoPlayerController? get controller => _delegate.controller;

  @override
  bool get isInitialized => _delegate.isInitialized;

  @override
  bool get isPlaying => _delegate.isPlaying;

  @override
  Duration get position => _delegate.position;

  @override
  Duration get duration => _delegate.duration;

  @override
  double get aspectRatio => _delegate.aspectRatio;

  @override
  Size get size => _delegate.size;

  @override
  Future<void> openFile(File file) => _delegate.openFile(file);

  @override
  Future<void> openNetwork(String url) => _delegate.openNetwork(url);

  @override
  Future<void> attachController(VideoPlayerController controller) =>
      _delegate.attachController(controller);

  @override
  Future<void> initialize() => _delegate.initialize();

  @override
  Future<void> play() => _delegate.play();

  @override
  Future<void> pause() => _delegate.pause();

  @override
  Future<void> dispose() => _delegate.dispose();

  @override
  Future<void> seekTo(Duration position) => _delegate.seekTo(position);

  @override
  Future<void> setVolume(double value) => _delegate.setVolume(value);

  @override
  Future<void> setLooping(bool looping) => _delegate.setLooping(looping);

  @override
  Future<void> setPlaybackSpeed(double speed) =>
      _delegate.setPlaybackSpeed(speed);

  @override
  void addListener(VoidCallback listener) => _delegate.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _delegate.removeListener(listener);

  @override
  Future<bool> isPipSupported() => _delegate.isPipSupported();

  @override
  Future<bool> enterPip() => _delegate.enterPip();
}
