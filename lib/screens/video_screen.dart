





import 'dart:ui' as ui;
import '../services/ads_service.dart';
import '../utils/app_imports.dart';

class VideoScreen extends StatefulWidget {
  bool isComeHomeScreen;

  VideoScreen({super.key, this.isComeHomeScreen = true});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

// 1. Class ni upar ek global variable banavo counter mate
int _videoClickCount = 0;

class _VideoScreenState extends State<VideoScreen> {
  String _searchQuery = '';
  bool _isGridView = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) {
      final state = context.read<VideoBloc>().state;
      if (state is VideoLoaded && state.hasMore) {
        context.read<VideoBloc>().add(LoadMoreVideos());
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  final GlobalPlayer player = GlobalPlayer();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final box = Hive.box('videos');
    if (widget.isComeHomeScreen)
      return BlocProvider(
        create: (_) =>
        VideoBloc(Hive.box('videos'))
          ..add(LoadVideosFromGallery(showLoading: false)),
        child: Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: AppImage(
                  src: AppSvg.backArrowIcon,
                  color: colors.blackColor,
                  height: 20,
                  width: 20,
                ),
              ),
            ),
            centerTitle: true,
            title: AppText("videos", fontSize: 20, fontWeight: FontWeight.w500),

            actions: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                child: Container(
                  height: 24,
                  width: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: AppImage(
                      src: "assets/svg_icon/search_icon.svg",
                      height: 24,
                      width: 24,
                      color: colors.blackColor,
                    ),
                  ),
                ),
              ),
              // Builder(builder: (context) {
              //   return IconButton(
              //     icon: const Icon(Icons.add),
              //     onPressed: () {
              //       context.read<VideoBloc>().add(
              //         PickVideos(() async {}),
              //       );
              //     },
              //   );
              // }),
              SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
                child: AppImage(
                  src: _isGridView ? AppSvg.listIcon : AppSvg.gridIcon,
                  color: colors.blackColor,
                ),
              ),
              SizedBox(width: 15),
            ],
          ),
          body: SafeArea(
            child:   Stack(
              children: [
                Column(
                  children: [
                    /// Ã°Å¸Å¸Â¢ 1. TOP ADAPTIVE BANNER
                    AdHelper.adaptiveBannerWidget(context),
                    Expanded(child: _buildVideoPage()),
                  ],
                ),
                SmartMiniPlayer(forceMiniMode: true) // Aa widget potani rite handle karshe
              ],
            ),
          ),
        ),
      );

    else
      return Stack(
        children: [
          Column(
            children: [
              CommonAppBar(
                title: "videMusicPlayer",
                subTitle: "mediaPlayer",
                actionWidget: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colors.textFieldFill,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () => setState(() => _isGridView = !_isGridView),
                      child: AppImage(
                        src: _isGridView ? AppSvg.listIcon : AppSvg.gridIcon,
                        color: colors.blackColor,
                      ),
                    ),
                  ),
                ),
              ),
              Divider(color: colors.dividerColor),
              /// Ã°Å¸Å¸Â¢ 2. TOP BANNER FOR TAB VIEW
              AdHelper.adaptiveBannerWidget(context),

              Expanded(child: _buildVideoPage()),
              // Audio chaltu hoy to niche space khali karva mate:
            ],
          ),
          SmartMiniPlayer(forceMiniMode: true)
        ],
      );
  }

  Widget _buildVideoPage() {
    return BlocBuilder<VideoBloc, VideoState>(
      buildWhen: (previous, current) =>
      current is VideoLoaded ||
          current is VideoLoading ||
          current is VideoError,
      builder: (context, state) {
        if (state is VideoLoading) {
          return const MediaShimmerLoading();
        }

        if (state is VideoError) {
          return Center(child: Text(state.message));
        }

        if (state is VideoLoaded) {
          final entitiesToShow = _searchQuery.isEmpty
              ? state.entities
              : state.entities.where((e) {
            final name = (e is AssetEntity)
                ? (e.title ?? '')
                : (e as MediaItem).path.split('/').last;
            return name.toLowerCase().contains(_searchQuery);
          }).toList();

          if (entitiesToShow.isEmpty && _searchQuery.isNotEmpty) {
            return const Center(child: AppText("noResultFound"));
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.02), // ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¹ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¥ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â°ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â° ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂµÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂªÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¶ÃƒÆ’Ã†â€™ ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¡
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _isGridView
                ? _buildGridView(
              entitiesToShow,
              state.hasMore,
              key: const ValueKey('grid'),
            )
                : _buildListView(
              entitiesToShow,
              state.hasMore,
              key: const ValueKey('list'),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }


  _buildGridView(List<dynamic> entitiesToShow, bool hasMore, {Key? key}) {
    // Ã°Å¸Å¸Â¢ Darek 5 item pachi ek Ad (Interval 2 bahu vadhare thai jase, 5-6 best rahese)
    const int adIndexInterval = 5;

    // Ã°Å¸Å¸Â¢ Sacho ItemCount: Videos + Ads + Loader
    int totalItems = entitiesToShow.length + (entitiesToShow.length ~/ adIndexInterval);
    if (hasMore) totalItems++;

    return GridView.builder(
      key: key,
      controller: _scrollController,
      padding: const EdgeInsets.all(15),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 15,
        childAspectRatio: 1.05,
      ),

      itemCount:totalItems,
      // itemCount: hasMore ? entitiesToShow.length + 1 : entitiesToShow.length,
      itemBuilder: (context, index) {
// 1. Loader check
        if (hasMore && index == totalItems - 1) {
          return const Center(child: CustomLoader());
        }

        // _buildGridView àª¨àª¾ itemBuilder àª…àª‚àª¦àª° AD LOGIC àªµàª¾àª³à«‹ àª­àª¾àª— àª† àª°à«€àª¤à«‡ àª¬àª¦àª²à«‹:

        if (index != 0 && (index + 1) % (adIndexInterval + 1) == 0) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white, // àªàª¡ àªªàª¾àª›àª³ àªµà«àª¹àª¾àª‡àªŸ àª¬à«‡àª•àª—à«àª°àª¾àª‰àª¨à«àª¡ àª¸àª¾àª°à«àª‚ àª²àª¾àª—àª¶à«‡
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)), // àª†àª‰àªŸàª²àª¾àª‡àª¨
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain, // àª† àªàª¡àª¨à«‡ àª¬à«‹àª•à«àª¸àª®àª¾àª‚ àª«àª¿àªŸ àª•àª°àª¶à«‡
                  child: AdHelper.bannerAdWidget(size: AdSize.mediumRectangle),
                ),
              ),
            ),
          );
        }

        // Ã°Å¸Å¸Â¢ 3. ACTUAL INDEX CALCULATION (Bau mukhya chhe)
        final int actualIndex = index - (index ~/ (adIndexInterval + 1));

        if (actualIndex >= entitiesToShow.length) return const SizedBox.shrink();

        final entity = entitiesToShow[actualIndex];

        return AppTransition(
          index: index % 10,
          columnCount: 2,
          child: GestureDetector(
            onTap: () async {
              // Ã°Å¸Å¸Â¢ Ahiya 'actualIndex' vapro, 'index' nahi
              if (entity is AssetEntity) {
                List<AssetEntity> videoList = entitiesToShow
                    .whereType<AssetEntity>()
                    .toList();

                int playerIndex = videoList.indexOf(entity);
                _navigateToPlayer(context, videoList, playerIndex, entity);
              }},
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: entity is AssetEntity
                        ? ImageItemWidget(
                      onMenuSelected: (action) async {
                        switch (action) {
                          case MediaMenuAction.detail:
                            routeToDetailPage(context, entity);
                            break;

                          case MediaMenuAction.info:
                            showInfoDialog(context, entity);
                            break;

                          case MediaMenuAction.thumb:
                            showThumb(entity, 500);
                            break;

                          case MediaMenuAction.share:
                            shareItem(context, entity);
                            break;

                          case MediaMenuAction.delete:
                            deleteCurrentItem(context, entity);
                            break;

                          case MediaMenuAction.addToFavourite:
                            await _toggleFavourite(
                              context,
                              entity,
                              index,
                            );
                            break;
                          case MediaMenuAction.addToPlaylist:
                            final file = await entity.file;
                            addToPlaylist(
                              MediaItem(
                                path: file!.path,
                                isNetwork: false,
                                type: entity.type == AssetType.audio
                                    ? "audio"
                                    : "video",
                                id: entity.id,
                                isFavourite: entity.isFavorite,
                              ),
                              context,
                            );
                            break;
                        }
                      },
                      onTap: null,
                      entity: entity,
                      option: const ThumbnailOption(
                        size: ThumbnailSize.square(150),
                      ),
                    )
                        : Container(
                      color: Colors.black12,
                      child: Center(
                        child: Text(
                          (entity as MediaItem).path.split('/').last,
                          textAlign: TextAlign.center,
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

  _buildListView(List<dynamic> entitiesToShow, bool hasMore, {Key? key}) {
    // Ã°Å¸Å¸Â¢ Ad frequency: Darek 5 items pachi ek ad
    const int adIndexInterval = 5;

    return ListView.builder(
      key: key,
      controller: _scrollController,
      padding: const EdgeInsets.all(4),
      // Ã°Å¸Å¸Â¢ Item count ma ads ni sankhya add karvi padse
      itemCount: (hasMore ? entitiesToShow.length + 1 : entitiesToShow.length) +
          (entitiesToShow.length ~/ adIndexInterval),
      itemBuilder: (context, index) {
        // ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ FIRST CHECK LOADER

        // Ã°Å¸Å¸Â¢ Logic: Check karo ke aa ad ni jagya chhe?
        if (index != 0 && (index + 1) % (adIndexInterval + 1) == 0) {
          return AdHelper.bannerAdWidget(size: AdSize.banner); // Nano banner list ni vachma
        }

        // Ã°Å¸Å¸Â¢ Actual data index calculate karo (Ads ne bad karye pachi no index)
        final int actualIndex = index - (index ~/ (adIndexInterval + 1));
        if (actualIndex >= entitiesToShow.length) {
          return const Padding(
            padding: EdgeInsets.all(0),
            child: Center(child: CustomLoader()),
          );
        }
        final entity = entitiesToShow[index];

        return AppTransition(
          index: actualIndex % 10,
          child: ImageItemWidget(
            onMenuSelected: (action) async {
              switch (action) {
                case MediaMenuAction.detail:
                  routeToDetailPage(context, entity);
                  break;

                case MediaMenuAction.info:
                  showInfoDialog(context, entity);
                  break;

                case MediaMenuAction.thumb:
                  showThumb(entity, 500);
                  break;

                case MediaMenuAction.share:
                  shareItem(context, entity);
                  break;

                case MediaMenuAction.delete:
                  deleteCurrentItem(context, entity);
                  break;

                case MediaMenuAction.addToFavourite:
                  await _toggleFavourite(context, entity, index);
                  break;
                case MediaMenuAction.addToPlaylist:
                  final file = await entity.file;
                  addToPlaylist(
                    MediaItem(
                      path: file!.path,
                      isNetwork: false,
                      type: entity.type == AssetType.audio ? "audio" : "video",
                      id: entity.id,
                      isFavourite: entity.isFavorite,
                    ),
                    context,
                  );
                  break;
              }
            },
            onTap: () async {
              print("vudio====${entity.typeInt}");
              // final file = await entity.file;
              // if (file == null || !file.existsSync()) return;
              _navigateToPlayer(
                context,
                entitiesToShow.cast<AssetEntity>(),
                index,
                entity,
              );
            },
            isGrid: _isGridView,
            entity: entity,
            option: const ThumbnailOption(size: ThumbnailSize.square(150)),
          ),
        );
      },
    );
  }

  Future<void> showThumb(AssetEntity entity, int size) async {
    final String title;
    if (entity.title?.isEmpty != false) {
      title = await entity.titleAsync;
    } else {
      title = entity.title!;
    }
    print('entity.title = $title');
    return showDialog(
      context: context,
      builder: (_) {
        return FutureBuilder<Uint8List?>(
          future: entity.thumbnailDataWithOption(
            ThumbnailOption.ios(
              size: const ThumbnailSize.square(150),
              // resizeContentMode: ResizeContentMode.fill,
            ),
          ),
          builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
            Widget w;
            if (snapshot.hasError) {
              return ErrorWidget(snapshot.error!);
            } else if (snapshot.hasData) {
              final Uint8List data = snapshot.data!;
              ui.decodeImageFromList(data, (ui.Image result) {
                print('result size: ${result.width}x${result.height}');
                // for 4288x2848
              });
              w = Image.memory(data);
            } else {
              w = Center(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: const CustomLoader(),
                ),
              );
            }
            return GestureDetector(
              child: w,
              onTap: () => Navigator.pop(context),
            );
          },
        );
      },
    );
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

    // ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¹ Update Hive
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

    // ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¹ Reload entity
    final AssetEntity? newEntity = await entity.obtainForNewProperties();
    if (!mounted || newEntity == null) return;

    context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));

    setState(() {});
  }

  void _navigateToPlayer(
      BuildContext context,
      List<AssetEntity> allEntities,
      int currentIndex,
      AssetEntity video,
      ) async {

    // àª† àª«àª‚àª•à«àª¶àª¨ àªªà«àª²à«‡àª¯àª° àª¸à«àª•à«àª°à«€àª¨ àªªàª° àª²àªˆ àªœàª¶à«‡
    void moveNext() async {
      final file = await video.file;
      if (file == null || !file.existsSync()) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            entityList: allEntities,
            entity: video,
            item: MediaItem(
              isFavourite: video.isFavorite,
              id: video.id,
              path: file.path,
              isNetwork: false,
              type: 'video',
            ),
            index: currentIndex, // àª‡àª¨à«àª¡à«‡àª•à«àª¸ àªªàª¾àª¸ àª•àª°àªµà«‹ àªœàª°à«‚àª°à«€ àª›à«‡ àªœà«‹ àªªà«àª²à«‡àª¯àª°àª®àª¾àª‚ àª¨à«‡àª•à«àª¸à«àªŸ/àªªà«àª°àª¿àªµàª¿àª¯àª¸ àª•àª°àªµà«àª‚ àª¹à«‹àª¯ àª¤à«‹
          ),
        ),
      ).then((_) {
        if (context.mounted) {
          context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
        }
      });
    }

    // àª•à«àª²àª¿àª• àª•àª¾àª‰àª¨à«àªŸ àªµàª§àª¾àª°à«‹
    _videoClickCount++;

    // àª¦àª° 3 àª•à«àª²àª¿àª• àªªàª° àªàª¡ àª¬àª¤àª¾àªµà«‹
    if (_videoClickCount % 3 == 0) {
      debugPrint("Showing Interstitial Ad on count: $_videoClickCount");

      AdHelper.showInterstitialAd(() {
        // àªàª¡ àªªà«‚àª°à«€ àª¥àª¯àª¾ àªªàª›à«€ àª…àª¥àªµàª¾ àªàª¡ àª²à«‹àª¡ àª¨ àª¥àª¾àª¯ àª¤à«‹ àª† àª•à«‹àª²àª¬à«‡àª• àª°àª¨ àª¥àª¶à«‡
        moveNext();
      });
    } else {
      // àªœà«‹ 3 àª•à«àª²àª¿àª• àª¨ àª¥àªˆ àª¹à«‹àª¯, àª¤à«‹ àª¸à«€àª§à«àª‚ àªœ àªµà«€àª¡àª¿àª¯à«‹ àªªà«àª²à«‡ àª•àª°à«‹
      debugPrint("Skipping Ad, Current count: $_videoClickCount");
      moveNext();
    }
  }
}