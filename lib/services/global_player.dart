import 'package:just_audio_background/just_audio_background.dart'
as bg;
import '../models/media_item.dart' as my;
import 'package:just_audio/just_audio.dart' hide PlayerState;
import '../utils/app_imports.dart';

class GlobalPlayer extends ChangeNotifier {
  static final GlobalPlayer _instance = GlobalPlayer._internal();

  factory GlobalPlayer() => _instance;

  GlobalPlayer._internal() {
    _initAudioSession();
    _listenToJustAudioEvents();
  }

  // àªªà«àª²à«‡àª¯àª°à«àª¸
  final AudioPlayer audioPlayer = AudioPlayer();
  VideoPlayerController? videoController;
  ChewieController? chewieController;

  // àª¡à«‡àªŸàª¾ àªµà«‡àª°à«€àªàª¬àª²à«àª¸
  List<my.MediaItem> queue = [];
  int currentIndex = -1;
  AssetEntity? currentEntity;
  String? currentType; // 'audio' àª…àª¥àªµàª¾ 'video'
  bool isShuffle = false;
  bool _isLoading = false;

  // à«§. Just Audio àª¨àª¾ àª‡àªµà«‡àª¨à«àªŸà«àª¸ àª¸àª¾àª‚àª­àª³à«‹ (UI àª…àªªàª¡à«‡àªŸ àª®àª¾àªŸà«‡)
  void _listenToJustAudioEvents() {
    audioPlayer.currentIndexStream.listen((index) {
      // àªœà«‹ àªªà«àª²à«‡àª¯àª° àª•à«àª²à«‹àª àª¥àªˆ àª—àª¯à«‹ àª¹à«‹àª¯ àª¤à«‹ àªªà«àª°à«‹àª¸à«‡àª¸ àª¨ àª•àª°àªµà«€
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

    audioPlayer.playerStateStream.listen((state) {
      if (currentIndex == -1) return; // àªªà«àª²à«‡àª¯àª° àª¬àª‚àª§ àª¹à«‹àª¯ àª¤à«‹ àª“àªŸà«‹-àª¨à«‡àª•à«àª¸à«àªŸ àª¨ àª•àª°àªµà«àª‚

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
      // àªµà«€àª¡àª¿àª¯à«‹ àª®àª¾àªŸà«‡ àªœà«‹ àª¶àª«àª² àª•àª°àªµà«àª‚ àª¹à«‹àª¯ àª¤à«‹ àª²àª¿àª¸à«àªŸàª¨à«‡ àª®à«‡àª¨à«àª¯à«àª…àª²à«€ àª¶àª«àª² àª•àª°àªµà«àª‚ àªªàª¡à«‡
      if (isShuffle) {
        queue.shuffle();
      } else {
        // àªªàª¾àª›à«àª‚ àª“àª°àª¿àªœàª¿àª¨àª² àª¸àª¿àª•à«àªµàª¨à«àª¸àª®àª¾àª‚ àª²àª¾àªµàªµàª¾ àª®àª¾àªŸà«‡ àª¡à«‡àªŸàª¾ àª°àª¿-àª²à«‹àª¡ àª•àª°àªµà«‹ àªªàª¡à«‡
        // (àª¨à«‹àª‚àª§: àª† àª®àª¾àªŸà«‡ àª“àª°àª¿àªœàª¿àª¨àª² àª²àª¿àª¸à«àªŸàª¨à«‹ àªµà«‡àª°à«€àªàª¬àª² àª¸àª¾àªšàªµàªµà«‹ àªªàª¡à«‡)
      }
    }
    notifyListeners();
  }

  // --- Loop Logic ---
  Future<void> toggleLoopMode() async {
    if (currentType == 'audio') {
      if (loopMode == LoopMode.off) {
        loopMode = LoopMode.all; // àª†àª–à«àª‚ àª²àª¿àª¸à«àªŸ àª²à«‚àªª àª¥àª¶à«‡
      } else if (loopMode == LoopMode.all) {
        loopMode = LoopMode.one; // àªàª• àªœ àª—à«€àª¤ àª²à«‚àªª àª¥àª¶à«‡
      } else {
        loopMode = LoopMode.off; // àª²à«‚àªª àª¬àª‚àª§
      }
      await audioPlayer.setLoopMode(loopMode);
    } else {
      // àªµà«€àª¡àª¿àª¯à«‹ àª®àª¾àªŸà«‡ àª²à«‚àªª àª²à«‹àªœàª¿àª• (àª«àª•à«àª¤ àªàª• àªµà«€àª¡àª¿àª¯à«‹ àª²à«‚àªª àª®àª¾àªŸà«‡)
      bool currentLoop = chewieController?.looping ?? false;
      chewieController?.dispose(); // àªœà«àª¨àª¾ àª•àª¨à«àªŸà«àª°à«‹àª²àª°àª¨à«‡ àª°àª¿àª«à«àª°à«‡àª¶ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡

      // àª¨àªµà«àª‚ àª²à«‹àªœàª¿àª• àª¸à«‡àªŸ àª•àª°à«‹ (àª† àªµà«€àª¡àª¿àª¯à«‹ àªªà«àª²à«‡àª¯àª°àª¨àª¾ àª•àª¨à«àªŸà«àª°à«‹àª²àª° àªªàª° àª†àª§àª¾àª°àª¿àª¤ àª›à«‡)
      videoController?.setLooping(!currentLoop);
    }
    notifyListeners();
  }

  // à«¨. MAIN ENTRY POINT: àª²àª¿àª¸à«àªŸ àª…àª¨à«‡ ID àª¦à«àªµàª¾àª°àª¾ àªªà«àª²à«‡ àª•àª°à«‹
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

          // àª†àª–à«àª‚ àª¸à«‡àªŸàª…àªª àª«àª°à«€àª¥à«€ àª•àª°àªµàª¾àª¨à«‡ àª¬àª¦àª²à«‡ àª¡àª¾àª¯àª°à«‡àª•à«àªŸ àª¤à«‡ àª‡àª¨à«àª¡à«‡àª•à«àª¸ àªªàª° àªœàª¾àªµ
          await audioPlayer.seek(Duration.zero, index: currentIndex);
          audioPlayer.play();

          _isLoading = false;
          notifyListeners();
          return; // àª…àª¹à«€àª‚àª¥à«€ àªœ àª¬àª¹àª¾àª° àª¨à«€àª•àª³à«€ àªœàª¾àªµ
        }
        await _clearPreviousPlayer();

        // à«ª. àª¡à«‡àªŸàª¾ àª¸à«‡àªŸ àª•àª°à«‹
        queue = await _convertEntitiesToMediaItems(entities);
        currentIndex = newIndex;
        currentType = queue[currentIndex].type;
        currentEntity = await AssetEntity.fromId(queue[currentIndex].id);

        if (currentType == 'audio') {
          print("ty is ===> ------>  audio");
          await _setupAudioQueue(); // àª†àª®àª¾àª‚ initialIndex: currentIndex àª›à«‡ àªœ
          audioPlayer.play();
        } else {
          print("ty is ===> ------>  video");
          await _setupVideoPlayer(queue[currentIndex].path);
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

    // àª…àª¹à«€àª‚ currentIndex àª¬àª°àª¾àª¬àª° àª¹à«‹àªµà«‹ àªœà«‹àªˆàª
    await audioPlayer.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: currentIndex, // àª† àª²àª¾àªˆàª¨ àª¬àª°àª¾àª¬àª° àª¹à«‹àªµà«€ àªœà«‹àªˆàª
      initialPosition: Duration.zero,
    );
  }

  // GlobalPlayer class àª¨à«€ àª…àª‚àª¦àª°
  Future<void> refreshCurrentEntity() async {
    if (currentEntity != null) {
      // obtainForNewProperties() àª²à«‡àªŸà«‡àª¸à«àªŸ àª¸àª¿àª¸à«àªŸàª® àª¸à«àªŸà«‡àªŸ (Favorite status) àª²àª¾àªµàª¶à«‡
      final updatedEntity = await currentEntity!.obtainForNewProperties();
      if (updatedEntity != null) {
        currentEntity = updatedEntity;
        notifyListeners(); // àª† MiniPlayer àª¨àª¾ AnimatedBuilder àª¨à«‡ àªŸà«àª°àª¿àª—àª° àª•àª°àª¶à«‡
      }
    }
  }

  // à«©. Entity àª²àª¿àª¸à«àªŸàª¨à«‡ MediaItem àª²àª¿àª¸à«àªŸàª®àª¾àª‚ àª¬àª¦àª²à«‹ (Sequence àªœàª¾àª³àªµà«€àª¨à«‡)
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

  // à«ª. Audio Player àª¸à«‡àªŸàª…àªª
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

  // à««. Video Player àª¸à«‡àªŸàª…àªª
  Future<void> _setupVideoPlayer(String path) async {
    videoController = VideoPlayerController.file(File(path));
    await videoController!.initialize();

    chewieController = ChewieController(
      zoomAndPan: true,
      aspectRatio: videoController!.value.aspectRatio,
      autoPlay: true,
      looping: loopMode == LoopMode.one,
      videoPlayerController: videoController!,
      deviceOrientationsOnEnterFullScreen: [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0XFF3D57F9),
        backgroundColor: const Color(0XFFF6F6F6),
      ),
      onSufflePressed: () => toggleShuffle(),
      onNextVideo: () => playNext(),
      onPreviousVideo: () => playPrevious(),
      additionalOptions: (context) => _buildAdditionalOptions(context),
    );

    videoController!.addListener(_videoListener);
  }

  void _videoListener() {
    if (currentIndex == -1) return; // Safety check

    if (videoController != null &&
        videoController!.value.isInitialized &&
        videoController!.value.position >= videoController!.value.duration) {
      videoController!.removeListener(_videoListener);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentIndex != -1) playNext(); // àª«àª°à«€ àªšà«‡àª• àª•àª°à«‹
      });
    }
  }

  // à«¬. àª¸àª¿àª‚àª• àª¸à«àªŸà«‡àªŸ (àªœà«àª¯àª¾àª°à«‡ àª—à«€àª¤ àª¬àª¦àª²àª¾àª¯ àª¤à«àª¯àª¾àª°à«‡)
  void _syncStateWithIndex(int index) async {
    currentIndex = index;
    final item = queue[index];
    currentEntity = await AssetEntity.fromId(item.id);
    notifyListeners();
  }

  // à«­. àª¨à«‡àª•à«àª¸à«àªŸ/àªªà«àª°àª¿àªµàª¿àª¯àª¸ àª•àª‚àªŸà«àª°à«‹àª²
  Future<void> playNext() async {
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

  // Helper: àª•àª°àª‚àªŸ àªàª¨à«àªŸàª¿àªŸà«€ àª²àª¿àª¸à«àªŸ àªªàª¾àª›à«àª‚ àª®à«‡àª³àªµàªµàª¾ àª®àª¾àªŸà«‡ (àªµà«€àª¡àª¿àª¯à«‹ àª¸à«àªµàª¿àªšàª¿àª‚àª— àªµàª–àª¤à«‡ àª•àª¾àª® àª²àª¾àª—àª¶à«‡)
  Future<List<AssetEntity>> _getCurrentEntities() async {
    List<AssetEntity> list = [];
    for (var item in queue) {
      final ent = await AssetEntity.fromId(item.id);
      if (ent != null) list.add(ent);
    }
    return list;
  }

  // à«®. àªªà«àª²à«‡àª¯àª° àª•à«àª²à«€àª¨àª…àªª
  Future<void> _clearPreviousPlayer({bool keepAudioSource = false}) async {
    if (videoController != null) {
      // àª²àª¿àª¸àª¨àª° àªªàª¹à«‡àª²àª¾ àª¦à«‚àª° àª•àª°à«‹
      videoController!.removeListener(_videoListener);

      // àª¸à«€àª§à«àª‚ àª¡àª¿àª¸à«àªªà«‹àª àª•àª°à«‹, pause() àª•àª°àªµàª¾àª¨à«€ àªœàª°à«‚àª° àª¨àª¥à«€ àªœà«‹ àª¤àª®à«‡ àª¤à«‡àª¨à«‡ àª¤àª°àª¤ àªœ àª•àª¾àª¢à«€ àª¨àª¾àª–àªµàª¾àª¨àª¾ àª¹à«‹àªµ
      final oldVideoController = videoController;
      final oldChewieController = chewieController;

      videoController = null;
      chewieController = null;

      // àª¡àª¿àª¸à«àªªà«‹àªàª¨à«‡ àª«à«àª°à«‡àª® àªªàª›à«€ àª°àª¨ àª•àª°à«‹ àªœà«‡àª¥à«€ àª¬àª¿àª²à«àª¡àª®àª¾àª‚ àª¨àª¡àª¤àª° àª¨ àª¥àª¾àª¯
      Future.delayed(Duration.zero, () {
        oldVideoController?.dispose();
        oldChewieController?.dispose();
      });
    }

    if (currentType == 'video' && audioPlayer.playing) {
      await audioPlayer.pause();
    }
  }

  // à«¯. àª“àª¡àª¿àª¯à«‹ àª¸à«‡àª¶àª¨ (Interruption handle àª•àª°àªµàª¾)
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

  // àª•àª‚àªŸà«àª°à«‹àª²à«àª¸
  void pause() {
    currentType == 'audio' ? audioPlayer.pause() : videoController?.pause();
    notifyListeners();
  }

  void resume() {
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
    audioPlayer.dispose();
    videoController?.dispose();
    chewieController?.dispose();
    super.dispose();
  }

  _buildAdditionalOptions(BuildContext context) {
    return [
      OptionItem(
        controlType: ControlType.miniVideo,
        onTap: (context) {
          Navigator.pop(context);
        },
        iconData: Icons.screen_rotation,
        title: "Mini Screen",
        iconImage: AppSvg.icMiniScreen,
      ),
      OptionItem(
        controlType: ControlType.volume,
        onTap: (context) {
          // toggleRotation();
          // Navigator.pop(context);
        },
        iconData: Icons.screen_rotation,
        title: "Volume",
        iconImage: AppSvg.icVolumeOff,
      ),
      OptionItem(
        controlType: ControlType.playbackSpeed,
        onTap: (context) {
          // toggleShuffle();
        },
        iconData: Icons.shuffle,
        title: "video speed",
        iconImage: AppSvg.ic2x,
      ),

      OptionItem(
        controlType: ControlType.shuffle,
        onTap: (context) => () {
          toggleShuffle();
        },
        iconData: Icons.shuffle,
        title: "Shuffle",
        iconImage: AppSvg.icShuffle,
      ),
      OptionItem(
        controlType: ControlType.theme,
        onTap: (context) {
          toggleShuffle();
        },
        iconData: Icons.shuffle,
        title: "dark",
        iconImage: AppSvg.icDarkMode,
      ),
      OptionItem(
        onTap: (context) {
          // chewie!.videoPlayerController.value.cancelAndRestartTimer();
          //
          // if (videoPlayerLatestValue.volume == 0) {
          //   chewie!.videoPlayerController.setVolume(chewie.videoPlayerController.videoPlayerOptions.);
          //   // controller.setVolume(_latestVolume ?? 0.5);
          // } else {
          //   _latestVolume = controller.value.volume;
          //   controller.setVolume(0.0);
          // }
        },
        controlType: ControlType.loop,
        iconData: Icons.shuffle,
        title: "Loop",
        iconImage: AppSvg.icLoop,
      ),
    ];
  }

  bool _isAppInBackground() {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached;
  }

  Future<void> _playMediaAtIndex(int index) async {
    if (index < 0 || index >= queue.length) return;

    int targetIndex = index;

    // à«§. àªœà«‹ àªàªª àª¬à«‡àª•àª—à«àª°àª¾àª‰àª¨à«àª¡àª®àª¾àª‚ àª¹à«‹àª¯, àª¤à«‹ àª²à«‚àªª àª«à«‡àª°àªµà«€àª¨à«‡ àªšà«‡àª• àª•àª°à«‹ àª•à«‡ àª¨à«‡àª•à«àª¸à«àªŸ àª“àª¡àª¿àª¯à«‹ àª•à«àª¯àª¾àª‚ àª›à«‡
    if (_isAppInBackground()) {
      int itemsChecked = 0;

      // àªœà«àª¯àª¾àª‚ àª¸à«àª§à«€ àªµàª¿àª¡àª¿àª¯à«‹ àª®àª³à«‡ àª¤à«àª¯àª¾àª‚ àª¸à«àª§à«€ àª†àª—àª³ àªµàª§à«‹
      while (queue[targetIndex].type == 'video' &&
          itemsChecked < queue.length) {
        debugPrint("Background mode: Skipping video at index $targetIndex");
        targetIndex = (targetIndex + 1) % queue.length;
        itemsChecked++;
      }

      // àªœà«‹ àª†àª–àª¾ àª²àª¿àª¸à«àªŸàª®àª¾àª‚ àª•à«àª¯àª¾àª‚àª¯ àª“àª¡àª¿àª¯à«‹ àª¨ àª®àª³à«‡, àª¤à«‹ àªªà«àª²à«‡àª¯àª° àª¸à«àªŸà«‹àªª àª•àª°à«‹
      if (itemsChecked >= queue.length) {
        debugPrint("No audio found to play in background. Stopping.");
        audioPlayer.stop();
        currentIndex = -1;
        notifyListeners();
        return;
      }
    }

    // à«¨. àª¹àªµà«‡ àª¸àª¾àªšà«‹ àªˆàª¨à«àª¡à«‡àª•à«àª¸ àª¸à«‡àªŸ àª•àª°à«‹
    currentIndex = targetIndex;
    final item = queue[currentIndex];
    currentType = item.type;
    currentEntity = await AssetEntity.fromId(item.id);

    // à«©. àªªà«àª²à«‡àª¯àª° àª•à«àª²à«€àª¨àª…àªª
    await _clearPreviousPlayer(keepAudioSource: true);

    if (currentType == 'audio') {
      // Just Audio àªªà«àª²à«‡àª¯àª°àª¨à«‡ àª¤à«‡ àªˆàª¨à«àª¡à«‡àª•à«àª¸ àªªàª° àª²àªˆ àªœàªˆàª¨à«‡ àªªà«àª²à«‡ àª•àª°à«‹
      await audioPlayer.seek(Duration.zero, index: currentIndex);
      audioPlayer.play();
    } else {
      // àª† àª²àª¾àªˆàª¨ àª¤à«àª¯àª¾àª°à«‡ àªœ àª°àª¨ àª¥àª¶à«‡ àªœà«àª¯àª¾àª°à«‡ àªàªª àª«à«‹àª°àª—à«àª°àª¾àª‰àª¨à«àª¡àª®àª¾àª‚ àª¹àª¶à«‡
      await _setupVideoPlayer(item.path);
    }

    notifyListeners();
  }

  // àªªà«àª²à«‡àª¯àª°àª¨à«àª‚ àª¸à«àªŸà«‡àªŸ àª¸à«‡àªµ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡
  Future<void> savePlayerState() async {
    final box = Hive.box('player_state');
    if (currentIndex == -1) {
      await box.clear(); // àªœà«‹ àªªà«àª²à«‡àª¯àª° àª¬àª‚àª§ àª¹à«‹àª¯ àª¤à«‹ àª¬àª§à«àª‚ àª¸àª¾àª« àª•àª°à«‹
      return;
    }
    if (currentMediaItem != null) {
      await box.put('last_item_id', currentMediaItem!.id);
      await box.put('last_position', audioPlayer.position.inMilliseconds);
      await box.put('last_type', currentType);
      // àª†àª–à«àª‚ àª²àª¿àª¸à«àªŸ àª¸à«‡àªµ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡ àª¤àª®à«‡ IDs àª¨à«€ àª¯àª¾àª¦à«€ àª¸à«àªŸà«‹àª° àª•àª°à«€ àª¶àª•à«‹ àª›à«‹
    }
  }

  Future<void> restoreLastSession() async {
    final box = Hive.box('player_state');
    final String? lastId = box.get('last_item_id');
    final int? lastPos = box.get('last_position');

    if (lastId != null) {
      // àª¤àª®àª¾àª°à«‡ àª¤àª®àª¾àª°à«€ àªàª¸à«‡àªŸà«àª¸àª®àª¾àª‚àª¥à«€ àª† ID àªµàª¾àª³à«€ àªàª¨à«àªŸàª¿àªŸà«€ àª¶à«‹àª§àªµà«€ àªªàª¡àª¶à«‡
      // àª§àª¾àª°à«‹ àª•à«‡ àª¤àª®àª¾àª°à«€ àªªàª¾àª¸à«‡ àª¬àª§à«€ àªàª¸à«‡àªŸà«àª¸àª¨à«àª‚ àª²àª¿àª¸à«àªŸ àª›à«‡
      // AssetEntity? entity = ... find by id ...

      // àªªà«àª²à«‡àª¯àª° àª²à«‹àª¡ àª•àª°à«‹ àªªàª£ àªªà«àª²à«‡ àª¨ àª•àª°à«‹ (àª®àª¾àª¤à«àª° àª¸à«‡àªŸàª…àªª àª•àª°à«‹)
      // await audioPlayer.setAudioSource(...);
      // await audioPlayer.seek(Duration(milliseconds: lastPos ?? 0));
      // notifyListeners();
    }
  }

  // àªªà«àª°àª¾àª‡àªµà«‡àªŸ àªµà«‡àª°à«€àªàª¬àª²
  my.MediaItem? _currentMediaItem;

  // Setter (àª† àª‰àª®à«‡àª°àªµàª¾àª¥à«€ àª­à«‚àª² àª¦à«‚àª° àª¥àª¶à«‡)
  set currentMediaItem(my.MediaItem? value) {
    _currentMediaItem = value;
    notifyListeners();
  }

  // àª àªœ àª°à«€àª¤à«‡ currentEntity àª®àª¾àªŸà«‡ àªªàª£ Setter àª¬àª¨àª¾àªµà«€ àª²à«‹
  AssetEntity? _currentEntity;

  void stopAndClose() {
    // à«§. àªµà«€àª¡àª¿àª¯à«‹ àª•àª‚àªŸà«àª°à«‹àª²àª°àª¨à«‡ àªªà«àª°à«‹àªªàª°àª²à«€ àª…àªŸàª•àª¾àªµà«‹
    if (videoController != null) {
      videoController!.removeListener(_videoListener);
      videoController!.pause();
      videoController!.dispose();
      videoController = null;
    }

    if (chewieController != null) {
      chewieController!.dispose();
      chewieController = null;
    }

    // à«¨. àª“àª¡àª¿àª¯à«‹ àªªà«àª²à«‡àª¯àª° àª•àª®à«àªªà«àª²à«€àªŸàª²à«€ àª¸à«àªŸà«‹àªª àª•àª°à«‹
    audioPlayer.stop();

    // à«©. àª¡à«‡àªŸàª¾ àª•à«àª²àª¿àª¯àª° àª•àª°à«‹
    queue = [];
    currentIndex = -1;
    currentMediaItem = null;
    currentEntity = null;
    currentType = null;

    // à«ª. àª²àª¿àª¸àª¨àª°à«àª¸àª¨à«‡ àª›à«‡àª²à«àª²à«€ àªµàª¾àª° àªœàª¾àª£ àª•àª°à«‹
    notifyListeners();
  }
}