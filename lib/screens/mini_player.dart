import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_player/screens/player_screen.dart';
import 'package:video_player/video_player.dart';
import '../models/media_item.dart';
import '../services/global_player.dart';

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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: player.controller!.value.size.width,
                    height: player.controller!.value.size.height,
                    child: VideoPlayer(player.controller!),
                  ),
                ),
              ),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10), // adjust for curve
                    child: LinearProgressIndicator(
                      value: duration.inMilliseconds == 0
                          ? 0
                          : position.inMilliseconds / duration.inMilliseconds,
                      backgroundColor: Colors.white24,
                      color: Colors.redAccent,
                      minHeight: 6, // adjust height
                    ),
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