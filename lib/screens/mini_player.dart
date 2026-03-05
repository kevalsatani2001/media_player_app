import 'dart:ui' as ui;

import '../utils/app_imports.dart';

// Offset position = Offset.zero;

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

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final size = MediaQuery.of(context).size;
    //   setState(() {
    //     // Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ¯Ã ÂªÂ°Ã ÂªÂ¨Ã Â«â‚¬ Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ 150x120 Ã Âªâ€ºÃ Â«â€¡, Ã ÂªÂ¤Ã Â«â€¹ Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÂ°Ã Â«ÂÃ ÂªÅ“Ã ÂªÂ¿Ã ÂªÂ¨ Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªÂ¥Ã Â«â€¡ Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÅ¸ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
    //     position = Offset(size.width - 170, size.height - 250);
    //   });
    // });

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

  // SmartMiniPlayer.dart ના build માં આ રીતે બદલો:

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // નોંધ: isVideo ને builder ની અંદર લેવું જોઈએ જેથી તે લેટેસ્ટ સ્ટેટ પકડે

    return AnimatedBuilder(
      animation: player,
      builder: (context, child) {
        if (player.currentIndex == -1) return const SizedBox.shrink();

        final bool isVideo = player.currentType == "video";
        final bool isSmall = size.width < 360;

        // ૧. ValueKey ઉમેરવાથી પ્લેયર જ્યારે ઓડિયો/વિડિયોમાં બદલાય ત્યારે આખું વિજેટ રિફ્રેશ થશે.
        // ૨. Key માં ID પણ ઉમેર્યો છે જેથી નવો ઓડિયો પ્લે થાય તો પણ રિફ્રેશ થાય.
        Widget playerBody = GestureDetector(
          key: ValueKey('${player.currentType}_${player.currentEntity?.id}'),
          onPanUpdate: isVideo ? _updatePosition : null,
          onPanEnd: isVideo ? (details) => _snapToClosestCorner(size) : null,
          child: Hero(
            tag: 'player_hero_tag',
            child: Material(
              type: MaterialType.transparency,
              child: isVideo
                  ? (player.videoController != null && player.videoController!.value.isInitialized
                  ? _buildVideoMiniPlayer(size: size, isSmall: isSmall)
                  : Container(
                  width: 150,
                  height: 100,
                  color: Colors.black,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2))
              ))
                  : _buildAudioMiniPlayer(size: size, isSmall: isSmall),
            ),
          ),
        );

        if (isVideo) {
          return Positioned(
            left: position.dx,
            top: position.dy,
            child: playerBody,
          );
        } else {
          // ઓડિયો વખતે રિફ્રેશનો ઇસ્યુ ટાળવા માટે તેને એક કન્ટેનરમાં લપેટો
          // જે Column માં બરાબર દેખાય
          return Container(
            width: size.width,
            child: playerBody,
          );
        }
      },
    );
  }

  void _updatePosition(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    setState(() {
      double newX = position.dx + details.delta.dx;
      double newY = position.dy + details.delta.dy;

      const double pWidth = 150.0;
      const double pHeight = 120.0;

      position = Offset(
        newX.clamp(0.0, size.width - pWidth),
        newY.clamp(padding.top, size.height - 250),
      );
    });
  }

  void _snapToClosestCorner(Size screenSize) {
    final padding = MediaQuery.of(context).padding;
    const double pWidth = 150.0;
    const double pHeight = 120.0;
    const double margin = 16.0;

    double finalX = (position.dx + pWidth / 2 < screenSize.width / 2)
        ? margin
        : screenSize.width - pWidth - margin;

    double finalY;
    if (position.dy + pHeight / 2 < screenSize.height / 2) {
      finalY = padding.top + margin; // Top safe area
    } else {
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
    final colors = Theme.of(context).extension<AppThemeColors>()!;
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
                  color: colors.blackColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _titleText(color: colors.blackColor),
                      AppText("playingFromLocal", fontSize: isSmall ? 10 : 12),
                    ],
                  ),
                ),
                if (player.currentEntity != null) ...[
                  SizedBox(width: 16),
                  FavouriteButton(
                    key: ValueKey(
                      '${player.currentEntity?.id}_${player.currentEntity?.isFavorite}',
                    ),
                    entity: player.currentEntity!,
                  ),
                ],
                SizedBox(width: 8),
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
                  color: colors.whiteColor,
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.03),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoButton(
                            onPressed: () => player.playPrevious(),
                            child: AppImage(src: AppSvg.skipPrev,color: colors.blackColor,),
                          ),
                          _playPauseButton(Colors.black),
                          CupertinoButton(
                            onPressed: () => player.playNext(),
                            child: AppImage(src: AppSvg.skipNext,color: colors.blackColor,),
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
        final videoKey = ValueKey(player.videoController.hashCode);

        return GestureDetector(
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
            width: 150,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color:
              Colors.black, // àªµà«àª¹àª¾àª‡àªŸ àª¸à«àªªà«‡àª¸ àª¨ àª¦à«‡àª–àª¾àª¯ àªàªŸàª²à«‡ àª¬à«àª²à«‡àª• àª¬à«‡àª•àª—à«àª°àª¾àª‰àª¨à«àª¡
            ),
            clipBehavior: Clip.antiAlias,
            // àª–à«‚àª£àª¾ àª°àª¾àª‰àª¨à«àª¡ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡
            child: Stack(
              children: [
                // 1. àª¡àª¾àª¯àª¨à«‡àª®àª¿àª• àª¬à«àª²àª° àª¬à«‡àª•àª—à«àª°àª¾àª‰àª¨à«àª¡
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Transform.scale(
                      scale: 1.8, // àª¬à«àª²àª° àªµàª§à« àª¸àª¾àª°à«àª‚ àª¦à«‡àª–àª¾àª¯ àª àª®àª¾àªŸà«‡ àª¥à«‹àª¡à«‹ àª®à«‹àªŸà«‹ àª¸à«àª•à«‡àª²
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: value.aspectRatio,
                          child: VideoPlayer(
                            player.videoController!,
                            key: videoKey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. àª¬à«àª²à«‡àª• àª“àªµàª°àª²à«‡ (àª¬à«àª²àª° àª¬à«‡àª•àª—à«àª°àª¾àª‰àª¨à«àª¡àª¨à«‡ àª¥à«‹àª¡à«àª‚ àª¡àª¾àª°à«àª• àª•àª°àªµàª¾ àª®àª¾àªŸà«‡)
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),

                // 3. àª®à«‡àªˆàª¨ àªµà«€àª¡àª¿àª¯à«‹ (àª¸à«‡àª¨à«àªŸàª°àª®àª¾àª‚ àª¸à«‡àªŸ àª¥àª¶à«‡)
                Center(
                  child: AspectRatio(
                    aspectRatio: value.aspectRatio,
                    child: VideoPlayer(player.videoController!, key: videoKey),
                  ),
                ),

                // 4. àª•àª‚àªŸà«àª°à«‹àª²à«àª¸ (Close àª…àª¨à«‡ Play/Pause)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            value.isPlaying
                                ? Icons.pause_circle
                                : Icons.play_circle,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => value.isPlaying
                              ? player.pause()
                              : player.resume(),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            player.stopAndClose();
                            if (mounted) setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _wrapper({required Widget child, required bool isAudio, Key? key}) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
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
          color: isAudio ? colors.smartPlayerBg : Colors.black87,
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