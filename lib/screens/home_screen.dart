

import 'dart:ui' as ui;
import 'package:media_player/utils/app_imports.dart';

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

  bool isShowViewAllButton = false;
  int activeIndex = 0;

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<HomeCountBloc>().add(LoadCounts());
    context.read<VideoBloc>().add(
      LoadVideosFromGallery(showLoading: false),
    ); // optional: refresh video list
    context.read<AudioBloc>().add(LoadAudios()); // optional: refresh video list
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeCountBloc>().add(LoadCounts());
        _loadFolders();
      }
    });
  }

// HomePage build method ma aa mujab logic rakho:
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCountBloc()..add(LoadCounts()),
      child: BlocListener<HomeTabBloc, HomeTabState>(
        listener: (context, state) {
          context.read<HomeCountBloc>().add(LoadCounts());
        },
        child: Stack( // ðŸŸ¢ Humesha Stack j rakho
          children: [
            Column(
              children: [
                Expanded(child: _buildHomePageWidget()),
                // Audio chaltu hoy to niche space khali karva mate niche no part:
                // AnimatedBuilder(
                //   animation: GlobalPlayer(),
                //   builder: (context, _) {
                //     final player = GlobalPlayer();
                //     // Fakt Audio hoy tyare j Column ma space add karo
                //     if (player.currentType == "audio" && player.currentIndex != -1) {
                //       return SizedBox(height: 10);
                //     }
                //     return const SizedBox.shrink();
                //   },
                // ),
              ],
            ),
            // ðŸŸ¢ Player humesha Stack na child tarike j raheshe
            const SmartMiniPlayer(forceMiniMode: true),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePageWidget() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return BlocBuilder<HomeCountBloc, HomeCountState>(
      builder: (context, state) {
        return Column(
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
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Grid of Cards
                    //state.entitie
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
                              onBack: () => context.read<HomeCountBloc>().add(
                                LoadCounts(),
                              ),
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
                              onBack: () => context.read<HomeCountBloc>().add(
                                LoadCounts(),
                              ),
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
                              onBack: () => context.read<HomeCountBloc>().add(
                                LoadCounts(),
                              ),
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
                              onBack: () => context.read<HomeCountBloc>().add(
                                LoadCounts(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.only(
                        left: 0,
                        right: 0,
                        top: 21,
                        bottom: 15,
                      ),
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
                              if (isVideoTab && state.videoCount > 6) {
                                showButton = true;
                              } else if (isFolderTab && folderList.length > 4) {
                                showButton = true;
                              }

                              if (!showButton) return const SizedBox.shrink();

                              return GestureDetector(
                                onTap: isVideoTab
                                    ? () {
                                  Navigator.pushNamed(
                                    context,
                                    "/video",
                                  ).then((value) {
                                    context.read<HomeCountBloc>().add(
                                      LoadCounts(),
                                    );
                                    context.read<VideoBloc>().add(
                                      LoadVideosFromGallery(
                                        showLoading: false,
                                      ),
                                    );
                                  });
                                }
                                    : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      const FolderScreen(),
                                    ),
                                  );
                                },
                                child: AppText(
                                  "viewAll",
                                  color: colors.primary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(0),
                      child: BlocBuilder<HomeTabBloc, HomeTabState>(
                        builder: (context, state) {
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.05),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: state.selectedIndex == 0
                                ? Container(
                              key: const ValueKey(0),
                              child: _buildVideoSection(),
                            )
                                : Container(
                              key: const ValueKey(1),
                              child: _buildFolderSection(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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

  // Video Section using VideoBloc
  Widget _buildVideoSection() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        if (state is VideoLoading) {
          return const MediaShimmerLoading();
        }

        if (state is VideoError) {
          return Center(child: Text(state.message));
        }

        if (state is VideoLoaded) {
          final entities = state.entities;

          if (entities.isEmpty) {
            return AppText("noVideosFound", color: colors.whiteColor);
          }

          isShowViewAllButton = entities.length > 1;

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entities.length > 6 ? 6 : entities.length,
            itemBuilder: (context, index) {
              final entity = entities[index];
              return AppTransition(
                index: index + 5,
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
                    size: ThumbnailSize.square(300),
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox();
      },
    );
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

    // readPathProvider(context).list[index] = newEntity;
    context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
    context.read<HomeCountBloc>().add(LoadCounts());
    setState(() {});
  }

  // Folder Section
  Widget _buildFolderSection() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    if (folderList.isEmpty) {
      return AppText("noFoldersFound", color: colors.whiteColor);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: folderList.length > 4 ? 4 : folderList.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 15,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final item = folderList[index];
        return AppTransition(
          index: index + 5,
          columnCount: 2,
          child: GalleryItemWidget(
            path: item,
            setState: setState,
          ),   );
      },
    );
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

    if (!mounted) return; // ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ VERY IMPORTANT

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
              size: const ThumbnailSize.square(500),
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

  void _navigateToPlayer(
      BuildContext context,
      List<AssetEntity> allEntities,
      int currentIndex,
      ) async {
    final entity = allEntities[currentIndex];
    final file = await entity.file;

    if (file == null || !file.existsSync()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          entity: entity,
          item: MediaItem(
            isFavourite: entity.isFavorite,
            id: entity.id,
            path: file.path,
            isNetwork: false,
            type: 'video',
          ),
          index: currentIndex,
          entityList:
          allEntities,
        ),
      ),
    ).then((value) {
      context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
    });
  }
}