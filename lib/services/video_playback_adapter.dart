import '../utils/app_imports.dart';
import 'ios_video_playback_adapter.dart';

/// Backend-agnostic video playback contract.
abstract class VideoPlaybackAdapter {
  VideoPlayerController? get controller;
  bool get isInitialized;
  bool get isPlaying;
  Duration get position;
  Duration get duration;
  double get aspectRatio;
  Size get size;

  Future<void> openFile(File file);
  Future<void> openNetwork(String url);
  Future<void> attachController(VideoPlayerController controller);
  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
  Future<void> seekTo(Duration position);
  Future<void> setVolume(double value);
  Future<void> setLooping(bool looping);
  Future<void> setPlaybackSpeed(double speed);
  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);

  Future<bool> isPipSupported();
  Future<bool> enterPip();
}

/// Current implementation based on `video_player`.
class VideoPlayerAdapter implements VideoPlaybackAdapter {
  static const MethodChannel _pipChannel = MethodChannel("media_player/pip");
  VideoPlayerController? _controller;

  @override
  VideoPlayerController? get controller => _controller;

  @override
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  @override
  bool get isPlaying => _controller?.value.isPlaying ?? false;

  @override
  Duration get position => _controller?.value.position ?? Duration.zero;

  @override
  Duration get duration => _controller?.value.duration ?? Duration.zero;

  @override
  double get aspectRatio => _controller?.value.aspectRatio ?? (16 / 9);

  @override
  Size get size => _controller?.value.size ?? const Size(16, 9);

  @override
  Future<void> openFile(File file) async {
    await dispose();
    _controller = VideoPlayerController.file(file);
  }

  @override
  Future<void> openNetwork(String url) async {
    await dispose();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
  }

  @override
  Future<void> attachController(VideoPlayerController controller) async {
    await dispose();
    _controller = controller;
  }

  @override
  Future<void> initialize() async {
    await _controller?.initialize();
  }

  @override
  Future<void> play() async {
    await _controller?.play();
  }

  @override
  Future<void> pause() async {
    await _controller?.pause();
  }

  @override
  Future<void> dispose() async {
    final c = _controller;
    _controller = null;
    if (c != null) {
      await c.dispose();
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _controller?.seekTo(position);
  }

  @override
  Future<void> setVolume(double value) async {
    await _controller?.setVolume(value);
  }

  @override
  Future<void> setLooping(bool looping) async {
    await _controller?.setLooping(looping);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    await _controller?.setPlaybackSpeed(speed);
  }

  @override
  void addListener(VoidCallback listener) {
    _controller?.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _controller?.removeListener(listener);
  }

  @override
  Future<bool> isPipSupported() async {
    try {
      return await _pipChannel.invokeMethod<bool>("isPipSupported") ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> enterPip() async {
    try {
      return await _pipChannel.invokeMethod<bool>("enterPip") ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// Stage-3: adapter selection entry-point.
/// iOS migration can swap this to a dedicated AVPlayer/PiP-capable adapter.
VideoPlaybackAdapter createDefaultVideoAdapter() {
  if (Platform.isIOS) {
    return IosVideoPlaybackAdapter();
  }
  return VideoPlayerAdapter();
}
