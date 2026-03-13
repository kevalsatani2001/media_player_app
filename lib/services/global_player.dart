import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:just_audio_background/just_audio_background.dart' as bg;
import '../models/media_item.dart' as my;
import 'package:just_audio/just_audio.dart' hide PlayerState;
import '../utils/app_imports.dart';
import 'connectivity_service.dart';
import 'notification_service.dart';

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
  ChewieController? chewieController;

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
          // à«§. àª¤àª°àª¤ àªœ àªªà«‹àª àª•àª°à«‹
          await audioPlayer.pause();

          // à«¨. àªªà«‹àªàª¿àª¶àª¨àª¨à«‡ àªªàª¾àª›à«€ àª¤à«àª¯àª¾àª‚ àªœ àª²àªˆ àªœàª¾àª“ àªœà«àª¯àª¾àª‚ àª¹àª¤à«€ (àªœà«‡àª¥à«€ à«§ àª¸à«‡àª•àª¨à«àª¡ àª†àª—àª³ àª¨ àªµàª§à«‡)
          // àª†àª¨àª¾àª¥à«€ àªªà«‡àª²à«€ à«§ àª¸à«‡àª•àª¨à«àª¡àª¨à«€ àªªà«àª²à«‡ àª¥àªµàª¾àª¨à«€ àª…àª¸àª° àªœàª¤à«€ àª°àª¹à«‡àª¶à«‡
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
      bool currentLoop = chewieController?.looping ?? false;
      chewieController?.dispose();
      videoController?.setLooping(!currentLoop);
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
        if (currentIndex != -1) playNext(); // Ã ÂªÂ«Ã ÂªÂ°Ã Â«â‚¬ Ã ÂªÅ¡Ã Â«â€¡Ã Âªâ€¢ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
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
      final oldChewieController = chewieController;

      videoController = null;
      chewieController = null;

      Future.delayed(Duration.zero, () {
        oldVideoController?.dispose();
        oldChewieController?.dispose();
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
      // àªªà«àª²à«‡àª¯àª°àª¨à«‡ àªªà«àª²à«‡ àª•àª°àªµàª¾àª¨à«€ àªªàª°àªµàª¾àª¨àª—à«€ àªœ àª¨ àª†àªªà«‹
      debugPrint("Resume blocked: No Internet");

      // àª¨à«‹àªŸàª¿àª«àª¿àª•à«‡àª¶àª¨ àª¬àª¤àª¾àªµà«‹ (context àªµàª—àª° àª•àª¾àª® àª•àª°à«‡ àª¤à«‡àªµà«€ àª°à«€àª¤à«‡)
      await AppNotificationService.showNoInternetNotification(
        title: "${currentContext?.tr("noInternetTitle")}",
        bodyTitle: "${currentContext?.tr("noInternetBody")}",
      );

      // àªœà«‹ àªŸà«‹àª¸à«àªŸ àª¬àª¤àª¾àªµàªµà«‹ àª¹à«‹àª¯ àª¤à«‹ NavigatorKey àª¥à«€ àª¬àª¤àª¾àªµà«‹
      if (currentContext != null) {
        AppToast.show(currentContext, "àª‡àª¨à«àªŸàª°àª¨à«‡àªŸ àª¬àª‚àª§ àª›à«‡, àªªà«àª²à«‡ àª¨ àª¥àªˆ àª¶àª•à«‡");
      }

      notifyListeners();
      return; // àª…àª¹à«€àª‚àª¥à«€ àªœ àªªàª¾àª›àª¾ àªµàª³à«€ àªœàª¾àª“, audioPlayer.play() àª¸à«àª§à«€ àªªàª¹à«‹àª‚àªšàªµàª¾ àªœ àª¨ àª¦à«‹
    }

    // àªœà«‹ àª“àª¨àª²àª¾àª‡àª¨ àª¹à«‹àª¯ àª¤à«‹ àªœ àªªà«àª²à«‡ àª•àª°à«‹
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
      await _setupVideoPlayer(item.path);
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

    if (chewieController != null) {
      chewieController!.dispose();
      chewieController = null;
    }
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
