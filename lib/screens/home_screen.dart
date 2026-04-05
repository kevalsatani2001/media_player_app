import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:media_player/utils/app_imports.dart';

import '../services/ads_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  AssetPathProvider readPathProvider(BuildContext c) =>
      c.read<AssetPathProvider>();

  AssetPathProvider watchPathProvider(BuildContext c) =>
      c.watch<AssetPathProvider>();
  List<AssetPathEntity> folderList = <AssetPathEntity>[];

  final ScrollController _scrollController = ScrollController();
  bool _isFABVisible = true; // FAB àª¦à«‡àª–àª¾àª¶à«‡ àª•à«‡ àª¨àª¹à«€àª‚ àª¤à«‡ àª®àª¾àªŸà«‡àª¨à«àª‚ àª¸à«àªŸà«‡àªŸ

  bool isShowViewAllButton = false;
  int activeIndex = 0;

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    debugPrint("Home Screen: Refreshing counts...");
    context.read<HomeCountBloc>().add(LoadCounts());
    context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      // ScrollDirection àª®à«àªœàª¬ àª¨àª•à«àª•à«€ àª•àª°à«‹
      bool isScrollingDown = _scrollController.position.userScrollDirection == ScrollDirection.reverse;

      if (isScrollingDown && _isFABVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isFABVisible = false);
        });
      } else if (!isScrollingDown && !_isFABVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isFABVisible = true);
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeCountBloc>().add(LoadCounts());
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _loadFolders();
    });
  }

  // HomePage build method ma aa mujab logic rakho:
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return BlocListener<HomeTabBloc, HomeTabState>(
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<HomeCountBloc>().add(LoadCounts());
        });
      },
      child: Stack(
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
              Expanded(child: _buildHomePageWidget()),
              // SizedBox(height: 16),
            ],
          ),
          Align(
              alignment: Alignment.bottomRight,
              child: _buildResumeFAB()),
          // const SmartMiniPlayer(forceMiniMode: true),
        ],
      ),
    );
  }

  // HomeScreen.dart (àª…àª¥àªµàª¾ àªœà«àª¯àª¾àª‚ FAB àª¬àª¤àª¾àªµàªµà«àª‚ àª¹à«‹àª¯ àª¤à«àª¯àª¾àª‚)



  Widget _buildResumeFAB() {
    final playerService = GlobalPlayerService();
    if (!Hive.isBoxOpen('last_played')) return const SizedBox.shrink(); // àª¸à«‡àª«à«àªŸà«€ àªšà«‡àª•

    final box = Hive.box('last_played');
    final String? lastId = box.get('last_id');

    if (lastId == null || playerService.playlist.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _isFABVisible ? 1.0 : 0.0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        scale: _isFABVisible ? 1.0 : 0.0,
        child: Padding(
            padding: EdgeInsets.only(bottom: 20,right: 15),
            child: Hero(
              tag: "resume_btn",
              child: GestureDetector(
                  onTap: _isFABVisible ? () { // àªœà«àª¯àª¾àª°à«‡ àª¦à«‡àª–àª¾àª¤à«àª‚ àª¹à«‹àª¯ àª¤à«àª¯àª¾àª°à«‡ àªœ àª•à«àª²àª¿àª• àª¥àª¾àª¯
                    int lastIndex = box.get('last_index', defaultValue: 0);
                    int lastPos = box.get('last_position', defaultValue: 0);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(
                          entityList: playerService.playlist,
                          entity: playerService.playlist[lastIndex],
                          index: lastIndex,
                          resumePosition: lastPos,
                        ),
                      ),
                    );
                  } : null,
                  child: AppImage(src: AppSvg.playVid,height: 50,width: 50,)),
            )
        ),
      ),
    );
  }

  Widget _buildHomePageWidget() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return BlocBuilder<HomeCountBloc, HomeCountState>(
      builder: (context, state) {
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  AdHelper.adaptiveBannerWidget(context),
                  SizedBox(height: 8),
                  // Adaptive Banner
                  // Padding(
                  //   padding: const EdgeInsets.only(left: 9,right: 9,bottom: 15),
                  //   child: Center(
                  //     child: Container(
                  //      child: AdHelper.adaptiveBannerWidget(context),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildGridCards(state),
                    const SizedBox(height: 20),
                    // Native Ad with Placeholder
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: colors.textFieldFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AdHelper.bannerAdWidget(
                        size: AdSize.mediumRectangle,
                      ),
                    ),
                    _buildTabRow(context, state),
                  ],
                ),
              ),
            ),
            BlocBuilder<HomeTabBloc, HomeTabState>(
              builder: (context, tabState) {
                return tabState.selectedIndex == 0
                    ? _buildSliverVideoList()
                    : _buildSliverFolderGrid();
              },
            ),

          ],
        );
      },
    );
  }

  Widget _buildGridCards(HomeCountState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTransition(
                index: 0,
                child: HomeCard(
                  title: "video",
                  icon: AppSvg.videoIcon,
                  route: "/video",
                  count: state.videoCount,
                  onBack: () => context.read<HomeCountBloc>().add(LoadCounts()),
                  // loadCounts: Future(() => context.read<HomeCountBloc>().add(LoadCounts())),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: AppTransition(
                index: 1,
                child: HomeCard(
                  title: "audio",
                  icon: AppSvg.audioIcon,
                  route: "/audio",
                  count: state.audioCount,
                  onBack: () => context.read<HomeCountBloc>().add(LoadCounts()),
                  // loadCounts:  Future(() => context.read<HomeCountBloc>().add(LoadCounts())),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppTransition(
                index: 2,
                child: HomeCard(
                  title: "playlist",
                  icon: AppSvg.playlistIcon,
                  route: "/playlist",
                  count: state.playlistCount,
                  onBack: () => context.read<HomeCountBloc>().add(LoadCounts()),
                  // loadCounts:  Future(() => context.read<HomeCountBloc>().add(LoadCounts())),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: AppTransition(
                index: 3,
                child: HomeCard(
                  title: "favourite",
                  icon: AppSvg.favouriteIcon,
                  route: "/favourite",
                  count: state.favouriteCount,
                  onBack: () => context.read<HomeCountBloc>().add(LoadCounts()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabRow(BuildContext context, HomeCountState state) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 21, bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildTab(context, "video", 0),
              const SizedBox(width: 25),
              _buildTab(context, "folder", 1),
            ],
          ),
          BlocBuilder<HomeTabBloc, HomeTabState>(
            builder: (context, tabState) {
              final isVideoTab = tabState.selectedIndex == 0;
              final isFolderTab = tabState.selectedIndex == 1;

              bool showButton = false;
              if (isVideoTab && state.videoCount > 4) {
                showButton = true;
              } else if (isFolderTab && folderList.length > 4) {
                showButton = true;
              }

              if (!showButton) return const SizedBox.shrink();

              return GestureDetector(
                onTap: isVideoTab
                    ? () {
                  Navigator.pushNamed(context, "/video").then((value) {
                    context.read<HomeCountBloc>().add(LoadCounts());
                    context.read<VideoBloc>().add(
                      LoadVideosFromGallery(showLoading: false),
                    );
                  });
                }
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FolderScreen(),
                    ),
                  );
                },
                child: AppText("viewAll", color: colors.primary),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String title, int index) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return BlocBuilder<HomeTabBloc, HomeTabState>(
      builder: (context, state) {
        final isActive = state.selectedIndex == index;

        return GestureDetector(
          onTap: () async {
            context.read<HomeTabBloc>().add(SelectTab(index));
            if (index == 1) {
              await _loadFolders();
            } else if (index == 0) {
              context.read<VideoBloc>().add(
                LoadVideosFromGallery(showLoading: false),
              );
            }
            setState(() {
              activeIndex = index;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText(
                title,
                color: isActive
                    ? colors.appBarTitleColor
                    : colors.textFieldBorder,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.linear,
                height: 3,
                width: isActive ? 35 : 0,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
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

    final state = context.read<VideoBloc>().state;
    if (state is VideoLoaded) {
      state.entities[index] = newEntity;
    }

    setState(() {});
  }

  // Load folders using PhotoManager
  Future<void> _loadFolders() async {
    final permission = await PhotoManager.requestPermissionExtend(
      requestOption: PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.fromTypes([RequestType.audio, RequestType.video]),
          mediaLocation: true,
        ),
      ),
    );

    if (!permission.hasAccess) return;

    final List<AssetPathEntity> galleryList =
    await PhotoManager.getAssetPathList(
      type: RequestType.fromTypes([RequestType.audio, RequestType.video]),
      filterOption: FilterOptionGroup(),
      pathFilterOption: PMPathFilter(
        darwin: PMDarwinPathFilter(
          type: [PMDarwinAssetCollectionType.album],
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      folderList = galleryList;
    });
  }

  Future<void> routeToDetailPage(AssetEntity entity) async {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => DetailPage(entity: entity)),
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

  int _videoClickCount = 0;

  void _navigateToPlayer(
      BuildContext context,
      List<AssetEntity> allEntities,
      int currentIndex,
      ) async {
    final entity = allEntities[currentIndex];
    final file = await entity.file;
    if (file == null || !file.existsSync()) return;

    void openPlayer() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            entity: entity,
            // item: MediaItem(
            //   isFavourite: entity.isFavorite,
            //   id: entity.id,
            //   path: file.path,
            //   isNetwork: false,
            //   type: 'video',
            // ),
            index: currentIndex,
            entityList: allEntities,
          ),
        ),
      ).then((value) {
        if (context.mounted) {
          context.read<VideoBloc>().add(
            LoadVideosFromGallery(showLoading: false),
          );
        }
      });
    }

    _videoClickCount++;

    if (_videoClickCount % 3 == 0) {
      debugPrint("Showing Interstitial Ad before navigation...");

      AdHelper.showInterstitialAd(() {
        openPlayer();
      });
    } else {
      openPlayer();
    }
  }

  Widget _buildSliverFolderGrid() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    if (folderList.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: AppText("noFoldersFound", color: colors.whiteColor),
        ),
      );
    }

    final displayCount = folderList.length > 4 ? 4 : folderList.length;
    const int adInterval = 2;
    int totalCount = displayCount + (displayCount ~/ adInterval);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 15,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index != 0 && (index + 1) % (adInterval + 1) == 0) {
            return Container(
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: AdHelper.bannerAdWidget(
                      size: AdSize.mediumRectangle,
                    ),
                  ),
                ),
              ),
            );
          }

          final int actualIndex = index - (index ~/ (adInterval + 1));
          if (actualIndex >= folderList.length) return const SizedBox.shrink();

          final item = folderList[actualIndex];

          // final item = folderList[index];
          return AppTransition(
            index: index + 5,
            columnCount: 2,
            child: GalleryItemWidget(path: item, setState: setState),
          );
        }, childCount: totalCount),
      ),
    );
  }

  Widget _buildSliverVideoList() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    const int adInterval = 2;
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        if (state is VideoLoading) {
          return const SliverToBoxAdapter(child: MediaShimmerLoading());
        }

        if (state is VideoLoaded) {
          final entities = state.entities;
          if (entities.isEmpty) {
            return SliverToBoxAdapter(
              child: Center(
                child: AppText("noVideosFound", color: colors.whiteColor),
              ),
            );
          }

          final displayCount = entities.length > 6 ? 6 : entities.length;

          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {

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
              final entity = entities[actualIndex];
              // final entity = entities[index];
              return AppTransition(
                index: index + 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: ImageItemWidget(
                    onMenuSelected: (action) async {
                      switch (action) {
                        case MediaMenuAction.detail:
                          routeToDetailPage(entity);
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
                    onTap: () async {
                      _navigateToPlayer(
                        context,
                        entities.cast<AssetEntity>(),
                        index,
                      );
                    },
                    isGrid: false,
                    entity: entity,
                    option: const ThumbnailOption(
                      size: ThumbnailSize.square(
                        150,
                      ), ),
                  ),
                ),
              );
            }, childCount: displayCount),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox());
      },
    );
  }
}