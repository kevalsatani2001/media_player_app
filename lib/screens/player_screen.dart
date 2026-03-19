import 'dart:ui' as ui;
import '../utils/app_imports.dart';

class PlayerScreen extends StatefulWidget {
  final List<AssetEntity> entityList;
  final AssetEntity entity;
  final int index;
  final int? resumePosition;

  const PlayerScreen({
    super.key,
    required this.entityList,
    required this.entity,
    required this.index,
    this.resumePosition,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  final playerService = GlobalPlayerService();

  // UI States
  bool _showControls = true;
  bool _isLocked = false;
  bool _isFullScreen = false;
  BoxFit _videoFit = BoxFit.contain;
  Timer? _controlsTimer;

  // Zoom/Scale/Gestures States
  double _baseScale = 1.0;
  double _videoScale = 1.0;
  bool _isScaling = false;
  double _brightness = 0.5;

  double? _gestureValue;
  bool _isBrightnessGesture = false;
  Timer? _gestureOverlayTimer;

  bool _showForwardIcon = false;
  bool _showBackwardIcon = false;
  Timer? _seekIconTimer;

  bool _isMirrored = false; // Mirror mode
  bool _isFlipped = false; // Vertical flip
  bool _isDarkMode = true; // Theme mode
  Duration? _pointA; // A-B Repeat Point A
  Duration? _pointB; // A-B Repeat Point B
  final GlobalKey _globalKey = GlobalKey();
  bool _isExtraControlsExpanded = false;

  String?
  _overlayText;
  Timer?
  _overlayTextTimer;
  Duration?
  _seekDuration;
  String _activeGestureType = 'none'; // 'none', 'seek', 'vertical'

  void _checkABRepeat() {
    if (_pointA != null && _pointB != null) {
      final currentPos = playerService.controller!.value.position;
      if (currentPos >= _pointB!) {
        playerService.controller!.seekTo(_pointA!);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final box = Hive.box('last_played');
    String? lastId = box.get('last_id');
    int? lastPos = box.get('last_position');

    int? seekTo;
    if (lastId == widget.entity.id) {
      seekTo = lastPos;
    }

    if (widget.entityList.isNotEmpty) {
      playerService.init(widget.entityList, widget.index, () {
        if (mounted) {
          _checkVideoEnd();
          setState(() {});
        }
      }, seekToMs: seekTo);
    }

    _isFullScreen = true;
    _setOrientation(true);
    _startControlsTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      playerService.saveLastPlayed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    playerService.clearListener();
    playerService.controller?.pause();
    playerService.saveLastPlayed();
    _controlsTimer?.cancel();
    _gestureOverlayTimer?.cancel();
    _seekIconTimer?.cancel();
    _setOrientation(false);
    // playerService.controller?.removeListener(_videoListener);
    super.dispose();
  }

  void _checkVideoEnd() {
    if (!mounted) return;

    final controller = playerService.controller;
    if (controller == null || !controller.value.isInitialized) return;

     final bool isFinished =
        controller.value.position >=
        (controller.value.duration - const Duration(milliseconds: 500));

    if (isFinished && !controller.value.isPlaying && !playerService.isLooping) {
      controller.removeListener(_videoListener);

      playerService.playNext(() {
        if (mounted) setState(() {});
      });
    }
  }

  void _toggleRotation() {
    setState(() {
      if (MediaQuery.of(context).orientation == Orientation.portrait) {
        print("==> if");
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        print("==> else");
         SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    });
  }

  void _setOrientation(bool isFull) {
    if (isFull) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _startControlsTimer() {
    _controlsTimer
        ?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isLocked && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!playerService.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: Center(child: CustomLoader())),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: _buildVideoPlayerWithGestures(),
      ),
    );
  }

  Widget _buildVideoPlayerWithGestures() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_isLocked) {
          setState(() => _showControls = !_showControls);
          return;
        }

        setState(() {
          _showControls = !_showControls;
          if (_showControls) {
            _startControlsTimer();   } else {
            _controlsTimer
                ?.cancel();
          }
        });
      },
      onDoubleTapDown: (details) => _seekRelative(details.globalPosition),
      onScaleStart: (details) {
        _baseScale = _videoScale;
        _isScaling = details.pointerCount >= 2;
        _activeGestureType =
            'none';
        },
      onScaleUpdate: (details) {
        if (_isLocked) return;

         if (details.pointerCount >= 2) {
          _isScaling = true;
          setState(() {
            _videoScale = (_baseScale * details.scale).clamp(1.0, 5.0);
          });
        } else if (!_isScaling) {
           _handleSwipe(details);
        }
      },
      onScaleEnd: (_) {
        _isScaling = false;
        _activeGestureType =
            'none';
        },
      child: Stack(
        alignment: Alignment.center,
        children: [
          /*
          Transform.scale(
            scale: _videoScale,
            child: Center( // Center àª‰àª®à«‡àª°àªµàª¾àª¥à«€ àª°à«‹àªŸà«‡àª¶àª¨ àªµàª–àª¤à«‡ àªµàª¿àª¡àª¿àª¯à«‹ àªµàªšà«àªšà«‡ àª°àª¹à«‡àª¶à«‡
              child: AspectRatio(
                aspectRatio: playerService.controller!.value.aspectRatio,
                child: VideoPlayer(playerService.controller!),
              ),
            ),
          ),
          */
          // Video Surface
          RepaintBoundary(
            key: _globalKey,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateY(_isMirrored ? 3.14159 : 0) // Mirror (Y-axis rotation)
                ..rotateX(_isFlipped ? 3.14159 : 0),
              // Vertical Flip (X-axis rotation)
              child: Transform.scale(
                scale: _videoScale,
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: _videoFit,
                    clipBehavior: Clip.hardEdge,
                    child: Center(
                      child: SizedBox(
                        width: playerService.controller!.value.size.width,
                        height: playerService.controller!.value.size.height,
                        child: VideoPlayer(playerService.controller!),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildSeekIndicator(),
          _buildGestureIndicator(),
          // Custom Overlay for Controls
          AnimatedOpacity(
            opacity: _showControls || _isLocked ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _buildControlsOverlay(),
          ),
          if (_overlayText != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _overlayText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGestureIndicator() {
    if (_gestureValue == null) return const SizedBox.shrink();

    return Align(
      // Brightness (Left Swipe) -> Design Right Side
      // Volume (Right Swipe) -> Design Left Side
      alignment: _isBrightnessGesture
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Icon(
                _isBrightnessGesture
                    ? (_gestureValue! > 0.5
                          ? Icons.brightness_7
                          : Icons.brightness_4)
                    : (_gestureValue! == 0
                          ? Icons.volume_off
                          : Icons.volume_up),
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(height: 15),

              Container(
                width: 6,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,

                  children: [
                    FractionallySizedBox(
                      heightFactor: _gestureValue!.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isBrightnessGesture
                              ? Colors.orangeAccent
                              : Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isBrightnessGesture
                                          ? Colors.orangeAccent
                                          : Colors.redAccent)
                                      .withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              Text(
                "${(_gestureValue! * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSwipe(ScaleUpdateDetails details) async {
    if (_isScaling)
      return;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    double deltaY = details.focalPointDelta.dy;
    double deltaX = details.focalPointDelta.dx;

     if (details.localFocalPoint.dy > height * 0.85) {
      return;
    }
    if (_activeGestureType == 'none') {
      if (deltaX.abs() > deltaY.abs() && deltaX.abs() > 2.0) {
        _activeGestureType = 'seek';
      } else if (deltaY.abs() > deltaX.abs() && deltaY.abs() > 2.0) {
        _activeGestureType = 'vertical';
      }
    }

    _gestureOverlayTimer?.cancel();

     if (_activeGestureType == 'seek') {
      final controller = playerService.controller!;
      if (controller.value.isInitialized) {
        final currentPos = controller.value.position;
        final totalDuration = controller.value.duration;

        Duration seekStep = Duration(milliseconds: (deltaX * 200).toInt());
        Duration newPos = currentPos + seekStep;

        if (newPos < Duration.zero) newPos = Duration.zero;
        if (newPos > totalDuration) newPos = totalDuration;

        controller.seekTo(newPos);

        String sign = deltaX > 0 ? "Â»" : "Â«";
        _showOverlayMessage("$sign ${_formatDuration(newPos)}");
      }
      return;
    }

    if (_activeGestureType == 'vertical') {
      if (details.localFocalPoint.dx < width / 2) {
        // Brightness Logic
        _isBrightnessGesture = true;
        _brightness = (_brightness - deltaY / 200).clamp(0.0, 1.0);
        _gestureValue = _brightness;
        await ScreenBrightness().setScreenBrightness(_brightness);
      } else {
        // Volume Logic
        _isBrightnessGesture = false;
        playerService.volume = (playerService.volume - deltaY / 200).clamp(
          0.0,
          1.0,
        );
        _gestureValue = playerService.volume;
        VolumeController().setVolume(playerService.volume, showSystemUI: false);
      }
      setState(() {});
    }

    _gestureOverlayTimer = Timer(const Duration(milliseconds: 800), () {
      setState(() => _gestureValue = null);
    });
  }

  void _seekRelative(Offset tapPosition) {
    if (_isLocked) return;
    final width = MediaQuery.of(context).size.width;
    final currentPos = playerService.controller!.value.position;

    _seekIconTimer?.cancel();

    bool isForward = tapPosition.dx > width / 2;

    setState(() {
      if (isForward) {
        _showForwardIcon = true;
        _showBackwardIcon = false;
      } else {
        _showBackwardIcon = true;
        _showForwardIcon = false;
      }
    });

    final newPos = isForward
        ? currentPos + const Duration(seconds: 10)
        : currentPos - const Duration(seconds: 10);
    playerService.controller!.seekTo(newPos);

    _seekIconTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showForwardIcon = false;
          _showBackwardIcon = false;
        });
      }
    });
  }

  Widget _buildSeekIndicator() {
    return Stack(
      children: [
        // Backward Indicator (Left Side)
        if (_showBackwardIcon)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: MediaQuery.of(context).size.width / 3,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.2), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fast_rewind_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  Text(
                    "-10s",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Forward Indicator (Right Side)
        if (_showForwardIcon)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width / 3,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.white.withOpacity(0.2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fast_forward_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  Text(
                    "+10s",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: _isLocked ? Colors.transparent : Colors.black.withOpacity(0.4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!_isLocked) ...[
            _buildTopBar(),
            _buildExtraControlsHeader(),
           ],
           const Spacer(),
          const Spacer(),
          const Spacer(),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildExtraControlsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) {
                 },
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx < -1 && !_isExtraControlsExpanded) {
                  setState(() {
                    _isExtraControlsExpanded = true;
                  });
                  _startControlsTimer();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                height: 90,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: Row(
                      children: [
                        if (_isExtraControlsExpanded) ...[
                          _controlItemWithLabel(
                            src: AppSvg.icCamera,
                            label: "Capture",
                            onTap: _captureScreenshot,
                          ),
                          _controlItemWithLabel(
                            src: AppSvg.icABRepeat,
                            label: "A-B Repeat",
                            color: _pointA != null
                                ? Colors.redAccent
                                : Colors.white,
                            onTap: _handleABRepeat,
                          ),
                          _controlItemWithLabel(
                            src: AppSvg.icSwapVert,
                            label: "Flip",
                            color: _isFlipped ? Colors.redAccent : Colors.white,
                            onTap: () =>
                                setState(() => _isFlipped = !_isFlipped),
                          ),
                          _controlItemWithLabel(
                            src: AppSvg.icSwapHor,
                            label: "Mirror",
                            color: _isMirrored
                                ? Colors.redAccent
                                : Colors.white,
                            onTap: () =>
                                setState(() => _isMirrored = !_isMirrored),
                          ),

                          _controlItemWithLabel(
                            src: AppSvg.likeIcon,
                            label: "Trim",
                            onTap: () async {
                               playerService.controller?.pause();
                              File? file = await playerService
                                  .playlist[playerService.currentIndex]
                                  .file;

                               final trimmedPath = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VideoTrimScreen(file: file!),
                                ),
                              );

                              if (trimmedPath != null) {
                                playerService.controller?.pause();
                                _playTrimmedVideo(trimmedPath);
                              }
                            },
                          ),
                        ],

                        _controlItemWithLabel(
                          src: playerService.isShuffle
                              ? AppSvg.icShuffleActive
                              : AppSvg.icShuffle,
                          label: "Shuffle",
                          onTap: () => setState(
                            () => playerService.isShuffle =
                                !playerService.isShuffle,
                          ),
                        ),
                        _controlItemWithLabel(
                          src: playerService.isLooping
                              ? AppSvg.icLoopActive
                              : AppSvg.icLoop,
                          label: "Repeat",
                          onTap: () => setState(() {
                            playerService.isLooping = !playerService.isLooping;
                            playerService.controller!.setLooping(
                              playerService.isLooping,
                            );
                          }),
                        ),
                        _controlItemWithLabel(
                          src: playerService.isMuted
                              ? AppSvg.icVolumeOff
                              : AppSvg.icVolumeOn,
                          label: "Mute",
                          onTap: () => setState(() {
                            playerService.isMuted = !playerService.isMuted;
                            playerService.controller!.setVolume(
                              playerService.isMuted ? 0 : playerService.volume,
                            );
                          }),
                        ),
                        _controlItemWithLabel(
                          src: _isFullScreen
                              ? AppSvg.icZoomOut
                              : AppSvg.icZoomIn,
                          label: "Screen",
                          onTap: () => setState(() {
                            _isFullScreen = !_isFullScreen;
                            _setOrientation(_isFullScreen);
                          }),
                        ),

                        _controlItemWithLabel(
                          src: _isExtraControlsExpanded
                              ? AppSvg.icOff
                              : AppSvg.icOn,
                          label: _isExtraControlsExpanded ? "Less" : "More",
                          onTap: () => setState(
                            () => _isExtraControlsExpanded =
                                !_isExtraControlsExpanded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlItemWithLabel({
    required String src,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        _startControlsTimer();
        },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppImage(src: src, height: 35, width: 35),
            if (_isExtraControlsExpanded) ...[
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      height: isLandscape ? 60 : 100,
      padding: EdgeInsets.only(top: isLandscape ? 0 : 30, left: 10, right: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              playerService.playlist[playerService.currentIndex].title ??
                  "Playing Video",
              style: TextStyle(
                color: Colors.white,
                fontSize: isLandscape ? 16 : 18,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircularButton(
          icon: AppSvg.skipPrev,
          onPressed: () => playerService.playPrevious(() => setState(() {})),
        ),
        const SizedBox(width: 40),
        GestureDetector(
          onTap: () {
            playerService.togglePlay();
            _startControlsTimer();
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: AppImage(
              src: playerService.controller!.value.isPlaying
                  ? AppSvg.pauseVid
                  : AppSvg.playVid,
              height: 45,
              width: 45,
            ),

            // Icon(
            //   playerService.controller!.value.isPlaying
            //       ? Icons.pause_rounded
            //       : Icons.play_arrow_rounded,
            //   size: 60,
            //   color: Colors.white,
            // ),
          ),
        ),
        const SizedBox(width: 40),
        _buildCircularButton(
          icon: AppSvg.skipNext,
          onPressed: () => playerService.playNext(() => setState(() {})),
        ),
      ],
    );
  }

  Widget _buildCircularButton({
    required String icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.40),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: AppImage(src: icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.only(bottom: 0, left: 10, right: 10),
      child: Column(
        children: [
          if (!_isLocked) ...[
             Row(
              children: [
                Text(
                  _formatDuration(playerService.controller!.value.position),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: VideoProgressIndicator(
                      playerService.controller!,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      colors: const VideoProgressColors(
                        playedColor: Colors.red,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ),
                ),
                Text(
                  _formatDuration(playerService.controller!.value.duration),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 0),

            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //
            //   ],
            // ),
          ],

           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  _isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => setState(() {
                  _isLocked = !_isLocked;
                  if (!_isLocked) _startControlsTimer();
                }),
              ),
              if (!_isLocked) ...[
                Row(
                  children: [
                    _buildCircularButton(
                      icon: AppSvg.skipPrev,
                      onPressed: () =>
                          playerService.playPrevious(() => setState(() {})),
                    ),
                    SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        playerService.togglePlay();
                        _startControlsTimer();
                        setState(() {});
                      },
                      child: AppImage(
                        src: playerService.controller!.value.isPlaying
                            ? AppSvg.pauseVid
                            : AppSvg.playVid,
                        height: 45,
                        width: 45,
                      ),
                    ),
                    SizedBox(width: 20),
                    _buildCircularButton(
                      icon: AppSvg.skipNext,
                      onPressed: () =>
                          playerService.playNext(() => setState(() {})),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    _getFitIcon(_videoFit),
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_videoFit == BoxFit.contain) {
                        _videoFit = BoxFit.cover;
                      } else if (_videoFit == BoxFit.cover) {
                        _videoFit = BoxFit.fill;
                      } else if (_videoFit == BoxFit.fill) {
                        _videoFit = BoxFit.none;
                      } else {
                        _videoFit = BoxFit.contain;
                      }

                       _overlayText = _getFitText(_videoFit);
                    });

                     _overlayTextTimer?.cancel();
                    _overlayTextTimer = Timer(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _overlayText = null);
                    });
                  },
                ),
              ],
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }


  String _getFitText(BoxFit fit) {
    switch (fit) {
      case BoxFit.contain:
        return "Fit";
      case BoxFit.cover:
        return "Crop";
      case BoxFit.fill:
        return "Stretch";
      case BoxFit.none:
        return "100%";
      default:
        return "Fit";
    }
  }

  IconData _getFitIcon(BoxFit fit) {
    switch (fit) {
      case BoxFit.contain:
        return Icons.fit_screen_outlined;
      case BoxFit.cover:
        return Icons.crop_free_rounded;
      case BoxFit.fill:
        return Icons.open_in_full_rounded;
      case BoxFit.none:
        return Icons.fullscreen_exit_rounded;
      default:
        return Icons.fit_screen;
    }
  }

    Widget _controlIconButton({
    String? src,
    IconData? icon,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: src != null
          ? AppImage(src: src, height: 35, width: 35)
          : Icon(icon, color: color, size: 22),
    );
  }

  Future<void> _captureScreenshot() async {
    try {
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      File imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      await Gal.putImage(imagePath);

      AppToast.show(
        context,
        "Screenshot saved to Gallery!",
        type: ToastType.success,
      );
    } catch (e) {
      print("Screenshot Error: $e");
      AppToast.show(context, "Error saving screenshot", type: ToastType.error);
    }
  }

  void _handleABRepeat() {
    final currentPos = playerService.controller!.value.position;
    if (_pointA == null) {
      _pointA = currentPos;
      AppToast.show(context, "Point A Set");
    } else if (_pointB == null) {
      _pointB = currentPos;
      AppToast.show(context, "Point B Set. Repeating A-B");
      playerService.controller!.addListener(_checkABRepeat);
    } else {
      _pointA = null;
      _pointB = null;
      playerService.controller!.removeListener(_checkABRepeat);
      AppToast.show(context, "A-B Repeat Cleared");
    }
    setState(() {});
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              border: Border.all(color: Colors.white10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Video Settings",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12, thickness: 1),
                const SizedBox(height: 10),

                // 1. Playback Speed Item
                _buildSettingsTile(
                  icon: Icons.speed_rounded,
                  title: "Playback Speed",
                  value: "${playerService.playbackSpeed}x",
                  onTap: () {
                    Navigator.pop(context);
                    _showSpeedSelection();
                  },
                ),

                // 2. Aspect Ratio (àª¤àª®à«‡ àªœà«‡ àª®àª¾àª‚àª—à«àª¯à«àª‚ àª¹àª¤à«àª‚ àª¤à«‡)
                // _buildSettingsTile(
                //   icon: Icons.aspect_ratio_rounded,
                //   title: "Aspect Ratio",
                //   value: _getFitText(_videoFit),
                //   onTap: () {
                //     Navigator.pop(context);
                //     // àª…àª¹à«€àª‚ àª¤àª®à«‡ Aspect Ratio àª¬àª¦àª²àªµàª¾àª¨à«àª‚ àª«àª‚àª•à«àª¶àª¨ àª•à«‹àª² àª•àª°à«€ àª¶àª•à«‹
                //   },
                // ),
                //
                // // 3. Audio/Subtitle (àªœà«‹ àª­àªµàª¿àª·à«àª¯àª®àª¾àª‚ àª‰àª®à«‡àª°àªµà«àª‚ àª¹à«‹àª¯)
                // _buildSettingsTile(
                //   icon: Icons.subtitles_rounded,
                //   title: "Subtitles",
                //   value: "Off",
                //   onTap: () {},
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

   Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 15),
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "Playback Speed",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),

                 Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                        bool isSelected = playerService.playbackSpeed == speed;
                        return ListTile(
                          onTap: () {
                            _changeSpeed(speed);
                            Navigator.pop(context);
                          },
                          leading: Icon(
                            Icons.check_circle_rounded,
                            color: isSelected
                                ? Colors.redAccent
                                : Colors.transparent,
                            size: 20,
                          ),
                          title: Text(
                            "${speed}x",
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.redAccent
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? const Text(
                                  "Current",
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _changeSpeed(double speed) async {
    await playerService.controller!.setPlaybackSpeed(speed);
    setState(() {
      playerService.playbackSpeed = speed;
    });
    Navigator.pop(context);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _showOverlayMessage(String message) {
    setState(() {
      _overlayText = message;
    });

      _overlayTextTimer?.cancel();
    _overlayTextTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _overlayText = null);
      }
    });
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
          });
    }
  }

  void _playTrimmedVideo(String path) async {
    if (playerService.controller != null) {
      playerService.controller!.removeListener(_videoListener);
      await playerService.controller!.dispose();
    }

    final newController = VideoPlayerController.file(File(path));

    try {
      await newController.initialize();

      setState(() {
        playerService.controller = newController;

        playerService.controller!.addListener(() {
          if (mounted) {
            setState(() {});

            _checkVideoEnd();
          }
        });

        playerService.controller!.play();
      });
    } catch (e) {
      debugPrint("Error loading trimmed video: $e");
    }
  }
}

/*
screenshot mate

<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
iOS (Info.plist):

XML
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save screenshots to your gallery.</string>
 */
