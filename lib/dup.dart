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
//   void _initJustAudio() {
//     audioPlayer.setAudioSource(ConcatenatingAudioSource(children: []),preload: true,);
//     // ઓડિયો પૂરો થાય ત્યારે નેક્સ્ટ સોન્ગ પ્લે કરવા માટે
//     audioPlayer.playerStateStream.listen((state) {
//       if (state.processingState == ProcessingState.completed) {
//         if (!isLooping) {
//           playNext();
//         }
//       }
//     });
//   }
//   Future<void> playNext() async {
//     if (queue.isEmpty) return;
//
//     if (currentIndex + 1 >= queue.length) {
//       if (isLooping) {
//         currentIndex = 0;
//       } else {
//         return;
//       }
//     } else {
//       currentIndex++;
//     }
//
//     final item = queue[currentIndex];
//
//     await play(item.path, network: item.isNetwork, type: item.type);
//
//     await _savePlayerState();
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
//     if (controller == null || !controller!.value.isInitialized) return;
//
//     // જ્યારે વિડિયો/ઓડિયો પૂરો થાય ત્યારે
//     if (controller!.value.position >= controller!.value.duration) {
//       // જો લૂપિંગ ચાલુ હોય તો video_player પોતે હેન્ડલ કરી લેશે (setLooping true હોય તો)
//       // જો લૂપિંગ બંધ હોય તો જ playNext() કોલ કરો
//       if (!isLooping) {
//         playNext();
//       }
//     }
//   }
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
//
//     if (currentIndex - 1 < 0) {
//       if (isLooping) {
//         currentIndex = queue.length - 1;
//       } else {
//         return;
//       }
//     } else {
//       currentIndex--;
//     }
//
//     final item = queue[currentIndex];
//     await play(item.path, network: item.isNetwork, type: item.type);
//     await _savePlayerState();
//     notifyListeners();
//   }
//
//   Future<void> play(String path, {bool network = false, required String type}) async {
//     // ૧. જો સેમ ગીત/વીડિયો ઓલરેડી ચાલુ હોય, તો રિઝ્યુમ કરો અથવા કશું ના કરો
//     if (currentPath == path) {
//       if (!isPlaying) resume();
//       return;
//     }
//
//     // ૨. જૂનું બધું અટકાવો
//     await stop();
//
//     currentPath = path;
//     currentType = type;
//
//     try {
//       final session = await AudioSession.instance;
//
//       if (type == "audio") {
//         // --- ઓડિયો પ્લેયર લોજિક ---
//
//         // ઓડિયો સેશનને મ્યુઝિક મોડમાં સેટ કરો
//         await session.configure(const AudioSessionConfiguration.music());
//         await session.setActive(true);
//         await audioPlayer.stop();
//         final source = AudioSource.uri(
//           network ? Uri.parse(path) : Uri.file(path),
//           tag: bg.MediaItem(
//             id: path,
//             album: "Local Media",
//             title: path.split('/').last,
//             artist: "Media Player",
//           ),
//         );
//
//         // એરર હેન્ડલિંગ સાથે ઓડિયો લોડ કરો
//         await audioPlayer.setAudioSource(source,preload: true,).catchError((error) {
//           if (error is PlayerInterruptedException) {
//             print("Loading interrupted: common and safe to ignore");
//           } else {
//             print("Actual loading error: $error");
//           }
//         });
//
//         await audioPlayer.play();
//         WakelockPlus.enable();
//       }
//       else {
//
//         // નવું સેટઅપ કરતા પહેલા UI ને કહી દો કે જૂનું કંટ્રોલર ગયું
//         controller = null;
//         notifyListeners();
//         // ૧. ઓડિયો પ્લેયરને પૂરેપૂરું શાંત કરો
//         await audioPlayer.stop();
//
//         // આ લાઈન સૌથી મહત્વની છે: સોર્સને null સેટ કરો જેથી Native એન્જિન ફ્રી થાય
//         await audioPlayer.setAudioSource(
//           ConcatenatingAudioSource(children: []),
//           initialIndex: null,
//           initialPosition: null,
//         );
//
//         // ૨. ઓડિયો સેશનને વીડિયો માટે "Exclusive" રીતે એક્ટિવ કરો
//         final session = await AudioSession.instance;
//         await session.configure(const AudioSessionConfiguration(
//           avAudioSessionCategory: AVAudioSessionCategory.playback,
//           avAudioSessionMode: AVAudioSessionMode.moviePlayback,
//           // એન્ડ્રોઇડ માટે ખાસ સેટિંગ્સ
//           androidAudioAttributes: AndroidAudioAttributes(
//             contentType: AndroidAudioContentType.movie,
//             usage: AndroidAudioUsage.media,
//           ),
//         ));
//
//         // ફોર્સફુલી સેશન એક્ટિવ કરો
//         await session.setActive(true);
//
//         // ૩. જૂનું કંટ્રોલર પ્રોપરલી કાઢી નાખો
//         if (controller != null) {
//           controller!.removeListener(_handlePlaybackCompletion);
//           await controller!.dispose();
//           controller = null;
//         }
//
//         controller = network
//             ? VideoPlayerController.networkUrl(Uri.parse(path))
//             : VideoPlayerController.file(File(path));
//
//         try {
//           await controller!.initialize();
//           // વોલ્યુમ અહીં સેટ કરવું જરૂરી છે
//           await controller!.setVolume(1.0);
//           notifyListeners();
//           controller!.addListener(_handlePlaybackCompletion);
//         } catch (e) {
//           print("Video Init Error: $e");
//           // Chewie સેટઅપ
//           chewie = ChewieController(
//             zoomAndPan: true,
//             aspectRatio: controller!.value.aspectRatio,
//             autoPlay: true,
//             looping: isLooping,
//             videoPlayerController: controller!,
//             // mute: false, // ખાતરી કરો કે અહીં ફોલ્સ છે
//
//             // તમારા કસ્ટમ ઓપ્શન્સ અને કંટ્રોલ્સ
//             deviceOrientationsOnEnterFullScreen: [
//               DeviceOrientation.landscapeLeft,
//               DeviceOrientation.landscapeRight,
//             ],
//             deviceOrientationsAfterFullScreen: [
//               DeviceOrientation.portraitUp,
//               DeviceOrientation.portraitDown,
//             ],
//             materialProgressColors: ChewieProgressColors(
//               playedColor: const Color(0XFF3D57F9),
//               backgroundColor: const Color(0XFFF6F6F6),
//             ),
//             onSufflePressed: () => toggleShuffle(),
//             onNextVideo: () => playNext(),
//             onPreviousVideo: () => playPrevious(),
//
//             additionalOptions: (context) {
//               return [
//                 // OptionItem(
//                 //   onTap: (context) {
//                 //     toggleRotation();
//                 //     Navigator.pop(context);
//                 //   },
//                 //   iconData: Icons.screen_rotation,
//                 //   title: isLandscape ? "Portrait Mode" : "Landscape Mode",
//                 // ),
//                 OptionItem(
//                   controlType: ControlType.miniVideo,
//                   onTap: (context) {
//                     Navigator.pop(context);
//                   },
//                   iconData: Icons.screen_rotation,
//                   title: "Mini Screen",
//                   iconImage: AppSvg.icMiniScreen,
//                 ),
//                 OptionItem(
//                   controlType: ControlType.volume,
//                   onTap: (context) {
//                     // toggleRotation();
//                     // Navigator.pop(context);
//                   },
//                   iconData: Icons.screen_rotation,
//                   title: "Volume",
//                   iconImage: AppSvg.icVolumeOff,
//                 ),
//
//                 OptionItem(
//                   controlType: ControlType.shuffle,
//                   onTap: (context) => toggleShuffle,
//                   iconData: Icons.shuffle,
//                   title: "Shuffle",
//                   iconImage: AppSvg.icShuffle,
//                 ),
//                 OptionItem(
//                   controlType: ControlType.playbackSpeed,
//                   onTap: (context) {
//                     // toggleShuffle();
//                   },
//                   iconData: Icons.shuffle,
//                   title: "video speed",
//                   iconImage: AppSvg.ic2x,
//                 ),
//                 OptionItem(
//                   controlType: ControlType.theme,
//                   onTap: (context) {
//                     toggleShuffle();
//                   },
//                   iconData: Icons.shuffle,
//                   title: "dark",
//                   iconImage: AppSvg.icDarkMode,
//                 ),
//                 OptionItem(
//                   controlType: ControlType.info,
//                   onTap: (context) {
//                     toggleShuffle();
//                   },
//                   iconData: Icons.shuffle,
//                   title: "info",
//                   iconImage: AppSvg.icInfo,
//                 ),
//                 OptionItem(
//                   controlType: ControlType.prev10,
//                   onTap: (context) {
//                     toggleShuffle();
//                   },
//                   iconData: Icons.shuffle,
//                   title: "prev10",
//                   iconImage: AppSvg.ic10Prev,
//                 ),
//                 OptionItem(
//                   controlType: ControlType.next10,
//                   onTap: (context) {
//                     toggleShuffle();
//                   },
//                   iconData: Icons.shuffle,
//                   title: "next10",
//                   iconImage: AppSvg.ic10Next,
//                 ),
//
//                 OptionItem(
//                   onTap: (context) {
//                     // chewie!.videoPlayerController.value.cancelAndRestartTimer();
//                     //
//                     // if (videoPlayerLatestValue.volume == 0) {
//                     //   chewie!.videoPlayerController.setVolume(chewie.videoPlayerController.videoPlayerOptions.);
//                     //   // controller.setVolume(_latestVolume ?? 0.5);
//                     // } else {
//                     //   _latestVolume = controller.value.volume;
//                     //   controller.setVolume(0.0);
//                     // }
//                   },
//                   controlType: ControlType.loop,
//                   iconData: Icons.shuffle,
//                   title: "Loop",
//                   iconImage: AppSvg.icLoop,
//                 ),
//                 OptionItem(
//                   controlType: ControlType.playbackSpeed,
//                   onTap: (context) async {
//                     final newPos =
//                         (controller!.value.position) - Duration(seconds: 10);
//                     controller!.seekTo(
//                       newPos > Duration.zero ? newPos : Duration.zero,
//                     );
//                   },
//                   iconData: Icons.replay_10,
//                   title: "kk",
//                   iconImage: AppSvg.ic10Prev,
//                 ),
//                 OptionItem(
//                   onTap: (context) async {},
//                   controlType: ControlType.miniVideo,
//                   iconData: Icons.replay_10,
//                   title: "miniScreen",
//                   iconImage: AppSvg.icMiniScreen,
//                 ),
//               ];
//             },
//           );
//
//           await controller!.play();
//         }}
//
//       _startPositionSaver();
//     } catch (e) {
//       print("Playback Error: $e");
//     }
//
//     notifyListeners();
//   }
//
//   // કંટ્રોલ મેથડ્સ (બંને પ્લેયર માટે)
//   void pause() {
//     if (currentType == "audio") {
//       audioPlayer.pause();
//     } else {
//       controller?.pause();
//     }
//     notifyListeners();
//   }
//
//   void resume() {
//     if (currentType == "audio") {
//       audioPlayer.play();
//     } else {
//       controller?.play();
//     }
//     notifyListeners();
//   }
//
//
//   Future<void> stop() async {
//     // ૧. ઓડિયો પ્લેયર ક્લીનઅપ
//     if (audioPlayer.playing) {
//       await audioPlayer.stop();
//     }
//     // સોર્સ લોડિંગ કેન્સલ કરવા માટે
//     await audioPlayer.setAudioSource(ConcatenatingAudioSource(children: [])).catchError((e) => null);
//
//     // ૨. વીડિયો પ્લેયર ક્લીનઅપ
//     if (controller != null) {
//       controller!.removeListener(_handlePlaybackCompletion);
//       await controller!.dispose();
//       controller = null;
//     }
//
//     if (chewie != null) {
//       chewie!.dispose();
//       chewie = null;
//     }
//
//     // ઓડિયો સેશન બંધ કરો
//     final session = await AudioSession.instance;
//     await session.setActive(false);
//
//     WakelockPlus.disable();
//     _stopPositionSaver();
//     notifyListeners();
//   }
//
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
//     if (items.isEmpty) return; // ખાલી લિસ્ટ હોય તો કશું ના કરવું
//
//     originalQueue = List.from(items);
//     queue = List.from(items);
//     currentIndex = startIndex;
//     notifyListeners(); // આનાથી UI ને ખબર પડશે કે હવે ઈન્ડેક્સ -1 નથી
//   }
// }
//
//
//
//
//
//
//
//
// // import 'dart:io';
// // import 'dart:typed_data';
// // import 'dart:ui' as ui;
// //
// // import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:hive/hive.dart';
// // import 'package:photo_manager/photo_manager.dart';
// // import 'package:photo_manager/platform_utils.dart';
// // import 'package:share_plus/share_plus.dart';
// //
// // import '../blocs/audio/audio_bloc.dart';
// // import '../models/media_item.dart';
// // import '../widgets/image_item_widget.dart';
// // import 'home_screen.dart';
// // import 'player_screen.dart';
// //
// // class AudioScreen extends StatefulWidget {
// //   const AudioScreen({super.key});
// //
// //   @override
// //   State<AudioScreen> createState() => _AudioScreenState();
// // }
// //
// // class _AudioScreenState extends State<AudioScreen> {
// //   @override
// //   Widget build(BuildContext context) {
// //     final box = Hive.box('audios');
// //
// //     return BlocProvider(
// //       create: (_) => AudioBloc(box)..add(LoadAudios()),
// //       child: Scaffold(
// //         appBar: AppBar(
// //           title: const Text("Audios"),
// //           actions: [
// //             IconButton(
// //               icon: const Icon(Icons.refresh),
// //               onPressed: () =>
// //                   context.read<AudioBloc>().add(LoadAudios()),
// //             ),
// //           ],
// //         ),
// //         body: Stack(children: [const _AudioBody(),Align(
// //             alignment: Alignment.bottomCenter,
// //             child: const MiniPlayer()),]),
// //         floatingActionButton: FloatingActionButton(
// //           onPressed: () =>
// //               context.read<AudioBloc>().add(LoadAudios()),
// //           child: const Icon(Icons.refresh),
// //         ),
// //       ),
// //     );
// //   }
// // }
// // class _AudioBody extends StatefulWidget {
// //   const _AudioBody();
// //
// //   @override
// //   State<_AudioBody> createState() => _AudioBodyState();
// // }
// //
// // class _AudioBodyState extends State<_AudioBody> {
// //   @override
// //   Widget build(BuildContext context) {
// //     return BlocBuilder<AudioBloc, AudioState>(
// //       builder: (context, state) {
// //         if (state is AudioLoading) {
// //           return const Center(
// //             child: CircularProgressIndicator.adaptive(),
// //           );
// //         }
// //
// //         if (state is AudioError) {
// //           return Center(child: Text(state.message));
// //         }
// //
// //         if (state is AudioLoaded) {
// //           if (state.entities.isEmpty) {
// //             return const Center(
// //               child: Text("No audio files found"),
// //             );
// //           }
// //
// //           return ListView.builder(
// //             padding: EdgeInsets.symmetric(horizontal: 15),
// //             itemCount: state.entities.length,
// //             itemBuilder: (context, index) {
// //               final audio = state.entities[index];
// //               final colors = Theme.of(context).extension<AppThemeColors>()!;
// //               return FutureBuilder<File?>(
// //                 future: audio.file,
// //                 builder: (context, snapshot) {
// //                   if (!snapshot.hasData) {
// //                     return const ListTile(
// //                       leading: Icon(Icons.music_note),
// //                       title: Text("Loading..."),
// //                     );
// //                   }
// //
// //                   final file = snapshot.data!;
// //                   return Padding(
// //                     padding: const EdgeInsets.symmetric(vertical: 7.5),
// //                     child: GestureDetector(
// //                       onTap: () {
// //                         print("audio====${audio.typeInt}");
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (_) => PlayerScreen(
// //                               entity: audio,
// //                               item: MediaItem(
// //                                 id: audio.id,
// //                                 path: file.path,
// //                                 isNetwork: false,
// //                                 type: 'audio',
// //                               ),
// //                             ),
// //                           ),
// //                         ).then((value) {
// //                           context.read<AudioBloc>().add(
// //                             LoadAudios(showLoading: false),
// //                           );
// //                         });
// //                       },
// //                       child: Container(
// //                         padding: const EdgeInsets.symmetric(
// //                           horizontal: 10,
// //                           vertical: 10,
// //                         ),
// //                         decoration: BoxDecoration(
// //                           color: colors.cardBackground,
// //                           borderRadius: BorderRadius.circular(10),
// //                         ),
// //                         child: Row(
// //                           children: [
// //                             /// 🎵 Icon + Play overlay
// //                             Container(
// //                               height: 50,
// //                               width: 50,
// //                               decoration: BoxDecoration(
// //                                 borderRadius: BorderRadius.circular(10),
// //                                 color: colors.blackColor.withOpacity(0.38),
// //                               ),
// //                               child: Stack(
// //                                 alignment: Alignment.center,
// //                                 children: [
// //                                   AppImage(
// //                                     src: AppSvg.musicUnselected,
// //                                     height: 22,
// //                                   ),
// //                                   AppImage(
// //                                     src: GlobalPlayer().currentPath == file.path
// //                                         ? AppSvg.playerPause
// //                                         : AppSvg.playerResume,
// //                                     height: 18,
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //
// //                             const SizedBox(width: 12),
// //
// //                             /// 🎶 Title + Duration
// //                             Expanded(
// //                               child: Column(
// //                                 crossAxisAlignment: CrossAxisAlignment.start,
// //                                 mainAxisSize: MainAxisSize.min,
// //                                 children: [
// //                                   AppText(
// //                                     file.path.split('/').last,
// //                                     maxLines: 1,
// //                                     // overflow: TextOverflow.ellipsis,
// //                                     fontSize: 15,
// //                                     fontWeight: FontWeight.w500,
// //                                   ),
// //                                   const SizedBox(height: 6),
// //                                   AppText(
// //                                     formatDuration(audio.duration),
// //                                     fontSize: 13,
// //                                     fontWeight: FontWeight.w500,
// //                                     color: colors.textFieldBorder,
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //
// //                             const SizedBox(width: 6),
// //
// //                             /// ⋮ Menu
// //                             PopupMenuButton<MediaMenuAction>(
// //                               padding: EdgeInsets.zero,
// //                               icon: AppImage(src: AppSvg.dropDownMenuDot),
// //                               onSelected: (action) async {
// //                                 switch (action) {
// //                                   case MediaMenuAction.detail:
// //                                     routeToDetailPage(context, audio);
// //                                     break;
// //                                   case MediaMenuAction.info:
// //                                     showInfoDialog(context, audio);
// //                                     break;
// //                                   case MediaMenuAction.thumb:
// //                                     showThumb(context, audio, 500);
// //                                     break;
// //                                   case MediaMenuAction.share:
// //                                     _shareItem(context, audio);
// //                                     break;
// //                                   case MediaMenuAction.delete:
// //                                     _deleteCurrent(context, audio);
// //                                     break;
// //                                   case MediaMenuAction.addToFavourite:
// //                                     await _toggleFavourite(
// //                                       context,
// //                                       audio,
// //                                       index,
// //                                     );
// //                                     break;
// //                                 }
// //                               },
// //                               itemBuilder: (context) => [
// //                                 const PopupMenuItem(
// //                                   value: MediaMenuAction.detail,
// //                                   child: Text('Show detail page'),
// //                                 ),
// //                                 const PopupMenuItem(
// //                                   value: MediaMenuAction.info,
// //                                   child: Text('Show info dialog'),
// //                                 ),
// //                                 if (audio.type == AssetType.video)
// //                                   const PopupMenuItem(
// //                                     value: MediaMenuAction.thumb,
// //                                     child: Text('Show 500 size thumb'),
// //                                   ),
// //                                 const PopupMenuItem(
// //                                   value: MediaMenuAction.share,
// //                                   child: Text('Share'),
// //                                 ),
// //                                 PopupMenuItem(
// //                                   value: MediaMenuAction.addToFavourite,
// //                                   child: Text(
// //                                     audio.isFavorite
// //                                         ? 'Remove from Favourite'
// //                                         : 'Add to Favourite',
// //                                   ),
// //                                 ),
// //                                 const PopupMenuItem(
// //                                   value: MediaMenuAction.delete,
// //                                   child: Text('Delete'),
// //                                 ),
// //                               ],
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                   );
// //
// //                   ListTile(
// //                     leading: const Icon(Icons.music_note),
// //                     title: Text(
// //                       file.path.split('/').last,
// //                       maxLines: 3,
// //                       overflow: TextOverflow.ellipsis,
// //                     ),
// //                     onTap: () {
// //                       print("audio====${audio.typeInt}");
// //                       Navigator.push(
// //                         context,
// //                         MaterialPageRoute(
// //                           builder: (_) => PlayerScreen(
// //                             entity: audio,
// //                             item: MediaItem(
// //                               id: audio.id,
// //                               path: file.path,
// //                               isNetwork: false,
// //                               type: 'audio',
// //                             ),
// //                           ),
// //                         ),
// //                       ).then((value) {
// //                         context.read<AudioBloc>().add(
// //                           LoadAudios(showLoading: false),
// //                         );
// //                       });
// //                     },
// //                     trailing: PopupMenuButton<MediaMenuAction>(
// //                       icon: Container(
// //                         padding: const EdgeInsets.all(6),
// //                         decoration: BoxDecoration(
// //                           color: Colors.black.withOpacity(0.5),
// //                           shape: BoxShape.circle,
// //                         ),
// //                         child: const Icon(
// //                           Icons.more_vert,
// //                           color: Colors.white,
// //                           size: 18,
// //                         ),
// //                       ),
// //                       onSelected: (action) async {
// //                         switch (action) {
// //                           case MediaMenuAction.detail:
// //                             routeToDetailPage(context, audio);
// //                             break;
// //
// //                           case MediaMenuAction.info:
// //                             showInfoDialog(context, audio);
// //                             break;
// //
// //                           case MediaMenuAction.thumb:
// //                             showThumb(context, audio, 500);
// //                             break;
// //
// //                           case MediaMenuAction.share:
// //                             _shareItem(context, audio);
// //                             break;
// //
// //                           case MediaMenuAction.delete:
// //                             _deleteCurrent(context, audio);
// //                             break;
// //
// //                           case MediaMenuAction.addToFavourite:
// //                             await _toggleFavourite(context, audio, index);
// //                             break;
// //                         }
// //                       },
// //                       itemBuilder: (context) => [
// //                         const PopupMenuItem(
// //                           value: MediaMenuAction.detail,
// //                           child: Text('Show detail page'),
// //                         ),
// //                         const PopupMenuItem(
// //                           value: MediaMenuAction.info,
// //                           child: Text('Show info dialog'),
// //                         ),
// //                         if (audio.type == AssetType.video)
// //                           const PopupMenuItem(
// //                             value: MediaMenuAction.thumb,
// //                             child: Text('Show 500 size thumb'),
// //                           ),
// //                         const PopupMenuItem(
// //                           value: MediaMenuAction.share,
// //                           child: Text('Share'),
// //                         ),
// //                         PopupMenuItem(
// //                           value: MediaMenuAction.addToFavourite,
// //                           child: Text(
// //                             audio.isFavorite
// //                                 ? "Remove to Favourite"
// //                                 : 'Add to Favourite',
// //                           ),
// //                         ),
// //                         const PopupMenuItem(
// //                           value: MediaMenuAction.delete,
// //                           child: Text('Delete'),
// //                         ),
// //                       ],
// //                     ),
// //                   );
// //                 },
// //               );
// //             },
// //           );
// //
// //         }
// //
// //         return const SizedBox();
// //       },
// //     );
// //   }
// //
// //   Future<void> routeToDetailPage(BuildContext context,AssetEntity entity) async {
// //     Navigator.of(context).push<void>(
// //       MaterialPageRoute<void>(builder: (_) => DetailPage(entity: entity)),
// //     );
// //   }
// //
// //   Future<void> showThumb(BuildContext context, AssetEntity entity, int size) async {
// //     final String title;
// //     if (entity.title?.isEmpty != false) {
// //       title = await entity.titleAsync;
// //     } else {
// //       title = entity.title!;
// //     }
// //     print('entity.title = $title');
// //     return showDialog(
// //       context: context,
// //       builder: (_) {
// //         return FutureBuilder<Uint8List?>(
// //           future: entity.thumbnailDataWithOption(
// //             ThumbnailOption.ios(
// //               size: const ThumbnailSize.square(500),
// //               // resizeContentMode: ResizeContentMode.fill,
// //             ),
// //           ),
// //           builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
// //             Widget w;
// //             if (snapshot.hasError) {
// //               return ErrorWidget(snapshot.error!);
// //             } else if (snapshot.hasData) {
// //               final Uint8List data = snapshot.data!;
// //               ui.decodeImageFromList(data, (ui.Image result) {
// //                 print('result size: ${result.width}x${result.height}');
// //                 // for 4288x2848
// //               });
// //               w = Image.memory(data);
// //             } else {
// //               w = Center(
// //                 child: Container(
// //                   color: Colors.white,
// //                   padding: const EdgeInsets.all(20),
// //                   child: const CircularProgressIndicator(),
// //                 ),
// //               );
// //             }
// //             return GestureDetector(
// //               child: w,
// //               onTap: () => Navigator.pop(context),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }
// //
// //   Future<void> _shareItem(BuildContext context, AssetEntity entity) async {
// //     final file = await entity.file;
// //     await Share.shareXFiles([XFile(file!.path)], text: entity.title);
// //   }
// //
// //   Future<void> _toggleFavourite(
// //       BuildContext context,
// //       AssetEntity entity,
// //       int index,
// //       ) async {
// //     final favBox = Hive.box('favourites');
// //     final bool isFavorite = entity.isFavorite;
// //
// //     final file = await entity.file;
// //     if (file == null) return;
// //
// //     final key = file.path;
// //
// //     // 🔹 Update Hive
// //     if (isFavorite) {
// //       favBox.delete(key);
// //     } else {
// //       favBox.put(key, {
// //         "path": file.path,
// //         "isNetwork": false,
// //         "type": entity.type == AssetType.audio ? "audio" : "video",
// //       });
// //     }
// //
// //     // 🔹 Update system favourite
// //     if (PlatformUtils.isOhos) {
// //       await PhotoManager.editor.ohos.favoriteAsset(
// //         entity: entity,
// //         favorite: !isFavorite,
// //       );
// //     } else if (Platform.isAndroid) {
// //       await PhotoManager.editor.android.favoriteAsset(
// //         entity: entity,
// //         favorite: !isFavorite,
// //       );
// //     } else {
// //       await PhotoManager.editor.darwin.favoriteAsset(
// //         entity: entity,
// //         favorite: !isFavorite,
// //       );
// //     }
// //
// //     // 🔹 Reload entity
// //     final AssetEntity? newEntity = await entity.obtainForNewProperties();
// //     if (!mounted || newEntity == null) return;
// //
// //     // 🔹 Update UI list
// //     // readPathProvider(context).list[index] = newEntity;
// //     context.read<AudioBloc>().add(LoadAudios(showLoading: false));
// //
// //     setState(() {});
// //   }
// //
// //   Future<void> _deleteCurrent(
// //       BuildContext context,
// //       AssetEntity entity,
// //       ) async {
// //     if (!Platform.isAndroid && !Platform.isIOS) return;
// //
// //     final bool? confirm = await showDialog<bool>(
// //       context: context,
// //       builder: (_) => AlertDialog(
// //         title: const Text('Delete media'),
// //         content: const Text('Are you sure you want to delete this file?'),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context, false),
// //             child: const Text('Cancel'),
// //           ),
// //           TextButton(
// //             onPressed: () => Navigator.pop(context, true),
// //             child: const Text(
// //               'Delete',
// //               style: TextStyle(color: Colors.red),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //
// //     if (confirm != true) return;
// //
// //     // ✅ Correct delete API
// //     final result = await PhotoManager.editor.deleteWithIds([entity.id]);
// //
// //     if (result.isNotEmpty) {
// //       context
// //           .read<AudioBloc>()
// //           .add(LoadAudios(showLoading: false));
// //     }
// //   }
// // }
// //
// //
// //
// // import 'dart:io';
// // import 'dart:typed_data';
// // import 'dart:ui' as ui;
// //
// // import 'package:flutter/cupertino.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:hive/hive.dart';
// // import 'package:photo_manager/photo_manager.dart';
// // import 'package:photo_manager/platform_utils.dart';
// // import 'package:share_plus/share_plus.dart';
// // import 'package:video_player_app/screens/player_screen.dart';
// //
// // import '../blocs/home/home_tab_bolc.dart';
// // import '../blocs/home/home_tab_event.dart';
// // import '../blocs/home/home_tab_state.dart';
// // import '../blocs/video/video_bloc.dart';
// // import '../main.dart';
// // import '../models/media_item.dart';
// // import '../widgets/home_card.dart';
// // import '../widgets/image_item_widget.dart';
// // import 'home_screen.dart';
// //
// // class HomePage extends StatefulWidget {
// //   const HomePage({super.key});
// //
// //   @override
// //   State<HomePage> createState() => _HomePageState();
// // }
// //
// // class _HomePageState extends State<HomePage> with RouteAware{
// //   AssetPathProvider readPathProvider(BuildContext c) =>
// //       c.read<AssetPathProvider>();
// //
// //   AssetPathProvider watchPathProvider(BuildContext c) =>
// //       c.watch<AssetPathProvider>();
// //   List<AssetPathEntity> folderList = <AssetPathEntity>[];
// //
// //   int videoCount = 0;
// //   int audioCount = 0;
// //   int favouriteCount = 0;
// //   int playlistCount = 0;
// //
// //   @override
// //   void didChangeDependencies() {
// //     super.didChangeDependencies();
// //     routeObserver.subscribe(this, ModalRoute.of(context)!);
// //   }
// //
// //   @override
// //   void dispose() {
// //     routeObserver.unsubscribe(this);
// //     super.dispose();
// //   }
// //
// //   // Called when we return to this page
// //   @override
// //   void didPopNext() {
// //     _loadCounts(); // <-- refresh counts when coming back
// //     context.read<VideoBloc>().add(LoadVideosFromGallery()); // optional: refresh video list
// //   }
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     // WidgetsBinding.instance.addPostFrameCallback((_) {
// //     _loadCounts();
// //     // });
// //   }
// //   Future<void> _loadCounts() async {
// //     final favBox = Hive.box('favourites');
// //     final videoBox = Hive.box('videos');
// //     final audioBox = Hive.box('audios');
// //     final playListBox = Hive.box('playlists');
// //
// //     if (!mounted) return;
// //
// //     setState(() {
// //       videoCount = videoBox.length;
// //       audioCount = audioBox.length;
// //       favouriteCount = favBox.length;
// //       playlistCount = playListBox.length;
// //     });
// //   }
// //
// //
// //
// //
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: Text("Media Player")),
// //       body: SingleChildScrollView(
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // Top Grid of Cards
// //             BlocBuilder<VideoBloc, VideoState>(
// //               builder: (context, state) {
// //                 int videoCount = 0, audioCount = 0, favCount = 0, playlistCount = 0;
// //
// //                 if (state is VideoLoaded) {
// //                   videoCount = state.videoCount;
// //                   audioCount = state.audioCount;
// //                   favCount = state.favouriteCount;
// //                   playlistCount = state.playlistCount;
// //                 }
// //
// //                 return GridView.count(
// //                   shrinkWrap: true,
// //                   physics: const NeverScrollableScrollPhysics(),
// //                   crossAxisCount: 2,
// //                   padding: const EdgeInsets.all(12),
// //                   children: [
// //                     HomeCard(
// //                       title: "Video",
// //                       icon: Icons.video_library,
// //                       route: "/video",
// //                       count: videoCount,
// //                       loadCounts: Future(() => context.read<VideoBloc>().add(RefreshCounts())),
// //                     ),
// //                     HomeCard(
// //                       title: "Audio",
// //                       icon: Icons.music_note,
// //                       route: "/audio",
// //                       count: audioCount,
// //                       loadCounts: Future(() => context.read<VideoBloc>().add(RefreshCounts())),
// //                     ),
// //                     HomeCard(
// //                       title: "Playlist",
// //                       icon: Icons.queue_music,
// //                       route: "/playlist",
// //                       count: playlistCount,
// //                       loadCounts: Future(() => context.read<VideoBloc>().add(RefreshCounts())),
// //                     ),
// //                     HomeCard(
// //                       title: "Favourite",
// //                       icon: Icons.favorite,
// //                       route: "/favourite",
// //                       count: favCount,
// //                       loadCounts: Future(() => context.read<VideoBloc>().add(RefreshCounts())),
// //                     ),
// //                   ],
// //                 );
// //               },
// //             ),
// //
// //
// //             // Custom Tab Bar
// //             Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //               child: Row(
// //                 children: [
// //                   Expanded(child: _buildTab(context, "Video", 0)),
// //                   const SizedBox(width: 16),
// //                   Expanded(child: _buildTab(context, "Folder", 1)),
// //                 ],
// //               ),
// //             ),
// //             // Tab Content
// //             Padding(
// //               padding: const EdgeInsets.all(8.0),
// //               child: BlocBuilder<HomeTabBloc, HomeTabState>(
// //                 builder: (context, state) {
// //                   if (state.selectedIndex == 0) {
// //                     return _buildVideoSection();
// //                   } else {
// //                     return _buildFolderSection();
// //                   }
// //                 },
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTab(BuildContext context, String title, int index) {
// //     return BlocBuilder<HomeTabBloc, HomeTabState>(
// //       builder: (context, state) {
// //         final isActive = state.selectedIndex == index;
// //
// //         return GestureDetector(
// //           onTap: () async {
// //             context.read<HomeTabBloc>().add(SelectTab(index));
// //             if (index == 1) {
// //               await _loadFolders();
// //             } else if (index == 0) {
// //               context.read<VideoBloc>().add(LoadVideosFromGallery());
// //             }
// //           },
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Text(
// //                 title,
// //                 style: TextStyle(
// //                   color: isActive ? Colors.white : Colors.white70,
// //                   fontSize: 18,
// //                   fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
// //                 ),
// //               ),
// //               const SizedBox(height: 4),
// //               AnimatedContainer(
// //                 duration: const Duration(milliseconds: 200),
// //                 height: 3,
// //                 width: isActive ? 30 : 0,
// //                 decoration: BoxDecoration(
// //                   color: Colors.red,
// //                   borderRadius: BorderRadius.circular(2),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// //
// //   // Video Section using VideoBloc
// //   Widget _buildVideoSection() {
// //     return BlocBuilder<VideoBloc, VideoState>(
// //       builder: (context, state) {
// //         if (state is VideoLoading) {
// //           return const Center(child: CircularProgressIndicator.adaptive());
// //         }
// //
// //         if (state is VideoError) {
// //           return Center(child: Text(state.message));
// //         }
// //
// //         if (state is VideoLoaded) {
// //           final entities = state.entities;
// //           if (entities.isEmpty) {
// //             return const Text(
// //               "No videos found",
// //               style: TextStyle(color: Colors.white),
// //             );
// //           }
// //
// //           return GridView.builder(
// //             shrinkWrap: true,
// //             physics: const NeverScrollableScrollPhysics(),
// //             itemCount: entities.length,
// //             gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(
// //               crossAxisCount: 2,
// //               crossAxisSpacing: 4,
// //               mainAxisSpacing: 4,
// //               childAspectRatio: 1.3,
// //             ),
// //             itemBuilder: (context, index) {
// //               final entity = entities[index];
// //               return ImageItemWidget(
// //                 entity: entity,
// //                 option: ThumbnailOption(size: ThumbnailSize.square(200)),
// //                 onMenuSelected: (action) async {
// //                   switch (action) {
// //                     case MediaMenuAction.detail:
// //                       routeToDetailPage(entity);
// //                       break;
// //
// //                     case MediaMenuAction.info:
// //                       showInfoDialog(context, entity);
// //                       break;
// //
// //                     case MediaMenuAction.thumb:
// //                       showThumb(entity, 500);
// //                       break;
// //
// //                     case MediaMenuAction.share:
// //                       _shareItem(context, entity);
// //                       break;
// //
// //                     case MediaMenuAction.delete:
// //                       _deleteCurrent(context, entity);
// //                       break;
// //
// //                     case MediaMenuAction.addToFavourite:
// //                       await _toggleFavourite(context, entity, index);
// //                       break;
// //                   }
// //                 },
// //                 onTap: () async {
// //                   final file = await entity.file;
// //                   if (file == null || !file.existsSync()) return;
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (_) =>
// //                           PlayerScreen(
// //                             entity: entity,
// //                             item: MediaItem(
// //                               id: entity.id,
// //                               path: file.path,
// //                               isNetwork: false,
// //                               type: entity.type == AssetType.video
// //                                   ? 'video'
// //                                   : 'audio',
// //                             ),
// //                           ),
// //                     ),
// //                   ).then((value) {
// //                     context.read<VideoBloc>().add(LoadVideosFromGallery());
// //                   },);
// //                 },
// //               );
// //             },
// //           );
// //         }
// //
// //         return const SizedBox();
// //       },
// //     );
// //   }
// //
// //
// //   Future<void> _deleteCurrent(BuildContext context,
// //       AssetEntity entity,) async {
// //     if (!Platform.isAndroid && !Platform.isIOS) return;
// //
// //     final bool? confirm = await showDialog<bool>(
// //       context: context,
// //       builder: (_) =>
// //           AlertDialog(
// //             title: const Text('Delete media'),
// //             content: const Text('Are you sure you want to delete this file?'),
// //             actions: [
// //               TextButton(
// //                 onPressed: () => Navigator.pop(context, false),
// //                 child: const Text('Cancel'),
// //               ),
// //               TextButton(
// //                 onPressed: () => Navigator.pop(context, true),
// //                 child: const Text(
// //                   'Delete',
// //                   style: TextStyle(color: Colors.red),
// //                 ),
// //               ),
// //             ],
// //           ),
// //     );
// //
// //     if (confirm != true) return;
// //
// //     // ✅ Correct delete API
// //     final result = await PhotoManager.editor.deleteWithIds([entity.id]);
// //
// //     if (result.isNotEmpty) {
// //       context
// //           .read<VideoBloc>()
// //           .add(LoadVideosFromGallery(showLoading: false));
// //     }
// //   }
// //
// //
// //   Future<void> _toggleFavourite(BuildContext context,
// //       AssetEntity entity,
// //       int index,) async {
// //     final favBox = Hive.box('favourites');
// //     final bool isFavorite = entity.isFavorite;
// //
// //     final file = await entity.file;
// //     if (file == null) return;
// //
// //     final key = file.path;
// //
// //     // 🔹 Update Hive
// //     if (isFavorite) {
// //       favBox.delete(key);
// //     } else {
// //       favBox.put(key, {
// //         "path": file.path,
// //         "isNetwork": false,
// //         "type": entity.type == AssetType.audio ? "audio" : "video",
// //       });
// //     }
// //
// //     // 🔹 Update system favourite
// //     if (PlatformUtils.isOhos) {
// //       await PhotoManager.editor.ohos.favoriteAsset(
// //         entity: entity,
// //         favorite: !isFavorite,
// //       );
// //     } else if (Platform.isAndroid) {
// //       await PhotoManager.editor.android.favoriteAsset(
// //         entity: entity,
// //         favorite: !isFavorite,
// //       );
// //     } else {
// //       await PhotoManager.editor.darwin.favoriteAsset(
// //         entity: entity,
// //         favorite: !isFavorite,
// //       );
// //     }
// //
// //     // 🔹 Reload entity
// //     final AssetEntity? newEntity = await entity.obtainForNewProperties();
// //     if (!mounted || newEntity == null) return;
// //
// //     // 🔹 Update UI list
// //     // readPathProvider(context).list[index] = newEntity;
// //     context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
// //
// //     setState(() {});
// //   }
// //
// //
// //   // Folder Section
// //   Widget _buildFolderSection() {
// //     if (folderList.isEmpty) {
// //       return const Text(
// //         "No folders found",
// //         style: TextStyle(color: Colors.white),
// //       );
// //     }
// //
// //     return ListView.builder(
// //       shrinkWrap: true,
// //       physics: const NeverScrollableScrollPhysics(),
// //       itemCount: folderList.length,
// //       itemBuilder: (context, index) {
// //         final item = folderList[index];
// //         return GalleryItemWidget(path: item, setState: setState);
// //       },
// //     );
// //   }
// //
// //   // Load folders using PhotoManager
// //   Future<void> _loadFolders() async {
// //     final permission = await PhotoManager.requestPermissionExtend(
// //       requestOption: PermissionRequestOption(
// //         androidPermission: AndroidPermission(
// //           type: RequestType.fromTypes([RequestType.audio, RequestType.video]),
// //           mediaLocation: true,
// //         ),
// //       ),
// //     );
// //     if (!permission.hasAccess) return;
// //
// //     final List<AssetPathEntity> galleryList =
// //     await PhotoManager.getAssetPathList(
// //       type: RequestType.fromTypes([RequestType.audio, RequestType.video]),
// //       filterOption: FilterOptionGroup(),
// //       pathFilterOption: PMPathFilter(
// //         darwin: PMDarwinPathFilter(
// //           type: [PMDarwinAssetCollectionType.album],
// //         ),
// //       ),
// //     );
// //
// //     setState(() {
// //       folderList.clear();
// //       folderList.addAll(galleryList);
// //     });
// //   }
// //
// //   Future<void> routeToDetailPage(AssetEntity entity) async {
// //     Navigator.of(context).push<void>(
// //       MaterialPageRoute<void>(builder: (_) => DetailPage(entity: entity)),
// //     );
// //   }
// //
// //   Future<void> showThumb(AssetEntity entity, int size) async {
// //     final String title;
// //     if (entity.title?.isEmpty != false) {
// //       title = await entity.titleAsync;
// //     } else {
// //       title = entity.title!;
// //     }
// //     print('entity.title = $title');
// //     return showDialog(
// //       context: context,
// //       builder: (_) {
// //         return FutureBuilder<Uint8List?>(
// //           future: entity.thumbnailDataWithOption(
// //             ThumbnailOption.ios(
// //               size: const ThumbnailSize.square(500),
// //               // resizeContentMode: ResizeContentMode.fill,
// //             ),
// //           ),
// //           builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
// //             Widget w;
// //             if (snapshot.hasError) {
// //               return ErrorWidget(snapshot.error!);
// //             } else if (snapshot.hasData) {
// //               final Uint8List data = snapshot.data!;
// //               ui.decodeImageFromList(data, (ui.Image result) {
// //                 print('result size: ${result.width}x${result.height}');
// //                 // for 4288x2848
// //               });
// //               w = Image.memory(data);
// //             } else {
// //               w = Center(
// //                 child: Container(
// //                   color: Colors.white,
// //                   padding: const EdgeInsets.all(20),
// //                   child: const CircularProgressIndicator(),
// //                 ),
// //               );
// //             }
// //             return GestureDetector(
// //               child: w,
// //               onTap: () => Navigator.pop(context),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }
// //
// //   Future<void> _shareItem(BuildContext context, AssetEntity entity) async {
// //     final file = await entity.file;
// //     await Share.shareXFiles([XFile(file!.path)], text: entity.title);
// //   }
// // }
// //
// // /*
// // BlocBuilder<VideoBloc, VideoState>(
// //               builder: (context, state) {
// //                 int videoCount = 0, audioCount = 0, favCount = 0, playlistCount = 0;
// //
// //                 if (state is VideoLoaded) {
// //                   videoCount = state.videoCount;
// //                   audioCount = state.audioCount;
// //                   favCount = state.favouriteCount;
// //                   playlistCount = state.playlistCount;
// //                 }
// //
// //                 return GridView.count(
// //                   shrinkWrap: true,
// //                   physics: const NeverScrollableScrollPhysics(),
// //                   crossAxisCount: 2,
// //                   padding: const EdgeInsets.all(12),
// //                   children: [
// //                     HomeCard(title: "Video", icon: Icons.video_library, route: "/video", count: videoCount, loadCounts: Future(() => context.read<VideoBloc>().add(RefreshCounts()))),
// //                     HomeCard(title: "Audio", icon: Icons.music_note, route: "/audio", count: audioCount, loadCounts: Future(() => context.read<VideoBloc>().add(RefreshCounts()))),
// //                     HomeCard(title: "Playlist", icon: Icons.queue_music, route: "/playlist", count: playlistCount, loadCounts: Future(() => context.read<VideoBloc>().add(RefreshCounts()))),
// //                     HomeCard(title: "Favourite", icon: Icons.favorite, route: "/favourite", count: favCount, loadCounts: Future(() => context.read<VideoBloc>().add(RefreshCounts()))),
// //                   ],
// //                 );
// //               },
// //             ),
// //
// //  */
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// // // import 'dart:io';
// // // import 'package:flutter/material.dart';
// // // import 'package:path_provider/path_provider.dart';
// // // import 'package:video_player/video_player.dart';
// // // import 'package:chewie/chewie.dart';
// // // import 'package:file_picker/file_picker.dart';
// // // import 'package:shared_preferences/shared_preferences.dart';
// // // import 'package:hive_flutter/hive_flutter.dart';
// // // import 'package:video_thumbnail/video_thumbnail.dart';
// // //
// // // import 'package:flutter/cupertino.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:hive/hive.dart';
// // //
// // //
// // // import 'dart:io';
// // //
// // // import 'package:flutter/cupertino.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:hive/hive.dart';
// // // import 'package:path_provider/path_provider.dart';
// // // import 'package:video_thumbnail/video_thumbnail.dart';
// // //
// // // void main() async {
// // //   WidgetsFlutterBinding.ensureInitialized();
// // //   await Hive.initFlutter();
// // //   await Hive.openBox('playlists');
// // //   runApp(const VideoPlayerApp());
// // // }
// // //
// // // /// ================= MEDIA ITEM =================
// // // class MediaItem {
// // //   final String path;
// // //   final bool isNetwork;
// // //
// // //   MediaItem({required this.path, required this.isNetwork});
// // // }
// // //
// // // class VideoPlayerApp extends StatelessWidget {
// // //   const VideoPlayerApp({super.key});
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return MaterialApp(
// // //       debugShowCheckedModeBanner: false,
// // //       theme: ThemeData.dark(),
// // //       home: const HomeScreen(),
// // //     );
// // //   }
// // // }
// // //
// // // enum LoopMode { none, one, all }
// // //
// // // class HomeScreen extends StatefulWidget {
// // //   const HomeScreen({super.key});
// // //
// // //   @override
// // //   State<HomeScreen> createState() => _HomeScreenState();
// // // }
// // //
// // // class _HomeScreenState extends State<HomeScreen> {
// // //   VideoPlayerController? _videoController;
// // //   ChewieController? _chewieController;
// // //   Key _playerKey = UniqueKey();
// // //
// // //   final List<MediaItem> _playlist = [];
// // //   int _currentIndex = -1;
// // //
// // //   double _volume = 0.5;
// // //   bool _isSwitching = false;
// // //   LoopMode _loopMode = LoopMode.none;
// // //
// // //   /// ================= PLAY MEDIA =================
// // //   Future<void> _playMedia(int index) async {
// // //     if (index < 0 || index >= _playlist.length) return;
// // //
// // //     final media = _playlist[index];
// // //     _isSwitching = true;
// // //
// // //     await _videoController?.pause();
// // //     _videoController?.dispose();
// // //     _chewieController?.dispose();
// // //
// // //     try {
// // //       final isAudio = media.path
// // //           .split('.')
// // //           .last
// // //           .toLowerCase()
// // //           .contains(RegExp(r'mp3|m4a|aac|wav'));
// // //
// // //       _videoController = media.isNetwork
// // //           ? VideoPlayerController.networkUrl(Uri.parse(media.path))
// // //           : VideoPlayerController.file(File(media.path));
// // //
// // //       await _videoController!.initialize();
// // //       _videoController!.setVolume(_volume);
// // //
// // //       _chewieController = ChewieController(
// // //         videoPlayerController: _videoController!,
// // //         autoPlay: true,
// // //         allowFullScreen: !isAudio,
// // //         allowPlaybackSpeedChanging: true,
// // //         aspectRatio: isAudio ? 1 : 16 / 9,
// // //       );
// // //
// // //       _playerKey = UniqueKey();
// // //       _currentIndex = index;
// // //       setState(() {});
// // //     } catch (e) {
// // //       _showSnack(
// // //         media.isNetwork
// // //             ? "Network error. Check your internet connection."
// // //             : "Unable to play this file.",
// // //       );
// // //     }
// // //
// // //     _isSwitching = false;
// // //   }
// // //
// // //   /// ================= PICK LOCAL FILES =================
// // //   Future<void> pickLocalFiles() async {
// // //     final result = await FilePicker.platform.pickFiles(
// // //       allowMultiple: true,
// // //       type: FileType.custom,
// // //       allowedExtensions: ['mp4', 'mkv', 'avi', 'mp3', 'm4a', 'aac', 'wav'],
// // //     );
// // //
// // //     if (result == null) return;
// // //
// // //     int startIndex = _playlist.length;
// // //
// // //     for (final f in result.files) {
// // //       _playlist.add(MediaItem(path: f.path!, isNetwork: false));
// // //     }
// // //
// // //     await _playMedia(startIndex);
// // //   }
// // //
// // //   /// ================= ADD NETWORK VIDEO =================
// // //   Future<void> addNetworkVideoDialog() async {
// // //     String url = '';
// // //
// // //     await showDialog(
// // //       context: context,
// // //       builder: (_) => AlertDialog(
// // //         title: const Text("Network Video URL"),
// // //         content: TextField(
// // //           onChanged: (v) => url = v,
// // //           decoration: const InputDecoration(hintText: "http://..."),
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.pop(context),
// // //             child: const Text("Cancel"),
// // //           ),
// // //           TextButton(
// // //             onPressed: () => Navigator.pop(context),
// // //             child: const Text("Add"),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //
// // //     if (url.isEmpty) return;
// // //
// // //     _playlist.add(MediaItem(path: url, isNetwork: true));
// // //     await _playMedia(_playlist.length - 1);
// // //   }
// // //
// // //   /// ================= ADD TO PLAYLIST (HIVE) =================
// // //   Future<void> _addCurrentMediaToPlaylist() async {
// // //     if (_currentIndex < 0) return;
// // //
// // //     final media = _playlist[_currentIndex];
// // //     final box = Hive.box('playlists');
// // //     String newName = '';
// // //
// // //     await showDialog(
// // //       context: context,
// // //       builder: (_) => AlertDialog(
// // //         title: const Text("Add to Playlist"),
// // //         content: SingleChildScrollView(
// // //           child: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               ...box.keys.map((key) {
// // //                 final playlist = box.get(key);
// // //                 return ListTile(
// // //                   title: Text(playlist['name']),
// // //                   onTap: () {
// // //                     final items = List<Map>.from(playlist['items']);
// // //                     items.removeWhere((e) => e['path'] == media.path);
// // //                     items.add({
// // //                       'path': media.path,
// // //                       'isNetwork': media.isNetwork,
// // //                     });
// // //                     box.put(key, {'name': playlist['name'], 'items': items});
// // //                     Navigator.pop(context);
// // //                     _showSnack("Added to ${playlist['name']}");
// // //                   },
// // //                 );
// // //               }).toList(),
// // //               const Divider(),
// // //               TextField(
// // //                 decoration: const InputDecoration(
// // //                   hintText: "New playlist name",
// // //                 ),
// // //                 onChanged: (v) => newName = v,
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () {
// // //               if (newName.isEmpty) return;
// // //               box.add({
// // //                 'name': newName,
// // //                 'items': [
// // //                   {'path': media.path, 'isNetwork': media.isNetwork},
// // //                 ],
// // //               });
// // //               Navigator.pop(context);
// // //               _showSnack("Playlist created");
// // //             },
// // //             child: const Text("Create"),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   /// ================= show all PLAYLIST =================
// // //   void _showAllPlaylists() async {
// // //     final box = Hive.box('playlists');
// // //
// // //     final result = await Navigator.push(
// // //       context,
// // //       MaterialPageRoute(builder: (_) => PlaylistListScreen(box: box)),
// // //     );
// // //
// // //     if (result == null) return;
// // //
// // //     final playlist = box.get(result['playlistKey']);
// // //     _playlist.clear();
// // //
// // //     for (final item in playlist['items']) {
// // //       _playlist.add(
// // //         MediaItem(path: item['path'], isNetwork: item['isNetwork']),
// // //       );
// // //     }
// // //
// // //     await _playMedia(result['startIndex']);
// // //   }
// // //
// // //   Future<void> _loadPlaylistFromHive(dynamic key) async {
// // //     final box = Hive.box('playlists');
// // //     final playlist = box.get(key);
// // //
// // //     _playlist.clear();
// // //
// // //     for (final item in playlist['items']) {
// // //       _playlist.add(
// // //         MediaItem(path: item['path'], isNetwork: item['isNetwork']),
// // //       );
// // //     }
// // //
// // //     if (_playlist.isNotEmpty) {
// // //       await _playMedia(0);
// // //     }
// // //   }
// // //
// // //   Future<bool> _confirmDeletePlaylist() async {
// // //     bool confirm = false;
// // //
// // //     await showDialog(
// // //       context: context,
// // //       builder: (_) => AlertDialog(
// // //         title: const Text("Delete Playlist"),
// // //         content: const Text("Are you sure?"),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () {
// // //               confirm = false;
// // //               Navigator.pop(context);
// // //             },
// // //             child: const Text("Cancel"),
// // //           ),
// // //           TextButton(
// // //             onPressed: () {
// // //               confirm = true;
// // //               Navigator.pop(context);
// // //             },
// // //             child: const Text("Delete"),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //
// // //     return confirm;
// // //   }
// // //
// // //   /// ================= PLAYLIST VIEW =================
// // //   void showPlaylist() {
// // //     if (_playlist.isEmpty) return;
// // //
// // //     showModalBottomSheet(
// // //       context: context,
// // //       builder: (_) => ListView.builder(
// // //         itemCount: _playlist.length,
// // //         itemBuilder: (_, i) {
// // //           final item = _playlist[i];
// // //           return ListTile(
// // //             leading: Icon(item.isNetwork ? Icons.wifi : Icons.folder),
// // //             title: Text(item.path.split('/').last),
// // //             selected: i == _currentIndex,
// // //             onTap: () {
// // //               Navigator.pop(context);
// // //               _playMedia(i);
// // //             },
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // //
// // //   /// ================= NEXT / PREVIOUS =================
// // //   void nextVideo() {
// // //     if (_currentIndex + 1 < _playlist.length) {
// // //       _playMedia(_currentIndex + 1);
// // //     }
// // //   }
// // //
// // //   void previousVideo() {
// // //     if (_currentIndex - 1 >= 0) {
// // //       _playMedia(_currentIndex - 1);
// // //     }
// // //   }
// // //
// // //   /// ================= UI =================
// // //   void _showSnack(String msg) {
// // //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _videoController?.dispose();
// // //     _chewieController?.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("VLC Style Player"),
// // //         actions: [
// // //           IconButton(
// // //             icon: const Icon(Icons.library_music),
// // //             onPressed: _showAllPlaylists,
// // //           ),
// // //
// // //           IconButton(
// // //             icon: const Icon(Icons.playlist_add),
// // //             onPressed: _addCurrentMediaToPlaylist,
// // //           ),
// // //           IconButton(
// // //             icon: const Icon(Icons.playlist_play),
// // //             onPressed: showPlaylist,
// // //           ),
// // //           IconButton(
// // //             icon: const Icon(Icons.wifi),
// // //             onPressed: addNetworkVideoDialog,
// // //           ),
// // //         ],
// // //       ),
// // //       body: Column(
// // //         children: [
// // //           Expanded(
// // //             child: Center(
// // //               child:
// // //               _chewieController != null &&
// // //                   _videoController!.value.isInitialized
// // //                   ? Chewie(key: _playerKey, controller: _chewieController!)
// // //                   : const Text("No media loaded"),
// // //             ),
// // //           ),
// // //           Padding(
// // //             padding: const EdgeInsets.symmetric(vertical: 10),
// // //             child: Row(
// // //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // //               children: [
// // //                 IconButton(
// // //                   icon: const Icon(Icons.skip_previous),
// // //                   onPressed: previousVideo,
// // //                 ),
// // //                 IconButton(
// // //                   icon: const Icon(Icons.folder),
// // //                   onPressed: pickLocalFiles,
// // //                 ),
// // //                 IconButton(
// // //                   icon: const Icon(Icons.skip_next),
// // //                   onPressed: nextVideo,
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // //
// // // class PlaylistItemsScreen extends StatelessWidget {
// // //   final dynamic playlistKey;
// // //   final Map playlistData;
// // //
// // //   const PlaylistItemsScreen({
// // //     super.key,
// // //     required this.playlistKey,
// // //     required this.playlistData,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final items = List<Map>.from(playlistData['items']);
// // //
// // //     return Scaffold(
// // //       appBar: AppBar(title: Text(playlistData['name'])),
// // //       body: ReorderableListView.builder(
// // //         itemCount: items.length,
// // //         onReorder: (oldIndex, newIndex) {
// // //           if (newIndex > oldIndex) newIndex--;
// // //           final item = items.removeAt(oldIndex);
// // //           items.insert(newIndex, item);
// // //
// // //           final box = Hive.box('playlists');
// // //           box.put(playlistKey, {'name': playlistData['name'], 'items': items});
// // //         },
// // //         itemBuilder: (_, index) {
// // //           final item = items[index];
// // //           return ListTile(
// // //             key: ValueKey(item['path']),
// // //             leading: FutureBuilder(
// // //               future: _buildThumbnail(
// // //                 MediaItem(path: item['path'], isNetwork: item['isNetwork']),
// // //               ),
// // //               builder: (_, snapshot) {
// // //                 if (!snapshot.hasData) {
// // //                   return const SizedBox(
// // //                     width: 50,
// // //                     height: 50,
// // //                     child: Center(
// // //                       child: CircularProgressIndicator(strokeWidth: 2),
// // //                     ),
// // //                   );
// // //                 }
// // //                 return SizedBox(width: 60, height: 60, child: snapshot.data);
// // //               },
// // //             ),
// // //
// // //             title: Text(item['path'].split('/').last),
// // //             onTap: () {
// // //               Navigator.pop(context, {
// // //                 'playlistKey': playlistKey,
// // //                 'startIndex': index,
// // //               });
// // //             },
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // //
// // //   Future<Widget> _buildThumbnail(MediaItem item) async {
// // //     if (item.isNetwork) {
// // //       return const Icon(Icons.wifi, size: 40);
// // //     }
// // //
// // //     final ext = item.path.split('.').last.toLowerCase();
// // //     if (['mp3', 'aac', 'wav', 'm4a'].contains(ext)) {
// // //       return const Icon(Icons.music_note, size: 40);
// // //     }
// // //
// // //     final thumb = await VideoThumbnail.thumbnailFile(
// // //       video: item.path,
// // //       thumbnailPath: (await getTemporaryDirectory()).path,
// // //       imageFormat: ImageFormat.JPEG,
// // //       maxHeight: 120,
// // //       quality: 75,
// // //     );
// // //
// // //     return thumb != null
// // //         ? Image.file(File(thumb), fit: BoxFit.cover)
// // //         : const Icon(Icons.video_file);
// // //   }
// // // }
// // //
// // //
// // // class PlaylistListScreen extends StatelessWidget {
// // //   final Box box;
// // //
// // //   const PlaylistListScreen({super.key, required this.box});
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(title: const Text("Playlists")),
// // //       body: box.isEmpty
// // //           ? const Center(child: Text("No playlists created"))
// // //           : ListView.builder(
// // //         itemCount: box.length,
// // //         itemBuilder: (context, index) {
// // //           final key = box.keyAt(index);
// // //           final playlist = box.get(key);
// // //
// // //           return ListTile(
// // //             leading: const Icon(Icons.queue_music),
// // //             title: Text(playlist['name']),
// // //             subtitle:
// // //             Text("${playlist['items'].length} items"),
// // //             onTap: () {
// // //               Navigator.push(
// // //                 context,
// // //                 MaterialPageRoute(
// // //                   builder: (_) => PlaylistItemsScreen(
// // //                     playlistKey: key,
// // //                     playlistData: playlist,
// // //                   ),
// // //                 ),
// // //               );
// // //             },
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // // }
// //
// //
// // import 'dart:io';
// //
// // import 'package:flutter/material.dart';
// // import 'package:chewie/chewie.dart';
// // import 'package:file_picker/file_picker.dart';
// // import 'package:hive/hive.dart';
// // import 'package:hive_flutter/hive_flutter.dart';
// // import 'package:path_provider/path_provider.dart';
// // import 'package:video_player/video_player.dart';
// // import 'package:video_thumbnail/video_thumbnail.dart';
// //
// // void main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   await Hive.initFlutter();
// //   await Hive.openBox('playlists');
// //   runApp(const VideoPlayerApp());
// // }
// //
// // /// ================= MEDIA MODEL =================
// // class MediaItem {
// //   final String path;
// //   final bool isNetwork;
// //
// //   MediaItem({required this.path, required this.isNetwork});
// // }
// //
// // /// ================= APP =================
// // class VideoPlayerApp extends StatelessWidget {
// //   const VideoPlayerApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       theme: ThemeData.dark(useMaterial3: true),
// //       home: const HomeScreen(),
// //     );
// //   }
// // }
// //
// // /// ================= HOME =================
// // class HomeScreen extends StatefulWidget {
// //   const HomeScreen({super.key});
// //
// //   @override
// //   State<HomeScreen> createState() => _HomeScreenState();
// // }
// //
// // class _HomeScreenState extends State<HomeScreen> {
// //   VideoPlayerController? _videoController;
// //   ChewieController? _chewieController;
// //   Key _playerKey = UniqueKey();
// //
// //   final List<MediaItem> _playlist = [];
// //   int _currentIndex = -1;
// //   double _volume = 0.6;
// //
// //   /// ================= PLAY MEDIA =================
// //   Future<void> _playMedia(int index) async {
// //     if (index < 0 || index >= _playlist.length) return;
// //
// //     final media = _playlist[index];
// //
// //     await _videoController?.dispose();
// //     // await _chewieController?.dispose();
// //
// //     try {
// //       _videoController = media.isNetwork
// //           ? VideoPlayerController.networkUrl(Uri.parse(media.path))
// //           : VideoPlayerController.file(File(media.path));
// //
// //       await _videoController!.initialize();
// //       _videoController!.setVolume(_volume);
// //
// //       _chewieController = ChewieController(
// //         videoPlayerController: _videoController!,
// //         autoPlay: true,
// //         allowFullScreen: true,
// //         allowPlaybackSpeedChanging: true,
// //       );
// //
// //       _playerKey = UniqueKey();
// //       _currentIndex = index;
// //       setState(() {});
// //     } catch (e) {
// //       _showSnack("Unable to play media");
// //     }
// //   }
// //
// //   /// ================= PICK FILE =================
// //   Future<void> pickLocalFiles() async {
// //     final result = await FilePicker.platform.pickFiles(
// //       allowMultiple: true,
// //       type: FileType.custom,
// //       allowedExtensions: ['mp4', 'mkv', 'avi', 'mp3', 'aac', 'wav', 'm4a'],
// //     );
// //
// //     if (result == null) return;
// //
// //     final startIndex = _playlist.length;
// //
// //     for (final file in result.files) {
// //       if (file.path != null) {
// //         _playlist.add(MediaItem(path: file.path!, isNetwork: false));
// //       }
// //     }
// //
// //     await _playMedia(startIndex);
// //   }
// //
// //   /// ================= NETWORK =================
// //   Future<void> addNetworkVideoDialog() async {
// //     String url = '';
// //
// //     await showDialog(
// //       context: context,
// //       builder: (_) => AlertDialog(
// //         title: const Text("Add Network Media"),
// //         content: TextField(
// //           onChanged: (v) => url = v,
// //           decoration: const InputDecoration(hintText: "https://..."),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: const Text("Cancel"),
// //           ),
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: const Text("Add"),
// //           ),
// //         ],
// //       ),
// //     );
// //
// //     if (!url.startsWith("http")) {
// //       _showSnack("Invalid URL");
// //       return;
// //     }
// //
// //     _playlist.add(MediaItem(path: url, isNetwork: true));
// //     await _playMedia(_playlist.length - 1);
// //   }
// //
// //   /// ================= ADD TO PLAYLIST =================
// //   Future<void> addToPlaylist() async {
// //     if (_currentIndex < 0) return;
// //
// //     final media = _playlist[_currentIndex];
// //     final box = Hive.box('playlists');
// //     String newName = '';
// //
// //     await showDialog(
// //       context: context,
// //       builder: (_) => AlertDialog(
// //         title: const Text("Add to Playlist"),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             ...box.keys.map((key) {
// //               final playlist = Map<String, dynamic>.from(box.get(key));
// //               return ListTile(
// //                 title: Text(playlist['name']),
// //                 onTap: () {
// //                   final items = List<Map>.from(playlist['items']);
// //                   items.removeWhere((e) => e['path'] == media.path);
// //                   items.add({
// //                     'path': media.path,
// //                     'isNetwork': media.isNetwork,
// //                   });
// //                   box.put(key, {'name': playlist['name'], 'items': items});
// //                   Navigator.pop(context);
// //                   _showSnack("Added to ${playlist['name']}");
// //                 },
// //               );
// //             }),
// //             const Divider(),
// //             TextField(
// //               decoration:
// //               const InputDecoration(hintText: "New playlist name"),
// //               onChanged: (v) => newName = v,
// //             ),
// //           ],
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () {
// //               if (newName.isEmpty) return;
// //               box.add({
// //                 'name': newName,
// //                 'items': [
// //                   {'path': media.path, 'isNetwork': media.isNetwork}
// //                 ],
// //               });
// //               Navigator.pop(context);
// //               _showSnack("Playlist created");
// //             },
// //             child: const Text("Create"),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   /// ================= SHOW PLAYLIST =================
// //   void showPlaylist() {
// //     if (_playlist.isEmpty) {
// //       _showSnack("Playlist empty");
// //       return;
// //     }
// //
// //     showModalBottomSheet(
// //       context: context,
// //       builder: (_) => ListView.builder(
// //         itemCount: _playlist.length,
// //         itemBuilder: (_, i) {
// //           final item = _playlist[i];
// //           return ListTile(
// //             leading: Icon(item.isNetwork ? Icons.wifi : Icons.video_file),
// //             title: Text(item.path.split('/').last),
// //             selected: i == _currentIndex,
// //             onTap: () {
// //               Navigator.pop(context);
// //               _playMedia(i);
// //             },
// //           );
// //         },
// //       ),
// //     );
// //   }
// //
// //   /// ================= NEXT / PREV =================
// //   void next() {
// //     if (_currentIndex + 1 < _playlist.length) {
// //       _playMedia(_currentIndex + 1);
// //     }
// //   }
// //
// //   void prev() {
// //     if (_currentIndex - 1 >= 0) {
// //       _playMedia(_currentIndex - 1);
// //     }
// //   }
// //
// //   void _showSnack(String msg) {
// //     ScaffoldMessenger.of(context)
// //         .showSnackBar(SnackBar(content: Text(msg)));
// //   }
// //
// //   @override
// //   void dispose() {
// //     _videoController?.dispose();
// //     _chewieController?.dispose();
// //     super.dispose();
// //   }
// //
// //   /// ================= UI =================
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("VLC Style Player"),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.library_music),
// //             onPressed: () {
// //               Navigator.push(
// //                 context,
// //                 MaterialPageRoute(
// //                   builder: (_) =>
// //                       PlaylistListScreen(box: Hive.box('playlists')),
// //                 ),
// //               );
// //             },
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.playlist_add),
// //             onPressed: addToPlaylist,
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.playlist_play),
// //             onPressed: showPlaylist,
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.wifi),
// //             onPressed: addNetworkVideoDialog,
// //           ),
// //         ],
// //       ),
// //       body: Column(
// //         children: [
// //           Expanded(
// //             child: Center(
// //               child: (_chewieController != null &&
// //                   _videoController != null &&
// //                   _videoController!.value.isInitialized)
// //                   ? Chewie(
// //                 key: _playerKey,
// //                 controller: _chewieController!,
// //               )
// //                   : const Text("Select media to play"),
// //             ),
// //           ),
// //           Container(
// //             padding: const EdgeInsets.symmetric(vertical: 8),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //               children: [
// //                 IconButton(icon: const Icon(Icons.skip_previous), onPressed: prev),
// //                 IconButton(
// //                     icon: const Icon(Icons.folder_open),
// //                     onPressed: pickLocalFiles),
// //                 IconButton(icon: const Icon(Icons.skip_next), onPressed: next),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // /// ================= PLAYLIST LIST =================
// // class PlaylistListScreen extends StatelessWidget {
// //   final Box box;
// //
// //   const PlaylistListScreen({super.key, required this.box});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text("Playlists")),
// //       body: box.isEmpty
// //           ? const Center(child: Text("No playlists created"))
// //           : ListView.builder(
// //         itemCount: box.length,
// //         itemBuilder: (_, i) {
// //           final key = box.keyAt(i);
// //           final playlist = Map<String, dynamic>.from(box.get(key));
// //           return ListTile(
// //             leading: const Icon(Icons.queue_music),
// //             title: Text(playlist['name']),
// //             subtitle: Text("${playlist['items'].length} items"),
// //             onTap: () {
// //               Navigator.push(
// //                 context,
// //                 MaterialPageRoute(
// //                   builder: (_) => PlaylistItemsScreen(
// //                     playlistKey: key,
// //                     playlistData: playlist,
// //                   ),
// //                 ),
// //               );
// //             },
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
// //
// // /// ================= PLAYLIST ITEMS =================
// // class PlaylistItemsScreen extends StatelessWidget {
// //   final dynamic playlistKey;
// //   final Map playlistData;
// //
// //   const PlaylistItemsScreen({
// //     super.key,
// //     required this.playlistKey,
// //     required this.playlistData,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final items = List<Map>.from(playlistData['items']);
// //
// //     return Scaffold(
// //       appBar: AppBar(title: Text(playlistData['name'])),
// //       body: ReorderableListView.builder(
// //         itemCount: items.length,
// //         onReorder: (oldIndex, newIndex) {
// //           if (newIndex > oldIndex) newIndex--;
// //           final item = items.removeAt(oldIndex);
// //           items.insert(newIndex, item);
// //
// //           Hive.box('playlists')
// //               .put(playlistKey, {'name': playlistData['name'], 'items': items});
// //         },
// //         itemBuilder: (_, index) {
// //           final item = items[index];
// //           return ListTile(
// //             key: ValueKey(item['path']),
// //             leading: FutureBuilder(
// //               future: _thumbnail(item),
// //               builder: (_, snap) =>
// //               snap.hasData ? snap.data! : const Icon(Icons.video_file),
// //             ),
// //             title: Text(item['path'].split('/').last),
// //             onTap: () {
// //               Navigator.pop(context, {
// //                 'playlistKey': playlistKey,
// //                 'startIndex': index,
// //               });
// //             },
// //           );
// //         },
// //       ),
// //     );
// //   }
// //
// //   Future<Widget> _thumbnail(Map item) async {
// //     if (item['isNetwork']) return const Icon(Icons.wifi, size: 40);
// //
// //     final ext = item['path'].split('.').last;
// //     if (['mp3', 'aac', 'wav', 'm4a'].contains(ext)) {
// //       return const Icon(Icons.music_note, size: 40);
// //     }
// //
// //     final thumb = await VideoThumbnail.thumbnailFile(
// //       video: item['path'],
// //       thumbnailPath: (await getTemporaryDirectory()).path,
// //       imageFormat: ImageFormat.JPEG,
// //       maxHeight: 120,
// //     );
// //
// //     return thumb != null
// //         ? Image.file(File(thumb), fit: BoxFit.cover)
// //         : const Icon(Icons.video_file);
// //   }
// // }
// //
// //
// // ////////////////////////////////////////////// part 2 /////////////////////////////////////////////////
// //
// // /*
// // import 'dart:io';
// //
// // import 'package:flutter/material.dart';
// // import 'package:file_picker/file_picker.dart';
// // import 'package:chewie/chewie.dart';
// // import 'package:video_player/video_player.dart';
// //
// // void main() {
// //   runApp(const MyApp());
// // }
// //
// // /// ================= APP =================
// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       theme: ThemeData(
// //         useMaterial3: true,
// //         fontFamily: 'Roboto',
// //       ),
// //       home: const HomeScreen(),
// //     );
// //   }
// // }
// //
// // /// ================= HOME SCREEN =================
// // class HomeScreen extends StatefulWidget {
// //   const HomeScreen({super.key});
// //
// //   @override
// //   State<HomeScreen> createState() => _HomeScreenState();
// // }
// //
// // class _HomeScreenState extends State<HomeScreen> {
// //   final List<File> pickedVideos = [];
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F8FA),
// //
// //       /// BOTTOM NAV
// //       bottomNavigationBar: NavigationBar(
// //         height: 64,
// //         selectedIndex: 0,
// //         destinations: const [
// //           NavigationDestination(
// //             icon: Icon(Icons.home_outlined),
// //             selectedIcon: Icon(Icons.home),
// //             label: "",
// //           ),
// //           NavigationDestination(
// //             icon: Icon(Icons.folder_outlined),
// //             selectedIcon: Icon(Icons.folder),
// //             label: "",
// //           ),
// //           NavigationDestination(
// //             icon: Icon(Icons.search_outlined),
// //             selectedIcon: Icon(Icons.search),
// //             label: "",
// //           ),
// //           NavigationDestination(
// //             icon: Icon(Icons.settings_outlined),
// //             selectedIcon: Icon(Icons.settings),
// //             label: "",
// //           ),
// //         ],
// //       ),
// //
// //       body: SafeArea(
// //         child: Padding(
// //           padding: const EdgeInsets.all(16),
// //           child: ListView(
// //             children: [
// //               /// HEADER
// //               Row(
// //                 children: [
// //                   Container(
// //                     width: 44,
// //                     height: 44,
// //                     decoration: BoxDecoration(
// //                       color: Colors.blue.shade50,
// //                       shape: BoxShape.circle,
// //                     ),
// //                     child: const Icon(Icons.play_arrow,
// //                         color: Colors.blue, size: 26),
// //                   ),
// //                   const SizedBox(width: 12),
// //                   const Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         "Video & Music Player",
// //                         style: TextStyle(
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.w600,
// //                         ),
// //                       ),
// //                       SizedBox(height: 2),
// //                       Text(
// //                         "MEDIA PLAYER",
// //                         style: TextStyle(
// //                           fontSize: 11,
// //                           color: Colors.grey,
// //                           letterSpacing: 1,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   const Spacer(),
// //                   Container(
// //                     width: 40,
// //                     height: 40,
// //                     decoration: BoxDecoration(
// //                       color: Colors.white,
// //                       borderRadius: BorderRadius.circular(12),
// //                       boxShadow: const [
// //                         BoxShadow(
// //                           color: Color(0x11000000),
// //                           blurRadius: 12,
// //                           offset: Offset(0, 6),
// //                         )
// //                       ],
// //                     ),
// //                     child: const Icon(Icons.search),
// //                   ),
// //                 ],
// //               ),
// //
// //               const SizedBox(height: 24),
// //
// //               /// CATEGORY GRID
// //               GridView(
// //                 shrinkWrap: true,
// //                 physics: const NeverScrollableScrollPhysics(),
// //                 gridDelegate:
// //                 const SliverGridDelegateWithFixedCrossAxisCount(
// //                   crossAxisCount: 2,
// //                   mainAxisSpacing: 16,
// //                   crossAxisSpacing: 16,
// //                   childAspectRatio: 1.25,
// //                 ),
// //                 children: [
// //                   _categoryCard(
// //                     icon: Icons.video_library,
// //                     title: "Video",
// //                     count: "Pick files",
// //                     color: Colors.pink,
// //                     onTap: _pickVideos,
// //                   ),
// //                   _categoryCard(
// //                     icon: Icons.headphones,
// //                     title: "Audio",
// //                     count: "Music files",
// //                     color: Colors.blue,
// //                     onTap: () {},
// //                   ),
// //                   _categoryCard(
// //                     icon: Icons.history,
// //                     title: "Recent",
// //                     count: "Recently played",
// //                     color: Colors.orange,
// //                     onTap: () {},
// //                   ),
// //                   _categoryCard(
// //                     icon: Icons.favorite,
// //                     title: "Favorite",
// //                     count: "Saved items",
// //                     color: Colors.red,
// //                     onTap: () {},
// //                   ),
// //                 ],
// //               ),
// //
// //               const SizedBox(height: 28),
// //
// //               /// VIDEO LIST
// //               const Text(
// //                 "Video",
// //                 style: TextStyle(
// //                   fontSize: 16,
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //               const SizedBox(height: 12),
// //
// //               if (pickedVideos.isEmpty)
// //                 const Padding(
// //                   padding: EdgeInsets.only(top: 24),
// //                   child: Center(
// //                     child: Text(
// //                       "No videos selected",
// //                       style: TextStyle(color: Colors.grey),
// //                     ),
// //                   ),
// //                 )
// //               else
// //                 ...pickedVideos.map((file) => _videoTile(file)).toList(),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   /// ================= CATEGORY CARD =================
// //   Widget _categoryCard({
// //     required IconData icon,
// //     required String title,
// //     required String count,
// //     required Color color,
// //     required VoidCallback onTap,
// //   }) {
// //     return InkWell(
// //       onTap: onTap,
// //       borderRadius: BorderRadius.circular(22),
// //       child: Container(
// //         padding: const EdgeInsets.all(18),
// //         decoration: BoxDecoration(
// //           color: Colors.white,
// //           borderRadius: BorderRadius.circular(22),
// //           boxShadow: const [
// //             BoxShadow(
// //               color: Color(0x11000000),
// //               blurRadius: 12,
// //               offset: Offset(0, 6),
// //             )
// //           ],
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Container(
// //               width: 44,
// //               height: 44,
// //               decoration: BoxDecoration(
// //                 color: color.withOpacity(.15),
// //                 shape: BoxShape.circle,
// //               ),
// //               child: Icon(icon, color: color),
// //             ),
// //             const Spacer(),
// //             Text(
// //               title,
// //               style: const TextStyle(
// //                 fontSize: 16,
// //                 fontWeight: FontWeight.w600,
// //               ),
// //             ),
// //             const SizedBox(height: 4),
// //             Text(
// //               count,
// //               style: const TextStyle(color: Colors.grey),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   /// ================= VIDEO TILE =================
// //   Widget _videoTile(File file) {
// //     return InkWell(
// //       onTap: () {
// //         Navigator.push(
// //           context,
// //           MaterialPageRoute(
// //             builder: (_) => PlayerScreen(file: file),
// //           ),
// //         );
// //       },
// //       child: Container(
// //         margin: const EdgeInsets.only(bottom: 14),
// //         padding: const EdgeInsets.all(10),
// //         decoration: BoxDecoration(
// //           color: Colors.white,
// //           borderRadius: BorderRadius.circular(16),
// //           boxShadow: const [
// //             BoxShadow(
// //               color: Color(0x11000000),
// //               blurRadius: 12,
// //               offset: Offset(0, 6),
// //             )
// //           ],
// //         ),
// //         child: Row(
// //           children: [
// //             Container(
// //               width: 60,
// //               height: 60,
// //               decoration: BoxDecoration(
// //                 color: Colors.grey.shade300,
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //               child: const Icon(Icons.video_file),
// //             ),
// //             const SizedBox(width: 12),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     file.path.split('/').last,
// //                     maxLines: 1,
// //                     overflow: TextOverflow.ellipsis,
// //                     style: const TextStyle(fontWeight: FontWeight.w600),
// //                   ),
// //                   const SizedBox(height: 4),
// //                   const Text(
// //                     "Photos, videos, logos",
// //                     style: TextStyle(color: Colors.grey, fontSize: 12),
// //                   ),
// //                   const SizedBox(height: 4),
// //                   const Text(
// //                     "00:01:03   102MB",
// //                     style: TextStyle(fontSize: 12),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             const Icon(Icons.more_vert),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   /// ================= PICK VIDEOS =================
// //   Future<void> _pickVideos() async {
// //     final result = await FilePicker.platform.pickFiles(
// //       allowMultiple: true,
// //       type: FileType.video,
// //     );
// //
// //     if (result == null) return;
// //
// //     setState(() {
// //       pickedVideos
// //           .addAll(result.paths.whereType<String>().map(File.new));
// //     });
// //   }
// // }
// //
// // /// ================= PLAYER SCREEN =================
// // class PlayerScreen extends StatefulWidget {
// //   final File file;
// //
// //   const PlayerScreen({super.key, required this.file});
// //
// //   @override
// //   State<PlayerScreen> createState() => _PlayerScreenState();
// // }
// //
// // class _PlayerScreenState extends State<PlayerScreen> {
// //   VideoPlayerController? controller;
// //   ChewieController? chewie;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _init();
// //   }
// //
// //   Future<void> _init() async {
// //     controller = VideoPlayerController.file(widget.file);
// //     await controller!.initialize();
// //
// //     chewie = ChewieController(
// //       videoPlayerController: controller!,
// //       autoPlay: true,
// //       allowFullScreen: true,
// //     );
// //
// //     setState(() {});
// //   }
// //
// //   @override
// //   void dispose() {
// //     controller?.dispose();
// //     chewie?.dispose();
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text("Player")),
// //       body: Center(
// //         child: chewie == null
// //             ? const CircularProgressIndicator()
// //             : Chewie(controller: chewie!),
// //       ),
// //     );
// //   }
// // }
// //
// //  */