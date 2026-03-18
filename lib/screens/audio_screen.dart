import '../services/ads_service.dart';
import '../utils/app_imports.dart';
import 'audio_player_screen.dart';

int _audioClickCount = 0;

class AudioScreen extends StatefulWidget {
  bool isComeHomeScreen;

  AudioScreen({super.key, this.isComeHomeScreen = true});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalPlayer player = GlobalPlayer();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<AudioBloc>().add(LoadMoreAudios());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final box = Hive.box('audios');

    return BlocProvider(
      create: (_) => AudioBloc(box)..add(LoadAudios()),
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
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
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
            SizedBox(width: 15),
          ],
        ),
        body: SafeArea(
          child: GlobalPlayer().currentType == "video"
              ? Stack(
            children: [
              Column(children: [Expanded(child: _AudioBody())]),
              const SmartMiniPlayer(),
            ],
          )
              : Column(
            children: [
              Expanded(child: _AudioBody()),
              Align(
                alignment: Alignment.bottomCenter,
                child: const SmartMiniPlayer(),
              ),
            ],
          ),
        ),

        // floatingActionButton: FloatingActionButton(
        //   onPressed: () => context.read<AudioBloc>().add(LoadAudios()),
        //   child: const Icon(Icons.refresh),
        // ),
      )
          : GlobalPlayer().currentType == "video"
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
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
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
          Align(
            alignment: Alignment.bottomCenter,
            child: const SmartMiniPlayer(),
          ),
        ],
      ),
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<AudioBloc>().add(LoadMoreAudios());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {
        List<AssetEntity> entities = [];

        if (state is AudioLoading) {
          entities = state.entities;
          return Center(child: CustomLoader());
        } else if (state is AudioLoaded) {
          entities = state.entities;
        } else if (state is AudioError) {
          return Center(child: Text(state.message));
        } else {
          return Center(child: CustomLoader());
        }

        return _buildAudioList(entities);
      },
    );
  }

  Widget _buildAudioList(List<AssetEntity> entities) {
    const int adInterval = 5;


    int adCount = entities.length ~/ adInterval;

    if (entities.isNotEmpty && entities.length < adInterval) {
      adCount = 1;
    }

    // Ã Â«Â¨. Total count: Audio + Ads + Bottom Spacer
    int totalCount = entities.length + adCount + 1;

    return AnimationLimiter(
      child: ListView.builder(
        controller: _scrollController,

        itemCount: totalCount,
        // itemCount: entities.length,
        itemBuilder: (context, index) {
          final colors = Theme.of(context).extension<AppThemeColors>()!;

          if (index == totalCount - 1) {
            return const SizedBox(height: 100); // Ã ÂªÂ¥Ã Â«â€¹Ã ÂªÂ¡Ã Â«ÂÃ Âªâ€š Ã ÂªÂµÃ ÂªÂ§Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â€¡ Ã ÂªÂªÃ Â«â€¡Ã ÂªÂ¡Ã ÂªÂ¿Ã Âªâ€šÃ Âªâ€”
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
          return Consumer<GlobalPlayer>(
            builder: (context, player, child) {
              final bool isCurrentPlaying =
                  player.currentEntity?.id == audio.id;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: AppTransition(
                  index: index,
                  child: FutureBuilder<File?>(
                    future: audio.file,
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
          );
        },
      ),
    );
  }

  void _handleOnTap(List<AssetEntity> entities, AssetEntity audio, File file) {

    void openAudioPlayer() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AudioPlayerScreen(
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
        ),
      ).then((_) {
        if (mounted) {
          context.read<AudioBloc>().add(LoadAudios(showLoading: false));
        }
      });
    }

    // Ã Â«Â¨. Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ²Ã ÂªÂ¿Ã Âªâ€¢ Ã Âªâ€¢Ã ÂªÂ¾Ã Âªâ€°Ã ÂªÂ¨Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÂµÃ ÂªÂ§Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â€¹
    _audioClickCount++;

    // Ã Â«Â©. Ã ÂªÂÃ ÂªÂ¡ Ã ÂªÂ²Ã Â«â€¹Ã ÂªÅ“Ã ÂªÂ¿Ã Âªâ€¢: Ã ÂªÂ¦Ã ÂªÂ° 4 Ã ÂªÂ¥Ã Â«â‚¬ Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ²Ã ÂªÂ¿Ã Âªâ€¢ Ã ÂªÂªÃ ÂªÂ° Ã ÂªÂÃ ÂªÂ¡ Ã ÂªÂ¬Ã ÂªÂ¤Ã ÂªÂ¾Ã ÂªÂµÃ Â«â€¹
    if (_audioClickCount % 4 == 0) {
      debugPrint("Showing Interstitial Ad before audio player...");

      // AdHelper Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã Âªâ€ Ã ÂªÂªÃ ÂªÂ£Ã Â«â€¡ Ã ÂªÅ“Ã Â«â€¡ Callback Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÅ¸ Ã Âªâ€¢Ã ÂªÂ°Ã Â«ÂÃ ÂªÂ¯Ã Â«â€¹ Ã Âªâ€ºÃ Â«â€¡ Ã ÂªÂ¤Ã Â«â€¡Ã ÂªÂ¨Ã Â«â€¹ Ã Âªâ€°Ã ÂªÂªÃ ÂªÂ¯Ã Â«â€¹Ã Âªâ€” Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
      AdHelper.showInterstitialAd(() {
        // Ã Âªâ€  Ã Âªâ€¢Ã Â«â€¹Ã ÂªÂ¡ Ã ÂªÂ¤Ã Â«ÂÃ ÂªÂ¯Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â€¡ Ã ÂªÅ“ Ã ÂªÅ¡Ã ÂªÂ¾Ã ÂªÂ²Ã ÂªÂ¶Ã Â«â€¡ Ã ÂªÅ“Ã Â«ÂÃ ÂªÂ¯Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â€¡ Ã ÂªÂÃ ÂªÂ¡ Ã ÂªÂ¬Ã Âªâ€šÃ ÂªÂ§ Ã ÂªÂ¥Ã ÂªÂ¶Ã Â«â€¡ Ã Âªâ€¦Ã ÂªÂ¥Ã ÂªÂµÃ ÂªÂ¾ Ã ÂªÂ²Ã Â«â€¹Ã ÂªÂ¡ Ã ÂªÂ¨Ã ÂªÂ¹Ã Â«â‚¬Ã Âªâ€š Ã ÂªÂ¥Ã ÂªÂ¾Ã ÂªÂ¯
        openAudioPlayer();
      });
    } else {
      // Ã ÂªÅ“Ã Â«â€¹ 4 Ã ÂªÂ¥Ã Â«â‚¬ Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ²Ã ÂªÂ¿Ã Âªâ€¢ Ã ÂªÂ¨Ã ÂªÂ¥Ã Â«â‚¬, Ã ÂªÂ¤Ã Â«â€¹ Ã ÂªÂ¸Ã Â«â‚¬Ã ÂªÂ§Ã Â«ÂÃ Âªâ€š Ã ÂªÅ“ Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ¯Ã ÂªÂ° Ã Âªâ€“Ã Â«â€¹Ã ÂªÂ²Ã Â«â€¹
      openAudioPlayer();
    }
  }

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
      child: Stack(
        alignment: Alignment.center,
        children: [
          AppImage(
            src: AppSvg.musicUnselected,
            height: 22,
            color: colors.whiteColor,
          ),
          if (isPlaying)
            AppImage(
              src: GlobalPlayer().isPlaying
                  ? AppSvg.playerPause
                  : AppSvg.playerResume,
              height: 18,
            ),
        ],
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
      ) async {
    final favBox = Hive.box('favourites');
    final bool isFavorite = entity.isFavorite;

    final file = await entity.file;
    if (file == null) return;

    final key = file.path;

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
        "isFavourite": isFavorite,
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
    context.read<AudioBloc>().add(LoadAudios(showLoading: false));

    setState(() {});
  }
}