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

// import '../models/media_item.dart';
import '../models/player_data.dart';
import 'package:just_audio_background/just_audio_background.dart'
as bg; // Alias આપો
import '../models/media_item.dart' as my;
import '../models/playlist_model.dart';
import '../screens/detail_screen.dart';

class GlobalPlayer extends ChangeNotifier {
  AssetEntity? currentEntity;
  static final GlobalPlayer _instance = GlobalPlayer._internal();

  factory GlobalPlayer() => _instance;

  GlobalPlayer._internal() {
    _initJustAudio(); // Constructor માં જ ઓડિયો પ્લેયર સેટ કરો
  }

  // પ્લેયર્સ
  VideoPlayerController? controller; // ફક્ત વીડિયો માટે
  final AudioPlayer audioPlayer = AudioPlayer(); // ફક્ત ઓડિયો માટે
  ChewieController? chewie;

  String? currentPath;
  String? currentType;
  bool? isFavourite;
  String? currentItemId;
  bool isLooping = false;
  List<my.MediaItem> queue = [];
  List<my.MediaItem> originalQueue = [];
  int currentIndex = -1;
  bool isShuffle = false;

  // Just Audio Initializer
  void _initJustAudio() async {
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // જ્યારે ઓડિયો પૂરો થાય ત્યારે આપણું playNext() કોલ કરો
        // આનાથી પ્લેલિસ્ટમાં વીડિયો હશે તો પણ તે સ્વિચ થઈ જશે
        playNext();
      }
    });

    audioPlayer.currentIndexStream.listen((index) {
      // Jyare background mathi next/prev thay tyare aa trigger thase
      if (index != null && index < queue.length && index >= 0) {
        currentIndex = index;
        currentPath = queue[index].path;
        currentType = queue[index].type;
        isFavourite = queue[index].isFavourite;
        currentItemId = queue[index].id;
        // currentType = "audio";
        notifyListeners();
        print("in side init======");
        print("in side init======$isFavourite");
      }
    });

    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // Just audio playlist automatically next par jashe,
        // pan tame tamari logic mujab handle kari shako.
      }
    });
    // await loadQueueFromHive();
  }

  Future<void> playFromPlaylist(PlaylistModel playlist, int startIndex) async {
    // ૧. પ્લેલિસ્ટની બધી આઈટમ્સને પ્લેયરની ક્યુમાં સેટ કરો
    this.originalQueue = List.from(playlist.items);
    this.queue = List.from(playlist.items);

    // ૨. જે આઈટમ પર ક્લિક કર્યું છે તેની વિગતો લો
    final firstItem = playlist.items[startIndex];
    this.currentIndex = startIndex;

    // ૩. આપણી મેઈન play મેથડને કોલ કરો
    // પણ ધ્યાન રાખજો: play() મેથડમાં તમે ફરીથી loadQueueFromHive() કોલ ના કરતા હોય એ જોજો.
    await play(
      firstItem.path,
      type: firstItem.type,
      isFavourite: firstItem.isFavourite ?? false,
      id: firstItem.id ?? "",
      fromPlaylist: true, // આપણે નીચે play મેથડમાં આ ફ્લેગ ઉમેરીશું
    );
  }


  Future<void> _clearPreviousPlayer() async {
    // ૧. ઓડિયો રોકો
    if (audioPlayer.playing) {
      await audioPlayer.stop();
    }

    // ૨. વીડિયો અને ચેવી ક્લીનઅપ
    if (controller != null) {
      controller!.removeListener(_handlePlaybackCompletion);

      // પ્લેયરને ડિસ્પોઝ કરતા પહેલા પોઝ કરો
      await controller!.pause();

      final oldController = controller;
      final oldChewie = chewie;

      // મેઈન વેરીએબલ્સને તરત જ નલ કરો જેથી UI અપડેટ થઈ જાય
      controller = null;
      chewie = null;
      notifyListeners();

      // ૩૦૦ મિલીસેકન્ડનો ગેપ આપવો (Android માટે જરૂરી છે)
      await Future.delayed(const Duration(milliseconds: 300));

      // અહીં ફેરફાર છે:
      oldChewie?.dispose(); // await વગર (કારણ કે આ void છે)

      if (oldController != null) {
        await oldController.dispose(); // await સાથે (કારણ કે આ Future છે)
      }
    }
    WakelockPlus.disable();
  }

  // // ૩. જૂના પ્લેયરને પ્રોપરલી બંધ કરવા માટે
  // Future<void> _clearPreviousPlayer() async {
  //   // ૧. ઓડિયો રોકો
  //   if (audioPlayer.playing) await audioPlayer.stop();
  //
  //   // ૨. વીડિયો ક્લીનઅપ
  //   if (controller != null) {
  //     controller!.removeListener(_handlePlaybackCompletion);
  //
  //     // પ્લેયરને ડિસ્પોઝ કરતા પહેલા રેફરન્સ લો અને વેરીએબલને null કરો
  //     final oldController = controller;
  //     controller = null;
  //     chewie?.dispose();
  //     chewie = null;
  //
  //     // આ લાઈન સૌથી મહત્વની છે: UI ને કહો કે પ્લેયર જતો રહ્યો છે
  //     notifyListeners();
  //
  //     // થોડી રાહ જોઈને ડિસ્પોઝ કરો જેથી વિજેટ ટ્રી અપડેટ થઈ જાય
  //     await Future.delayed(Duration(milliseconds: 100));
  //     await oldController!.dispose();
  //   }
  // }

  // GlobalPlayer Class ની અંદર
  my.MediaItem? get currentMediaItem {
    if (currentIndex >= 0 && currentIndex < queue.length) {
      return queue[currentIndex];
    }
    return null;
  }

  Future<void> playNext() async {
    if (queue.isEmpty) return;

    int nextIndex = (currentIndex + 1) % queue.length;

    // જો આપણે ફરીથી એ જ ઇન્ડેક્સ પર આવી ગયા હોઈએ (બધા વિડિયો સ્કીપ થયા હોય), તો અટકી જવું
    int startTrackIndex = currentIndex;

    while (true) {
      final nextItem = queue[nextIndex];
      final isAppInBackground = WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed;

      // જો વિડિયો હોય અને એપ બેકગ્રાઉન્ડમાં હોય, તો સ્કીપ કરો
      if (nextItem.type == 'video' && isAppInBackground) {
        nextIndex = (nextIndex + 1) % queue.length;

        // જો આખું લિસ્ટ ચેક થઈ ગયું હોય અને કઈ વગાડવા જેવું ન મળે તો બ્રેક કરો
        if (nextIndex == startTrackIndex) {
          debugPrint("No playable audio found in background.");
          return;
        }
        continue;
      }
      break; // યોગ્ય આઈટમ મળી ગઈ
    }

    currentIndex = nextIndex;
    final item = queue[currentIndex];
    if (chewie != null && chewie!.isFullScreen) {
      chewie!.exitFullScreen(); // નવો વીડિયો શરૂ થાય એ પહેલા ફૂલ સ્ક્રીન માંથી બહાર નીકળો
    }
    await play(
      item.path,
      type: item.type,
      id: item.id,
      isFavourite: item.isFavourite,
      network: item.isNetwork,
      fromPlaylist: true, // આ ઉમેરવું જરૂરી છે
    );
    notifyListeners();
  }

  Future<void> _savePlayerState() async {
    final box = Hive.box('player_state');

    await box.put(
      'current',
      PlayerState()
        ..paths = queue.map((e) => e.path).toList()
        ..currentIndex = currentIndex
        ..currentType = currentType ?? 'audio'
        ..currentPositionMs = controller?.value.position.inMilliseconds ?? 0,
    );
  }

  // GlobalPlayer Class ની અંદર
  Future<void> initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // આ લાઈન ત્યારે કામ લાગશે જ્યારે ફોન પર કોલ આવે તો ઓડિયો ઓટોમેટિક પોઝ થઈ જાય
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        pause();
      } else {
        resume();
      }
    });
  }

  void _handlePlaybackCompletion() {
    if (controller != null &&
        controller!.value.position >= controller!.value.duration &&
        !isLooping &&
        controller!.value.isInitialized) {
      // ચેક કરો કે ઇનિશિયલાઇઝ છે

      // લિસનર હટાવી દો જેથી નેક્સ્ટ વીડિયો વખતે લૂપ ના થાય
      controller!.removeListener(_handlePlaybackCompletion);
      playNext();
    }
  }

  void toggleShuffle() {
    isShuffle = !isShuffle;
    if (isShuffle) {
      queue.shuffle();
    } else {
      queue = List.from(originalQueue);
    }
    notifyListeners();
  }

  Timer? _positionTimer;

  void _startPositionSaver() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _savePlayerState();
    });
  }

  void _stopPositionSaver() {
    _positionTimer?.cancel();
  }

  Future<void> playPrevious() async {
    if (queue.isEmpty) return;

    currentIndex = (currentIndex - 1 < 0) ? queue.length - 1 : currentIndex - 1;
    final item = queue[currentIndex];

    await play(
      item.path,
      type: item.type,
      id: item.id,
      isFavourite: item.isFavourite,
      network: item.isNetwork,
      fromPlaylist: true, // આ ભૂલતા નહીં
    );
    notifyListeners();
  }

  Future<void> loadQueueFromHive(String type) async {
    print("type is ====------$type");
    try {
      // Hive boxes open karo
      final audioBox = Hive.box('audios');
      final videoBox = Hive.box('videos');

      List<my.MediaItem> allItems = [];

      // --- Audio Data ---
      if (type == 'audio') {
        for (var item in audioBox.values) {
          if (item is my.MediaItem) {
            // Jo direct object male to
            allItems.add(item);
          } else if (item is Map) {
            // Jo Map male to factory method vapro
            allItems.add(my.MediaItem.fromMap(Map<String, dynamic>.from(item)));
          }
        }
      } else {
        // --- Video Data ---
        for (var item in videoBox.values) {
          if (item is my.MediaItem) {
            allItems.add(item);
          } else if (item is Map) {
            allItems.add(my.MediaItem.fromMap(Map<String, dynamic>.from(item)));
          }
        }
      }

      this.originalQueue = List.from(allItems);
      this.queue = List.from(allItems);

      debugPrint("Queue Loaded Successfully: ${queue.length} items");
      notifyListeners();
    } catch (e) {
      debugPrint("Hive Load Error: $e");
    }
  }

  // Future<void> play(
  //   String path, {
  //   bool network = false,
  //   required String type,
  //   required bool isFavourite,
  //   required String id,
  //   bool fromPlaylist = false,
  // }) async {
  //   // 1. Queue check & find index
  //
  //   // if (queue.isEmpty) await loadQueueFromHive();
  //
  //   currentIndex = queue.indexWhere((element) => element.path == path);
  //
  //   if (currentIndex == -1) {
  //     // Jo current item queue ma nathi to add karo
  //     final newItem = my.MediaItem(
  //       path: path,
  //       type: type,
  //       isNetwork: network,
  //       isFavourite: isFavourite,
  //       id: id,
  //     );
  //     queue.add(newItem);
  //     currentIndex = queue.length - 1;
  //   }
  //
  //   await _clearPreviousPlayer();
  //   currentPath = path;
  //   currentType = type;
  //   isFavourite = isFavourite;
  //   currentItemId = id;
  //
  //   try {
  //     final session = await AudioSession.instance;
  //
  //     if (type == "audio") {
  //       // Audio background playlist banavo
  //       final audioSources = queue.where((i) => i.type == 'audio').map((item) {
  //         return AudioSource.uri(
  //           item.isNetwork ? Uri.parse(item.path) : Uri.file(item.path),
  //           tag: bg.MediaItem(
  //             id: item.path,
  //             album: "My Playlist",
  //             title: item.path.split('/').last,
  //           ),
  //         );
  //       }).toList();
  //
  //       // Audio list no correct index shodho
  //       int audioIndex = queue
  //           .where((i) => i.type == 'audio')
  //           .toList()
  //           .indexWhere((e) => e.path == path);
  //
  //       await audioPlayer.setAudioSource(
  //         ConcatenatingAudioSource(children: audioSources),
  //         initialIndex: audioIndex >= 0 ? audioIndex : 0,
  //       );
  //       audioPlayer.play();
  //     } else {
  //       // --- વીડિયો પ્લેયર લોજિક ---
  //       await session.configure(
  //         const AudioSessionConfiguration.music(),
  //       ); // સિમ્પલ કોન્ફિગરેશન
  //
  //       controller = network
  //           ? VideoPlayerController.networkUrl(Uri.parse(path))
  //           : VideoPlayerController.file(File(path));
  //
  //       // ૨. ઇનિશિયલાઇઝેશન પૂરું થાય ત્યાં સુધી રાહ જુઓ
  //       await controller!.initialize();
  //
  //       chewie = ChewieController(
  //         zoomAndPan: true,
  //         aspectRatio: controller!.value.aspectRatio,
  //         autoPlay: true,
  //         looping: isLooping,
  //         videoPlayerController: controller!,
  //         deviceOrientationsOnEnterFullScreen: [
  //           DeviceOrientation.landscapeLeft,
  //           DeviceOrientation.landscapeRight,
  //         ],
  //         deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
  //         materialProgressColors: ChewieProgressColors(
  //           playedColor: const Color(0XFF3D57F9),
  //           backgroundColor: const Color(0XFFF6F6F6),
  //         ),
  //         onSufflePressed: () => toggleShuffle(),
  //         onNextVideo: () => playNext(),
  //         onPreviousVideo: () => playPrevious(),
  //         additionalOptions: (context) =>
  //             _buildAdditionalOptions(context), // આને અલગ ફંક્શનમાં લઈ લો
  //       );
  //
  //       controller!.addListener(_handlePlaybackCompletion);
  //     }
  //
  //     WakelockPlus.enable();
  //     _startPositionSaver();
  //
  //     // ❗ સૌથી મહત્વનું: આખા ફંક્શનમાં ફક્ત એક જ વાર અંતે નોટિફાય કરો
  //     notifyListeners();
  //   } catch (e) {
  //     debugPrint("Playback Error Details: $e");
  //     // એરર આવે તો પણ નોટિફાય કરો જેથી લોડિંગ સર્કલ અટકે
  //     notifyListeners();
  //   }
  // }


  Future<void> play(
      String path, {
        bool network = false,
        required String type,
        required bool isFavourite,
        required String id,
        bool fromPlaylist = false, // તમે ઉમેરેલો નવો પેરામીટર
      }) async {
// ૧. Index સેટઅપ
    currentIndex = queue.indexWhere((element) => element.path == path);
    if (currentIndex == -1 && !fromPlaylist) {
      final newItem = my.MediaItem(
        path: path,
        type: type,
        isNetwork: network,
        isFavourite: isFavourite,
        id: id,
      );
      queue.add(newItem);
      currentIndex = queue.length - 1;
    }

    await _clearPreviousPlayer();
    currentPath = path;
    currentType = type; // આ મહત્વનું છે
    this.isFavourite = isFavourite;
    currentItemId = id;

    try {
      final session = await AudioSession.instance;

      if (type == "audio") {
        // --- અહીં ફેરફાર છે ---
        // જો પ્લેલિસ્ટ માંથી હોય, તો બધી આઈટમ લેવી (Audio + Video)
        // જો પ્લેલિસ્ટ માંથી ના હોય, તો જૂનું ફિલ્ટર લોજિક રાખવું

        final List<my.MediaItem> itemsForSource = queue
            .where((i) => i.type == 'audio') // ફક્ત ઓડિયો જ ઓડિયો પ્લેયરમાં જવા જોઈએ
            .toList();

        final audioSources = itemsForSource.map((item) {
          return AudioSource.uri(
            item.isNetwork ? Uri.parse(item.path) : Uri.file(item.path),
            tag: bg.MediaItem(
              id: item.path,
              album: fromPlaylist ? "Playlist" : "My Library",
              title: item.path.split('/').last,
            ),
          );
        }).toList();

        int audioIndex = itemsForSource.indexWhere((e) => e.path == path);

        await audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: audioSources),
          initialIndex: audioIndex >= 0 ? audioIndex : 0,
        );
        audioPlayer.play();
      } else {
        // --- વીડિયો પ્લેયર લોજિક (તમારું જે છે એ જ, કોઈ જ ફેરફાર નથી) ---
        await session.configure(const AudioSessionConfiguration.music());

        controller = network
            ? VideoPlayerController.networkUrl(Uri.parse(path))
            : VideoPlayerController.file(File(path));

        await controller!.initialize().timeout(const Duration(seconds: 15));
        // await _clearPreviousPlayer();
        chewie = ChewieController(
          zoomAndPan: true,
          aspectRatio: controller!.value.aspectRatio,
          autoPlay: true,
          looping: isLooping,
          videoPlayerController: controller!,
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

        controller!.addListener(_handlePlaybackCompletion);
      }

      WakelockPlus.enable();
      _startPositionSaver();
      notifyListeners();
      print("queue length is ========${queue.length}");
      print("queue length is ========${queue}");
    } catch (e) {
      debugPrint("Playback Error Details: $e");
      notifyListeners();
    }
  }


  // કંટ્રોલ મેથડ્સ (બંને પ્લેયર માટે)
  void pause() {
    if (currentType == "audio")
      audioPlayer.pause();
    else
      controller?.pause();
    notifyListeners();
  }

  void resume() {
    if (currentType == "audio")
      audioPlayer.play();
    else
      controller?.play();
    notifyListeners();
  }

  // Stop મેથડ - જે બધું જ ક્લીન કરશે
  Future<void> stop() async {
    // ૧. ઓડિયો રોકો
    await audioPlayer.stop();

    // ૨. વીડિયો અને ચેવી ડિસ્પોઝ કરો
    if (controller != null) {
      await controller!.dispose();
      controller = null;
    }
    if (chewie != null) {
      chewie!.dispose();
      chewie = null;
    }

    // ૩. ડેટા સાવ ખાલી કરો
    currentPath = null;
    currentType = null;
    currentIndex = -1; // આનાથી મિની પ્લેયર અને પ્લેયર સ્ક્રીન આપોઆપ બંધ થશે

    WakelockPlus.disable();
    notifyListeners(); // બધા વિજેટ્સને ખબર પડશે કે હવે કંઈ પ્લે નથી થઈ રહ્યું
  }

  // Getter for UI
  bool get isPlaying {
    if (currentType == "audio") return audioPlayer.playing;
    return controller?.value.isPlaying ?? false;
  }

  // Progress Bar માટે પોઝિશન અને ડ્યુરેશન
  Duration get position {
    if (currentType == "audio") return audioPlayer.position;
    return controller?.value.position ?? Duration.zero;
  }

  Duration get duration {
    if (currentType == "audio") return audioPlayer.duration ?? Duration.zero;
    return controller?.value.duration ?? Duration.zero;
  }

  void setQueue(List<my.MediaItem> items, int startIndex) {
    if (items.isEmpty) return;

    this.originalQueue = List.from(items);
    this.queue = List.from(items);

    // -1 ne badle 0 check karo
    this.currentIndex = (startIndex >= 0 && startIndex < items.length)
        ? startIndex
        : 0;

    notifyListeners();
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    audioPlayer.dispose();
    controller?.dispose();
    chewie?.dispose();
    super.dispose();
  }

  _buildAdditionalOptions(BuildContext context) {
    return [
      // OptionItem(
      //   onTap: (context) {
      //     toggleRotation();
      //     Navigator.pop(context);
      //   },
      //   iconData: Icons.screen_rotation,
      //   title: isLandscape ? "Portrait Mode" : "Landscape Mode",
      // ),
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
        controlType: ControlType.shuffle,
        onTap: (context) => (){
          toggleShuffle();
        },
        iconData: Icons.shuffle,
        title: "Shuffle",
        iconImage: AppSvg.icShuffle,
      ),
      // OptionItem(
      //   controlType: ControlType.playbackSpeed,
      //   onTap: (context) {
      //     // toggleShuffle();
      //   },
      //   iconData: Icons.shuffle,
      //   title: "video speed",
      //   iconImage: AppSvg.ic2x,
      // ),
      OptionItem(
        controlType: ControlType.theme,
        onTap: (context) {
          toggleShuffle();
        },
        iconData: Icons.shuffle,
        title: "dark",
        iconImage: AppSvg.icDarkMode,
      ),
      // OptionItem(
      //   controlType: ControlType.info,
      //   onTap: (context) async{
      //     Navigator.of(context).push<void>(
      //       MaterialPageRoute<void>(builder: (_) => DetailPage(entity: AssetEntity(id: currentItemId!, typeInt: currentType=="audio"?3:2, width: 200, height: 200,isFavorite: isFavourite!,relativePath: currentPath))),
      //     );
      //     // await routeToDetailPage(AssetEntity(id: currentItemId!, typeInt: currentType=="audio"?3:2, width: 200, height: 200,isFavorite: isFavourite!,relativePath: currentPath), context);
      //   },
      //   iconData: Icons.shuffle,
      //   title: "info",
      //   iconImage: AppSvg.icInfo,
      // ),
      // OptionItem(
      //   controlType: ControlType.prev10,
      //   onTap: (context) {
      //     toggleShuffle();
      //   },
      //   iconData: Icons.shuffle,
      //   title: "prev10",
      //   iconImage: AppSvg.ic10Prev,
      // ),
      // OptionItem(
      //   controlType: ControlType.next10,
      //   onTap: (context) {
      //     toggleShuffle();
      //   },
      //   iconData: Icons.shuffle,
      //   title: "next10",
      //   iconImage: AppSvg.ic10Next,
      // ),

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
      // OptionItem(
      //   controlType: ControlType.playbackSpeed,
      //   onTap: (context) async {
      //     final newPos = (controller!.value.position) - Duration(seconds: 10);
      //     controller!.seekTo(newPos > Duration.zero ? newPos : Duration.zero);
      //   },
      //   iconData: Icons.replay_10,
      //   title: "kk",
      //   iconImage: AppSvg.ic10Prev,
      // ),
      // OptionItem(
      //   onTap: (context) async {},
      //   controlType: ControlType.miniVideo,
      //   iconData: Icons.replay_10,
      //   title: "miniScreen",
      //   iconImage: AppSvg.icMiniScreen,
      // ),
    ];
  }

  void setPlaylistQueue(List<my.MediaItem> items, int startIndex) {
    this.originalQueue = List.from(items);
    this.queue = List.from(items);
    this.currentIndex = startIndex;

    final item = queue[startIndex];
    play(
      item.path,
      type: item.type,
      isFavourite: item.isFavourite,
      id: item.id,
    );
  }

  Future<void> routeToDetailPage(AssetEntity entity,BuildContext context) async {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => DetailPage(entity: entity)),
    );
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
