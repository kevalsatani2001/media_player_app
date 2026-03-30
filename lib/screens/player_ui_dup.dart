//////////////////////////////////////////////////////////////////////// part 1 new player scareen//////////////////////////////////////////////////////////
/*
/*

Equalizer (àª¸àª¾àª‰àª¨à«àª¡ àª¬àª¾àª°à«àª¸)


<svg width="35" height="35" viewBox="0 0 35 35" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="17.5" cy="17.5" r="17.5" fill="#3D57F9"/>
<rect x="10" y="16" width="3" height="8" rx="1.5" fill="white"/>
<rect x="16" y="10" width="3" height="14" rx="1.5" fill="white"/>
<rect x="22" y="14" width="3" height="10" rx="1.5" fill="white"/>
</svg>

Background Play (àª¹à«‡àª¡àª«à«‹àª¨)

<svg width="35" height="35" viewBox="0 0 35 35" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="17.5" cy="17.5" r="17.5" fill="#3D57F9"/>
<path d="M17.5 9C13.3579 9 10 12.3579 10 16.5V23C10 24.6569 11.3431 26 13 26H14C14.5523 26 15 25.5523 15 25V20C15 19.4477 14.5523 19 14 19H12V16.5C12 13.4624 14.4624 11 17.5 11C20.5376 11 23 13.4624 23 16.5V19H21C20.4477 19 20 19.4477 20 20V25C20 25.5523 20.4477 26 21 26H22C23.6569 26 25 24.6569 25 23V16.5C25 12.3579 21.6421 9 17.5 9Z" fill="white"/>
</svg>


 */
 */

import 'dart:math' show Random;
import 'dart:ui' as ui;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
  static const List<Color> _presetColors = [
    Colors.white,
    Colors.black,
    Color(0XFF3D57F9),
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.yellowAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.cyanAccent,
    Colors.grey,
  ];

  final playerService = GlobalPlayerService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // UI States
  bool _showControls = true;
  bool _isLocked = false;
  final List<int> _kidsLockSequence = [];
  Offset? _touchEffectPoint;
  Timer? _touchEffectTimer;
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

  String? _overlayText;
  String? sign;
  Timer? _overlayTextTimer;
  Duration? _seekDuration;
  String _activeGestureType = 'none'; // 'none', 'seek', 'vertical'
  bool _isMoreMenuVisible = false;
  bool _isQueueVisible = false;

  bool _showShortcutsInMenu = false;
  static const MethodChannel _equalizerChannel = MethodChannel(
    "media_player/equalizer",
  );

  /// Last tap position for MX-style "Pause/resume" edge zones.
  Offset? _lastTapLocal;

  /// When true, "Pause/resume" mode keeps chrome visible until edge toggled.
  bool _pauseResumeControlsPinned = false;

  Offset _videoPanOffset = Offset.zero;
  double _subtitleScrollPx = 0;
  double _subtitleVerticalPx = 0;
  double _subtitlePinchScale = 1;
  double _subPinchBase = 1;

  bool _nightModeDim = false;
  Timer? _sleepTimer;
  int? _sleepSecondsLeft;

  int _touchEffectShape = 0;
  Color _touchEffectColor = Colors.white;

  // aspect ratio

  bool _isRatioVisible = false;
  double? _selectedAspectRatio;
  bool _applyRatioToAll = false;

  // Screen settings runtime helpers â€” isolated from full-screen setState for smoothness
  final ValueNotifier<DateTime> _clockNotifier = ValueNotifier(DateTime.now());
  final ValueNotifier<int?> _batteryNotifier = ValueNotifier(null);
  late final Listenable _clockBatteryListenable = Listenable.merge([
    _clockNotifier,
    _batteryNotifier,
  ]);
  Timer? _clockTimer;
  final Battery _battery = Battery();
  bool _pausedDueToObstruction = false;

  final Map<String, double?> _ratioValues = {
    "Default": null,
    "Custom": 1.2,
    "1:1": 1.0,
    "4:3": 4 / 3,
    "16:9": 16 / 9,
    "18:9": 18 / 9,
    "21:9": 21 / 9,
    "2.21:1": 2.21 / 1,
    "2.35:1": 2.35 / 1,
    "2.39:1": 2.39 / 1,
  };

  bool _isShortcutEnabled(SettingsProvider s, String key) {
    final map = {
      "Capture": "ScreenShot",
      "Playback Speed": "Playback speed",
      "A-B Repeat": "A - B Repeat",
      "Flip": "Verticle Flip",
      "Mirror": "Mirror mode",
      "Shuffle": "Shuffle",
      "Repeat": "Loop",
      "Mute": "Mute",
      "Screen": "Screen Rotation",
      "Trim": "Customise Items",
      "Equalizer": "Equalizer",
      "Sleep": "Sleep Timer",
      "Night": "Night Mode",
      "BgPlay": "Background play",
    };
    final mapped = map[key] ?? key;
    return s.quickShortcuts[mapped] ?? true;
  }

  void _onGestureItemChanged(SettingsProvider s, String item, bool? v) {
    s.updateSetting(() {
      s.gestures[item] = v ?? false;
      if (item == "Zoom and pan" && (v ?? false)) {
        s.gestures["Video zoom"] = false;
        s.gestures["Video pan"] = false;
      }
      if ((item == "Video zoom" || item == "Video pan") && (v ?? false)) {
        s.gestures["Zoom and pan"] = false;
      }
      if (item == "Video zoom(double tap)" && (v ?? false)) {
        s.gestures["Play/pause(Double tap)"] = false;
        s.gestures["FF/RW(Double tap)"] = false;
      }
      if ((item == "Play/pause(Double tap)" || item == "FF/RW(Double tap)") &&
          (v ?? false)) {
        s.gestures["Video zoom(double tap)"] = false;
      }
    });
  }

  bool _isGestureCheckboxEnabled(SettingsProvider s, String item) {
    if (s.gestures["Zoom and pan"] == true &&
        (item == "Video zoom" || item == "Video pan")) {
      return false;
    }
    if (s.gestures["Video zoom(double tap)"] == true) {
      if (item == "Play/pause(Double tap)" || item == "FF/RW(Double tap)") {
        return false;
      }
    }
    return true;
  }

  void _showSleepTimerSheet() {
    int minutes = 15;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setS) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Sleep timer",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$minutes min",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Slider(
                    value: minutes.toDouble(),
                    min: 1,
                    max: 120,
                    divisions: 119,
                    activeColor: Color(0XFF3D57F9),
                    onChanged: (v) => setS(() => minutes = v.round()),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _sleepTimer?.cancel();
                          setState(() => _sleepSecondsLeft = null);
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0XFF3D57F9),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _sleepTimer?.cancel();
                          final total = minutes * 60;
                          setState(() => _sleepSecondsLeft = total);
                          _sleepTimer = Timer.periodic(
                            const Duration(seconds: 1),
                                (t) {
                              if (!mounted) return;
                              setState(() {
                                _sleepSecondsLeft =
                                    (_sleepSecondsLeft ?? 1) - 1;
                              });
                              if ((_sleepSecondsLeft ?? 0) <= 0) {
                                t.cancel();
                                playerService.pauseVideo();
                                if (mounted) {
                                  AppToast.show(context, "Sleep timer ended");
                                }
                              }
                            },
                          );
                        },
                        child: const Text("Start"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onBackgroundPlayHint() {
    AppToast.show(
      context,
      "Keep the app open or use PiP. Audio-focused background playback uses the media notification when available.",
    );
  }

  void _checkABRepeat() {
    if (_pointA != null && _pointB != null) {
      final currentPos = playerService.currentPosition;
      if (currentPos >= _pointB!) {
        playerService.seekTo(_pointA!);
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      settings.loadFromHive();
      _applyScreenSettings(settings);
      _applyEqualizerSettings(settings);
      if (settings.touchAction == "Pause/resume") {
        setState(() {
          _showControls = false;
          _pauseResumeControlsPinned = false;
        });
      } else if (!settings.showInterfaceAtStartup) {
        setState(() => _showControls = false);
      }
    });

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _clockNotifier.value = DateTime.now();
      _refreshBatteryIfNeeded();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      playerService.saveLastPlayed();
    }
    if (state == AppLifecycleState.inactive &&
        mounted &&
        Provider.of<SettingsProvider>(
          context,
          listen: false,
        ).pausePlaybackIfObstructed) {
      playerService.pauseVideo();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    playerService.clearListener();
    playerService.pauseVideo();
    playerService.saveLastPlayed();
    _controlsTimer?.cancel();
    _gestureOverlayTimer?.cancel();
    _seekIconTimer?.cancel();
    _touchEffectTimer?.cancel();
    _clockTimer?.cancel();
    _clockNotifier.dispose();
    _batteryNotifier.dispose();
    _sleepTimer?.cancel();
    _setOrientation(false);
    // playerService.controller?.removeListener(_videoListener);
    super.dispose();
  }

  Future<void> _refreshBatteryIfNeeded() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!settings.showBatteryClock && !settings.displayBatteryClockInTitleBar) {
      return;
    }
    try {
      final level = await _battery.batteryLevel;
      if (mounted && level != _batteryNotifier.value) {
        _batteryNotifier.value = level;
      }
    } catch (_) {}
  }

  Future<void> _applyBrightnessSetting(SettingsProvider s) async {
    if (!s.isBrightnessEnabled) return;
    try {
      await ScreenBrightness().setScreenBrightness(s.brightness);
      setState(() => _brightness = s.brightness);
    } catch (_) {}
  }

  Future<void> _applyBrightnessValue(bool isEnabled, double brightness) async {
    if (!isEnabled) return;
    try {
      await ScreenBrightness().setScreenBrightness(brightness);
      setState(() => _brightness = brightness);
    } catch (_) {}
  }

  Future<void> _applySoftButtonsSetting(SettingsProvider s) async {
    await _applySoftButtonsMode(s.softButtonsMode);
  }

  Future<void> _applySoftButtonsMode(String mode) async {
    switch (mode) {
      case "Show":
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        break;
      case "Hide":
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        break;
      case "Auto hide":
      default:
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        break;
    }
  }

  Future<void> _applyFullScreenSetting(SettingsProvider s) async {
    await _applyFullScreenMode(s.fullScreenMode);
  }

  Future<void> _applyFullScreenMode(String mode) async {
    switch (mode) {
      case "On":
        setState(() => _isFullScreen = true);
        _setOrientation(true);
        break;
      case "Off":
        setState(() => _isFullScreen = false);
        _setOrientation(false);
        break;
      case "Auto Switch":
      default:
        break;
    }
  }

  Future<void> _applyKeepScreenOn(SettingsProvider s) async {
    await _applyKeepScreenOnValue(s.keepScreenOn);
  }

  Future<void> _applyKeepScreenOnValue(bool keepScreenOn) async {
    try {
      if (keepScreenOn) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {}
  }

  Future<void> _applyScreenSettings(SettingsProvider s) async {
    _applyOrientation(s.orientation);
    await _applyFullScreenSetting(s);
    await _applySoftButtonsSetting(s);
    await _applyKeepScreenOn(s);
    await _applyBrightnessSetting(s);
    _refreshBatteryIfNeeded();
  }

  Future<void> _applyScreenState(ScreenSettingsState s) async {
    _applyOrientation(s.orientation);
    await _applyFullScreenMode(s.fullScreenMode);
    await _applySoftButtonsMode(s.softButtonsMode);
    await _applyKeepScreenOnValue(s.keepScreenOn);
    await _applyBrightnessValue(s.isBrightnessEnabled, s.brightness);
    if (mounted) {
      if (!s.showInterfaceAtStartup && _showControls) {
        setState(() => _showControls = false);
      } else if (s.showInterfaceAtStartup && !_showControls) {
        setState(() => _showControls = true);
        _startControlsTimer();
      }
    }
    _refreshBatteryIfNeeded();
  }

  void _checkVideoEnd() {
    if (!mounted) return;

    final controller = playerService.controller;
    if (controller == null || !controller.value.isInitialized) return;

    final v = controller.value;
    if (!playerService.shouldAdvanceToNextVideo(
      v.position,
      v.duration,
      v.isPlaying,
    )) {
      return;
    }

    controller.removeListener(_videoListener);

    playerService.playNext(() {
      if (mounted) setState(() {});
    });
  }

  void _toggleRotation() {
    setState(() {
      if (MediaQuery.of(context).orientation == Orientation.portrait) {
        print("==> if");
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        //////////////////////////////////////////////////////////////////////// part 2 new player scareen//////////////////////////////////////////////////////////

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
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _controlsTimer?.cancel();
    if (!settings.controlsInterfaceAutoHideEnabled) return;
    if (_isLocked) return;
    if (settings.touchAction == "Pause/resume" && _pauseResumeControlsPinned) {
      return;
    }
    final sec = settings.interfaceAutoHide.clamp(1.0, 60.0);
    _controlsTimer = Timer(Duration(seconds: sec.round()), () {
      if (mounted && !_isLocked && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!playerService.isInitialized) {
      return Scaffold(
        backgroundColor: settings.layoutBackgroundEnabled
            ? settings.layoutBackgroundColor
            : colors.background,
        body: SafeArea(child: Center(child: CustomLoader())),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      key: _scaffoldKey,

      endDrawer: _buildSideMenu(),
      onEndDrawerChanged: (isOpened) {
        if (isOpened) {
          setState(() {
            _showControls = false;
            _controlsTimer?.cancel();
          });
        } else {
          _resetDrawerState();
          setState(() {
            _showControls = true;
            _startControlsTimer();
          });
        }
      },
      // backgroundColor: Colors.black,
      backgroundColor: settings.layoutBackgroundEnabled
          ? settings.layoutBackgroundColor
          : colors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: _buildVideoPlayerWithGestures(),
      ),
    );
  }

  void _resetDrawerState() {
    setState(() {
      _isMoreMenuVisible = false;
      _showShortcutsInMenu = false;
      _isRatioVisible = false;
    });
  }

  bool _isNearScreenCorner(Offset local, Size size, {double inset = 80}) {
    return (local.dx <= inset && local.dy <= inset) ||
        (local.dx >= size.width - inset && local.dy <= inset) ||
        (local.dx >= size.width - inset && local.dy >= size.height - inset) ||
        (local.dx <= inset && local.dy >= size.height - inset);
  }

  void _handleVideoTap() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final size = MediaQuery.of(context).size;
    final touchAction = settings.touchAction;

    if (_isLocked) {
      if (settings.lockMode != "Lock") {
        _showKidsLockInstructionIfNeeded();
      } else if (settings.showInterfaceWhenLockedTouched) {
        setState(() => _showControls = !_showControls);
      }
      return;
    }

    if (touchAction == "Pause/resume") {
      final y = _lastTapLocal?.dy ?? size.height / 2;
      final topZone = y < size.height * 0.15;
      final bottomZone = y > size.height * 0.82;
      if (topZone || bottomZone) {
        setState(() {
          if (_pauseResumeControlsPinned && _showControls) {
            _showControls = false;
            _pauseResumeControlsPinned = false;
          } else {
            _showControls = true;
            _pauseResumeControlsPinned = true;
          }
        });
        _controlsTimer?.cancel();
        return;
      }
      playerService.togglePlay();
      return;
    }

    if (touchAction == "Show/hide interface") {
      final nextVisible = !_showControls;
      setState(() => _showControls = nextVisible);
      if (settings.controlsInterfaceAutoHideEnabled && nextVisible) {
        _startControlsTimer();
      } else {
        _controlsTimer?.cancel();
      }
      return;
    }

    playerService.togglePlay();
    final playingAfter = playerService.isVideoPlaying;

    setState(() {
      if (touchAction == "Show Interface -> Pause/Resume") {
        _showControls = true;
      } else if (touchAction == "Show interface + pause/resume") {
        _showControls = !playingAfter;
      }
    });

    if (settings.controlsInterfaceAutoHideEnabled) {
      _startControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  Widget _buildLockedProgressRow(SettingsProvider settings) {
    final playedColor = settings.progressBarCategory == "Flat"
        ? settings.progressBarColor.withOpacity(0.8)
        : settings.progressBarColor;
    return Row(
      children: [
        Text(
          _formatDuration(playerService.currentPosition),
          style: TextStyle(color: settings.controlsColor, fontSize: 12),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: VideoProgressIndicator(
              _playerController,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 10),
              colors: VideoProgressColors(
                playedColor: playedColor,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ),
        Text(
          settings.showRemainingTime
              ? "-${_formatDuration(playerService.totalDuration - playerService.currentPosition)}"
              : _formatDuration(playerService.totalDuration),
          style: TextStyle(color: settings.controlsColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildVideoPlayerWithGestures() {
    final settings = Provider.of<SettingsProvider>(context);

    return VisibilityDetector(
      key: const ValueKey("player_visibility"),
      onVisibilityChanged: (info) {
        if (!settings.pausePlaybackIfObstructed) return;
        final controller = playerService.controller;
        if (controller == null) return;

        final visible = info.visibleFraction;
        if (visible < 0.6 && controller.value.isPlaying) {
          controller.pause();
          _pausedDueToObstruction = true;
        } else if (visible > 0.95 &&
            _pausedDueToObstruction &&
            !controller.value.isPlaying) {
          controller.play();
          _pausedDueToObstruction = false;
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleVideoTap,
        onDoubleTapDown: (details) => _handleDoubleTap(details.globalPosition),
        onScaleStart: (details) {
          final mq = MediaQuery.of(context);
          _baseScale = _videoScale;
          _subPinchBase = _subtitlePinchScale;
          _isScaling = details.pointerCount >= 2;
          _activeGestureType = 'none';
          final bottom = details.localFocalPoint.dy > mq.size.height * 0.72;
          if (details.pointerCount >= 2 &&
              bottom &&
              (settings.gestures["Subtitle zoom"] ?? false)) {
            _activeGestureType = 'subtitle_zoom';
          }
        },
        onScaleUpdate: (details) {
          if (_isLocked ||
              (_scaffoldKey.currentState?.isEndDrawerOpen ?? false)) {
            return;
          }
          final mq = MediaQuery.of(context);
          final sz = mq.size;
          final g = settings.gestures;
          final zoomAndPan = g["Zoom and pan"] ?? false;
          final videoZoom = g["Video zoom"] ?? false;
          final videoPan = g["Video pan"] ?? false;
          final allowZoom = zoomAndPan || videoZoom;
          final allowPan = zoomAndPan || videoPan;

          if (details.pointerCount >= 2 &&
              _activeGestureType == 'subtitle_zoom') {
            setState(() {
              _subtitlePinchScale = (_subPinchBase * details.scale).clamp(
                0.5,
                3.0,
              );
            });
            return;
          }

          if (details.pointerCount >= 2 &&
              details.localFocalPoint.dy > sz.height * 0.72 &&
              (g["Subtitle zoom"] ?? false) &&
              !allowZoom) {
            setState(() {
              _subtitlePinchScale = (_subPinchBase * details.scale).clamp(
                0.5,
                3.0,
              );
            });
            return;
          }

          if (details.pointerCount >= 2) {
            _isScaling = true;
            setState(() {
              if (allowZoom) {
                _videoScale = (_baseScale * details.scale).clamp(1.0, 5.0);
              }
              if (allowPan && (allowZoom ? _videoScale > 1.01 : true)) {
                _videoPanOffset += details.focalPointDelta;
              }
            });
          } else if (!_isScaling) {
            _handleSwipe(details);
          }
        },
        onScaleEnd: (_) {
          if (_videoScale <= 1.01) {
            _videoPanOffset = Offset.zero;
          }
          _isScaling = false;
          _activeGestureType = 'none';
        },
        onLongPressStart: (details) {
          final sz = MediaQuery.of(context).size;
          final local = details.localPosition;
          final corner = _isNearScreenCorner(local, sz);
          if (corner && (settings.gestures["Speed FF(Long press)"] ?? false)) {
            _showPlaybackSpeedBottomSheet();
            return;
          }
          if (!corner && (settings.gestures["Playback speed"] ?? false)) {
            _showPlaybackSpeedBottomSheet();
          }
        },
        onTapDown: (details) {
          _lastTapLocal = details.localPosition;
          if (_isLocked && settings.lockMode != "Lock") {
            _handleKidsLockTap(details.localPosition);
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            /*
          Transform.scale(
            scale: _videoScale,
            child: Center(
              child: AspectRatio(
                aspectRatio: playerService.currentAspectRatio,
                child: VideoPlayer(_playerController),
              ),
            ),
          ),
          */
            if (!settings.layoutBackgroundEnabled)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: playerService.currentVideoSize.width,
                            height: playerService.currentVideoSize.height,
                            child: VideoPlayer(_playerController),
                          ),
                        ),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                          child: Container(
                            color: Colors.black.withOpacity(
                              0.3,
                            ), // àª¥à«‹àª¡à«‹ àª¡àª¾àª°à«àª•àª¨à«‡àª¸ àª†àªªàªµàª¾ àª®àª¾àªŸà«‡
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Video Surface
            RepaintBoundary(
              key: _globalKey,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateY(
                    _isMirrored ? 3.14159 : 0,
                  ) // Mirror (Y-axis rotation)
                  ..rotateX(_isFlipped ? 3.14159 : 0),
                // Vertical Flip (X-axis rotation)
                child: Transform.translate(
                  offset: _videoPanOffset,
                  child: Transform.scale(
                    scale: _videoScale,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio:
                        _selectedAspectRatio ??
                            playerService.currentAspectRatio,
                        child: FittedBox(
                          fit: _videoFit,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: playerService.currentVideoSize.width,
                            height: playerService.currentVideoSize.height,
                            child: VideoPlayer(_playerController),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_nightModeDim)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: Colors.black.withOpacity(0.48)),
                ),
              ),
            _buildSeekIndicator(),
            _buildGestureIndicator(),
            // Custom Overlay for Controls
            RepaintBoundary(
              child: IgnorePointer(
                ignoring: !_showControls && !_isLocked,
                child: AnimatedOpacity(
                  opacity: _showControls || _isLocked ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _buildControlsOverlay(),
                ),
              ),
            ),
            _buildScreenOverlays(settings),
            if (_overlayText != null)
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    // This keeps the box tight around the text
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (sign != null) ...[
                        Text(
                          sign ?? "",
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      SizedBox(width: 8), // Gap between icon and time
                      Text(
                        _overlayText ?? "",
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            if (_touchEffectPoint != null) _buildTouchEffect(),
          ],
        ),
      ),
    );
  }

  Widget _buildTouchEffect() {
    final c = _touchEffectColor;
    return Positioned(
      left: _touchEffectPoint!.dx - 28,
      top: _touchEffectPoint!.dy - 28,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.15, end: 1.0),
        duration: const Duration(milliseconds: 400),
        builder: (_, value, child) {
          Widget core;
          switch (_touchEffectShape % 6) {
            case 0:
              core = Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.withOpacity(0.35),
                  shape: BoxShape.circle,
                  border: Border.all(color: c, width: 2),
                ),
              );
              break;
            case 1:
              core = Transform.rotate(
                angle: value * 1.047,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: c, width: 2),
                  ),
                ),
              );
              break;
            case 2:
              core = Icon(Icons.change_history, color: c, size: 52);
              break;
            case 3:
              core = Container(
                width: 60,
                height: 36,
                decoration: BoxDecoration(
                  color: c.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: c),
                ),
              );
              break;
            case 4:
              core = Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c, width: 3),
                ),
              );
              break;
            default:
              core = Icon(Icons.auto_awesome, color: c, size: 40 * value);
          }
          return Transform.rotate(
            angle: value * 0.8,
            child: Opacity(opacity: 1 - value * 0.55, child: core),
          );
        },
      ),
    );
  }

  void _showKidsLockInstructionIfNeeded() {
    if (_kidsLockSequence.isEmpty) {
      AppToast.show(context, "Touch each corner of the screen");
    }
  }

  void _handleKidsLockTap(Offset point) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final size = MediaQuery.of(context).size;
    const threshold = 80.0;
    int? corner;
    if (point.dx <= threshold && point.dy <= threshold) {
      corner = 0; // top-left
    } else if (point.dx >= size.width - threshold && point.dy <= threshold) {
      corner = 1; // top-right
    } else if (point.dx >= size.width - threshold &&
        point.dy >= size.height - threshold) {
      corner = 2; // bottom-right
    } else if (point.dx <= threshold && point.dy >= size.height - threshold) {
      corner = 3; // bottom-left
    }

    if (corner == null) {
      if (settings.lockMode == "Kids lock (+Touch effects)") {
        setState(() {
          _touchEffectPoint = point;
          _touchEffectShape = Random().nextInt(6);
          _touchEffectColor =
          Colors.primaries[Random().nextInt(Colors.primaries.length)];
        });
        _touchEffectTimer?.cancel();
        _touchEffectTimer = Timer(const Duration(milliseconds: 450), () {
          if (mounted) setState(() => _touchEffectPoint = null);
        });
      }
      return;
    }

    final expected = _kidsLockSequence.length;
    if (corner == expected) {
      _kidsLockSequence.add(corner);
      if (_kidsLockSequence.length == 4) {
        setState(() {
          _isLocked = false;
          _showControls = true;
          _kidsLockSequence.clear();
        });
        _startControlsTimer();
      }
    } else {
      _kidsLockSequence.clear();
      AppToast.show(context, "Wrong sequence, try again");
    }
  }

  void _handleDoubleTap(Offset tapPosition) {
    if (_isLocked) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final g = settings.gestures;
    final w = MediaQuery.of(context).size.width;
    final left = tapPosition.dx < w * 0.33;
    final right = tapPosition.dx > w * 0.67;
    final mid = !left && !right;

    final videoZoomDt = g["Video zoom(double tap)"] ?? false;
    final ffRw = g["FF/RW(Double tap)"] ?? false;
    final playPauseDt = g["Play/pause(Double tap)"] ?? false;

    if (videoZoomDt) {
      setState(() {
        _videoScale = _videoScale > 1.0 ? 1.0 : 2.0;
      });
      return;
    }

    if (ffRw && playPauseDt) {
      if (left || right) {
        _seekRelative(tapPosition);
      } else if (mid) {
        playerService.togglePlay();
        setState(() => _showControls = true);
        _startControlsTimer();
      }
      return;
    }

    if (ffRw && (left || right)) {
      _seekRelative(tapPosition);
      return;
    }

    if (playPauseDt) {
      playerService.togglePlay();
      setState(() => _showControls = true);
      _startControlsTimer();
    }
  }

  Widget _buildScreenOverlays(SettingsProvider settings) {
    final controller = playerService.controller;
    final position = controller?.value.position ?? Duration.zero;
    final duration = controller?.value.duration ?? Duration.zero;
    final remaining = duration - position;
    final pad = MediaQuery.paddingOf(context);
    final double topInset = pad.top;
    final double sideInset = pad.left;

    final List<Widget> overlays = [];

    // Corner chips only when top bar / controls are hidden â€” avoids stacking with top bar.
    final bool showCornerOverlays = !_showControls;

    if (showCornerOverlays && settings.showElapsedTime) {
      final double offset = settings.isCornerOffsetEnabled
          ? settings.cornerOffset.clamp(0.0, 150.0)
          : 0.0;
      overlays.add(
        Positioned(
          left: 12 + sideInset + offset,
          top: topInset + 12,
          child: _overlayChip(
            _formatDuration(position),
            bg: settings.screenTextBackgroundEnabled
                ? settings.screenTextBackgroundColor
                : Colors.black54,
            fg: settings.controlsColor,
          ),
        ),
      );
    }

    if (showCornerOverlays && settings.showBatteryClock) {
      final double offset = settings.isCornerOffsetEnabled
          ? settings.cornerOffset.clamp(0.0, 150.0)
          : 0.0;
      overlays.add(
        Positioned(
          right: 12 + pad.right + offset,
          top: topInset + 12,
          child: _overlayChipClockBattery(
            settings: settings,
            compactSeparator: true,
          ),
        ),
      );
    }

    if (settings.screenTextPlaceAtBottom) {
      overlays.add(
        Positioned(
          left: 12 + pad.left,
          right: 12 + pad.right,
          bottom: 12 + pad.bottom,
          child: Transform.translate(
            offset: Offset(
              _subtitleScrollPx.clamp(-400.0, 400.0) * 0.15,
              -_subtitleVerticalPx.clamp(-400.0, 400.0) * 0.15,
            ),
            child: Transform.scale(
              scale: _subtitlePinchScale.clamp(0.5, 3.0),
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: settings.screenTextBackgroundEnabled
                      ? settings.screenTextBackgroundColor
                      : Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  settings.showRemainingTime
                      ? "-${_formatDuration(remaining)}"
                      : _formatDuration(position),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: settings.screenTextBottomColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (overlays.isEmpty) return const SizedBox.shrink();
    return Stack(children: overlays);
  }

  Widget _overlayChip(String text, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _overlayChipClockBattery({
    required SettingsProvider settings,
    required bool compactSeparator,
  }) {
    final bg = settings.screenTextBackgroundEnabled
        ? settings.screenTextBackgroundColor
        : Colors.black54;
    final fg = settings.controlsColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: AnimatedBuilder(
        animation: _clockBatteryListenable,
        builder: (context, _) {
          final bat = _batteryNotifier.value;
          final sep = compactSeparator ? " â€¢ " : "  ";
          final extra = bat != null ? "$sep$bat%" : "";
          return Text(
            "${_formatClock(_clockNotifier.value)}$extra",
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }

  String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  VideoPlayerController get _playerController => playerService.controller!;

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
      //////////////////////////////////////////////////////////////////////// part 3 new player scareen//////////////////////////////////////////////////////////

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
                      : Color(0XFF3D57F9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color:
                      (_isBrightnessGesture
                          ? Colors.orangeAccent
                          : Color(0XFF3D57F9))
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
    if (_isScaling) return;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    double deltaY = details.focalPointDelta.dy;
    double deltaX = details.focalPointDelta.dx;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final inSubtitleBand = details.localFocalPoint.dy > height * 0.72;
    final ss = settings.gestures["Subtitle Scroll"] ?? false;
    final su = settings.gestures["Subtitle up/down"] ?? false;

    if (inSubtitleBand && (ss || su)) {
      if (_activeGestureType == 'none') {
        if (deltaX.abs() > deltaY.abs() && deltaX.abs() > 2.0 && ss) {
          _activeGestureType = 'subtitle_h';
        } else if (deltaY.abs() > deltaX.abs() && deltaY.abs() > 2.0 && su) {
          _activeGestureType = 'subtitle_v';
        }
      }
      if (_activeGestureType == 'subtitle_h') {
        setState(() => _subtitleScrollPx += deltaX);
        return;
      }
      if (_activeGestureType == 'subtitle_v') {
        setState(() => _subtitleVerticalPx += deltaY);
        return;
      }
    }

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
      if (!(settings.gestures["Seek position"] ?? true)) return;
      final controller = playerService.controller!;
      if (controller.value.isInitialized) {
        final currentPos = controller.value.position;
        final totalDuration = controller.value.duration;

        final speed = settings.seekSpeed.clamp(2, 400);
        Duration seekStep = Duration(
          milliseconds: (deltaX * speed * 10).toInt(),
        );
        Duration newPos = currentPos + seekStep;

        if (newPos < Duration.zero) newPos = Duration.zero;
        if (newPos > totalDuration) newPos = totalDuration;

        controller.seekTo(newPos);

        bool isForward = deltaX > 0;

        String icon = isForward ? "\u00BB" : "\u00AB";
        if (settings.displayCurrentPositionWhileChanging) {
          _showOverlayMessage(_formatDuration(newPos), icon);
        }
      }
      return;
    }

    if (_activeGestureType == 'vertical') {
      if (details.localFocalPoint.dx < width / 2) {
        if (!(settings.gestures["Brightness"] ?? false)) return;
        // Brightness Logic
        _isBrightnessGesture = true;
        _brightness = (_brightness - deltaY / 200).clamp(0.0, 1.0);
        settings.updateSetting(() => settings.brightness = _brightness);
        _gestureValue = _brightness;
        await ScreenBrightness().setApplicationScreenBrightness(_brightness);
      } else {
        if (!(settings.gestures["Volume"] ?? false)) return;
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
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!(settings.gestures["FF/RW(Double tap)"] ?? true)) return;
    final width = MediaQuery.of(context).size.width;
    final currentPos = playerService.currentPosition;

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

    final stepSec = settings.moveInterval.round().clamp(1, 120);
    final newPos = isForward
        ? currentPos + Duration(seconds: stepSec)
        : currentPos - Duration(seconds: stepSec);
    playerService.seekTo(newPos);

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
    final settings = Provider.of<SettingsProvider>(context);
    if (_isLocked && settings.lockMode == "Lock") {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (settings.showInterfaceWhenLockedTouched && _showControls)
            Positioned(
              left: 10,
              right: 10,
              bottom: 72,
              child: _buildLockedProgressRow(settings),
            ),
          Positioned(
            bottom: 8,
            left: 4,
            child: IconButton(
              icon: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => setState(() {
                _isLocked = false;
                _kidsLockSequence.clear();
                _startControlsTimer();
              }),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _isLocked ? Colors.transparent : Colors.black.withOpacity(0.4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!_isLocked) ...[_buildTopBar(), _buildExtraControlsHeader()],
          const Spacer(),
          const Spacer(),
          const Spacer(),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildExtraControlsHeader() {
    final settings = Provider.of<SettingsProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) {},
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
                          if (_isShortcutEnabled(settings, "Capture"))
                            _controlItemWithLabel(
                              src: AppSvg.icCamera,
                              label: "Capture",
                              onTap: _captureScreenshot,
                            ),

                          if (_isShortcutEnabled(settings, "A-B Repeat"))
                            _controlItemWithLabel(
                              src: AppSvg.icABRepeat,
                              label: "A-B Repeat",
                              color: _pointA != null
                                  ? Color(0XFF3D57F9)
                                  : Colors.white,
                              onTap: _handleABRepeat,
                            ),

                          if (_isShortcutEnabled(settings, "Flip"))
                            _controlItemWithLabel(
                              src: AppSvg.icSwapVert,
                              label: "Flip",
                              color: _isFlipped
                                  ? Color(0XFF3D57F9)
                                  : Colors.white,
                              onTap: () =>
                                  setState(() => _isFlipped = !_isFlipped),
                            ),

                          if (_isShortcutEnabled(settings, "Mirror"))
                            _controlItemWithLabel(
                              src: AppSvg.icSwapHor,
                              label: "Mirror",
                              color: _isMirrored
                                  ? Color(0XFF3D57F9)
                                  : Colors.white,
                              onTap: () =>
                                  setState(() => _isMirrored = !_isMirrored),
                            ),

                          if (_isShortcutEnabled(settings, "Trim"))
                            _controlItemWithLabel(
                              src: AppSvg.likeIcon,
                              label: "Trim",
                              onTap: () async {
                                await playerService.pauseVideo();
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
                                print("trimmedPath is ==> $trimmedPath");

                                int lastPosition =
                                    playerService
                                        .controller
                                        ?.value
                                        .position
                                        .inMilliseconds ??
                                        0;

                                playerService.loadVideo(() {
                                  if (mounted) setState(() {});
                                }, seekToMs: lastPosition);
                              },
                            ),
                          if (_isShortcutEnabled(settings, "Playback Speed"))
                            _controlItemWithLabel(
                              src: AppSvg.ic2x,
                              label: "Speed",
                              onTap: _showPlaybackSpeedBottomSheet,
                            ),
                        ],

                        if (_isShortcutEnabled(settings, "Shuffle"))
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

                        if (_isShortcutEnabled(settings, "Repeat"))
                          _controlItemWithLabel(
                            src: playerService.isLooping
                                ? AppSvg.icLoopActive
                                : AppSvg.icLoop,
                            label: "Repeat",
                            onTap: () => setState(() {
                              playerService.isLooping =
                              !playerService.isLooping;
                              playerService.setLooping(playerService.isLooping);
                            }),
                          ),
                        if (_isShortcutEnabled(settings, "Equalizer"))
                          _controlItemWithLabel(
                            src: AppSvg.ic2x,
                            label: "Equalizer",
                            color: settings.equalizerEnabled
                                ? Color(0XFF3D57F9)
                                : Colors.white,
                            onTap: () => _showEqualizerBottomSheet(settings),
                          ),
                        if (_isShortcutEnabled(settings, "Sleep"))
                          _controlItemWithLabel(
                            src: AppSvg.ic2x,
                            label: "Sleep",
                            color:
                            (_sleepSecondsLeft != null &&
                                _sleepSecondsLeft! > 0)
                                ? Color(0XFF3D57F9)
                                : Colors.white,
                            onTap: _showSleepTimerSheet,
                          ),
                        if (_isShortcutEnabled(settings, "Night"))
                          _controlItemWithLabel(
                            src: AppSvg.ic2x,
                            label: "Night",
                            color: _nightModeDim
                                ? Color(0XFF3D57F9)
                                : Colors.white,
                            onTap: () =>
                                setState(() => _nightModeDim = !_nightModeDim),
                          ),
                        if (_isShortcutEnabled(settings, "BgPlay"))
                          _controlItemWithLabel(
                            src: AppSvg.ic2x,
                            label: "BG play",
                            onTap: _onBackgroundPlayHint,
                          ),

                        if (_isShortcutEnabled(settings, "Mute"))
                          _controlItemWithLabel(
                            src: playerService.isMuted
                                ? AppSvg.icVolumeOff
                                : AppSvg.icVolumeOn,
                            label: "Mute",
                            onTap: () => setState(() {
                              playerService.isMuted = !playerService.isMuted;
                              playerService.setVideoVolume(
                                playerService.isMuted
                                    ? 0
                                    : playerService.volume,
                              );
                            }),
                          ),
                        if (_isShortcutEnabled(settings, "Screen"))
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
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return GestureDetector(
      onTap: () {
        onTap();
        _startControlsTimer();
      },
      child: Container(
        height: 35,
        width: 35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: settings.controlsBgColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppImage(
              src: src,
              height: 35,
              width: 35,
              color: settings.controlsColor,
            ),
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
    final settings = Provider.of<SettingsProvider>(context);
    final pad = MediaQuery.paddingOf(context);
    return Container(
      padding: EdgeInsets.only(
        top: pad.top + (isLandscape ? 4 : 8),
        left: pad.left + 10,
        right: pad.right + 10,
        bottom: 8,
      ),
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
          if (settings.showElapsedTime)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _formatDuration(playerService.currentPosition),
                style: TextStyle(
                  color: settings.controlsColor.withOpacity(0.95),
                  fontSize: isLandscape ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          if (settings.displayBatteryClockInTitleBar)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AnimatedBuilder(
                animation: _clockBatteryListenable,
                builder: (context, _) {
                  final bat = _batteryNotifier.value;
                  final extra = bat != null ? "  $bat%" : "";
                  return Text(
                    "${_formatClock(_clockNotifier.value)}$extra",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          if (settings.screenRotationButton)
            IconButton(
              icon: const Icon(Icons.screen_rotation, color: Colors.white),
              onPressed: _toggleRotation,
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // playerService.controller?.pause();
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSideMenu() {
    double drawerWidth =
    MediaQuery.of(context).orientation == Orientation.landscape
        ? MediaQuery.of(context).size.width * 0.35
        : MediaQuery.of(context).size.width * 0.75;

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        backgroundColor: Colors.black.withOpacity(0.01),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section (Dynamic based on _isMoreMenuVisible)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 10,
                ),
                child: Row(
                  children: [
                    if (_isMoreMenuVisible || _isQueueVisible)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => setState(() {
                          _isMoreMenuVisible = false;
                          _isQueueVisible = false;
                        }),
                      ),
                    Text(
                      _isQueueVisible
                          ? "Playing Queue"
                          : (_isMoreMenuVisible ? "More" : "Quick Menu"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),

              // Content Section
              Expanded(
                child: _isQueueVisible
                    ? _buildQueueList()
                    : (_isRatioVisible
                    ? _buildRatioMenu()
                    : (_isMoreMenuVisible
                    ? _buildMoreCategoryMenu()
                    : _buildMainMenuGrid())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueueList() {
    return ReorderableListView.builder(
      itemCount: playerService.playlist.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = playerService.playlist.removeAt(oldIndex);
          playerService.playlist.insert(newIndex, item);

          if (oldIndex == playerService.currentIndex) {
            playerService.currentIndex = newIndex;
          } else if (oldIndex < playerService.currentIndex &&
              newIndex >= playerService.currentIndex) {
            playerService.currentIndex -= 1;
          } else if (oldIndex > playerService.currentIndex &&
              newIndex <= playerService.currentIndex) {
            playerService.currentIndex += 1;
          }
        });
      },
      itemBuilder: (context, index) {
        final video = playerService.playlist[index];
        final bool isCurrent = index == playerService.currentIndex;

        return ListTile(
          key: ValueKey(video.id),
          leading: Container(
            width: 50,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.videocam, color: Colors.white54, size: 20),
          ),
          title: Text(
            video.title ?? "Unknown",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isCurrent ? Color(0XFF3D57F9) : Colors.white,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          trailing: const Icon(Icons.drag_handle, color: Colors.white24),
          onTap: () {
            playerService.currentIndex = index;
            playerService.loadVideo(() {
              if (mounted) setState(() {});
            });
          },
        );
      },
    );
  }

  Widget _buildRatioMenu() {
    return Column(
        children: [
    Expanded(
    child: ListView(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    children: [
    ..._ratioValues.keys.map((String key) {
    bool isSelected = _selectedAspectRatio == _ratioValues[key];
    return ListTile(
    leading: Icon(//////////////////////////////////////////////////////////////////////// part 4 new player scareen//////////////////////////////////////////////////////////

      isSelected
          ? Icons.radio_button_checked
          : Icons.radio_button_off,
      color: isSelected ? Color(0XFF3D57F9) : Colors.white54,
      size: 20,
    ),
      title: Text(
        key,
        style: TextStyle(
          color: isSelected ? Color(0XFF3D57F9) : Colors.white,
          fontSize: 15,
        ),
      ),
      onTap: () {
        setState(() {
          _selectedAspectRatio = _ratioValues[key];
        });
      },
    );
    }).toList(),
    ],
    ),
    ),

          const Divider(color: Colors.white24),

          // Apply to all videos Checkbox
          CheckboxListTile(
            title: const Text(
              "Apply to all videos",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            value: _applyRatioToAll,
            activeColor: Color(0XFF3D57F9),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (bool? value) {
              setState(() {
                _applyRatioToAll = value ?? false;
              });
            },
          ),
        ],
    );
  }

  void _showPlaybackSpeedBottomSheet() {
    double currentSpeed = playerService.playbackSpeed;
    TextEditingController speedTextController = TextEditingController(
      text: currentSpeed.toStringAsFixed(2),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updateSpeed(double newSpeed, {bool isManual = false}) {
              double validatedSpeed = newSpeed.clamp(0.25, 4.0);

              double finalSpeed;
              if (isManual) {
                finalSpeed = double.parse(validatedSpeed.toStringAsFixed(2));
              } else {
                finalSpeed = (validatedSpeed * 20).round() / 20;
              }

              playerService.setPlaybackSpeed(finalSpeed);

              setSheetState(() {
                currentSpeed = finalSpeed;
                speedTextController.text = finalSpeed.toString();
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Playback Speed",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- Row 1: [-] [TextField] [+] ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _speedCircleButton(
                        Icons.remove,
                            () => updateSpeed(currentSpeed - 0.05),
                      ),

                      Container(
                        width: 100,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: speedTextController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0XFF3D57F9)),
                            ),
                            suffixText: "x",
                          ),
                          onSubmitted: (value) {
                            double? entered = double.tryParse(value);
                            if (entered != null) {
                              updateSpeed(entered, isManual: true);
                            }
                          },
                        ),
                      ),

                      _speedCircleButton(
                        Icons.add,
                            () => updateSpeed(currentSpeed + 0.05),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- Row 2: [Slider] [Reset Icon] ---
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: currentSpeed,
                          min: 0.25,
                          max: 4.0,
                          activeColor: Color(0XFF3D57F9),
                          onChanged: (value) => updateSpeed(value),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () => updateSpeed(1.0), // Reset to Normal
                        tooltip: "Reset",
                      ),
                    ],
                  ),

                  // Slider Labels
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "0.25x",
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                        Text(
                          "1.0x",
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                        Text(
                          "2.0x",
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                        Text(
                          "3.0x",
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                        Text(
                          "4.0x",
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNetworkStreamDialog() {
    TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Network Stream",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter a video URL to stream (HTTP, HTTPS, or direct link)",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: urlController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "http://example.com/video.mp4",
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.content_paste,
                      color: Color(0XFF3D57F9),
                    ),
                    onPressed: () async {
                      // final data = await Clipboard.getData('text/plain');
                      // if (data != null) urlController.text = data.text!;
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0XFF3D57F9),
              ),
              onPressed: () {
                String url = urlController.text.trim();
                if (url.isNotEmpty && Uri.parse(url).isAbsolute) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  playerService.playNetworkStream(url, () {
                    if (mounted) setState(() {});
                  });
                } else {}
              },
              child: const Text(
                "Play Stream",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _speedCircleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildMainMenuGrid() {
    return SingleChildScrollView(
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 15,
            crossAxisSpacing: 10,
            padding: const EdgeInsets.all(15),
            children: [
              _menuGridItem(
                Icons.queue_play_next,
                "Queue",
                onTapCustom: () {
                  setState(() => _isQueueVisible = true);
                },
              ),
              _menuGridItem(
                Icons.aspect_ratio,
                "Ratio",
                onTapCustom: () {
                  setState(() => _isRatioVisible = true);
                },
              ),
              _menuGridItem(
                Icons.settings_display,
                "Display",
                onTapCustom: () {
                  Navigator.pop(context);
                  _showDisplaySettings(context);
                },
              ),
              // _menuGridItem(Icons.bookmark_border, "Bookmark"),
              _menuGridItem(
                Icons.content_cut,
                "Cut",
                onTapCustom: () async {
                  await playerService.pauseVideo();
                  File? file = await playerService
                      .playlist[playerService.currentIndex]
                      .file;

                  final trimmedPath = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoTrimScreen(file: file!),
                    ),
                  );
                  print("trimmedPath is ==> $trimmedPath");

                  int lastPosition =
                      playerService.controller?.value.position.inMilliseconds ??
                          0;

                  playerService.loadVideo(() {
                    if (mounted) setState(() {});
                  }, seekToMs: lastPosition);
                },
              ),
              _menuGridItem(Icons.favorite_border, "Favourite"),
              _menuGridItem(
                Icons.playlist_add,
                "Playlist",
                onTapCustom: () async {
                  AssetEntity currentAsset =
                  playerService.playlist[playerService.currentIndex];

                  // àªªàª¾àª¥ àª®à«‡àª³àªµà«‹
                  String? filePath = await getFile(currentAsset);

                  if (filePath != null) {
                    addToPlaylist(
                      MediaItem(
                        path: filePath,
                        isNetwork: false,
                        type: currentAsset.type == AssetType.audio
                            ? "audio"
                            : "video",
                        id: currentAsset.id,
                        isFavourite: currentAsset.isFavorite,
                      ),
                      context,
                    );
                  } else {
                    AppToast.show(
                      context,
                      "File not found or deleted",
                      type: ToastType.error,
                    );

                    setState(() {
                      playerService.playlist.removeAt(
                        playerService.currentIndex,
                      );
                    });
                  }
                },
              ),
              _menuGridItem(
                Icons.info_outline,
                "Info",
                onTapCustom: () {
                  showInfoDialog(
                    context,
                    playerService.playlist[playerService.currentIndex],
                  );
                },
              ),
              _menuGridItem(
                Icons.share,
                "Share",
                onTapCustom: () {
                  shareItem(
                    context,
                    playerService.playlist[playerService.currentIndex],
                  );
                },
              ),
              _menuGridItem(
                Icons.language,
                "Stream",
                onTapCustom: () {
                  _showNetworkStreamDialog();
                },
              ),
              // _menuGridItem(Icons.help_outline, "Tutorial"),
              _menuGridItem(
                Icons.more_horiz,
                "More",
                onTapCustom: () {
                  setState(() => _isMoreMenuVisible = true);
                },
              ),
            ],
          ),

          const Divider(color: Colors.white24),

          // --- Shortcuts Switch ---
          SwitchListTile(
            title: const Text(
              "Shortcuts",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            value: _showShortcutsInMenu,
            activeColor: Color(0XFF3D57F9),
            onChanged: (bool value) {
              setState(() => _showShortcutsInMenu = value);
            },
          ),

          // --- Checkbox List
          if (_showShortcutsInMenu)
            ...Provider.of<SettingsProvider>(context).quickShortcuts.keys.map((
                String key,
                ) {
              return CheckboxListTile(
                title: Text(
                  key,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                value: Provider.of<SettingsProvider>(
                  context,
                ).quickShortcuts[key],
                activeColor: Color(0XFF3D57F9),
                checkColor: Colors.white,
                onChanged: (bool? value) {
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).updateSetting(() {
                    Provider.of<SettingsProvider>(
                      context,
                      listen: false,
                    ).quickShortcuts[key] = value ?? false;
                  });
                },
              );
            }).toList(),
        ],
      ),
    );
  }

  Future<String?> getFile(AssetEntity entity) async {
    try {
      File? file = await entity.file;
      if (file != null && await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint("Error getting file path: $e");
      return null;
    }
  }

  Widget _buildMoreCategoryMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TOOLS",
            style: TextStyle(
              color: Color(0XFF3D57F9),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _textButtonItem("Delete", () async {
            int currentIndex = playerService.currentIndex;

            bool? isDeleted = await deleteCurrentItem(
              context,
              playerService.playlist[currentIndex],
            );

            if (isDeleted == true) {
              setState(() {
                playerService.playlist.removeAt(currentIndex);

                if (playerService.playlist.isEmpty) {
                  Navigator.pop(context);
                  return;
                }

                if (currentIndex >= playerService.playlist.length) {
                  playerService.currentIndex =
                      playerService.playlist.length - 1;
                }

                playerService.loadVideo(() {
                  if (mounted) setState(() {});
                });
              });

              context.read<VideoBloc>().add(
                LoadVideosFromGallery(showLoading: false),
              );
            }
          }),
          if (Platform.isAndroid) ...[
            _textButtonItem("Rename", () async {
              AssetEntity currentAsset =
              playerService.playlist[playerService.currentIndex];

              if (Platform.isAndroid) {
                String oldName = currentAsset.title ?? "video";
                String extension = oldName.contains('.')
                    ? oldName.split('.').last
                    : "mp4";
                String fileNameWithoutExtension = oldName.contains('.')
                    ? oldName.substring(0, oldName.lastIndexOf('.'))
                    : oldName;

                TextEditingController _renameController = TextEditingController(
                  text: fileNameWithoutExtension,
                );

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Rename Video"),
                    content: TextField(
                      controller: _renameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: "Enter new name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          String newTitle = _renameController.text.trim();
                          if (newTitle.isEmpty) return;

                          Navigator.pop(context);

                          File? originalFile = await currentAsset.file;
                          if (originalFile != null) {
                            try {
                              const editChannel = MethodChannel(
                                'media_player/editor',
                              );

                              // Native Android Method Call
                              final bool isSuccess = await editChannel
                                  .invokeMethod('renameVideo', {
                                'path': originalFile.path,
                                'newName': newTitle,
                                'isFavourite': currentAsset.isFavorite,
                              });

                              if (isSuccess) {
                                AssetEntity? updatedAsset =
                                await AssetEntity.fromId(currentAsset.id);

                                if (updatedAsset != null) {
                                  setState(() {
                                    playerService.playlist[playerService
                                        .currentIndex] =
                                        updatedAsset;
                                  });
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Video renamed successfully!",
                                    ),
                                  ),
                                );
                              } else {
                                print("Rename Failed or Cancelled by User");
                              }
                            } catch (e) {
                              print("Native Error: $e");
                            }
                          }
                        },
                        child: const Text("Rename"),
                      ),
                    ],
                  ),
                );
              } else if (Platform.isIOS) {
                await PhotoManager.editor.darwin.favoriteAsset(
                  entity: currentAsset,
                  favorite: true,
                );

                /*
                File? file = await currentAsset.file;
                if (file != null) {
                    await PhotoManager.editor.saveVideo(
                    file,
                    title: "New_Name.mp4",
                 );
                   }
              */

                // await currentAsset.refresh();
                setState(() {});
              }
            }),
          ],
          _textButtonItem("Lock", () {}),
          _textButtonItem("Settings", () {}),

          const SizedBox(height: 30),

          const Text(
            "HELP",
            style: TextStyle(
              color: Color(0XFF3D57F9),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _textButtonItem("FAQ", () {}),
          _textButtonItem("About", () {}),
        ],
      ),
    );
  }

  Widget _textButtonItem(String title, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _menuGridItem(
      IconData icon,
      String title, {
        VoidCallback? onTapCustom,
      }) {
    return InkWell(
      onTap: onTapCustom ?? () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showMoreOptionsBottomSheet() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.grey[900],
        shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
    return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Category 1: Tools
    const Text(
    "Tools",
    style: TextStyle(
    color: Color(0XFF3D57F9),
    fontWeight: FontWeight.bold,
    fontSize: 16,
    ),
    ),
    const SizedBox(height: 10),
    Wrap(
    spacing: 10,
    children: [
    TextButton.icon(
    onPressed: () {},
    icon: const Icon(Icons.delete_outline, color: Colors.white),
    label: const Text(
    "Delete",
    style: TextStyle(color: Colors.white),
    ),
    ),
    TextButton.icon(
    onPressed: () {},
    icon: const Icon(Icons.edit_outlined, color: Colors.white),
    label: const Text(
    "Rename",
    style: TextStyle(color: Colors.white),
    ),
    ),
    TextButton.icon(
    onPressed: () {},
    icon: const Icon(Icons.lock_outline, color: Colors.white),
    label: const Text(
    "Lock",
    style: TextStyle(color: Colors.white),
    ),
    ),
    TextButton.icon(
    onPressed: () {},
    icon: const Icon(Icons.settings, color: Colors.white),
    label: const Text(
    "Settings",
    style: TextStyle(color: Colors.white),
    ),
    ),
    ],
    ),
    const Divider(color: Colors.white24, height: 30),

    // Category 2: Help
    const Text(
    "Help",
    style: TextStyle(
    color: Color(0XFF3D57F9),
    fontWeight: FontWeight.bold,
    fontSize: 16,
    ),
    ),
    const SizedBox(height: 10),
    Wrap(
    spacing: 10,
    children: [
    TextButton.icon(
    onPressed: () {},
    icon: const Icon(
    Icons.question_answer_outlined,
    color: Colors.white,
    ),
      //////////////////////////////////////////////////////////////////////// part 5 new player scareen//////////////////////////////////////////////////////////
      label: const Text(
        "FAQ",
        style: TextStyle(color: Colors.white),
      ),
    ),
      TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.info_outline, color: Colors.white),
        label: const Text(
          "About",
          style: TextStyle(color: Colors.white),
        ),
      ),
    ],
    ),
      const SizedBox(height: 20),
    ],
    ),
    );
    },
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
              src: playerService.isVideoPlaying
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
    final settings = Provider.of<SettingsProvider>(context);
    final playedColor = settings.progressBarCategory == "Flat"
        ? settings.progressBarColor.withOpacity(0.8)
        : settings.progressBarColor;

    Widget buildProgressBar() {
      return Row(
        children: [
          Text(
            _formatDuration(playerService.currentPosition),
            style: TextStyle(color: settings.controlsColor, fontSize: 12),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: VideoProgressIndicator(
                _playerController,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 10),
                colors: VideoProgressColors(
                  playedColor: playedColor,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
          ),
          Text(
            settings.showRemainingTime
                ? "-${_formatDuration(playerService.totalDuration - playerService.currentPosition)}"
                : _formatDuration(playerService.totalDuration),
            style: TextStyle(color: settings.controlsColor, fontSize: 12),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isLocked && !settings.isProgressBarBelow) buildProgressBar(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LOCK BUTTON
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => setState(() {
                  _isLocked = !_isLocked;
                  _kidsLockSequence.clear();
                  if (!_isLocked) _startControlsTimer();
                }),
              ),

              // MIDDLE CONTROLS (Only if not locked)
              if (!_isLocked)
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (settings.forwardBackwardButton)
                          IconButton(
                            onPressed: () => playerService.seekBy(
                              Duration(seconds: -settings.moveInterval.round()),
                            ),
                            icon: const Icon(
                              Icons.replay_10,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        if (settings.previousNextButton)
                          _buildCircularButton(
                            icon: AppSvg.skipPrev,
                            onPressed: () => playerService.playPrevious(
                                  () => setState(() {}),
                            ),
                          ),

                        const SizedBox(width: 15),

                        GestureDetector(
                          onTap: () {
                            playerService.togglePlay();
                            _startControlsTimer();
                            setState(() {});
                          },
                          child: AppImage(
                            src: playerService.isVideoPlaying
                                ? AppSvg.pauseVid
                                : AppSvg.playVid,
                            height: 48,
                            width: 48,
                          ),
                        ),

                        const SizedBox(width: 15),

                        if (settings.previousNextButton)
                          _buildCircularButton(
                            icon: AppSvg.skipNext,
                            onPressed: () =>
                                playerService.playNext(() => setState(() {})),
                          ),
                        if (settings.forwardBackwardButton)
                          IconButton(
                            onPressed: () => playerService.seekBy(
                              Duration(seconds: settings.moveInterval.round()),
                            ),
                            icon: const Icon(
                              Icons.forward_10,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // RIGHT SIDE BUTTONS (Fit & PiP)
              if (!_isLocked)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _getFitIcon(_videoFit),
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_videoFit == BoxFit.contain)
                            _videoFit = BoxFit.cover;
                          else if (_videoFit == BoxFit.cover)
                            _videoFit = BoxFit.fill;
                          else if (_videoFit == BoxFit.fill)
                            _videoFit = BoxFit.none;
                          else
                            _videoFit = BoxFit.contain;
                          _overlayText = _getFitText(_videoFit);
                        });
                        _overlayTextTimer?.cancel();
                        _overlayTextTimer = Timer(
                          const Duration(seconds: 2),
                              () {
                            if (mounted) setState(() => _overlayText = null);
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 5),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.picture_in_picture_alt_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: _enterPictureInPicture,
                    ),
                  ],
                ),
            ],
          ),

          if (!_isLocked && settings.isProgressBarBelow) buildProgressBar(),

          const SizedBox(height: 12),
          // Bottom spacing
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
    final currentPos = playerService.currentPosition;
    if (_pointA == null) {
      _pointA = currentPos;
      AppToast.show(context, "Point A Set");
    } else if (_pointB == null) {
      _pointB = currentPos;
      AppToast.show(context, "Point B Set. Repeating A-B");
      playerService.addVideoListener(_checkABRepeat);
    } else {
      _pointA = null;
      _pointB = null;
      playerService.removeVideoListener(_checkABRepeat);
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

                // _buildSettingsTile(
                //   icon: Icons.aspect_ratio_rounded,
                //   title: "Aspect Ratio",
                //   value: _getFitText(_videoFit),
                //   onTap: () {
                //     Navigator.pop(context);
                //     // ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¹ÃƒÆ’ Ãƒâ€šÃ‚Â«ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¤ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â®ÃƒÆ’ Ãƒâ€šÃ‚Â«ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¡ Aspect Ratio ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¬ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¦ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â²ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚ÂµÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¾ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¨ÃƒÆ’ Ãƒâ€šÃ‚Â«Ãƒâ€šÃ‚ÂÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â«ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ÃƒÆ’ Ãƒâ€šÃ‚Â«Ãƒâ€šÃ‚ÂÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¶ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¨ ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ÃƒÆ’ Ãƒâ€šÃ‚Â«ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¹ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â² ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â°ÃƒÆ’ Ãƒâ€šÃ‚Â«ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¶ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ÃƒÆ’ Ãƒâ€šÃ‚Â«ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¹
                //   },
                // ),
                //
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
                color: Color(0XFF3D57F9),
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
            child: SingleChildScrollView(
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
                          bool isSelected =
                              playerService.playbackSpeed == speed;
                          return ListTile(
                            onTap: () {
                              _changeSpeed(speed);
                              Navigator.pop(context);
                            },
                            leading: Icon(
                              Icons.check_circle_rounded,
                              color: isSelected
                                  ? Color(0XFF3D57F9)
                                  : Colors.transparent,
                              size: 20,
                            ),
                            title: Text(
                              "${speed}x",
                              style: TextStyle(
                                color: isSelected
                                    ? Color(0XFF3D57F9)
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
          ),
        );
      },
    );
  }

  void _changeSpeed(double speed) async {
    await playerService.setPlaybackSpeed(speed);
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

  void _showOverlayMessage(String message, String icon) {
    setState(() {
      _overlayText = message;
      sign = icon;
    });

    _overlayTextTimer?.cancel();
    _overlayTextTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _overlayText = null;
          sign = null;
        });
      }
    });
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  void _playTrimmedVideo(String path) async {
    try {
      final currentPos = playerService.currentPosition.inMilliseconds;
      await playerService.loadExternalFilePath(path, () {
        if (!mounted) return;
        setState(() {});
        _checkVideoEnd();
      }, seekToMs: currentPos);
    } catch (e) {
      debugPrint("Error loading trimmed video: $e");
    }
  }

  void _showDisplaySettings(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent, // àª•àª¾àªš àªœà«‡àªµà«€ àª…àª¸àª° àª®àª¾àªŸà«‡
        builder: (context) {
      return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
    child: DefaultTabController(
    length: 6,
    child: Container(
    height: MediaQuery.of(context).size.height * 0.80,
    decoration: BoxDecoration(
    color: const Color(0XFF0A0A0A).withOpacity(0.85),
    // Deep Dark Glass
    borderRadius: const BorderRadius.vertical(
    top: Radius.circular(35),
    ),
    border: Border.all(
    color: Colors.white.withOpacity(0.1),
    width: 1,
    ),
    ),
    child: Column(
    children: [
    // --- Handle Bar ---
    const SizedBox(height: 12),
    Container(
    width: 50,
    height: 5,
    decoration: BoxDecoration(
    color: Colors.white12,
    borderRadius: BorderRadius.circular(10),
    ),
    ),

    // --- Header ---
    Padding(
    padding: const EdgeInsets.fromLTRB(25, 10, 15, 10),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    const Text(
    "Settings",
    style: TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
    ),
    ),
    IconButton(
    onPressed: () => Navigator.pop(context),
    icon: const Icon(
    Icons.close_rounded,
    color: Colors.white70,
    ),
    style: IconButton.styleFrom(
    backgroundColor: Colors.white.withOpacity(0.05),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15),
    ),
    ),
    ),
    ],
    ),
    ),

    // --- Floating Modern Tab Bar ---
    Container(
    height: 38,
    margin: const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 8,
    ),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(12),
    ),
    child: TabBar(
    isScrollable: true,
    tabAlignment: TabAlignment.start,
    dividerColor: Colors.transparent,
    indicatorSize: TabBarIndicatorSize.tab,

    indicator: BoxDecoration(
    color: const Color(0XFF3D57F9),
    borderRadius: BorderRadius.circular(8),
    ),

    labelPadding: const EdgeInsets.symmetric(horizontal: 16),

    labelColor: Colors.white,
    unselectedLabelColor: Colors.white38,

    // àª«à«‹àª¨à«àªŸ àª¸àª¾àªˆàª à«§à«¨-à«§à«© àª°àª¾àª–àªµà«€ àªœà«‡àª¥à«€ àª®à«‹àªŸà«àª‚ àª¨àª¾ àª²àª¾àª—à«‡
    labelStyle: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 12.5,
    letterSpacing: 0.3,
    ),
    unselectedLabelStyle: const TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 12.5,
    ),

    tabs: const [
    Tab(text: "Style"),
    Tab(text: "Screen"),
    Tab(text: "Controls"),
    Tab(text: "Navigation"),
    Tab(text: "Text"),
    Tab(text: "Layout"),
    ],
    ),
    ),

    const SizedBox(height: 15),

    // --- Content Area ---
    Expanded(
    child: ClipRRect(
    borderRadius: const BorderRadius.vertical(
    top: Radius.circular(30),
    ),
    child: Container(
    color: Colors.black26,
    child: TabBarView(
    physics: const BouncingScrollPhysics(),
    children: [
    Consumer<SettingsProvider>(
    builder: (_, s, __) => _styleTab(s),
    ),

    BlocProvider(
    create: (ctx) => ScreenSettingsBloc(
    Provider.of<SettingsProvider>(
    context,
    listen: false,
    ),
    ),
    child:
    BlocConsumer<
    ScreenSettingsBloc,
    ScreenSettingsState
    >(//////////////////////////////////////////////////////////////////////// part 6 new player scareen//////////////////////////////////////////////////////////
      listener: (_, state) =>
          _applyScreenState(state),
      builder: (blocContext, state) =>
          _screenTabBloc(
            state,
            blocContext
                .read<ScreenSettingsBloc>(),
          ),
    ),
    ),

      Consumer<SettingsProvider>(
        builder: (_, s, __) => _controlsTab(s),
      ),
      Consumer<SettingsProvider>(
        builder: (_, s, __) => _navigationTab(s),
      ),
      Consumer<SettingsProvider>(
        builder: (_, s, __) => _textTab(s),
      ),
      Consumer<SettingsProvider>(
        builder: (_, s, __) => _layoutTab(s),
      ),
    ],
    ),
    ),
    ),
    ),
    ],
    ),
    ),
    ),
      );
        },
    );
  }

  /// Enters system Picture-in-Picture. No extra permission dialog: Android PiP
  /// does not use "display over other apps"; that text was misleading and forced
  /// Allow/Cancel on every tap.
  Future<void> _enterPictureInPicture() async {
    if (Platform.isAndroid) {
      try {
        final supported = await playerService.isPipSupported();
        if (!supported) {
          AppToast.show(
            context,
            "PiP is not supported on this Android version",
          );
          return;
        }
        final entered = await playerService.enterPipMode();
        if (!entered) {
          AppToast.show(
            context,
            "Unable to enter PiP mode",
            type: ToastType.error,
          );
        }
      } catch (_) {
        AppToast.show(context, "PiP error", type: ToastType.error);
      }
    } else if (Platform.isIOS) {
      try {
        final supported = await playerService.isPipSupported();
        if (!supported) {
          AppToast.show(context, "PiP is not supported on this iOS device");
          return;
        }
        final entered = await playerService.enterPipMode();
        if (!entered) {
          AppToast.show(
            context,
            "PiP is currently unavailable with current iOS playback backend",
          );
        }
      } catch (_) {
        AppToast.show(context, "PiP error", type: ToastType.error);
      }
    }
  }

  void _showEqualizerBottomSheet(SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (_, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Equalizer",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text(
                        settings.equalizerEnabled ? "On" : "Off",
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: settings.equalizerEnabled,
                      onChanged: (v) {
                        settings.updateSetting(
                              () => settings.equalizerEnabled = v,
                        );
                        _applyEqualizerSettings(settings);
                        setSheetState(() {});
                      },
                      activeColor: Color(0XFF3D57F9),
                    ),
                    _buildDropdown(
                      "Reverb",
                      const [
                        "None",
                        "Small Room",
                        "Medium Room",
                        "Large Room",
                        "Medium Hall",
                        "Large Hall",
                        "Plate",
                      ],
                      settings.equalizerReverb,
                          (v) {
                        if (!settings.equalizerEnabled || v == null) return;
                        settings.updateSetting(
                              () => settings.equalizerReverb = v,
                        );
                        _applyEqualizerSettings(settings);
                        setSheetState(() {});
                      },
                    ),
                    _buildSlider(
                      "Bass Boost (%)",
                      0,
                      100,
                      settings.equalizerBassBoost,
                      settings.equalizerEnabled
                          ? (v) {
                        settings.updateSetting(
                              () => settings.equalizerBassBoost = v,
                        );
                        _applyEqualizerSettings(settings);
                        setSheetState(() {});
                      }
                          : (_) {},
                    ),
                    _buildSlider(
                      "Virtualizer (%)",
                      0,
                      100,
                      settings.equalizerVirtualizer,
                      settings.equalizerEnabled
                          ? (v) {
                        settings.updateSetting(
                              () => settings.equalizerVirtualizer = v,
                        );
                        _applyEqualizerSettings(settings);
                        setSheetState(() {});
                      }
                          : (_) {},
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _applyEqualizerSettings(SettingsProvider settings) async {
    try {
      await _equalizerChannel.invokeMethod("setEnabled", {
        "enabled": settings.equalizerEnabled,
      });
      if (!settings.equalizerEnabled) return;
      await _equalizerChannel.invokeMethod("setReverb", {
        "value": settings.equalizerReverb,
      });
      await _equalizerChannel.invokeMethod("setBassBoost", {
        "value": settings.equalizerBassBoost,
      });
      await _equalizerChannel.invokeMethod("setVirtualizer", {
        "value": settings.equalizerVirtualizer,
      });
    } catch (_) {
      // ignore platform-specific errors
    }
  }

  Widget _controlsTab(SettingsProvider s) {
    final gestureItems = s.gestures.keys.toList();
    final shortcutItems = s.quickShortcuts.keys.toList();

    return RawScrollbar(
      // thumbColor: const Color(0XFF3D57F9).withOpacity(0.3),
      thickness: 4,
      radius: const Radius.circular(10),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          // --- 1. Interaction (Dropdowns) ---
          _buildAttractiveHeader(Icons.touch_app_rounded, "Interaction"),
          _buildSettingsCard(
            child: Column(
              children: [
                _buildDropdown(
                  "Touch Action",
                  [
                    "Show Interface -> Pause/Resume",
                    "Show interface + pause/resume",
                    "Pause/resume",
                    "Show/hide interface",
                  ],
                  s.touchAction,
                      (v) => s.updateSetting(() => s.touchAction = v!),
                ),
                const Divider(color: Colors.white10, height: 25),
                _buildDropdown(
                  "Lock Mode",
                  ["Lock", "Kids lock", "Kids lock (+Touch effects)"],
                  s.lockMode,
                      (v) => s.updateSetting(() => s.lockMode = v!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // --- 2. Gestures Grid ---
          _buildAttractiveHeader(Icons.gesture_rounded, "Gestures"),
          _buildSettingsCard(
            padding: const EdgeInsets.all(12), // àª—à«àª°à«€àª¡ àª®àª¾àªŸà«‡ àª¥à«‹àª¡à«€ àª“àª›à«€ àªªà«‡àª¡àª¿àª‚àª—
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gestureItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5, // à«¨ àª²àª¾àª‡àª¨àª¨àª¾ àªŸà«‡àª•à«àª¸à«àªŸ àª®àª¾àªŸà«‡ àª¬à«‡àª¸à«àªŸ àª°à«‡àª¶àª¿àª¯à«‹
                mainAxisSpacing: 8,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final item = gestureItems[index];
                return _buildCustomCheckbox(
                  item,
                  s.gestures[item] ?? true,
                  _isGestureCheckboxEnabled(s, item)
                      ? (v) => _onGestureItemChanged(s, item, v)
                      : null,
                );
              },
            ),
          ),

          const SizedBox(height: 25),

          // --- 3. Quick Shortcuts Grid ---
          _buildAttractiveHeader(Icons.flash_on_rounded, "Quick Shortcuts"),
          _buildSettingsCard(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shortcutItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final item = shortcutItems[index];
                return _buildCustomCheckbox(
                  item,
                  s.quickShortcuts[item] ?? true,
                  _isGestureCheckboxEnabled(s, item)
                      ? (v) => _onGestureItemChanged(s, item, v)
                      : null,
                );
              },
            ),
          ),

          const SizedBox(height: 25),

          // --- 4. Interface Behavior ---
          _buildAttractiveHeader(Icons.vignette_rounded, "Interface Behavior"),
          _buildSettingsCard(
            child: Column(
              children: [
                _buildCustomCheckbox(
                  "Interface auto hide",
                  s.controlsInterfaceAutoHideEnabled,
                      (v) => s.updateSetting(
                        () => s.controlsInterfaceAutoHideEnabled = v ?? true,
                  ),
                ),
                if (s.controlsInterfaceAutoHideEnabled) ...[
                  const SizedBox(height: 15),
                  _buildSlider(
                    "Hide Interval (sec)",
                    1,
                    60,
                    s.interfaceAutoHide,
                        (v) => s.updateSetting(() => s.interfaceAutoHide = v),
                  ),
                ],
                const Divider(color: Colors.white10, height: 30),
                _buildCustomCheckbox(
                  "Show interface when locked screen is touched",
                  s.showInterfaceWhenLockedTouched,
                      (v) => s.updateSetting(
                        () => s.showInterfaceWhenLockedTouched = v ?? true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCheckbox(
      String title,
      bool value,
      ValueChanged<bool?>? onChange,
      ) {
    bool isEnabled = onChange != null;
    return InkWell(
      onTap: isEnabled ? () => onChange(!value) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6), // àª¥à«‹àª¡à«€ àª‰àª­à«€ àª¸à«àªªà«‡àª¸ àª†àªªà«‹
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: value ? const Color(0XFF3D57F9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: value ? const Color(0XFF3D57F9) : Colors.white30,
                    width: 1.5,
                  ),
                ),
                child: value
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isEnabled
                      ? Colors.white.withOpacity(0.9)
                      : Colors.white24,
                  fontSize: 12.5,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navigationTab(SettingsProvider s) {
    final ScrollController _navScrollController = ScrollController();

    return RawScrollbar(
      controller: _navScrollController,
      // thumbColor: const Color(0XFF3D57F9).withOpacity(0.3),
      thickness: 4,
      radius: const Radius.circular(10),
      child: ListView(
        controller: _navScrollController,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          // --- 1. Seeking & Speed Settings ---
          _buildAttractiveHeader(Icons.fast_forward_rounded, "Seek Behavior"),
          _buildSettingsCard(
            child: Column(
              children: [
                _buildSlider(
                  "Seek Speed (sec/cm)",
                  2,
                  400,
                  s.seekSpeed,
                      (v) => s.updateSetting(() => s.seekSpeed = v),
                ),
                const Divider(color: Colors.white10, height: 30),
                _buildCustomCheckbox(
                  "Display current position while seeking",
                  s.displayCurrentPositionWhileChanging,
                      (v) => s.updateSetting(
                        () => s.displayCurrentPositionWhileChanging = v ?? true,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // --- 2. Navigation Buttons Control ---
          _buildAttractiveHeader(
            Icons.play_circle_outline_rounded,
            "Playback Buttons",
          ),
          _buildSettingsCard(
            child: Column(
              children: [
                _buildCustomCheckbox(
                  "Forward/Backward Buttons",
                  s.forwardBackwardButton,
                      (v) => s.updateSetting(
                        () => s.forwardBackwardButton = v ?? true,
                  ),
                ),
                if (s.forwardBackwardButton) ...[
                  const SizedBox(height: 15),
                  _buildSlider(
                    "Move Interval (sec)",
                    1,
                    60,
                    s.moveInterval,
                        (v) => s.updateSetting(() => s.moveInterval = v),
                  ),
                ],
                const Divider(color: Colors.white10, height: 30),
                _buildCustomCheckbox(
                  "Previous/Next Buttons",
                  s.previousNextButton,
                      (v) =>
                      s.updateSetting(() => s.previousNextButton = v ?? true),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "Note: Seek speed affects how fast the video moves when swiping on the screen.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textTab(SettingsProvider s) {
    return Material(
      color: Colors.transparent,
      child: RawScrollbar(
        thickness: 4,
        radius: const Radius.circular(10),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          physics: const BouncingScrollPhysics(),
          children: [
            // --- 1. Typography (Font & Size) ---
            _buildAttractiveHeader(Icons.text_fields_rounded, "Typography"),
            _buildSettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdown(
                    "Font Family",
                    [
                      "Select Font Folder",
                      "Default",
                      "Mono",
                      "Sans Serif",
                      "Serif",
                    ],
                    s.font,
                        (v) => s.updateSetting(() => s.font = v!),
                  ),
                  const Divider(color: Colors.white10, height: 30),
                  _buildSlider(
                    "Font Size",
                    16,
                    60,
                    s.fontSize,
                        (v) => s.updateSetting(() => s.fontSize = v),
                  ),
                  const SizedBox(height: 15),
                  _buildSlider(
                    "Text Scale (%)",
                    50,
                    400,
                    s.textScale,
                        (v) => s.updateSetting(() => s.textScale = v),
                  ),
                  const Divider(color: Colors.white10, height: 30),

                  // Color & Bold - Wrap prevents "RenderBox was not laid out"
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 170,
                        child: _buildColorTile(
                          "Text Color",
                          s.textColor,
                          onPick: (c) => s.updateSetting(() => s.textColor = c),
                        ),
                      ),
                      _buildCustomCheckbox(
                        "Bold Text",
                        s.isBold,
                            (v) => s.updateSetting(() => s.isBold = v!),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- 2. Text Effects (Background & Border) ---
            _buildAttractiveHeader(Icons.layers_outlined, "Visual Effects"),
            _buildSettingsCard(
              child: Column(
                children: [
                  _buildColorTileRow(
                    "Background",
                    s.subtitleBackgroundEnabled,
                    s.subtitleBackgroundColor,
                    onCheck: (v) => s.updateSetting(
                          () => s.subtitleBackgroundEnabled = v ?? false,
                    ),
                    onPick: (c) =>
                        s.updateSetting(() => s.subtitleBackgroundColor = c),
                  ),
                  const Divider(color: Colors.white10, height: 25),
                  _buildColorTileRow(
                    "Border/Stroke",
                    s.hasBorder,
                    s.borderColor,
                    onCheck: (v) => s.updateSetting(() => s.hasBorder = v!),
                    onPick: (c) => s.updateSetting(() => s.borderColor = c),
                  ),
                  if (s.hasBorder) ...[
                    const SizedBox(height: 15),
                    _buildSlider(
                      "Border Width",
                      50,
                      300,
                      s.borderSize,
                          (v) => s.updateSetting(() => s.borderSize = v),
                    ),
                    _buildCustomCheckbox(
                      "Improve stroke rendering",
                      s.improveStrokeRendering,
                          (v) => s.updateSetting(
                            () => s.improveStrokeRendering = v ?? true,
                      ),
                    ),
                  ],
                  const Divider(color: Colors.white10, height: 25),

                  // Effects Wrap
                  Wrap(
                    spacing: 20,
                    runSpacing: 10,
                    children: [
                      _buildCustomCheckbox(
                        "Shadow",
                        s.shadowEnabled,
                            (v) =>
                            s.updateSetting(() => s.shadowEnabled = v ?? true),
                      ),
                      _buildCustomCheckbox(
                        "Fade out",
                        s.fadeOutEnabled,
                            (v) => s.updateSetting(
                              () => s.fadeOutEnabled = v ?? false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- 3. Advanced Rendering (SSA/ASS) ---
            _buildAttractiveHeader(
              Icons.high_quality_rounded,
              "Advanced Rendering",
            ),
            _buildSettingsCard(
              child: Column(
                children: [
                  _buildCustomCheckbox(
                    "Improve SSA rendering",
                    s.improveSsaRendering,
                        (v) => s.updateSetting(
                          () => s.improveSsaRendering = v ?? true,
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  _buildCustomCheckbox(
                    "Complex scripts rendering",
                    s.improveComplexScriptRendering,
                        (v) => s.updateSetting(
                          () => s.improveComplexScriptRendering = v ?? true,
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  _buildCustomCheckbox(
                    "Ignore SSA font specifications",
                    s.ignoreSsaFont,
                        (v) => s.updateSetting(() => s.ignoreSsaFont = v ?? false),
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  _buildCustomCheckbox(
                    "Ignore broken SSA fonts (Exp.)",
                    s.ignoreBrokenSsaFonts,
                        (v) => s.updateSetting(
                          () => s.ignoreBrokenSsaFonts = v ?? false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _layoutTab(SettingsProvider s) {
    return Material(
      color: Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          // --- 1. Positioning & Alignment ---
          _buildAttractiveHeader(Icons.layers_outlined, "Positioning"),
          _buildSettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdown(
                  "Text Alignment",
                  ["Left", "Center", "Right"],
                  s.layoutAlignment,
                      (v) => s.updateSetting(() => s.layoutAlignment = v!),
                ),
                const Divider(color: Colors.white10, height: 30),

                // Bottom Margins Slider
                _buildSlider(
                  "Bottom Margin",
                  0,
                  150,
                  s.bottomMargins,
                      (v) => s.updateSetting(() => s.bottomMargins = v),
                ),

                const SizedBox(height: 10),

                // Fit Subtitles Checkbox
                _buildCustomCheckbox(
                  "Fit subtitles into video size",
                  s.fitSubtitlesIntoVideoSize,
                      (v) => s.updateSetting(
                        () => s.fitSubtitlesIntoVideoSize = v ?? true,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // --- 2. Layout Background ---
          _buildAttractiveHeader(Icons.fullscreen_rounded, "Layout Background"),
          _buildSettingsCard(
            child: Column(
              children: [
                // Background Toggle & Color Row using Wrap for safety
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Toggle Checkbox
                    _buildCustomCheckbox(
                      "Enable Background",
                      s.layoutBackgroundEnabled,
                          (v) => s.updateSetting(
                            () => s.layoutBackgroundEnabled = v ?? false,
                      ),
                    ),

                    // Color Picker (Only visible/active if enabled)
                    if (s.layoutBackgroundEnabled)
                      SizedBox(
                        width: 160,
                        child: _buildColorTile(
                          "BG Color",
                          s.layoutBackgroundColor,
                          onPick: (c) => s.updateSetting(
                                () => s.layoutBackgroundColor = c,
                          ),
                        ),
                      ),
                  ],
                ),

                if (s.layoutBackgroundEnabled) ...[
                  const Divider(color: Colors.white10, height: 30),
                  const Text(
                    "This adds a solid backdrop behind the entire subtitle area.",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 25),

          // --- 3. Additional Info (Optional) ---
          Center(
            child: Text(
              "Changes are applied in real-time",
              style: TextStyle(
                color: Colors.white24,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _styleTab(SettingsProvider s) {
    final ScrollController _styleScrollController = ScrollController();

    return Material(
        color: Colors.transparent,
        child: RawScrollbar(
        controller: _styleScrollController,
        thumbColor: const Color(0XFF3D57F9).withOpacity(0.6),
    // àª¤àª®àª¾àª°à«‹ àª¥à«€àª® àª•àª²àª°
    thickness: 4,
    radius: const Radius.circular(10),
    fadeDuration: const Duration(milliseconds: 500),
    timeToFade: const Duration(milliseconds: 1000),
    child: ListView(
    controller: _styleScrollController,
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
    physics: const BouncingScrollPhysics(),
    children: [//////////////////////////////////////////////////////////////////////// part 7 new player scareen//////////////////////////////////////////////////////////

      // --- 1. Appearance  ---
      _buildAttractiveHeader(Icons.auto_awesome_rounded, "Appearance"),
      _buildSettingsCard(
        child: Column(
          children: [
            _buildDropdown(
              "Preset Style",
              ["Default", "Inverse"],
              s.present,
                  (v) => s.updateSetting(() => s.present = v!),
            ),
            const Divider(color: Colors.white10, height: 30),
            _buildSwitch(
              "Visual Frame",
              s.isFrameEnabled,
                  (v) => s.updateSetting(() => s.isFrameEnabled = v),
            ),
          ],
        ),
      ),

      const SizedBox(height: 25),

      // --- 2. Themes & Colors ---
      _buildAttractiveHeader(Icons.palette_rounded, "Themes & Colors"),
      _buildSettingsCard(
        child: Column(
          children: [
            _buildColorTile(
              "Controls Accent",
              s.controlsColor,
              onPick: (c) => s.updateSetting(() => s.controlsColor = c),
            ),
            const Divider(color: Colors.white10, height: 20),
            _buildColorTile(
              "Background Shade",
              s.controlsBgColor,
              onPick: (c) => s.updateSetting(() => s.controlsBgColor = c),
            ),
            const Divider(color: Colors.white10, height: 20),
            _buildColorTile(
              "Progress Bar Tint",
              s.progressBarColor,
              onPick: (c) =>
                  s.updateSetting(() => s.progressBarColor = c),
            ),
          ],
        ),
      ),

      const SizedBox(height: 25),

      // --- 3. Progress Bar Settings ---
      _buildAttractiveHeader(
        Icons.slow_motion_video_rounded,
        "Progress Bar",
      ),
      _buildSettingsCard(
        child: Column(
          children: [
            _buildDropdown(
              "UI Category",
              ["Material", "Flat"],
              s.progressBarCategory,
                  (v) => s.updateSetting(() => s.progressBarCategory = v!),
            ),
            const Divider(color: Colors.white10, height: 30),
            _buildCustomCheckbox(
              "Position below controls",
              s.isProgressBarBelow,
                  (v) => s.updateSetting(() => s.isProgressBarBelow = v!),
            ),
          ],
        ),
      ),

      const SizedBox(height: 20),

      // Footer Note
      Center(
        child: Text(
          "Custom themes apply to the player interface",
          style: TextStyle(color: Colors.white24, fontSize: 11),
        ),
      ),
    ],
    ),
        ),
    );
  }

  Widget _buildAttractiveHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0XFF3D57F9)),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.07),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  Widget _screenTabBloc(ScreenSettingsState s, ScreenSettingsBloc cubit) {
    return Material(
      color: Colors.transparent,
      child: RawScrollbar(
        thickness: 4.5,
        radius: const Radius.circular(10),
        interactive: true,
        child: ListView(
          primary: true,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          physics: const BouncingScrollPhysics(),
          children: [
            // --- à«§. Display & Orientation ---
            _buildAttractiveHeader(
              Icons.screen_rotation_rounded,
              "Display & Orientation",
            ),
            _buildSettingsCard(
              child: Column(
                children: [
                  _buildDropdown(
                    "Orientation",
                    [
                      "Landscape",
                      "Reverse Landscape",
                      "Auto rotation(landscape)",
                      "Auto rotation",
                      "Use System default",
                      "Use video orientation",
                    ],
                    s.orientation,
                        (v) => v != null ? cubit.updateOrientation(v) : null,
                  ),
                  const Divider(color: Colors.white10, height: 25),
                  _buildDropdown(
                    "Full Screen Mode",
                    ["On", "Off", "Auto Switch"],
                    s.fullScreenMode,
                        (v) => v != null ? cubit.updateFullScreenMode(v) : null,
                  ),
                  const Divider(color: Colors.white10, height: 25),
                  _buildDropdown(
                    "Soft Buttons",
                    ["Show", "Hide", "Auto hide"],
                    s.softButtonsMode,
                        (v) => v != null ? cubit.updateSoftButtonsMode(v) : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- 2. Brightness Control ---
            _buildAttractiveHeader(Icons.wb_sunny_rounded, "Brightness"),
            _buildSettingsCard(
              child: Column(
                children: [
                  _buildSwitch(
                    "Enable Brightness Control",
                    s.isBrightnessEnabled,
                        (v) => cubit.updateBrightnessEnabled(v),
                  ),
                  if (s.isBrightnessEnabled) ...[
                    const SizedBox(height: 15),
                    _buildSlider(
                      "Level",
                      0.1,
                      1.0,
                      s.brightness,
                          (v) => cubit.updateBrightness(v),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- 3. On-Screen Information ---
            _buildAttractiveHeader(
              Icons.info_outline_rounded,
              "On-Screen Info",
            ),
            _buildSettingsCard(
              child: Column(
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: 150,
                        child: _buildCustomCheckbox(
                          "Elapsed Time",
                          s.showElapsedTime,
                              (v) => cubit.updateShowElapsedTime(v ?? true),
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: _buildCustomCheckbox(
                          "Battery/Clock",
                          s.showBatteryClock,
                              (v) => cubit.updateShowBatteryClock(v ?? true),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 25),
                  _buildCustomCheckbox(
                    "Corner Offset",
                    s.isCornerOffsetEnabled,
                    (s.showElapsedTime || s.showBatteryClock)
                        ? (v) => cubit.updateCornerOffsetEnabled(v ?? false)
                        : null,
                  ),
                  if (s.showElapsedTime || s.showBatteryClock)
                    _buildSlider(
                      "Offset Value",
                      0,
                      150,
                      s.cornerOffset.clamp(0.0, 150.0),
                          (v) => cubit.updateCornerOffset(v),
                    ),

                  const Divider(color: Colors.white10, height: 25),

                  _buildColorTileRow(
                    "Text Background",
                    s.screenTextBackgroundEnabled,
                    s.screenTextBackgroundColor,
                    onCheck: (v) =>
                        cubit.updateScreenTextBackgroundEnabled(v ?? false),
                    onPick: cubit.updateScreenTextBackgroundColor,
                  ),
                  const SizedBox(height: 10),
                  _buildColorTileRow(
                    "Bottom Text",
                    s.screenTextPlaceAtBottom,
                    s.screenTextBottomColor,
                    onCheck: (v) =>
                        cubit.updateScreenTextPlaceAtBottom(v ?? false),
                    onPick: cubit.updateScreenTextBottomColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- 4. Advanced System Settings ---
            _buildAttractiveHeader(
              Icons.settings_suggest_rounded,
              "System & Behavior",
            ),
            _buildSettingsCard(
              child: Column(
                children: [
                  _buildCustomCheckbox(
                    "Screen rotation button",
                    s.screenRotationButton,
                        (v) => cubit.updateScreenRotationButton(v ?? true),
                  ),
                  const Divider(color: Colors.white10),
                  _buildCustomCheckbox(
                    "Battery/clock in title bar",
                    s.displayBatteryClockInTitleBar,
                        (v) => cubit.updateDisplayBatteryClockInTitleBar(v ?? true),
                  ),
                  const Divider(color: Colors.white10),
                  _buildCustomCheckbox(
                    "Show remaining time",
                    s.showRemainingTime,
                        (v) => cubit.updateShowRemainingTime(v ?? true),
                  ),
                  const Divider(color: Colors.white10),
                  _buildCustomCheckbox(
                    "Keep screen on",
                    s.keepScreenOn,
                        (v) => cubit.updateKeepScreenOn(v ?? true),
                  ),
                  const Divider(color: Colors.white10),
                  _buildCustomCheckbox(
                    "Pause if obstructed",
                    s.pausePlaybackIfObstructed,
                        (v) => cubit.updatePausePlaybackIfObstructed(v ?? false),
                  ),
                  const Divider(color: Colors.white10),
                  _buildCustomCheckbox(
                    "Interface at startup",
                    s.showInterfaceAtStartup,
                        (v) => cubit.updateShowInterfaceAtStartup(v ?? true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorTileRow(
      String title,
      bool isEnabled,
      Color color, {
        required Function(bool?) onCheck,
        required Function(Color) onPick,
      }) {
    return Row(
      children: [
        Expanded(child: _buildCustomCheckbox(title, isEnabled, onCheck)),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: isEnabled
              ? () => _openColorPicker(title, color, onPick)
              : null,
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: isEnabled ? color : Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(
                color: isEnabled ? Colors.white : Colors.white10,
                width: 1.5,
              ),
              boxShadow: isEnabled
                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]
                  : [],
            ),
            child: !isEnabled
                ? const Icon(
              Icons.lock_outline,
              size: 14,
              color: Colors.white24,
            )
                : null,
          ),
        ),
      ],
    );
  }

  void _applyOrientation(String? value) {
    switch (value) {
      case "Landscape":
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
        ]);
        break;
      case "Reverse Landscape":
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case "Auto rotation(landscape)":
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case "Auto rotation":
      case "Use System default":
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
        break;
      case "Use video orientation":
        _setOrientation(_isFullScreen);
        break;
      default:
        break;
    }
  }

  // Dropdown Widget
  Widget _buildDropdown(
      String label,
      List<String> options,
      String selectedValue,
      ValueChanged<String?> onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05), // àª†àª›à«àª‚ àª—à«àª²àª¾àª¸ àª²à«àª•
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              dropdownColor: const Color(0XFF1A1A1A),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white54,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              borderRadius: BorderRadius.circular(15),
              items: options.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  /// Label: actual slider value (not `value * 100`). Brightness-style 0.1â€“1.0 shows as percent.
  String _formatSliderLabel(double min, double max, double value) {
    if (max <= 1.0 && min >= 0.09 && min < 1.0) {
      return "${(value * 100).round()}%";
    }
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  int? _sliderDivisions(double min, double max) {
    if (max <= 1.0 && min >= 0.09 && min < 1.0) {
      return 18;
    }
    if (min != min.roundToDouble() || max != max.roundToDouble()) {
      return null;
    }
    final n = (max - min).round();
    if (n <= 0 || n > 2000) return null;
    return n;
  }

  // Slider Widget
  Widget _buildSlider(
      String title,
      double min,
      double max,
      double value,
      ValueChanged<double> onChange,
      ) {
    final double clamped = value.clamp(min, max);
    final int? divisions = _sliderDivisions(min, max);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ${_formatSliderLabel(min, max, clamped)}",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Slider(
            value: clamped,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: Color(0XFF3D57F9),
            onChanged: onChange,
          ),
        ],
      ),
    );
  }

  // Switch Widget
  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChange) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      value: value,
      onChanged: onChange,
      activeColor: Color(0XFF3D57F9),
    );
  }

  // Color Box Widget
  Widget _buildColorTile(
      String title,
      Color color, {
        ValueChanged<Color>? onPick,
        bool enabled = true,
      }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.grey,
          fontSize: 14,
        ),
      ),
      onTap: (onPick != null && enabled)
          ? () => _openColorPicker(title, color, onPick)
          : null,
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white),
        ),
      ),
    );
  }

  void _openColorPicker(
      String title,
      Color current,
      ValueChanged<Color> onPick,
      ) {
    int r = current.red;
    int g = current.green;
    int b = current.blue;
    int a = current.alpha;

    String initialHex = current.value
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, '0');
    final TextEditingController hexController = TextEditingController(
      text: initialHex,
    );

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
      return StatefulBuilder(
          builder: (context, setModalState) {
        Color selectedColor = Color.fromARGB(a, r, g, b);
        void updateHexFromPicker(Color color) {
          setModalState(() {
            r = color.red;
            g = color.green;
            b = color.blue;
            a = color.alpha;
            hexController.text = color.value
                .toRadixString(16)
                .toUpperCase()
                .padLeft(8, '0');
          });
        }

        void updatePickerFromHex(String hex) {
          String cleanHex = hex.trim().replaceFirst('#', '');
          if (cleanHex.length == 6)
            cleanHex = 'FF$cleanHex';

          if (cleanHex.length == 8) {
            try {
              int colorValue = int.parse(cleanHex, radix: 16);
              Color newCol = Color(colorValue);
              setModalState(() {
                a = newCol.alpha;
                r = newCol.red;
                g = newCol.green;
                b = newCol.blue;
              });
            } catch (e) {
            }
          }
        }

        return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    child: Container(
    padding: EdgeInsets.only(
    left: 24,
    right: 24,
    top: 12,
    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    decoration: BoxDecoration(
    color: const Color(0XFF0D0D0D).withOpacity(0.92),
    borderRadius: const BorderRadius.vertical(
    top: Radius.circular(35),
    ),
    border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: SingleChildScrollView(
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    // Handle Bar
    Container(
    width: 50,
    height: 5,
    margin: const EdgeInsets.only(bottom: 25),
    decoration: BoxDecoration(
    color: Colors.white12,
    borderRadius: BorderRadius.circular(10),
    ),
    ),

    // --- Header: Title & Interactive Hex Input ---
    Row(
    children: [
    Expanded(
    child: Text(
    title,
    style: const TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    // Hex Input Field
    Container(
    width: 130,
    height: 45,
    alignment: Alignment.center,
    decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.03),
    borderRadius: BorderRadius.circular(15),
    border: Border.all(
    color: const Color(0XFF3D57F9).withOpacity(0.3),
    width: 1.5,
    ),
    boxShadow: [
    BoxShadow(
    color: const Color(
    0XFF3D57F9,
    ).withOpacity(0.05),
    blurRadius: 10,
    spreadRadius: 1,
    ),
    ],
    ),
    child: TextField(
    controller: hexController,
    onChanged: updatePickerFromHex,
    textAlign: TextAlign.center,
    cursorColor: const Color(0XFF3D57F9),
    style: const TextStyle(
    color: Color(0XFF3D57F9),
    fontWeight: FontWeight.w800,
    fontSize: 14,
    letterSpacing: 1.5,
    fontFamily:
    'monospace',
    ),
    decoration: InputDecoration(
    hintText: "FFFFFFFF",
    hintStyle: TextStyle(
    color: Colors.white.withOpacity(0.1),
    fontSize: 12,
    ),
    border: InputBorder.none,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
    vertical: 10,
    ),
    prefixIcon: const Padding(
    padding: EdgeInsets.only(left: 12, right: 4),
    child: Text(
    "#",
    style: TextStyle(
    color: Colors.white24,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    prefixIconConstraints: const BoxConstraints(
    minWidth: 0,
    minHeight: 0,
    ),
    ),
    ),
    ),
    ],
    ),
    const SizedBox(height: 25),

    // --- Color Wheel Section ---
    Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.02),
    // shape: BoxShape.circle,
    border: Border.all(
    color: Colors.white.withOpacity(0.05),
    ),
    ),
    child: ColorPicker(
    pickerColor: selectedColor,
    onColorChanged: updateHexFromPicker,
    pickerAreaHeightPercent: 0.7,
    enableAlpha: true,
    displayThumbColor: true,
    paletteType: PaletteType.hsvWithHue,
    labelTypes: const [],
    pickerAreaBorderRadius: BorderRadius.circular(
    100,
    ), // àª¸àª°à«àª•àª² àªœà«‡àªµà«‹ àª²à«àª•
    ),
    ),

    const SizedBox(height: 30),

    // --- Modern Quick Presets ---
    Column(
    children: [
    const Text(
    "QUICK SELECT",
    style: TextStyle(
    color: Colors.white24,
    fontSize: 10,
    letterSpacing: 1.5,
    fontWeight: FontWeight.bold,
    ),
    ),
    const SizedBox(height: 15),
    Wrap(
    spacing: 15,
    runSpacing: 15,
    alignment: WrapAlignment.center,
    children: [
    _presetCircle(Colors.red, setModalState, (c) {
    updateHexFromPicker(c);
    }),
    _presetCircle(Colors.green, setModalState, (c) {
    updateHexFromPicker(c);
    }),
    _presetCircle(Colors.blue, setModalState, (c) {
    updateHexFromPicker(c);
    }),
    _presetCircle(
    const Color(0XFF3D57F9),
    setModalState,
    (c) {
    updateHexFromPicker(c);
    },
    ),
    _presetCircle(Colors.white, setModalState, (c) {
    updateHexFromPicker(c);
    }),
    _presetCircle(Colors.orange, setModalState, (c) {
    updateHexFromPicker(c);
    }),
      //////////////////////////////////////////////////////////////////////// part 8 new player scareen//////////////////////////////////////////////////////////

      _presetCircle(Colors.purple, setModalState, (c) {
        updateHexFromPicker(c);
      }),
      _presetCircle(Colors.black, setModalState, (c) {
        updateHexFromPicker(c);
      }),
    ],
    ),
    ],
    ),

      const SizedBox(height: 35),

      // --- Action Button ---
      GestureDetector(
        onTap: () {
          onPick(selectedColor);
          Navigator.pop(context);
        },
        child: Container(
          width: double.infinity,
          height: 55,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0XFF3D57F9), Color(0XFF2A40C7)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0XFF3D57F9).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Text(
            "Apply Selection",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
    ),
    ),
    ),
        );
          },
      );
        },
    );
  }

  Widget _presetCircle(
      Color color,
      StateSetter setState,
      Function(Color) onSelected,
      ) {
    return GestureDetector(
      onTap: () => onSelected(color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCompactSlider(
      String label,
      int value,
      Color color,
      ValueChanged<double> onChange,
      ) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: color,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 255,
              onChanged: onChange,
            ),
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _presetColor(
      Color color,
      StateSetter setState,
      Function(Color) onSelected,
      ) {
    return GestureDetector(
      onTap: () => setState(() => onSelected(color)),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
      ),
    );
  }

  Widget _applyButton(
      Color selectedColor,
      TextEditingController hexController,
      Function applyHex,
      ValueChanged<Color> onPick,
      ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0XFF3D57F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
      ),
      onPressed: () {
        applyHex(hexController.text);
        onPick(selectedColor);
        Navigator.pop(context);
      },
      child: const Text(
        "APPLY",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _verticalManualSlider(
      String label,
      int value,
      List<Color> gradientColors,
      ValueChanged<double> onChanged,
      bool isLandscape,
      ) {
    // Landscape àª®àª¾àª‚ àª¹àª¾àªˆàªŸ àª“àª›à«€ àª°àª¾àª–àªµà«€ àªªàª¡à«‡
    double sliderHeight = isLandscape ? 120 : 180;

    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: sliderHeight,
          width: 30,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vertical Gradient Track
              Container(
                width: 8,
                height: sliderHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: gradientColors,
                  ),
                ),
              ),
              // Rotated Slider
              RotatedBox(
                quarterTurns: 3, // àª†àª¨àª¾àª¥à«€ àª¸à«àª²àª¾àª‡àª¡àª° àª‰àª­à«àª‚ àª¥àªˆ àªœàª¶à«‡
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 0,
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 9,
                      elevation: 3,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 15,
                    ),
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: 0,
                    max: 255,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class ScreenSettingsState {
  final String orientation;
  final String fullScreenMode;
  final String softButtonsMode;
  final bool isBrightnessEnabled;
  final double brightness;
  final bool showElapsedTime;
  final bool showBatteryClock;
  final bool isCornerOffsetEnabled;
  final double cornerOffset;
  final bool screenTextBackgroundEnabled;
  final Color screenTextBackgroundColor;
  final bool screenTextPlaceAtBottom;
  final Color screenTextBottomColor;
  final bool screenRotationButton;
  final bool displayBatteryClockInTitleBar;
  final bool showRemainingTime;
  final bool keepScreenOn;
  final bool pausePlaybackIfObstructed;
  final bool showInterfaceAtStartup;

  const ScreenSettingsState({
    required this.orientation,
    required this.fullScreenMode,
    required this.softButtonsMode,
    required this.isBrightnessEnabled,
    required this.brightness,
    required this.showElapsedTime,
    required this.showBatteryClock,
    required this.isCornerOffsetEnabled,
    required this.cornerOffset,
    required this.screenTextBackgroundEnabled,
    required this.screenTextBackgroundColor,
    required this.screenTextPlaceAtBottom,
    required this.screenTextBottomColor,
    required this.screenRotationButton,
    required this.displayBatteryClockInTitleBar,
    required this.showRemainingTime,
    required this.keepScreenOn,
    required this.pausePlaybackIfObstructed,
    required this.showInterfaceAtStartup,
  });

  factory ScreenSettingsState.fromProvider(SettingsProvider s) {
    return ScreenSettingsState(
      orientation: s.orientation,
      fullScreenMode: s.fullScreenMode,
      softButtonsMode: s.softButtonsMode,
      isBrightnessEnabled: s.isBrightnessEnabled,
      brightness: s.brightness,
      showElapsedTime: s.showElapsedTime,
      showBatteryClock: s.showBatteryClock,
      isCornerOffsetEnabled: s.isCornerOffsetEnabled,
      cornerOffset: s.cornerOffset,
      screenTextBackgroundEnabled: s.screenTextBackgroundEnabled,
      screenTextBackgroundColor: s.screenTextBackgroundColor,
      screenTextPlaceAtBottom: s.screenTextPlaceAtBottom,
      screenTextBottomColor: s.screenTextBottomColor,
      screenRotationButton: s.screenRotationButton,
      displayBatteryClockInTitleBar: s.displayBatteryClockInTitleBar,
      showRemainingTime: s.showRemainingTime,
      keepScreenOn: s.keepScreenOn,
      pausePlaybackIfObstructed: s.pausePlaybackIfObstructed,
      showInterfaceAtStartup: s.showInterfaceAtStartup,
    );
  }

  ScreenSettingsState copyWith({
    String? orientation,
    String? fullScreenMode,
    String? softButtonsMode,
    bool? isBrightnessEnabled,
    double? brightness,
    bool? showElapsedTime,
    bool? showBatteryClock,
    bool? isCornerOffsetEnabled,
    double? cornerOffset,
    bool? screenTextBackgroundEnabled,
    Color? screenTextBackgroundColor,
    bool? screenTextPlaceAtBottom,
    Color? screenTextBottomColor,
    bool? screenRotationButton,
    bool? displayBatteryClockInTitleBar,
    bool? showRemainingTime,
    bool? keepScreenOn,
    bool? pausePlaybackIfObstructed,
    bool? showInterfaceAtStartup,
  }) {
    return ScreenSettingsState(
      orientation: orientation ?? this.orientation,
      fullScreenMode: fullScreenMode ?? this.fullScreenMode,
      softButtonsMode: softButtonsMode ?? this.softButtonsMode,
      isBrightnessEnabled: isBrightnessEnabled ?? this.isBrightnessEnabled,
      brightness: brightness ?? this.brightness,
      showElapsedTime: showElapsedTime ?? this.showElapsedTime,
      showBatteryClock: showBatteryClock ?? this.showBatteryClock,
      isCornerOffsetEnabled:
      isCornerOffsetEnabled ?? this.isCornerOffsetEnabled,
      cornerOffset: cornerOffset ?? this.cornerOffset,
      screenTextBackgroundEnabled:
      screenTextBackgroundEnabled ?? this.screenTextBackgroundEnabled,
      screenTextBackgroundColor:
      screenTextBackgroundColor ?? this.screenTextBackgroundColor,
      screenTextPlaceAtBottom:
      screenTextPlaceAtBottom ?? this.screenTextPlaceAtBottom,
      screenTextBottomColor:
      screenTextBottomColor ?? this.screenTextBottomColor,
      screenRotationButton: screenRotationButton ?? this.screenRotationButton,
      displayBatteryClockInTitleBar:
      displayBatteryClockInTitleBar ?? this.displayBatteryClockInTitleBar,
      showRemainingTime: showRemainingTime ?? this.showRemainingTime,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      pausePlaybackIfObstructed:
      pausePlaybackIfObstructed ?? this.pausePlaybackIfObstructed,
      showInterfaceAtStartup:
      showInterfaceAtStartup ?? this.showInterfaceAtStartup,
    );
  }
}

class ScreenSettingsEvent {
  final ScreenSettingsState next;
  final VoidCallback mutateProvider;

  ScreenSettingsEvent(this.next, this.mutateProvider);
}

class ScreenSettingsBloc
    extends Bloc<ScreenSettingsEvent, ScreenSettingsState> {
  final SettingsProvider _provider;

  ScreenSettingsBloc(this._provider)
      : super(ScreenSettingsState.fromProvider(_provider)) {
    on<ScreenSettingsEvent>((event, emit) {
      _provider.updateSetting(event.mutateProvider);
      emit(event.next);
    });
  }

  void _emitAndSync(ScreenSettingsState next, VoidCallback mutateProvider) {
    add(ScreenSettingsEvent(next, mutateProvider));
  }

  void updateOrientation(String value) => _emitAndSync(
    state.copyWith(orientation: value),
        () => _provider.orientation = value,
  );

  void updateFullScreenMode(String value) => _emitAndSync(
    state.copyWith(fullScreenMode: value),
        () => _provider.fullScreenMode = value,
  );

  void updateSoftButtonsMode(String value) => _emitAndSync(
    state.copyWith(softButtonsMode: value),
        () => _provider.softButtonsMode = value,
  );

  void updateBrightnessEnabled(bool value) => _emitAndSync(
    state.copyWith(isBrightnessEnabled: value),
        () => _provider.isBrightnessEnabled = value,
  );

  void updateBrightness(double value) => _emitAndSync(
    state.copyWith(brightness: value),
        () => _provider.brightness = value,
  );

  void updateShowElapsedTime(bool value) => _emitAndSync(
    state.copyWith(
      showElapsedTime: value,
      isCornerOffsetEnabled: (value || state.showBatteryClock)
          ? state.isCornerOffsetEnabled
          : false,
    ),
        () {
      _provider.showElapsedTime = value;
      if (!value && !_provider.showBatteryClock) {
        _provider.isCornerOffsetEnabled = false;
      }
    },
  );

  void updateShowBatteryClock(bool value) => _emitAndSync(
    state.copyWith(
      showBatteryClock: value,
      isCornerOffsetEnabled: (value || state.showElapsedTime)
          ? state.isCornerOffsetEnabled
          : false,
    ),
        () {
      _provider.showBatteryClock = value;
      if (!value && !_provider.showElapsedTime) {
        _provider.isCornerOffsetEnabled = false;
      }
    },
  );

  void updateCornerOffsetEnabled(bool value) => _emitAndSync(
    state.copyWith(
      isCornerOffsetEnabled: (state.showElapsedTime || state.showBatteryClock)
          ? value
          : false,
    ),
        () => _provider.isCornerOffsetEnabled =
    (state.showElapsedTime || state.showBatteryClock) ? value : false,
  );

  void updateCornerOffset(double value) => _emitAndSync(
    state.copyWith(
      cornerOffset: value.clamp(0.0, 150.0),
      isCornerOffsetEnabled: (state.showElapsedTime || state.showBatteryClock)
          ? true
          : state.isCornerOffsetEnabled,
    ),
        () {
      final v = value.clamp(0.0, 150.0);
      _provider.cornerOffset = v;
      if (_provider.showElapsedTime || _provider.showBatteryClock) {
        _provider.isCornerOffsetEnabled = true;
      }
    },
  );

  void updateScreenTextBackgroundEnabled(bool value) => _emitAndSync(
    state.copyWith(screenTextBackgroundEnabled: value),
        () => _provider.screenTextBackgroundEnabled = value,
  );

  void updateScreenTextBackgroundColor(Color value) => _emitAndSync(
    state.copyWith(screenTextBackgroundColor: value),
        () => _provider.screenTextBackgroundColor = value,
  );

  void updateScreenTextPlaceAtBottom(bool value) => _emitAndSync(
    state.copyWith(screenTextPlaceAtBottom: value),
        () => _provider.screenTextPlaceAtBottom = value,
  );

  void updateScreenTextBottomColor(Color value) => _emitAndSync(
    state.copyWith(screenTextBottomColor: value),
        () => _provider.screenTextBottomColor = value,
  );

  void updateScreenRotationButton(bool value) => _emitAndSync(
    state.copyWith(screenRotationButton: value),
        () => _provider.screenRotationButton = value,
  );

  void updateDisplayBatteryClockInTitleBar(bool value) => _emitAndSync(
    state.copyWith(displayBatteryClockInTitleBar: value),
        () => _provider.displayBatteryClockInTitleBar = value,
  );

  void updateShowRemainingTime(bool value) => _emitAndSync(
    state.copyWith(showRemainingTime: value),
        () => _provider.showRemainingTime = value,
  );

  void updateKeepScreenOn(bool value) => _emitAndSync(
    state.copyWith(keepScreenOn: value),
        () => _provider.keepScreenOn = value,
  );

  void updatePausePlaybackIfObstructed(bool value) => _emitAndSync(
    state.copyWith(pausePlaybackIfObstructed: value),
        () => _provider.pausePlaybackIfObstructed = value,
  );

  void updateShowInterfaceAtStartup(bool value) => _emitAndSync(
    state.copyWith(showInterfaceAtStartup: value),
        () => _provider.showInterfaceAtStartup = value,
  );
}

class SettingsProvider extends ChangeNotifier {
  static const String _settingsBoxName = 'player_settings';
  static const String _settingsKey = 'display_settings_v1';

  // --- Style ---
  String present = "Default";
  bool isFrameEnabled = true;
  Color controlsColor = Colors.white;
  Color controlsBgColor = Colors.white.withOpacity(0.40);
  Color progressBarColor = Color(0XFF3D57F9);
  String progressBarCategory = "Material";
  bool isProgressBarBelow = false;

  // --- Screen ---
  String orientation = "Auto rotation";
  String fullScreenMode = "Auto Switch";
  String softButtonsMode = "Auto hide";
  double brightness = 0.5;
  bool isBrightnessEnabled = true;
  bool showElapsedTime = true;
  bool showBatteryClock = true;
  bool isCornerOffsetEnabled = false;
  double cornerOffset = 0.0;
  bool screenTextBackgroundEnabled = false;
  Color screenTextBackgroundColor = Colors.black54;
  bool screenTextPlaceAtBottom = false;
  Color screenTextBottomColor = Colors.white;
  bool screenRotationButton = true;
  bool displayBatteryClockInTitleBar = true;
  bool showRemainingTime = false;
  bool keepScreenOn = true;
  bool pausePlaybackIfObstructed = false;
  bool showInterfaceAtStartup = true;

  // --- Text (Subtitles) ---
  String font = "Default";
  double fontSize = 20.0;
  double textScale = 100.0;
  Color textColor = Colors.white;
  bool isBold = false;
  bool subtitleBackgroundEnabled = false;
  Color subtitleBackgroundColor = Colors.black54;
  bool hasBorder = false;
  Color borderColor = Colors.black;
  double borderSize = 100.0;
  bool improveStrokeRendering = true;
  bool shadowEnabled = true;
  bool fadeOutEnabled = false;
  bool improveSsaRendering = true;
  bool improveComplexScriptRendering = true;
  bool ignoreSsaFont = false;
  bool ignoreBrokenSsaFonts = false;

  String touchAction = "Show Interface -> Pause/Resume";
  String lockMode = "Lock";
  Map<String, bool> gestures = {
    "Seek position": true,
    "Zoom and pan": true,
    "Video zoom": true,
    "Video pan": true,
    "Volume": true,
    "Brightness": true,
    "Play/pause(Double tap)": true,
    "Video zoom(double tap)": true,
    "FF/RW(Double tap)": true,
    "Speed FF(Long press)": true,
    "Playback speed": true,
    "Subtitle Scroll": true,
    "Subtitle up/down": true,
    "Subtitle zoom": true,
  };
  Map<String, bool> quickShortcuts = {
    "Screen Rotation": true,
    "Playback speed": true,
    "Background play": true,
    "Loop": true,
    "Mute": true,
    "Shuffle": true,
    "Equalizer": true,
    "Sleep Timer": true,
    "A - B Repeat": true,
    "Night Mode": true,
    "Customise Items": true,
    "ScreenShot": true,
    "Mirror mode": true,
    "Verticle Flip": true,
  };
  bool controlsInterfaceAutoHideEnabled = true;
  double interfaceAutoHide = 3.0;
  bool showInterfaceWhenLockedTouched = true;
  double seekSpeed = 10.0;
  bool forwardBackwardButton = true;
  double moveInterval = 10.0;
  bool previousNextButton = true;
  bool displayCurrentPositionWhileChanging = true;
  bool equalizerEnabled = false;
  String equalizerReverb = "None";
  double equalizerBassBoost = 0.0;
  double equalizerVirtualizer = 0.0;

  String layoutAlignment = "Center";
  double bottomMargins = 20.0;
  bool layoutBackgroundEnabled = false;
  Color layoutBackgroundColor = Colors.black54;
  bool fitSubtitlesIntoVideoSize = true;

  Future<void> loadFromHive() async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      final data = box.get(_settingsKey);
      if (data is! Map) return;

      present = data['present'] ?? present;
      isFrameEnabled = data['isFrameEnabled'] ?? isFrameEnabled;
      controlsColor = Color(data['controlsColor'] ?? controlsColor.toARGB32());
      controlsBgColor = Color(
        data['controlsBgColor'] ?? controlsBgColor.toARGB32(),
      );
      progressBarColor = Color(
        data['progressBarColor'] ?? progressBarColor.toARGB32(),
      );
      progressBarCategory = data['progressBarCategory'] ?? progressBarCategory;
      isProgressBarBelow = data['isProgressBarBelow'] ?? isProgressBarBelow;
      orientation = data['orientation'] ?? orientation;
      fullScreenMode = data['fullScreenMode'] ?? fullScreenMode;
      softButtonsMode = data['softButtonsMode'] ?? softButtonsMode;
      brightness = (data['brightness'] ?? brightness).toDouble();
      isBrightnessEnabled = data['isBrightnessEnabled'] ?? isBrightnessEnabled;
      showElapsedTime = data['showElapsedTime'] ?? showElapsedTime;
      showBatteryClock = data['showBatteryClock'] ?? showBatteryClock;
      isCornerOffsetEnabled =
          data['isCornerOffsetEnabled'] ?? isCornerOffsetEnabled;
      cornerOffset = (data['cornerOffset'] ?? cornerOffset).toDouble().clamp(
        0.0,
        150.0,
      );
      screenTextBackgroundEnabled =
          data['screenTextBackgroundEnabled'] ?? screenTextBackgroundEnabled;
      screenTextBackgroundColor = Color(
        data['screenTextBackgroundColor'] ??
            screenTextBackgroundColor.toARGB32(),
      );
      screenTextPlaceAtBottom =
          data['screenTextPlaceAtBottom'] ?? screenTextPlaceAtBottom;
      screenTextBottomColor = Color(
        data['screenTextBottomColor'] ?? screenTextBottomColor.toARGB32(),
      );
      screenRotationButton =
          data['screenRotationButton'] ?? screenRotationButton;
      displayBatteryClockInTitleBar =
          data['displayBatteryClockInTitleBar'] ??
              displayBatteryClockInTitleBar;
      showRemainingTime = data['showRemainingTime'] ?? showRemainingTime;
      keepScreenOn = data['keepScreenOn'] ?? keepScreenOn;
      pausePlaybackIfObstructed =
          data['pausePlaybackIfObstructed'] ?? pausePlaybackIfObstructed;
      showInterfaceAtStartup =
          data['showInterfaceAtStartup'] ?? showInterfaceAtStartup;
      touchAction = data['touchAction'] ?? touchAction;
      lockMode = data['lockMode'] ?? lockMode;
      interfaceAutoHide = (data['interfaceAutoHide'] ?? interfaceAutoHide)
          .toDouble();
      controlsInterfaceAutoHideEnabled =
          data['controlsInterfaceAutoHideEnabled'] ??
              controlsInterfaceAutoHideEnabled;
      showInterfaceWhenLockedTouched =
          data['showInterfaceWhenLockedTouched'] ??
              showInterfaceWhenLockedTouched;
      seekSpeed = (data['seekSpeed'] ?? seekSpeed).toDouble();
      forwardBackwardButton =
          data['forwardBackwardButton'] ?? forwardBackwardButton;
      moveInterval = (data['moveInterval'] ?? moveInterval).toDouble();
      previousNextButton = data['previousNextButton'] ?? previousNextButton;
      displayCurrentPositionWhileChanging =
          data['displayCurrentPositionWhileChanging'] ??
              displayCurrentPositionWhileChanging;
      equalizerEnabled = data['equalizerEnabled'] ?? equalizerEnabled;
      equalizerReverb = data['equalizerReverb'] ?? equalizerReverb;
      equalizerBassBoost = (data['equalizerBassBoost'] ?? equalizerBassBoost)
          .toDouble();
      equalizerVirtualizer =
          (data['equalizerVirtualizer'] ?? equalizerVirtualizer).toDouble();

      final g = data['gestures'];
      if (g is Map) {
        gestures = g.map((k, v) => MapEntry(k.toString(), v == true));
      }
      final q = data['quickShortcuts'];
      if (q is Map) {
        quickShortcuts = q.map((k, v) => MapEntry(k.toString(), v == true));
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveToHive() async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      await box.put(_settingsKey, {
        'present': present,
        'isFrameEnabled': isFrameEnabled,
        'controlsColor': controlsColor.toARGB32(),
        'controlsBgColor': controlsBgColor.toARGB32(),
        'progressBarColor': progressBarColor.toARGB32(),
        'progressBarCategory': progressBarCategory,
        'isProgressBarBelow': isProgressBarBelow,
        'orientation': orientation,
        'fullScreenMode': fullScreenMode,
        'softButtonsMode': softButtonsMode,
        'brightness': brightness,
        'isBrightnessEnabled': isBrightnessEnabled,
        'showElapsedTime': showElapsedTime,
        'showBatteryClock': showBatteryClock,
        'isCornerOffsetEnabled': isCornerOffsetEnabled,
        'cornerOffset': cornerOffset,
        'screenTextBackgroundEnabled': screenTextBackgroundEnabled,
        'screenTextBackgroundColor': screenTextBackgroundColor.toARGB32(),
        'screenTextPlaceAtBottom': screenTextPlaceAtBottom,
        'screenTextBottomColor': screenTextBottomColor.toARGB32(),
        'screenRotationButton': screenRotationButton,
        'displayBatteryClockInTitleBar': displayBatteryClockInTitleBar,
        'showRemainingTime': showRemainingTime,
        'keepScreenOn': keepScreenOn,
        'pausePlaybackIfObstructed': pausePlaybackIfObstructed,
        'showInterfaceAtStartup': showInterfaceAtStartup,
        'touchAction': touchAction,
        'lockMode': lockMode,
        'interfaceAutoHide': interfaceAutoHide,
        'controlsInterfaceAutoHideEnabled': controlsInterfaceAutoHideEnabled,
        'showInterfaceWhenLockedTouched': showInterfaceWhenLockedTouched,
        'seekSpeed': seekSpeed,
        'forwardBackwardButton': forwardBackwardButton,
        'moveInterval': moveInterval,
        'previousNextButton': previousNextButton,
        'displayCurrentPositionWhileChanging':
        displayCurrentPositionWhileChanging,
        'equalizerEnabled': equalizerEnabled,
        'equalizerReverb': equalizerReverb,
        'equalizerBassBoost': equalizerBassBoost,
        'equalizerVirtualizer': equalizerVirtualizer,
        'gestures': gestures,
        'quickShortcuts': quickShortcuts,
      });
    } catch (_) {}
  }

  // Function to update values and notify UI
  void updateSetting(VoidCallback action) {
    action();
    notifyListeners();
    unawaited(_saveToHive());
  }
}

/*
/ Slider Widget
  Widget _buildSlider(String title, double min, double max, double value, ValueChanged<double> onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title: ${(value*100).toInt()}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Slider(value: value, min: min, max: max, activeColor: Color(0XFF3D57F9), onChanged: onChange),
        ],
      ),
    );
  }
 */