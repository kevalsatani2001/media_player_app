import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_player/core/constants.dart';
import 'package:media_player/screens/player_screen.dart';
import 'package:media_player/widgets/favourite_button.dart';
import 'package:media_player/widgets/image_widget.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import '../models/media_item.dart';
import '../services/global_player.dart';


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
    final size = MediaQuery
        .of(context)
        .size;
    final bool isSmallScreen = size.width < 360; // નાના ફોન માટે ચેક
    return SafeArea(
      child: AnimatedBuilder(
        animation: player,
        builder: (context, child) {
          if (player.currentPath == null) return const SizedBox.shrink();

          return player.currentType == "audio"
              ? _buildAudioMiniPlayer(size: size,
              isSmall: isSmallScreen,
              key: ValueKey(player.currentPath))
              : _buildVideoMiniPlayer(size: size,
              isSmall: isSmallScreen,
              key: ValueKey(player.currentPath));
        },
      ),
    );
  }

  Widget _buildAudioMiniPlayer(
      {required Size size, required bool isSmall, Key? key}) {
    return _wrapper(
      key: key,
      isAudio: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04, // 4% responsive padding
              vertical: 12,
            ),
            child: Row(
              children: [
                AppImage(
                    src: AppSvg.musicUnselected, height: isSmall ? 18 : 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _titleText(),
                      AppText(
                          "Playing from Local", fontSize: isSmall ? 10 : 12),
                    ],
                  ),
                ),
                // ફેવરિટ બટન
                FavouriteButton(
                  entity: AssetEntity(
                    id: player.currentItemId!,
                    typeInt: player.currentType == "audio" ? 3 : 2,
                    width: 200,
                    height: 200,
                    isFavorite: player.isFavourite!,
                    title: player.currentPath,
                  ),
                ),
                _closeButton(Colors.black),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.topCenter,
            children: [
              ClipPath(
                clipper: NativeClipper(),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.05), // Responsive gap
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.skip_previous,
                                size: isSmall ? 24 : 28),
                            onPressed: () => player.playPrevious(),
                          ),
                          _playPauseButton(Colors.black),
                          IconButton(
                            icon: Icon(Icons.skip_next,
                                size: isSmall ? 24 : 28),
                            onPressed: () => player.playNext(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              // પ્રોગ્રેસ બાર બરાબર કર્વની ઉપર
              Positioned(
                top: 20, // કર્વના સ્ટાર્ટિંગ પોઈન્ટ મુજબ એડજસ્ટ કરેલ
                left: 0,
                right: 0,
                child: _audioProgressBar(),
              ),
            ],
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
          progress = (position.inMilliseconds / duration.inMilliseconds).clamp(
              0.0, 1.0);
        }

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            // યુઝર જ્યારે આંગળી ફેરવે ત્યારે પ્રોગ્રેસ ગણવો
            final box = context.findRenderObject() as RenderBox;
            final localOffset = box.globalToLocal(details.globalPosition);
            final double relativeProgress = (localOffset.dx / box.size.width)
                .clamp(0.0, 1.0);

            final newDuration = duration * relativeProgress;
            player.audioPlayer.seek(newDuration);
          },
          child: Container(
            width: double.infinity,
            height: 30,
            color: Colors.transparent, // ક્લિક પકડવા માટે જરૂરી
            child: CustomPaint(painter: CurveProgressPainter(progress)),
          ),
        );
      },
    );
  }

  // --- વીડિયો મિની પ્લેયર ---
  Widget _buildVideoMiniPlayer(
      {required Size size, required bool isSmall, Key? key}) {
    if (player.controller == null || !player.controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<Duration>(
      stream: player.audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player.audioPlayer.duration ?? Duration.zero;

        double progress = 0.0;
        if (duration.inMilliseconds > 0) {
          progress = (position.inMilliseconds / duration.inMilliseconds).clamp(
              0.0, 1.0);
        }

        return _wrapper(
          key: key,
          isAudio: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
                        borderRadius: BorderRadius.circular(10),
                        // adjust for curve
                        child: LinearProgressIndicator(
                          value: duration.inMilliseconds == 0
                              ? 0
                              : position.inMilliseconds /
                              duration.inMilliseconds,
                          backgroundColor: Colors.white24,
                          color: Colors.redAccent,
                          minHeight: 6, // adjust height
                        ),
                      ),

                      SizedBox(height: 2),
                      Text(
                        "${_formatDuration(position)} / ${_formatDuration(
                            duration)}",
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
      },
    );
  }

  // --- કોમન વિજેટ્સ ---

  Widget _wrapper({required Widget child, required bool isAudio, Key? key}) {
    return GestureDetector(
      key: key,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PlayerScreen(
                  entity: AssetEntity(id: player.currentItemId!,
                      typeInt: player.currentType == "audio" ? 3 : 2,
                      width: 200,
                      height: 200,
                      isFavorite:player.isFavourite!,
                      relativePath: player.currentPath!,
                      title: player.currentPath!.split("/").last),
                  item: MediaItem(
                    isFavourite: player.isFavourite!,
                    id: player.currentItemId!,
                    path: player.currentPath!,
                    isNetwork: false,
                    type: player.currentType!,
                  ),
                  index: player.currentIndex,
                  entityList: const [],
                ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isAudio ? Colors.grey[300] : Colors.black87,
          // ઓડિયો માટે થોડો લાઈટ કલર
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            topLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              // spreadRadius: 2,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _titleText({Color color = Colors.black}) {
    // GlobalPlayer માંથી સીધો પાથ લો
    final path = player.currentPath;

    // જો પાથ ન હોય તો જ No Media બતાવો
    final String fileName = path != null ? path
        .split('/')
        .last : "No Media";

    return AppText(
      fileName,
      maxLines: 2,
      color: color,
      fontWeight: FontWeight.w700,
    );
  }

  Widget _playPauseButton(Color color) {
    // AnimatedBuilder પહેલેથી જ SmartMiniPlayer ના build માં છે,
    // એટલે અહીં player.isPlaying નો ઉપયોગ સીધો કરી શકાશે.

    bool playing = player.isPlaying;

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
        // UI રિફ્રેશ કરવા માટે (જો જરૂર પડે તો)
        setState(() {});
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
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          activeTrackColor: Colors.blueAccent,
          inactiveTrackColor: Colors.white24,
          thumbColor: Colors.blueAccent,
        ),
        child: Slider(
          value: pos.inMilliseconds.toDouble().clamp(
              0, dur.inMilliseconds.toDouble()),
          min: 0,
          max: dur.inMilliseconds.toDouble() > 0
              ? dur.inMilliseconds.toDouble()
              : 1.0,
          onChanged: (value) {
            // જ્યારે યુઝર સ્લાઇડર ફેરવે ત્યારે વીડિયો સીક (Seek) થશે
            player.controller!.seekTo(Duration(milliseconds: value.toInt()));
          },
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

class CurveProgressPainter extends CustomPainter {
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
    path.quadraticBezierTo(
      size.width / 2,
      -size.height,
      size.width,
      size.height,
    );

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

class NativeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    // ૧. શરૂઆત નીચે ડાબી બાજુથી (Bottom Left)
    path.moveTo(0, size.height);

    // ૨. ઉપર ડાબી બાજુ સુધી લાઈન દોરો, પણ થોડી જગ્યા છોડો (દા.ત. 50px)
    path.lineTo(0, 48);

    // ૩. ઉપરની બાજુ કર્વ દોરો
    // size.width / 2 એ સેન્ટર છે અને બીજો 0 એ સૌથી ઉપરનો પોઈન્ટ (Peak) છે
    path.quadraticBezierTo(size.width / 2, 0, size.width, 48);

    // ૪. જમણી બાજુ નીચે સુધી લાઈન
    path.lineTo(size.width, size.height);

    // ૫. પાથ બંધ કરો
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
