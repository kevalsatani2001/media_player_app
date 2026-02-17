import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState; // Just Audio ઉમેરો
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../core/constants.dart';
// import '../models/media_item.dart';
import '../models/player_data.dart';
import 'package:just_audio_background/just_audio_background.dart' as bg; // Alias આપો
import '../models/media_item.dart' as my;

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
  bool isLooping = false;
  List<my.MediaItem> queue = [];
  List<my.MediaItem> originalQueue = [];
  int currentIndex = -1;
  bool isShuffle = false;

  // Just Audio Initializer
  void _initJustAudio() {
    audioPlayer.setAudioSource(ConcatenatingAudioSource(children: []),preload: true,);
    // ઓડિયો પૂરો થાય ત્યારે નેક્સ્ટ સોન્ગ પ્લે કરવા માટે
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (!isLooping) {
          playNext();
        }
      }
    });
  }
  // ૩. જૂના પ્લેયરને પ્રોપરલી બંધ કરવા માટે
  Future<void> _clearPreviousPlayer() async {
    // ૧. ઓડિયો રોકો
    if (audioPlayer.playing) await audioPlayer.stop();

    // ૨. વીડિયો ક્લીનઅપ
    if (controller != null) {
      controller!.removeListener(_handlePlaybackCompletion);

      // પ્લેયરને ડિસ્પોઝ કરતા પહેલા રેફરન્સ લો અને વેરીએબલને null કરો
      final oldController = controller;
      controller = null;
      chewie?.dispose();
      chewie = null;

      // આ લાઈન સૌથી મહત્વની છે: UI ને કહો કે પ્લેયર જતો રહ્યો છે
      notifyListeners();

      // થોડી રાહ જોઈને ડિસ્પોઝ કરો જેથી વિજેટ ટ્રી અપડેટ થઈ જાય
      await Future.delayed(Duration(milliseconds: 100));
      await oldController!.dispose();
    }
  }

  Future<void> playNext() async {
    if (queue.isEmpty) return;
    currentIndex = (currentIndex + 1) % queue.length;
    final item = queue[currentIndex];
    await play(item.path, network: item.isNetwork, type: item.type);
  }

  Future<void> _savePlayerState() async {
    final box = Hive.box('player_state');

    await box.put(
      'current',
      PlayerState()
        ..paths = queue.map((e) => e.path).toList()
        ..currentIndex = currentIndex
        ..currentType = currentType ?? 'audio'
        ..currentPositionMs =
            controller?.value.position.inMilliseconds ?? 0,
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
        !isLooping) {
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
    await play(item.path, network: item.isNetwork, type: item.type);
  }

  // ૨. મુખ્ય પ્લે મેથડ (Fixed Video Logic)
  Future<void> play(String path, {bool network = false, required String type}) async {
    // જો ઓલરેડી એ જ ફાઈલ ચાલતી હોય
    if (currentPath == path && isPlaying) return;

    // જૂનું ક્લીનઅપ
    await _clearPreviousPlayer();

    currentPath = path;
    currentType = type;

    try {
      final session = await AudioSession.instance;

      if (type == "audio") {
        await session.configure(const AudioSessionConfiguration.music());

        final source = AudioSource.uri(
          network ? Uri.parse(path) : Uri.file(path),
          tag: bg.MediaItem(
            id: path,
            album: "Local Media",
            title: path.split('/').last,
          ),
        );

        try {
          // જૂની કોઈ પણ લોડિંગ પ્રોસેસને અટકાવવા માટે પહેલા stop કરો
          await audioPlayer.stop();

          // 'preload: false' કરવાથી અને એરરને કેચ કરવાથી 'Loading interrupted' તમારી એપ ક્રેશ નહીં કરે
          await audioPlayer.setAudioSource(source, preload: true).catchError((error) {
            if (error is PlayerInterruptedException) {
              debugPrint("નવું ગીત લોડ થવાને કારણે જૂનું અટકાવ્યું: Safe to ignore");
            } else {
              debugPrint("ઓડિયો લોડ કરવામાં ભૂલ: $error");
            }
          });

          if (audioPlayer.audioSource != null) {
            audioPlayer.play();
          }
        } catch (e) {
          debugPrint("Play logic error: $e");
        }
      }
      else {
        // --- વીડિયો પ્લેયર લોજિક ---
        await session.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionMode: AVAudioSessionMode.moviePlayback,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.movie,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        ));

        controller = network
            ? VideoPlayerController.networkUrl(Uri.parse(path))
            : VideoPlayerController.file(File(path));

        await controller!.initialize();

        // Chewie સેટઅપ (Try બ્લોકની અંદર જ રાખવું)
        chewie =  ChewieController(
          zoomAndPan: true,
          aspectRatio: controller!.value.aspectRatio,
          autoPlay: true,
          looping: isLooping,
          videoPlayerController: controller!,
          // mute: false, // ખાતરી કરો કે અહીં ફોલ્સ છે

          // તમારા કસ્ટમ ઓપ્શન્સ અને કંટ્રોલ્સ
          deviceOrientationsOnEnterFullScreen: [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
          deviceOrientationsAfterFullScreen: [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ],
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0XFF3D57F9),
            backgroundColor: const Color(0XFFF6F6F6),
          ),
          onSufflePressed: () => toggleShuffle(),
          onNextVideo: () => playNext(),
          onPreviousVideo: () => playPrevious(),

          additionalOptions: (context) {
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
                onTap: (context) => toggleShuffle,
                iconData: Icons.shuffle,
                title: "Shuffle",
                iconImage: AppSvg.icShuffle,
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
                controlType: ControlType.theme,
                onTap: (context) {
                  toggleShuffle();
                },
                iconData: Icons.shuffle,
                title: "dark",
                iconImage: AppSvg.icDarkMode,
              ),
              OptionItem(
                controlType: ControlType.info,
                onTap: (context) {
                  toggleShuffle();
                },
                iconData: Icons.shuffle,
                title: "info",
                iconImage: AppSvg.icInfo,
              ),
              OptionItem(
                controlType: ControlType.prev10,
                onTap: (context) {
                  toggleShuffle();
                },
                iconData: Icons.shuffle,
                title: "prev10",
                iconImage: AppSvg.ic10Prev,
              ),
              OptionItem(
                controlType: ControlType.next10,
                onTap: (context) {
                  toggleShuffle();
                },
                iconData: Icons.shuffle,
                title: "next10",
                iconImage: AppSvg.ic10Next,
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
              OptionItem(
                controlType: ControlType.playbackSpeed,
                onTap: (context) async {
                  final newPos =
                      (controller!.value.position) - Duration(seconds: 10);
                  controller!.seekTo(
                    newPos > Duration.zero ? newPos : Duration.zero,
                  );
                },
                iconData: Icons.replay_10,
                title: "kk",
                iconImage: AppSvg.ic10Prev,
              ),
              OptionItem(
                onTap: (context) async {},
                controlType: ControlType.miniVideo,
                iconData: Icons.replay_10,
                title: "miniScreen",
                iconImage: AppSvg.icMiniScreen,
              ),
            ];
          },
        );

        controller!.addListener(_handlePlaybackCompletion);
      }

      WakelockPlus.enable();
      _startPositionSaver();
      notifyListeners();

    } catch (e) {
      print("Playback Error Details: $e");
    }
  }

  // કંટ્રોલ મેથડ્સ (બંને પ્લેયર માટે)
  void pause() {
    if (currentType == "audio") audioPlayer.pause();
    else controller?.pause();
    notifyListeners();
  }

  void resume() {
    if (currentType == "audio") audioPlayer.play();
    else controller?.play();
    notifyListeners();
  }


  Future<void> stop() async {
    // ૧. ઓડિયો પ્લેયર ક્લીનઅપ
    if (audioPlayer.playing) {
      await audioPlayer.stop();
    }
    // સોર્સ લોડિંગ કેન્સલ કરવા માટે
    await audioPlayer.setAudioSource(ConcatenatingAudioSource(children: [])).catchError((e) => null);

    // ૨. વીડિયો પ્લેયર ક્લીનઅપ
    if (controller != null) {
      controller!.removeListener(_handlePlaybackCompletion);
      await controller!.dispose();
      controller = null;
    }

    if (chewie != null) {
      chewie!.dispose();
      chewie = null;
    }

    // ઓડિયો સેશન બંધ કરો
    final session = await AudioSession.instance;
    await session.setActive(false);

    WakelockPlus.disable();
    _stopPositionSaver();
    notifyListeners();
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
    if (items.isEmpty) return; // ખાલી લિસ્ટ હોય તો કશું ના કરવું

    originalQueue = List.from(items);
    queue = List.from(items);
    currentIndex = startIndex;
    notifyListeners(); // આનાથી UI ને ખબર પડશે કે હવે ઈન્ડેક્સ -1 નથી
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    audioPlayer.dispose();
    controller?.dispose();
    chewie?.dispose();
    super.dispose();
  }
}





// import 'dart:async';
// import 'dart:io';
// import 'package:chewie/chewie.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:video_player/video_player.dart';
// import '../core/constants.dart';
// import '../models/media_item.dart';
// class GlobalPlayer extends ChangeNotifier {
//   MaterialControlsState materialControlsState = MaterialControlsState();
//   static final GlobalPlayer _instance = GlobalPlayer._internal();
//
//   factory GlobalPlayer() => _instance;
//
//   GlobalPlayer._internal();
//
//   VideoPlayerController? controller;
//   ChewieController? chewie;
//   String? currentPath;
//   bool isLandscape = false;
//   bool isNetwork = false;
//   String? currentType; // "audio" or "video"
//   bool isLooping = false;
//
//   List<MediaItem> queue = [];
//   List<MediaItem> originalQueue = [];
//   int currentIndex = -1;
//   bool isShuffle = false;
//
//   void toggleShuffle() {
//     print("call ssss========$isShuffle");
//     isShuffle = !isShuffle;
//     print("call ssss========$isShuffle");
//
//     final currentItem = queue[currentIndex];
//
//     if (isShuffle) {
//       queue.shuffle();
//     } else {
//       queue = List.from(originalQueue);
//     }
//
//     currentIndex = queue.indexOf(currentItem);
//
//     notifyListeners();
//   }
//
//   void setQueue(List<MediaItem> items, int startIndex) {
//     originalQueue = List.from(items);
//     queue = List.from(items);
//     currentIndex = startIndex;
//   }
//
//   Future<void> toggleRotation() async {
//     isLandscape = !isLandscape;
//
//     if (isLandscape) {
//       await SystemChrome.setPreferredOrientations([
//         DeviceOrientation.landscapeLeft,
//         DeviceOrientation.landscapeRight,
//       ]);
//
//       await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//     } else {
//       await SystemChrome.setPreferredOrientations([
//         DeviceOrientation.portraitUp,
//       ]);
//
//       await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     }
//
//     notifyListeners();
//   }
//
//   Future<void> playNext() async {
//     print("queue length is ===> ${queue.length}");
//     print("queue length is ===> ${queue}");
//     if (queue.isEmpty) return;
//     if (currentIndex + 1 >= queue.length) return;
//
//     currentIndex++;
//     final item = queue[currentIndex];
//     await play(item.path, network: item.isNetwork, type: item.type);
//   }
//
//   Future<void> playPrevious() async {
//     if (queue.isEmpty) return;
//     if (currentIndex - 1 < 0) return;
//
//     currentIndex--;
//     final item = queue[currentIndex];
//     await play(item.path, network: item.isNetwork, type: item.type);
//   }
//
//   void toggleLoop() {
//     isLooping = !isLooping;
//     controller?.setLooping(isLooping);
//   }
//
//   Future<void> play(
//       String path, {
//         bool network = false,
//         required String type,
//       }) async {
//     if (currentPath == path && controller != null) {
//       controller!.play();
//       return;
//     }
//
//     await controller?.dispose();
//
//     currentPath = path;
//     isNetwork = network;
//     currentType = type;
//
//     controller = isNetwork
//         ? VideoPlayerController.networkUrl(Uri.parse(path))
//         : VideoPlayerController.file(File(path));
//
//     await controller!.initialize();
//
//     // 🔥 ADD LISTENER HERE
//     controller!.addListener(() {
//       final value = controller!.value;
//       if (value.isInitialized &&
//           value.position >= value.duration &&
//           !isLooping) {
//         playNext();
//       }
//     });
//
//     chewie = type == "video"
//         ? ChewieController(
//       zoomAndPan: true,
//       deviceOrientationsOnEnterFullScreen: [
//         DeviceOrientation.landscapeLeft,
//         DeviceOrientation.landscapeRight,
//       ],
//
//       deviceOrientationsAfterFullScreen: [
//         DeviceOrientation.portraitUp,
//         DeviceOrientation.portraitDown,
//       ],
//       additionalOptions: (context) {
//         return [
//           // OptionItem(
//           //   onTap: (context) {
//           //     toggleRotation();
//           //     Navigator.pop(context);
//           //   },
//           //   iconData: Icons.screen_rotation,
//           //   title: isLandscape ? "Portrait Mode" : "Landscape Mode",
//           // ),
//           OptionItem(
//             controlType: ControlType.miniVideo,
//             onTap: (context) {
//               Navigator.pop(context);
//             },
//             iconData: Icons.screen_rotation,
//             title: "Mini Screen",
//             iconImage: AppSvg.icMiniScreen,
//           ),
//           OptionItem(
//             controlType: ControlType.volume,
//             onTap: (context) {
//               // toggleRotation();
//               // Navigator.pop(context);
//             },
//             iconData: Icons.screen_rotation,
//             title: "Volume",
//             iconImage: AppSvg.icVolumeOff,
//           ),
//
//           OptionItem(
//             controlType: ControlType.shuffle,
//             onTap: (context) => toggleShuffle,
//             iconData: Icons.shuffle,
//             title: "Shuffle",
//             iconImage: AppSvg.icShuffle,
//           ),
//           OptionItem(
//             controlType: ControlType.playbackSpeed,
//             onTap: (context) {
//               // toggleShuffle();
//             },
//             iconData: Icons.shuffle,
//             title: "video speed",
//             iconImage: AppSvg.ic2x,
//           ),
//           OptionItem(
//             controlType: ControlType.theme,
//             onTap: (context) {
//               toggleShuffle();
//             },
//             iconData: Icons.shuffle,
//             title: "dark",
//             iconImage: AppSvg.icDarkMode,
//           ),
//           OptionItem(
//             controlType: ControlType.info,
//             onTap: (context) {
//               toggleShuffle();
//             },
//             iconData: Icons.shuffle,
//             title: "info",
//             iconImage: AppSvg.icInfo,
//           ),
//           OptionItem(
//             controlType: ControlType.prev10,
//             onTap: (context) {
//               toggleShuffle();
//             },
//             iconData: Icons.shuffle,
//             title: "prev10",
//             iconImage: AppSvg.ic10Prev,
//           ),
//           OptionItem(
//             controlType: ControlType.next10,
//             onTap: (context) {
//               toggleShuffle();
//             },
//             iconData: Icons.shuffle,
//             title: "next10",
//             iconImage: AppSvg.ic10Next,
//           ),
//
//           OptionItem(
//             onTap: (context) {
//               // chewie!.videoPlayerController.value.cancelAndRestartTimer();
//               //
//               // if (videoPlayerLatestValue.volume == 0) {
//               //   chewie!.videoPlayerController.setVolume(chewie.videoPlayerController.videoPlayerOptions.);
//               //   // controller.setVolume(_latestVolume ?? 0.5);
//               // } else {
//               //   _latestVolume = controller.value.volume;
//               //   controller.setVolume(0.0);
//               // }
//             },
//             controlType: ControlType.loop,
//             iconData: Icons.shuffle,
//             title: "Loop",
//             iconImage: AppSvg.icLoop,
//           ),
//           OptionItem(
//             controlType: ControlType.playbackSpeed,
//             onTap: (context) async {
//               final newPos =
//                   (controller!.value.position) - Duration(seconds: 10);
//               controller!.seekTo(
//                 newPos > Duration.zero ? newPos : Duration.zero,
//               );
//             },
//             iconData: Icons.replay_10,
//             title: "kk",
//             iconImage: AppSvg.ic10Prev,
//           ),
//           OptionItem(
//             onTap: (context) async {},
//             controlType: ControlType.miniVideo,
//             iconData: Icons.replay_10,
//             title: "miniScreen",
//             iconImage: AppSvg.icMiniScreen,
//           ),
//         ];
//       },
//       materialProgressColors: ChewieProgressColors(
//         playedColor: Color(0XFF3D57F9),
//         backgroundColor: Color(0XFFF6F6F6),
//       ),
//
//       looping: true,
//       onSufflePressed: () {
//         toggleShuffle();
//       },
//       videoPlayerController: controller!,
//       // onPressedLooping: (){},
//       autoPlay: true,
//       allowFullScreen: true,
//       onNextVideo: () async {
//         await playNext();
//       },
//       onPreviousVideo: () async {
//         await playPrevious();
//       },
//     )
//         : null;
//   }
//
//   void pause() => controller?.pause();
//
//   void resume() => controller?.play();
//
//   void stop() {
//     controller?.pause();
//     controller?.seekTo(Duration.zero);
//   }
//
//   bool get isPlaying => controller?.value.isPlaying ?? false;
// }