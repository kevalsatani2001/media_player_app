import 'dart:math';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:just_audio_background/just_audio_background.dart' as bg;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/media_item.dart' as my;
import 'package:just_audio/just_audio.dart' hide PlayerState;
import '../utils/app_imports.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'connectivity_service.dart';
import 'notification_service.dart';
import 'video_playback_adapter.dart';
//youtube_explode_dart:

/// Minimal valid PCM WAV (mono 16-bit) for [just_audio_background], which requires
/// a [MediaItem] tag on every [AudioSource]. [SilenceAudioSource] does not satisfy
/// that assertion on all plugin versions.
Uint8List _silentWavPcm16Mono({int sampleRate = 44100, int durationMs = 800}) {
  final n = sampleRate * durationMs ~/ 1000;
  final dataSize = n * 2;
  final chunkSize = 36 + dataSize;
  final bb = BytesBuilder(copy: false);
  void w32(int v) {
    bb.add([
      v & 0xff,
      (v >> 8) & 0xff,
      (v >> 16) & 0xff,
      (v >> 24) & 0xff,
    ]);
  }

  void w16(int v) {
    bb.add([v & 0xff, (v >> 8) & 0xff]);
  }

  bb.add([82, 73, 70, 70]); // RIFF
  w32(chunkSize);
  bb.add([87, 65, 86, 69]); // WAVE
  bb.add([102, 109, 116, 32]); // fmt
  w32(16);
  w16(1); // PCM
  w16(1); // mono
  w32(sampleRate);
  w32(sampleRate * 2); // byte rate
  w16(2); // block align
  w16(16); // bits
  bb.add([100, 97, 116, 97]); // data
  w32(dataSize);
  for (var i = 0; i < n; i++) {
    w16(0);
  }
  return Uint8List.fromList(bb.toBytes());
}

class GlobalPlayerService {
  static final GlobalPlayerService _instance = GlobalPlayerService._internal();
  VoidCallback? _currentListener;

  /// Limits how often [loadVideo]'s [onUpdate] runs during playback so the player
  /// UI is not rebuilt on every video frame. Play/pause, init, and duration
  /// changes still notify immediately.
  static const Duration _uiUpdateThrottle = Duration(milliseconds: 120);
  bool? _uiThrottleLastPlaying;
  bool _uiThrottleLastInitialized = false;
  int _uiThrottleLastDurationMs = -1;
  DateTime _uiThrottleLastNotify = DateTime.fromMillisecondsSinceEpoch(0);

  factory GlobalPlayerService() => _instance;

  GlobalPlayerService._internal();

  void _resetUiThrottle() {
    _uiThrottleLastPlaying = null;
    _uiThrottleLastInitialized = false;
    _uiThrottleLastDurationMs = -1;
    _uiThrottleLastNotify = DateTime.fromMillisecondsSinceEpoch(0);
  }

  final VideoPlaybackAdapter _videoAdapter = createDefaultVideoAdapter();

  VideoPlayerController? get controller => _videoAdapter.controller;

  set controller(VideoPlayerController? value) {
    if (value == null) return;
    _videoAdapter.attachController(value);
  }

  List<AssetEntity> playlist = [];
  int currentIndex = 0;

  // States
  bool isInitialized = false;
  bool isLooping = false;
  bool isShuffle = false;
  double volume = 0.5;
  bool isMuted = false;
  double playbackSpeed = 1.0;
  bool wasPlayingBeforeDisconnect = false;
  bool _isToggleInProgress = false;
  int _lastToggleAtMs = 0;

  /// True when [playNetworkStream] is active; false for local [loadVideo] / file playback.
  bool isNetworkPlayback = false;

  /// Original URL entered for stream (YouTube page or direct link); for share / info UI.
  String? networkStreamUrl;

  bool get hasController => _videoAdapter.controller != null;

  bool get isVideoReady => _videoAdapter.isInitialized;

  bool get isVideoPlaying => _videoAdapter.isPlaying;

  Duration get currentPosition => _videoAdapter.position;

  Duration get totalDuration => _videoAdapter.duration;

  double get currentAspectRatio => _videoAdapter.aspectRatio;

  Size get currentVideoSize => _videoAdapter.size;

  Future<void> seekTo(Duration position) => _videoAdapter.seekTo(position);

  Future<void> seekBy(Duration delta) async {
    final target = (_videoAdapter.position + delta);
    if (target < Duration.zero) {
      await _videoAdapter.seekTo(Duration.zero);
      return;
    }
    if (_videoAdapter.duration != Duration.zero &&
        target > _videoAdapter.duration) {
      await _videoAdapter.seekTo(_videoAdapter.duration);
      return;
    }
    await _videoAdapter.seekTo(target);
  }

  /// Same system media notification as music: uses the single shared
  /// [GlobalPlayer.audioPlayer] with [just_audio_background]. If the music
  /// queue owns that player, falls back to local notification.
  Future<void> _updateMediaNotification() async {
    if (playlist.isEmpty || !isInitialized) return;
    final entity = playlist[currentIndex];
    final title = entity.title ?? "Video";
    final gp = GlobalPlayer();
    final ok = await gp.tryAttachVideoBackgroundMediaSession(
      mediaId: entity.id,
      title: title,
      duration: totalDuration,
    );
    if (!ok) {
      await AppNotificationService.showVideoBackgroundNotification(
        title: title,
        body: "Playing in background",
      );
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    playbackSpeed = speed;
    await _videoAdapter.setPlaybackSpeed(speed);
  }

  Future<bool> isPipSupported() => _videoAdapter.isPipSupported();

  Future<bool> enterPipMode() => _videoAdapter.enterPip();

  Future<void> pauseVideo() async {
    await _videoAdapter.pause();
    await GlobalPlayer().detachVideoBackgroundMediaSession();
    await AppNotificationService.cancelVideoBackgroundNotification();
  }

  Future<void> playVideo() async {
    await _videoAdapter.play();
  }

  Future<void> ensureBackgroundNotificationActive() async {
    if (!isInitialized) return;
    await _updateMediaNotification();
  }

  Future<void> stopBackgroundNotificationAudio() async {
    await GlobalPlayer().detachVideoBackgroundMediaSession();
    await AppNotificationService.cancelVideoBackgroundNotification();
  }

  /// True when the controller is at the real end (not the "zero duration" init state).
  bool shouldAdvanceToNextVideo(
      Duration position,
      Duration duration,
      bool controllerIsPlaying,
      ) {
    if (isLooping || controllerIsPlaying) return false;
    final endMs = duration.inMilliseconds;
    if (endMs <= 0) return false;
    final posMs = position.inMilliseconds;
    final startOfEndWindow = max(1, endMs - 500);
    return posMs >= startOfEndWindow;
  }

  Future<void> setLooping(bool looping) => _videoAdapter.setLooping(looping);

  Future<void> setVideoVolume(double value) => _videoAdapter.setVolume(value);

  void addVideoListener(VoidCallback listener) =>
      _videoAdapter.addListener(listener);

  void removeVideoListener(VoidCallback listener) =>
      _videoAdapter.removeListener(listener);

  Future<void> saveLastPlayed() async {
    if (controller == null || !isInitialized) return;

    var box = Hive.isBoxOpen('last_played')
        ? Hive.box('last_played')
        : await Hive.openBox('last_played');

    await box.put('last_id', playlist[currentIndex].id);
    await box.put('last_position', currentPosition.inMilliseconds);
    await box.put('last_index', currentIndex);
  }

  Future<void> init(
      List<AssetEntity> list,
      int index,
      Function onUpdate, {
        int? seekToMs,
      }) async {
    if (list.isEmpty) {
      print("Error: Playlist is empty");
      return;
    }
    playlist = list;
    currentIndex = index < list.length ? index : 0;
    await loadVideo(onUpdate, seekToMs: seekToMs);
  }

  Future<void> loadVideo(Function onUpdate, {int? seekToMs}) async {
    if (playlist.isEmpty) return;

    isNetworkPlayback = false;
    networkStreamUrl = null;

    final entity = playlist[currentIndex];
    final file = await entity.file;

    // âœ… Step 4: File Safety Check
    if (file == null || !await file.exists()) {
      print("âŒ File not found / deleted");
      playNext(onUpdate);
      return;
    }

    isInitialized = false;
    _resetUiThrottle();

    try {
      if (controller != null) {
        clearListener();
        await _videoAdapter.dispose();
      }

      await _videoAdapter.openFile(file);

      // âœ… Step 5: Retry + Timeout
      int retry = 0;
      while (retry < 2) {
        try {
          await _videoAdapter.initialize().timeout(const Duration(seconds: 10));
          break;
        } catch (e) {
          retry++;
          print("âš ï¸ Retry $retry");

          if (retry >= 2) {
            print("âŒ Failed after retry");
            playNext(onUpdate);
            return;
          }
        }
      }

      if (seekToMs != null) {
        await _videoAdapter.seekTo(Duration(milliseconds: seekToMs));
      }

      isInitialized = true;

      await _videoAdapter.setVolume(isMuted ? 0 : volume);
      await _videoAdapter.setLooping(isLooping);

      await _videoAdapter.play();

      // Give the engine time to start; do not auto-skip the playlist if `isPlaying`
      // is still false (common right after first open while buffering).
      for (var i = 0; i < 12; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_videoAdapter.isPlaying) break;
      }

      _currentListener = () {
        if (isInitialized && controller != null) {
          if (shouldAdvanceToNextVideo(
            _videoAdapter.position,
            _videoAdapter.duration,
            _videoAdapter.isPlaying,
          ) &&
              _videoAdapter.isInitialized) {
            playNext(onUpdate);
            return;
          }
        }

        final playing = _videoAdapter.isPlaying;
        final initialized = _videoAdapter.isInitialized;
        final durationMs = _videoAdapter.duration.inMilliseconds;
        final playingChanged = _uiThrottleLastPlaying != playing;
        final initChanged = _uiThrottleLastInitialized != initialized;
        final durationChanged = _uiThrottleLastDurationMs != durationMs;
        _uiThrottleLastPlaying = playing;
        _uiThrottleLastInitialized = initialized;
        _uiThrottleLastDurationMs = durationMs;

        final now = DateTime.now();
        final elapsed = now.difference(_uiThrottleLastNotify);
        final throttleOk = elapsed >= _uiUpdateThrottle;
        if (initChanged || playingChanged || durationChanged || throttleOk) {
          _uiThrottleLastNotify = now;
          onUpdate();
        }
      };

      _videoAdapter.addListener(_currentListener!);
      onUpdate();
    } catch (e) {
      print("âŒ Video load failed: $e");

      // ðŸ”¥ Auto skip
      playNext(onUpdate);
    }
  }

  void clearListener() {
    if (controller != null && _currentListener != null) {
      _videoAdapter.removeListener(_currentListener!);
      _currentListener = null;
    }
  }

  void playNext(Function onUpdate) {
    if (playlist.isEmpty) return;

    // âœ… Shuffle Fix
    if (isShuffle && playlist.length > 1) {
      final random = Random();
      currentIndex = random.nextInt(playlist.length);
    } else if (currentIndex < playlist.length - 1) {
      currentIndex++;
    } else {
      currentIndex = 0;
    }

    clearListener();
    loadVideo(onUpdate);
  }

  void playPrevious(Function onUpdate) {
    if (currentIndex > 0) {
      currentIndex--;
    } else {
      currentIndex = playlist.length - 1;
    }
    loadVideo(onUpdate);
  }

  void togglePlay() {
    if (controller == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_isToggleInProgress || (now - _lastToggleAtMs) < 140) return;
    _isToggleInProgress = true;
    _lastToggleAtMs = now;
    final shouldPause = _videoAdapter.isPlaying;
    final Future<void> op = shouldPause ? pauseVideo() : playVideo();
    op.timeout(const Duration(seconds: 3), onTimeout: () {
      // Do not keep toggle lock forever on rare plugin hangs.
      return;
    }).whenComplete(() {
      _isToggleInProgress = false;
    });
  }

  Future<void> playNetworkStream(String url, VoidCallback onUpdate) async {
    final yt = YoutubeExplode();

    try {
      isInitialized = false;
      onUpdate();

      // Always close current playback first. If stream parsing fails, old video
      // must not continue behind the loader.
      if (controller != null) {
        clearListener();
        await _videoAdapter.dispose();
      }

      String finalUrl = url;
      final uri = Uri.tryParse(url);
      final host = (uri?.host ?? '').toLowerCase();
      final isYoutube =
          host.contains('youtube.com') || host.contains('youtu.be');

      if (isYoutube) {
        String? videoId = VideoId.parseVideoId(url);
        if (videoId == null && uri != null) {
          final segments = uri.pathSegments;
          final shortsIdx = segments.indexOf('shorts');
          if (shortsIdx >= 0 && shortsIdx + 1 < segments.length) {
            videoId = segments[shortsIdx + 1];
          }
        }
        if (videoId == null || videoId.isEmpty) {
          throw "Invalid YouTube URL";
        }

        final manifest = await yt.videos.streamsClient
            .getManifest(videoId)
            .timeout(const Duration(seconds: 12));
        final streamInfo = manifest.muxed.withHighestBitrate();
        finalUrl = streamInfo.url.toString();
      }

      await _videoAdapter.openNetwork(finalUrl);

      await _videoAdapter.initialize().timeout(const Duration(seconds: 12));

      _currentListener = () {
        if (isInitialized && controller != null) {
          onUpdate();
        }
      };
      _videoAdapter.addListener(_currentListener!);

      isInitialized = true;
      isNetworkPlayback = true;
      networkStreamUrl = url;
      await _videoAdapter.play();
      onUpdate();
    } catch (e) {
      print("âŒ Stream Error: $e");
      isInitialized = false;
      isNetworkPlayback = false;
      networkStreamUrl = null;
      onUpdate();
    } finally {
      yt.close();
    }
  }

  Future<void> loadExternalFilePath(
      String path,
      VoidCallback onUpdate, {
        int? seekToMs,
      }) async {
    final file = File(path);
    if (!await file.exists()) return;

    try {
      clearListener();
      isNetworkPlayback = false;
      networkStreamUrl = null;
      await _videoAdapter.openFile(file);
      await _videoAdapter.initialize();

      if (seekToMs != null) {
        await _videoAdapter.seekTo(Duration(milliseconds: seekToMs));
      }

      await _videoAdapter.setVolume(isMuted ? 0 : volume);
      await _videoAdapter.setLooping(isLooping);
      await _videoAdapter.setPlaybackSpeed(playbackSpeed);

      _currentListener = onUpdate;
      _videoAdapter.addListener(_currentListener!);

      isInitialized = true;
      await _videoAdapter.play();
      onUpdate();
    } catch (_) {
      isInitialized = false;
      onUpdate();
    }
  }
}

extension SaveState on GlobalPlayerService {
  Future<void> saveCurrentState() async {
    if (controller == null || !isInitialized) return;

    final box = Hive.box('last_played');
    final currentEntity = playlist[currentIndex];

    await box.put('video_data', {
      'index': currentIndex,
      'position': currentPosition.inMilliseconds,
      'playlist_ids': playlist.map((e) => e.id).toList(),
    });
  }
}

class GlobalPlayer extends ChangeNotifier {
  static final GlobalPlayer _instance = GlobalPlayer._internal();

  factory GlobalPlayer() => _instance;
  StreamSubscription<List<ConnectivityResult>>? _networkSubscription;
  bool _wasPlayingBeforeOffline = false;

  GlobalPlayer._internal() {
    _initAudioSession();
    _listenToJustAudioEvents();
    _listenToNetworkChanges();
  }

  Future<List<AssetEntity>> get currentEntities async =>
      await _getCurrentEntities();
  List<AssetEntity> currentEntitiesList = [];

  void _listenToNetworkChanges() {
    _networkSubscription = Connectivity().onConnectivityChanged.listen((
        results,
        ) {
      final isOffline = !NetworkInfo.hasUsableConnection(results);

      if (isOffline) {
        debugPrint("GlobalPlayer: Internet Lost!");

        if (isPlaying) {
          _wasPlayingBeforeOffline = true;
          pause();
        }
      } else {
        debugPrint("GlobalPlayer: Internet Restored!");

        if (_wasPlayingBeforeOffline) {
          resume();
          _wasPlayingBeforeOffline = false;
        }
      }
    });
  }

  final AudioPlayer audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  VideoPlayerController? videoController;

  // ChewieController? chewieController;

  List<my.MediaItem> queue = [];
  int currentIndex = -1;
  AssetEntity? currentEntity;
  String? currentType;
  bool isShuffle = false;
  double playbackSpeed = 1.0;
  bool _isLoading = false;

  Offset miniPlayerPosition = const Offset(20, 500); // Default position

  void updatePosition(Offset newPos) {
    miniPlayerPosition = newPos;
    notifyListeners();
  }

  void _listenToJustAudioEvents() {
    audioPlayer.currentIndexStream.listen((index) {
      if (currentIndex == -1) return;

      if (index != null && index < queue.length) {
        if (queue[index].type == 'video') {
          audioPlayer.pause();
          _playMediaAtIndex(index);
        } else {
          _syncStateWithIndex(index);
        }
      }
    });

    audioPlayer.playingStream.listen((isPlaying) async {
      if (!isPlaying) return;
      // Video background uses the same [audioPlayer] for silent MediaSession — never
      // treat that as "music playing" for network checks.
      if (_videoBackgroundMediaAttached) return;
      if (currentIndex < 0 || currentIndex >= queue.length) return;
      // Local files do not need internet; connectivity APIs often glitch anyway.
      if (!queue[currentIndex].isNetwork) return;

      final isOnline = await NetworkInfo.isConnected();
      if (!isOnline) {
        final currentContext = NavigatorKey.root.currentContext;
        await audioPlayer.pause();

        await audioPlayer.seek(audioPlayer.position);

        await AppNotificationService.showNoInternetNotification(
          title: "${currentContext?.tr("noInternetTitle")}",
          bodyTitle: "${currentContext?.tr("noInternetBody")}",
        );
      }
    });

    audioPlayer.playerStateStream.listen((state) {
      if (currentIndex == -1) return;
      // ConcatenatingAudioSource advances tracks internally; loop modes are handled
      // by just_audio. Do not call playNext() here — it broke loop/shuffle and
      // wrapped the queue when playback naturally completed.
      notifyListeners();
    });

    audioPlayer.shuffleModeEnabledStream.listen((enabled) {
      if (isShuffle != enabled) {
        isShuffle = enabled;
        notifyListeners();
      }
    });

    audioPlayer.loopModeStream.listen((mode) {
      if (loopMode != mode) {
        loopMode = mode;
        notifyListeners();
      }
    });
  }

  /// Applies saved [loopMode] / [isShuffle] to [audioPlayer] after a new source loads.
  Future<void> _applyAudioPlaybackModes() async {
    if (currentType != 'audio') return;
    try {
      await audioPlayer.setLoopMode(loopMode);
      await audioPlayer.setShuffleModeEnabled(isShuffle);
    } catch (_) {}
  }

  // --- Playback Speed (audio only) ---
  Future<void> setPlaybackSpeed(double speed) async {
    playbackSpeed = speed;
    if (currentType == 'audio') {
      await audioPlayer.setSpeed(speed);
    }
    notifyListeners();
  }

  // --- Shuffle Logic ---
  Future<void> toggleShuffle() async {
    if (currentType != 'audio') return;

    isShuffle = !isShuffle;
    await audioPlayer.setShuffleModeEnabled(isShuffle);
    isShuffle = audioPlayer.shuffleModeEnabled;
    notifyListeners();
  }

  // --- Loop Logic ---
  Future<void> toggleLoopMode() async {
    if (currentType != 'audio') return;

    if (loopMode == LoopMode.off) {
      loopMode = LoopMode.all;
    } else if (loopMode == LoopMode.all) {
      loopMode = LoopMode.one;
    } else {
      loopMode = LoopMode.off;
    }
    await audioPlayer.setLoopMode(loopMode);
    loopMode = audioPlayer.loopMode;
    notifyListeners();
  }

  Future<void> initAndPlay({
    required List<AssetEntity> entities,
    required String selectedId,
  }) async {
    if (_isLoading) return;
    _isLoading = true;
    // notifyListeners();

    await Future.microtask(() async {
      _isLoading = true;
      notifyListeners();

      try {
        int newIndex = entities.indexWhere((item) => item.id == selectedId);
        newIndex = newIndex == -1 ? 0 : newIndex;
        if (currentType == 'audio' &&
            audioPlayer.audioSource != null &&
            entities.length == queue.length) {
          // print("ty is ===> ------>  audio");
          currentIndex = newIndex;
          currentEntity = await AssetEntity.fromId(entities[newIndex].id);

          await audioPlayer.seek(Duration.zero, index: currentIndex);
          await audioPlayer.setSpeed(playbackSpeed);
          await _applyAudioPlaybackModes();
          audioPlayer.play();

          _isLoading = false;
          notifyListeners();
          return;
        }
        await _clearPreviousPlayer();

        queue = await _convertEntitiesToMediaItems(entities);
        currentEntitiesList = entities;
        if (queue.isEmpty) return;
        currentIndex = newIndex;
        currentType = queue[currentIndex].type;
        currentEntity = await AssetEntity.fromId(queue[currentIndex].id);

        if (currentType == 'audio') {
          print("ty is ===> ------>  audio");
          await _setupAudioQueue();
          audioPlayer.play();
        } else {
          print("ty is ===> ------>  video");
          // await _setupVideoPlayer(queue[currentIndex].path);
        }
      } catch (e) {
        debugPrint("Init Error: $e");
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _setupAudioQueue() async {
    await detachVideoBackgroundMediaSession();
    // just_audio_background notification often uses `extras['android.color']`
    // (and optionally `artUri`) for the current track. To keep startup fast,
    // we extract palette only for `currentIndex` (not for the whole queue).
    Color? extractedColor;
    Uri? artUri;

    try {
      if (currentIndex >= 0 && currentIndex < queue.length) {
        final currentItem = queue[currentIndex];
        final Uint8List? artwork = await _audioQuery.queryArtwork(
          Platform.isIOS
              ? currentItem.id.hashCode
              : int.tryParse(currentItem.id) ?? 0,
          ArtworkType.AUDIO,
          size: 500,
        );

        if (artwork != null && artwork.isNotEmpty) {
          final palette = await PaletteGenerator.fromImageProvider(
            MemoryImage(artwork),
          );
          extractedColor =
              palette.lightMutedColor?.color ?? palette.dominantColor?.color;

          final tempDir = await getTemporaryDirectory();
          final File artworkFile = File(
            '${tempDir.path}/thumb_${currentItem.id}.jpg',
          );
          await artworkFile.writeAsBytes(artwork);
          artUri = Uri.file(artworkFile.path);
        }
      }
    } catch (_) {
      // ignore palette failures; notification will fall back to default colors
    }

    final defaultColorValue = const Color(0xFF3D57F9).value;
    final currentColorValue = (extractedColor?.value ?? defaultColorValue);

    final audioSources = queue
        .asMap()
        .map((i, item) {
      final title = item.path.split('/').last;

      // Only set color/artUri for the currently playing track to avoid heavy work.
      final isCurrent = i == currentIndex;
      return MapEntry(
        i,
        AudioSource.uri(
          Uri.file(item.path),
          tag: bg.MediaItem(
            id: item.id,
            title: title,
            displayTitle: title,
            artist: "Local Media",
            artUri: isCurrent ? artUri : null,
            extras: <String, dynamic>{
              'android.color': isCurrent
                  ? currentColorValue
                  : defaultColorValue,
            },
          ),
        ),
      );
    })
        .values
        .toList();

    await audioPlayer.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: currentIndex,
      initialPosition: Duration.zero,
    );
    await audioPlayer.setVolume(_audioVolumeBeforeVideoBg.clamp(0.0, 1.0));

    // Apply speed for audio immediately after loading the new queue.
    await audioPlayer.setSpeed(playbackSpeed);
    await _applyAudioPlaybackModes();
  }

  Future<void> refreshCurrentEntity() async {
    if (currentEntity != null) {
      final updatedEntity = await currentEntity!.obtainForNewProperties();
      if (updatedEntity != null) {
        currentEntity = updatedEntity;
        notifyListeners();
      }
    }
  }

  Future<List<my.MediaItem>> _convertEntitiesToMediaItems(
      List<AssetEntity> entities,
      ) async {
    final files = await Future.wait(entities.map((entity) => entity.file));
    final List<my.MediaItem> items = [];
    for (int i = 0; i < entities.length; i++) {
      final file = files[i];
      if (file == null) continue;
      final entity = entities[i];
      items.add(
        my.MediaItem(
          id: entity.id,
          path: file.path,
          type: entity.type == AssetType.audio ? 'audio' : 'video',
          isNetwork: false,
          isFavourite: entity.isFavorite,
        ),
      );
    }
    return items;
  }

  Future<void> _setupAudioPlayer() async {
    final audioSources = queue.map((item) {
      return AudioSource.uri(
        Uri.file(item.path),
        tag: bg.MediaItem(
          id: item.id,
          title: item.path.split('/').last,
          artist: "Local Media",
        ),
      );
    }).toList();

    await audioPlayer.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: currentIndex,
      initialPosition: Duration.zero,
    );
    audioPlayer.play();
  }

  LoopMode loopMode = LoopMode.off;

  // Future<void> _setupVideoPlayer(String path) async {
  //   videoController = VideoPlayerController.file(File(path));
  //   await videoController!.initialize();
  //
  //   chewieController = ChewieController(
  //     zoomAndPan: true,
  //     aspectRatio: videoController!.value.aspectRatio,
  //     autoPlay: true,
  //     looping: loopMode == LoopMode.one,
  //     videoPlayerController: videoController!,
  //     deviceOrientationsOnEnterFullScreen: [
  //       DeviceOrientation.landscapeLeft,
  //       DeviceOrientation.landscapeRight,
  //     ],
  //     deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
  //     materialProgressColors: ChewieProgressColors(
  //       playedColor: const Color(0XFF3D57F9),
  //       backgroundColor: const Color(0XFFF6F6F6),
  //     ),
  //     onSufflePressed: () => toggleShuffle(),
  //     onNextVideo: () => playNext(),
  //     onPreviousVideo: () => playPrevious(),
  //     additionalOptions: (context) => _buildAdditionalOptions(context),
  //   );
  //
  //   videoController!.addListener(_videoListener);
  // }

  void _videoListener() {
    if (currentIndex == -1) return; // Safety check

    if (videoController != null &&
        videoController!.value.isInitialized &&
        videoController!.value.position >= videoController!.value.duration) {
      videoController!.removeListener(_videoListener);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentIndex != -1) playNext();
      });
    }
  }

  void _syncStateWithIndex(int index) async {
    currentIndex = index;
    final item = queue[index];
    currentEntity = await AssetEntity.fromId(item.id);
    notifyListeners();
  }

  Future<void> playNext() async {
    if (currentType == "video") {
      Navigator.pop;
      return;
    }
    if (queue.isEmpty) return;
    if (currentType == 'audio') {
      try {
        await audioPlayer.seekToNext();
      } catch (_) {
        if (queue.isEmpty) return;
        final nextIndex = (currentIndex + 1) % queue.length;
        await _playMediaAtIndex(nextIndex);
      }
      return;
    }
    final nextIndex = (currentIndex + 1) % queue.length;
    await _playMediaAtIndex(nextIndex);
  }

  Future<void> playPrevious() async {
    if (queue.isEmpty) return;
    if (currentType == 'audio') {
      try {
        await audioPlayer.seekToPrevious();
      } catch (_) {
        final prevIndex = (currentIndex - 1 < 0)
            ? queue.length - 1
            : currentIndex - 1;
        await _playMediaAtIndex(prevIndex);
      }
      return;
    }
    final prevIndex = (currentIndex - 1 < 0)
        ? queue.length - 1
        : currentIndex - 1;
    await _playMediaAtIndex(prevIndex);
  }

  Future<List<AssetEntity>> _getCurrentEntities() async {
    List<AssetEntity> list = [];

    for (var item in queue) {
      final ent = await AssetEntity.fromId(item.id);
      if (ent != null) list.add(ent);
    }
    return list;
  }

  Future<void> _clearPreviousPlayer({bool keepAudioSource = false}) async {
    if (videoController != null) {
      videoController!.removeListener(_videoListener);

      final oldVideoController = videoController;
      // final oldChewieController = chewieController;

      videoController = null;
      // chewieController = null;

      Future.delayed(Duration.zero, () {
        oldVideoController?.dispose();
        // oldChewieController?.dispose();
      });
    }

    if (currentType == 'video' && audioPlayer.playing) {
      await audioPlayer.pause();
    }
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    session.interruptionEventStream.listen((event) {
      if (event.begin)
        pause();
      else
        resume();
    });
  }

  void pause() {
    currentType == 'audio' ? audioPlayer.pause() : videoController?.pause();
    notifyListeners();
  }

  bool _currentPlaybackRequiresInternet() {
    if (currentType == 'audio' &&
        currentIndex >= 0 &&
        currentIndex < queue.length) {
      return queue[currentIndex].isNetwork;
    }
    // Mini-player / legacy video file path is local; no internet required to resume.
    if (currentType == 'video') return false;
    return false;
  }

  void resume() async {
    if (_currentPlaybackRequiresInternet()) {
      final isOnline = await NetworkInfo.isConnected();
      if (!isOnline) {
        final currentContext = NavigatorKey.root.currentContext;
        debugPrint("Resume blocked: No Internet");

        await AppNotificationService.showNoInternetNotification(
          title: "${currentContext?.tr("noInternetTitle")}",
          bodyTitle: "${currentContext?.tr("noInternetBody")}",
        );

        if (currentContext != null && currentContext.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              AppToast.show(
                currentContext,
                "Internet connection lost. Video cannot be played.",
                type: ToastType.error,
              );
            } catch (e) {
              debugPrint("Failed to show toast: $e");
            }
          });
        }

        notifyListeners();
        return;
      }
    }

    currentType == 'audio' ? audioPlayer.play() : videoController?.play();
    notifyListeners();
  }

  // Getters for UI
  bool get isPlaying => currentType == 'audio'
      ? audioPlayer.playing
      : (videoController?.value.isPlaying ?? false);

  Duration get position => currentType == 'audio'
      ? audioPlayer.position
      : (videoController?.value.position ?? Duration.zero);

  Duration get duration => currentType == 'audio'
      ? (audioPlayer.duration ?? Duration.zero)
      : (videoController?.value.duration ?? Duration.zero);

  my.MediaItem? get currentMediaItem =>
      (currentIndex >= 0 && currentIndex < queue.length)
          ? queue[currentIndex]
          : null;

  /// Music UI owns the shared [audioPlayer] when there is an audio queue.
  bool get _musicOwnsSharedAudioSession =>
      currentType == 'audio' && queue.isNotEmpty;

  bool _videoBackgroundMediaAttached = false;
  File? _videoBgSilenceFile;
  double _audioVolumeBeforeVideoBg = 1.0;

  /// Uses the same [just_audio_background] session as audio (lock screen / shade).
  /// Returns false if the music player must keep [audioPlayer] — use local notif then.
  Future<bool> tryAttachVideoBackgroundMediaSession({
    required String mediaId,
    required String title,
    required Duration duration,
  }) async {
    if (_videoBackgroundMediaAttached) return true;
    if (_musicOwnsSharedAudioSession) {
      return false;
    }
    try {
      _audioVolumeBeforeVideoBg = audioPlayer.volume;
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/video_bg_silence.wav');
      if (!await f.exists()) {
        await f.writeAsBytes(_silentWavPcm16Mono(durationMs: 1000));
      }
      _videoBgSilenceFile = f;

      final mediaTag = bg.MediaItem(
        id: 'video_bg_$mediaId',
        album: 'Video Player',
        title: title,
        artist: 'Video',
        // Keep duration unset to avoid tiny looping progress in notification UI.
      );

      // Single tagged URI source — satisfies just_audio_background's assertion.
      await audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.file(f.path),
          tag: mediaTag,
        ),
      );
      await audioPlayer.setLoopMode(LoopMode.one);
      await audioPlayer.setVolume(0);
      await audioPlayer.play();
      _videoBackgroundMediaAttached = true;
      return true;
    } catch (e) {
      debugPrint('tryAttachVideoBackgroundMediaSession: $e');
      return false;
    }
  }

  Future<void> detachVideoBackgroundMediaSession() async {
    if (!_videoBackgroundMediaAttached) return;
    try {
      await audioPlayer.pause();
      await audioPlayer.stop();
      await audioPlayer.setVolume(_audioVolumeBeforeVideoBg.clamp(0.0, 1.0));
    } catch (_) {}
    _videoBackgroundMediaAttached = false;
    try {
      final f = _videoBgSilenceFile;
      if (f != null && await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
    _videoBgSilenceFile = null;
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    audioPlayer.dispose();
    videoController?.dispose();
    // chewieController?.dispose();
    super.dispose();
  }

  bool _isAppInBackground() {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached;
  }

  Future<void> _playMediaAtIndex(int index) async {
    if (index < 0 || index >= queue.length) return;

    int targetIndex = index;

    if (_isAppInBackground()) {
      int itemsChecked = 0;

      while (queue[targetIndex].type == 'video' &&
          itemsChecked < queue.length) {
        debugPrint("Background mode: Skipping video at index $targetIndex");
        targetIndex = (targetIndex + 1) % queue.length;
        itemsChecked++;
      }

      if (itemsChecked >= queue.length) {
        debugPrint("No audio found to play in background. Stopping.");
        audioPlayer.stop();
        currentIndex = -1;
        notifyListeners();
        return;
      }
    }

    currentIndex = targetIndex;
    final item = queue[currentIndex];
    currentType = item.type;
    currentEntity = await AssetEntity.fromId(item.id);

    await _clearPreviousPlayer(keepAudioSource: true);

    if (currentType == 'audio') {
      await audioPlayer.seek(Duration.zero, index: currentIndex);
      audioPlayer.play();
    } else {
      // await _setupVideoPlayer(item.path);
    }

    notifyListeners();
  }

  Future<void> savePlayerState() async {
    final box = Hive.box('player_state');
    if (currentIndex == -1) {
      await box.clear();
      return;
    }
    if (currentMediaItem != null) {
      await box.put('last_item_id', currentMediaItem!.id);
      await box.put('last_position', audioPlayer.position.inMilliseconds);
      await box.put('last_type', currentType);
    }
  }

  Future<void> restoreLastSession() async {
    final box = Hive.box('player_state');
    final String? lastId = box.get('last_item_id');
    final int? lastPos = box.get('last_position');

    if (lastId != null) {
      // AssetEntity? entity = ... find by id ...

      // await audioPlayer.setAudioSource(...);
      // await audioPlayer.seek(Duration(milliseconds: lastPos ?? 0));
      // notifyListeners();
    }
  }

  my.MediaItem? _currentMediaItem;

  set currentMediaItem(my.MediaItem? value) {
    _currentMediaItem = value;
    notifyListeners();
  }

  AssetEntity? _currentEntity;

  void stopAndClose() {
    if (videoController != null) {
      videoController!.removeListener(_videoListener);
      videoController!.pause();
      videoController!.dispose();
      videoController = null;
    }

    // if (chewieController != null) {
    //   chewieController!.dispose();
    //   chewieController = null;
    // }
    audioPlayer.stop();
    queue = [];
    currentIndex = -1;
    currentMediaItem = null;
    currentEntity = null;
    currentType = null;

    notifyListeners();
  }
}









// class GlobalPlayer extends ChangeNotifier {
//   static final GlobalPlayer _instance = GlobalPlayer._internal();
//
//   factory GlobalPlayer() => _instance;
//   StreamSubscription<List<ConnectivityResult>>? _networkSubscription;
//   bool _wasPlayingBeforeOffline = false;
//
//   GlobalPlayer._internal() {
//     _initAudioSession();
//     _listenToJustAudioEvents();
//     _listenToNetworkChanges();
//   }
//
//    Future<List<AssetEntity>> get currentEntities async => await _getCurrentEntities();
//   List<AssetEntity> currentEntitiesList = [];
//
//   void _listenToNetworkChanges() {
//     _networkSubscription = Connectivity().onConnectivityChanged.listen((
//         results,
//         ) {
//       bool isOffline = results.contains(ConnectivityResult.none);
//
//       if (isOffline) {
//         debugPrint("GlobalPlayer: Internet Lost!");
//
//         if (isPlaying) {
//           _wasPlayingBeforeOffline = true;
//           pause();
//         }
//       } else {
//         debugPrint("GlobalPlayer: Internet Restored!");
//
//         if (_wasPlayingBeforeOffline) {
//           resume();
//           _wasPlayingBeforeOffline = false;
//         }
//       }
//     });
//   }
//
//   final AudioPlayer audioPlayer = AudioPlayer();
//   final OnAudioQuery _audioQuery = OnAudioQuery();
//   VideoPlayerController? videoController;
//   // ChewieController? chewieController;
//
//   List<my.MediaItem> queue = [];
//   int currentIndex = -1;
//   AssetEntity? currentEntity;
//   String? currentType;
//   bool isShuffle = false;
//   double playbackSpeed = 1.0;
//   bool _isLoading = false;
//
//   Offset miniPlayerPosition = const Offset(20, 500); // Default position
//
//   void updatePosition(Offset newPos) {
//     miniPlayerPosition = newPos;
//     notifyListeners();
//   }
//
//   void _listenToJustAudioEvents() {
//     audioPlayer.currentIndexStream.listen((index) {
//       if (currentIndex == -1) return;
//
//       if (index != null && index < queue.length) {
//         if (queue[index].type == 'video') {
//           audioPlayer.pause();
//           _playMediaAtIndex(index);
//         } else {
//           _syncStateWithIndex(index);
//         }
//       }
//     });
//
//     audioPlayer.playingStream.listen((isPlaying) async {
//       if (isPlaying) {
//         bool isOnline = await NetworkInfo.isConnected();
//         if (!isOnline) {
//           final currentContext = NavigatorKey.root.currentContext;
//           await audioPlayer.pause();
//
//           await audioPlayer.seek(audioPlayer.position);
//
//           await AppNotificationService.showNoInternetNotification(
//             title: "${currentContext?.tr("noInternetTitle")}",
//             bodyTitle: "${currentContext?.tr("noInternetBody")}",
//           );
//         }
//       }
//     });
//
//     audioPlayer.playerStateStream.listen((state) {
//       if (currentIndex == -1) return;
//       if (state.processingState == ProcessingState.completed) {
//         playNext();
//       }
//       notifyListeners();
//     });
//   }
//
//   // --- Playback Speed (audio only) ---
//   Future<void> setPlaybackSpeed(double speed) async {
//     playbackSpeed = speed;
//     if (currentType == 'audio') {
//       await audioPlayer.setSpeed(speed);
//     }
//     notifyListeners();
//   }
//
//   // --- Shuffle Logic ---
//   Future<void> toggleShuffle() async {
//     isShuffle = !isShuffle;
//
//     if (currentType == 'audio') {
//       await audioPlayer.setShuffleModeEnabled(isShuffle);
//     } else {
//       if (isShuffle) {
//         queue.shuffle();
//       } else {}
//     }
//     notifyListeners();
//   }
//
//   // --- Loop Logic ---
//   Future<void> toggleLoopMode() async {
//     if (currentType == 'audio') {
//       if (loopMode == LoopMode.off) {
//         loopMode = LoopMode.all;
//       } else if (loopMode == LoopMode.all) {
//         loopMode = LoopMode.one;
//       } else {
//         loopMode = LoopMode.off;
//       }
//       await audioPlayer.setLoopMode(loopMode);
//     } else {
//       // bool currentLoop = chewieController?.looping ?? false;
//       // chewieController?.dispose();
//       // videoController?.setLooping(!currentLoop);
//     }
//     notifyListeners();
//   }
//
//   Future<void> initAndPlay({
//     required List<AssetEntity> entities,
//     required String selectedId,
//   }) async {
//     if (_isLoading) return;
//     _isLoading = true;
//     // notifyListeners();
//
//     await Future.microtask(() async {
//       _isLoading = true;
//       notifyListeners();
//
//       try {
//         int newIndex = entities.indexWhere((item) => item.id == selectedId);
//         newIndex = newIndex == -1 ? 0 : newIndex;
//         if (currentType == 'audio' &&
//             audioPlayer.audioSource != null &&
//             entities.length == queue.length) {
//           // print("ty is ===> ------>  audio");
//           currentIndex = newIndex;
//           currentEntity = await AssetEntity.fromId(entities[newIndex].id);
//
//           await audioPlayer.seek(Duration.zero, index: currentIndex);
//           await audioPlayer.setSpeed(playbackSpeed);
//           audioPlayer.play();
//
//           _isLoading = false;
//           notifyListeners();
//           return;
//         }
//         await _clearPreviousPlayer();
//
//         queue = await _convertEntitiesToMediaItems(entities);
//         currentEntitiesList = entities;
//         if (queue.isEmpty) return;
//         currentIndex = newIndex;
//         currentType = queue[currentIndex].type;
//         currentEntity = await AssetEntity.fromId(queue[currentIndex].id);
//
//         if (currentType == 'audio') {
//           print("ty is ===> ------>  audio");
//           await _setupAudioQueue();
//           audioPlayer.play();
//         } else {
//           print("ty is ===> ------>  video");
//           // await _setupVideoPlayer(queue[currentIndex].path);
//         }
//       } catch (e) {
//         debugPrint("Init Error: $e");
//       } finally {
//         _isLoading = false;
//         notifyListeners();
//       }
//     });
//   }
//
//   Future<void> _setupAudioQueue() async {
//     // just_audio_background notification often uses `extras['android.color']`
//     // (and optionally `artUri`) for the current track. To keep startup fast,
//     // we extract palette only for `currentIndex` (not for the whole queue).
//     Color? extractedColor;
//     Uri? artUri;
//
//     try {
//       if (currentIndex >= 0 && currentIndex < queue.length) {
//         final currentItem = queue[currentIndex];
//         final Uint8List? artwork = await _audioQuery.queryArtwork(
//           Platform.isIOS ? currentItem.id.hashCode : int.tryParse(currentItem.id) ?? 0,
//           ArtworkType.AUDIO,
//           size: 500,
//         );
//
//         if (artwork != null && artwork.isNotEmpty) {
//           final palette = await PaletteGenerator.fromImageProvider(
//             MemoryImage(artwork),
//           );
//           extractedColor =
//               palette.lightMutedColor?.color ?? palette.dominantColor?.color;
//
//           final tempDir = await getTemporaryDirectory();
//           final File artworkFile = File('${tempDir.path}/thumb_${currentItem.id}.jpg');
//           await artworkFile.writeAsBytes(artwork);
//           artUri = Uri.file(artworkFile.path);
//         }
//       }
//     } catch (_) {
//       // ignore palette failures; notification will fall back to default colors
//     }
//
//     final defaultColorValue = const Color(0xFF3D57F9).value;
//     final currentColorValue = (extractedColor?.value ?? defaultColorValue);
//
//     final audioSources = queue.asMap().map((i, item) {
//       final title = item.path.split('/').last;
//
//       // Only set color/artUri for the currently playing track to avoid heavy work.
//       final isCurrent = i == currentIndex;
//       return MapEntry(
//         i,
//         AudioSource.uri(
//           Uri.file(item.path),
//           tag: bg.MediaItem(
//             id: item.id,
//             title: title,
//             displayTitle: title,
//             artist: "Local Media",
//             artUri: isCurrent ? artUri : null,
//             extras: <String, dynamic>{
//               'android.color': isCurrent ? currentColorValue : defaultColorValue,
//             },
//           ),
//         ),
//       );
//     }).values.toList();
//
//     await audioPlayer.setAudioSource(
//       ConcatenatingAudioSource(children: audioSources),
//       initialIndex: currentIndex,
//       initialPosition: Duration.zero,
//     );
//
//     // Apply speed for audio immediately after loading the new queue.
//     await audioPlayer.setSpeed(playbackSpeed);
//   }
//
//   Future<void> refreshCurrentEntity() async {
//     if (currentEntity != null) {
//       final updatedEntity = await currentEntity!.obtainForNewProperties();
//       if (updatedEntity != null) {
//         currentEntity = updatedEntity;
//         notifyListeners();
//       }
//     }
//   }
//
//   Future<List<my.MediaItem>> _convertEntitiesToMediaItems(
//       List<AssetEntity> entities,
//       ) async {
//     final files = await Future.wait(entities.map((entity) => entity.file));
//     final List<my.MediaItem> items = [];
//     for (int i = 0; i < entities.length; i++) {
//       final file = files[i];
//       if (file == null) continue;
//       final entity = entities[i];
//       items.add(
//         my.MediaItem(
//           id: entity.id,
//           path: file.path,
//           type: entity.type == AssetType.audio ? 'audio' : 'video',
//           isNetwork: false,
//           isFavourite: entity.isFavorite,
//         ),
//       );
//     }
//     return items;
//   }
//
//   Future<void> _setupAudioPlayer() async {
//     final audioSources = queue.map((item) {
//       return AudioSource.uri(
//         Uri.file(item.path),
//         tag: bg.MediaItem(
//           id: item.id,
//           title: item.path.split('/').last,
//           artist: "Local Media",
//         ),
//       );
//     }).toList();
//
//     await audioPlayer.setAudioSource(
//       ConcatenatingAudioSource(children: audioSources),
//       initialIndex: currentIndex,
//       initialPosition: Duration.zero,
//     );
//     audioPlayer.play();
//   }
//
//   LoopMode loopMode = LoopMode.off;
//
//   // Future<void> _setupVideoPlayer(String path) async {
//   //   videoController = VideoPlayerController.file(File(path));
//   //   await videoController!.initialize();
//   //
//   //   chewieController = ChewieController(
//   //     zoomAndPan: true,
//   //     aspectRatio: videoController!.value.aspectRatio,
//   //     autoPlay: true,
//   //     looping: loopMode == LoopMode.one,
//   //     videoPlayerController: videoController!,
//   //     deviceOrientationsOnEnterFullScreen: [
//   //       DeviceOrientation.landscapeLeft,
//   //       DeviceOrientation.landscapeRight,
//   //     ],
//   //     deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
//   //     materialProgressColors: ChewieProgressColors(
//   //       playedColor: const Color(0XFF3D57F9),
//   //       backgroundColor: const Color(0XFFF6F6F6),
//   //     ),
//   //     onSufflePressed: () => toggleShuffle(),
//   //     onNextVideo: () => playNext(),
//   //     onPreviousVideo: () => playPrevious(),
//   //     additionalOptions: (context) => _buildAdditionalOptions(context),
//   //   );
//   //
//   //   videoController!.addListener(_videoListener);
//   // }
//
//   void _videoListener() {
//     if (currentIndex == -1) return; // Safety check
//
//     if (videoController != null &&
//         videoController!.value.isInitialized &&
//         videoController!.value.position >= videoController!.value.duration) {
//       videoController!.removeListener(_videoListener);
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (currentIndex != -1) playNext();
//       });
//     }
//   }
//
//   void _syncStateWithIndex(int index) async {
//     currentIndex = index;
//     final item = queue[index];
//     currentEntity = await AssetEntity.fromId(item.id);
//     notifyListeners();
//   }
//
//   Future<void> playNext() async {
//     if (currentType == "video") {
//       // dispose();
//       Navigator.pop;
//       return;
//     }
//     if (queue.isEmpty) return;
//     int nextIndex = (currentIndex + 1) % queue.length;
//     await _playMediaAtIndex(nextIndex);
//   }
//
//   Future<void> playPrevious() async {
//     if (queue.isEmpty) return;
//     int prevIndex = (currentIndex - 1 < 0)
//         ? queue.length - 1
//         : currentIndex - 1;
//     await _playMediaAtIndex(prevIndex);
//   }
//
//   Future<List<AssetEntity>> _getCurrentEntities() async {
//     List<AssetEntity> list = [];
//
//     for (var item in queue) {
//       final ent = await AssetEntity.fromId(item.id);
//       if (ent != null) list.add(ent);
//     }
//     return list;
//   }
//
//   Future<void> _clearPreviousPlayer({bool keepAudioSource = false}) async {
//     if (videoController != null) {
//       videoController!.removeListener(_videoListener);
//
//       final oldVideoController = videoController;
//       // final oldChewieController = chewieController;
//
//       videoController = null;
//       // chewieController = null;
//
//       Future.delayed(Duration.zero, () {
//         oldVideoController?.dispose();
//         // oldChewieController?.dispose();
//       });
//     }
//
//     if (currentType == 'video' && audioPlayer.playing) {
//       await audioPlayer.pause();
//     }
//   }
//
//   Future<void> _initAudioSession() async {
//     final session = await AudioSession.instance;
//     await session.configure(const AudioSessionConfiguration.music());
//     session.interruptionEventStream.listen((event) {
//       if (event.begin)
//         pause();
//       else
//         resume();
//     });
//   }
//
//   void pause() {
//     currentType == 'audio' ? audioPlayer.pause() : videoController?.pause();
//     notifyListeners();
//   }
//
//   void resume() async {
//     bool isOnline = await NetworkInfo.isConnected();
//
//     if (!isOnline) {
//       final currentContext = NavigatorKey.root.currentContext;
//       debugPrint("Resume blocked: No Internet");
//
//       await AppNotificationService.showNoInternetNotification(
//         title: "${currentContext?.tr("noInternetTitle")}",
//         bodyTitle: "${currentContext?.tr("noInternetBody")}",
//       );
//
//       if (currentContext != null) {
//         AppToast.show(
//           currentContext,
//           "Internet connection lost. Video cannot be played.",
//           type: ToastType.error,
//         );
//       }
//
//       notifyListeners();
//       return;
//     }
//     currentType == 'audio' ? audioPlayer.play() : videoController?.play();
//     notifyListeners();
//   }
//
//   // Getters for UI
//   bool get isPlaying => currentType == 'audio'
//       ? audioPlayer.playing
//       : (videoController?.value.isPlaying ?? false);
//
//   Duration get position => currentType == 'audio'
//       ? audioPlayer.position
//       : (videoController?.value.position ?? Duration.zero);
//
//   Duration get duration => currentType == 'audio'
//       ? (audioPlayer.duration ?? Duration.zero)
//       : (videoController?.value.duration ?? Duration.zero);
//
//   my.MediaItem? get currentMediaItem =>
//       (currentIndex >= 0 && currentIndex < queue.length)
//           ? queue[currentIndex]
//           : null;
//
//   @override
//   void dispose() {
//     _networkSubscription?.cancel();
//     audioPlayer.dispose();
//     videoController?.dispose();
//     // chewieController?.dispose();
//     super.dispose();
//   }
//
//
//
//   bool _isAppInBackground() {
//     final state = WidgetsBinding.instance.lifecycleState;
//     return state == AppLifecycleState.paused ||
//         state == AppLifecycleState.detached;
//   }
//
//   Future<void> _playMediaAtIndex(int index) async {
//     if (index < 0 || index >= queue.length) return;
//
//     int targetIndex = index;
//
//     if (_isAppInBackground()) {
//       int itemsChecked = 0;
//
//       while (queue[targetIndex].type == 'video' &&
//           itemsChecked < queue.length) {
//         debugPrint("Background mode: Skipping video at index $targetIndex");
//         targetIndex = (targetIndex + 1) % queue.length;
//         itemsChecked++;
//       }
//
//       if (itemsChecked >= queue.length) {
//         debugPrint("No audio found to play in background. Stopping.");
//         audioPlayer.stop();
//         currentIndex = -1;
//         notifyListeners();
//         return;
//       }
//     }
//
//     currentIndex = targetIndex;
//     final item = queue[currentIndex];
//     currentType = item.type;
//     currentEntity = await AssetEntity.fromId(item.id);
//
//     await _clearPreviousPlayer(keepAudioSource: true);
//
//     if (currentType == 'audio') {
//       await audioPlayer.seek(Duration.zero, index: currentIndex);
//       audioPlayer.play();
//     } else {
//       // await _setupVideoPlayer(item.path);
//     }
//
//     notifyListeners();
//   }
//
//   Future<void> savePlayerState() async {
//     final box = Hive.box('player_state');
//     if (currentIndex == -1) {
//       await box.clear();
//       return;
//     }
//     if (currentMediaItem != null) {
//       await box.put('last_item_id', currentMediaItem!.id);
//       await box.put('last_position', audioPlayer.position.inMilliseconds);
//       await box.put('last_type', currentType);
//     }
//   }
//
//   Future<void> restoreLastSession() async {
//     final box = Hive.box('player_state');
//     final String? lastId = box.get('last_item_id');
//     final int? lastPos = box.get('last_position');
//
//     if (lastId != null) {
//       // AssetEntity? entity = ... find by id ...
//
//       // await audioPlayer.setAudioSource(...);
//       // await audioPlayer.seek(Duration(milliseconds: lastPos ?? 0));
//       // notifyListeners();
//     }
//   }
//
//   my.MediaItem? _currentMediaItem;
//
//   set currentMediaItem(my.MediaItem? value) {
//     _currentMediaItem = value;
//     notifyListeners();
//   }
//
//   AssetEntity? _currentEntity;
//
//   void stopAndClose() {
//     if (videoController != null) {
//       videoController!.removeListener(_videoListener);
//       videoController!.pause();
//       videoController!.dispose();
//       videoController = null;
//     }
//
//     // if (chewieController != null) {
//     //   chewieController!.dispose();
//     //   chewieController = null;
//     // }
//     audioPlayer.stop();
//     queue = [];
//     currentIndex = -1;
//     currentMediaItem = null;
//     currentEntity = null;
//     currentType = null;
//
//     notifyListeners();
//   }
// }



/*
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
 */

/*
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
 */