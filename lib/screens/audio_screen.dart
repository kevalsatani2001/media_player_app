import 'package:on_audio_query_forked/on_audio_query.dart';

import '../services/ads_service.dart';
import '../utils/app_imports.dart';
import 'audio_album_screen.dart';
import 'audio_player_screen.dart';

int _audioClickCount = 0;

class AudioScreen extends StatefulWidget {
  bool isComeHomeScreen;
  /// When false, shell (e.g. bottom nav) owns [SmartMiniPlayer] — avoids duplicate [Hero] in [IndexedStack].
  final bool showMiniPlayer;

  AudioScreen({
    super.key,
    this.isComeHomeScreen = true,
    this.showMiniPlayer = true,
  });

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final GlobalPlayer player = GlobalPlayer();
  VoidCallback? _favouriteSignalListener;

  @override
  void initState() {
    super.initState();
    _favouriteSignalListener = () async {
      if (!mounted) return;
      final signalValue = PlaylistService.favouriteSignal.value;
      if (signalValue.isEmpty) return;

      final String changedId = signalValue.split('_').first;

      final state = context.read<AudioBloc>().state;
      if (state is AudioLoaded) {
        final listIndex = state.entities.indexWhere(
              (element) => element.id == changedId,
        );
        if (listIndex != -1) {
          final AssetEntity? newEntity = await state.entities[listIndex]
              .obtainForNewProperties();
          if (newEntity != null) {
            context.read<AudioBloc>().add(UpdateAudioItem(newEntity, listIndex));
          }
        }
      }
    };
    PlaylistService.favouriteSignal.addListener(_favouriteSignalListener!);
  }

  @override
  void dispose() {
    if (_favouriteSignalListener != null) {
      PlaylistService.favouriteSignal.removeListener(_favouriteSignalListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    // Use the global `AudioBloc` provided in `main.dart` so this screen
    // does not reload every time you navigate back.
    return BlocListener<FavouriteChangeBloc, FavouriteChangeState>(
      listener: (context, favState) async {
        if (favState is FavouriteChanged) {
          final audioBloc = context.read<AudioBloc>();
          final state = audioBloc.state;

          if (state is AudioLoaded) {
            final listIndex = state.entities.indexWhere(
                  (element) => element.id == favState.entity.id,
            );

            if (listIndex != -1) {
              final AssetEntity? newEntity = await favState.entity
                  .obtainForNewProperties();

              if (newEntity != null) {
                audioBloc.add(UpdateAudioItem(newEntity, listIndex));
              }
            }
          }
        }
      },
      child: widget.isComeHomeScreen
          ? Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: AppImage(
                src: AppSvg.backArrowIcon,
                height: 20,
                width: 20,
                color: colors.blackColor,
              ),
            ),
          ),
          centerTitle: true,
          title: AppText(
            "audio",
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),

          actions: [
              // --- Album Button ---
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                    MaterialPageRoute(
                      builder: (_) =>  AudioAlbumScreen(),
                    ),
                );
              },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colors.textFieldFill,
                  ),
                    padding: const EdgeInsets.all(8),
                  child: Icon(Icons.album_rounded, color: colors.blackColor, size: 22),
                ),
              ),
              const SizedBox(width: 10),

              // àª¤àª®àª¾àª°à«àª‚ àªœà«‚àª¨à«àª‚ Search Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colors.textFieldFill,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: AppImage(src: AppSvg.searchIcon, color: colors.blackColor),
                ),
              ),
              const SizedBox(width: 15),
          ],
        ),
        body: SafeArea(
          child: GlobalPlayer().currentType == "video"
              ? (widget.showMiniPlayer
                  ? Stack(
                      children: [
                        Column(children: [Expanded(child: _AudioBody())]),
                        const SmartMiniPlayer(),
                      ],
                    )
                  : Column(children: [Expanded(child: _AudioBody())]))
              : (widget.showMiniPlayer
                  ? Column(
                      children: [
                        Expanded(child: _AudioBody()),
                        const Align(
                          alignment: Alignment.bottomCenter,
                          child: SmartMiniPlayer(),
                        ),
                      ],
                    )
                  : Column(
                      children: [Expanded(child: _AudioBody())],
                    )),
        ),
      )
          : GlobalPlayer().currentType == "video"
          ? (widget.showMiniPlayer
              ? Stack(
                  children: [
                    Column(
                      children: [
                        CommonAppBar(
                          title: "videMusicPlayer",
                          subTitle: "mediaPlayer",
                          actionWidget: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SearchScreen(),
                                ),
                              );
                            },
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.8, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, double val, child) =>
                                  Transform.scale(scale: val, child: child),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: colors.textFieldFill,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: AppImage(
                                    src: AppSvg.searchIcon,
                                    color: colors.blackColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Divider(color: colors.dividerColor),
                        Expanded(child: _AudioBody()),
                      ],
                    ),
                    const SmartMiniPlayer(),
                  ],
                )
              : Column(
                  children: [
                    CommonAppBar(
                      title: "videMusicPlayer",
                      subTitle: "mediaPlayer",
                      actionWidget: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SearchScreen(),
                            ),
                          );
                        },
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, double val, child) =>
                              Transform.scale(scale: val, child: child),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: colors.textFieldFill,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: AppImage(
                                src: AppSvg.searchIcon,
                                color: colors.blackColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Divider(color: colors.dividerColor),
                    Expanded(child: _AudioBody()),
                  ],
                ))
          : (widget.showMiniPlayer
              ? Column(
                  children: [
                    CommonAppBar(
                      title: "videMusicPlayer",
                      subTitle: "mediaPlayer",
                      actionWidget: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SearchScreen(),
                            ),
                          );
                        },
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, double val, child) =>
                              Transform.scale(scale: val, child: child),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: colors.textFieldFill,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: AppImage(
                                src: AppSvg.searchIcon,
                                color: colors.blackColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Divider(color: colors.dividerColor),
                    Expanded(child: _AudioBody()),
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: SmartMiniPlayer(),
                    ),
                  ],
                )
              : Column(
                  children: [
                    CommonAppBar(
                      title: "videMusicPlayer",
                      subTitle: "mediaPlayer",
                      actionWidget: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SearchScreen(),
                            ),
                          );
                        },
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, double val, child) =>
                              Transform.scale(scale: val, child: child),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: colors.textFieldFill,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: AppImage(
                                src: AppSvg.searchIcon,
                                color: colors.blackColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Divider(color: colors.dividerColor),
                    Expanded(child: _AudioBody()),
                  ],
                )),
    );
  }
}

class _AudioBody extends StatefulWidget {
  const _AudioBody();

  @override
  State<_AudioBody> createState() => _AudioBodyState();
}

class _AudioBodyState extends State<_AudioBody>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  String _selectedLetter = '';

  final Map<String, int> _letterIndices = {};
  final Map<String, Future<File?>> _fileFutureCache = {};
  final Map<String, Future<Uint8List?>> _artworkFutureCache = {};

  final double _itemHeight = 80.0;

  Future<File?> _fileFutureFor(AssetEntity audio) {
    return _fileFutureCache.putIfAbsent(audio.id, () => audio.file);
  }

  Future<Uint8List?> _artworkFutureFor(AssetEntity audio) {
    return _artworkFutureCache.putIfAbsent(
      audio.id,
      () => _audioQuery.queryArtwork(
        Platform.isIOS ? audio.id.hashCode : int.tryParse(audio.id) ?? 0,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 200,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _getAlphabetList(List<AssetEntity> entities) {
    Set<String> letters = {};
    for (var entity in entities) {
      String name = entity.title ?? "";
      if (name.isEmpty) name = entity.id;

      if (name.isNotEmpty) {
        String firstChar = name[0].toUpperCase();
        if (RegExp(r'^\p{L}', unicode: true).hasMatch(firstChar)) {
          letters.add(firstChar);
        } else {
          letters.add('#');
        }
      }
    }
    List<String> sortedLetters = letters.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });
    return sortedLetters;
  }

  void _scrollToLetter(String letter) {
    final targetIndex = _letterIndices[letter];
    if (targetIndex != null) {
      double scrollOffset = targetIndex * _itemHeight;

      if (scrollOffset > _scrollController.position.maxScrollExtent) {
        scrollOffset = _scrollController.position.maxScrollExtent;
      }

      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      setState(() {
        _selectedLetter = letter;
      });
    }
  }

  void _calculateLetterIndices(List<AssetEntity> entities, int adInterval) {
    _letterIndices.clear();
    String currentProcessedLetter = '';

    for (int i = 0; i < entities.length; i++) {
      final audio = entities[i];
      String name = audio.title ?? "";
      String firstChar = name.isNotEmpty ? name[0].toUpperCase() : '#';
      String letter = RegExp(r'^\p{L}', unicode: true).hasMatch(firstChar)
          ? firstChar
          : '#';

      if (letter != currentProcessedLetter) {
        currentProcessedLetter = letter;

        int adOffset = i ~/ adInterval;
        int actualUiIndex = i + adOffset;

        _letterIndices[letter] = actualUiIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return BlocBuilder<AudioBloc, AudioState>(
      buildWhen: (previous, current) =>
          current is AudioLoaded ||
          current is AudioLoading ||
          current is AudioError ||
          current is AudioInitial,
      builder: (context, state) {
        if (state is AudioInitial || state is AudioLoading) {
          return const MediaShimmerLoading();
        }

        if (state is AudioError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      context.read<AudioBloc>().add(LoadAudios());
                    },
                    icon: const Icon(Icons.refresh),
                    label: AppText('retry', fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! AudioLoaded) {
          return const MediaShimmerLoading();
        }

        List<AssetEntity> entities = List.from(state.entities);
        entities.sort(
          (a, b) => (a.title ?? "").toLowerCase().compareTo(
                (b.title ?? "").toLowerCase(),
              ),
        );

        if (entities.isEmpty) {
          return Center(
            child: AppText(
              'noResultFound',
              fontSize: 15,
              color: colors.blackColor.withOpacity(0.6),
            ),
          );
        }

        const int adInterval = 5;
        final alphabetList = _getAlphabetList(entities);

        _calculateLetterIndices(entities, adInterval);

        final currentPlayingId = context.select<GlobalPlayer, String?>(
          (p) => p.currentEntity?.id,
        );

        return Stack(
          children: [
            _buildAudioList(entities, adInterval, currentPlayingId),

            // Alphabet Sidebar
            Positioned(
              right: 6,
              top: 50,
              bottom: 100,
              child: Center(
                child: Container(
                  width: 24,
                  decoration: BoxDecoration(
                    color: colors.blackColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: alphabetList.map((letter) {
                        bool isActive = _selectedLetter == letter;
                        return GestureDetector(
                          onTap: () => _scrollToLetter(letter),
                          child: Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.symmetric(vertical: 2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? colors.primary
                                  : Colors.transparent,
                            ),
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isActive
                                    ? Colors.white
                                    : colors.blackColor.withOpacity(0.6),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioList(
    List<AssetEntity> entities,
    int adInterval,
    String? currentPlayingId,
  ) {
    int adCount = entities.length ~/ adInterval;
    if (entities.isNotEmpty && entities.length < adInterval) {
      adCount = 1;
    }
    int totalCount = entities.length + adCount + 1;

    return AnimationLimiter(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: totalCount,
        itemBuilder: (context, index) {
          final colors = Theme.of(context).extension<AppThemeColors>()!;

          if (index == totalCount - 1) {
            return const SizedBox(height: 100);
          }

          bool isAdPosition =
          (index != 0 && (index + 1) % (adInterval + 1) == 0);
          bool isLastAdForSmallList =
          (entities.length < adInterval && index == entities.length);

          if (isAdPosition || isLastAdForSmallList) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AdHelper.bannerAdWidget(size: AdSize.banner),
            );
          }

          final int actualIndex = index - (index ~/ (adInterval + 1));
          if (actualIndex >= entities.length) return const SizedBox.shrink();

          final audio = entities[actualIndex];

          final bool isCurrentPlaying = currentPlayingId == audio.id;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: AppTransition(
                  index: index,
                  child: FutureBuilder<File?>(
                future: _fileFutureFor(audio),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return ListTile(
                          leading: Icon(
                            Icons.music_note,
                            color: colors.blackColor,
                          ),
                          title: AppText("loading"),
                        );
                      }
                      final file = snapshot.data!;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7.5),
                        child: GestureDetector(
                          onTap: () => _handleOnTap(entities, audio, file),
                          child: Container(
                            padding: const EdgeInsets.only(
                              top: 10,
                              left: 10,
                              bottom: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.cardBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: isCurrentPlaying
                                  ? Border.all(
                                color: colors.primary,
                                width: 0.5,
                              )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                _buildLeadingIcon(
                                  audio,
                                  colors,
                                  isCurrentPlaying,
                                ),
                                const SizedBox(width: 12),
                                _buildTitleAndDuration(audio, file, colors),
                                _buildPopupMenu(audio, index),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          );
        },
      ),
    );
  }

  void _handleOnTap(List<AssetEntity> entities, AssetEntity audio, File file) {
    void openAudioPlayer() {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AudioPlayerScreen(
            entityList: entities,
            entity: audio,
            item: MediaItem(
              isFavourite: audio.isFavorite,
              id: audio.id,
              path: file.path,
              isNetwork: false,
              type: 'audio',
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // àª† àª•à«‹àª¡ àªªà«‡àªœàª¨à«‡ àª¨à«€àªšà«‡àª¥à«€ àª‰àªªàª° àª…àª¨à«‡ àª‰àªªàª°àª¥à«€ àª¨à«€àªšà«‡ àª²àªˆ àªœàª¶à«‡
            const begin = Offset(0.0, 1.0); // à«§.à«¦ àªàªŸàª²à«‡ àª•à«‡ àª›à«‡àª• àª¨à«€àªšà«‡àª¥à«€ àª¶àª°à«‚ àª¥àª¶à«‡
            const end = Offset.zero; // à«¦.à«¦ àªàªŸàª²à«‡ àª•à«‡ àª¨à«‹àª°à«àª®àª² àªœàª—à«àª¯àª¾àª àª†àªµà«€ àªœàª¶à«‡
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400), // àªàª¨àª¿àª®à«‡àª¶àª¨àª¨à«€ àª¸à«àªªà«€àª¡
        ),
      );
    }

    _audioClickCount++;

    if (_audioClickCount % 4 == 0) {
      debugPrint("Showing Interstitial Ad before audio player...");

      AdHelper.showInterstitialAd(() {
        openAudioPlayer();
      });
    } else {
      openAudioPlayer();
    }
  }

  // Widget _buildLeadingIcon(
  //   AssetEntity audio,
  //   AppThemeColors colors,
  //   bool isPlaying,
  // ) {
  //   return Container(
  //     height: 50,
  //     width: 50,
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(10),
  //       color: colors.blackColor.withOpacity(0.38),
  //     ),
  //     child: Stack(
  //       alignment: Alignment.center,
  //       children: [
  //         AppImage(
  //           src: AppSvg.musicUnselected,
  //           height: 22,
  //           color: colors.whiteColor,
  //         ),
  //         if (isPlaying)
  //           AppImage(
  //             src: GlobalPlayer().isPlaying
  //                 ? AppSvg.playerPause
  //                 : AppSvg.playerResume,
  //             height: 18,
  //           ),
  //       ],
  //     ),
  //   );
  // }
  final OnAudioQuery _audioQuery = OnAudioQuery();
  Widget _buildLeadingIcon(
      AssetEntity audio,
      AppThemeColors colors,
      bool isPlaying,
      ) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colors.blackColor.withOpacity(0.38),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
            FutureBuilder<Uint8List?>(
              future: _artworkFutureFor(audio),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                  return Image.memory(
                    snapshot.data!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  );
                }

                return AppImage(
            src: AppSvg.musicUnselected,
            height: 22,
            color: colors.whiteColor,
                );
              },
          ),

          if (isPlaying)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: AppImage(
              src: GlobalPlayer().isPlaying
                  ? AppSvg.playerPause
                  : AppSvg.playerResume,
              height: 18,
                ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildTitleAndDuration(
      AssetEntity audio,
      File file,
      AppThemeColors colors,
      ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            file.path.split('/').last,
            maxLines: 1,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          const SizedBox(height: 6),
          AppText(
            formatDuration(audio.duration),
            fontSize: 13,
            color: colors.textFieldBorder,
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(AssetEntity audio, int index) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return PopupMenuButton<MediaMenuAction>(
      elevation: 15,
      color: colors.dropdownBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.black.withOpacity(0.60),
      offset: Offset(0, 0),
      // splashRadius: 15,
      icon: AppImage(src: AppSvg.dropDownMenuDot, color: colors.blackColor),
      menuPadding: EdgeInsets.symmetric(horizontal: 10),
      onSelected: (action) => handleMenuAction(context, audio, action, index),
      itemBuilder: (context) => [
        _buildPopupItem(
          MediaMenuAction.addToFavourite,
          audio.isFavorite ? 'removeToFavourite' : 'addToFavourite',
        ),
        const PopupMenuDivider(height: 0.5),
        _buildPopupItem(MediaMenuAction.delete, 'delete'),
        const PopupMenuDivider(height: 0.5),
        _buildPopupItem(MediaMenuAction.share, 'share'),
        const PopupMenuDivider(height: 0.5),
        _buildPopupItem(MediaMenuAction.detail, 'showDetail'),
        const PopupMenuDivider(height: 0.5),
        _buildPopupItem(MediaMenuAction.addToPlaylist, 'addToPlaylist'),
      ],
    );
  }

  PopupMenuItem<MediaMenuAction> _buildPopupItem(
      MediaMenuAction action,
      String title,
      ) {
    return PopupMenuItem(
      value: action,
      child: Center(child: AppText(title, fontSize: 12)),
    );
  }

  void handleMenuAction(
      BuildContext context,
      AssetEntity audio,
      MediaMenuAction action,
      int index,
      ) async
  {
    switch (action) {
      case MediaMenuAction.detail:
        routeToDetailPage(context, audio);
        break;
      case MediaMenuAction.info:
        showInfoDialog(context, audio);
        break;
      case MediaMenuAction.share:
        shareItem(context, audio);
        break;
      case MediaMenuAction.delete:
        deleteCurrentItem(context, audio);
        break;
      case MediaMenuAction.addToFavourite:
        await _toggleFavourite(context, audio, index);
        break;
      case MediaMenuAction.addToPlaylist:
        final file = await audio.file;
        if (file != null) {
          addToPlaylist(
            MediaItem(
              path: file.path,
              isNetwork: false,
              type: "audio",
              id: audio.id,
              isFavourite: audio.isFavorite,
            ),
            context,
          );
        }
        break;
      case MediaMenuAction.thumb:
        showThumb(context, audio, 500);
        break;
    }
  }

  Future<void> _toggleFavourite(
      BuildContext context,
      AssetEntity entity,
      int index,
      ) async
  {
    final favBox = Hive.box('favourites');
    final bool isFavorite = entity.isFavorite;

    final file = await entity.file;
    if (file == null) return;

    final key = file.path;
    print("result is ===> ${Hive.box('favourites').containsKey(file.path)}");

    if (isFavorite) {
      favBox.delete(key);
      AppToast.show(
        context,
        context.tr("removedFromFavourites"),
        type: ToastType.info,
      );
    } else {
      favBox.put(key, {
        "id": entity.id,
        "path": file.path,
        "isNetwork": false,
        "isFavourite": true,
        "type": entity.type == AssetType.audio ? "audio" : "video",
      });
      AppToast.show(
        context,
        context.tr("addedToFavourite"),
        type: ToastType.success,
      );
    }

    if (PlatformUtils.isOhos) {
      await PhotoManager.editor.ohos.favoriteAsset(
        entity: entity,
        favorite: !isFavorite,
      );
    } else if (Platform.isAndroid) {
      await PhotoManager.editor.android.favoriteAsset(
        entity: entity,
        favorite: !isFavorite,
      );
    } else {
      await PhotoManager.editor.darwin.favoriteAsset(
        entity: entity,
        favorite: !isFavorite,
      );
    }

    final AssetEntity? newEntity = await entity.obtainForNewProperties();

    if (!mounted || newEntity == null) return;

    if (GlobalPlayer().currentEntity?.id == entity.id) {
      await GlobalPlayer().refreshCurrentEntity();
    }

    final state = context.read<AudioBloc>().state;
    if (state is AudioLoaded) {
      final listIndex = state.entities.indexWhere(
            (element) => element.id == entity.id,
      );
      if (listIndex != -1) {
        context.read<AudioBloc>().add(UpdateAudioItem(newEntity, listIndex));
      }
    }
    context.read<FavouriteChangeBloc>().add(FavouriteUpdated(newEntity));

    setState(() {});

    // context.read<AudioBloc>().add(LoadAudios(showLoading: false));
  }
}





