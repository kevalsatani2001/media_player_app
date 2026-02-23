


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
      if (index != null && index < queue.length) {
        // જો નવું ઈન્ડેક્સ વીડિયો આઈટમ પર જાય, તો ઓડિયો પ્લેયર રોકીને વીડિયો પ્લેયર શરૂ કરવું પડે
        if (queue[index].type == 'video') {
          audioPlayer.pause();
          _playMediaAtIndex(index);
        } else {
          _syncStateWithIndex(index);
        }
      }
    });

    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext(); // ઓટોમેટિક નેક્સ્ટ આઈટમ પર જવા માટે
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
    if (videoController != null &&
        videoController!.value.isInitialized &&
        videoController!.value.position >= videoController!.value.duration) {

      videoController!.removeListener(_videoListener);

      // આ ખાતરી કરે છે કે playNext() બિલ્ડ ફેઝમાં કોલ ન થાય
      WidgetsBinding.instance.addPostFrameCallback((_) {
        playNext();
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

  Future<void> _playMediaAtIndex(int index) async {
    if (index < 0 || index >= queue.length) return;

    currentIndex = index;
    final item = queue[index];
    currentType = item.type;
    currentEntity = await AssetEntity.fromId(item.id);

    await _clearPreviousPlayer(keepAudioSource: true);

    if (currentType == 'audio') {
      // જો ઓડિયો હોય, તો જસ્ટ ઓડિયો પ્લેયરને તે ઈન્ડેક્સ પર સીક કરો
      await audioPlayer.seek(Duration.zero, index: index);
      audioPlayer.play();
    } else {
      // જો વીડિયો હોય, તો વીડિયો પ્લેયર સેટઅપ કરો
      await _setupVideoPlayer(item.path);
    }
    notifyListeners();
  }

  // પ્લેયરનું સ્ટેટ સેવ કરવા માટે
  Future<void> savePlayerState() async {
    final box = Hive.box('player_state');
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
    audioPlayer.stop();
    // ઓડિયો સોર્સ ને નલ કરી દેવો જેથી જૂની મેમરી સાફ થઈ જાય
    audioPlayer.setAudioSource(ConcatenatingAudioSource(children: []));

    currentIndex = -1;
    currentEntity = null;
    currentType = null;
    _isLoading = false;

    // વીડિયો કંટ્રોલર પણ સાફ કરો
    _clearPreviousPlayer();

    notifyListeners();
  }
}








// import 'dart:async';
// import 'dart:io';
// import 'package:audio_session/audio_session.dart';
// import 'package:chewie/chewie.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:hive/hive.dart';
// import 'package:just_audio/just_audio.dart' hide PlayerState; // Just Audio ઉમેરો
// import 'package:photo_manager/photo_manager.dart';
// import 'package:video_player/video_player.dart';
// import 'package:wakelock_plus/wakelock_plus.dart';
// import '../core/constants.dart';
// // import '../models/media_item.dart';
// import '../models/player_data.dart';
// import 'package:just_audio_background/just_audio_background.dart' as bg; // Alias આપો
// import '../models/media_item.dart' as my;
//
// class GlobalPlayer extends ChangeNotifier {
//   AssetEntity? currentEntity;
//   static final GlobalPlayer _instance = GlobalPlayer._internal();
//   factory GlobalPlayer() => _instance;
//   GlobalPlayer._internal() {
//     _initJustAudio(); // Constructor માં જ ઓડિયો પ્લેયર સેટ કરો
//
//   }
//
//   // પ્લેયર્સ
//   VideoPlayerController? controller; // ફક્ત વીડિયો માટે
//   final AudioPlayer audioPlayer = AudioPlayer(); // ફક્ત ઓડિયો માટે
//   ChewieController? chewie;
//
//   String? currentPath;
//   String? currentType;
//   bool isLooping = false;
//   List<my.MediaItem> queue = [];
//   List<my.MediaItem> originalQueue = [];
//   int currentIndex = -1;
//   bool isShuffle = false;
//
//   // Just Audio Initializer
//   void _initJustAudio() async{
//     audioPlayer.currentIndexStream.listen((index) {
//       // Jyare background mathi next/prev thay tyare aa trigger thase
//       if (index != null && index < queue.length && index >= 0) {
//         currentIndex = index;
//         currentPath = queue[index].path;
//         currentType = queue[index].type;
//         // currentType = "audio";
//         notifyListeners();
//       }
//     });
//
//     audioPlayer.playerStateStream.listen((state) {
//       if (state.processingState == ProcessingState.completed) {
//         // Just audio playlist automatically next par jashe,
//         // pan tame tamari logic mujab handle kari shako.
//       }
//     });
//     // await loadQueueFromHive();
//   }
//   // ૩. જૂના પ્લેયરને પ્રોપરલી બંધ કરવા માટે
//   Future<void> _clearPreviousPlayer() async {
//     // ૧. ઓડિયો રોકો
//     if (audioPlayer.playing) await audioPlayer.stop();
//
//     // ૨. વીડિયો ક્લીનઅપ
//     if (controller != null) {
//       controller!.removeListener(_handlePlaybackCompletion);
//
//       // પ્લેયરને ડિસ્પોઝ કરતા પહેલા રેફરન્સ લો અને વેરીએબલને null કરો
//       final oldController = controller;
//       controller = null;
//       chewie?.dispose();
//       chewie = null;
//
//       // આ લાઈન સૌથી મહત્વની છે: UI ને કહો કે પ્લેયર જતો રહ્યો છે
//       notifyListeners();
//
//       // થોડી રાહ જોઈને ડિસ્પોઝ કરો જેથી વિજેટ ટ્રી અપડેટ થઈ જાય
//       await Future.delayed(Duration(milliseconds: 100));
//       await oldController!.dispose();
//     }
//   }
//
//   // GlobalPlayer Class ની અંદર
//   my.MediaItem? get currentMediaItem {
//     if (currentIndex >= 0 && currentIndex < queue.length) {
//       return queue[currentIndex];
//     }
//     return null;
//   }
//
//   // સુધારેલી playNext મેથડ
//   Future<void> playNext() async {
//     if (queue.isEmpty) return;
//
//     // જો છેલ્લું ગીત હોય તો પહેલા પર જાઓ (Loop Queue)
//     currentIndex = (currentIndex + 1) % queue.length;
//
//     final nextItem = queue[currentIndex];
//     // અહીં await જરૂરી છે જેથી ડેટા લોડ થયા પછી જ UI અપડેટ થાય
//     await play(nextItem.path, network: nextItem.isNetwork, type: nextItem.type);
//     notifyListeners();
//   }
//
//   Future<void> _savePlayerState() async {
//     final box = Hive.box('player_state');
//
//     await box.put(
//       'current',
//       PlayerState()
//         ..paths = queue.map((e) => e.path).toList()
//         ..currentIndex = currentIndex
//         ..currentType = currentType ?? 'audio'
//         ..currentPositionMs =
//             controller?.value.position.inMilliseconds ?? 0,
//     );
//   }
//
//   // GlobalPlayer Class ની અંદર
//   Future<void> initAudioSession() async {
//     final session = await AudioSession.instance;
//     await session.configure(const AudioSessionConfiguration.music());
//
//     // આ લાઈન ત્યારે કામ લાગશે જ્યારે ફોન પર કોલ આવે તો ઓડિયો ઓટોમેટિક પોઝ થઈ જાય
//     session.interruptionEventStream.listen((event) {
//       if (event.begin) {
//         pause();
//       } else {
//         resume();
//       }
//     });
//   }
//
//
//   void _handlePlaybackCompletion() {
//     if (controller != null &&
//         controller!.value.position >= controller!.value.duration &&
//         !isLooping &&
//         controller!.value.isInitialized) { // ચેક કરો કે ઇનિશિયલાઇઝ છે
//
//       // લિસનર હટાવી દો જેથી નેક્સ્ટ વીડિયો વખતે લૂપ ના થાય
//       controller!.removeListener(_handlePlaybackCompletion);
//       playNext();
//     }
//   }
//   void toggleShuffle() {
//     isShuffle = !isShuffle;
//     if (isShuffle) {
//       queue.shuffle();
//     } else {
//       queue = List.from(originalQueue);
//     }
//     notifyListeners();
//   }
//   Timer? _positionTimer;
//
//   void _startPositionSaver() {
//     _positionTimer?.cancel();
//     _positionTimer = Timer.periodic(Duration(seconds: 5), (_) {
//       _savePlayerState();
//     });
//   }
//   void _stopPositionSaver() {
//     _positionTimer?.cancel();
//   }
//   Future<void> playPrevious() async {
//     if (queue.isEmpty) return;
//     currentIndex = (currentIndex - 1 < 0) ? queue.length - 1 : currentIndex - 1;
//     final item = queue[currentIndex];
//     await play(item.path, network: item.isNetwork, type: item.type);
//   }
//
//   Future<void> loadQueueFromHive(String type) async {
// print("type is ====------$type");
//     try {
//       // Hive boxes open karo
//       final audioBox = Hive.box('audios');
//       final videoBox = Hive.box('videos');
//
//       List<my.MediaItem> allItems = [];
//
//
//       // --- Audio Data ---
//       if(type=='audio'){
//       for (var item in audioBox.values) {
//         if (item is my.MediaItem) {
//           // Jo direct object male to
//           allItems.add(item);
//         } else if (item is Map) {
//           // Jo Map male to factory method vapro
//           allItems.add(my.MediaItem.fromMap(Map<String, dynamic>.from(item)));
//         }
//       }}
// else{
//       // --- Video Data ---
//       for (var item in videoBox.values) {
//         if (item is my.MediaItem) {
//           allItems.add(item);
//         } else if (item is Map) {
//           allItems.add(my.MediaItem.fromMap(Map<String, dynamic>.from(item)));
//         }
//       }}
//
//       this.originalQueue = List.from(allItems);
//       this.queue = List.from(allItems);
//
//       debugPrint("Queue Loaded Successfully: ${queue.length} items");
//       notifyListeners();
//     } catch (e) {
//       debugPrint("Hive Load Error: $e");
//     }
//   }
//
//   Future<void> play(String path, {bool network = false, required String type}) async {
// // 1. Queue check & find index
//
//     // if (queue.isEmpty) await loadQueueFromHive();
//
//     currentIndex = queue.indexWhere((element) => element.path == path);
//
//     if (currentIndex == -1) {
//       // Jo current item queue ma nathi to add karo
//       final newItem = my.MediaItem(path: path, type: type, isNetwork: network);
//       queue.add(newItem);
//       currentIndex = queue.length - 1;
//     }
//
//     await _clearPreviousPlayer();
//     currentPath = path;
//     currentType = type;
//
//     try {
//       final session = await AudioSession.instance;
//
//       if (type == "audio") {
//         // Audio background playlist banavo
//         final audioSources = queue.where((i) => i.type == 'audio').map((item) {
//           return AudioSource.uri(
//             item.isNetwork ? Uri.parse(item.path) : Uri.file(item.path),
//             tag: bg.MediaItem(
//               id: item.path,
//               album: "My Playlist",
//               title: item.path.split('/').last,
//             ),
//           );
//         }).toList();
//
//         // Audio list no correct index shodho
//         int audioIndex = queue.where((i) => i.type == 'audio')
//             .toList()
//             .indexWhere((e) => e.path == path);
//
//         await audioPlayer.setAudioSource(
//           ConcatenatingAudioSource(children: audioSources),
//           initialIndex: audioIndex >= 0 ? audioIndex : 0,
//         );
//         audioPlayer.play();
//       }
//       else {
//         // --- વીડિયો પ્લેયર લોજિક ---
//         await session.configure(const AudioSessionConfiguration.music()); // સિમ્પલ કોન્ફિગરેશન
//
//         controller = network
//             ? VideoPlayerController.networkUrl(Uri.parse(path))
//             : VideoPlayerController.file(File(path));
//
//         // ૨. ઇનિશિયલાઇઝેશન પૂરું થાય ત્યાં સુધી રાહ જુઓ
//         await controller!.initialize();
//
//         chewie = ChewieController(
//           zoomAndPan: true,
//           aspectRatio: controller!.value.aspectRatio,
//           autoPlay: true,
//           looping: isLooping,
//           videoPlayerController: controller!,
//           deviceOrientationsOnEnterFullScreen: [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
//           deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
//           materialProgressColors: ChewieProgressColors(
//             playedColor: const Color(0XFF3D57F9),
//             backgroundColor: const Color(0XFFF6F6F6),
//           ),
//           onSufflePressed: () => toggleShuffle(),
//           onNextVideo: () => playNext(),
//           onPreviousVideo: () => playPrevious(),
//           additionalOptions: (context) => _buildAdditionalOptions(context), // આને અલગ ફંક્શનમાં લઈ લો
//         );
//
//         controller!.addListener(_handlePlaybackCompletion);
//       }
//
//       WakelockPlus.enable();
//       _startPositionSaver();
//
//       // ❗ સૌથી મહત્વનું: આખા ફંક્શનમાં ફક્ત એક જ વાર અંતે નોટિફાય કરો
//       notifyListeners();
//
//     } catch (e) {
//       debugPrint("Playback Error Details: $e");
//       // એરર આવે તો પણ નોટિફાય કરો જેથી લોડિંગ સર્કલ અટકે
//       notifyListeners();
//     }
//   }
//   // કંટ્રોલ મેથડ્સ (બંને પ્લેયર માટે)
//   void pause() {
//     if (currentType == "audio") audioPlayer.pause();
//     else controller?.pause();
//     notifyListeners();
//   }
//
//   void resume() {
//     if (currentType == "audio") audioPlayer.play();
//     else controller?.play();
//     notifyListeners();
//   }
//
//
//   // Stop મેથડ - જે બધું જ ક્લીન કરશે
//   Future<void> stop() async {
//     // ૧. ઓડિયો રોકો
//     await audioPlayer.stop();
//
//     // ૨. વીડિયો અને ચેવી ડિસ્પોઝ કરો
//     if (controller != null) {
//       await controller!.dispose();
//       controller = null;
//     }
//     if (chewie != null) {
//       chewie!.dispose();
//       chewie = null;
//     }
//
//     // ૩. ડેટા સાવ ખાલી કરો
//     currentPath = null;
//     currentType = null;
//     currentIndex = -1; // આનાથી મિની પ્લેયર અને પ્લેયર સ્ક્રીન આપોઆપ બંધ થશે
//
//     WakelockPlus.disable();
//     notifyListeners(); // બધા વિજેટ્સને ખબર પડશે કે હવે કંઈ પ્લે નથી થઈ રહ્યું
//   }
//   // Getter for UI
//   bool get isPlaying {
//     if (currentType == "audio") return audioPlayer.playing;
//     return controller?.value.isPlaying ?? false;
//   }
//
//   // Progress Bar માટે પોઝિશન અને ડ્યુરેશન
//   Duration get position {
//     if (currentType == "audio") return audioPlayer.position;
//     return controller?.value.position ?? Duration.zero;
//   }
//
//   Duration get duration {
//     if (currentType == "audio") return audioPlayer.duration ?? Duration.zero;
//     return controller?.value.duration ?? Duration.zero;
//   }
//
//   void setQueue(List<my.MediaItem> items, int startIndex) {
//     if (items.isEmpty) return;
//
//     this.originalQueue = List.from(items);
//     this.queue = List.from(items);
//
//     // -1 ne badle 0 check karo
//     this.currentIndex = (startIndex >= 0 && startIndex < items.length) ? startIndex : 0;
//
//     notifyListeners();
//   }
//   @override
//   void dispose() {
//     _positionTimer?.cancel();
//     audioPlayer.dispose();
//     controller?.dispose();
//     chewie?.dispose();
//     super.dispose();
//   }
//
//   _buildAdditionalOptions(BuildContext context){
//     return [
//       // OptionItem(
//       //   onTap: (context) {
//       //     toggleRotation();
//       //     Navigator.pop(context);
//       //   },
//       //   iconData: Icons.screen_rotation,
//       //   title: isLandscape ? "Portrait Mode" : "Landscape Mode",
//       // ),
//       OptionItem(
//         controlType: ControlType.miniVideo,
//         onTap: (context) {
//           Navigator.pop(context);
//         },
//         iconData: Icons.screen_rotation,
//         title: "Mini Screen",
//         iconImage: AppSvg.icMiniScreen,
//       ),
//       OptionItem(
//         controlType: ControlType.volume,
//         onTap: (context) {
//           // toggleRotation();
//           // Navigator.pop(context);
//         },
//         iconData: Icons.screen_rotation,
//         title: "Volume",
//         iconImage: AppSvg.icVolumeOff,
//       ),
//
//       OptionItem(
//         controlType: ControlType.shuffle,
//         onTap: (context) => toggleShuffle,
//         iconData: Icons.shuffle,
//         title: "Shuffle",
//         iconImage: AppSvg.icShuffle,
//       ),
//       OptionItem(
//         controlType: ControlType.playbackSpeed,
//         onTap: (context) {
//           // toggleShuffle();
//         },
//         iconData: Icons.shuffle,
//         title: "video speed",
//         iconImage: AppSvg.ic2x,
//       ),
//       OptionItem(
//         controlType: ControlType.theme,
//         onTap: (context) {
//           toggleShuffle();
//         },
//         iconData: Icons.shuffle,
//         title: "dark",
//         iconImage: AppSvg.icDarkMode,
//       ),
//       OptionItem(
//         controlType: ControlType.info,
//         onTap: (context) {
//           toggleShuffle();
//         },
//         iconData: Icons.shuffle,
//         title: "info",
//         iconImage: AppSvg.icInfo,
//       ),
//       OptionItem(
//         controlType: ControlType.prev10,
//         onTap: (context) {
//           toggleShuffle();
//         },
//         iconData: Icons.shuffle,
//         title: "prev10",
//         iconImage: AppSvg.ic10Prev,
//       ),
//       OptionItem(
//         controlType: ControlType.next10,
//         onTap: (context) {
//           toggleShuffle();
//         },
//         iconData: Icons.shuffle,
//         title: "next10",
//         iconImage: AppSvg.ic10Next,
//       ),
//
//       OptionItem(
//         onTap: (context) {
//           // chewie!.videoPlayerController.value.cancelAndRestartTimer();
//           //
//           // if (videoPlayerLatestValue.volume == 0) {
//           //   chewie!.videoPlayerController.setVolume(chewie.videoPlayerController.videoPlayerOptions.);
//           //   // controller.setVolume(_latestVolume ?? 0.5);
//           // } else {
//           //   _latestVolume = controller.value.volume;
//           //   controller.setVolume(0.0);
//           // }
//         },
//         controlType: ControlType.loop,
//         iconData: Icons.shuffle,
//         title: "Loop",
//         iconImage: AppSvg.icLoop,
//       ),
//       OptionItem(
//         controlType: ControlType.playbackSpeed,
//         onTap: (context) async {
//           final newPos =
//               (controller!.value.position) - Duration(seconds: 10);
//           controller!.seekTo(
//             newPos > Duration.zero ? newPos : Duration.zero,
//           );
//         },
//         iconData: Icons.replay_10,
//         title: "kk",
//         iconImage: AppSvg.ic10Prev,
//       ),
//       OptionItem(
//         onTap: (context) async {},
//         controlType: ControlType.miniVideo,
//         iconData: Icons.replay_10,
//         title: "miniScreen",
//         iconImage: AppSvg.icMiniScreen,
//       ),
//     ];
//   }
// }
//
