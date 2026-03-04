import '../utils/app_imports.dart';

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
                    child: AppImage(src: AppSvg.searchIcon),
                  ),
                ),
              ),
            ),
            SizedBox(width: 15),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(child: _AudioBody()),
                ],
              ),
              const SmartMiniPlayer(),
            ],
          ),
        ),




        // floatingActionButton: FloatingActionButton(
        //   onPressed: () => context.read<AudioBloc>().add(LoadAudios()),
        //   child: const Icon(Icons.refresh),
        // ),
      )
          : Stack(
        // àª†àª–àª¾ àªªà«‡àªœàª¨à«‡ Stack àª®àª¾àª‚ àª®à«‚àª•à«‹
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
                        child: AppImage(src: AppSvg.searchIcon),
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
      ),
    );
  }
}

class _AudioBody extends StatefulWidget {
  const _AudioBody();

  @override
  State<_AudioBody> createState() => _AudioBodyState();
}

// 1. wantKeepAlive Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡ Mixin Ã Âªâ€¦Ã ÂªÂ¨Ã Â«â€¡ Override Ã ÂªÅ“Ã ÂªÂ°Ã Â«â€šÃ ÂªÂ°Ã Â«â‚¬ Ã Âªâ€ºÃ Â«â€¡
class _AudioBodyState extends State<_AudioBody>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true; // Ã Âªâ€  Ã ÂªÂªÃ Â«â€¡Ã ÂªÅ“Ã ÂªÂ¨Ã Â«â€¡ Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ®Ã ÂªÂ°Ã Â«â‚¬Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã ÂªÅ“Ã Â«â‚¬Ã ÂªÂµÃ Âªâ€šÃ ÂªÂ¤ Ã ÂªÂ°Ã ÂªÂ¾Ã Âªâ€“Ã ÂªÂ¶Ã Â«â€¡

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
    super.build(
      context,
    ); // AutomaticKeepAlive Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡ Ã Âªâ€  Ã ÂªÅ“Ã ÂªÂ°Ã Â«â€šÃ ÂªÂ°Ã Â«â‚¬ Ã Âªâ€ºÃ Â«â€¡
    return BlocBuilder<AudioBloc, AudioState>(
      // _AudioBody Ã ÂªÂ¨Ã ÂªÂ¾ build Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã Âªâ€  Ã ÂªÂ°Ã Â«â‚¬Ã ÂªÂ¤Ã Â«â€¡ Ã ÂªÂ«Ã Â«â€¡Ã ÂªÂ°Ã ÂªÂ«Ã ÂªÂ¾Ã ÂªÂ° Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
      builder: (context, state) {
        List<AssetEntity> entities = [];

        if (state is AudioLoading) {
          entities =
              state.entities; // Ã ÂªÂ¹Ã ÂªÂµÃ Â«â€¡ Ã ÂªÂÃ ÂªÂ°Ã ÂªÂ° Ã ÂªÂ¨Ã ÂªÂ¹Ã Â«â‚¬Ã Âªâ€š Ã Âªâ€ Ã ÂªÂµÃ Â«â€¡
          // if (entities.isEmpty)
          return Center(child: CustomLoader());
        } else if (state is AudioLoaded) {
          entities =
              state.entities; // Ã ÂªÂ¹Ã ÂªÂµÃ Â«â€¡ Ã ÂªÂÃ ÂªÂ°Ã ÂªÂ° Ã ÂªÂ¨Ã ÂªÂ¹Ã Â«â‚¬Ã Âªâ€š Ã Âªâ€ Ã ÂªÂµÃ Â«â€¡
        } else if (state is AudioError) {
          return Center(child: Text(state.message));
        } else {
          return const SizedBox.shrink();
        }

        return _buildAudioList(entities);
      },
    );
  }

  // Ã ÂªÂ¡Ã Â«ÂÃ ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â‚¬Ã Âªâ€¢Ã Â«â€¡Ã ÂªÅ¸ Ã Âªâ€¢Ã Â«â€¹Ã ÂªÂ¡ Ã ÂªËœÃ ÂªÅ¸Ã ÂªÂ¾Ã ÂªÂ¡Ã ÂªÂµÃ ÂªÂ¾ Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡ Ã Âªâ€¦Ã ÂªÂ²Ã Âªâ€” Ã ÂªÂ«Ã Âªâ€šÃ Âªâ€¢Ã Â«ÂÃ ÂªÂ¶Ã ÂªÂ¨
  Widget _buildAudioList(List<AssetEntity> entities) {
    return AnimationLimiter(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: entities.length,
        itemBuilder: (context, index) {
          final audio = entities[index];
          final colors = Theme.of(context).extension<AppThemeColors>()!;

          return Consumer<GlobalPlayer>(
            builder: (context, player, child) {
              final bool isCurrentPlaying =
                  player.currentEntity?.id == audio.id;

              return AppTransition(
                index: index,
                child: FutureBuilder<File?>(
                  future: audio.file,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const ListTile(
                        leading: Icon(Icons.music_note),
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
                                ? Border.all(color: colors.primary, width: 0.5)
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
              );
            },
          );
        },
      ),
    );
  }

  // Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ¯Ã ÂªÂ° Ã ÂªÂ¹Ã Â«â€¡Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¡Ã ÂªÂ²Ã ÂªÂ°
  void _handleOnTap(List<AssetEntity> entities, AssetEntity audio, File file) {
    // GlobalPlayer().initAndPlay(entities: entities, selectedId: audio.id);
    print("type===> ${audio.type}");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
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
      context.read<AudioBloc>().add(LoadAudios(showLoading: false));
    });
  }

  // Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸ Ã Âªâ€ Ã ÂªË†Ã ÂªÅ¸Ã ÂªÂ®Ã ÂªÂ¨Ã Â«ÂÃ Âªâ€š Ã Âªâ€ Ã ÂªË†Ã Âªâ€¢Ã ÂªÂ¨
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
          AppImage(src: AppSvg.musicUnselected, height: 22),
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

  // Ã ÂªÅ¸Ã ÂªÂ¾Ã ÂªË†Ã ÂªÅ¸Ã ÂªÂ² Ã Âªâ€¦Ã ÂªÂ¨Ã Â«â€¡ Ã ÂªÂ¸Ã ÂªÂ®Ã ÂªÂ¯
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

  // Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ¨Ã Â«Â Ã ÂªÂ¬Ã ÂªÅ¸Ã ÂªÂ¨
  Widget _buildPopupMenu(AssetEntity audio, int index) {
    return PopupMenuButton<MediaMenuAction>(
      elevation: 15,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.black.withOpacity(0.60),
      offset: Offset(0, 0),
      // splashRadius: 15,
      icon: AppImage(src: AppSvg.dropDownMenuDot),
      menuPadding: EdgeInsets.symmetric(horizontal: 10),
      onSelected: (action) => handleMenuAction(context, audio, action, index),
      // common_methods Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂµÃ Â«ÂÃ Âªâ€š Ã ÂªÅ“Ã Â«â€¹Ã ÂªË†Ã ÂªÂ
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
      ) async {
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

    // Ã°Å¸â€Â¹ Update Hive
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

    // Ã°Å¸â€Â¹ Update system favourite
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

    // Ã°Å¸â€Â¹ Reload entity
    final AssetEntity? newEntity = await entity.obtainForNewProperties();
    if (!mounted || newEntity == null) return;
    if (GlobalPlayer().currentEntity?.id == entity.id) {
      await GlobalPlayer().refreshCurrentEntity();
    }
    // Ã°Å¸â€Â¹ Update UI list
    // readPathProvider(context).list[index] = newEntity;
    context.read<AudioBloc>().add(LoadAudios(showLoading: false));

    setState(() {});
  }
}