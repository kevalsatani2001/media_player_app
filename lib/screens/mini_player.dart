import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
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
                isNetwork: false,
                // isNetwork: player.isNetwork,
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




class SmartMiniPlayer extends StatefulWidget {
  const SmartMiniPlayer({super.key});

  @override
  State<SmartMiniPlayer> createState() => _SmartMiniPlayerState();
}

class _SmartMiniPlayerState extends State<SmartMiniPlayer> {
  final GlobalPlayer player = GlobalPlayer();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // વીડિયો પોઝિશન અપડેટ કરવા માટે ટાઈમર
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (player.currentType == "video" &&
          player.controller != null &&
          player.controller!.value.isInitialized) {
        if (mounted) setState(() {});
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
    // SmartMiniPlayer ના build માં:
    return AnimatedBuilder(
      animation: player,
      builder: (context, child) {
        if (player.currentPath == null) return const SizedBox.shrink();

        // Unique key આપવાથી જૂનું વિજેટ પૂરેપૂરું નાશ પામશે અને નવું બનશે
        return player.currentType == "audio"
            ? _buildAudioMiniPlayer(key: ValueKey(player.currentPath))
            : _buildVideoMiniPlayer(key: ValueKey(player.currentPath));
      },
    );
  }

  // --- ઓડિયો મિની પ્લેયર ---
  Widget _buildAudioMiniPlayer({Key? key}) {
    return _wrapper(
      key: key,
      isAudio: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ૧. પ્રોગ્રેસ સ્લાઇડર (સૌથી ઉપર)
          _audioProgressBar(),

          // ૨. મેઈન કંટ્રોલ્સ રો (Row)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Icon(Icons.music_note, color: Colors.blue, size: 24),
                const SizedBox(width: 8),

                // ગીતનું નામ
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _titleText(),
                      const Text("Playing from Local", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),

                // કંટ્રોલ બટન્સ (Prev, Play/Pause, Next)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 28),
                      onPressed: () => player.playPrevious(),
                    ),
                    _playPauseButton(Colors.black),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 28),
                      onPressed: () => player.playNext(),
                    ),
                  ],
                ),
                _closeButton(Colors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _audioProgressBar() {
    return StreamBuilder<Duration>(
      stream: player.audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player.audioPlayer.duration ?? Duration.zero;

        double progress = 0.0;
        if (duration.inMilliseconds > 0) {
          progress = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
        }

        return Container(
          width: double.infinity,
          height: 20, // કર્વની ઉંચાઈ
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomPaint(
            painter: CurveProgressPainter(progress),
          ),
        );
      },
    );
  }

  // --- વીડિયો મિની પ્લેયર ---
  Widget _buildVideoMiniPlayer({Key? key}) {
    if (player.controller == null || !player.controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return _wrapper(
      key: key,
      child: Row(
        children: [
          // વીડિયો પ્રીવ્યૂ
          Container(
            width: 90,
            height: 55,
            margin: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AspectRatio(
                aspectRatio: player.controller!.value.aspectRatio,
                child: VideoPlayer(player.controller!),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titleText(color: Colors.white),
                const SizedBox(height: 5),
                _progressBar(),
              ],
            ),
          ),
          _playPauseButton(Colors.white),
          _closeButton(Colors.white),
        ],
      ),
      isAudio: false,
    );
  }

  // --- કોમન વિજેટ્સ ---



  Widget _wrapper({required Widget child, required bool isAudio, Key? key}) {
    return GestureDetector(
      key: key,
      onTap: () {
        // અહીં આપણે entityList પાસ કરીએ છીએ
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              item: MediaItem(
                id: player.currentPath!,
                path: player.currentPath!,
                isNetwork: false,
                type: player.currentType!,
              ),
              index: player.currentIndex,
              // જો તમે GlobalPlayer માં entityList સાચવી હોય તો અહીંથી પાસ કરો
              // અથવા જો તમારી પાસે અવેલેબલ ન હોય તો ખાલી લિસ્ટ []
              entityList: const [],
            ),
          ),
        );
      },
      child: Container(
        // ઓડિયો પ્લેયર માટે હાઇટ ૮૦ અથવા ૮૫ કરો
        height: isAudio ? 85 : 100,
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        decoration: BoxDecoration(
          color: isAudio ? Colors.white : Colors.black87,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2)
            )
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _titleText({Color color = Colors.black}) {
    return Text(
      player.currentPath!.split('/').last,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  Widget _playPauseButton(Color color) {
    return StreamBuilder<PlayerState>(
      stream: player.audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing ?? false;

        // જો ઓડિયો લોડ થઈ રહ્યો હોય (Buffering) તો Loading બતાવો
        if (processingState == ProcessingState.buffering ||
            processingState == ProcessingState.loading) {
          return Container(
            margin: const EdgeInsets.all(8),
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color,
            ),
          );
        }

        return IconButton(
          icon: Icon(
            playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: color,
            size: 35,
          ),
          onPressed: () {
            if (playing) {
              player.pause();
            } else {
              player.resume();
            }
          },
        );
      },
    );
  }

  Widget _closeButton(Color color) {
    return IconButton(
      icon: Icon(Icons.close, color: color.withOpacity(0.6), size: 20),
      onPressed: () => player.stop(),
    );
  }

  Widget _progressBar() {
    final pos = player.controller!.value.position;
    final dur = player.controller!.value.duration;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: LinearProgressIndicator(
        value: dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0,
        backgroundColor: Colors.white24,
        color: Colors.blueAccent,
        minHeight: 3,
      ),
    );
  }
}class CurveProgressPainter extends CustomPainter {
  final double progress;
  CurveProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    Paint progressPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // આ એક કર્વ (Arc) દોરશે.
    // -1.2 થી 1.2 સુધીની વેલ્યુથી તે ઉપરની તરફ વળેલો દેખાશે.
    Path path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, -size.height, size.width, size.height);

    canvas.drawPath(path, backgroundPaint);

    // પ્રોગ્રેસ મુજબ લાઈન દોરવા માટે
    ui.PathMetrics pathMetrics = path.computeMetrics();
    for (ui.PathMetric pathMetric in pathMetrics) {
      canvas.drawPath(
        pathMetric.extractPath(0, pathMetric.length * progress),
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}