import 'dart:async';
import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<FavouriteChangeBloc>();
    // });
    currentItem = widget.item;
    isFav = favBox.containsKey(currentItem!.path);

    // Convert AssetEntity to MediaItem and set queue
    _setupQueue();
  }

  Future<void> _setupQueue() async {
    final mediaItems = await convertEntitiesToMediaItems(
      widget.entityList ?? [],
    );
    if (!mounted) return;

    // Add to recents
    recentBox.addAll(mediaItems.map((e) => e.toMap()).toList());

    // Set queue in player
    player.setQueue(mediaItems, widget.index ?? 0);

    // Play current item
    player.play(
      currentItem!.path,
      network: currentItem!.isNetwork,
      type: currentItem!.type,
    );

    setState(() {}); // refresh UI
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
    if (!_controllerInitialized) return;

    if (state == AppLifecycleState.detached) {
      player.pause();
    }
  }

  bool get _controllerInitialized =>
      player.controller != null && player.controller!.value.isInitialized;

  void _toggleFavourite() async {
    if (widget.entity == null || currentItem == null) return;

    final playlistService = PlaylistService();

    // Toggle favourite
    final newFavState = await playlistService.toggleFavourite(widget.entity!);

    setState(() {
      isFav = newFavState;
    });

    // Notify the Bloc AFTER toggling
    context.read<FavouriteChangeBloc>().add(FavouriteUpdated(widget.entity!));
  }



  bool get isAudio => currentItem?.type == "audio";

  @override
  Widget build(BuildContext context) {
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
              addToPlaylist(currentItem!,context);
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
                ? _buildAudioPlayer()
                : Stack(
              children: [
                // Chewie(controller: player.chewie!), // <-- Chewie already has a progress bar
                Positioned(child: _buildVideoPlayer()),
              ],
            ),
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

  Widget _buildAudioPlayer() {
    if (player.controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final controller = player.controller!;
    final duration = controller.value.duration;
    final position = controller.value.position;
    return ValueListenableBuilder(
      valueListenable: player.controller!,
      builder: (context, VideoPlayerValue value, child) {
        if (!value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff6dd5fa), Color(0xfffbc2eb)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              // Container(
              //   height: 220,
              //   width: 220,
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(24),
              //     color: Colors.white24,
              //   ),
              //   child: const Icon(
              //     Icons.music_note_rounded,
              //     size: 120,
              //     color: Colors.white,
              //   ),
              // ),
              // Source - https://stackoverflow.com/a/74490292
              // Posted by Md. Yeasin Sheikh, modified by community. See post 'Timeline' for change history
              // Retrieved 2026-02-16, License - CC BY-SA 4.0
              Container(
                width: 220,
                // color: Colors.red,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 220,
                      decoration: ShapeDecoration(
                        shape: CustomShape(),
                        color: Colors.purple,
                      ),
                    ),

                    // Positioned widget to place FavoriteButton near curve top bump
                    widget.entity!=null? Positioned(
                      bottom: -10, // તમારા curve ની ઊંચાઈ અનુસાર adjust કરો
                      left: 0,
                      right: 0,
                      child: Center(
                        child: FavouriteButton(entity: widget.entity!),
                      ),
                    ):SizedBox(),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  currentItem?.path.split('/').last ?? '',
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
              const SizedBox(height: 20),
              // Slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    final duration = value.duration;
                    final position = value.position;

                    return Column(
                      children: [
                        Slider(
                          min: 0,
                          max: duration.inMilliseconds.toDouble().clamp(
                            1,
                            double.infinity,
                          ),
                          value: position.inMilliseconds.toDouble().clamp(
                            0,
                            duration.inMilliseconds.toDouble(),
                          ),
                          onChangeEnd: (v) {
                            final seekToPos = Duration(milliseconds: v.toInt());
                            if (seekToPos < Duration.zero) return;
                            if (seekToPos > duration) return;

                            controller.seekTo(seekToPos);
                            if (!controller.value.isPlaying) controller.play();
                          },
                          onChanged: (v) {
                            controller.seekTo(
                              Duration(milliseconds: v.toInt()),
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(position)),
                            Text(_fmt(duration)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: player.isShuffle ? Colors.blue : Colors.black54,
                    ),
                    onPressed: () => setState(() => player.toggleShuffle()),
                  ),
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    onPressed: () {
                      if (!controller.value.isInitialized) return;
                      final newPos =
                          controller.value.position - Duration(seconds: 10);
                      controller.seekTo(
                        newPos > Duration.zero ? newPos : Duration.zero,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () async {
                      await player.playPrevious();
                      setState(() {
                        currentItem = player.queue[player.currentIndex];
                        isFav = favBox.containsKey(currentItem!.path);
                      });
                    },
                  ),
                  IconButton(
                    iconSize: 64,
                    icon: Icon(
                      player.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                    ),
                    onPressed: () => setState(() {
                      player.isPlaying ? player.pause() : player.resume();
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () async {
                      await player.playNext();
                      setState(() {
                        currentItem = player.queue[player.currentIndex];
                        isFav = favBox.containsKey(currentItem!.path);
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    onPressed: () {
                      if (!controller.value.isInitialized) return;
                      final newPos =
                          controller.value.position + Duration(seconds: 10);
                      controller.seekTo(
                        newPos < controller.value.duration
                            ? newPos
                            : controller.value.duration,
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.repeat,
                      color: player.isLooping ? Colors.blue : Colors.black54,
                    ),
                    onPressed: () => setState(() => player.toggleLoop()),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    if (player.controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final controller = player.controller!;
    final position = controller.value.position;
    final duration = controller.value.duration;

    return ValueListenableBuilder(
      valueListenable: player.controller!,
      builder: (context, VideoPlayerValue value, child) {
        if (!value.isInitialized || player.chewie == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            Chewie(controller: player.chewie!),
            // Video display
            // Positioned(
            //   bottom: 0,
            //   left: 0,
            //   right: 0,
            //   child: Container(
            //     color: Colors.black45,
            //     padding: const EdgeInsets.all(12),
            //     child: Column(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         // Slider
            //         Slider(
            //           min: 0,
            //           max: duration.inMilliseconds.toDouble().clamp(
            //             1,
            //             double.infinity,
            //           ),
            //           value: position.inMilliseconds.toDouble().clamp(
            //             0,
            //             duration.inMilliseconds.toDouble(),
            //           ),
            //           onChanged: (v) =>
            //               controller.seekTo(Duration(milliseconds: v.toInt())),
            //         ),
            //         Row(
            //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //           children: [Text(_fmt(position)), Text(_fmt(duration))],
            //         ),
            //         const SizedBox(height: 8),
            //         // Controls (same as audio)
            //         Row(
            //           mainAxisAlignment: MainAxisAlignment.center,
            //           children: [
            //             IconButton(
            //               icon: Icon(
            //                 Icons.shuffle,
            //                 color: player.isShuffle ? Colors.blue : Colors.white,
            //               ),
            //               onPressed: () => setState(() => player.toggleShuffle()),
            //             ),
            //             IconButton(
            //               icon: const Icon(Icons.replay_10),
            //               onPressed: () => controller.seekTo(
            //                 position - const Duration(seconds: 10),
            //               ),
            //             ),
            //             IconButton(
            //               icon: const Icon(Icons.skip_previous),
            //               onPressed: () async {
            //                 await player.playPrevious();
            //                 setState(() {
            //                   currentItem = player.queue[player.currentIndex];
            //                   isFav = favBox.containsKey(currentItem!.path);
            //                 });
            //               },
            //             ),
            //             IconButton(
            //               iconSize: 64,
            //               icon: Icon(
            //                 player.isPlaying
            //                     ? Icons.pause_circle_filled
            //                     : Icons.play_circle_filled,
            //               ),
            //               onPressed: () => setState(() {
            //                 player.isPlaying ? player.pause() : player.resume();
            //               }),
            //             ),
            //             IconButton(
            //               icon: const Icon(Icons.skip_next),
            //               onPressed: () async {
            //                 await player.playNext();
            //                 setState(() {
            //                   currentItem = player.queue[player.currentIndex];
            //                   isFav = favBox.containsKey(currentItem!.path);
            //                 });
            //               },
            //             ),
            //             IconButton(
            //               icon: const Icon(Icons.forward_10),
            //               onPressed: () => controller.seekTo(
            //                 position + const Duration(seconds: 10),
            //               ),
            //             ),
            //             IconButton(
            //               icon: Icon(
            //                 Icons.repeat,
            //                 color: player.isLooping ? Colors.blue : Colors.white,
            //               ),
            //               onPressed: () => setState(() => player.toggleLoop()),
            //             ),
            //           ],
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        );
      },
    );
  }

  String _fmt(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}




