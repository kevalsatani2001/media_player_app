import '../utils/app_imports.dart';

class PlayerScreen extends StatefulWidget {
  final MediaItem item;
  final int? index;
  final AssetEntity entity;
  final List<AssetEntity>? entityList;
  bool isPlaylist;

  PlayerScreen({
    super.key,
    required this.item,
    this.index = 0,
    required this.entity,
    this.entityList = const [],
    this.isPlaylist = false,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  // GlobalPlayer Ã ÂªÂ¨Ã Â«â‚¬ Ã Âªâ€¡Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¸ Ã ÂªÂ²Ã Â«â€¹
  final GlobalPlayer player = GlobalPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // àª† àª«à«‡àª°àª«àª¾àª° àª•àª°à«‹:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupInitialPlayer();
    });
  }

  Future<void> _setupInitialPlayer() async {
    // 1. If the same item is already playing, do not reload it
    if (player.currentEntity?.id == widget.entity.id) {
      return;
    }

    // 2. Pass list for playlist functionality
    if (widget.entityList != null && widget.entityList!.isNotEmpty) {
      print("type is ======   1  ${player.currentType}");
      await player.initAndPlay(
        entities: widget.entityList!,
        selectedId: widget.entity.id,
      );
    } else {
      // Even for a single item, send it as a list
      print("type is ======   2  ${player.currentType}");
      await player.initAndPlay(
        entities: [widget.entity],
        selectedId: widget.entity.id,
      );
    }
  }

  @override
  void dispose() {
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
        final currentType = player.currentType ?? (widget.entity.typeInt == 3 ? "audio" : "video");
        final bool isAudio = currentType == "audio";

        return Scaffold(
          appBar: AppBar(
            title: AppText(
              isAudio ? "audio" : getTitle(),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            leading: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  // if ((player.currentEntity ?? widget.entity).typeInt == 2){
                  //   player.stopAndClose();
                  //   if (mounted) {
                  //     setState(() {});
                  //   }
                  // }
                  Navigator.pop(context);
                },
                child: AppImage(
                  src: AppSvg.backArrowIcon,
                  height: 20,
                  width: 20,
                ),
              ),
            ),
            centerTitle: true,
            actions: [
              // Favorite Button: Use live entity from player
              if ((player.currentEntity ?? widget.entity).typeInt == 2)
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: FavouriteButton(
                    entity: player.currentEntity ?? widget.entity,
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: isAudio
                    ? _buildAudioPlayer()
                    : // Hero વિજેટમાં ટેગ આ રીતે રાખો
                Hero(
                  tag: 'player_${widget.entity.id}', // ટાઇપ કાઢી નાખો, માત્ર ID રાખો
                  child: Material(
                    color: Colors.transparent, // Material ને ટ્રાન્સપરન્ટ રાખો
                    child: _buildVideoPlayer(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudioPlayer() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: colors.whiteColor),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 70),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56),
            child: SizedBox(
              height: 345,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: 320,
                    decoration: ShapeDecoration(
                      shape: CustomShape(),
                      color: colors.background,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(23),
                      child: AppImage(
                        src: AppSvg.musicSelected,
                        fit: BoxFit.cover,
                        color: colors.primary,
                      ),
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
          const SizedBox(height: 62),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppText(
              getTitle(),
              fontSize: 18,
              maxLines: 2,
              fontWeight: FontWeight.w600,
              color: colors.grey1,
              align: TextAlign.center,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: StreamBuilder<Duration>(
              stream: player.audioPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = player.audioPlayer.duration ?? Duration.zero;

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: SliderComponentShape.noThumb,
                        trackHeight: 2,
                        activeTrackColor: colors.primary,
                        inactiveTrackColor: colors.textFieldBorder,
                      ),
                      child: Slider(
                        min: 0,
                        max: duration.inMilliseconds.toDouble().clamp(
                          1,
                          double.infinity,
                        ),
                        value: position.inMilliseconds.toDouble().clamp(
                          0,
                          duration.inMilliseconds.toDouble(),
                        ),
                        onChanged: (v) {
                          player.audioPlayer.seek(
                            Duration(milliseconds: v.toInt()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          _fmt(position),
                          color: colors.primary2,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          onPressed: () => player.playPrevious(),
                          child: AppImage(src: AppSvg.skipPrev),
                        ),
                        const SizedBox(width: 8),
                        StreamBuilder<bool>(
                          stream: player.audioPlayer.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            return IconButton(
                              iconSize: 64,
                              icon: AppImage(
                                src: isPlaying
                                    ? AppSvg.pauseVid
                                    : AppSvg.playVid,
                                height: 61,
                                width: 61,
                              ),
                              onPressed: () =>
                              isPlaying ? player.pause() : player.resume(),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          onPressed: () => player.playNext(),
                          child: AppImage(src: AppSvg.skipNext),
                        ),
                        const SizedBox(width: 8),
                        AppText(
                          _fmt(duration),
                          color: colors.primary2,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                    const SizedBox(height: 62),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (player.chewieController == null ||
        player.videoController == null ||
        !player.videoController!.value.isInitialized) {
      return _buildVideoLoadingPlaceholder();
    }

    // અસાઇન કરેલા કંટ્રોલર માટે ચેક
    if (player.chewieController != null &&
        player.chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(
        // અહીં UniqueKey() કાઢી નાખો અને ValueKey વાપરો
        key: ValueKey(player.currentEntity?.id ?? "default_video"),
        controller: player.chewieController!,
      );
    } else {
      return const CustomLoader();
    }
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