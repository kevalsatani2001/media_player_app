import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart'
    hide PlayerState; // Just Audio ઉમેરો
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../core/constants.dart';
import 'package:just_audio_background/just_audio_background.dart'
as bg; // Alias આપો
import '../models/media_item.dart' as my;
import 'package:just_audio/just_audio.dart';

class GlobalPlayer extends ChangeNotifier {
  static final GlobalPlayer _instance = GlobalPlayer._internal();
  factory GlobalPlayer() => _instance;
  GlobalPlayer._internal() {
    _initAudioSession();
    _listenToJustAudioEvents();
  }

  // પ્લેયર્સ
  final AudioPlayer audioPlayer = AudioPlayer();
  VideoPlayerController? videoController;
  ChewieController? chewieController;

  // ડેટા વેરીએબલ્સ
  List<my.MediaItem> queue = [];
  int currentIndex = -1;
  AssetEntity? currentEntity;
  String? currentType; // 'audio' અથવા 'video'
  bool isShuffle = false;
  bool _isLoading = false;

  // ૧. Just Audio ના ઇવેન્ટ્સ સાંભળો (UI અપડેટ માટે)
  void _listenToJustAudioEvents() {
    audioPlayer.currentIndexStream.listen((index) {
      // જો પ્લેયર ક્લોઝ થઈ ગયો હોય તો પ્રોસેસ ન કરવી
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
      if (currentIndex == -1) return; // પ્લેયર બંધ હોય તો ઓટો-નેક્સ્ટ ન કરવું

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
      // વીડિયો માટે જો શફલ કરવું હોય તો લિસ્ટને મેન્યુઅલી શફલ કરવું પડે
      if (isShuffle) {
        queue.shuffle();
      } else {
        // પાછું ઓરિજિનલ સિક્વન્સમાં લાવવા માટે ડેટા રિ-લોડ કરવો પડે
        // (નોંધ: આ માટે ઓરિજિનલ લિસ્ટનો વેરીએબલ સાચવવો પડે)
      }
    }
    notifyListeners();
  }

  // --- Loop Logic ---
  Future<void> toggleLoopMode() async {
    if (currentType == 'audio') {
      if (loopMode == LoopMode.off) {
        loopMode = LoopMode.all; // આખું લિસ્ટ લૂપ થશે
      } else if (loopMode == LoopMode.all) {
        loopMode = LoopMode.one; // એક જ ગીત લૂપ થશે
      } else {
        loopMode = LoopMode.off; // લૂપ બંધ
      }
      await audioPlayer.setLoopMode(loopMode);
    } else {
      // વીડિયો માટે લૂપ લોજિક (ફક્ત એક વીડિયો લૂપ માટે)
      bool currentLoop = chewieController?.looping ?? false;
      chewieController?.dispose(); // જુના કન્ટ્રોલરને રિફ્રેશ કરવા માટે

      // નવું લોજિક સેટ કરો (આ વીડિયો પ્લેયરના કન્ટ્રોલર પર આધારિત છે)
      videoController?.setLooping(!currentLoop);
    }
    notifyListeners();
  }

  // ૨. MAIN ENTRY POINT: લિસ્ટ અને ID દ્વારા પ્લે કરો
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
        if (currentType == 'audio' && audioPlayer.audioSource != null && entities.length == queue.length) {
          currentIndex = newIndex;
          currentEntity = await AssetEntity.fromId(entities[newIndex].id);

          // આખું સેટઅપ ફરીથી કરવાને બદલે ડાયરેક્ટ તે ઇન્ડેક્સ પર જાવ
          await audioPlayer.seek(Duration.zero, index: currentIndex);
          audioPlayer.play();

          _isLoading = false;
          notifyListeners();
          return; // અહીંથી જ બહાર નીકળી જાવ
        }
        await _clearPreviousPlayer();

        // ૪. ડેટા સેટ કરો
        queue = await _convertEntitiesToMediaItems(entities);
        currentIndex = newIndex;
        currentType = queue[currentIndex].type;
        currentEntity = await AssetEntity.fromId(queue[currentIndex].id);

        if (currentType == 'audio') {
          await _setupAudioQueue(); // આમાં initialIndex: currentIndex છે જ
          audioPlayer.play();
        } else {
          await _setupVideoPlayer(queue[currentIndex].path);
        }
      } catch (e) {
        debugPrint("Init Error: $e");
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });


    //
    // try {
    //   // ૧. નવો ઇન્ડેક્સ શોધો
    //   int newIndex = entities.indexWhere((item) => item.id == selectedId);
    //   newIndex = newIndex == -1 ? 0 : newIndex;
    //
    //   // ૨. જો ઓડિયો પ્લે થઈ રહ્યો હોય અને યુઝર તે જ લિસ્ટમાં બીજા ગીત પર ક્લિક કરે
    //   if (currentType == 'audio' && audioPlayer.audioSource != null && entities.length == queue.length) {
    //     currentIndex = newIndex;
    //     currentEntity = await AssetEntity.fromId(entities[newIndex].id);
    //
    //     // આખું સેટઅપ ફરીથી કરવાને બદલે ડાયરેક્ટ તે ઇન્ડેક્સ પર જાવ
    //     await audioPlayer.seek(Duration.zero, index: currentIndex);
    //     audioPlayer.play();
    //
    //     _isLoading = false;
    //     notifyListeners();
    //     return; // અહીંથી જ બહાર નીકળી જાવ
    //   }
    //
    //   // ૩. જો નવું લિસ્ટ હોય અથવા વીડિયો હોય, તો જૂનું બધું સાફ કરો
    //   await _clearPreviousPlayer();
    //
    //   // ૪. ડેટા સેટ કરો
    //   queue = await _convertEntitiesToMediaItems(entities);
    //   currentIndex = newIndex;
    //   currentType = queue[currentIndex].type;
    //   currentEntity = await AssetEntity.fromId(queue[currentIndex].id);
    //
    //   if (currentType == 'audio') {
    //     await _setupAudioQueue(); // આમાં initialIndex: currentIndex છે જ
    //     audioPlayer.play();
    //   } else {
    //     await _setupVideoPlayer(queue[currentIndex].path);
    //   }
    //
    // }
    // catch (e) {
    //   debugPrint("Init Error: $e");
    // } finally {
    //   _isLoading = false;
    //   notifyListeners();
    // }
  }

  Future<void> _setupAudioQueue() async {
    final audioSources = queue.map((item) {
      return AudioSource.uri(
        Uri.file(item.path),
        tag: bg.MediaItem(
            id: item.id,
            title: item.path.split('/').last,
            artist: "Local Media"
        ),
      );
    }).toList();

    // અહીં currentIndex બરાબર હોવો જોઈએ
    await audioPlayer.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: currentIndex, // આ લાઈન બરાબર હોવી જોઈએ
      initialPosition: Duration.zero,
    );
  }

  // GlobalPlayer class ની અંદર
  Future<void> refreshCurrentEntity() async {
    if (currentEntity != null) {
      // obtainForNewProperties() લેટેસ્ટ સિસ્ટમ સ્ટેટ (Favorite status) લાવશે
      final updatedEntity = await currentEntity!.obtainForNewProperties();
      if (updatedEntity != null) {
        currentEntity = updatedEntity;
        notifyListeners(); // આ MiniPlayer ના AnimatedBuilder ને ટ્રિગર કરશે
      }
    }
  }

  // ૩. Entity લિસ્ટને MediaItem લિસ્ટમાં બદલો (Sequence જાળવીને)
  Future<List<my.MediaItem>> _convertEntitiesToMediaItems(List<AssetEntity> entities) async {
    List<my.MediaItem> items = [];
    for (var entity in entities) {
      final file = await entity.file;
      if (file != null) {
        items.add(my.MediaItem(
          id: entity.id,
          path: file.path,
          type: entity.type == AssetType.audio ? 'audio' : 'video',
          isNetwork: false,
          isFavourite: entity.isFavorite,
        ));
      }
    }
    return items;
  }

  // ૪. Audio Player સેટઅપ
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
  // ૫. Video Player સેટઅપ
  Future<void> _setupVideoPlayer(String path) async {
    videoController = VideoPlayerController.file(File(path));
    await videoController!.initialize();

    chewieController =  ChewieController(
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
        if (currentIndex != -1) playNext(); // ફરી ચેક કરો
      });
    }
  }

  // ૬. સિંક સ્ટેટ (જ્યારે ગીત બદલાય ત્યારે)
  void _syncStateWithIndex(int index) async {
    currentIndex = index;
    final item = queue[index];
    currentEntity = await AssetEntity.fromId(item.id);
    notifyListeners();
  }

  // ૭. નેક્સ્ટ/પ્રિવિયસ કંટ્રોલ
  Future<void> playNext() async {
    if (queue.isEmpty) return;
    int nextIndex = (currentIndex + 1) % queue.length;
    await _playMediaAtIndex(nextIndex);
  }

  Future<void> playPrevious() async {
    if (queue.isEmpty) return;
    int prevIndex = (currentIndex - 1 < 0) ? queue.length - 1 : currentIndex - 1;
    await _playMediaAtIndex(prevIndex);
  }

  // Helper: કરંટ એન્ટિટી લિસ્ટ પાછું મેળવવા માટે (વીડિયો સ્વિચિંગ વખતે કામ લાગશે)
  Future<List<AssetEntity>> _getCurrentEntities() async {
    List<AssetEntity> list = [];
    for (var item in queue) {
      final ent = await AssetEntity.fromId(item.id);
      if (ent != null) list.add(ent);
    }
    return list;
  }

  // ૮. પ્લેયર ક્લીનઅપ
  Future<void> _clearPreviousPlayer({bool keepAudioSource = false}) async {
    if (videoController != null) {
      // લિસનર પહેલા દૂર કરો
      videoController!.removeListener(_videoListener);

      // સીધું ડિસ્પોઝ કરો, pause() કરવાની જરૂર નથી જો તમે તેને તરત જ કાઢી નાખવાના હોવ
      final oldVideoController = videoController;
      final oldChewieController = chewieController;

      videoController = null;
      chewieController = null;

      // ડિસ્પોઝને ફ્રેમ પછી રન કરો જેથી બિલ્ડમાં નડતર ન થાય
      Future.delayed(Duration.zero, () {
        oldVideoController?.dispose();
        oldChewieController?.dispose();
      });
    }

    if (currentType == 'video' && audioPlayer.playing) {
      await audioPlayer.pause();
    }
  }

  // ૯. ઓડિયો સેશન (Interruption handle કરવા)
  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    session.interruptionEventStream.listen((event) {
      if (event.begin) pause();
      else resume();
    });
  }

  // કંટ્રોલ્સ
  void pause() {
    currentType == 'audio' ? audioPlayer.pause() : videoController?.pause();
    notifyListeners();
  }

  void resume() {
    currentType == 'audio' ? audioPlayer.play() : videoController?.play();
    notifyListeners();
  }

  // Getters for UI
  bool get isPlaying => currentType == 'audio' ? audioPlayer.playing : (videoController?.value.isPlaying ?? false);
  Duration get position => currentType == 'audio' ? audioPlayer.position : (videoController?.value.position ?? Duration.zero);
  Duration get duration => currentType == 'audio' ? (audioPlayer.duration ?? Duration.zero) : (videoController?.value.duration ?? Duration.zero);
  my.MediaItem? get currentMediaItem => (currentIndex >= 0 && currentIndex < queue.length) ? queue[currentIndex] : null;

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
        onTap: (context) => (){
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

  // Future<void> _playMediaAtIndex(int index) async {
  //   if (index < 0 || index >= queue.length) return;
  //
  //   currentIndex = index;
  //   final item = queue[index];
  //   currentType = item.type;
  //   currentEntity = await AssetEntity.fromId(item.id);
  //
  //   await _clearPreviousPlayer(keepAudioSource: true);
  //
  //   if (currentType == 'audio') {
  //     // જો ઓડિયો હોય, તો જસ્ટ ઓડિયો પ્લેયરને તે ઈન્ડેક્સ પર સીક કરો
  //     await audioPlayer.seek(Duration.zero, index: index);
  //     audioPlayer.play();
  //   } else {
  //     // જો વીડિયો હોય, તો વીડિયો પ્લેયર સેટઅપ કરો
  //     await _setupVideoPlayer(item.path);
  //   }
  //   notifyListeners();
  // }

  // GlobalPlayer ની અંદર આ ફંક્શન ઉમેરો અથવા સુધારો
  bool _isAppInBackground() {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == AppLifecycleState.paused || state == AppLifecycleState.detached;
  }

  Future<void> _playMediaAtIndex(int index) async {
    if (index < 0 || index >= queue.length) return;

    int targetIndex = index;

    // ૧. જો એપ બેકગ્રાઉન્ડમાં હોય, તો લૂપ ફેરવીને ચેક કરો કે નેક્સ્ટ ઓડિયો ક્યાં છે
    if (_isAppInBackground()) {
      int itemsChecked = 0;

      // જ્યાં સુધી વિડિયો મળે ત્યાં સુધી આગળ વધો
      while (queue[targetIndex].type == 'video' && itemsChecked < queue.length) {
        debugPrint("Background mode: Skipping video at index $targetIndex");
        targetIndex = (targetIndex + 1) % queue.length;
        itemsChecked++;
      }

      // જો આખા લિસ્ટમાં ક્યાંય ઓડિયો ન મળે, તો પ્લેયર સ્ટોપ કરો
      if (itemsChecked >= queue.length) {
        debugPrint("No audio found to play in background. Stopping.");
        audioPlayer.stop();
        currentIndex = -1;
        notifyListeners();
        return;
      }
    }

    // ૨. હવે સાચો ઈન્ડેક્સ સેટ કરો
    currentIndex = targetIndex;
    final item = queue[currentIndex];
    currentType = item.type;
    currentEntity = await AssetEntity.fromId(item.id);

    // ૩. પ્લેયર ક્લીનઅપ
    await _clearPreviousPlayer(keepAudioSource: true);

    if (currentType == 'audio') {
      // Just Audio પ્લેયરને તે ઈન્ડેક્સ પર લઈ જઈને પ્લે કરો
      await audioPlayer.seek(Duration.zero, index: currentIndex);
      audioPlayer.play();
    } else {
      // આ લાઈન ત્યારે જ રન થશે જ્યારે એપ ફોરગ્રાઉન્ડમાં હશે
      await _setupVideoPlayer(item.path);
    }

    notifyListeners();
  }

  // પ્લેયરનું સ્ટેટ સેવ કરવા માટે
  Future<void> savePlayerState() async {
    final box = Hive.box('player_state');
    if (currentIndex == -1) {
      await box.clear(); // જો પ્લેયર બંધ હોય તો બધું સાફ કરો
      return;
    }
    if (currentMediaItem != null) {
      await box.put('last_item_id', currentMediaItem!.id);
      await box.put('last_position', audioPlayer.position.inMilliseconds);
      await box.put('last_type', currentType);
      // આખું લિસ્ટ સેવ કરવા માટે તમે IDs ની યાદી સ્ટોર કરી શકો છો
    }
  }

  Future<void> restoreLastSession() async {
    final box = Hive.box('player_state');
    final String? lastId = box.get('last_item_id');
    final int? lastPos = box.get('last_position');

    if (lastId != null) {
      // તમારે તમારી એસેટ્સમાંથી આ ID વાળી એન્ટિટી શોધવી પડશે
      // ધારો કે તમારી પાસે બધી એસેટ્સનું લિસ્ટ છે
      // AssetEntity? entity = ... find by id ...

      // પ્લેયર લોડ કરો પણ પ્લે ન કરો (માત્ર સેટઅપ કરો)
      // await audioPlayer.setAudioSource(...);
      // await audioPlayer.seek(Duration(milliseconds: lastPos ?? 0));
      // notifyListeners();
    }
  }

  // પ્રાઇવેટ વેરીએબલ
  my.MediaItem? _currentMediaItem;
  /*
    my.MediaItem? get currentMediaItem => (currentIndex >= 0 && currentIndex < queue.length) ? queue[currentIndex] : null;

   */

  // Getter (જે તમે અત્યારે વાપરી રહ્યા હશો)
  // my.MediaItem? get currentMediaItem => _currentMediaItem;

  // Setter (આ ઉમેરવાથી ભૂલ દૂર થશે)
  set currentMediaItem(my.MediaItem? value) {
    _currentMediaItem = value;
    notifyListeners();
  }

  // એ જ રીતે currentEntity માટે પણ Setter બનાવી લો
  AssetEntity? _currentEntity;
  // AssetEntity? get currentEntity => _currentEntity;

  // set currentEntity(AssetEntity? value) {
  //   _currentEntity = value;
  //   notifyListeners();
  // }
  void stopAndClose() {
    // ૧. વીડિયો કંટ્રોલરને પ્રોપરલી અટકાવો
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

    // ૨. ઓડિયો પ્લેયર કમ્પ્લીટલી સ્ટોપ કરો
    audioPlayer.stop();
    // audioPlayer.setAudioSource(null); // આ લાઈન એડ કરવાથી કોઈ જૂનું સોર્સ બાકી નહીં રહે

    // ૩. ડેટા ક્લિયર કરો
    queue = [];
    currentIndex = -1;
    currentMediaItem = null;
    currentEntity = null;
    currentType = null;

    // ૪. લિસનર્સને છેલ્લી વાર જાણ કરો
    notifyListeners();
  }

// GlobalPlayer ની અંદર આ ફંક્શન ઉમેરો અથવા સુધારો
// bool _isAppInBackground() {
//   final state = WidgetsBinding.instance.lifecycleState;
//   return state == AppLifecycleState.paused || state == AppLifecycleState.detached;
// }

}

/*
/*
 (English)
 (Arabic)
 (Burmese)
 (Filipino)
 (French)
 (German)
 (Gujarati)
 (Hindi)
 (Indonesian)
 (Italian)
 (Japanese)
 (Korean)
 (Malay)
 (Marathi)
 (Persian)
 (Polish)
 (Portuguese)
 (Spanish)
 (Swedish)
 (Tamil)

























 */

 */