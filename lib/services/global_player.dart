import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:just_audio_background/just_audio_background.dart' as bg;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/media_item.dart' as my;
import 'package:just_audio/just_audio.dart' hide PlayerState;
import '../utils/app_imports.dart';
import 'connectivity_service.dart';
import 'notification_service.dart';
import 'video_playback_adapter.dart';
//youtube_explode_dart:

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
    if (_videoAdapter.duration != Duration.zero && target > _videoAdapter.duration) {
      await _videoAdapter.seekTo(_videoAdapter.duration);
      return;
    }
    await _videoAdapter.seekTo(target);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    playbackSpeed = speed;
    await _videoAdapter.setPlaybackSpeed(speed);
  }
  Future<bool> isPipSupported() => _videoAdapter.isPipSupported();
  Future<bool> enterPipMode() => _videoAdapter.enterPip();
  Future<void> pauseVideo() => _videoAdapter.pause();
  Future<void> playVideo() => _videoAdapter.play();

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
  void addVideoListener(VoidCallback listener) => _videoAdapter.addListener(listener);
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

  Future<void> init(List<AssetEntity> list, int index, Function onUpdate,
      {int? seekToMs}) async {
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
          await _videoAdapter
              .initialize()
              .timeout(const Duration(seconds: 10));
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
    _videoAdapter.isPlaying ? _videoAdapter.pause() : _videoAdapter.play();
  }



  Future<void> playNetworkStream(String url, VoidCallback onUpdate) async {
    // YouTube Explode àª¨à«‹ àª“àª¬à«àªœà«‡àª•à«àªŸ àª²àª¿àª®àª¿àªŸà«‡àª¡ àª°àª¿àª•à«àªµà«‡àª¸à«àªŸ àª®àª¾àªŸà«‡
    final yt = YoutubeExplode();

    try {
      isInitialized = false;
      onUpdate();

      String finalUrl = url;

      if (url.contains("youtube.com") || url.contains("youtu.be")) {
        // à«§. àª®àª¾àª¤à«àª° Video ID àªàª•à«àª¸àªŸà«àª°à«‡àª•à«àªŸ àª•àª°à«‹ (àª•à«‹àªˆ àª°àª¿àª•à«àªµà«‡àª¸à«àªŸ àªµàª—àª°)
        var videoId = VideoId.parseVideoId(url);
        if (videoId == null) throw "Invalid YouTube URL";

        // à«¨. àª®àª¾àª¤à«àª° àª¸à«àªŸà«àª°à«€àª® àª®à«‡àª¨àª¿àª«à«‡àª¸à«àªŸ àª«à«‡àªš àª•àª°à«‹ (àª† àª¸à«Œàª¥à«€ 'Lite' àª°àª¿àª•à«àªµà«‡àª¸à«àªŸ àª›à«‡)
        var manifest = await yt.videos.streamsClient.getManifest(videoId);

        // à«©. Muxed àª¸à«àªŸà«àª°à«€àª® àªªàª¸àª‚àª¦ àª•àª°à«‹ (àªœà«‡àª®àª¾àª‚ Audio + Video àª¬àª‚àª¨à«‡ àª¹à«‹àª¯)
        // .withHighestBitrate() àª¨à«‡ àª¬àª¦àª²à«‡ .first àªµàª¾àªªàª°àªµàª¾àª¥à«€ àªªàª£ àª¸à«àªªà«€àª¡ àªµàª§àª¶à«‡
        var streamInfo = manifest.muxed.withHighestBitrate();
        finalUrl = streamInfo.url.toString();
      }

      // àªœà«‚àª¨àª¾ àª•àª‚àªŸà«àª°à«‹àª²àª°àª¨à«‡ àª¸àª¾àª« àª•àª°à«‹
      if (controller != null) {
        clearListener();
        await _videoAdapter.dispose();
      }

      // àª¤àª®àª¾àª°àª¾ àªœ àªªà«àª²à«‡àª¯àª°àª¨àª¾ àª•àª‚àªŸà«àª°à«‹àª²àª°àª®àª¾àª‚ àª¨à«‡àªŸàªµàª°à«àª• URL àª¸à«‡àªŸ àª•àª°à«‹
      await _videoAdapter.openNetwork(finalUrl);

      await _videoAdapter.initialize();

      // àª²àª¿àª¸à«àªŸàª¨àª° àª¸à«‡àªŸ àª•àª°à«‹ àªœà«‡àª¥à«€ àªªà«àª°à«‹àª—à«àª°à«‡àª¸ àª¬àª¾àª° àªšàª¾àª²à«‡
      _currentListener = () {
        if (isInitialized && controller != null) {
          onUpdate();
        }
      };
      _videoAdapter.addListener(_currentListener!);

      isInitialized = true;
      await _videoAdapter.play();
      onUpdate();

    } catch (e) {
      print("âŒ Stream Error: $e");
      isInitialized = false;
      onUpdate();
    } finally {
      yt.close(); // àª•àª¨à«‡àª•à«àª¶àª¨ àª•à«àª²à«‹àª àª•àª°àªµà«àª‚ àª«àª°àªœàª¿àª¯àª¾àª¤ àª›à«‡
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

  void _listenToNetworkChanges() {
    _networkSubscription = Connectivity().onConnectivityChanged.listen((
        results,
        ) {
      bool isOffline = results.contains(ConnectivityResult.none);

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
  VideoPlayerController? videoController;
  // ChewieController? chewieController;

  List<my.MediaItem> queue = [];
  int currentIndex = -1;
  AssetEntity? currentEntity;
  String? currentType;
  bool isShuffle = false;
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
      if (isPlaying) {
        bool isOnline = await NetworkInfo.isConnected();
        if (!isOnline) {
          final currentContext = NavigatorKey.root.currentContext;
          await audioPlayer.pause();

          await audioPlayer.seek(audioPlayer.position);

          await AppNotificationService.showNoInternetNotification(
            title: "${currentContext?.tr("noInternetTitle")}",
            bodyTitle: "${currentContext?.tr("noInternetBody")}",
          );
        }
      }
    });

    audioPlayer.playerStateStream.listen((state) {
      if (currentIndex == -1) return;
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
      notifyListeners();
    });
  }

  // --- Shuffle Logic ---
  Future<void> toggleShuffle() async {
    isShuffle = !isShuffle;

    if (currentType == 'audio') {
      await audioPlayer.setShuffleModeEnabled(isShuffle);
    } else {
      if (isShuffle) {
        queue.shuffle();
      } else {}
    }
    notifyListeners();
  }

  // --- Loop Logic ---
  Future<void> toggleLoopMode() async {
    if (currentType == 'audio') {
      if (loopMode == LoopMode.off) {
        loopMode = LoopMode.all;
      } else if (loopMode == LoopMode.all) {
        loopMode = LoopMode.one;
      } else {
        loopMode = LoopMode.off;
      }
      await audioPlayer.setLoopMode(loopMode);
    } else {
      // bool currentLoop = chewieController?.looping ?? false;
      // chewieController?.dispose();
      // videoController?.setLooping(!currentLoop);
    }
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
          audioPlayer.play();

          _isLoading = false;
          notifyListeners();
          return;
        }
        await _clearPreviousPlayer();

        queue = await _convertEntitiesToMediaItems(entities);
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
    List<my.MediaItem> items = [];
    for (var entity in entities) {
      final file = await entity.file;
      if (file != null) {
        print("entity.type is ====== ${entity.type}");
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
      // dispose();
      Navigator.pop;
      return;
    }
    if (queue.isEmpty) return;
    int nextIndex = (currentIndex + 1) % queue.length;
    await _playMediaAtIndex(nextIndex);
  }

  Future<void> playPrevious() async {
    if (queue.isEmpty) return;
    int prevIndex = (currentIndex - 1 < 0)
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

  void resume() async {
    bool isOnline = await NetworkInfo.isConnected();

    if (!isOnline) {
      final currentContext = NavigatorKey.root.currentContext;
      debugPrint("Resume blocked: No Internet");

      await AppNotificationService.showNoInternetNotification(
        title: "${currentContext?.tr("noInternetTitle")}",
        bodyTitle: "${currentContext?.tr("noInternetBody")}",
      );

      if (currentContext != null) {
        AppToast.show(
          currentContext,
          "Internet connection lost. Video cannot be played.",
          type: ToastType.error, // àªœà«‹ àª¤àª®àª¾àª°à«€ àªàªªàª®àª¾àª‚ type àª¸àªªà«‹àª°à«àªŸ àª•àª°àª¤à«àª‚ àª¹à«‹àª¯ àª¤à«‹
        );
      }

      notifyListeners();
      return;
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