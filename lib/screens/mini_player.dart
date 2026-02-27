import 'dart:ui' as ui;

import '../utils/app_imports.dart';

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
    player.restoreLastSession();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (player.currentIndex == -1) return;

      if (player.currentType == "video" &&
          player.videoController != null &&
          player.videoController!.value.isInitialized) {
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
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 360;

    return SafeArea(
      child: AnimatedBuilder(
        animation: player,
        builder: (context, child) {
          if (player.currentIndex == -1 ||
              player.currentMediaItem == null ||
              player.currentEntity == null) {
            return const SizedBox.shrink();
          }

          if (player.currentType == "video") {
            if (player.videoController == null ||
                !player.videoController!.value.isInitialized) {
              return const SizedBox.shrink();
            }
            return _buildVideoMiniPlayer(
              size: size,
              isSmall: isSmallScreen,
              // ID àª…àª¨à«‡ Favourite àª¸à«àªŸà«‡àªŸ àª¸àª¾àª¥à«‡àª¨à«€ àª•à«€
              key: ValueKey('video_${player.currentEntity!.id}'),
            );
          } else {
            // àª“àª¡àª¿àª¯à«‹ àªªà«àª²à«‡àª¯àª°
            return _buildAudioMiniPlayer(
              key: ValueKey('audio_${player.currentEntity!.id}'),
              size: size,
              isSmall: isSmallScreen,
            );
          }
        },
      ),
    );
  }

  Widget _buildAudioMiniPlayer({
    required Size size,
    required bool isSmall,
    Key? key,
  }) {
    return _wrapper(
      key: key,
      isAudio: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: 12,
            ),
            child: Row(
              children: [
                AppImage(
                  src: AppSvg.musicUnselected,
                  height: isSmall ? 18 : 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _titleText(),
                      AppText("playingFromLocal", fontSize: isSmall ? 10 : 12),
                    ],
                  ),
                ),
                if (player.currentEntity != null)
                  FavouriteButton(
                    key: ValueKey(
                      '${player.currentEntity?.id}_${player.currentEntity?.isFavorite}',
                    ),
                    entity: player.currentEntity!,
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
                      SizedBox(height: size.height * 0.03),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoButton(
                            onPressed: () => player.playPrevious(),
                            child: AppImage(src: AppSvg.skipPrev),
                          ),
                          _playPauseButton(Colors.black),
                          CupertinoButton(
                            onPressed: () => player.playNext(),
                            child: AppImage(src: AppSvg.skipNext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 0),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 20,
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
        final int positionMs = snapshot.data?.inMilliseconds ?? 0;
        final int durationMs = player.audioPlayer.duration?.inMilliseconds ?? 0;

        double progress = 0.0;
        if (durationMs > 0) {
          progress = (positionMs / durationMs).clamp(0.0, 1.0);
        }
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final box = context.findRenderObject() as RenderBox;
            final localOffset = box.globalToLocal(details.globalPosition);
            final double relativeProgress = (localOffset.dx / box.size.width)
                .clamp(0.0, 1.0);

            final int newPosMs = (durationMs * relativeProgress).toInt();
            player.audioPlayer.seek(Duration(milliseconds: newPosMs));
          },
          child: Container(
            width: double.infinity,
            height: 30,
            color: Colors.transparent,
            child: CustomPaint(painter: CurveProgressPainter(progress)),
          ),
        );
      },
    );
  }

  Widget _buildVideoMiniPlayer({
    required Size size,
    required bool isSmall,
    Key? key,
  }) {
    if (player.videoController == null ||
        !player.videoController!.value.isInitialized ||
        player.currentType != "video") {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder(
      valueListenable: player.videoController!,
      builder: (context, VideoPlayerValue value, child) {
        final controller = player.videoController;
        if (controller == null || !controller.value.isInitialized) {
          return const SizedBox.shrink();
        }
        if (value.hasError) return const SizedBox.shrink();

        final int pos = value.position.inMilliseconds;
        final int dur = value.duration.inMilliseconds;

        double progress = 0.0;
        if (dur > 0) {
          progress = (pos / dur).clamp(0.0, 1.0);
        }

        return _wrapper(
          key: key,
          isAudio: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 70,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: value.size.width,
                        height: value.size.height,
                        child: VideoPlayer(
                          player.videoController!,
                          key: ValueKey(player.videoController.hashCode),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        player.currentMediaItem?.path.split('/').last ?? "",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white24,
                          color: Colors.redAccent,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_formatDuration(pos)} / ${_formatDuration(dur)}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.replay_10,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        player.videoController!.seekTo(
                          Duration(milliseconds: pos - 10000),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 35,
                      ),
                      onPressed: () =>
                      value.isPlaying ? player.pause() : player.resume(),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.forward_10,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        player.videoController!.seekTo(
                          Duration(milliseconds: pos + 10000),
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

  Widget _wrapper({required Widget child, required bool isAudio, Key? key}) {
    final item = player.currentMediaItem;
    return GestureDetector(
      key: key,
      onTap: () {
        if (item == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              entity: player.currentEntity!,
              item: item,
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
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            topLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _titleText({Color color = Colors.black}) {
    final path = player.currentMediaItem?.path;
    final String fileName = path != null ? path.split('/').last : "noMedia";
    return AppText(
      fileName,
      maxLines: 2,
      color: color,
      fontWeight: FontWeight.w700,
    );
  }

  Widget _playPauseButton(Color color) {
    return CupertinoButton(
      child: AppImage(
        src: player.isPlaying ? AppSvg.pauseVid : AppSvg.playVid,
        height: 45,
        width: 45,
      ),
      onPressed: () => player.isPlaying ? player.pause() : player.resume(),
    );
  }

  Widget _closeButton(Color color) {
    return IconButton(
      icon: AppImage(src: AppSvg.closeIcon),
      onPressed: () {
        player.stopAndClose();
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  String _formatDuration(int ms) {
    if (ms < 0) ms = 0;

    int totalSeconds = ms ~/ 1000;

    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
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

    Path path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      -size.height,
      size.width,
      size.height,
    );

    canvas.drawPath(path, backgroundPaint);

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
    path.moveTo(0, size.height);
    path.lineTo(0, 48);
    path.quadraticBezierTo(size.width / 2, 0, size.width, 48);
    path.lineTo(size.width, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}