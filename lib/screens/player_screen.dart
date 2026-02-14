////////////////////////////////////////// new/////

import 'dart:async';
import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import '../core/constants.dart';
import '../models/media_item.dart';
import '../models/playlist_model.dart';
import '../services/playlist_service.dart';
import '../widgets/image_widget.dart';

class GlobalPlayer extends ChangeNotifier {
  MaterialControlsState materialControlsState = MaterialControlsState();
  static final GlobalPlayer _instance = GlobalPlayer._internal();

  factory GlobalPlayer() => _instance;

  GlobalPlayer._internal();

  VideoPlayerController? controller;
  ChewieController? chewie;
  String? currentPath;
  bool isNetwork = false;
  String? currentType; // "audio" or "video"
  bool isLooping = false;

  List<MediaItem> queue = [];
  List<MediaItem> originalQueue = [];
  int currentIndex = -1;
  bool isShuffle = false;

  void toggleShuffle() {
    print("call ssss========$isShuffle");
    isShuffle = !isShuffle;
    print("call ssss========$isShuffle");

    final currentItem = queue[currentIndex];

    if (isShuffle) {
      queue.shuffle();
    } else {
      queue = List.from(originalQueue);
    }

    currentIndex = queue.indexOf(currentItem);

    notifyListeners();
  }

  void setQueue(List<MediaItem> items, int startIndex) {
    originalQueue = List.from(items);
    queue = List.from(items);
    currentIndex = startIndex;
  }

  Future<void> playNext() async {
    print("queue length is ===> ${queue.length}");
    print("queue length is ===> ${queue}");
    if (queue.isEmpty) return;
    if (currentIndex + 1 >= queue.length) return;

    currentIndex++;
    final item = queue[currentIndex];
    await play(item.path, network: item.isNetwork, type: item.type);
  }

  Future<void> playPrevious() async {
    if (queue.isEmpty) return;
    if (currentIndex - 1 < 0) return;

    currentIndex--;
    final item = queue[currentIndex];
    await play(item.path, network: item.isNetwork, type: item.type);
  }

  void toggleLoop() {
    isLooping = !isLooping;
    controller?.setLooping(isLooping);
  }

  Future<void> play(
      String path, {
        bool network = false,
        required String type,
      }) async {
    if (currentPath == path && controller != null) {
      controller!.play();
      return;
    }

    await controller?.dispose();

    currentPath = path;
    isNetwork = network;
    currentType = type;

    controller = isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(path))
        : VideoPlayerController.file(File(path));

    await controller!.initialize();

    // 🔥 ADD LISTENER HERE
    controller!.addListener(() {
      final value = controller!.value;
      if (value.isInitialized &&
          value.position >= value.duration &&
          !isLooping) {
        playNext();
      }
    });

    chewie = type == "video"
        ? ChewieController(
      additionalOptions: (context) {
        return [
          OptionItem(
            onTap: (context) {
              toggleShuffle();
            },
            iconData: Icons.shuffle,
            title: "Shuffle",
          ),
          OptionItem(
            onTap: (context) async {
              final newPos =
                  (controller!.value.position) - Duration(seconds: 10);
              controller!.seekTo(
                newPos > Duration.zero ? newPos : Duration.zero,
              );
            },
            iconData: Icons.replay_10,
            title: "kk",
          ),
        ];
      },
      materialProgressColors: ChewieProgressColors(
        playedColor: Color(0XFF3D57F9),
        backgroundColor: Color(0XFFF6F6F6),
      ),

      looping: true,
      onSufflePressed: () {
        toggleShuffle();
      },
      videoPlayerController: controller!,
      // onPressedLooping: (){},
      autoPlay: true,
      allowFullScreen: true,
    )
        : null;
  }

  void pause() => controller?.pause();

  void resume() => controller?.play();

  void stop() {
    controller?.pause();
    controller?.seekTo(Duration.zero);
  }

  bool get isPlaying => controller?.value.isPlaying ?? false;
}

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final GlobalPlayer player = GlobalPlayer();
  Timer? _timer;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    // update position every 500ms
    _timer = Timer.periodic(Duration(milliseconds: 500), (_) {
      if (player.controller != null && player.controller!.value.isInitialized) {
        setState(() {
          position = player.controller!.value.position;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (player.currentPath == null || player.controller == null)
      return SizedBox.shrink();

    final duration = player.controller!.value.duration;

    return GestureDetector(
      onTap: () {
        // open full player

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              item: MediaItem(
                path: player.currentPath!,
                isNetwork: player.isNetwork,
                type: player.currentType!,
              ),
            ),
          ),
        );


        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => PlayerScreen(
        //       item: MediaItem(
        //         path: player.currentPath!,
        //         isNetwork: player.isNetwork,
        //         type: player.currentType!, // ✅ REAL TYPE
        //       ),
        //     ),
        //   ),
        // );
      },
      child: Container(
        color: Colors.grey[900],
        height: 100,
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            // 🔹 Small video preview
            SizedBox(
              width: 120,
              height: 70,
              child: player.currentType == "audio"
                  ? const Icon(Icons.music_note, color: Colors.white, size: 40)
                  : VideoPlayer(player.controller!),
            ),

            SizedBox(width: 8),

            // 🔹 Info and controls
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    player.currentPath!.split('/').last,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  // 🔹 Progress bar
                  LinearProgressIndicator(
                    value: duration.inMilliseconds == 0
                        ? 0
                        : position.inMilliseconds / duration.inMilliseconds,
                    backgroundColor: Colors.white24,
                    color: Colors.redAccent,
                  ),
                  SizedBox(height: 2),
                  Text(
                    "${_formatDuration(position)} / ${_formatDuration(duration)}",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            // 🔹 Playback buttons
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.replay_10, color: Colors.white),
                  onPressed: () {
                    final newPos = position - Duration(seconds: 10);
                    player.controller!.seekTo(
                      newPos > Duration.zero ? newPos : Duration.zero,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    player.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() {
                      if (player.isPlaying) {
                        player.pause();
                      } else {
                        player.resume();
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.forward_10, color: Colors.white),
                  onPressed: () {
                    final newPos = position + Duration(seconds: 10);
                    player.controller!.seekTo(
                      newPos < duration ? newPos : duration,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

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

  void _addToPlaylist(MediaItem currentItem) {
    final playlistBox = Hive.box('playlists');
    String newPlaylistName = '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Add to Playlist",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Existing playlists
                  if (playlistBox.isNotEmpty)
                    ...List.generate(playlistBox.length, (index) {
                      final playlist = playlistBox.getAt(index)!;
                      return ListTile(
                        leading: const Icon(Icons.queue_music),
                        title: Text(playlist.name),
                        onTap: () {
                          // Add currentItem to the existing playlist
                          if (!playlist.items.any((e) => e.path == currentItem.path)) {
                            playlist.items.add(currentItem);
                            playlistBox.putAt(index, playlist); // ✅ put updated PlaylistModel
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Added to ${playlist.name}"),
                            ),
                          );
                        },
                      );
                    }),

                  if (playlistBox.isNotEmpty) const Divider(),

                  // Create new playlist
                  TextField(
                    decoration: InputDecoration(
                      labelText: "New Playlist Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) => newPlaylistName = v,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPlaylistName.trim().isEmpty) return;

                final newPlaylist = PlaylistModel(
                  name: newPlaylistName.trim(),
                  items: [currentItem],
                );
                playlistBox.add(newPlaylist);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Playlist \"$newPlaylistName\" created")),
                );
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }



  bool get isAudio => currentItem?.type == "audio";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText(currentItem?.path.split('/').last ?? ''),
        leading: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
              onTap: (){
                Navigator.pop(context);
              },
              child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20)),
        ),
        actions: [
          IconButton(
            icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
            onPressed: () => setState(() => isLocked = true),
          ),
          widget.entity!=null?FavouriteButton(entity: widget.entity!,):SizedBox(),


          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: (){
              _addToPlaylist(currentItem!);
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
              Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white24,
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 120,
                  color: Colors.white,
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
                          max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
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
                            controller.seekTo(Duration(milliseconds: v.toInt()));
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
                      final newPos = controller.value.position - Duration(seconds: 10);
                      controller.seekTo(newPos > Duration.zero ? newPos : Duration.zero);
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
                      final newPos = controller.value.position + Duration(seconds: 10);
                      controller.seekTo(
                          newPos < controller.value.duration ? newPos : controller.value.duration
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

class FavouriteButton extends StatefulWidget {
  final AssetEntity entity;

  const FavouriteButton({super.key, required this.entity});

  @override
  State<FavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends State<FavouriteButton> {
  late Box favBox;
  bool favState = false;

  @override
  void initState() {
    super.initState();
    favBox = Hive.box('favourites'); // Make sure Hive is opened
    _initFavState();
  }

  /// Initialize favourite state from Hive
  Future<void> _initFavState() async {
    final file = await widget.entity.file;
    if (file == null) return;

    setState(() {
      favState = favBox.containsKey(file.path);
    });
  }

  /// Toggle favourite using PlaylistService
  Future<void> _toggleFavourite() async {
    final file = await widget.entity.file;
    if (file == null) return;

    final playlistService = PlaylistService();
    final newFavState = await playlistService.toggleFavourite(widget.entity);

    setState(() {
      favState = newFavState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: favBox.listenable(),
      builder: (context, Box box, _) {
        return IconButton(
          icon: Icon(favState ? Icons.favorite : Icons.favorite_border),
          onPressed: _toggleFavourite,
          color: favState ? Colors.red : null,
        );
      },
    );
  }
}