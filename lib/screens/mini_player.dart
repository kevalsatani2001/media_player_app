import 'dart:ui' as ui;

import '../utils/app_imports.dart';

// Offset position = Offset.zero;

class SmartMiniPlayer extends StatefulWidget {
  final bool forceMiniMode; // Aa option pass karva mate

  const SmartMiniPlayer({
    super.key,
    this.forceMiniMode = false, // Default false, etle ke bottom bar dekhase
  });

  @override
  State<SmartMiniPlayer> createState() => _SmartMiniPlayerState();
}
class _SmartMiniPlayerState extends State<SmartMiniPlayer> {
  final GlobalPlayer player = GlobalPlayer();
  Timer? _timer;
  bool isAudioMiniMode = false;

  @override
  void initState() {
    super.initState();
    player.restoreLastSession();


    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final size = MediaQuery.of(context).size;
    //   setState(() {
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
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Fakt ek j var initialize karva mate jyare app start thay
    if (!isPositionInitialized) {
      final size = MediaQuery.of(context).size;
      final bool isVideo = player.currentType == "video";


      // // Type mujab width ane height
      // final double pWidth = isVideo ? 150.0 : 210.0;
      // final double pHeight = isVideo ? 100.0 : 70.0;
      // const double margin = 16.0;

      setState(() {
        // Right-Bottom corner starting position (Video/Audio banne mate alag calculate thase)
        if(isVideo){
          position = Offset(255.1, 655.1);
        }
        else{
          position= Offset(185.4, 703.4);
        }
        isPositionInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: player,
      builder: (context, child) {
        if (player.currentIndex == -1) return const SizedBox.shrink();

        final bool isVideo = player.currentType == "video";
        final double pWidth = isVideo ? 150.0 : 210.0;
        const double margin = 16.0;

         // to automatic check kari ne screen ni andar push karo
        if (isPositionInitialized && (position.dx + pWidth > size.width)) {
          Future.delayed(Duration.zero, () {
            if (mounted) {
              setState(() {
                position = Offset(size.width - pWidth - margin, position.dy);
              });
            }
          });
        }

        final bool isFloating = isVideo || widget.forceMiniMode;

        if (isFloating) {
          return Stack(
            children: [
              Positioned(
                left: position.dx,
                top: position.dy,
                child: _buildPlayerBody(size, isFloating),
              ),
            ],
          );
        } else {
          return Align(
            alignment: Alignment.bottomCenter,
            child: _buildPlayerBody(size, isFloating),
          );
        }
      },
    );
  }

  Widget _buildPlayerBody(Size size, bool isFloating) {
    final bool isVideo = player.currentType == "video";

    return GestureDetector(
      onPanUpdate: isFloating ? _updatePosition : null,
      onPanEnd: isFloating ? (details) => _snapToClosestCorner(size) : null,
      child: Hero(
        tag: 'player_hero_${player.currentType}',
        child: Material(
          type: MaterialType.transparency,
          child: isVideo
              ? _buildVideoMiniPlayer(size: size, isSmall: size.width < 360)
              : (widget.forceMiniMode
              ? _buildAudioFloatingPlayer(size: size) // Chotu Floating Audio
              : _buildAudioMiniPlayer(size: size, isSmall: size.width < 360)), // Full Bottom Audio
        ),
      ),
    );
  }

  Widget _buildAudioFloatingPlayer({required Size size}) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return GestureDetector(
      onTap: () {
        if (player.currentMediaItem == null) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(
          entity: player.currentEntity!,
          // item: player.currentMediaItem!,
          index: player.currentIndex,
          entityList: const [],
        )));
      },
      child: Container(
        width: 210,
        height: 70, // Ekdum sleek height
        decoration: BoxDecoration(
          color: colors.secondaryText, // Dark Premium Look (Tame tamara colors mujab badli shako)
          borderRadius: BorderRadius.circular(12), // Capsule Shape
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Subtle Glow Background
            Positioned(
              left: 10,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

            // 2. Main Content Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  // Music Disc (Rotating feel)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFF2A2A2A),
                      child: Icon(Icons.music_note_rounded, color: Colors.blueAccent, size: 24),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Text and Controls
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.currentMediaItem?.path.split('/').last ?? "Unknown",
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _smallIconBtn(Icons.skip_previous_rounded, () => player.playPrevious()),
                            const SizedBox(width: 8),
                            _playPauseFloating(), // Blue Glow Play Button
                            const SizedBox(width: 8),
                            _smallIconBtn(Icons.skip_next_rounded, () => player.playNext()),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Favorite and Close (Compact)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => player.stopAndClose(),
                        child: const Icon(Icons.close_rounded, size: 16, color: Colors.white54),
                      ),
                      const SizedBox(height: 10),
                      if (player.currentEntity != null)
                        SizedBox(
                          height: 16, width: 16,
                          child: FittedBox(child: FavouriteButton(entity: player.currentEntity!)),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            // 3. Futuristic Progress Line (Bottom Edge)
            Positioned(
              bottom: 12,
              right: 50,
              left: 65,
              child: StreamBuilder<Duration>(
                stream: player.audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final pos = snapshot.data?.inMilliseconds ?? 0;
                  final dur = player.audioPlayer.duration?.inMilliseconds ?? 1;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (pos / dur).clamp(0.0, 1.0),
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      minHeight: 1.5,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playPauseFloating() {
    return GestureDetector(
      onTap: () => player.isPlaying ? player.pause() : player.resume(),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          player.isPlaying ? Icons.pause : Icons.play_arrow_rounded,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _smallIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 18, color: Colors.white70),
    );
  }

// Helper for smaller buttons
  Widget _miniControlBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 24, color: Colors.black87),
    );
  }

  Widget _playPauseButtonSmall() {
    // GlobalPlayer mathi state lese
    return CupertinoButton(
      padding: EdgeInsets.zero, // Extra padding kadhi nakva mate
      child: AppImage(
        src: player.isPlaying ? AppSvg.pauseVid : AppSvg.playVid,
        height: 30,
        width: 30,
      ),
      onPressed: () => player.isPlaying ? player.pause() : player.resume(),
    );
  }
  Widget _audioProgressBarSmall() {
    return StreamBuilder<Duration>(
      stream: player.audioPlayer.positionStream,
      builder: (context, snapshot) {
        final pos = snapshot.data?.inMilliseconds ?? 0;
        final dur = player.audioPlayer.duration?.inMilliseconds ?? 1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: LinearProgressIndicator(
            value: (pos / dur).clamp(0.0, 1.0),
            backgroundColor: Colors.blue.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            minHeight: 2,
          ),
        );
      },
    );
  }
  Size _getCurrentPlayerSize() {
    if (player.currentType == "video") {
      return const Size(150.0, 100.0); // Video size
    } else {
      return const Size(210.0, 70.0);  // Audio floating size
    }
  }
  void _updatePosition(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    final bool isVideo = player.currentType == "video";
    final double pWidth = isVideo ? 150.0 : 210.0;
    final double pHeight = isVideo ? 100.0 : 70.0;

    setState(() {
      // Left side 0 thi Right side (width - playerWidth) sudhi
      double newX = (position.dx + details.delta.dx).clamp(0.0, size.width - pWidth);
      // Top side 30 (Status bar) thi Bottom side (height - playerHeight - margin) sudhi
      double newY = (position.dy + details.delta.dy).clamp(30.0, size.height - pHeight - 100);
      position = Offset(newX, newY);
    });
  }
  void _snapToClosestCorner(Size screenSize) {
    final padding = MediaQuery.of(context).padding;
    final playerSize = _getCurrentPlayerSize(); // Ã°Å¸Å¸Â¢ Dynamic Size
    const double margin = 16.0;

    double finalX = (position.dx + playerSize.width / 2 < screenSize.width / 2)
        ? margin
        : screenSize.width - playerSize.width - margin;

    double finalY;
    if (position.dy + playerSize.height / 2 < screenSize.height / 2) {
      finalY = padding.top + margin;
    } else {
      finalY = screenSize.height - playerSize.height - 150;
    }

    setState(() {
      position = Offset(finalX, finalY);
    });
    print("f pos==> $position");
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
                  // item: item,
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
              Colors.black,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Transform.scale(
                      scale: 1.8,
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

                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),

                Center(
                  child: AspectRatio(
                    aspectRatio: value.aspectRatio,
                    child: VideoPlayer(player.videoController!, key: videoKey),
                  ),
                ),

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
              // item: item,
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