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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        // àªªà«àª²à«‡àª¯àª°àª¨à«€ àª¸àª¾àªˆàª 150x120 àª›à«‡, àª¤à«‹ àª®àª¾àª°à«àªœàª¿àª¨ àª¸àª¾àª¥à«‡ àª¸à«‡àªŸ àª•àª°à«‹
        position = Offset(size.width - 170, size.height - 250);
      });
    });

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

// àªªà«àª²à«‡àª¯àª°àª¨à«€ àª¶àª°à«‚àª†àª¤àª¨à«€ àªªà«‹àªàª¿àª¶àª¨ àª¸à«‡àªŸ àª•àª°à«‹
  // àª¤àª®àª¾àª°àª¾ State àª•à«àª²àª¾àª¸àª®àª¾àª‚ àª¶àª°à«‚àª†àª¤àª¨à«€ àªªà«‹àªàª¿àª¶àª¨ 0,0 àª°àª¾àª–à«‹ àª•àª¾àª°àª£ àª•à«‡ àª¤à«‡ Align àª®àª¾àª‚ àª›à«‡
  Offset position = Offset.zero;


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 360;
    final bool isVideo = player.currentType == "video";

    return AnimatedBuilder(
      animation: player,
      builder: (context, child) {
        if (player.currentIndex == -1) return const SizedBox.shrink();

        // àªœà«‹ àªµà«€àª¡àª¿àª¯à«‹ àª¹à«‹àª¯ àª¤à«‹ àªœ 'position' àª“àª«àª¸à«‡àªŸ àªµàª¾àªªàª°àªµà«‹,
        // àª“àª¡àª¿àª¯à«‹ àª®àª¾àªŸà«‡ bottom: 0 àªªàª° àª«àª¿àª•à«àª¸ àª°àª¾àª–àªµà«‹.
        return Positioned(
          left: isVideo ? position.dx : 0,
          top: isVideo ? position.dy : null, // àª“àª¡àª¿àª¯à«‹ àª®àª¾àªŸà«‡ àªŸà«‹àªª àª¨àª² àª°àª¾àª–àªµà«‹
          bottom: isVideo ? null : 0,        // àª“àª¡àª¿àª¯à«‹ àª®àª¾àªŸà«‡ àª¨à«€àªšà«‡ àªšà«‹àª‚àªŸàª¾àª¡à«€ àª¦à«‡àªµà«‹
          right: isVideo ? null : 0,         // àª“àª¡àª¿àª¯à«‹ àª†àª–à«€ àªµàª¿àª¡à«àª¥ àª²à«‡àª¶à«‡
          child: GestureDetector(
            // àª®àª¾àª¤à«àª° àªµà«€àª¡àª¿àª¯à«‹ àª¹à«‹àª¯ àª¤à«àª¯àª¾àª°à«‡ àªœ àª¡à«àª°à«‡àª— àª•àª°àªµàª¾àª¨à«€ àªªàª°àª®àª¿àª¶àª¨ àª†àªªàªµà«€
            onPanUpdate: isVideo ? _updatePosition : null,
            onPanEnd: isVideo ? (details) => _snapToClosestCorner(size) : null,
            child: Hero(
              tag: 'player_${player.currentEntity?.id}_${player.currentType}',
              child: Material(
                type: MaterialType.transparency,
                child: player.currentType == "video"
                    ? (player.videoController != null
                    ? _buildVideoMiniPlayer(size: size, isSmall: isSmallScreen)
                    : const Center(child: CircularProgressIndicator()))
                    : _buildAudioMiniPlayer(size: size, isSmall: isSmallScreen),
              ),
            ),
          ),
        );
      },
    );
  }


  // @override
  // Widget build(BuildContext context) {
  //   final size = MediaQuery.of(context).size;
  //   final bool isSmallScreen = size.width < 360;
  //
  //   return AnimatedBuilder(
  //     animation: player,
  //     builder: (context, child) {
  //       if (player.currentIndex == -1 ||
  //           player.currentMediaItem == null ||
  //           player.currentEntity == null) {
  //         return const SizedBox.shrink();
  //       }
  //
  //       // âœ… Positioned àª•àª¾àª¢à«€ àª¨àª¾àª–à«‹ àª…àª¨à«‡ Transform.translate àªµàª¾àªªàª°à«‹
  //       return AnimatedContainer(
  //         duration: const Duration(milliseconds: 300), // àª¸à«àª¨à«‡àªªàª¿àª‚àª— àªàª¨àª¿àª®à«‡àª¶àª¨
  //         curve: Curves.easeOutBack,
  //         transform: Matrix4.translationValues(position.dx, position.dy, 0),
  //         child: GestureDetector(
  //           onPanUpdate: (details) {
  //             setState(() {
  //               position += details.delta; // àª¡à«àª°à«‡àª— àª•àª°àªµàª¾àª¥à«€ àª“àª«àª¸à«‡àªŸ àª¬àª¦àª²àª¾àª¶à«‡
  //             });
  //           },
  //           onPanEnd: (details) {
  //             _snapToClosestCorner(size); // àª¡à«àª°à«‡àª— àª›à«‹àª¡àª¤àª¾ àªœ àª–à«‚àª£àª¾ àªªàª° àªœàª¶à«‡
  //           },
  //           child: player.currentType == "video"
  //               ? _buildVideoMiniPlayer(
  //             size: size,
  //             isSmall: isSmallScreen,
  //             key: ValueKey('video_${player.currentEntity!.id}'),
  //           )
  //               : _buildAudioMiniPlayer(
  //             key: ValueKey('audio_${player.currentEntity!.id}'),
  //             size: size,
  //             isSmall: isSmallScreen,
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  void _updatePosition(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    setState(() {
      double newX = position.dx + details.delta.dx;
      double newY = position.dy + details.delta.dy;

      const double pWidth = 150.0;
      const double pHeight = 120.0;

      // àª† àª²à«‹àªœàª¿àª• àªªà«àª²à«‡àª¯àª°àª¨à«‡ àª¨à«€àªšà«‡ àª‰àª¤àª°àª¤àª¾ àª°à«‹àª•à«€ àª¦à«‡àª¶à«‡
      position = Offset(
        newX.clamp(0.0, size.width - pWidth),
        // Top: Safe area (padding.top) àª¥à«€ àª¶àª°à«‚ àª¥àª¶à«‡
        // Bottom: àª¤àª®à«‡ àª•à«€àª§à«àª‚ àªàª® size.height - 250 àªªàª° àª…àªŸàª•à«€ àªœàª¶à«‡
        newY.clamp(padding.top, size.height - 250),
      );
    });
  }

  void _snapToClosestCorner(Size screenSize) {
    final padding = MediaQuery.of(context).padding;
    const double pWidth = 150.0;
    const double pHeight = 120.0;
    const double margin = 16.0;

    // X Position (àª¡àª¾àª¬à«‡ àª•à«‡ àªœàª®àª£à«‡)
    double finalX = (position.dx + pWidth / 2 < screenSize.width / 2)
        ? margin
        : screenSize.width - pWidth - margin;

    // Y Position (àª¤àª®àª¾àª°à«€ àª¶àª°àª¤ àª®à«àªœàª¬)
    double finalY;
    if (position.dy + pHeight / 2 < screenSize.height / 2) {
      finalY = padding.top + margin; // Top safe area
    } else {
      // àª¤àª®à«‡ àª†àªªà«‡àª²à«€ àª«àª¿àª•à«àª¸ àªªà«‹àªàª¿àª¶àª¨: àª›à«‡àª• àª¨à«€àªšà«‡ àª¨àª¹à«€àª‚, àªªàª£ 250 àª¨àª¾ àª…àª‚àª¤àª°à«‡
      finalY = screenSize.height - 250;
    }

    setState(() {
      position = Offset(finalX, finalY);
    });
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
              mainAxisSize: MainAxisSize.min,
              children: [
                AppImage(
                  src: AppSvg.musicUnselected,
                  height: isSmall ? 18 : 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
    final item = player.currentMediaItem;
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

        return  GestureDetector(
          onTap: (){
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
          child: SizedBox(
            key: ValueKey(player.videoController.hashCode),
            width: 150,
            height: 120,
            child: Stack(
              children: [
                ClipRRect(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () =>
                      value.isPlaying ? player.pause() : player.resume(),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () {
                        player.stopAndClose();
                        if (mounted) {
                          setState(() {});
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _wrapper({required Widget child, required bool isAudio, Key? key}) {
    final item = player.currentMediaItem;
    final size = MediaQuery.of(context).size;
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
        width: size.width,
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
