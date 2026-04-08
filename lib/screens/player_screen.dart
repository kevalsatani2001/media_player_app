import 'dart:math' show Random, min;
import 'dart:ui' as ui;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/ads_service.dart';
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
  bool _isFullScreen = true;
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
  bool isBgPlayEnabled = false;

  String? _overlayText;
  String? sign;
  Timer? _overlayTextTimer;
  Duration? _seekDuration;
  String _activeGestureType = 'none'; // 'none', 'seek', 'vertical'
  bool _isMoreMenuVisible = false;
  bool _isQueueVisible = false;
  bool _isDisplayVisible = false;
  bool _isPlayListVisible = false;
  bool _iColorPickerVisible = false;
  bool _isDeleteVisible = false;
  bool _isRenameVisible = false;
  bool _isNetWorkStreamVisible = false;
  bool _isInfoVisible = false;
  String _currentPickerTitle = "";
  Color _currentSelectedColor = Colors.white;
  ValueChanged<Color>? _currentColorOnPick;
  MediaItem? mediaItem;

  bool _showShortcutsInMenu = false;
  bool _showVideoDisplay = true;
  static const MethodChannel _equalizerChannel = MethodChannel(
    "media_player/equalizer",
  );

  /// Last tap position for MX-style "Pause/resume" edge zones.
  Offset? _lastTapLocal;

  /// When true, "Pause/resume" mode keeps chrome visible until edge toggled.
  bool _pauseResumeControlsPinned = false;

  /// User dismissed the pause native ad; reset when playback resumes.
  bool _pauseNativeAdDismissedThisSession = false;
  bool _pauseNativeAdEligibleFromUserPause = false;
  int _lastUserPlayPauseToggleMs = 0;

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
  double _selectedAspectRatio = 0.0;
  bool _applyRatioToAll = false;

  // Screen settings runtime helpers Ã¢â‚¬â€ isolated from full-screen setState for smoothness
  final ValueNotifier<DateTime> _clockNotifier = ValueNotifier(DateTime.now());
  final ValueNotifier<int?> _batteryNotifier = ValueNotifier(null);
  late final Listenable _clockBatteryListenable = Listenable.merge([
    _clockNotifier,
    _batteryNotifier,
  ]);
  Timer? _clockTimer;
  final Battery _battery = Battery();
  bool _pausedDueToObstruction = false;
  bool _wasPlayingBeforeBackground = false;

  final Map<String, double?> _ratioValues = {
    "_Default": 0.0,
    "_Custom": 1.2,
    "_1:1": 1.0,
    "_4:3": 4 / 3,
    "_16:9": 16 / 9,
    "_18:9": 18 / 9,
    "_21:9": 21 / 9,
    "_2.21:1": 2.21 / 1,
    "_2.35:1": 2.35 / 1,
    "_2.39:1": 2.39 / 1,
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
                bottom: MediaQuery
                    .of(ctx)
                    .viewInsets
                    .bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppText(
                    "sleepTimer",
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    "${context.tr('_$minutes')} ${context.tr('min')}",
                    color: Colors.white70,
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
                        child: AppText("cancel", color: Colors.white54),
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
                                  AppToast.show(
                                    context,
                                    context.tr("sleepTimerEnded"),
                                  );
                                }
                              }
                            },
                          );
                        },
                        child: AppText("start"),
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
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    setState(() {
      // ઓન હોય તો ઓફ અને ઓફ હોય તો ઓન થશે
      settings.isBgPlayEnabled = !settings.isBgPlayEnabled;
    });

    // યુઝરને સાચી માહિતી આપવા માટેના મેસેજીસ
    final String message = settings.isBgPlayEnabled
        ? "Background Play Enabled: Audio will continue when you minimize the app."
        : "Background Play Disabled: Video will pause on exit.";

    AppToast.show(context, message);
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
    // ૧. પહેલા ઓડિયો સેશન એક્ટિવ કરો
    _enableBackgroundAudio().then((_) {
      // ૨. ત્યારબાદ પ્લેયર સર્વિસ ઈનિશિયલાઈઝ કરો
      if (widget.entityList.isNotEmpty) {
        playerService.init(widget.entityList, widget.index, () {
          if (!mounted) return;
          _checkVideoEnd();
          setState(() {});
        });
      }
    });
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final box = Hive.box('last_played');
    String? lastId = box.get('last_id');
    int? lastPos = box.get('last_position');

    int? seekTo;
    if (lastId == widget.entity.id) {
      seekTo = lastPos;
    }

    // if (widget.entityList.isNotEmpty) {
    //   playerService.init(widget.entityList, widget.index, () {
    //     if (!mounted) return;
    //     _checkVideoEnd();
    //     setState(() {
    //       final ctl = playerService.controller;
    //       if (ctl != null &&
    //           ctl.value.isInitialized &&
    //           ctl.value.isPlaying &&
    //           _pauseNativeAdDismissedThisSession) {
    //         _pauseNativeAdDismissedThisSession = false;
    //       }
    //     });
    //   }, seekToMs: seekTo);
    // }

    _isFullScreen = true;
    _setOrientation(true);
    _startControlsTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      settings.loadFromHive();
      _applyScreenSettings(settings);
      _applyEqualizerSettings(settings, settings.equalizerReverb);
      if (settings.touchAction == "pauseResume") {
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
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (state == AppLifecycleState.paused) {
      _wasPlayingBeforeBackground = playerService.isVideoPlaying;
      final bgOn = settings.isBgPlayEnabled;
      if (bgOn) {
        // Resume playback if user left while playing (some devices pause surface first).
        if (_wasPlayingBeforeBackground) {
          playerService.playVideo();
        }
        WakelockPlus.enable();
        // Show notification after a short delay so play state + channel are ready.
        Future<void>(() async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          if (!mounted) return;
          final s = Provider.of<SettingsProvider>(context, listen: false);
          if (!s.isBgPlayEnabled) return;
          final ctl = playerService.controller;
          final playing = playerService.isVideoPlaying ||
              (ctl?.value.isInitialized == true && ctl!.value.isPlaying);
          if (!playing && _wasPlayingBeforeBackground) {
            await playerService.playVideo();
          }
          if (!playerService.isInitialized || playerService.playlist.isEmpty) {
            return;
          }
          if (playerService.isVideoPlaying ||
              (ctl?.value.isPlaying ?? false)) {
            await playerService.ensureBackgroundNotificationActive();
          }
        });
      } else {
        playerService.pauseVideo();
        WakelockPlus.disable();
      }
    } else if (state == AppLifecycleState.resumed) {
      _wasPlayingBeforeBackground = false;
      playerService.stopBackgroundNotificationAudio();
      // જ્યારે એપ પાછી આવે ત્યારે જો ઓડિયો ચાલુ હોય તો માત્ર UI અપડેટ કરો
      setState(() {});
    }
  }

  Future<void> _enableBackgroundAudio() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.movie,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    ));
    await session.setActive(true);
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
      case "on":
        setState(() => _isFullScreen = true);
        _setOrientation(true);
        break;
      case "off":
        setState(() => _isFullScreen = false);
        _setOrientation(false);
        break;
      case "autoSwitch":
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

  bool get _shouldShowPauseNativeAdOverlay {
    final c = playerService.controller;
    if (c == null || !c.value.isInitialized) return false;
    if (!_pauseNativeAdEligibleFromUserPause) return false;
    if (c.value.isPlaying) return false;
    if (c.value.isBuffering) return false;
    if (_pauseNativeAdDismissedThisSession) return false;
    if (AdHelper.isFullScreenAdShowing) return false;
    return true;
  }

  void _onUserPlayPauseToggle() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastUserPlayPauseToggleMs < 300) return;
    _lastUserPlayPauseToggleMs = nowMs;

    final wasPlaying = playerService.isVideoPlaying;
    playerService.togglePlay();
    if (wasPlaying) {
      // Show pause ad only when user explicitly pauses.
      _pauseNativeAdEligibleFromUserPause = true;
      _pauseNativeAdDismissedThisSession = false;
    } else {
      // Resume clears current pause-ad session.
      _pauseNativeAdEligibleFromUserPause = false;
      _pauseNativeAdDismissedThisSession = false;
    }

    if (mounted) {
      setState(() {});
    }
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
      if (MediaQuery
          .of(context)
          .orientation == Orientation.portrait) {
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
    if (settings.touchAction == "pauseResume" && _pauseResumeControlsPinned) {
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

  /// Bottom-center zone where the main play/pause control sits (_buildBottomSection).
  Rect _playPauseTapRectWhenPauseAdVisible(Size size) {
    final centerX = size.width / 2;
    final rowCenterY = size.height * 0.82;
    final rw = min(size.shortestSide * 0.5, 180.0);
    const rh = 88.0;
    return Rect.fromCenter(
      center: Offset(centerX, rowCenterY),
      width: rw,
      height: rh,
    );
  }

  void _handleVideoTap() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final size = MediaQuery
        .of(context)
        .size;
    final touchAction = settings.touchAction;

    // à«§. àªœà«‹ àª¸à«àª•à«àª°à«€àª¨ àª²à«‹àª• àª¹à«‹àª¯ àª¤à«‹
    if (_isLocked) {
      if (settings.lockMode != "lock") {
        _showKidsLockInstructionIfNeeded();
      } else if (settings.showInterfaceWhenLockedTouched) {
        setState(() => _showControls = !_showControls);
      }
      return;
    }

    // Pause native ad: play/pause only in bottom-center zone; elsewhere toggle UI.
    if (_shouldShowPauseNativeAdOverlay) {
      // When controls are visible, explicit control buttons should own the tap.
      // This avoids accidental double play/pause toggles from overlapping handlers.
      if (_showControls) {
        return;
      }
      final local = _lastTapLocal ?? Offset(size.width / 2, size.height / 2);
      if (_playPauseTapRectWhenPauseAdVisible(size).contains(local)) {
        _onUserPlayPauseToggle();
        _startControlsTimer();
        return;
      }
      final nextVisible = !_showControls;
      setState(() => _showControls = nextVisible);
      if (settings.controlsInterfaceAutoHideEnabled && nextVisible) {
        _startControlsTimer();
      } else {
        _controlsTimer?.cancel();
      }
      return;
    }

    // à«¨. àªœà«‹ àª“àªªà«àª¶àª¨ "pauseResume" àª¹à«‹àª¯
    if (touchAction == "pauseResume") {
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
      _onUserPlayPauseToggle();
      return;
    }

    if (touchAction == "showHideInterface") {
      final nextVisible = !_showControls;
      setState(() => _showControls = nextVisible);
      if (settings.controlsInterfaceAutoHideEnabled && nextVisible) {
        _startControlsTimer();
      } else {
        _controlsTimer?.cancel();
      }
      return;
    }

    if (touchAction == "showInterfacePauseResume") {
      if (!_showControls) {
        setState(() => _showControls = true);
        if (settings.controlsInterfaceAutoHideEnabled) {
          _startControlsTimer();
        }
      } else {
        _onUserPlayPauseToggle();
      }
      return;
    }

    if (touchAction == "showInterfaceAndPauseResume") {
      _onUserPlayPauseToggle();
      final playingAfter = playerService.isVideoPlaying;

      setState(() {
        _showControls = !playingAfter;
      });

      if (settings.controlsInterfaceAutoHideEnabled) {
        _startControlsTimer();
      } else {
        _controlsTimer?.cancel();
      }
      return;
    }

    _onUserPlayPauseToggle();
  }

  Widget _buildLockedProgressRow(SettingsProvider settings) {
    final playedColor = settings.progressBarCategory == "flat"
        ? settings.progressBarColor.withOpacity(0.8)
        : settings.progressBarColor;
    return Row(
      children: [
        AppText(
          _formatDuration(playerService.currentPosition, context),
          color: settings.controlsColor,
          fontSize: 12,
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

        AppText(
          settings.showRemainingTime
              ? "-${_formatDuration(
              playerService.totalDuration - playerService.currentPosition,
              context)}"
              : _formatDuration(playerService.totalDuration, context),
          color: settings.controlsColor,
          fontSize: 12,
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
        if (settings.isBgPlayEnabled) return;
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
          final sz = MediaQuery
              .of(context)
              .size;
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
                        _showVideoDisplay ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: playerService.currentVideoSize.width,
                            height: playerService.currentVideoSize.height,
                            child: VideoPlayer(_playerController,),
                          ),
                        ) : Container(color: Colors.black.withOpacity(
                          0.3,
                        ),),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                          child: Container(
                            color: Colors.black.withOpacity(
                              0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Video Surface
            // Video Surface વિભાગમાં આ કોડ અપડેટ કરો:
            RepaintBoundary(
              key: _globalKey,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateY(_isMirrored ? 3.14159 : 0)
                  ..rotateX(_isFlipped ? 3.14159 : 0),
                child: Transform.translate(
                  offset: _videoPanOffset,
                  child: Transform.scale(
                    scale: _videoScale,
                    child: Center(
                      child: AspectRatio(
                        // ૧. જો યુઝરે મેન્યુઅલ રેશિયો સિલેક્ટ કર્યો હોય તો એ, નહીં તો વિડીયોનો ઓરિજિનલ રેશિયો
                        aspectRatio: _selectedAspectRatio != 0.0
                            ? _selectedAspectRatio
                            : playerService.currentAspectRatio,
                        child: SizedBox.expand( // ૨. આ ખૂબ મહત્વનું છે, તે AspectRatio ની પૂરી સાઈઝ કવર કરશે
                          child: FittedBox(
                            fit: _videoFit, // ૩. હવે તમારો CROP, STRETCH, 100% આની અંદર પર્ફેક્ટ કામ કરશે
                            clipBehavior: Clip.hardEdge,
                            child: SizedBox(
                              // ૪. અહીં વિડિયોની ઓરિજિનલ સાઈઝ આપવાની
                              width: playerService.currentVideoSize.width,
                              height: playerService.currentVideoSize.height,
                              child: _showVideoDisplay
                                  ? VideoPlayer(_playerController)
                                  : _buildAudioOnlyPlaceholder(),
                            ),
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
            if (_shouldShowPauseNativeAdOverlay)
              PauseVideoNativeAdLayer(
                key: ValueKey(
                  'pause_native_${playerService.currentIndex}_${widget.entity
                      .id}',
                ),
                onDismiss: () {
                  if (mounted) {
                    setState(() => _pauseNativeAdDismissedThisSession = true);
                  }
                },
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
                        AppText(
                          sign ?? "",
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                      SizedBox(width: 8), // Gap between icon and time
                      AppText(
                        _overlayText ?? "",
                        fontSize: 24,
                        color: Colors.white,
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

  Widget _buildAudioOnlyPlaceholder() {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.music_note_rounded,
            size: 100,
            color: Color(0XFF3D57F9), // તમારો બ્રાન્ડ કલર
          ),
          const SizedBox(height: 10),
          AppText(
            "audioModeActive",
            color: Colors.white70,
            fontSize: 16,
          ),
        ],
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
      AppToast.show(context, context.tr("touchEachCornerOfTheScreen"));
    }
  }

  void _handleKidsLockTap(Offset point) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final size = MediaQuery
        .of(context)
        .size;
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
      AppToast.show(context, context.tr("wrongSequenceTryAgain"));
    }
  }

  void _handleDoubleTap(Offset tapPosition) {
    if (_isLocked) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final g = settings.gestures;
    final w = MediaQuery
        .of(context)
        .size
        .width;
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
        _onUserPlayPauseToggle();
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
      _onUserPlayPauseToggle();
      setState(() => _showControls = true);
      _startControlsTimer();
    }
  }

  TextAlign _subtitleTextAlign(SettingsProvider settings) {
    switch (settings.layoutAlignment.toLowerCase()) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  /// Typography from Display → Text tab for the bottom on-screen time line
  /// (same layer as subtitle scroll / pinch gestures).
  TextStyle _subtitleOverlayTextStyle(SettingsProvider settings,
      BuildContext context,) {
    final scale = settings.textScale / 100.0;
    double size = settings.fontSize * scale;
    final mq = MediaQuery.of(context);
    if (mq.orientation != Orientation.landscape) {
      size = R.sp(context, size);
    }

    final fontKey = SettingsProvider.normalizeFontValue(settings.font);
    String? family;
    switch (fontKey.toLowerCase()) {
      case 'mono':
        family = 'monospace';
        break;
      case 'sansserif':
      case 'sans_serif':
        family = 'Roboto';
        break;
      case 'serif':
        family = null;
        break;
      case 'inter':
        family = 'Inter';
        break;
      case 'roboto':
        family = 'Roboto';
        break;
      case 'olioscript':
        family = 'Olio Script';
        break;
      default:
        family = null;
    }

    final shadows = <Shadow>[];
    if (settings.shadowEnabled) {
      shadows.add(
        const Shadow(
          color: Color(0x80000000),
          offset: Offset(0, 2),
          blurRadius: 4,
        ),
      );
    }
    if (settings.improveStrokeRendering) {
      const outline = Color(0xDD000000);
      const outlineOffsets = <Offset>[
        Offset(-1, -1),
        Offset(1, -1),
        Offset(-1, 1),
        Offset(1, 1),
        Offset(0, -1),
        Offset(0, 1),
        Offset(-1, 0),
        Offset(1, 0),
      ];
      for (final o in outlineOffsets) {
        shadows.add(Shadow(color: outline, offset: o, blurRadius: 0));
      }
    }

    return TextStyle(
      color: settings.textColor,
      fontSize: size,
      fontWeight: settings.isBold ? FontWeight.bold : FontWeight.w600,
      fontFamily: family,
      shadows: shadows.isEmpty ? null : shadows,
    );
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

    // Corner chips only when top bar / controls are hidden Ã¢â‚¬â€ avoids stacking with top bar.
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
            _formatDuration(position, context),
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
      final bottomText = settings.showRemainingTime
          ? "-${_formatDuration(remaining, context)}"
          : _formatDuration(position, context);
      final bgColor = settings.subtitleBackgroundEnabled
          ? settings.subtitleBackgroundColor
          : (settings.screenTextBackgroundEnabled
          ? settings.screenTextBackgroundColor
          : Colors.black54);
      final borderWidth = settings.hasBorder
          ? (settings.borderSize / 100.0).clamp(0.5, 8.0)
          : 1.0;
      final borderCol = settings.hasBorder
          ? settings.borderColor
          : Colors.white12;

      Widget textChild = Text(
        bottomText,
        textAlign: _subtitleTextAlign(settings),
        style: _subtitleOverlayTextStyle(settings, context),
      );

      if (settings.fitSubtitlesIntoVideoSize) {
        final maxW =
            (MediaQuery
                .sizeOf(context)
                .width - 24 - pad.left - pad.right) *
                0.92;
        textChild = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: textChild,
          ),
        );
      }

      overlays.add(
        Positioned(
          left: 12 + pad.left,
          right: 12 + pad.right,
          bottom: 12 + pad.bottom + settings.bottomMargins,
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
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderCol, width: borderWidth),
                ),
                child: textChild,
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
      child: AppText(
        text,
        color: fg,
        fontSize: 12,
        fontWeight: FontWeight.w600,
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
          final sep = compactSeparator ? " • " : "  ";

          final clockStr = _formatClock(_clockNotifier.value, context);

          String extra = "";
          if (bat != null) {
            String batStr = bat
                .toString()
                .split('')
                .map((digit) {
              return context.tr('_$digit');
            })
                .join('');

            extra = "$sep$batStr%";
          }

          return AppText(
            "$clockStr$extra",
            color: fg,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        },
      ),
    );
  }

  String _formatClock(DateTime dt, BuildContext context) {
    int hour = dt.hour;
    int minute = dt.minute;

    String h = hour < 10
        ? "${context.tr('_0')}${context.tr('_$hour')}"
        : "${context.tr('_' + (hour ~/ 10).toString())}${context.tr(
        '_' + (hour % 10).toString())}";

    String m = minute < 10
        ? "${context.tr('_0')}${context.tr('_$minute')}"
        : "${context.tr('_' + (minute ~/ 10).toString())}${context.tr(
        '_' + (minute % 10).toString())}";

    return "$h:$m";
  }

  /// Localized digits using [app_string] keys `_0`…`_9` (same pattern as [_formatClock]).
  String _localizedIntDigits(int value, BuildContext context) {
    final s = value.clamp(0, 999).toString();
    return s.split('').map((digit) => context.tr('_$digit')).join();
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
              AppText(
                "${_localizedIntDigits(
                    (_gestureValue! * 100).round().clamp(0, 100), context)}%",
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSwipe(ScaleUpdateDetails details) async {
    if (_isScaling) return;
    final width = MediaQuery
        .of(context)
        .size
        .width;
    final height = MediaQuery
        .of(context)
        .size
        .height;
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
          _showOverlayMessage(_formatDuration(newPos, context), icon);
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
    final width = MediaQuery
        .of(context)
        .size
        .width;
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
              width: MediaQuery
                  .of(context)
                  .size
                  .width / 3,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.2), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fast_rewind_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  AppText(
                    'minus_10s',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
              width: MediaQuery
                  .of(context)
                  .size
                  .width / 3,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.white.withOpacity(0.2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fast_forward_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  AppText(
                    'plus_10s',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
              onPressed: () =>
                  setState(() {
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
                              label: "capture",
                              onTap: _captureScreenshot,
                            ),

                          if (_isShortcutEnabled(settings, "A-B Repeat"))
                            _controlItemWithLabel(
                              src: AppSvg.icABRepeat,
                              label: "abRepeat",
                              isActive: _pointA != null,
                              color: _pointA != null
                                  ? settings.controlsColor
                                  : Colors.white,
                              onTap: _handleABRepeat,
                            ),

                          if (_isShortcutEnabled(settings, "Flip"))
                            _controlItemWithLabel(
                              src: AppSvg.icSwapVert,
                              label: "flip",
                              isActive: _isFlipped,
                              color: _isFlipped
                                  ? settings.controlsColor
                                  : Colors.white,
                              onTap: () =>
                                  setState(() => _isFlipped = !_isFlipped),
                            ),

                          if (_isShortcutEnabled(settings, "Mirror"))
                            _controlItemWithLabel(
                              src: AppSvg.icSwapHor,
                              label: "mirror",
                              isActive: _isMirrored,
                              color: _isMirrored
                                  ? settings.controlsColor
                                  : Colors.white,
                              onTap: () =>
                                  setState(() => _isMirrored = !_isMirrored),
                            ),

                          if (_isShortcutEnabled(settings, "Trim") &&
                              !playerService.isNetworkPlayback)
                            _controlItemWithLabel(
                              src: AppSvg.icTrim,
                              label: "trim",
                              onTap: () async {
                                await playerService.pauseVideo();
                                File? file = await playerService
                                    .playlist[playerService.currentIndex]
                                    .file;

                                final trimResult = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VideoTrimScreen(file: file!),
                                  ),
                                );
                                if (!mounted) return;
                                if (trimResult == true ||
                                    (trimResult is String &&
                                        trimResult.isNotEmpty)) {
                                  context.read<VideoBloc>().add(
                                    LoadVideosFromGallery(
                                      showLoading: false,
                                      isRefresh: true,
                                    ),
                                  );
                                }

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
                              label: "speed",
                              onTap: _showPlaybackSpeedBottomSheet,
                            ),
                        ],

                        if (_isShortcutEnabled(settings, "Shuffle"))
                          _controlItemWithLabel(
                            src: playerService.isShuffle
                                ? AppSvg.icShuffleActive
                                : AppSvg.icShuffle,
                            label: "shuffle",
                            isActive: playerService.isShuffle,
                            color: playerService.isShuffle
                                ? settings.controlsColor
                                : Colors.white,
                            onTap: () =>
                                setState(
                                      () =>
                                  playerService.isShuffle =
                                  !playerService.isShuffle,
                                ),
                          ),

                        if (_isShortcutEnabled(settings, "Repeat"))
                          _controlItemWithLabel(
                            src: playerService.isLooping
                                ? AppSvg.icLoopActive
                                : AppSvg.icLoop,
                            label: "repeat",
                            isActive: playerService.isLooping,
                            color: playerService.isLooping
                                ? settings.controlsColor
                                : Colors.white,
                            onTap: () =>
                                setState(() {
                                  playerService.isLooping =
                                  !playerService.isLooping;
                                  playerService.setLooping(
                                      playerService.isLooping);
                                }),
                          ),
                        if (_isShortcutEnabled(settings, "Equalizer"))
                          _controlItemWithLabel(
                            src: AppSvg.icEqualizer,
                            label: "equalizer",
                            isActive: settings.equalizerEnabled,
                            color: settings.equalizerEnabled
                                ? settings.controlsColor
                                : Colors.white,
                            onTap: () => _showEqualizerBottomSheet(settings),
                          ),
                        if (_isShortcutEnabled(settings, "Sleep"))
                          _controlItemWithLabel(
                            src: AppSvg.icSleep,
                            label: "sleep",
                            isActive:
                                (_sleepSecondsLeft != null &&
                                    _sleepSecondsLeft! > 0),
                            color:
                            (_sleepSecondsLeft != null &&
                                _sleepSecondsLeft! > 0)
                                ? settings.controlsColor
                                : Colors.white,
                            onTap: _showSleepTimerSheet,
                          ),
                        if (_isShortcutEnabled(settings, "Night"))
                          _controlItemWithLabel(
                            src: AppSvg.icDarkMode,
                            label: "night",
                            isActive: _nightModeDim,
                            color: _nightModeDim
                                ? settings.controlsColor
                                : Colors.white,
                            onTap: () =>
                                setState(() => _nightModeDim = !_nightModeDim),
                          ),
                        if (_isShortcutEnabled(settings, "BgPlay"))
                          _controlItemWithLabel(
                            src: AppSvg.icBgPlay,
                            label: "bgPlay",
                            isActive: settings.isBgPlayEnabled,
                            color: settings.isBgPlayEnabled
                                ? settings.controlsColor
                                : Colors.white,
                            onTap: _onBackgroundPlayHint,
                          ),

                        if (_isShortcutEnabled(settings, "Mute"))
                          _controlItemWithLabel(
                            src: playerService.isMuted
                                ? AppSvg.icVolumeOff
                                : AppSvg.icVolumeOn,
                            label: "mute",
                            isActive: playerService.isMuted,
                            color: playerService.isMuted
                                ? settings.controlsColor
                                : Colors.white,
                            onTap: () =>
                                setState(() {
                                  playerService.isMuted =
                                  !playerService.isMuted;
                                  playerService.setVideoVolume(
                                    playerService.isMuted
                                        ? 0
                                        : playerService.volume,
                                  );
                                }),
                          ),
                        if (_isShortcutEnabled(settings, "Screen"))
                          _controlItemWithLabel(
                            // ૧. અહીં આપોઆપ સ્ટેટ પ્રમાણે સાચો SVG પાથ સેટ થઈ જશે
                            src: _getFitIconPath(_videoFit),
                            label: "screen", // જો તમે Localization વાપરતા હોવ તો context.tr("screen") પણ લખી શકો
                            isActive: _videoFit != BoxFit.contain,
                            color: _videoFit != BoxFit.contain
                                ? settings.controlsColor
                                : Colors.white,
                            onTap: () {
                              setState(() {
                                // ૨. વારાફરતી ચારેય મોડ બદલવા માટેનું લૂપ લોજિક
                                if (_videoFit == BoxFit.contain) {
                                  _videoFit = BoxFit.cover; // CROP
                                } else if (_videoFit == BoxFit.cover) {
                                  _videoFit = BoxFit.fill;  // STRETCH
                                } else if (_videoFit == BoxFit.fill) {
                                  _videoFit = BoxFit.none;  // 100% (Original)
                                } else {
                                  _videoFit = BoxFit.contain; // FIT TO SCREEN
                                }

                                // ૩. સ્ક્રીન પર ટેક્સ્ટ બતાવવા માટે
                                _overlayText = _getFitText(_videoFit,context);
                              });

                              // ૪. ૨ સેકન્ડ પછી સ્ક્રીન પરથી ટેક્સ્ટ હટાવવા માટેનું ટાઈમર
                              _overlayTextTimer?.cancel();
                              _overlayTextTimer = Timer(const Duration(seconds: 2), () {
                                if (mounted) setState(() => _overlayText = null);
                              });
                            },
                          ),
                        _controlItemWithLabel(
                          src: _isExtraControlsExpanded
                              ? AppSvg.icOff
                              : AppSvg.icOn,
                          label: _isExtraControlsExpanded ? "less" : "more",
                          isActive: _isExtraControlsExpanded,
                          color: _isExtraControlsExpanded
                              ? settings.controlsColor
                              : Colors.white,
                          onTap: () =>
                              setState(
                                    () =>
                                _isExtraControlsExpanded =
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

  // BoxFit મુજબ સાચો SVG પાથ મેળવવા માટેનું ફંક્શન
  String _getFitIconPath(BoxFit fit) {
    switch (fit) {
      case BoxFit.contain:
        return AppSvg.icFitToScreen; // 'assets/svg/ic_fit_to_screen.svg'
      case BoxFit.cover:
        return AppSvg.icVideoCrop;   // 'assets/svg/ic_video_crop.svg'
      case BoxFit.fill:
        return AppSvg.icStretch;     // 'assets/svg/ic_stretch.svg'
      case BoxFit.none:
        return AppSvg.icOriginal;    // 'assets/svg/ic_original.svg'
      default:
        return AppSvg.icFitToScreen;
    }
  }

  Widget _controlItemWithLabel({
    required String src,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
    bool isActive = false,
  }) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final Color iconColor = isActive ? color : settings.controlsColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: () {
          onTap();
          _startControlsTimer();
        },
        child: SizedBox(
          width: 35,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: settings.controlsBgColor,
                  border: isActive
                      ? Border.all(color: color, width: 2)
                      : null,
                ),
                padding: const EdgeInsets.all(0),
                child: AppImage(
                  src: src,
                  height: 35,
                  width: 35,
                  color: iconColor,
                ),
              ),
              if (_isExtraControlsExpanded) ...[
                const SizedBox(height: 6),
                AppText(
                  label,
                  maxLines: 1,
                  color: isActive ? color : Colors.white,
                  fontSize: 10,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    bool isLandscape =
        MediaQuery
            .of(context)
            .orientation == Orientation.landscape;
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
              child: AppText(
                _formatDuration(playerService.currentPosition, context),
                color: settings.controlsColor.withOpacity(0.95),
                fontSize: isLandscape ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          Expanded(
            child: AppText(
              playerService.playlist[playerService.currentIndex].title ??
                  "playingVideo",
              color: Colors.white,
              fontSize: isLandscape ? 16 : 18,
              fontWeight: FontWeight.w500,
              maxLines: 1,
            ),
          ),
          if (settings.displayBatteryClockInTitleBar)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AnimatedBuilder(
                animation: _clockBatteryListenable,
                builder: (context, _) {
                  final bat = _batteryNotifier.value;

                  final clockStr = _formatClock(_clockNotifier.value, context);

                  String extra = "";
                  if (bat != null) {
                    String batStr = bat
                        .toString()
                        .split('')
                        .map((digit) {
                      return context.tr('_$digit');
                    })
                        .join('');

                    extra = "  $batStr%";
                  }

                  return AppText(
                    "$clockStr$extra",
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
    MediaQuery
        .of(context)
        .orientation == Orientation.landscape
        ? !(!_isRatioVisible &&
        !_isQueueVisible &&
        !_isMoreMenuVisible &&
        !_isDisplayVisible &&
        !_iColorPickerVisible &&
        !_isPlayListVisible)
        ? MediaQuery
        .of(context)
        .size
        .width * 0.7
        : MediaQuery
        .of(context)
        .size
        .width * 0.52
        : !(!_isRatioVisible &&
        !_isQueueVisible &&
        !_isMoreMenuVisible &&
        !_isDisplayVisible &&
        _iColorPickerVisible &&
        !_isPlayListVisible)
        ? MediaQuery
        .of(context)
        .size
        .width * 0.9
        : MediaQuery
        .of(context)
        .size
        .width * 0.75;

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(20),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: const ColoredBox(color: Colors.transparent),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xF01A1A26), const Color(0xF5080810)],
                  ),
                  border: Border(
                    left: BorderSide(
                      color: Colors.white.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                ),
              ),
              SafeArea(
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
                          if (_isRatioVisible ||
                              _isQueueVisible ||
                              _isMoreMenuVisible ||
                              _isDisplayVisible ||
                              _iColorPickerVisible ||
                              _isPlayListVisible ||
                              _isDeleteVisible ||
                              _isRenameVisible ||
                              _isNetWorkStreamVisible ||
                              _isInfoVisible)
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  setState(() {
                                    _isMoreMenuVisible = false;
                                    _isQueueVisible = false;
                                    _isDisplayVisible = false;
                                    _iColorPickerVisible = false;
                                    _isDisplayVisible = false;
                                    _isPlayListVisible = false;
                                    _isDeleteVisible = false;
                                    _isRenameVisible = false;
                                    _isNetWorkStreamVisible = false;
                                    _isInfoVisible = false;
                                    _isRatioVisible = false;
                                  }),
                            ),

                          AppText(
                            // _iColorPickerVisible?_currentPickerTitle:
                            _isRatioVisible ? "ratio" : _isInfoVisible
                                ? "info"
                                : _isNetWorkStreamVisible
                                ? "networkStream"
                                : _isRenameVisible
                                ? "rename"
                                : _isDeleteVisible
                                ? "delete"
                                : _isPlayListVisible
                                ? "playlist"
                                : _isDisplayVisible
                                ? "display":_isPlayListVisible ?
                                 "playingQueue":(_isMoreMenuVisible ? "more" : "quickMenu"),
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          const Spacer(),
                          // if (!_isMoreMenuVisible &&
                          //     !_isDisplayVisible &&
                          //     !_isPlayListVisible &&
                          //     !_isDeleteVisible &&
                          //     !_isRenameVisible &&
                          //     !_isNetWorkStreamVisible &&
                          //     !_isInfoVisible)
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.white.withOpacity(0.14),
                      height: 1,
                      thickness: 1,
                    ),

                    // Content Section
                    Expanded(
                      child:
                      // _iColorPickerVisible
                      //     ?MyColorPickerWidget(
                      //   title: _currentPickerTitle,
                      //   initialColor: _currentSelectedColor,
                      //   onPick: _currentColorOnPick!,
                      //   onApply: () {
                      //     // àª…àªªà«àª²àª¾àª¯ àª¥àª¾àª¯ àª¤à«àª¯àª¾àª°à«‡ àª®à«‡àªˆàª¨ àªªà«‡àªœàª¨àª¾ àª®à«‡àª¨à« àª…àªªàª¡à«‡àªŸ àª¥àª¶à«‡
                      //     setState(() {
                      //       _iColorPickerVisible = false;
                      //       _isRatioVisible = false;
                      //       _isQueueVisible = false;
                      //       _isMoreMenuVisible = false;
                      //       _isDisplayVisible = true;
                      //     });
                      //   },
                      // ):
                      _isPlayListVisible
                          ? PlaylistSelectorView(currentItem: mediaItem!)
                          : _isDisplayVisible
                          ? _buildDisplaySetting()
                          : _isQueueVisible
                          ? _buildQueueList()
                          : _isDeleteVisible
                          ? _buildDeleteView()
                          : _isRenameVisible
                          ? _buildRenameView()
                          : _isNetWorkStreamVisible
                          ? _buildNetworkStreamView()
                          : _isInfoVisible
                          ? (playerService.isNetworkPlayback
                              ? _buildNetworkStreamInfoView()
                              : _buildInfoView(
                                  playerService.playlist[
                                      playerService.currentIndex],
                                ))
                          : (_isRatioVisible
                          ? _buildRatioMenu()
                          : (_isMoreMenuVisible
                          ? _buildMoreCategoryMenu()
                          : _buildMainMenuGrid())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayListView(MediaItem currentItem) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final playlistBox = Hive.box('playlists');

    final filteredPlaylists = playlistBox.values.where((playlist) {
      return (playlist as PlaylistModel).type == currentItem.type;
    }).toList();

    // à«§. àª•àª‚àªŸà«àª°à«‹àª²àª° àª…àª¨à«‡ àª‡àª¨à«àª¡à«‡àª•à«àª¸àª¨à«‡ àª…àª¹à«€àª‚ àª¡àª¿àª•à«àª²à«‡àª° àª•àª°à«‹ àªœà«‡àª¥à«€ àª°à«€àª¬àª¿àª²à«àª¡ àª¥àªµàª¾ àªªàª° àª¡à«‡àªŸàª¾ àª¨ àª­à«‚àª²àª¾àª¯
    final TextEditingController nameController = TextEditingController();
    dynamic selectedPlaylistIndex;

    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- àª¡à«àª°à«‹àªªàª¡àª¾àª‰àª¨ àª¸à«‡àª•à«àª¶àª¨ ---
              if (filteredPlaylists.isNotEmpty) ...[
                AppText(
                  "selectExistingPlaylist",
                  fontSize: 14,
                  color: colors.dialogueSubTitle,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colors.textFieldFill,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  dropdownColor: colors.background,
                  hint: AppText(
                    "choosePlaylist",
                    color: colors.dialogueSubTitle,
                  ),
                  value: selectedPlaylistIndex,
                  items: List.generate(filteredPlaylists.length, (index) {
                    final playlist = filteredPlaylists[index] as PlaylistModel;
                    return DropdownMenuItem(
                      value: index,
                      child: Text(
                        playlist.name,
                        style: TextStyle(color: colors.appBarTitleColor),
                      ),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      selectedPlaylistIndex = value;
                      nameController
                          .clear(); // àªœà«‹ àª¡à«àª°à«‹àªªàª¡àª¾àª‰àª¨ àª¸àª¿àª²à«‡àª•à«àªŸ àª¥àª¾àª¯ àª¤à«‹ àªŸà«‡àª•à«àª¸à«àªŸ àª•à«àª²àª¿àª¯àª° àª¥àª¶à«‡
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Divider(),
              ],

              // --- àª¨àªµà«àª‚ àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àª¬àª¨àª¾àªµàªµàª¾àª¨à«àª‚ àª¸à«‡àª•à«àª¶àª¨ ---
              AppText(
                "orCreateNew",
                fontSize: 14,
                color: colors.dialogueSubTitle,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: TextStyle(color: colors.appBarTitleColor),
                decoration: InputDecoration(
                  hintText: "enterName",
                  hintStyle: TextStyle(
                    color: colors.dialogueSubTitle.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) {
                  // àªœà«‹ àªŸàª¾àª‡àªª àª•àª°àªµàª¾àª¨à«àª‚ àªšàª¾àª²à« àª¥àª¾àª¯, àª¤à«‹ àª¡à«àª°à«‹àªªàª¡àª¾àª‰àª¨ àª°à«€àª¸à«‡àªŸ àª•àª°à«€ àª¦à«‹
                  if (v
                      .trim()
                      .isNotEmpty && selectedPlaylistIndex != null) {
                    setState(() {
                      selectedPlaylistIndex = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // --- àªàª•à«àª¶àª¨ àª¬àªŸàª¨à«àª¸ ---
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      title: "cancel",
                      backgroundColor: colors.whiteColor,
                      textColor: colors.dialogueSubTitle,
                      onTap: () {
                        nameController.dispose();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppButton(
                      title: "add",
                      onTap: () {
                        final String newName = nameController.text.trim();

                        // àª«àª‚àª•à«àª¶àª¨àª¾àª²àª¿àªŸà«€ à«§: àªàª•à«àªàª¿àª¸à«àªŸàª¿àª‚àª— àª²àª¿àª¸à«àªŸàª®àª¾àª‚ àªšà«‡àª• àª•àª°à«€àª¨à«‡ àªàª¡ àª•àª°àªµà«àª‚
                        if (selectedPlaylistIndex != null) {
                          final playlist =
                          filteredPlaylists[selectedPlaylistIndex]
                          as PlaylistModel;

                          bool isAlreadyExist = playlist.items.any(
                                (e) => e.path == currentItem.path,
                          );

                          if (!isAlreadyExist) {
                            playlist.items.add(currentItem);

                            // Hive àª®àª¾àª‚ àª•àª¨à«àª«àª°à«àª® àª¡à«‡àªŸàª¾ àª…àªªàª¡à«‡àªŸ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡ put àªµàª¾àªªàª°àªµà«àª‚
                            final int originalKey = playlist.key;
                            playlistBox.put(originalKey, playlist);

                            nameController.dispose();
                            Navigator.pop(context);
                            AppToast.show(
                              context,
                              "${context.tr("addedTo")} ${playlist.name}",
                              type: ToastType.success,
                            );
                          } else {
                            AppToast.show(
                              context,
                              "${context.tr("alreadyExistIn")} ${playlist
                                  .name}",
                              type: ToastType.info,
                            );
                          }
                        }
                        // àª«àª‚àª•à«àª¶àª¨àª¾àª²àª¿àªŸà«€ à«¨: àª¨àªµà«àª‚ àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àª¬àª¨àª¾àªµà«€àª¨à«‡ àªàª¡ àª•àª°àªµà«àª‚
                        else if (newName.isNotEmpty) {
                          final newPlaylist = PlaylistModel(
                            name: newName,
                            items: [currentItem],
                            type: currentItem.type,
                          );

                          playlistBox.add(newPlaylist);

                          nameController.dispose();
                          Navigator.pop(context);
                          AppToast.show(
                            context,
                            context.tr("newPlaylistCreated"),
                            type: ToastType.success,
                          );
                        }
                        // àªœà«‹ àª¬àª‚àª¨à«‡àª®àª¾àª‚àª¥à«€ àª•àª‚àªˆ àª¸àª¿àª²à«‡àª•à«àªŸ àª¨ àª•àª°à«àª¯à«àª‚ àª¹à«‹àª¯
                        else {
                          AppToast.show(
                            context,
                            context.tr("pleaseSelectOrCreate"),
                            type: ToastType.info,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisplaySetting() {
    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          // --- Handle Bar ---
          const SizedBox(height: 12),
          // Container(
          //   width: 50,
          //   height: 5,
          //   decoration: BoxDecoration(
          //     color: Colors.white12,
          //     // borderRadius: BorderRadius.circular(10),
          //   ),
          // ),

          // --- Header ---
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(25, 10, 15, 10),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       const AppText(
          //         "settings",
          //         color: Colors.white,
          //         fontSize: 24,
          //         fontWeight: FontWeight.w900,
          //         letterSpacing: 0.5,
          //       ),
          //       IconButton(
          //         onPressed: () => Navigator.pop(context),
          //         icon: const Icon(
          //           Icons.close_rounded,
          //           color: Colors.white70,
          //         ),
          //         style: IconButton.styleFrom(
          //           backgroundColor: Colors.white.withOpacity(0.05),
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(15),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // --- Floating Modern Tab Bar ---
          Container(
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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

              // Ã ÂªÂ«Ã Â«â€¹Ã ÂªÂ¨Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ Ã Â«Â§Ã Â«Â¨-Ã Â«Â§Ã Â«Â© Ã ÂªÂ°Ã ÂªÂ¾Ã Âªâ€“Ã ÂªÂµÃ Â«â‚¬ Ã ÂªÅ“Ã Â«â€¡Ã ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ®Ã Â«â€¹Ã ÂªÅ¸Ã Â«ÂÃ Âªâ€š Ã ÂªÂ¨Ã ÂªÂ¾ Ã ÂªÂ²Ã ÂªÂ¾Ã Âªâ€”Ã Â«â€¡
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12.5,
              ),

              tabs: [
                Tab(text: context.tr("style")),
                Tab(text: context.tr("screen")),
                Tab(text: context.tr("controls")),
                Tab(text: context.tr("navigation")),
                Tab(text: context.tr("text")),
                Tab(text: context.tr("layout")),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // --- Content Area ---
          Expanded(
            child: ClipRRect(
              // borderRadius: const BorderRadius.vertical(
              //   top: Radius.circular(30),
              // ),
              child: Container(
                // color: Colors.black12,
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Consumer<SettingsProvider>(
                      builder: (_, s, __) => _styleTab(s),
                    ),

                    BlocProvider(
                      create: (ctx) =>
                          ScreenSettingsBloc(
                            Provider.of<SettingsProvider>(
                                context, listen: false),
                          ),
                      child: BlocConsumer<
                          ScreenSettingsBloc,
                          ScreenSettingsState>(
                        //////////////////////////////////////////////////////////////////////// part 6 new player scareen//////////////////////////////////////////////////////////
                        listener: (_, state) => _applyScreenState(state),
                        builder: (blocContext, state) =>
                            _screenTabBloc(
                              state,
                              blocContext.read<ScreenSettingsBloc>(),
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
          title: AppText(
            video.title ?? "unknown",
            maxLines: 1,
            color: isCurrent ? Color(0XFF3D57F9) : Colors.white,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0XFF3D57F9).withOpacity(0.45)
                              : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      leading: Icon(
                        //////////////////////////////////////////////////////////////////////// part 4 new player scareen//////////////////////////////////////////////////////////
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? const Color(0XFF3D57F9)
                            : Colors.white.withOpacity(0.55),
                        size: 20,
                      ),
                      title: AppText(
                        key,
                        color: isSelected
                            ? const Color(0XFF3D57F9)
                            : Colors.white.withOpacity(0.95),
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedAspectRatio = _ratioValues[key] ?? 0.0;
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        const Divider(color: Colors.white24),

        // Apply to all videos Checkbox
        CheckboxListTile(
          tileColor: Colors.white.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const AppText(
            "applyToAllVideos",
            color: Colors.white,
            fontSize: 14,
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
                bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppText(
                    "playbackSpeed",
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          "${context.tr("_0.25")}x",
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                        AppText(
                          "${context.tr("_1.0")}x",
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                        AppText(
                          "${context.tr("_2.0")}x",
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                        AppText(
                          "${context.tr("_3.0")}x",
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                        AppText(
                          "${context.tr("_4.0")}x",
                          color: Colors.white54,
                          fontSize: 10,
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
          title: const AppText("networkStream", color: Colors.white),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppText(
                "enterVideoStream",
                color: Colors.white54,
                fontSize: 12,
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
              child: const AppText("cancel", color: Colors.white54),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0XFF3D57F9),
              ),
              onPressed: () {
                _startNetworkStream(urlController.text, closeCount: 1);
              },
              child: const AppText("playStream", color: Colors.white),
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

  /// Same layout as [_menuGridItem] (white icon + label); toggles favourite for the
  /// current queue item and syncs playlist / blocs — avoids embedding [FavouriteButton]
  /// which uses different styling and did not match this drawer.
  Future<void> _togglePlayerSidebarFavourite(AssetEntity entity) async {
    final file = await entity.file;
    if (file == null) {
      if (!mounted) return;
      AppToast.show(
        context,
        context.tr('fileNotFoundMsg'),
        type: ToastType.error,
      );
      return;
    }

    final playlistService = PlaylistService();
    final newFavState = await playlistService.toggleFavourite(entity);

    if (!mounted) return;

    AppToast.show(
      context,
      newFavState
          ? context.tr('addedToFavourite')
          : context.tr('removedFromFavourites'),
      type: newFavState ? ToastType.success : ToastType.info,
    );

    final AssetEntity? newEntity = await entity.obtainForNewProperties();
    if (!mounted || newEntity == null) return;

    final i = playerService.currentIndex;
    if (i >= 0 &&
        i < playerService.playlist.length &&
        playerService.playlist[i].id == entity.id) {
      playerService.playlist[i] = newEntity;
    }

    try {
      final gp = GlobalPlayer();
      if (gp.currentEntity?.id == entity.id) {
        await gp.refreshCurrentEntity();
      }
    } catch (_) {}

    try {
      final audioState = context
          .read<AudioBloc>()
          .state;
      if (audioState is AudioLoaded) {
        final listIndex = audioState.entities.indexWhere(
              (e) => e.id == entity.id,
        );
        if (listIndex != -1) {
          context.read<AudioBloc>().add(UpdateAudioItem(newEntity, listIndex));
        }
      }
    } catch (_) {}

    try {
      context.read<FavouriteChangeBloc>().add(FavouriteUpdated(newEntity));
    } catch (_) {}

    try {
      context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
    } catch (_) {}

    if (mounted) setState(() {});
  }

  Widget _sidebarFavouriteGridItem({
    bool compact = false,
    bool enabled = true,
  }) {
    final idx = playerService.currentIndex;
    if (idx < 0 || idx >= playerService.playlist.length) {
      return _menuGridItem(
        Icons.favorite_border,
        'favourite',
        compact: compact,
        enabled: enabled,
        onTapCustom: () {},
      );
    }
    final entity = playerService.playlist[idx];
    final double iconSz = compact ? 22 : 26;
    final double labelSz = compact ? 10 : 11;
    final double gap = compact ? 4 : 6;
    final EdgeInsets pad = EdgeInsets.symmetric(
      vertical: compact ? 8 : 12,
      horizontal: compact ? 3 : 4,
    );
    final double radius = compact ? 12 : 14;
    final Color heartColor = !enabled
        ? Colors.white38
        : (entity.isFavorite
            ? const Color(0XFF3D57F9)
            : Colors.white);
    final Color labelColor =
        enabled ? Colors.white.withOpacity(0.92) : Colors.white38;

    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? () => _togglePlayerSidebarFavourite(entity)
              : () {
                  AppToast.show(
                    context,
                    context.tr('notAvailableForNetworkPlayback'),
                    type: ToastType.info,
                  );
                },
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.10),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Padding(
              padding: pad,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entity.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: heartColor,
                    size: iconSz,
                  ),
                  SizedBox(height: gap),
                  AppText(
                    'favourite',
                    align: TextAlign.center,
                    color: labelColor,
                    fontSize: labelSz,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Quick menu grid: adapts column count and cell aspect for narrow drawers
  /// (landscape) to avoid vertical overflow inside tiles.
  Widget _buildMainMenuGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final bool land =
            MediaQuery
                .of(context)
                .orientation == Orientation.landscape;
        final int crossAxisCount;
        final double childAspectRatio;
        final double gridPad;
        final double spacing;
        if (w < 228) {
          crossAxisCount = 2;
          childAspectRatio = 0.68;
          gridPad = 10;
          spacing = 6;
        } else if (w < 300 || (land && w < 340)) {
          crossAxisCount = 3;
          childAspectRatio = 0.76;
          gridPad = 12;
          spacing = 6;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 0.88;
          gridPad = 15;
          spacing = land ? 6 : 8;
        }
        final bool compact = w < 300 || (land && w < 360);
        final bool net = playerService.isNetworkPlayback;

        return SingleChildScrollView(
          child: Column(
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                padding: EdgeInsets.all(gridPad),
                children: [
                  _menuGridItem(
                    Icons.queue_play_next,
                    "queue",
                    compact: compact,
                    onTapCustom: () {
                      setState(() => _isQueueVisible = true);
                    },
                  ),
                  _menuGridItem(
                    Icons.aspect_ratio,
                    "ratio",
                    compact: compact,
                    onTapCustom: () {
                      setState(() => _isRatioVisible = true);
                    },
                  ),
                  _menuGridItem(
                    Icons.settings_display,
                    "display",
                    compact: compact,
                    onTapCustom: () {
                      setState(() => _isDisplayVisible = true);
                    },
                    // onTapCustom: () {
                    //   Navigator.pop(context);
                    //   _showDisplaySettings(context);
                    // },
                  ),
                  // _menuGridItem(Icons.bookmark_border, "Bookmark"),
                  _menuGridItem(
                    Icons.content_cut,
                    "cut",
                    compact: compact,
                    enabled: !net,
                    onTapCustom: () async {
                      await playerService.pauseVideo();
                      File? file = await playerService
                          .playlist[playerService.currentIndex]
                          .file;

                      final trimResult = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoTrimScreen(file: file!),
                        ),
                      );
                      if (!mounted) return;
                      if (trimResult == true ||
                          (trimResult is String && trimResult.isNotEmpty)) {
                        context.read<VideoBloc>().add(
                          LoadVideosFromGallery(
                            showLoading: false,
                            isRefresh: true,
                          ),
                        );
                      }

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
                  _sidebarFavouriteGridItem(compact: compact, enabled: !net),
                  _menuGridItem(
                    Icons.playlist_add,
                    "playlist",
                    compact: compact,
                    enabled: !net,
                    onTapCustom: () async {
                      AssetEntity currentAsset =
                      playerService.playlist[playerService.currentIndex];

                      // Ã ÂªÂªÃ ÂªÂ¾Ã ÂªÂ¥ Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ³Ã ÂªÂµÃ Â«â€¹
                      String? filePath = await getFile(currentAsset);

                      if (filePath != null) {
                        setState(() {
                          _isPlayListVisible = true;
                          mediaItem = MediaItem(
                            path: filePath,
                            isNetwork: false,
                            type: currentAsset.type == AssetType.audio
                                ? "audio"
                                : "video",
                            id: currentAsset.id,
                            isFavourite: currentAsset.isFavorite,
                          );
                        });
                        // addToPlaylist(
                        //   MediaItem(
                        //     path: filePath,
                        //     isNetwork: false,
                        //     type: currentAsset.type == AssetType.audio
                        //         ? "audio"
                        //         : "video",
                        //     id: currentAsset.id,
                        //     isFavourite: currentAsset.isFavorite,
                        //   ),
                        //   context,
                        // );
                      } else {
                        AppToast.show(
                          context,
                          context.tr("fileNotFoundOrDeleted"),
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
                    "info",
                    compact: compact,
                    onTapCustom: () {
                      setState(() => _isInfoVisible = true);
                      // showInfoDialog(
                      //   context,
                      //   playerService.playlist[playerService.currentIndex],
                      // );
                    },
                  ),
                  _menuGridItem(
                    Icons.share,
                    "share",
                    compact: compact,
                    onTapCustom: () async {
                      if (playerService.isNetworkPlayback) {
                        final u = playerService.networkStreamUrl ?? '';
                        if (u.isEmpty) {
                          AppToast.show(
                            context,
                            context.tr('notAvailableForNetworkPlayback'),
                            type: ToastType.info,
                          );
                          return;
                        }
                        await Share.share(
                          u,
                          subject: context.tr('networkStream'),
                        );
                      } else {
                        shareItem(
                          context,
                          playerService.playlist[playerService.currentIndex],
                        );
                      }
                    },
                  ),
                  _menuGridItem(
                    Icons.language,
                    "stream",
                    compact: compact,
                    onTapCustom: () {
                      setState(() => _isNetWorkStreamVisible = true);
                      // _showNetworkStreamDialog();
                    },
                  ),
                  // _menuGridItem(Icons.help_outline, "Tutorial"),

                  // _menuGridItem(
                  //   Icons.more_horiz,
                  //   "more",
                  //   onTapCustom: () {
                  //     setState(() => _isMoreMenuVisible = true);
                  //   },
                  // ),

                  //_isDeleteVisible = false;
                  _menuGridItem(
                    Icons.delete,
                    "delete",
                    compact: compact,
                    enabled: !net,
                    onTapCustom: () {
                      setState(() => _isDeleteVisible = true);
                    },
                  ),

                  //_isRenameVisible = false;
                  _menuGridItem(
                    Icons.edit,
                    "rename",
                    compact: compact,
                    enabled: !net,
                    onTapCustom: () {
                      setState(() => _isRenameVisible = true);
                    },
                  ),
                ],
              ),

              Divider(
                color: Colors.white.withOpacity(0.14),
                height: 24,
                thickness: 1,
              ),

              // --- video display ---
              SwitchListTile(
                dense: compact,
                visualDensity: compact
                    ? VisualDensity.compact
                    : VisualDensity.standard,
                tileColor: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: AppText(
                  "videoDisplay",
                  color: Colors.white,
                  fontSize: compact ? 14 : 16,
                ),
                value: _showVideoDisplay,
                activeColor: Color(0XFF3D57F9),
                onChanged: (bool value) {
                  setState(() => _showVideoDisplay = value);
                },
              ),


              // --- Shortcuts Switch ---
              SwitchListTile(
                dense: compact,
                visualDensity: compact
                    ? VisualDensity.compact
                    : VisualDensity.standard,
                tileColor: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: AppText(
                  "shortcuts",
                  color: Colors.white,
                  fontSize: compact ? 14 : 16,
                ),
                value: _showShortcutsInMenu,
                activeColor: Color(0XFF3D57F9),
                onChanged: (bool value) {
                  setState(() => _showShortcutsInMenu = value);
                },
              ),

              // --- Checkbox List
              if (_showShortcutsInMenu)
                ...Provider
                    .of<SettingsProvider>(
                  context,
                )
                    .quickShortcuts
                    .keys
                    .map((String key) {
                  return CheckboxListTile(
                    dense: compact,
                    visualDensity: compact
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                    tileColor: Colors.white.withOpacity(0.04),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    title: AppText(
                      getTranslationKey(key),
                      color: Colors.white.withOpacity(0.9),
                      fontSize: compact ? 12 : 14,
                    ),
                    value: Provider
                        .of<SettingsProvider>(
                      context,
                    )
                        .quickShortcuts[key],
                    activeColor: Color(0XFF3D57F9),
                    checkColor: Colors.white,
                    onChanged: (bool? value) {
                      Provider.of<SettingsProvider>(
                        context,
                        listen: false,
                      ).updateSetting(() {
                        Provider
                            .of<SettingsProvider>(
                          context,
                          listen: false,
                        )
                            .quickShortcuts[key] = value ?? false;
                      });
                    },
                  );
                }).toList(),
            ],
          ),
        );
      },
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

  Widget _buildDeleteView() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final mediaQuery = MediaQuery.of(context);
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;

    // Current index અને entity મેળવો
    int currentIndex = playerService.currentIndex;
    final entity = playerService.playlist[currentIndex];

    return Container(
      // Landscape મોડમાં ઓવરફ્લો અટકાવવા માટે constraints
      constraints: BoxConstraints(
        maxHeight: isLandscape
            ? mediaQuery.size.height * 0.6
            : mediaQuery.size.height * 0.7,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Left aligned title
            children: [
              // ==========================================
              // ૧. ટાઇટલ સેક્શન
              // ==========================================
              AppText(
                'deleteThisFile',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.dialogueSubTitle,
              ),
              const SizedBox(height: 12),

              // ==========================================
              // ૨. મેસેજ સેક્શન
              // ==========================================
              AppText(
                  'areYouSureWantDeleteThisFile',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colors.secondaryText
              ),

              SizedBox(height: isLandscape ? 20 : 30),

              // ==========================================
              // ૩. બટન સેક્શન (Fixed Height 48)
              // ==========================================
              Row(
                children: [
                  // NO Button (Cancel)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: AppButton(
                        title: "no",
                        textColor: colors.dialogueSubTitle,
                        backgroundColor: colors.whiteColor,
                        onTap: () => Navigator.pop(context, false),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // YES Button (Delete Logic)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: AppButton(
                        title: "yes",
                        textColor: Colors.white,
                        backgroundColor: colors.primary,
                        onTap: () async {
                          // 1. Native File Delete logic
                          final List<String> result = await PhotoManager.editor
                              .deleteWithIds([entity.id]);

                          if (result.isNotEmpty) {
                            // 2. Playlist Update Logic
                            setState(() {
                              playerService.playlist.removeAt(currentIndex);

                              if (playerService.playlist.isEmpty) {
                                Navigator.pop(context);
                                return;
                              }

                              if (currentIndex >=
                                  playerService.playlist.length) {
                                playerService.currentIndex =
                                    playerService.playlist.length - 1;
                              }

                              playerService.loadVideo(() {
                                if (mounted) setState(() {});
                              });
                            });

                            // 3. Bloc & Toast Update
                            if (context.mounted) {
                              context.read<VideoBloc>().add(
                                LoadVideosFromGallery(showLoading: false),
                              );
                              AppToast.show(
                                context,
                                context.tr("fileDeletedSuccessfully"),
                                type: ToastType.error,
                              );

                              if (playerService.playlist.isNotEmpty) {
                                Navigator.pop(context, true);
                              }
                            }
                          } else {
                            // Fail Logic
                            if (context.mounted) {
                              AppToast.show(
                                context,
                                context.tr("failedToDeleteFile"),
                                type: ToastType.error,
                              );
                              Navigator.pop(context, false);
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRenameView() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final mediaQuery = MediaQuery.of(context);
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;

    // 1. Current video/asset અને તેનું નામ મેળવો
    AssetEntity currentAsset =
    playerService.playlist[playerService.currentIndex];
    String oldName = currentAsset.title ?? "video";

    // એક્સટેન્શન અલગ કરો
    String fileNameWithoutExtension = oldName.contains('.')
        ? oldName.substring(0, oldName.lastIndexOf('.'))
        : oldName;

    TextEditingController _renameController = TextEditingController(
      text: fileNameWithoutExtension,
    );

    return Container(
      // તમારી UI મુજબ Landscape માં સ્ક્રીન ફાટી ન જાય તે માટે constraints
      constraints: BoxConstraints(
        maxHeight: isLandscape
            ? mediaQuery.size.height * 0.6
            : mediaQuery.size.height * 0.7,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // ૧. ટાઇટલ સેક્શન
              // ==========================================
              AppText(
                'renameVideo',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.dialogueSubTitle,
              ),
              const SizedBox(height: 8),

              // ==========================================
              // ૨. ઇનપુટ સેક્શન (તમારી થીમ મુજબ)
              // ==========================================
              TextField(
                controller: _renameController,
                autofocus: true,
                style: TextStyle(color: colors.appBarTitleColor, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.14),
                  // તમારો ઓપેસિટી કલર
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintText: context.tr("enterNewName"),
                  hintStyle: TextStyle(
                    color: colors.dialogueSubTitle.withOpacity(0.5),
                    fontSize: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // તમારો રેડિયસ
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              // Landscape હોય તો સ્પેસ ઓછી રાખવાની તમારી ટ્રીક
              SizedBox(height: isLandscape ? 16 : 24),

              // ==========================================
              // ૩. બટન સેક્શન (Fixed Height 48)
              // ==========================================
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: SizedBox(
                      height: 48, // ફિક્સ હાઇટ જેથી લેન્ડસ્કેપમાં દબાઈ ન જાય
                      child: AppButton(
                        title: "cancel",
                        backgroundColor: colors.whiteColor,
                        textColor: colors.dialogueSubTitle,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Rename Button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: AppButton(
                        title: "rename",
                        onTap: () async {
                          String newTitle = _renameController.text.trim();
                          if (newTitle.isEmpty) return;

                          // Platform Wise Logic (તમારું નેટિવ લોજિક)
                          if (Platform.isAndroid) {
                            File? originalFile = await currentAsset.file;
                            if (originalFile != null) {
                              try {
                                const editChannel = MethodChannel(
                                  'media_player/editor',
                                );

                                final bool isSuccess = await editChannel
                                    .invokeMethod('renameVideo', {
                                  'path': originalFile.path,
                                  'newName': newTitle,
                                  'isFavourite': currentAsset.isFavorite,
                                });

                                if (isSuccess) {
                                  AssetEntity? updatedAsset =
                                  await AssetEntity.fromId(currentAsset.id);

                                  if (updatedAsset != null && context.mounted) {
                                    setState(() {
                                      playerService.playlist[playerService
                                          .currentIndex] =
                                          updatedAsset;
                                    });
                                  }

                                  if (context.mounted) {
                                    AppToast.show(
                                      context,
                                      context.tr("videoRenamedSuccessfully"),
                                      type: ToastType.success,
                                    );
                                    Navigator.pop(context, true);
                                  }
                                } else {
                                  print("Rename Failed or Cancelled by User");
                                }
                              } catch (e) {
                                print("Native Error: $e");
                              }
                            }
                          } else if (Platform.isIOS) {
                            await PhotoManager.editor.darwin.favoriteAsset(
                              entity: currentAsset,
                              favorite: true,
                            );

                            if (context.mounted) {
                              setState(() {});
                              Navigator.pop(context, true);
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextEditingController urlController = TextEditingController();

  String? _normalizeNetworkUrl(String raw) {
    String url = raw.trim();
    if (url.isEmpty) return null;

    // Common user input: paste domain/youtube link without scheme.
    if (!url.startsWith(RegExp(r'https?://', caseSensitive: false))) {
      if (url.startsWith('www.') ||
          url.contains('youtube.com') ||
          url.contains('youtu.be')) {
        url = 'https://$url';
      }
    }

    try {
      final uri = Uri.parse(url);
      if (uri.isAbsolute &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          (uri.host.isNotEmpty || url.contains('youtu.be'))) {
        return url;
      }
    } catch (_) {}
    return null;
  }

  void _startNetworkStream(String rawInput, {int closeCount = 1}) {
    final normalized = _normalizeNetworkUrl(rawInput);
    if (normalized == null) {
      AppToast.show(
        context,
        context.tr("pleaseEnterValidUrl"),
        type: ToastType.info,
      );
      return;
    }

    for (int i = 0; i < closeCount; i++) {
      Navigator.pop(context);
    }
    playerService.playNetworkStream(normalized, () {
      if (mounted) setState(() {});
    });
  }

  Widget _buildNetworkStreamView() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final mediaQuery = MediaQuery.of(context);
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;


    return Container(
      // Landscape મોડમાં ઓવરફ્લો અટકાવવા માટે constraints
      constraints: BoxConstraints(
        maxHeight: isLandscape
            ? mediaQuery.size.height * 0.6
            : mediaQuery.size.height * 0.7,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Left aligned title
            children: [
              // ==========================================
              // ૧. ટાઇટલ સેક્શન
              // ==========================================
              AppText(
                "networkStream",
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.dialogueSubTitle,
              ),
              const SizedBox(height: 12),

              // ==========================================
              // ૨. સબટાઇટલ અને ઇનપુટ સેક્શન
              // ==========================================
              AppText(
                "enterVideoStream",
                color: colors.secondaryText,
                fontSize: 15,
              ),
              const SizedBox(height: 8),

              TextField(
                controller: urlController,
                autofocus: true,
                style: TextStyle(color: colors.whiteColor, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.14),
                  // તમારી થીમ મુજબ
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintText: "http://example.com/video.mp4",
                  hintStyle: TextStyle(
                    color: colors.dialogueSubTitle.withOpacity(0.5),
                    fontSize: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  // Paste Icon
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.content_paste,
                      color: Color(0XFF3D57F9), // તમારો બ્રાન્ડ બ્લુ કલર
                    ),
                    onPressed: () async {
                      // final data = await Clipboard.getData('text/plain');
                      // if (data != null) urlController.text = data.text!;
                    },
                  ),
                ),
              ),

              SizedBox(height: isLandscape ? 16 : 24),

              // ==========================================
              // ૩. બટન સેક્શન (Fixed Height 48)
              // ==========================================
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: AppButton(
                        title: "cancel",
                        textColor: colors.dialogueSubTitle,
                        backgroundColor: colors.whiteColor,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Play Stream Button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: AppButton(
                        title: "playStream",
                        textColor: Colors.white,
                        backgroundColor: colors.primary, // #3D57F9
                        onTap: () {
                          _startNetworkStream(urlController.text, closeCount: 1);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Info drawer when [GlobalPlayerService.isNetworkPlayback] is true (URL + duration).
  Widget _buildNetworkStreamInfoView() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final mediaQuery = MediaQuery.of(context);
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;
    final url = playerService.networkStreamUrl ?? '';
    final dur = playerService.totalDuration;
    final durLabel = dur.inMilliseconds <= 0
        ? '—'
        : _formatDuration(dur, context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: isLandscape
            ? mediaQuery.size.height * 0.7
            : mediaQuery.size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
            child: AppText(
              "networkStreamDetails",
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.dialogueSubTitle,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(context.tr('streamUrl'), url, colors),
                  _buildInfoRow(
                    context.tr('format'),
                    context.tr('networkStream'),
                    colors,
                  ),
                  _buildInfoRow(context.tr('duration'), durLabel, colors),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: AppButton(
                      title: "share",
                      textColor: Colors.white,
                      backgroundColor: colors.primary,
                      onTap: () async {
                        if (url.isEmpty) return;
                        await Share.share(
                          url,
                          subject: context.tr('networkStream'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: AppButton(
                title: "close",
                backgroundColor: colors.primary,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoView(AssetEntity entity) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final mediaQuery = MediaQuery.of(context);
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Container(
      constraints: BoxConstraints(
        maxHeight: isLandscape
            ? mediaQuery.size.height * 0.7
            : mediaQuery.size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 固定 Title Section (પેડિંગ સાથે)
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
            child: AppText(
              "fileInformation",
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.dialogueSubTitle,
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  _buildInfoRow('Title', entity.title ?? "Unknown", colors),
                  _buildInfoRow('Format', entity.mimeType ?? "Video", colors),
                  _buildInfoRow(
                    'Duration',
                    entity.videoDuration.toString() + " sec",
                    colors,
                  ),
                  _buildInfoRow(
                    'Size',
                    "${(entity.size.width).toInt()} x ${(entity.size.height)
                        .toInt()}",
                    colors,
                  ),
                  _buildInfoRow(
                    'Created',
                    entity.createDateTime
                        .toString()
                        .split('.')
                        .first,
                    colors,
                  ),
                  _buildInfoRow(
                    'Modified',
                    entity.modifiedDateTime
                        .toString()
                        .split('.')
                        .first,
                    colors,
                  ),
                  _buildInfoRow('Path', entity.relativePath ?? 'N/A', colors),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Close Button Section
          Padding(
            padding: const EdgeInsets.all(15),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: AppButton(
                title: "close",
                backgroundColor: colors.primary,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppText(
              label,
              fontSize: 13,
              color: colors.dialogueSubTitle.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: AppText(
              value,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreCategoryMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            "tools",
            color: Color(0XFF3D57F9),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
          const SizedBox(height: 10),
          _textButtonItem("delete", () async {
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
            _textButtonItem("rename", () async {
              AssetEntity currentAsset =
              playerService.playlist[playerService.currentIndex];

              if (Platform.isAndroid) {
                String oldName = currentAsset.title ?? "video";
                String extension = oldName.contains('.')
                    ? oldName
                    .split('.')
                    .last
                    : "mp4";
                String fileNameWithoutExtension = oldName.contains('.')
                    ? oldName.substring(0, oldName.lastIndexOf('.'))
                    : oldName;

                TextEditingController _renameController = TextEditingController(
                  text: fileNameWithoutExtension,
                );

                showDialog(
                  context: context,
                  builder: (context) =>
                      AlertDialog(
                        title: const AppText("renameVideo"),
                        content: TextField(
                          controller: _renameController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: context.tr("enterNewName"),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const AppText("cancel"),
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
                                      SnackBar(
                                        content: AppText(
                                          "videoRenamedSuccessfully",
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
                            child: const AppText("rename"),
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
          _textButtonItem("lock", () {}),
          _textButtonItem("settings", () {}),

          const SizedBox(height: 30),

          const AppText(
            "help_upper",
            color: Color(0XFF3D57F9),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
          const SizedBox(height: 10),
          _textButtonItem("faq", () {}),
          _textButtonItem("about", () {}),
        ],
      ),
    );
  }

  Widget _textButtonItem(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            backgroundColor: Colors.white.withOpacity(0.07),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
          ),
          child: AppText(
            title,
            color: Colors.white.withOpacity(0.95),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _menuGridItem(IconData icon,
      String title, {
        VoidCallback? onTapCustom,
        bool compact = false,
        bool enabled = true,
      }) {
    final double iconSz = compact ? 22 : 26;
    final double fontSz = compact ? 10 : 11;
    final double gap = compact ? 4 : 6;
    final EdgeInsets pad = EdgeInsets.symmetric(
      vertical: compact ? 8 : 12,
      horizontal: compact ? 3 : 4,
    );
    final double radius = compact ? 12 : 14;
    final double lineHeight = compact ? 1.05 : 1.15;
    final Color iconColor = enabled ? Colors.white : Colors.white38;
    final Color labelColor =
        enabled ? Colors.white.withOpacity(0.92) : Colors.white38;

    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? (onTapCustom ?? () {})
              : () {
                  AppToast.show(
                    context,
                    context.tr('notAvailableForNetworkPlayback'),
                    type: ToastType.info,
                  );
                },
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.11),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Padding(
              padding: pad,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: iconColor, size: iconSz),
                  SizedBox(height: gap),
                  AppText(
                    title,
                    align: TextAlign.center,
                    color: labelColor,
                    fontSize: fontSz,
                    maxLines: 2,
                    height: lineHeight,
                  ),
                ],
              ),
            ),
          ),
        ),
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
              const AppText(
                "tools",
                color: Color(0XFF3D57F9),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    label: const AppText("delete", color: Colors.white),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    label: const AppText("rename", color: Colors.white),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.lock_outline, color: Colors.white),
                    label: const AppText("lock", color: Colors.white),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.settings, color: Colors.white),
                    label: const AppText("settings", color: Colors.white),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 30),

              // Category 2: Help
              const AppText(
                "help",
                color: Color(0XFF3D57F9),
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
                    label: const AppText("faq", color: Colors.white),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    label: const AppText("about", color: Colors.white),
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
            _onUserPlayPauseToggle();
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
      final settings = Provider.of<SettingsProvider>(context);
      final playedColor = settings.progressBarCategory == "Flat"
          ? settings.progressBarColor.withOpacity(0.8)
          : settings.progressBarColor;

      // બાકી રહેલો સમય ગણવા માટે
      final remainingDuration = playerService.totalDuration - playerService.currentPosition;

      return Row(
        children: [
          Text(
            _formatDuration(playerService.currentPosition, context),
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
          // અહીં પ્રોપર કન્ડિશન મૂકેલી છે
          Text(
            settings.showRemainingTime
                ? "-${_formatDuration(remainingDuration, context)}"
                : _formatDuration(playerService.totalDuration, context),
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
                            _onUserPlayPauseToggle();
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
                    // IconButton(
                    //   padding: EdgeInsets.zero,
                    //   constraints: const BoxConstraints(),
                    //   icon: Icon(
                    //     _getFitIcon(_videoFit),
                    //     color: Colors.white,
                    //     size: 20,
                    //   ),
                    //   onPressed: () {
                    //     setState(() {
                    //       if (_videoFit == BoxFit.contain)
                    //         _videoFit = BoxFit.cover;
                    //       else if (_videoFit == BoxFit.cover)
                    //         _videoFit = BoxFit.fill;
                    //       else if (_videoFit == BoxFit.fill)
                    //         _videoFit = BoxFit.none;
                    //       else
                    //         _videoFit = BoxFit.contain;
                    //       _overlayText = _getFitText(_videoFit,context);
                    //     });
                    //     _overlayTextTimer?.cancel();
                    //     _overlayTextTimer = Timer(
                    //       const Duration(seconds: 2),
                    //       () {
                    //         if (mounted) setState(() => _overlayText = null);
                    //       },
                    //     );
                    //   },
                    // ),
                    // const SizedBox(width: 5),
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

  String _getFitText(BoxFit fit, BuildContext context) {
    switch (fit) {
      case BoxFit.contain:
        return context.tr("fitToScreen");
      case BoxFit.cover:
        return context.tr("crop");
      case BoxFit.fill:
        return context.tr("stretch");
      case BoxFit.none:
        return context.tr("original100");
      default:
        return context.tr("fitToScreen");
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
        context.tr("screenShotSaved"),
        type: ToastType.success,
      );
    } catch (e) {
      print("Screenshot Error: $e");
      AppToast.show(
        context,
        context.tr("errorSavingScreenShot"),
        type: ToastType.error,
      );
    }
  }

  void _handleABRepeat() {
    final currentPos = playerService.currentPosition;
    if (_pointA == null) {
      _pointA = currentPos;
      AppToast.show(context, context.tr("pointASet"));
    } else if (_pointB == null) {
      _pointB = currentPos;
      AppToast.show(context, context.tr("pointBSetRepeating"));
      playerService.addVideoListener(_checkABRepeat);
    } else {
      _pointA = null;
      _pointB = null;
      playerService.removeVideoListener(_checkABRepeat);
      AppToast.show(context, context.tr("abCleared"));
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

                const AppText(
                  "videoSettings",
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12, thickness: 1),
                const SizedBox(height: 10),

                // 1. Playback Speed Item
                _buildSettingsTile(
                  icon: Icons.speed_rounded,
                  title: "playbackSpeed",
                  value: _formatPlaybackSpeed(
                    playerService.playbackSpeed,
                    context,
                  ),
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
                //     // ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¹ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¤ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â®ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¡ Aspect Ratio ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â²ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂµÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¶ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨ ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¹ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â² ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â°ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¶ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¹
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

  String _formatPlaybackSpeed(double speed, BuildContext context) {
    // 1. Convert the speed double value to a string (e.g., 1.25)
    String speedStr = speed.toString();

    // 2. Split the string into individual characters and translate digits
    String localizedSpeed = speedStr
        .split('')
        .map((char) {
          // Check if the character is a digit between 0 and 9
          if (RegExp(r'[0-9]').hasMatch(char)) {
            // Find the localized translation key like '_0', '_1', etc.
            String localizedDigit = context.tr('_$char');

            // If translation is not found, keep the original digit (e.g., '1')
            return localizedDigit != '_$char' ? localizedDigit : char;
          }
          // Keep dots (.) as they are
          return char;
        })
        .join('');

    // 3. Append 'x' at the end of the localized speed (e.g., Ã Â«Â§.Ã Â«Â«x)
    return "${localizedSpeed}x";
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
        title: AppText(
          title,
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              value,
              color: Color(0XFF3D57F9),
              fontSize: 14,
              fontWeight: FontWeight.bold,
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
                    child: AppText(
                      "playbackSpeed",
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                            title: AppText(
                              "${context.tr('_${speed}x')}",
                              color: isSelected
                                  ? Color(0XFF3D57F9)
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            trailing: isSelected
                                ? const AppText(
                                    "current",
                                    color: Colors.white38,
                                    fontSize: 12,
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

  String _formatDuration(Duration? duration, BuildContext context) {
    if (duration == null) return "00:00";

    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;

    String hoursStr = hours.toString().padLeft(2, '0');
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = seconds.toString().padLeft(2, '0');

    String rawTime;
    if (hours > 0) {
      // જો ૧ કલાકથી મોટો વિડિયો હોય તો: 01:05:20
      rawTime = "$hoursStr:$minutesStr:$secondsStr";
    } else {
      // જો નાનો વિડિયો હોય તો: 05:20
      rawTime = "$minutesStr:$secondsStr";
    }

    // નંબર્સનું લોકલાઈઝેશન કરવા માટે (જેમ કે 0->૦, 1->૧ વગેરે)
    return _localizeNumbers(rawTime, context);
  }

// આ એક સપોર્ટિવ ફંક્શન છે જે આખા ટાઈમ સ્ટ્રિંગના નંબર્સને કન્વર્ટ કરશે
  String _localizeNumbers(String input, BuildContext context) {
    String output = "";
    for (int i = 0; i < input.length; i++) {
      String char = input[i];
      if (char == ':') {
        output += ':';
      } else {
        // '_0', '_1' વગેરે કીઝ ડાયરેક્ટ ટ્રાન્સલેટ થશે
        output += context.tr('_$char');
      }
    }
    return output;
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
      backgroundColor: Colors.transparent,
      // Ã Âªâ€¢Ã ÂªÂ¾Ã ÂªÅ¡ Ã ÂªÅ“Ã Â«â€¡Ã ÂªÂµÃ Â«â‚¬ Ã Âªâ€¦Ã ÂªÂ¸Ã ÂªÂ° Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡
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
                        const AppText(
                          "settings",
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
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

                      // Ã ÂªÂ«Ã Â«â€¹Ã ÂªÂ¨Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ Ã Â«Â§Ã Â«Â¨-Ã Â«Â§Ã Â«Â© Ã ÂªÂ°Ã ÂªÂ¾Ã Âªâ€“Ã ÂªÂµÃ Â«â‚¬ Ã ÂªÅ“Ã Â«â€¡Ã ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ®Ã Â«â€¹Ã ÂªÅ¸Ã Â«ÂÃ Âªâ€š Ã ÂªÂ¨Ã ÂªÂ¾ Ã ÂªÂ²Ã ÂªÂ¾Ã Âªâ€”Ã Â«â€¡
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        letterSpacing: 0.3,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                      ),

                      tabs: [
                        Tab(text: context.tr("style")),
                        Tab(text: context.tr("screen")),
                        Tab(text: context.tr("controls")),
                        Tab(text: context.tr("navigation")),
                        Tab(text: context.tr("text")),
                        Tab(text: context.tr("layout")),
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
                                  >(
                                    //////////////////////////////////////////////////////////////////////// part 6 new player scareen//////////////////////////////////////////////////////////
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
          AppToast.show(context, context.tr("pipNotSupportedAndroid"));
          return;
        }
        final entered = await playerService.enterPipMode();
        if (!entered) {
          AppToast.show(
            context,
            context.tr("unableToEnterPip"),
            type: ToastType.error,
          );
        }
      } catch (_) {
        AppToast.show(context, context.tr("pipError"), type: ToastType.error);
      }
    } else if (Platform.isIOS) {
      try {
        final supported = await playerService.isPipSupported();
        if (!supported) {
          AppToast.show(context, context.tr("pipNotSupportedIOS"));
          return;
        }
        final entered = await playerService.enterPipMode();
        if (!entered) {
          AppToast.show(context, context.tr("pipUnavailableIOS"));
        }
      } catch (_) {
        AppToast.show(context, context.tr("pipError"), type: ToastType.error);
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
                    const AppText(
                      "equalizer",
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: AppText(
                        settings.equalizerEnabled ? "on" : "off",
                        color: Colors.white,
                      ),
                      value: settings.equalizerEnabled,
                      onChanged: (v) {
                        settings.updateSetting(
                          () => settings.equalizerEnabled = v,
                        );
                        _applyEqualizerSettings(
                          settings,
                          settings.equalizerReverb,
                        );
                        setSheetState(() {});
                      },
                      activeColor: Color(0XFF3D57F9),
                    ),
                    _buildDropdown(
                      "reverb",
                      [
                        "none",
                        "smallRoom",
                        "mediumRoom",
                        "largeRoom",
                        "mediumHall",
                        "largeHall",
                        "plate",
                      ],
                      settings.equalizerReverb,
                      (v) {
                        if (!settings.equalizerEnabled || v == null) return;
                        settings.updateSetting(
                          () => settings.equalizerReverb = v,
                        );
                        _applyEqualizerSettings(
                          settings,
                          settings.equalizerReverb,
                        );
                        setSheetState(() {});
                      },
                    ),
                    _buildSlider(
                      "bassBoost",
                      0,
                      100,
                      settings.equalizerBassBoost,
                      settings.equalizerEnabled
                          ? (v) {
                              settings.updateSetting(
                                () => settings.equalizerBassBoost = v,
                              );
                              _applyEqualizerSettings(
                                settings,
                                settings.equalizerReverb,
                              );
                              setSheetState(() {});
                            }
                          : (_) {},
                    ),
                    _buildSlider(
                      "virtualizer",
                      0,
                      100,
                      settings.equalizerVirtualizer,
                      settings.equalizerEnabled
                          ? (v) {
                              settings.updateSetting(
                                () => settings.equalizerVirtualizer = v,
                              );
                              _applyEqualizerSettings(
                                settings,
                                settings.equalizerReverb,
                              );
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

  Future<void> _applyEqualizerSettings(
    SettingsProvider settings,
    String reverb,
  ) async {
    //  _applyEqualizerSettings( settings,settings.equalizerReverb);
    String reverbPreset = "None";
    switch (reverb) {
      case "smallRoom":
        reverbPreset = "Small Room";
        break;
      case "mediumRoom":
        reverbPreset = "Medium Room";
        break;
      case "largeRoom":
        reverbPreset = "Large Room";
        break;
      case "mediumHall":
        reverbPreset = "Medium Hall";
        break;
      case "largeHall":
        reverbPreset = "Large Hall";
        break;
      case "plate":
        reverbPreset = "Plate";
        break;
      default:
        reverbPreset = "None";
    }
    try {
      await _equalizerChannel.invokeMethod("setEnabled", {
        "enabled": settings.equalizerEnabled,
      });
      if (!settings.equalizerEnabled) return;
      await _equalizerChannel.invokeMethod("setReverb", {
        "value": reverbPreset,
      });
      await _equalizerChannel.invokeMethod("setBassBoost", {
        "value": settings.equalizerBassBoost,
      });
      await _equalizerChannel.invokeMethod("setVirtualizer", {
        "value": settings.equalizerVirtualizer,
      });
    } catch (e) {
      // print("Equalizer Error: $e");
    }
  }

  Widget _controlsTab(SettingsProvider s) {
    final gestureItems = s.gestures.keys.toList();
    final shortcutItems = s.quickShortcuts.keys.toList();

    return _DisplaySettingsScrollBody(
      children: [
        // --- 1. Interaction (Dropdowns) ---
        _buildAttractiveHeader(Icons.touch_app_rounded, "Interaction"),
        _buildSettingsCard(
          child: Column(
            children: [
              _buildDropdown(
                "touchAction",
                [
                  "showInterfacePauseResume",
                  "showInterfaceAndPauseResume",
                  "pauseResume",
                  "showHideInterface",
                ],
                s.touchAction,
                (v) => s.updateSetting(() => s.touchAction = v!),
              ),
              const Divider(color: Colors.white10, height: 25),
              _buildDropdown(
                "lockMode",
                ["lock", "kidsLock", "kidsLockTouchEffects"],
                s.lockMode,
                (v) => s.updateSetting(() => s.lockMode = v!),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        // --- 2. Gestures Grid ---
        _buildAttractiveHeader(Icons.gesture_rounded, "gestures"),
        _buildSettingsCard(
          padding: const EdgeInsets.all(12),
          // Ã Âªâ€”Ã Â«ÂÃ ÂªÂ°Ã Â«â‚¬Ã ÂªÂ¡ Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡ Ã ÂªÂ¥Ã Â«â€¹Ã ÂªÂ¡Ã Â«â‚¬ Ã Âªâ€œÃ Âªâ€ºÃ Â«â‚¬ Ã ÂªÂªÃ Â«â€¡Ã ÂªÂ¡Ã ÂªÂ¿Ã Âªâ€šÃ Âªâ€”
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gestureItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              // Ã Â«Â¨ Ã ÂªÂ²Ã ÂªÂ¾Ã Âªâ€¡Ã ÂªÂ¨Ã ÂªÂ¨Ã ÂªÂ¾ Ã ÂªÅ¸Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡ Ã ÂªÂ¬Ã Â«â€¡Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÂ°Ã Â«â€¡Ã ÂªÂ¶Ã ÂªÂ¿Ã ÂªÂ¯Ã Â«â€¹
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
        _buildAttractiveHeader(Icons.flash_on_rounded, "quickShortcuts"),
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
        _buildAttractiveHeader(Icons.vignette_rounded, "interfaceBehavior"),
        _buildSettingsCard(
          child: Column(
            children: [
              _buildCustomCheckbox(
                "interfaceAutoHide",
                s.controlsInterfaceAutoHideEnabled,
                (v) => s.updateSetting(
                  () => s.controlsInterfaceAutoHideEnabled = v ?? true,
                ),
              ),
              if (s.controlsInterfaceAutoHideEnabled) ...[
                const SizedBox(height: 15),
                _buildSlider(
                  "hideInterval",
                  1,
                  60,
                  s.interfaceAutoHide,
                  (v) => s.updateSetting(() => s.interfaceAutoHide = v),
                ),
              ],
              const Divider(color: Colors.white10, height: 30),
              _buildCustomCheckbox(
                "showInterFaceWhenLocked",
                s.showInterfaceWhenLockedTouched,
                (v) => s.updateSetting(
                  () => s.showInterfaceWhenLockedTouched = v ?? true,
                ),
              ),
            ],
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 0),
        // Ã ÂªÂ¥Ã Â«â€¹Ã ÂªÂ¡Ã Â«â‚¬ Ã Âªâ€°Ã ÂªÂ­Ã Â«â‚¬ Ã ÂªÂ¸Ã Â«ÂÃ ÂªÂªÃ Â«â€¡Ã ÂªÂ¸ Ã Âªâ€ Ã ÂªÂªÃ Â«â€¹
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
              child: AppText(
                title,

                color: isEnabled
                    ? Colors.white.withOpacity(0.9)
                    : Colors.white24,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navigationTab(SettingsProvider s) {
    return _DisplaySettingsScrollBody(
      children: [
        // --- 1. Seeking & Speed Settings ---
        _buildAttractiveHeader(Icons.fast_forward_rounded, "seekBehavior"),
        _buildSettingsCard(
          child: Column(
            children: [
              _buildSlider(
                "seekSpeed",
                2,
                400,
                s.seekSpeed,
                (v) => s.updateSetting(() => s.seekSpeed = v),
              ),
              const Divider(color: Colors.white10, height: 30),
              _buildCustomCheckbox(
                "displayCurrentPosition",
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
          "playbackButtons",
        ),
        _buildSettingsCard(
          child: Column(
            children: [
              _buildCustomCheckbox(
                "forwardBackwardButtons",
                s.forwardBackwardButton,
                (v) =>
                    s.updateSetting(() => s.forwardBackwardButton = v ?? true),
              ),
              if (s.forwardBackwardButton) ...[
                const SizedBox(height: 15),
                _buildSlider(
                  "moveIntervalSec",
                  1,
                  60,
                  s.moveInterval,
                  (v) => s.updateSetting(() => s.moveInterval = v),
                ),
              ],
              const Divider(color: Colors.white10, height: 30),
              _buildCustomCheckbox(
                "previousNextButtons",
                s.previousNextButton,
                (v) => s.updateSetting(() => s.previousNextButton = v ?? true),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: AppText(
            "seekSpeedNote",
            color: Colors.white.withOpacity(0.3),
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _textTab(SettingsProvider s) {
    final normalizedFont = SettingsProvider.normalizeFontValue(s.font);
    if (normalizedFont != s.font) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        s.updateSetting(() => s.font = normalizedFont);
      });
    }

    return Material(
      color: Colors.transparent,
      child: _DisplaySettingsScrollBody(
        children: [
          // --- 1. Typography (Font & Size) ---
          _buildAttractiveHeader(Icons.text_fields_rounded, "typography"),
          _buildSettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _buildDropdown(
                //   "fontFamily",
                //   const [
                //     "default",
                //     "mono",
                //     "sansSerif",
                //     "serif",
                //     "inter",
                //     "roboto",
                //     "olioScript",
                //   ],
                //   normalizedFont,
                //   (v) => s.updateSetting(() => s.font = v!),
                // ),
                // const Divider(color: Colors.white10, height: 30),
                _buildSlider(
                  "fontSize",
                  16,
                  60,
                  s.fontSize,
                  (v) => s.updateSetting(() => s.fontSize = v),
                ),
                const SizedBox(height: 15),
                _buildSlider(
                  "textScale",
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
                        "textColor",
                        s.textColor,
                        onPick: (c) => s.updateSetting(() => s.textColor = c),
                      ),
                    ),
                    _buildCustomCheckbox(
                      "boldText",
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
          _buildAttractiveHeader(Icons.layers_outlined, "visualEffects"),
          _buildSettingsCard(
            child: Column(
              children: [
                _buildColorTileRow(
                  "background",
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
                  "borderStroke",
                  s.hasBorder,
                  s.borderColor,
                  onCheck: (v) => s.updateSetting(() => s.hasBorder = v!),
                  onPick: (c) => s.updateSetting(() => s.borderColor = c),
                ),
                if (s.hasBorder) ...[
                  const SizedBox(height: 15),
                  _buildSlider(
                    "borderWidth",
                    50,
                    300,
                    s.borderSize,
                    (v) => s.updateSetting(() => s.borderSize = v),
                  ),
                  _buildCustomCheckbox(
                    "improveStrokeRendering",
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
                      "shadow",
                      s.shadowEnabled,
                      (v) => s.updateSetting(() => s.shadowEnabled = v ?? true),
                    ),
                    _buildCustomCheckbox(
                      "fadeOut",
                      s.fadeOutEnabled,
                      (v) =>
                          s.updateSetting(() => s.fadeOutEnabled = v ?? false),
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
            "advancedRendering",
          ),
          _buildSettingsCard(
            child: Column(
              children: [
                _buildCustomCheckbox(
                  "improveSSARendering",
                  s.improveSsaRendering,
                  (v) =>
                      s.updateSetting(() => s.improveSsaRendering = v ?? true),
                ),
                const Divider(color: Colors.white10, height: 20),
                _buildCustomCheckbox(
                  "complexScriptsRendering",
                  s.improveComplexScriptRendering,
                  (v) => s.updateSetting(
                    () => s.improveComplexScriptRendering = v ?? true,
                  ),
                ),
                const Divider(color: Colors.white10, height: 20),
                _buildCustomCheckbox(
                  "ignoreSSAFontSpecifications",
                  s.ignoreSsaFont,
                  (v) => s.updateSetting(() => s.ignoreSsaFont = v ?? false),
                ),
                const Divider(color: Colors.white10, height: 20),
                _buildCustomCheckbox(
                  "ignoreSSAFontExp",
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
    );
  }

  Widget _layoutTab(SettingsProvider s) {
    return Material(
      color: Colors.transparent,
      child: _DisplaySettingsScrollBody(
        showScrollbar: false,
        children: [
          // --- 1. Positioning & Alignment ---
          _buildAttractiveHeader(Icons.layers_outlined, "positioning"),
          _buildSettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdown(
                  "textAlignment", // translated key for "Text Alignment"
                  [
                    "left", // translated key for "Left"
                    "center", // translated key for "Center"
                    "right", // translated key for "Right"
                  ],
                  s.layoutAlignment,
                  (v) => s.updateSetting(() => s.layoutAlignment = v!),
                ),
                const Divider(color: Colors.white10, height: 30),

                // Bottom Margins Slider
                _buildSlider(
                  "bottomMargin",
                  0,
                  150,
                  s.bottomMargins,
                  (v) => s.updateSetting(() => s.bottomMargins = v),
                ),

                const SizedBox(height: 10),

                // Fit Subtitles Checkbox
                _buildCustomCheckbox(
                  "fitSubtitlesIntoVideoSize",
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
          _buildAttractiveHeader(Icons.fullscreen_rounded, "layoutBackground"),
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
                      "enableBackground",
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
                          "bgColor",
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
                  const AppText(
                    "thisAddsASolidBackdrop",
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 25),

          // --- 3. Additional Info (Optional) ---
          Center(
            child: AppText(
              "changesAreAppliedInRealTime",
              color: Colors.white24,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _styleTab(SettingsProvider s) {
    return Material(
      color: Colors.transparent,
      child: _DisplaySettingsScrollBody(
        thumbColor: const Color(0XFF3D57F9).withOpacity(0.6),
        // Ã ÂªÂ¤Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â€¹ Ã ÂªÂ¥Ã Â«â‚¬Ã ÂªÂ® Ã Âªâ€¢Ã ÂªÂ²Ã ÂªÂ°
        thickness: 4,
        radius: const Radius.circular(10),
        fadeDuration: const Duration(milliseconds: 500),
        timeToFade: const Duration(milliseconds: 1000),
        children: [
          //////////////////////////////////////////////////////////////////////// part 7 new player scareen//////////////////////////////////////////////////////////

          // --- 1. Appearance  ---
          _buildAttractiveHeader(Icons.auto_awesome_rounded, "appearance"),
          _buildSettingsCard(
            child: Column(
              children: [
                _buildDropdown(
                  "presetStyle",
                  ["default", "inverse"],
                  s.present,
                  (v) => s.updateSetting(() => s.present = v!),
                ),
                const Divider(color: Colors.white10, height: 30),
                _buildSwitch(
                  "visualFrame",
                  s.isFrameEnabled,
                  (v) => s.updateSetting(() => s.isFrameEnabled = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // --- 2. Themes & Colors ---
          _buildAttractiveHeader(Icons.palette_rounded, "themesColors"),
          _buildSettingsCard(
            child: Column(
              children: [
                _buildColorTile(
                  "controlsAccent",
                  s.controlsColor,
                  onPick: (c) => s.updateSetting(() => s.controlsColor = c),
                ),
                const Divider(color: Colors.white10, height: 20),
                _buildColorTile(
                  "backgroundShade",
                  s.controlsBgColor,
                  onPick: (c) => s.updateSetting(() => s.controlsBgColor = c),
                ),
                const Divider(color: Colors.white10, height: 20),
                _buildColorTile(
                  "progressBarTint",
                  s.progressBarColor,
                  onPick: (c) => s.updateSetting(() => s.progressBarColor = c),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // --- 3. Progress Bar Settings ---
          _buildAttractiveHeader(
            Icons.slow_motion_video_rounded,
            "progressBar",
          ),
          _buildSettingsCard(
            child: Column(
              children: [
                _buildDropdown(
                  "uiCategory",
                  ["material", "flat"],
                  s.progressBarCategory,
                  (v) => s.updateSetting(() => s.progressBarCategory = v!),
                ),
                const Divider(color: Colors.white10, height: 30),
                _buildCustomCheckbox(
                  "positionBelowControls",
                  s.isProgressBarBelow,
                  (v) => s.updateSetting(() => s.isProgressBarBelow = v!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Footer Note
          Center(
            child: AppText(
              "customThemesApply",
              color: Colors.white24,
              fontSize: 11,
            ),
          ),
        ],
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
          AppText(
            context.tr(title).toUpperCase(),
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
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
      child: _DisplaySettingsScrollBody(
        thickness: 4.5,
        interactive: true,
        children: [
          // --- Ã Â«Â§. Display & Orientation ---
          _buildAttractiveHeader(
            Icons.screen_rotation_rounded,
            "displayOrientation",
          ),
          _buildSettingsCard(
            child: Column(
              children: [
                _buildDropdown(
                  "orientation",
                  [
                    "landscape",
                    "reverseLandscape",
                    "autoRotationLandscape",
                    "autoRotation",
                    "useSystemDefault",
                    "useVideoOrientation",
                  ],
                  s.orientation,
                  (v) => v != null ? cubit.updateOrientation(v) : null,
                ),
                const Divider(color: Colors.white10, height: 25),
                _buildDropdown(
                  "fullScreenMode",
                  // 'Full Screen Mode' Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡Ã ÂªÂ¨Ã Â«â‚¬ Ã Âªâ€¢Ã Â«â‚¬
                  ["on", "off", "autoSwitch"],
                  s.fullScreenMode,
                  (v) => v != null ? cubit.updateFullScreenMode(v) : null,
                ),
                const Divider(color: Colors.white10, height: 25),
                _buildDropdown(
                  "softButtons",
                  // 'Soft Buttons' Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡Ã ÂªÂ¨Ã Â«â‚¬ Ã Âªâ€¢Ã Â«â‚¬
                  ["show", "hide", "autoHide"],
                  s.softButtonsMode,
                  (v) => v != null ? cubit.updateSoftButtonsMode(v) : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // --- 2. Brightness Control ---
          _buildAttractiveHeader(Icons.wb_sunny_rounded, "brightness"),
          _buildSettingsCard(
            child: Column(
              children: [
                _buildSwitch(
                  "enableBrightnessControl",
                  s.isBrightnessEnabled,
                  (v) => cubit.updateBrightnessEnabled(v),
                ),
                if (s.isBrightnessEnabled) ...[
                  const SizedBox(height: 15),
                  _buildSlider(
                    "level",
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
          _buildAttractiveHeader(Icons.info_outline_rounded, "onScreenInfo"),
          _buildSettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 150,
                      child: _buildCustomCheckbox(
                        "elapsedTime",
                        s.showElapsedTime,
                        (v) => cubit.updateShowElapsedTime(v ?? true),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: _buildCustomCheckbox(
                        "batteryClock",
                        s.showBatteryClock,
                        (v) => cubit.updateShowBatteryClock(v ?? true),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 25),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: _buildCustomCheckbox(
                    "cornerOffset",
                    s.isCornerOffsetEnabled,
                    (s.showElapsedTime || s.showBatteryClock)
                        ? (v) => cubit.updateCornerOffsetEnabled(v ?? false)
                        : null,
                  ),
                ),
                if (s.showElapsedTime || s.showBatteryClock)
                  _buildSlider(
                    "offsetValue",
                    0,
                    150,
                    s.cornerOffset.clamp(0.0, 150.0),
                    (v) => cubit.updateCornerOffset(v),
                  ),

                const Divider(color: Colors.white10, height: 25),

                _buildColorTileRow(
                  "textBackground",
                  s.screenTextBackgroundEnabled,
                  s.screenTextBackgroundColor,
                  onCheck: (v) =>
                      cubit.updateScreenTextBackgroundEnabled(v ?? false),
                  onPick: cubit.updateScreenTextBackgroundColor,
                ),
                const SizedBox(height: 10),
                _buildColorTileRow(
                  "bottomText",
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
            "systemBehavior",
          ),
          _buildSettingsCard(
            child: Column(
              children: [
                _buildCustomCheckbox(
                  "screenRotationButton",
                  s.screenRotationButton,
                  (v) => cubit.updateScreenRotationButton(v ?? true),
                ),
                SizedBox(height: 5),
                const Divider(color: Colors.white10),
                SizedBox(height: 5),
                _buildCustomCheckbox(
                  "batteryClockInTitleBar",
                  s.displayBatteryClockInTitleBar,
                  (v) => cubit.updateDisplayBatteryClockInTitleBar(v ?? true),
                ),
                SizedBox(height: 5),
                const Divider(color: Colors.white10),
                SizedBox(height: 5),
                _buildCustomCheckbox(
                  "showRemainingTime",
                  s.showRemainingTime,
                  (v) => cubit.updateShowRemainingTime(v ?? true),
                ),
                SizedBox(height: 5),
                const Divider(color: Colors.white10),
                SizedBox(height: 5),
                _buildCustomCheckbox(
                  "keepScreenOn",
                  s.keepScreenOn,
                  (v) => cubit.updateKeepScreenOn(v ?? true),
                ),
                SizedBox(height: 5),
                const Divider(color: Colors.white10),
                SizedBox(height: 5),
                _buildCustomCheckbox(
                  "pauseIfObstructed",
                  s.pausePlaybackIfObstructed,
                  (v) => cubit.updatePausePlaybackIfObstructed(v ?? false),
                ),
                SizedBox(height: 5),
                const Divider(color: Colors.white10),
                SizedBox(height: 5),
                _buildCustomCheckbox(
                  "interfaceAtStartup",
                  s.showInterfaceAtStartup,
                  (v) => cubit.updateShowInterfaceAtStartup(v ?? true),
                ),
              ],
            ),
          ),
        ],
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
              ? () {
                  // _iColorPickerVisible = true;
                  _openColorPicker(title, color, onPick);
                }
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
      case "landscape":
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
        ]);
        break;
      case "reverseLandscape":
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case "autoRotationLandscape":
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case "autoRotation":
      case "useSystemDefault":
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
        break;
      case "useVideoOrientation":
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
          child: AppText(
            label,
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            // Ã Âªâ€ Ã Âªâ€ºÃ Â«ÂÃ Âªâ€š Ã Âªâ€”Ã Â«ÂÃ ÂªÂ²Ã ÂªÂ¾Ã ÂªÂ¸ Ã ÂªÂ²Ã Â«ÂÃ Âªâ€¢
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
                  child: AppText(
                    value,
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  /// Label: actual slider value (not `value * 100`). Brightness-style 0.1Ã¢â‚¬â€œ1.0 shows as percent.
  String _formatSliderLabel(
    double min,
    double max,
    double value,
    BuildContext context,
  ) {
    String resultStr = "";

    // 1. If it needs to be shown as a percentage (between 0.09 and 1.0)
    if (max <= 1.0 && min >= 0.09 && min < 1.0) {
      resultStr = "${(value * 100).round()}%";
    }
    // 2. If the value is a whole number (e.g., converting 5.0 to 5)
    else if (value == value.roundToDouble()) {
      resultStr = value.round().toString();
    }
    // 3. If the value is a decimal number (e.g., converting 1.25 to 1.3)
    else {
      resultStr = value.toStringAsFixed(1);
    }

    // Ã°Å¸â€™Â¡ Proper way to split the characters and translate digits
    return resultStr
        .split('')
        .map((char) {
          // Check if the character is a digit between 0 and 9
          if (RegExp(r'[0-9]').hasMatch(char)) {
            // Find the localized translation key like '_0', '_1', etc.
            String localizedDigit = context.tr('_$char');

            // If translation is not found, keep the original digit (e.g., '4')
            return localizedDigit != '_$char' ? localizedDigit : char;
          }
          // Keep dots (.) and percentage signs (%) as they are
          return char;
        })
        .join('');
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
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            "${context.tr(title)}: ${_formatSliderLabel(min, max, clamped, context)}",
            color: Colors.white70,
            fontSize: 12,
          ),
          SizedBox(height: 5),
          Slider(
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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
      title: AppText(title, color: Colors.white, fontSize: 14),
      value: value,
      onChanged: onChange,
      activeColor: Color(0XFF3D57F9),
    );
  }

  // Color Box Widget
  // Widget _buildColorTile(
  //     String title,
  //     Color color, {
  //       ValueChanged<Color>? onPick,
  //       bool enabled = true,
  //     }) {
  //   return ListTile(
  //     title: AppText(
  //       title,
  //       color: enabled ? Colors.white : Colors.grey,
  //       fontSize: 14,
  //     ),
  //     onTap: (onPick != null && enabled)
  //         ? () {
  //       // àª…àª¹àª¿àª¯àª¾àª‚ àª¡à«‡àªŸàª¾ àª¸à«‡àªµ àª•àª°à«‹ àª…àª¨à«‡ àªªà«€àª•àª° àª“àªªàª¨ àª•àª°à«‹
  //       setState(() {
  //         _currentPickerTitle = title;
  //         _currentSelectedColor = color;
  //         _currentColorOnPick = onPick;
  //         _iColorPickerVisible = true; // àªªà«€àª•àª° àª¬àª¤àª¾àªµàªµàª¾ àª®àª¾àªŸà«‡
  //       });
  //     }
  //         : null,
  //     trailing: Container(
  //       width: 24,
  //       height: 24,
  //       decoration: BoxDecoration(
  //         color: color,
  //         shape: BoxShape.circle,
  //         border: Border.all(color: Colors.white),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildColorTile(
    String title,
    Color color, {
    ValueChanged<Color>? onPick,
    bool enabled = true,
  }) {
    return ListTile(
      title: AppText(
        title,
        color: enabled ? Colors.white : Colors.grey,
        fontSize: 14,
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
              if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';

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
                } catch (e) {}
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTightWidth = constraints.maxWidth < 420;
                    final mq = MediaQuery.of(context);
                    final isLandscape = mq.orientation == Orientation.landscape;
                    // Keep the picker usable on short landscape screens.
                    final pickerMaxHeight = isLandscape
                        ? (mq.size.height * 0.42).clamp(220.0, 320.0)
                        : 360.0;

                    final header = isTightWidth
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                title,
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              const SizedBox(height: 12),
                              _hexInputBox(
                                controller: hexController,
                                onChanged: updatePickerFromHex,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: AppText(
                                  title,
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 160,
                                child: _hexInputBox(
                                  controller: hexController,
                                  onChanged: updatePickerFromHex,
                                ),
                              ),
                            ],
                          );

                    final scrollController = ScrollController();
                    return Scrollbar(
                      controller: scrollController,
                      thumbVisibility: true,
                      interactive: true,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              // Portrait: keep the premium narrow sheet look.
                              // Landscape: allow full width so picker can place sliders on the right (like your screenshot).
                              maxWidth: isLandscape
                                  ? constraints.maxWidth
                                  : 560,
                            ),
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
                                header,
                                const SizedBox(height: 25),

                                // --- Color Wheel Section ---
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.02),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                    ),
                                  ),
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: isLandscape
                                            ? constraints.maxWidth
                                            : 560,
                                        maxHeight: pickerMaxHeight,
                                      ),
                                      child: isLandscape
                                          ? SizedBox(
                                              width: constraints.maxWidth,
                                              height: pickerMaxHeight,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.center,
                                                child: ColorPicker(
                                                  pickerColor: selectedColor,
                                                  onColorChanged:
                                                      updateHexFromPicker,
                                                  pickerAreaHeightPercent: 0.7,
                                                  enableAlpha: true,
                                                  displayThumbColor: true,
                                                  paletteType:
                                                      PaletteType.hsvWithHue,
                                                  labelTypes: const [],
                                                  pickerAreaBorderRadius:
                                                      BorderRadius.circular(
                                                        100,
                                                      ),
                                                ),
                                              ),
                                            )
                                          : ColorPicker(
                                              pickerColor: selectedColor,
                                              onColorChanged:
                                                  updateHexFromPicker,
                                              pickerAreaHeightPercent: 0.7,
                                              enableAlpha: true,
                                              displayThumbColor: true,
                                              paletteType:
                                                  PaletteType.hsvWithHue,
                                              labelTypes: const [],
                                              pickerAreaBorderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // --- Modern Quick Presets ---
                                Column(
                                  children: [
                                    const AppText(
                                      "quickSelect",
                                      color: Colors.white24,
                                      fontSize: 10,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    const SizedBox(height: 15),
                                    Wrap(
                                      spacing: 15,
                                      runSpacing: 15,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        _presetCircle(
                                          Colors.red,
                                          setModalState,
                                          (c) {
                                            updateHexFromPicker(c);
                                          },
                                        ),
                                        _presetCircle(
                                          Colors.green,
                                          setModalState,
                                          (c) {
                                            updateHexFromPicker(c);
                                          },
                                        ),
                                        _presetCircle(
                                          Colors.blue,
                                          setModalState,
                                          (c) {
                                            updateHexFromPicker(c);
                                          },
                                        ),
                                        _presetCircle(
                                          const Color(0XFF3D57F9),
                                          setModalState,
                                          (c) {
                                            updateHexFromPicker(c);
                                          },
                                        ),
                                        _presetCircle(
                                          Colors.white,
                                          setModalState,
                                          (c) {
                                            updateHexFromPicker(c);
                                          },
                                        ),
                                        _presetCircle(
                                          Colors.orange,
                                          setModalState,
                                          (c) {
                                            updateHexFromPicker(c);
                                          },
                                        ),
                                        _presetCircle(
                                          Colors.purple,
                                          setModalState,
                                          (c) {
                                            updateHexFromPicker(c);
                                          },
                                        ),
                                        _presetCircle(
                                          Colors.black,
                                          setModalState,
                                          (c) {
                                            updateHexFromPicker(c);
                                          },
                                        ),
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
                                        colors: [
                                          Color(0XFF3D57F9),
                                          Color(0XFF2A40C7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0XFF3D57F9,
                                          ).withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: const AppText(
                                      "applySelection",
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _hexInputBox({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
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
            color: const Color(0XFF3D57F9).withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        cursorColor: const Color(0XFF3D57F9),
        style: const TextStyle(
          color: Color(0XFF3D57F9),
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 1.5,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          hintText: "FFFFFFFF",
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.1),
            fontSize: 12,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 4),
            child: AppText(
              "#",
              color: Colors.white24,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
        ),
      ),
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
      child: const AppText(
        "apply",
        color: Colors.white,
        fontWeight: FontWeight.bold,
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
    // Landscape Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã ÂªÂ¹Ã ÂªÂ¾Ã ÂªË†Ã ÂªÅ¸ Ã Âªâ€œÃ Âªâ€ºÃ Â«â‚¬ Ã ÂªÂ°Ã ÂªÂ¾Ã Âªâ€“Ã ÂªÂµÃ Â«â‚¬ Ã ÂªÂªÃ ÂªÂ¡Ã Â«â€¡
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
                quarterTurns: 3,
                // Ã Âªâ€ Ã ÂªÂ¨Ã ÂªÂ¾Ã ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ¸Ã Â«ÂÃ ÂªÂ²Ã ÂªÂ¾Ã Âªâ€¡Ã ÂªÂ¡Ã ÂªÂ° Ã Âªâ€°Ã ÂªÂ­Ã Â«ÂÃ Âªâ€š Ã ÂªÂ¥Ã ÂªË† Ã ÂªÅ“Ã ÂªÂ¶Ã Â«â€¡
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

  String getTranslationKey(String shortcutName) {
    switch (shortcutName) {
      case "Screen Rotation":
        return "screenRotation";
      case "Playback speed":
        return "playbackSpeed"; // Ã Âªâ€  Ã ÂªÂ¤Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÂ°Ã ÂªÂ¾ Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã ÂªÂ¨Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ¤Ã Â«ÂÃ Âªâ€š Ã ÂªÂªÃ ÂªÂ£ Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂªÃ ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã ÂªÂ¹Ã ÂªÂ¤Ã Â«ÂÃ Âªâ€š Ã ÂªÂÃ ÂªÅ¸Ã ÂªÂ²Ã Â«â€¡ Ã Âªâ€°Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ°Ã Â«â‚¬ Ã ÂªÂ¦Ã Â«â‚¬Ã ÂªÂ§Ã Â«ÂÃ Âªâ€š Ã Âªâ€ºÃ Â«â€¡
      case "Background play":
        return "backgroundPlay";
      case "Loop":
        return "loop";
      case "Mute":
        return "mute";
      case "Shuffle":
        return "shuffle";
      case "Equalizer":
        return "equalizer";
      case "Sleep Timer":
        return "sleepTimer";
      case "A - B Repeat":
        return "abRepeat";
      case "Night Mode":
        return "nightMode";
      case "Customise Items":
        return "customiseItems";
      case "ScreenShot":
        return "screenShot";
      case "Mirror mode":
        return "mirrorMode";
      case "Verticle Flip":
        return "verticleFlip";
      default:
        return shortcutName;
    }
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
  String present = "default";
  bool isFrameEnabled = true;
  bool isBgPlayEnabled = false;
  Color controlsColor = Colors.white;
  Color controlsBgColor = Colors.white.withOpacity(0.40);
  Color progressBarColor = Color(0XFF3D57F9);
  String progressBarCategory = "material";
  bool isProgressBarBelow = false;

  // --- Screen ---
  String orientation = "autoRotation";
  String fullScreenMode = "on";
  String softButtonsMode = "autoHide";
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
  String font = "default";
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

  String touchAction = "showInterfacePauseResume";
  String lockMode = "lock";
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
  String equalizerReverb = "none";
  double equalizerBassBoost = 0.0;
  double equalizerVirtualizer = 0.0;

  String layoutAlignment = "center";
  double bottomMargins = 20.0;
  bool layoutBackgroundEnabled = false;
  Color layoutBackgroundColor = Colors.black54;
  bool fitSubtitlesIntoVideoSize = true;

  /// Valid [font] keys for the Text tab + Hive migration (drops legacy folder picker).
  static String normalizeFontValue(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return 'default';
    const allowed = {
      'default',
      'mono',
      'sansSerif',
      'serif',
      'inter',
      'roboto',
      'olioScript',
    };
    if (allowed.contains(value)) return value;
    if (value == 'selectFontFolder') return 'default';
    final lc = value.toLowerCase();
    if (lc == 'sansserif' || lc == 'sans-serif') return 'sansSerif';
    if (allowed.contains(lc)) return lc;
    return 'default';
  }

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

      font = SettingsProvider.normalizeFontValue(data['font'] ?? font);
      fontSize = (data['fontSize'] ?? fontSize).toDouble();
      textScale = (data['textScale'] ?? textScale).toDouble();
      textColor = Color(data['textColor'] ?? textColor.toARGB32());
      isBold = data['isBold'] ?? isBold;
      subtitleBackgroundEnabled =
          data['subtitleBackgroundEnabled'] ?? subtitleBackgroundEnabled;
      subtitleBackgroundColor = Color(
        data['subtitleBackgroundColor'] ?? subtitleBackgroundColor.toARGB32(),
      );
      hasBorder = data['hasBorder'] ?? hasBorder;
      borderColor = Color(data['borderColor'] ?? borderColor.toARGB32());
      borderSize = (data['borderSize'] ?? borderSize).toDouble();
      improveStrokeRendering =
          data['improveStrokeRendering'] ?? improveStrokeRendering;
      shadowEnabled = data['shadowEnabled'] ?? shadowEnabled;
      fadeOutEnabled = data['fadeOutEnabled'] ?? fadeOutEnabled;
      improveSsaRendering = data['improveSsaRendering'] ?? improveSsaRendering;
      improveComplexScriptRendering =
          data['improveComplexScriptRendering'] ??
          improveComplexScriptRendering;
      ignoreSsaFont = data['ignoreSsaFont'] ?? ignoreSsaFont;
      ignoreBrokenSsaFonts =
          data['ignoreBrokenSsaFonts'] ?? ignoreBrokenSsaFonts;
      layoutAlignment = data['layoutAlignment'] ?? layoutAlignment;
      bottomMargins = (data['bottomMargins'] ?? bottomMargins).toDouble();
      layoutBackgroundEnabled =
          data['layoutBackgroundEnabled'] ?? layoutBackgroundEnabled;
      layoutBackgroundColor = Color(
        data['layoutBackgroundColor'] ?? layoutBackgroundColor.toARGB32(),
      );
      fitSubtitlesIntoVideoSize =
          data['fitSubtitlesIntoVideoSize'] ?? fitSubtitlesIntoVideoSize;

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
        'font': font,
        'fontSize': fontSize,
        'textScale': textScale,
        'textColor': textColor.toARGB32(),
        'isBold': isBold,
        'subtitleBackgroundEnabled': subtitleBackgroundEnabled,
        'subtitleBackgroundColor': subtitleBackgroundColor.toARGB32(),
        'hasBorder': hasBorder,
        'borderColor': borderColor.toARGB32(),
        'borderSize': borderSize,
        'improveStrokeRendering': improveStrokeRendering,
        'shadowEnabled': shadowEnabled,
        'fadeOutEnabled': fadeOutEnabled,
        'improveSsaRendering': improveSsaRendering,
        'improveComplexScriptRendering': improveComplexScriptRendering,
        'ignoreSsaFont': ignoreSsaFont,
        'ignoreBrokenSsaFonts': ignoreBrokenSsaFonts,
        'layoutAlignment': layoutAlignment,
        'bottomMargins': bottomMargins,
        'layoutBackgroundEnabled': layoutBackgroundEnabled,
        'layoutBackgroundColor': layoutBackgroundColor.toARGB32(),
        'fitSubtitlesIntoVideoSize': fitSubtitlesIntoVideoSize,
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

/// One [ScrollController] per display-settings tab so [TabBarView] never shares
/// [PrimaryScrollController] across multiple [ListView]s (fixes RawScrollbar assert).
class _DisplaySettingsScrollBody extends StatefulWidget {
  const _DisplaySettingsScrollBody({
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 40),
    this.showScrollbar = true,
    this.thumbColor,
    this.thickness = 4,
    this.radius = const Radius.circular(10),
    this.fadeDuration,
    this.timeToFade,
    this.interactive,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool showScrollbar;
  final Color? thumbColor;
  final double thickness;
  final Radius radius;
  final Duration? fadeDuration;
  final Duration? timeToFade;
  final bool? interactive;

  @override
  State<_DisplaySettingsScrollBody> createState() =>
      _DisplaySettingsScrollBodyState();
}

class _DisplaySettingsScrollBodyState
    extends State<_DisplaySettingsScrollBody> {
  late final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listView = ListView(
      controller: _controller,
      primary: false,
      padding: widget.padding,
      physics: const BouncingScrollPhysics(),
      children: widget.children,
    );

    if (!widget.showScrollbar) {
      return listView;
    }

    if (widget.thumbColor != null ||
        widget.fadeDuration != null ||
        widget.timeToFade != null) {
      return RawScrollbar(
        controller: _controller,
        thumbColor: widget.thumbColor,
        thickness: widget.thickness,
        radius: widget.radius,
        fadeDuration: widget.fadeDuration ?? const Duration(milliseconds: 300),
        timeToFade: widget.timeToFade ?? const Duration(milliseconds: 600),
        interactive: widget.interactive ?? true,
        child: listView,
      );
    }

    return RawScrollbar(
      controller: _controller,
      thickness: widget.thickness,
      radius: widget.radius,
      interactive: widget.interactive ?? true,
      child: listView,
    );
  }
}

class PlaylistSelectorView extends StatefulWidget {
  final MediaItem currentItem;

  const PlaylistSelectorView({Key? key, required this.currentItem})
    : super(key: key);

  @override
  State<PlaylistSelectorView> createState() => _PlaylistSelectorViewState();
}

class _PlaylistSelectorViewState extends State<PlaylistSelectorView> {
  late final TextEditingController _nameController;
  dynamic _selectedPlaylistIndex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final playlistBox = Hive.box('playlists');

    final filteredPlaylists = playlistBox.values.where((playlist) {
      return (playlist as PlaylistModel).type == widget.currentItem.type;
    }).toList();

    // MediaQuery àª¥à«€ àª¸à«àª•à«àª°à«€àª¨àª¨à«€ àª¸àª¾àªˆàª àª…àª¨à«‡ àª“àª°àª¿àªàª¨à«àªŸà«‡àª¶àª¨ àª®à«‡àª³àªµà«‹
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Container(
      // àªœà«‹ àª†àª¡à«€ àª¸à«àª•à«àª°à«€àª¨ àª¹à«‹àª¯ àª¤à«‹ àª¡àª¾àª¯àª²à«‹àª—àª¨à«€ àª¹àª¾àª‡àªŸ àª²àª¿àª®àª¿àªŸà«‡àª¡ àª•àª°à«€ àª¦àªˆàª àªœà«‡àª¥à«€ àªàª°àª° àª¨ àª†àªµà«‡
      constraints: BoxConstraints(
        maxHeight: isLandscape
            ? mediaQuery.size.height * 0.6
            : mediaQuery.size.height * 0.7,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // à«§. àªàª•à«àªàª¿àª¸à«àªŸàª¿àª‚àª— àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àª¸à«‡àª•à«àª¶àª¨
              // ==========================================
              if (filteredPlaylists.isNotEmpty) ...[
                AppText(
                  "selectExistingPlaylist",
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.dialogueSubTitle,
                ),
                const SizedBox(height: 8),
                // àª†àª¡à«€ àª¸à«àª•à«àª°à«€àª¨ àª®àª¾àªŸà«‡ àª¸à«àªªà«‡àª¸ àª“àª›à«€ àª•àª°à«€
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.14),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: colors.background,
                  hint: AppText(
                    "choosePlaylist",
                    color: colors.dialogueSubTitle.withOpacity(0.7),
                  ),
                  value: _selectedPlaylistIndex,
                  items: List.generate(filteredPlaylists.length, (index) {
                    final playlist = filteredPlaylists[index] as PlaylistModel;
                    return DropdownMenuItem(
                      value: index,
                      child: Text(
                        playlist.name,
                        style: TextStyle(
                          color: colors.appBarTitleColor,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedPlaylistIndex = value;
                      _nameController.clear();
                    });
                  },
                ),

                // àªœà«‹ àª†àª¡à«€ àª¸à«àª•à«àª°à«€àª¨ àª¹à«‹àª¯ àª¤à«‹ àªµàªšà«àªšà«‡àª¨à«àª‚ 'or' àªµàª¾àª³à«àª‚ àª¸à«‡àª•à«àª¶àª¨ àª¨àª¾àª¨à«àª‚ àª°àª¾àª–à«€àª
                SizedBox(height: isLandscape ? 12 : 20),

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: colors.dialogueSubTitle.withOpacity(0.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: AppText(
                        "or",
                        fontSize: 12,
                        color: colors.dialogueSubTitle.withOpacity(0.5),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: colors.dialogueSubTitle.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isLandscape ? 12 : 20),
              ],

              // ==========================================
              // à«¨. àª¨àªµà«àª‚ àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àª¸à«‡àª•à«àª¶àª¨
              // ==========================================
              AppText(
                "orCreateNew",
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.dialogueSubTitle,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: TextStyle(color: colors.whiteColor, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.14),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintText: context.tr("enterName"),
                  hintStyle: TextStyle(
                    color: colors.dialogueSubTitle.withOpacity(0.5),
                    fontSize: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) {
                  if (v.trim().isNotEmpty && _selectedPlaylistIndex != null) {
                    setState(() {
                      _selectedPlaylistIndex = null;
                    });
                  }
                },
              ),

              SizedBox(height: isLandscape ? 16 : 24),

              // ==========================================
              // 3. Button Section with Fixed Height for Landscape
              // ==========================================
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      // Set a fixed height of 48 so it doesn't shrink in landscape mode
                      height: 48,
                      child: AppButton(
                        title: "cancel",
                        backgroundColor: colors.whiteColor,
                        textColor: colors.dialogueSubTitle,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      // Fixed height for Add button as well
                      height: 48,
                      child: AppButton(
                        title: "add",
                        onTap: () {
                          final String newName = _nameController.text.trim();

                          // Add to existing playlist
                          if (_selectedPlaylistIndex != null) {
                            final playlist =
                                filteredPlaylists[_selectedPlaylistIndex]
                                    as PlaylistModel;
                            bool isAlreadyExist = playlist.items.any(
                              (e) => e.path == widget.currentItem.path,
                            );

                            if (!isAlreadyExist) {
                              playlist.items.add(widget.currentItem);
                              final int originalKey = playlist.key;
                              playlistBox.put(originalKey, playlist);

                              Navigator.pop(context);
                              AppToast.show(
                                context,
                                "${context.tr("addedTo")} ${playlist.name}",
                                type: ToastType.success,
                              );
                            } else {
                              AppToast.show(
                                context,
                                "${context.tr("alreadyExistIn")} ${playlist.name}",
                                type: ToastType.info,
                              );
                            }
                          }
                          // Create new playlist
                          else if (newName.isNotEmpty) {
                            bool isDuplicateName = filteredPlaylists.any(
                              (playlist) =>
                                  (playlist as PlaylistModel).name
                                      .trim()
                                      .toLowerCase() ==
                                  newName.toLowerCase(),
                            );

                            if (isDuplicateName) {
                              AppToast.show(
                                context,
                                context.tr("playlistNameAlreadyExists"),
                                type: ToastType.info,
                                // type: ToastType.warning,
                              );
                              return;
                            }

                            final newPlaylist = PlaylistModel(
                              name: newName,
                              items: [widget.currentItem],
                              type: widget.currentItem.type,
                            );

                            playlistBox.add(newPlaylist);
                            Navigator.pop(context);
                            AppToast.show(
                              context,
                              context.tr("newPlaylistCreated"),
                              type: ToastType.success,
                            );
                          } else {
                            AppToast.show(
                              context,
                              context.tr("pleaseSelectOrCreate"),
                              type: ToastType.info,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
