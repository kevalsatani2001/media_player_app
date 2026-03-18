import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
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

  double?
  _gestureValue; // àª¬à«àª°àª¾àª‡àªŸàª¨à«‡àª¸ àª•à«‡ àªµà«‹àª²à«àª¯à«àª®àª¨à«€ àª¤àª¾àªœà«‡àª¤àª°àª¨à«€ àªµà«‡àª²à«àª¯à« (0.0 to 1.0)
  bool _isBrightnessGesture =
      false; // àªšà«‡àª• àª•àª°àªµàª¾ àª®àª¾àªŸà«‡ àª•à«‡ àª¬à«àª°àª¾àª‡àªŸàª¨à«‡àª¸ àª¬àª¦àª²àª¾àªˆ àª°àª¹à«€ àª›à«‡ àª•à«‡ àªµà«‹àª²à«àª¯à«àª®
  Timer?
  _gestureOverlayTimer; // àª“àªµàª°àª²à«‡ àª›à«àªªàª¾àªµàªµàª¾ àª®àª¾àªŸà«‡àª¨à«‹ àªŸàª¾àªˆàª®àª°

  bool _showForwardIcon = false; // àªœàª®àª£à«€ àª¬àª¾àªœà« àª®àª¾àªŸà«‡
  bool _showBackwardIcon = false; // àª¡àª¾àª¬à«€ àª¬àª¾àªœà« àª®àª¾àªŸà«‡
  Timer? _seekIconTimer; // àª†àª‡àª•à«‹àª¨ àª›à«àªªàª¾àªµàªµàª¾ àª®àª¾àªŸà«‡

  @override
  void initState() {
    super.initState();
    // à«¨. àª† àª²àª¾àª‡àª¨ àª‰àª®à«‡àª°àªµà«€ àª«àª°àªœàª¿àª¯àª¾àª¤ àª›à«‡, àª¨àª¹à«€àª‚àª¤àª° didChangeAppLifecycleState àª•àª¾àª® àª¨àª¹à«€àª‚ àª•àª°à«‡
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
          _checkVideoEnd(); // àª…àª¹à«€àª‚ àª¨à«‡àª•à«àª¸à«àªŸ àªšà«‡àª• àª¥àª¶à«‡
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

  // player_screen.dart àª®àª¾àª‚ dispose àª®à«‡àª¥àª¡ àª…àªªàª¡à«‡àªŸ àª•àª°à«‹
  // player_screen.dart àª®àª¾àª‚ dispose àª®à«‡àª¥àª¡
  @override
  void dispose() {
    // à«ª. àª“àª¬à«àªàª°à«àªµàª°àª¨à«‡ àª°à«€àª®à«àªµ àª•àª°à«‹
    WidgetsBinding.instance.removeObserver(this);
    playerService.clearListener();
    playerService.controller?.pause();
    playerService.saveLastPlayed();
    _controlsTimer?.cancel();
    _gestureOverlayTimer?.cancel();
    _seekIconTimer?.cancel();
    _setOrientation(false);
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
      playerService.playNext(() {
        if (mounted) setState(() {});
      });
    }
  }

  void _setOrientation(bool full) {
    if (full) {
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
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isLocked) setState(() => _showControls = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!playerService.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CustomLoader()),
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
        setState(() => _showControls = !_showControls);
        if (_showControls) _startControlsTimer();
      },
      onDoubleTapDown: (details) => _seekRelative(details.globalPosition),
      onScaleStart: (details) {
        _baseScale = _videoScale;
        _isScaling = details.pointerCount >= 2;
      },
      onScaleUpdate: (details) {
        if (_isLocked) return;
        if (details.pointerCount >= 2 || _isScaling) {
          setState(
            () => _videoScale = (_baseScale * details.scale).clamp(1.0, 5.0),
          );
        } else {
          _handleSwipe(details);
        }
      },
      onScaleEnd: (_) => _isScaling = false,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video Surface
          // Video Surface
          Transform.scale(
            scale: _videoScale,
            child: SizedBox.expand(
              // àª†àª–àª¾ àª‰àªªàª²àª¬à«àª§ àªàª°àª¿àª¯àª¾àª®àª¾àª‚ àª«à«‡àª²àª¾àªˆ àªœàª¶à«‡
              child: FittedBox(
                fit: _videoFit,
                // àª…àª¹à«€àª‚ àª¤àª®àª¾àª°à«‹ _videoFit (contain, cover, fill) àª•àª¾àª® àª•àª°àª¶à«‡
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  // àªµàª¿àª¡àª¿àª¯à«‹àª¨àª¾ àª“àª°àª¿àªœàª¿àª¨àª² àª¸àª¾àª‡àª àª®à«àªœàª¬ àª¬à«‹àª•à«àª¸ àª¬àª¨àª¾àªµàª¶à«‡
                  width: playerService.controller!.value.size.width,
                  height: playerService.controller!.value.size.height,
                  child: VideoPlayer(playerService.controller!),
                ),
              ),
            ),
          ),

          // 2. Seek Indicator (àª†àª¨à«‡ àªµàª¿àª¡àª¿àª¯à«‹àª¨à«€ àª‰àªªàª° àª°àª¾àª–à«‹)
          _buildSeekIndicator(),
          // à«§. àªœà«‡àª¸à«àªšàª° àª‡àª¨à«àª¡àª¿àª•à«‡àªŸàª° àª…àª¹à«€àª‚ àª‰àª®à«‡àª°à«‹
          _buildGestureIndicator(),
          // Custom Overlay for Controls
          AnimatedOpacity(
            opacity: _showControls || _isLocked ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _buildControlsOverlay(),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureIndicator() {
    if (_gestureValue == null) return const SizedBox.shrink();

    IconData icon = _isBrightnessGesture
        ? (_gestureValue! > 0.5 ? Icons.brightness_7 : Icons.brightness_4)
        : (_gestureValue! == 0 ? Icons.volume_off : Icons.volume_up);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 10),
            // Progress Bar àªœà«‡àªµà«€ àª¡àª¿àªàª¾àª‡àª¨
            Container(
              width: 100,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _gestureValue!,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "${(_gestureValue! * 100).toInt()}%",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSwipe(ScaleUpdateDetails details) async {
    final width = MediaQuery.of(context).size.width;
    double delta = details.focalPointDelta.dy;

    _gestureOverlayTimer?.cancel();

    if (details.localFocalPoint.dx < width / 2) {
      // Left Side: Brightness
      _isBrightnessGesture = true;
      _brightness = (_brightness - delta / 200).clamp(0.0, 1.0);
      _gestureValue = _brightness;
      await ScreenBrightness().setScreenBrightness(_brightness);
    } else {
      // Right Side: Volume
      _isBrightnessGesture = false;
      playerService.volume = (playerService.volume - delta / 200).clamp(
        0.0,
        1.0,
      );
      _gestureValue = playerService.volume;
      if (!playerService.isMuted) {
        VolumeController().setVolume(playerService.volume, showSystemUI: false);
      }
    }

    setState(() {});

    _gestureOverlayTimer = Timer(const Duration(milliseconds: 800), () {
      setState(() => _gestureValue = null);
    });
  }

  void _seekRelative(Offset tapPosition) {
    if (_isLocked) return;
    final width = MediaQuery.of(context).size.width;
    final currentPos = playerService.controller!.value.position;

    _seekIconTimer
        ?.cancel(); // àªœà«‚àª¨à«‹ àªŸàª¾àªˆàª®àª° àª•à«‡àª¨à«àª¸àª² àª•àª°à«‹

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

    // àªµàª¿àª¡àª¿àª¯à«‹ àª¸à«€àª• àª•àª°à«‹
    final newPos = isForward
        ? currentPos + const Duration(seconds: 10)
        : currentPos - const Duration(seconds: 10);
    playerService.controller!.seekTo(newPos);

    // à«¬à«¦à«¦ àª®àª¿àª²à«€àª¸à«‡àª•àª¨à«àª¡ àªªàª›à«€ àª†àª‡àª•à«‹àª¨ àª›à«àªªàª¾àªµà«‹
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
        children: [
          if (!_isLocked) _buildTopBar(),
          const Spacer(),
          if (!_isLocked) _buildCenterControls(),
          const Spacer(),
          _buildBottomSection(),
        ],
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
          icon: Icons.skip_previous_rounded,
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              playerService.controller!.value.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 40),
        _buildCircularButton(
          icon: Icons.skip_next_rounded,
          onPressed: () => playerService.playNext(() => setState(() {})),
        ),
      ],
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 35),
    );
  }

  Widget _buildBottomSection() {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Row(
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
              const Spacer(),
            ],
          ),
          if (!_isLocked) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
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
            Row(
              children: [
                const SizedBox(width: 15),
                Text(
                  "${_formatDuration(playerService.controller!.value.position)} / ${_formatDuration(playerService.controller!.value.duration)}",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    size: 20,
                    color: playerService.isShuffle ? Colors.red : Colors.white,
                  ),
                  onPressed: () => setState(
                    () => playerService.isShuffle = !playerService.isShuffle,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    playerService.isLooping ? Icons.repeat_one : Icons.repeat,
                    size: 20,
                    color: playerService.isLooping ? Colors.red : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      playerService.isLooping = !playerService.isLooping;
                      playerService.controller!.setLooping(
                        playerService.isLooping,
                      );
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    playerService.isMuted ? Icons.volume_off : Icons.volume_up,
                    size: 20,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      playerService.isMuted = !playerService.isMuted;
                      playerService.controller!.setVolume(
                        playerService.isMuted ? 0 : playerService.volume,
                      );
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    size: 20,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFullScreen = !_isFullScreen;
                      _setOrientation(_isFullScreen);
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // àª¸à«‡àªŸàª¿àª‚àª—à«àª¸ àª…àª¨à«‡ àª¬àª¾àª•à«€àª¨à«€ àª¹à«‡àª²à«àªªàª° àª®à«‡àª¥àª¡à«àª¸ (àªœà«‚àª¨àª¾ àª•à«‹àª¡ àª®à«àªœàª¬ àªœ...)
  // à«¨. àª¸à«‡àªŸàª¿àª‚àª—à«àª¸ àª¬à«‹àªŸàª® àª¶à«€àªŸ àª¬àª¤àª¾àªµàªµàª¾ àª®àª¾àªŸà«‡
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Video Settings",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.white24),

              // Speed Option
              ListTile(
                leading: const Icon(Icons.speed, color: Colors.white),
                title: const Text(
                  "Playback Speed",
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Text(
                  "${playerService.playbackSpeed}x",
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSpeedSelection();
                },
              ),

              // Aspect Ratio Option
              ListTile(
                leading: const Icon(Icons.fit_screen, color: Colors.white),
                title: const Text(
                  "Screen Fit",
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Text(
                  _videoFit.name.toUpperCase(),
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  setState(() {
                    if (_videoFit == BoxFit.contain) {
                      _videoFit = BoxFit
                          .cover; // àª¸à«àª•à«àª°à«€àª¨ àª­àª°àª¾àªˆ àªœàª¶à«‡ (Crop àª¥àª¶à«‡)
                    } else if (_videoFit == BoxFit.cover) {
                      _videoFit = BoxFit
                          .fill; // àª†àª–àª¾ àª®à«‹àª¬àª¾àªˆàª²àª®àª¾àª‚ àª–à«‡àª‚àªšàª¾àªˆ àªœàª¶à«‡ (Stretch àª¥àª¶à«‡)
                    } else {
                      _videoFit = BoxFit
                          .contain; // àª“àª°àª¿àªœàª¿àª¨àª² àª°à«‡àª¶àª¿àª¯à«‹
                    }
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // à«©. àª¸à«àªªà«€àª¡ àª¸àª¿àª²à«‡àª•à«àª¶àª¨ àª®àª¾àªŸà«‡àª¨à«‹ àª¡àª¾àª¯àª²à«‹àª—
  void _showSpeedSelection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Select Speed",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
            return ListTile(
              title: Text(
                "${speed}x",
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () => _changeSpeed(speed),
              selected: playerService.playbackSpeed == speed,
              selectedColor: Colors.redAccent,
            );
          }).toList(),
        ),
      ),
    );
  }

  // à«§. Playback Speed àª¬àª¦àª²àªµàª¾ àª®àª¾àªŸà«‡
  void _changeSpeed(double speed) async {
    await playerService.controller!.setPlaybackSpeed(speed);
    setState(() {
      playerService.playbackSpeed = speed;
    });
    Navigator.pop(context); // àª¡àª¾àª¯àª²à«‹àª— àª¬àª‚àª§ àª•àª°àªµàª¾
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
