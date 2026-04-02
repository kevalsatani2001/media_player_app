import 'package:marquee/marquee.dart';
import '../services/ads_service.dart';
import '../utils/app_imports.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

class AudioPlayerScreen extends StatefulWidget {
  final MediaItem item;
  final int? index;
  final AssetEntity entity;
  final List<AssetEntity>? entityList;
  bool isPlaylist;

  AudioPlayerScreen({
    super.key,
    required this.item,
    this.index = 0,
    required this.entity,
    this.entityList = const [],
    this.isPlaylist = false,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

enum _AudioMoreAction {
  addToPlaylist,
  properties,
  setAsRingtone,
  setSleepTimer,
  abSetPointA,
  abSetPointB,
  abClearRepeat,
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with WidgetsBindingObserver {
  final GlobalPlayer player = GlobalPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  static const MethodChannel _equalizerChannel =
      MethodChannel("media_player/equalizer");
  static const MethodChannel _ringtoneChannel =
      MethodChannel("media_player/ringtone");

  Color bgColor1 = Colors.grey.shade300;
  Color bgColor2 = Colors.white;
  late PageController _pageController;
  String? _lastProcessedId;
  bool _isUpdatingFromPlayer = false;
  StreamSubscription? _indexSubscription;

  // A-B repeat (audio only)
  Duration? _pointA;
  Duration? _pointB;
  bool _isAbSeeking = false;
  StreamSubscription<Duration>? _positionSubscription;

  // Sleep timer
  Timer? _sleepTimer;
  int? _sleepSecondsLeft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    int initialIdx = 0;
    final list = (widget.entityList != null && widget.entityList!.isNotEmpty)
        ? widget.entityList!
        : [widget.entity];

    initialIdx =
        widget.index ?? list.indexWhere((e) => e.id == widget.entity.id);
    if (initialIdx == -1) initialIdx = 0;

    _pageController = PageController(initialPage: initialIdx);

    _setupInitialPlayer().then((_) {
      _updateBackgroundColors();

      _indexSubscription = player.audioPlayer.currentIndexStream.listen((
          index,
          ) {
        if (index != null && mounted && _pageController.hasClients) {
          if (_pageController.page?.round() != index) {
            _isUpdatingFromPlayer = true;
            _pageController
                .animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutQuad,
            )
                .then((_) => _isUpdatingFromPlayer = false);
          }
        }
      });
    });

    player.addListener(_updateBackgroundColors);

    // A-B repeat: when position reaches point B, seek back to A.
    _positionSubscription = player.audioPlayer.positionStream.listen((pos) {
      if (player.currentType != 'audio') return;
      if (_pointA == null || _pointB == null) return;
      if (_isAbSeeking) return;

      if (pos >= _pointB!) {
        _isAbSeeking = true;
        player.audioPlayer
            .seek(_pointA!)
            .then((_) async {
              // keep playback consistent
              if (player.audioPlayer.playing) {
                await player.audioPlayer.play();
              }
            })
            .whenComplete(() => _isAbSeeking = false);
      }
    });
  }

  Future<void> _updateBackgroundColors() async {
    if (!mounted) return;

    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final list = (widget.entityList != null && widget.entityList!.isNotEmpty)
        ? widget.entityList!
        : [widget.entity];

    int currentIndex = 0;
    if (_pageController.hasClients) {
      currentIndex = _pageController.page?.round() ?? player.currentIndex ?? 0;
    } else {
      currentIndex = player.currentIndex ?? 0;
    }

    if (currentIndex < 0 || currentIndex >= list.length) return;
    final currentEntity = list[currentIndex];

    if (_lastProcessedId == currentEntity.id &&
        bgColor1 != Colors.grey.shade300) {
      return;
    }
    _lastProcessedId = currentEntity.id;

    try {
      final Uint8List? artwork = await _audioQuery.queryArtwork(
        Platform.isIOS
            ? currentEntity.id.hashCode
            : int.parse(currentEntity.id),
        ArtworkType.AUDIO,
        size: 100,
      );

      if (artwork != null && artwork.isNotEmpty) {
        final palette = await PaletteGenerator.fromImageProvider(
          MemoryImage(artwork),
        );
        if (mounted) {
          setState(() {
            bgColor1 =
                palette.dominantColor?.color.withOpacity(0.5) ??
                    colors.primary.withOpacity(0.3);
            bgColor2 =
                palette.darkMutedColor?.color.withOpacity(0.8) ??
                    colors.cardBackground;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            bgColor1 = colors.primary.withOpacity(0.2);
            bgColor2 = colors.cardBackground;
          });
        }
      }
    } catch (e) {
      _lastProcessedId = null;
    }
  }

  Future<void> _setupInitialPlayer() async {
    final list = (widget.entityList != null && widget.entityList!.isNotEmpty)
        ? widget.entityList!
        : [widget.entity];

    if (player.currentEntity?.id == widget.entity.id) {
      int currentIdx = list.indexWhere((e) => e.id == widget.entity.id);
      if (currentIdx != -1 && _pageController.hasClients) {
        _pageController.jumpToPage(currentIdx);
      }
      return;
    }

    if (widget.entityList != null && widget.entityList!.isNotEmpty) {
      await player.initAndPlay(
        entities: widget.entityList!,
        selectedId: widget.entity.id,
      );
    } else {
      await player.initAndPlay(
        entities: [widget.entity],
        selectedId: widget.entity.id,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    player.removeListener(_updateBackgroundColors);
    _positionSubscription?.cancel();
    _sleepTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (player.currentType == "video") {
        player.pause();
      }
    }
  }

  // Get title directly using player data
  String getTitle() {
    final activeItem = player.currentMediaItem ?? widget.item;
    return activeItem.path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return AnimatedBuilder(
      animation: player, // UI updates on every player state change
      builder: (context, _) {
        // Live data fetching
        final currentType =
            player.currentType ??
                (widget.entity.typeInt == 3 ? "audio" : "video");
        final bool isAudio = currentType == "audio";

        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgColor1, bgColor2],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,

                title: SizedBox(
                  height: 30,
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: isAudio
                      ? Marquee(
                    text: getTitle(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    scrollAxis: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    blankSpace: 50.0,
                    velocity: 30.0,
                    pauseAfterRound: const Duration(seconds: 1),
                    accelerationDuration: const Duration(seconds: 1),
                    accelerationCurve: Curves.linear,
                    decelerationDuration: const Duration(
                      milliseconds: 500,
                    ),
                    decelerationCurve: Curves.easeOut,
                  )
                      : AppText(
                    getTitle(),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    maxLines: 1,
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 28,
                      color: colors.blackColor,
                    ),
                  ),
                ),
                centerTitle: true,
                actions: [
                  if ((player.currentEntity ?? widget.entity).typeInt == 2)
                    Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: FavouriteButton(
                        entity: player.currentEntity ?? widget.entity,
                      ),
                    ),
                  if ((player.currentEntity ?? widget.entity).typeInt == 3)
                    PopupMenuButton<_AudioMoreAction>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) async {
                        final entity = player.currentEntity ?? widget.entity;
                        switch (action) {
                          case _AudioMoreAction.addToPlaylist:
                            final file = await entity.file;
                            if (file == null) return;
                            addToPlaylist(
                              MediaItem(
                                id: entity.id,
                                path: file.path,
                                isNetwork: false,
                                type: 'audio',
                                isFavourite: entity.isFavorite,
                              ),
                              context,
                            );
                            break;
                          case _AudioMoreAction.properties:
                            routeToDetailPage(context, entity);
                            break;
                          case _AudioMoreAction.setAsRingtone:
                            await _handleSetAsRingtone(context, entity);
                            break;
                          case _AudioMoreAction.setSleepTimer:
                            _showSleepTimerBottomSheet(context);
                            break;
                          case _AudioMoreAction.abSetPointA:
                            _abSetPointAFromMenu();
                            break;
                          case _AudioMoreAction.abSetPointB:
                            _abSetPointBFromMenu();
                            break;
                          case _AudioMoreAction.abClearRepeat:
                            _abClearRepeatFromMenu();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _AudioMoreAction.addToPlaylist,
                          child: AppText(
                            "addToPlaylist",
                            fontSize: 12,
                          ),
                        ),
                        PopupMenuItem(
                          value: _AudioMoreAction.properties,
                          child: AppText(
                            "properties",
                            fontSize: 12,
                          ),
                        ),
                        PopupMenuItem(
                          value: _AudioMoreAction.setAsRingtone,
                          child: AppText(
                            "setAsRingtone",
                            fontSize: 12,
                          ),
                        ),
                        PopupMenuItem(
                          value: _AudioMoreAction.setSleepTimer,
                          child: AppText(
                            "setSleepTimer",
                            fontSize: 12,
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: _AudioMoreAction.abSetPointA,
                          child: AppText(
                            "abSetPointA",
                            fontSize: 12,
                          ),
                        ),
                        PopupMenuItem(
                          value: _AudioMoreAction.abSetPointB,
                          enabled:
                              _pointA != null && _pointB == null,
                          child: AppText(
                            "abSetPointB",
                            fontSize: 12,
                          ),
                        ),
                        PopupMenuItem(
                          value: _AudioMoreAction.abClearRepeat,
                          enabled: _pointA != null || _pointB != null,
                          child: AppText(
                            "abClearRepeat",
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [Positioned.fill(child: _buildAudioPlayer())],
                    ),
                  ),
                  if (isAudio)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AdHelper.adaptiveBannerWidget(context),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioPlayer() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final list = (widget.entityList != null && widget.entityList!.isNotEmpty)
        ? widget.entityList!
        : [widget.entity];

    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56),
            child: SizedBox(
              height: 345,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    height: 320,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: list.length,
                      onPageChanged: (index) {
                        if (!_isUpdatingFromPlayer) {
                          if (player.audioPlayer.currentIndex != index) {
                            player.audioPlayer.seek(
                              Duration.zero,
                              index: index,
                            );
                          }
                        }
                        // AB repeat is per-track, so reset when switching items.
                        if (_pointA != null || _pointB != null) {
                          setState(() {
                            _pointA = null;
                            _pointB = null;
                          });
                        }
                        _updateBackgroundColors();
                      },
                      itemBuilder: (context, index) {
                        final entity = list[index];
                        return ClipPath(
                          clipper: _MyCustomClipper(),
                          child: Container(
                            width: double.infinity,
                            height: 320,
                            decoration: BoxDecoration(color: colors.dropdownBg),
                            child: FutureBuilder<Uint8List?>(
                              key: ValueKey(entity.id),
                              future: _audioQuery.queryArtwork(
                                Platform.isIOS
                                    ? entity.id.hashCode
                                    : int.parse(entity.id),
                                ArtworkType.AUDIO,
                                format: ArtworkFormat.JPEG,
                                size: 1000,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.hasData &&
                                    snapshot.data != null &&
                                    snapshot.data!.isNotEmpty) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                    gaplessPlayback: true,
                                  );
                                }
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(color: colors.dropdownBg);
                                }
                                return Padding(
                                  padding: const EdgeInsets.all(23),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.5, end: 1.0),
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.elasticOut,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: child,
                                      );
                                    },
                                    child: AppImage(
                                      src: AppSvg.musicSelected,
                                      fit: BoxFit.contain,
                                      color: colors.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.whiteColor,
                          boxShadow: [
                            BoxShadow(
                              offset: const Offset(0, 0),
                              blurRadius: 15,
                              color: colors.blackColor.withOpacity(0.20),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: FavouriteButton(
                            key: ValueKey(
                              player.currentEntity?.id ?? widget.entity.id,
                            ),
                            entity: player.currentEntity ?? widget.entity,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // --- Title Section ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppText(
              getTitle(),
              fontSize: 18,
              maxLines: 2,
              fontWeight: FontWeight.w600,
              color: colors.blackColor,
              align: TextAlign.center,
            ),
          ),
          const Spacer(),

          // --- Main Controls Section ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: StreamBuilder<Duration>(
              stream: player.audioPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = player.audioPlayer.duration ?? Duration.zero;

                return Column(
                  children: [
                    // --- Custom Slider ---
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                        trackHeight: 4,
                        activeTrackColor: colors.primary,
                        inactiveTrackColor: colors.blackColor.withOpacity(0.1),
                        thumbColor: colors.primary,
                      ),
                      child: Slider(
                        padding: EdgeInsets.zero,
                        min: 0,
                        max: duration.inMilliseconds.toDouble().clamp(
                          1,
                          double.infinity,
                        ),
                        value: position.inMilliseconds.toDouble().clamp(
                          0,
                          duration.inMilliseconds.toDouble(),
                        ),
                        onChanged: (v) => player.audioPlayer.seek(
                          Duration(milliseconds: v.toInt()),
                        ),
                      ),
                    ),

                    // --- Time Row ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          _fmt(position),
                          fontSize: 12,
                          color: colors.blackColor.withOpacity(0.6),
                        ),
                        AppText(
                          _fmt(duration),
                          fontSize: 12,
                          color: colors.blackColor.withOpacity(0.6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // --- Advanced Features Row (Shuffle, A-B, Equalizer, Loop) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await player.toggleShuffle();
                          },
                          icon: Icon(
                            Icons.shuffle,
                            size: 22,
                            color: player.isShuffle
                                ? colors.primary
                                : colors.blackColor.withOpacity(0.7),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            final pos = player.position;
                            setState(() {
                              // 1st tap => set A
                              if (_pointA == null || _pointB != null) {
                                _pointA = pos;
                                _pointB = null;
                              } else {
                                // 2nd tap => set B
                                _pointB = pos;
                              }
                              // 3rd tap (when B is set) resets on next tap due to logic above
                            });
                          },
                          icon: Icon(
                            Icons.repeat_one_on_outlined,
                            size: 22,
                            color: (_pointA != null && _pointB != null)
                                ? colors.primary
                                : colors.blackColor.withOpacity(0.7),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _showEqualizerBottomSheet();
                          },
                          icon: Icon(
                            Icons.equalizer_rounded,
                            size: 22,
                            color: colors.blackColor.withOpacity(0.7),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await player.toggleLoopMode();
                          },
                          icon: Icon(
                            player.loopMode == LoopMode.one
                                ? Icons.repeat_one_rounded
                                : player.loopMode == LoopMode.all
                                    ? Icons.repeat_rounded
                                    : Icons.loop_rounded,
                            size: 22,
                            color: player.loopMode != LoopMode.off
                                ? colors.primary
                                : colors.blackColor.withOpacity(0.7),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showPlaybackSpeedBottomSheet(),
                          icon: Icon(
                            Icons.speed,
                            size: 22,
                            color: colors.blackColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // --- Playback Controls Row ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // === Skip Previous ===
                        IconButton(
                          iconSize: 32,
                          onPressed: () async {
                            if (_pageController.hasClients) {
                              int currentIdx =
                                  _pageController.page?.round() ?? 0;
                              int prevIdx = currentIdx - 1;
                              if (prevIdx >= 0) {
                                _pageController.animateToPage(
                                  prevIdx,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              }
                            }
                          },
                          icon: AppImage(
                            src: AppSvg.skipPrev,
                            color: colors.blackColor,
                          ),
                        ),
                        const SizedBox(width: 20),

                        StreamBuilder<bool>(
                          stream: player.audioPlayer.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            return GestureDetector(
                              onTap: () =>
                              isPlaying ? player.pause() : player.resume(),
                              child: Container(
                                height: 61,
                                width: 61,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.primary.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: AppImage(
                                    src: isPlaying
                                        ? AppSvg.pauseVid
                                        : AppSvg.playVid,
                                    height: 61,
                                    width: 61,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),

                        // === Skip Next àª¬àªŸàª¨ ===
                        IconButton(
                          iconSize: 32,
                          onPressed: () async {
                            if (_pageController.hasClients) {
                              int currentIdx =
                                  _pageController.page?.round() ?? 0;
                              int nextIdx =
                                  currentIdx + 1; // àª…àª¹à«€àª‚ àªªà«àª²àª¸ (+) àª†àªµàª¶à«‡

                              if (nextIdx < list.length) {
                                _pageController.animateToPage(
                                  nextIdx,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              }
                            }
                          },
                          icon: AppImage(
                            src: AppSvg.skipNext,
                            color: colors.blackColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPlaybackSpeedBottomSheet() async {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    await showModalBottomSheet<double>(
      context: context,
      backgroundColor: colors.dropdownBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        double tempSpeed = player.playbackSpeed;
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    "Playback speed",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 10),
                  AppText(
                    "${tempSpeed.toStringAsFixed(2)}x",
                    fontSize: 16,
                    color: colors.dialogueSubTitle,
                  ),
                  Slider(
                    value: tempSpeed.clamp(0.5, 2.0),
                    min: 0.5,
                    max: 2.0,
                    divisions: 30,
                    onChanged: (v) {
                      setStateModal(() => tempSpeed = v);
                    },
                    onChangeEnd: (v) async {
                      await player.setPlaybackSpeed(v);
                      if (mounted) setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          title: "0.75x",
                          onTap: () async {
                            await player.setPlaybackSpeed(0.75);
                            Navigator.pop(ctx, 0.75);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          title: "1.0x",
                          onTap: () async {
                            await player.setPlaybackSpeed(1.0);
                            Navigator.pop(ctx, 1.0);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          title: "1.5x",
                          onTap: () async {
                            await player.setPlaybackSpeed(1.5);
                            Navigator.pop(ctx, 1.5);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEqualizerBottomSheet() {
    if (!Platform.isAndroid) {
      AppToast.show(
        context,
        "Equalizer not supported on iOS",
        type: ToastType.info,
      );
      return;
    }

    final settings = Provider.of<SettingsProvider>(context, listen: false);

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
                      onChanged: (v) async {
                        settings.updateSetting(
                          () => settings.equalizerEnabled = v,
                        );
                        await _applyEqualizerSettings(
                          settings,
                          settings.equalizerReverb,
                        );
                        setSheetState(() {});
                      },
                      activeColor: const Color(0XFF3D57F9),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: settings.equalizerReverb,
                      dropdownColor: Colors.grey[900],
                      decoration: const InputDecoration(
                        labelText: "reverb",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        "none",
                        "smallRoom",
                        "mediumRoom",
                        "largeRoom",
                        "mediumHall",
                        "largeHall",
                        "plate"
                      ].map((v) {
                        return DropdownMenuItem<String>(
                          value: v,
                          child: Text(v),
                        );
                      }).toList(),
                      onChanged: (v) async {
                        if (v == null) return;
                        settings.updateSetting(() => settings.equalizerReverb = v);
                        await _applyEqualizerSettings(settings, v);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildEqSlider(
                      label: "bassBoost",
                      min: 0,
                      max: 100,
                      value: settings.equalizerBassBoost,
                      enabled: settings.equalizerEnabled,
                      onChanged: (v) async {
                        settings.updateSetting(() => settings.equalizerBassBoost = v);
                        await _applyEqualizerSettings(settings, settings.equalizerReverb);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildEqSlider(
                      label: "virtualizer",
                      min: 0,
                      max: 100,
                      value: settings.equalizerVirtualizer,
                      enabled: settings.equalizerEnabled,
                      onChanged: (v) async {
                        settings.updateSetting(() => settings.equalizerVirtualizer = v);
                        await _applyEqualizerSettings(settings, settings.equalizerReverb);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEqSlider({
    required String label,
    required double min,
    required double max,
    required double value,
    required bool enabled,
    required ValueChanged<double> onChanged,
  }) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return IgnorePointer(
      ignoring: !enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            "$label: ${value.toStringAsFixed(0)}",
            color: colors.dialogueSubTitle,
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: enabled ? onChanged : (_) {},
          ),
        ],
      ),
    );
  }

  Future<void> _applyEqualizerSettings(
    SettingsProvider settings,
    String reverb,
  ) async {
    // Map our stored values -> Android preset names.
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
    } catch (_) {
      // If EQ fails on some devices, ignore to avoid breaking playback UI.
    }
  }

  Future<void> _handleSetAsRingtone(
    BuildContext context,
    AssetEntity entity,
  ) async {
    if (!Platform.isAndroid) {
      AppToast.show(
        context,
        "Setting ringtone not supported on iOS",
        type: ToastType.info,
      );
      return;
    }

    final id = int.tryParse(entity.id);
    if (id == null) {
      AppToast.show(
        context,
        "Invalid audio id for ringtone",
        type: ToastType.error,
      );
      return;
    }

    try {
      final ok = await _ringtoneChannel.invokeMethod<bool>(
        "setRingtone",
        {"id": id},
      );
      AppToast.show(
        context,
        ok == true ? "Ringtone set successfully" : "Failed to set ringtone",
        type: ok == true ? ToastType.success : ToastType.error,
      );
    } catch (_) {
      AppToast.show(
        context,
        "Failed to set ringtone",
        type: ToastType.error,
      );
    }
  }

  void _showSleepTimerBottomSheet(BuildContext ctx) {
    final colors = Theme.of(ctx).extension<AppThemeColors>()!;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: colors.dropdownBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        const options = <int>[5, 10, 15, 30, 45, 60];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                "Sleep timer",
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 10),
              ...options.map(
                (sec) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: AppButton(
                    title: "${sec} min",
                    onTap: () {
                      _sleepTimer?.cancel();
                      _startSleepTimer(sec * 60);
                      Navigator.pop(sheetCtx);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AppButton(
                title: "Cancel",
                backgroundColor: colors.whiteColor,
                textColor: colors.dialogueSubTitle,
                onTap: () {
                  _sleepTimer?.cancel();
                  setState(() {
                    _sleepSecondsLeft = null;
                  });
                  Navigator.pop(sheetCtx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startSleepTimer(int totalSeconds) {
    if (player.currentType != 'audio') return;

    _sleepSecondsLeft = totalSeconds;
    _sleepTimer?.cancel();

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }

      _sleepSecondsLeft = (_sleepSecondsLeft ?? 1) - 1;
      if ((_sleepSecondsLeft ?? 0) <= 0) {
        t.cancel();
        player.pause();
        if (mounted) {
          AppToast.show(
            context,
            context.tr("sleepTimerEnded"),
            type: ToastType.info,
          );
        }
        setState(() => _sleepSecondsLeft = null);
      } else {
        setState(() {});
      }
    });
  }

  void _abSetPointAFromMenu() {
    if (player.currentType != 'audio') return;
    final pos = player.position;
    setState(() {
      _pointA = pos;
      _pointB = null;
    });
    AppToast.show(context, context.tr("pointASet"));
  }

  void _abSetPointBFromMenu() {
    if (player.currentType != 'audio') return;
    if (_pointA == null || _pointB != null) return;
    final pos = player.position;
    setState(() {
      _pointB = pos;
    });
    AppToast.show(context, context.tr("pointBSetRepeating"));
  }

  void _abClearRepeatFromMenu() {
    if (_pointA == null && _pointB == null) return;
    setState(() {
      _pointA = null;
      _pointB = null;
    });
    AppToast.show(context, context.tr("abCleared"));
  }

  String _fmt(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  Widget _buildVideoLoadingPlaceholder() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withOpacity(0.30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(child: CustomLoader()),
    );
  }
}

class _MyCustomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return CustomShape().getOuterPath(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}