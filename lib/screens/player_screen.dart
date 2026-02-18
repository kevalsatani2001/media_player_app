import 'dart:async';
import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import '../core/constants.dart';
import '../models/media_item.dart';
import '../models/playlist_model.dart';
import '../services/global_player.dart';
import '../services/playlist_service.dart';
import '../utils/app_colors.dart';
import '../widgets/add_to_playlist.dart';
import '../widgets/app_button.dart';
import '../widgets/customa_shape.dart';
import '../widgets/favourite_button.dart';
import '../widgets/image_widget.dart';

class PlayerScreen extends StatefulWidget {
  final MediaItem item;
  final int? index;
  final AssetEntity? entity;
  final List<AssetEntity>? entityList;

  PlayerScreen({
    super.key,
    required this.item,
    this.index = 0,
    this.entity,
    this.entityList = const [],
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  final favBox = Hive.box('favourites');
  final recentBox = Hive.box('recents');
  final GlobalPlayer player = GlobalPlayer();

  MediaItem? currentItem;
  bool isFav = false;
  bool isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ૧. પહેલા વેલ્યુ અસાઈન કરો
    currentItem = widget.item;
    isFav = Hive.box('favourites').containsKey(widget.item.path);

    // ૨. જો પાથ અલગ હોય તો જ ક્યૂ સેટઅપ કરો
    if (player.currentPath != widget.item.path) {
      _setupQueue();
    }
  }

  Future<void> _setupQueue() async {
    // ૧. જો અત્યારે જે પ્લે થાય છે તે જ આઈટમ હોય, તો પ્લેયરને રિસેટ ન કરો
    if (player.currentPath == widget.item.path && (player.controller?.value.isInitialized ?? false)) {
      return;
    }

    // ૨. પ્લે કોલ કરો
    await player.play(
      widget.item.path,
      type: widget.item.type,
    );

    if (mounted) {
      setState(() {
        currentItem = widget.item;
      });
    }
  }

  Future<List<MediaItem>> convertEntitiesToMediaItems(
      List<AssetEntity> entities,
      ) async {
    List<MediaItem> items = [];
    for (var entity in entities) {
      final file = await entity.file;
      if (file != null) {
        final type = entity.type == AssetType.audio ? 'audio' : 'video';
        items.add(
          MediaItem(
            id: entity.id,
            path: file.path,
            isNetwork: false,
            type: type,
          ),
        );
      }
    }
    return items;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // જો કંટ્રોલર ઇનિશિયલાઇઝ ન હોય તો કશું ના કરો
    if (!_controllerInitialized) return;

    if (state == AppLifecycleState.paused) {
      // જ્યારે એપ બેકગ્રાઉન્ડમાં જાય:
      // માત્ર વીડિયો હોય તો જ પોઝ કરો.
      // ઓડિયો માટે 'just_audio' કે 'video_player' નું 'allowBackgroundPlayback' કામ કરશે.
      if (currentItem?.type == "video") {
        player.pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      // જ્યારે યુઝર એપમાં પાછો આવે:
      // જો વીડિયો હતો, તો યુઝર તેને મેન્યુઅલી પ્લે કરી શકે અથવા ઓટો-રિઝ્યુમ કરી શકાય.
      if (currentItem?.type == "video") {
        // player.resume(); // જો ઓટો-પ્લે જોઈતું હોય તો
      }
    }
  }

  // @override
  // void dispose() {
  //   WidgetsBinding.instance.removeObserver(this);
  //   // જ્યારે સ્ક્રીન બંધ થાય ત્યારે Wakelock બંધ કરવો જરૂરી છે
  //   // WakelockPlus.disable();
  //   super.dispose();
  // }



  bool get _controllerInitialized =>
      player.controller != null && player.controller!.value.isInitialized;
  String getTitle() {
    if (player.currentIndex != -1 && player.queue.isNotEmpty && player.currentIndex >= 0 && player.currentIndex < player.queue.length) {
      return player.queue[player.currentIndex].path.split('/').last;
    }
    // જો ક્યૂ હજુ લોડ ન થઈ હોય, તો widget માંથી આવેલું નામ બતાવો
    return widget.item.path.split('/').last;
  }


  bool get isAudio => currentItem?.type == "audio";

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: player,
        builder: (context,_) {
          return Scaffold(
            appBar: AppBar(
              title: AppText(
                isAudio ? "Music" : currentItem?.path.split('/').last ?? '',
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              leading: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20),
                ),
              ),
              centerTitle: true,
              actions: [
                // IconButton(
                //   icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
                //   onPressed: () => setState(() => isLocked = true),
                // ),
                widget.entity != null && widget.entity!.type == AssetType.video
                    ? FavouriteButton(entity: widget.entity!)
                    : SizedBox(),

                IconButton(
                  icon: const Icon(Icons.playlist_add),
                  onPressed: () {
                    addToPlaylist(currentItem!, context);
                  },
                ),
              ],
            ),

            // AppBar(
            //   title: Text(currentItem?.path.split('/').last ?? ''),
            //   actions: [
            //     IconButton(
            //       icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
            //       onPressed: () => setState(() => isLocked = true),
            //     ),
            //     IconButton(
            //       icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            //       onPressed: _toggleFavourite,
            //     ),
            //     IconButton(
            //       icon: const Icon(Icons.playlist_add),
            //       onPressed: _addToPlaylist,
            //     ),
            //   ],
            // ),
            body: Stack(
              children: [
                // Fill the background with video or audio
                Positioned.fill(
                  child: isAudio
                      ? (player.queue.isEmpty && player.currentPath == null)
                      ? const Center(child: CircularProgressIndicator()) // ડેટા લોડ થાય ત્યાં સુધી
                      : _buildAudioPlayer()
                      : (player.controller != null && player.controller!.value.isInitialized)
                      ? _buildVideoPlayer()
                      : _buildVideoLoadingPlaceholder(),
                ),
                // Add overlay widgets here, e.g., lock button
                if (isLocked)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Icon(Icons.lock, color: Colors.white),
                  ),
              ],
            ),
          );
        }
    );
  }

  Widget _buildAudioPlayer() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    // અહીં ચેક કરો: જો વિડિયો નથી, તો just_audio વાપરો
    // જો ઓડિયો હોય તો CircularProgress કાઢી નાખો
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withOpacity(0.30), colors.primary.withOpacity(0.20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Image/Icon UI (તમારું જે છે તે જ)
          Container(
            width: 220,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 220,
                  decoration: ShapeDecoration(shape: CustomShape(), color: Colors.purple),
                ),
                widget.entity != null
                    ? Positioned(
                  bottom: -10,
                  left: 0,
                  right: 0,
                  child: Center(child: FavouriteButton(entity: widget.entity!)),
                )
                    : SizedBox(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              getTitle()?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Slider (just_audio ના Stream સાથે - આનાથી ચોંટશે નહીં)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: StreamBuilder<Duration>(
              stream: player.audioPlayer.positionStream, // just_audio ની પોઝિશન
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = player.audioPlayer.duration ?? Duration.zero;

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: SliderComponentShape.noThumb,
                        trackHeight: 2,
                        activeTrackColor: colors.primary,
                        inactiveTrackColor: colors.textFieldBorder,
                      ),
                      child: Slider(
                        min: 0,
                        max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                        value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
                        onChanged: (v) {
                          player.audioPlayer.seek(Duration(milliseconds: v.toInt()));
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 4. Controls & Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(_fmt(position), color: colors.primary),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          onPressed: () async {
                            await player.playPrevious();
                            setState(() {
                              currentItem = player.queue[player.currentIndex];
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        // Play/Pause Button
                        StreamBuilder<bool>(
                          stream: player.audioPlayer.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            return IconButton(
                              iconSize: 64,
                              icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                              onPressed: () => isPlaying ? player.pause() : player.resume(),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          onPressed: () async {
                            await player.playNext();
                            // setState(() {
                            //   currentItem = player.queue[player.currentIndex];
                            // });
                          },
                        ),
                        const SizedBox(width: 8),
                        AppText(_fmt(duration), color: colors.primary),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (player.chewie == null || !player.controller!.value.isInitialized) {
      return _buildVideoLoadingPlaceholder();
    }
    final controller = player.controller!;
    final position = controller.value.position;
    final duration = controller.value.duration;

    return Chewie(controller: player.chewie!);
  }

  String _fmt(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  Widget _buildVideoLoadingPlaceholder() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            colors.primary.withOpacity(0.30),
            colors.primary.withOpacity(0.20)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ઓડિયો પ્લેયર જેવો જ લુક આપવા માટે સેન્ટર આઈકોન
          Container(
            width: 220,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 220,
                  decoration: ShapeDecoration(
                    shape: CustomShape(),
                    color: Colors.black26, // વીડિયો માટે થોડો ડાર્ક લુક
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Icon(Icons.videocam, color: Colors.white, size: 40),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // વીડિયોનું નામ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.item.path.split('/').last,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const AppText(
            "Initializing Video Player...",
            fontSize: 14,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }
}


Widget buildMiniPlayer(BuildContext context) {
  final player = GlobalPlayer();

  return StreamBuilder<PlayerState>(
    stream: player.audioPlayer.playerStateStream,
    builder: (context, snapshot) {
      if (player.currentPath == null || player.currentType != "audio") {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: () {
          // ક્લિક કરવા પર પ્લેયર સ્ક્રીન પર જવા માટેનું લોજિક
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerScreen(
                item: player.queue[player.currentIndex], // અત્યારે જે પ્લે થાય છે તે આઈટમ
                entity: player.currentEntity, // અત્યારનો એન્ટિટી ડેટા
                index: player.currentIndex,
                entityList: [], // જો જરૂર હોય તો આખું લિસ્ટ મોકલી શકાય
              ),
            ),
          );
        },
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(
            children: [
              // ગીતની વિગતો અને કંટ્રોલ્સ
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.music_note, color: Colors.blue),
              ),
              Expanded(
                child: Text(
                  player.currentPath!.split('/').last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(player.audioPlayer.playing ? Icons.pause : Icons.play_arrow),
                onPressed: () => player.audioPlayer.playing ? player.pause() : player.resume(),
              ),
            ],
          ),
        ),
      );
    },
  );
}









// import 'dart:async';
// import 'dart:io';
// import 'package:chewie/chewie.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hive/hive.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:media_player/widgets/text_widget.dart';
// import 'package:photo_manager/photo_manager.dart';
// import 'package:video_player/video_player.dart';
// import '../core/constants.dart';
// import '../models/media_item.dart';
// import '../models/playlist_model.dart';
// import '../services/global_player.dart';
// import '../services/playlist_service.dart';
// import '../utils/app_colors.dart';
// import '../widgets/add_to_playlist.dart';
// import '../widgets/app_button.dart';
// import '../widgets/customa_shape.dart';
// import '../widgets/favourite_button.dart';
// import '../widgets/image_widget.dart';
//
// class PlayerScreen extends StatefulWidget {
//   final MediaItem item;
//   final int? index;
//   final AssetEntity? entity;
//   final List<AssetEntity>? entityList;
//
//   PlayerScreen({
//     super.key,
//     required this.item,
//     this.index = 0,
//     this.entity,
//     this.entityList = const [],
//   });
//
//   @override
//   State<PlayerScreen> createState() => _PlayerScreenState();
// }
//
// class _PlayerScreenState extends State<PlayerScreen>
//     with WidgetsBindingObserver {
//   final favBox = Hive.box('favourites');
//   final recentBox = Hive.box('recents');
//   final GlobalPlayer player = GlobalPlayer();
//
//   MediaItem? currentItem;
//   bool isFav = false;
//   bool isLocked = false;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//
//     // ૧. પહેલા વેલ્યુ અસાઈન કરો
//     currentItem = widget.item;
//     isFav = Hive.box('favourites').containsKey(widget.item.path);
//
//     // ૨. જો પાથ અલગ હોય તો જ ક્યૂ સેટઅપ કરો
//     if (player.currentPath != widget.item.path) {
//       _setupQueue();
//     }
//   }
//
//   Future<void> _setupQueue() async {
//     // અહીં currentItem! ને બદલે widget.item વાપરો
//     if (player.currentPath == widget.item.path && player.isPlaying) {
//       print("Song already playing, skipping setup...");
//       return;
//     }
//
//     // લિસ્ટ કન્વર્ટ કરો
//     final mediaItems = await convertEntitiesToMediaItems(
//       widget.entityList ?? [],
//     );
//
//     if (!mounted) return;
//
//     // Add to recents
//     recentBox.addAll(mediaItems.map((e) => e.toMap()).toList());
//
//     // Player માં ક્યૂ સેટ કરો
//     player.setQueue(mediaItems, widget.index ?? 0);
//
//     // પ્લે કરો - અહીં પણ widget.item વાપરવું સેફ છે
//     await player.play(
//       widget.item.path,
//       network: widget.item.isNetwork,
//       type: widget.item.type,
//     );
//
//     // હવે currentItem સેટ કરો અને UI રિફ્રેશ કરો
//     if (mounted) {
//       setState(() {
//         currentItem = widget.item;
//       });
//     }
//   }
//
//   Future<List<MediaItem>> convertEntitiesToMediaItems(
//       List<AssetEntity> entities,
//       ) async {
//     List<MediaItem> items = [];
//     for (var entity in entities) {
//       final file = await entity.file;
//       if (file != null) {
//         final type = entity.type == AssetType.audio ? 'audio' : 'video';
//         items.add(
//           MediaItem(
//             id: entity.id,
//             path: file.path,
//             isNetwork: false,
//             type: type,
//           ),
//         );
//       }
//     }
//     return items;
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     // SystemChrome.setPreferredOrientations(DeviceOrientation.values);
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // જો કંટ્રોલર ઇનિશિયલાઇઝ ન હોય તો કશું ના કરો
//     if (!_controllerInitialized) return;
//
//     if (state == AppLifecycleState.paused) {
//       // જ્યારે એપ બેકગ્રાઉન્ડમાં જાય:
//       // માત્ર વીડિયો હોય તો જ પોઝ કરો.
//       // ઓડિયો માટે 'just_audio' કે 'video_player' નું 'allowBackgroundPlayback' કામ કરશે.
//       if (currentItem?.type == "video") {
//         player.pause();
//       }
//     } else if (state == AppLifecycleState.resumed) {
//       // જ્યારે યુઝર એપમાં પાછો આવે:
//       // જો વીડિયો હતો, તો યુઝર તેને મેન્યુઅલી પ્લે કરી શકે અથવા ઓટો-રિઝ્યુમ કરી શકાય.
//       if (currentItem?.type == "video") {
//         // player.resume(); // જો ઓટો-પ્લે જોઈતું હોય તો
//       }
//     }
//   }
//
//   // @override
//   // void dispose() {
//   //   WidgetsBinding.instance.removeObserver(this);
//   //   // જ્યારે સ્ક્રીન બંધ થાય ત્યારે Wakelock બંધ કરવો જરૂરી છે
//   //   // WakelockPlus.disable();
//   //   super.dispose();
//   // }
//
//
//
//   bool get _controllerInitialized =>
//       player.controller != null && player.controller!.value.isInitialized;
//   String getTitle() {
//     if (player.currentIndex != -1 && player.queue.isNotEmpty && player.currentIndex >= 0 && player.currentIndex < player.queue.length) {
//       return player.queue[player.currentIndex].path.split('/').last;
//     }
//     // જો ક્યૂ હજુ લોડ ન થઈ હોય, તો widget માંથી આવેલું નામ બતાવો
//     return widget.item.path.split('/').last;
//   }
//
//
//   bool get isAudio => currentItem?.type == "audio";
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//         animation: player,
//         builder: (context,_) {
//           return Scaffold(
//             appBar: AppBar(
//               title: AppText(
//                 isAudio ? "Music" : currentItem?.path.split('/').last ?? '',
//                 fontSize: 20,
//                 fontWeight: FontWeight.w500,
//               ),
//               leading: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: GestureDetector(
//                   onTap: () {
//                     Navigator.pop(context);
//                   },
//                   child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20),
//                 ),
//               ),
//               centerTitle: true,
//               actions: [
//                 // IconButton(
//                 //   icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
//                 //   onPressed: () => setState(() => isLocked = true),
//                 // ),
//                 widget.entity != null && widget.entity!.type == AssetType.video
//                     ? FavouriteButton(entity: widget.entity!)
//                     : SizedBox(),
//
//                 IconButton(
//                   icon: const Icon(Icons.playlist_add),
//                   onPressed: () {
//                     addToPlaylist(currentItem!, context);
//                   },
//                 ),
//               ],
//             ),
//
//             // AppBar(
//             //   title: Text(currentItem?.path.split('/').last ?? ''),
//             //   actions: [
//             //     IconButton(
//             //       icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
//             //       onPressed: () => setState(() => isLocked = true),
//             //     ),
//             //     IconButton(
//             //       icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
//             //       onPressed: _toggleFavourite,
//             //     ),
//             //     IconButton(
//             //       icon: const Icon(Icons.playlist_add),
//             //       onPressed: _addToPlaylist,
//             //     ),
//             //   ],
//             // ),
//             body: Stack(
//               children: [
//                 // Fill the background with video or audio
//                 Positioned.fill(
//                   child: isAudio
//                       ? (player.queue.isEmpty && player.currentPath == null)
//                       ? const Center(child: CircularProgressIndicator()) // ડેટા લોડ થાય ત્યાં સુધી
//                       : _buildAudioPlayer()
//                       : (player.controller != null && player.controller!.value.isInitialized)
//                       ? _buildVideoPlayer()
//                       : _buildVideoLoadingPlaceholder(),
//                 ),
//                 // Add overlay widgets here, e.g., lock button
//                 if (isLocked)
//                   Positioned(
//                     top: 16,
//                     right: 16,
//                     child: Icon(Icons.lock, color: Colors.white),
//                   ),
//               ],
//             ),
//           );
//         }
//     );
//   }
//
//   Widget _buildAudioPlayer() {
//     final colors = Theme.of(context).extension<AppThemeColors>()!;
//
//     // અહીં ચેક કરો: જો વિડિયો નથી, તો just_audio વાપરો
//     // જો ઓડિયો હોય તો CircularProgress કાઢી નાખો
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [colors.primary, colors.primary.withOpacity(0.30), colors.primary.withOpacity(0.20)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // 1. Image/Icon UI (તમારું જે છે તે જ)
//           Container(
//             width: 220,
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 Container(
//                   height: 220,
//                   decoration: ShapeDecoration(shape: CustomShape(), color: Colors.purple),
//                 ),
//                 widget.entity != null
//                     ? Positioned(
//                   bottom: -10,
//                   left: 0,
//                   right: 0,
//                   child: Center(child: FavouriteButton(entity: widget.entity!)),
//                 )
//                     : SizedBox(),
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),
//
//           // 2. Title
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Text(
//               getTitle()?? '',
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
//             ),
//           ),
//           const SizedBox(height: 20),
//
//           // 3. Slider (just_audio ના Stream સાથે - આનાથી ચોંટશે નહીં)
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: StreamBuilder<Duration>(
//               stream: player.audioPlayer.positionStream, // just_audio ની પોઝિશન
//               builder: (context, snapshot) {
//                 final position = snapshot.data ?? Duration.zero;
//                 final duration = player.audioPlayer.duration ?? Duration.zero;
//
//                 return Column(
//                   children: [
//                     SliderTheme(
//                       data: SliderTheme.of(context).copyWith(
//                         thumbShape: SliderComponentShape.noThumb,
//                         trackHeight: 2,
//                         activeTrackColor: colors.primary,
//                         inactiveTrackColor: colors.textFieldBorder,
//                       ),
//                       child: Slider(
//                         min: 0,
//                         max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
//                         value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
//                         onChanged: (v) {
//                           player.audioPlayer.seek(Duration(milliseconds: v.toInt()));
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     // 4. Controls & Time
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         AppText(_fmt(position), color: colors.primary),
//                         const SizedBox(width: 8),
//                         IconButton(
//                           icon: const Icon(Icons.skip_previous),
//                           onPressed: () async {
//                             await player.playPrevious();
//                             setState(() {
//                               currentItem = player.queue[player.currentIndex];
//                             });
//                           },
//                         ),
//                         const SizedBox(width: 8),
//                         // Play/Pause Button
//                         StreamBuilder<bool>(
//                           stream: player.audioPlayer.playingStream,
//                           builder: (context, snapshot) {
//                             final isPlaying = snapshot.data ?? false;
//                             return IconButton(
//                               iconSize: 64,
//                               icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
//                               onPressed: () => isPlaying ? player.pause() : player.resume(),
//                             );
//                           },
//                         ),
//                         const SizedBox(width: 8),
//                         IconButton(
//                           icon: const Icon(Icons.skip_next),
//                           onPressed: () async {
//                             await player.playNext();
//                             setState(() {
//                               currentItem = player.queue[player.currentIndex];
//                             });
//                           },
//                         ),
//                         const SizedBox(width: 8),
//                         AppText(_fmt(duration), color: colors.primary),
//                       ],
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildVideoPlayer() {
//     if (player.controller == null) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     final controller = player.controller!;
//     final position = controller.value.position;
//     final duration = controller.value.duration;
//
//     return ValueListenableBuilder(
//       valueListenable: player.controller!,
//       builder: (context, VideoPlayerValue value, child) {
//         if (!value.isInitialized || player.chewie == null) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         return Stack(
//           children: [
//             Chewie(controller: player.chewie!),
//           ],
//         );
//       },
//     );
//   }
//
//   String _fmt(Duration d) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
//   }
//
//   Widget _buildVideoLoadingPlaceholder() {
//     final colors = Theme.of(context).extension<AppThemeColors>()!;
//
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             colors.primary,
//             colors.primary.withOpacity(0.30),
//             colors.primary.withOpacity(0.20)
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // ઓડિયો પ્લેયર જેવો જ લુક આપવા માટે સેન્ટર આઈકોન
//           Container(
//             width: 220,
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 Container(
//                   height: 220,
//                   decoration: ShapeDecoration(
//                     shape: CustomShape(),
//                     color: Colors.black26, // વીડિયો માટે થોડો ડાર્ક લુક
//                   ),
//                   child: const Center(
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   ),
//                 ),
//                 const Positioned(
//                   bottom: 20,
//                   left: 0,
//                   right: 0,
//                   child: Center(
//                     child: Icon(Icons.videocam, color: Colors.white, size: 40),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 40),
//
//           // વીડિયોનું નામ
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Text(
//               widget.item.path.split('/').last,
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           const AppText(
//             "Initializing Video Player...",
//             fontSize: 14,
//             color: Colors.black54,
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//
// Widget buildMiniPlayer(BuildContext context) {
//   final player = GlobalPlayer();
//
//   return StreamBuilder<PlayerState>(
//     stream: player.audioPlayer.playerStateStream,
//     builder: (context, snapshot) {
//       if (player.currentPath == null || player.currentType != "audio") {
//         return const SizedBox.shrink();
//       }
//
//       return GestureDetector(
//         onTap: () {
//           // ક્લિક કરવા પર પ્લેયર સ્ક્રીન પર જવા માટેનું લોજિક
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PlayerScreen(
//                 item: player.queue[player.currentIndex], // અત્યારે જે પ્લે થાય છે તે આઈટમ
//                 entity: player.currentEntity, // અત્યારનો એન્ટિટી ડેટા
//                 index: player.currentIndex,
//                 entityList: [], // જો જરૂર હોય તો આખું લિસ્ટ મોકલી શકાય
//               ),
//             ),
//           );
//         },
//         child: Container(
//           height: 70,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
//           ),
//           child: Row(
//             children: [
//               // ગીતની વિગતો અને કંટ્રોલ્સ
//               const Padding(
//                 padding: EdgeInsets.all(8.0),
//                 child: Icon(Icons.music_note, color: Colors.blue),
//               ),
//               Expanded(
//                 child: Text(
//                   player.currentPath!.split('/').last,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               IconButton(
//                 icon: Icon(player.audioPlayer.playing ? Icons.pause : Icons.play_arrow),
//                 onPressed: () => player.audioPlayer.playing ? player.pause() : player.resume(),
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }