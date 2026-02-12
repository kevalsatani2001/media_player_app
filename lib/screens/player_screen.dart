
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:chewie/chewie.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import '../blocs/favourite/favourite_bloc.dart';
import '../models/media_item.dart';
import '../services/playlist_service.dart';
import 'player_screen.dart';

import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class GlobalPlayer {
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
  int currentIndex = -1;
  bool isShuffle = false;

  void toggleShuffle() {
    isShuffle = !isShuffle;
    if (isShuffle) {
      queue.shuffle();
      currentIndex = 0;
    }
  }

  void setQueue(List<MediaItem> items, int startIndex) {
    queue = items;
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
      videoPlayerController: controller!,
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
                type: player.currentType!, // ✅ REAL TYPE
              ),
            ),
          ),
        );
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

    final playlistService = PlaylistService(
      favouriteChangeBloc: context.read<FavouriteChangeBloc>(),
    );

    await playlistService.toggleFavourite(widget.entity!);

    setState(() {
      isFav = !isFav;
    });

    // Optionally update Hive
    final file = await widget.entity!.file;
    if (file == null) return;

    final key = file.path;
    if (isFav) {
      favBox.put(key, {
        "id": widget.entity!.id,
        "path": file.path,
        "isNetwork": false,
        "type": widget.entity!.type == AssetType.audio ? "audio" : "video",
      });
    } else {
      favBox.delete(key);
    }
  }

  void _addToPlaylist() {
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
                    ...playlistBox.keys.map((key) {
                      final playlist = playlistBox.get(key);
                      return ListTile(
                        leading: const Icon(Icons.queue_music),
                        title: Text(playlist['name']),
                        onTap: () {
                          PlaylistService.addToPlaylist(key, currentItem!);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Added to ${playlist['name']}"),
                            ),
                          );
                        },
                      );
                    }).toList(),

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

                PlaylistService.createPlaylist(newPlaylistName, currentItem!);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Playlist created")),
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
        title: Text(currentItem?.path.split('/').last ?? ''),
        actions: [
          IconButton(
            icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
            onPressed: () => setState(() => isLocked = true),
          ),
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavourite,
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: _addToPlaylist,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fill the background with video or audio
          Positioned.fill(
              child: isAudio ? _buildAudioPlayer() : Stack(
                children: [
                  Chewie(controller: player.chewie!), // <-- Chewie already has a progress bar
                  Positioned(child: _buildVideoPlayer())
                ],
              )




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
    if (player.controller == null || !player.controller!.value.isInitialized) {
      // show a loader or placeholder until controller is ready
      return const Center(child: CircularProgressIndicator());
    }

    final controller = player.controller!;
    final duration = controller.value.duration;
    final position = controller.value.position;
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
            child: Column(
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
                  onChanged: (v) {
                    controller.seekTo(Duration(milliseconds: v.toInt()));
                    setState(() {});
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(_fmt(position)), Text(_fmt(duration))],
                ),
              ],
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
                onPressed: () =>
                    controller.seekTo(position - const Duration(seconds: 10)),
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
                onPressed: () =>
                    controller.seekTo(position + const Duration(seconds: 10)),
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
  }

  Widget _buildVideoPlayer() {
    if (player.chewie == null || !player.controller!.value.isInitialized) {
      // show a loader or placeholder until controller is ready
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final controller = player.controller!;
    final position = controller.value.position;
    final duration = controller.value.duration;

    return Stack(
      children: [
        Chewie(controller: player.chewie!), // Video display
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black45,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Slider
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
                  onChanged: (v) =>
                      controller.seekTo(Duration(milliseconds: v.toInt())),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(_fmt(position)), Text(_fmt(duration))],
                ),
                const SizedBox(height: 8),
                // Controls (same as audio)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: player.isShuffle ? Colors.blue : Colors.white,
                      ),
                      onPressed: () => setState(() => player.toggleShuffle()),
                    ),
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      onPressed: () => controller.seekTo(
                        position - const Duration(seconds: 10),
                      ),
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
                      onPressed: () => controller.seekTo(
                        position + const Duration(seconds: 10),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.repeat,
                        color: player.isLooping ? Colors.blue : Colors.white,
                      ),
                      onPressed: () => setState(() => player.toggleLoop()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}






// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hive/hive.dart';
// import 'package:chewie/chewie.dart';
// import 'package:photo_manager/photo_manager.dart';
// import 'package:video_player/video_player.dart';
// import '../blocs/favourite/favourite_bloc.dart';
// import '../models/media_item.dart';
// import '../services/playlist_service.dart';
// import 'player_screen.dart';
//
// import 'dart:io';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';
//
// class GlobalPlayer {
//   static final GlobalPlayer _instance = GlobalPlayer._internal();
//
//   factory GlobalPlayer() => _instance;
//
//   GlobalPlayer._internal();
//
//   VideoPlayerController? controller;
//   ChewieController? chewie;
//   String? currentPath;
//   bool isNetwork = false;
//
//   Future<void> play(String path, {bool network = false}) async {
//     // If already playing this path, just resume
//     if (currentPath == path && controller != null) {
//       controller!.play();
//       return;
//     }
//
//     // Dispose old controllers
//     // await chewie?.dispose();
//     await controller?.dispose();
//
//     currentPath = path;
//     isNetwork = network;
//
//     controller = isNetwork
//         ? VideoPlayerController.networkUrl(Uri.parse(path))
//         : VideoPlayerController.file(File(path));
//
//     await controller!.initialize();
//
//     chewie = ChewieController(
//       videoPlayerController: controller!,
//       autoPlay: true,
//       allowFullScreen: true,
//     );
//   }
//
//   void pause() => controller?.pause();
//   void resume() => controller?.play();
//   void stop() {
//     controller?.pause();
//     controller?.seekTo(Duration.zero);
//   }
//
//   bool get isPlaying => controller?.value.isPlaying ?? false;
// }
//
//
//
//
// class MiniPlayer extends StatefulWidget {
//   const MiniPlayer({super.key});
//
//   @override
//   State<MiniPlayer> createState() => _MiniPlayerState();
// }
//
// class _MiniPlayerState extends State<MiniPlayer> {
//   final GlobalPlayer player = GlobalPlayer();
//   Timer? _timer;
//   Duration position = Duration.zero;
//
//   @override
//   void initState() {
//     super.initState();
//     // update position every 500ms
//     _timer = Timer.periodic(Duration(milliseconds: 500), (_) {
//       if (player.controller != null && player.controller!.value.isInitialized) {
//         setState(() {
//           position = player.controller!.value.position;
//         });
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (player.currentPath == null || player.controller == null) return SizedBox.shrink();
//
//     final duration = player.controller!.value.duration;
//
//     return GestureDetector(
//       onTap: () {
//         // open full player
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => PlayerScreen(item: MediaItem(path: player.currentPath!, isNetwork: false, type: player.controller!.value.isInitialized?'video':'audio'))),
//         );
//       },
//       child: Container(
//         color: Colors.grey[900],
//         height: 100,
//         padding: EdgeInsets.all(8),
//         child: Row(
//           children: [
//             // 🔹 Small video preview
//             SizedBox(
//               width: 120,
//               height: 70,
//               child: player.controller!.value.isInitialized
//                   ? VideoPlayer(player.controller!)
//                   : Container(color: Colors.black),
//             ),
//
//             SizedBox(width: 8),
//
//             // 🔹 Info and controls
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     player.currentPath!.split('/').last,
//                     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   SizedBox(height: 4),
//                   // 🔹 Progress bar
//                   LinearProgressIndicator(
//                     value: duration.inMilliseconds == 0
//                         ? 0
//                         : position.inMilliseconds / duration.inMilliseconds,
//                     backgroundColor: Colors.white24,
//                     color: Colors.redAccent,
//                   ),
//                   SizedBox(height: 2),
//                   Text(
//                     "${_formatDuration(position)} / ${_formatDuration(duration)}",
//                     style: TextStyle(color: Colors.white70, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//
//             // 🔹 Playback buttons
//             Row(
//               children: [
//                 IconButton(
//                   icon: Icon(Icons.replay_10, color: Colors.white),
//                   onPressed: () {
//                     final newPos = position - Duration(seconds: 10);
//                     player.controller!.seekTo(newPos > Duration.zero ? newPos : Duration.zero);
//                   },
//                 ),
//                 IconButton(
//                   icon: Icon(
//                     player.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
//                     color: Colors.white,
//                     size: 30,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       if (player.isPlaying) {
//                         player.pause();
//                       } else {
//                         player.resume();
//                       }
//                     });
//                   },
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.forward_10, color: Colors.white),
//                   onPressed: () {
//                     final newPos = position + Duration(seconds: 10);
//                     player.controller!.seekTo(newPos < duration ? newPos : duration);
//                   },
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _formatDuration(Duration d) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(d.inMinutes.remainder(60));
//     final seconds = twoDigits(d.inSeconds.remainder(60));
//     return "$minutes:$seconds";
//   }
// }
//
//
//
// class PlayerScreen extends StatefulWidget {
//   final MediaItem item;
//   int? index;
//   AssetEntity? entity;
//
//   PlayerScreen({super.key, required this.item, this.index = -1, this.entity});
//   @override
//   State<PlayerScreen> createState() => _PlayerScreenState();
// }
//
// class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
//   final favBox = Hive.box('favourites');
//   final recentBox = Hive.box('recents');
//
//   bool isFav = false;
//   final GlobalPlayer player = GlobalPlayer();
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//
//     isFav = favBox.containsKey(widget.item.path);
//     recentBox.add(widget.item.toMap());
//
//     player.play(widget.item.path, network: widget.item.isNetwork).then((_) {
//       setState(() {}); // refresh Chewie
//     });
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // Keep audio playing in background
//     if (!_controllerInitialized) return;
//
//     switch (state) {
//       case AppLifecycleState.detached:
//         player.pause();
//         break;
//       default:
//         break;
//     }
//   }
//
//   bool get _controllerInitialized => player.controller != null && player.controller!.value.isInitialized;
//
//   void _toggleFavourite() async {
//     final favBloc = context.read<FavouriteBloc>();
//     // Implement your favourite logic here
//     setState(() {
//       isFav = !isFav;
//     });
//   }
//
//   void _addToPlaylist() {
//     final playlistBox = Hive.box('playlists');
//     String newPlaylistName = '';
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//           title: const Text(
//             'Add to Playlist',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//           ),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   /// 🔹 Existing playlists
//                   if (playlistBox.isNotEmpty)
//                     ...playlistBox.keys.map((key) {
//                       final playlist = playlistBox.get(key);
//                       return ListTile(
//                         dense: true,
//                         title: Text(
//                           playlist['name'],
//                           style: const TextStyle(fontSize: 14),
//                         ),
//                         onTap: () {
//                           PlaylistService.addToPlaylist(key, widget.item);
//                           Navigator.pop(context);
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content:
//                               Text("Added to ${playlist['name']}"),
//                             ),
//                           );
//                         },
//                       );
//                     }),
//
//                   if (playlistBox.isNotEmpty)
//                     const Divider(height: 20),
//
//                   /// 🔹 Create new playlist
//                   TextField(
//                     decoration: const InputDecoration(
//                       labelText: "New Playlist Name",
//                       border: OutlineInputBorder(),
//                       isDense: true,
//                     ),
//                     onChanged: (v) => newPlaylistName = v,
//                   ),
//
//                   const SizedBox(height: 12),
//                 ],
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 if (newPlaylistName.trim().isEmpty) return;
//
//                 PlaylistService.createPlaylist(
//                   newPlaylistName,
//                   widget.item,
//                 );
//
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Playlist created")),
//                 );
//               },
//               child: const Text('Create'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.item.path.split('/').last),
//         actions: [
//           IconButton(
//             icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
//             onPressed: _toggleFavourite,
//           ),
//           IconButton(
//             icon: const Icon(Icons.playlist_add),
//             onPressed: _addToPlaylist,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Center(
//               child: player.chewie == null
//                   ? const CircularProgressIndicator()
//                   : Chewie(controller: player.chewie!),
//             ),
//           ),
//           const MiniPlayer(), // bottom mini-player
//         ],
//       ),
//     );
//   }
// }
//
