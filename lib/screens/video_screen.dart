import 'dart:ui' as ui;
import '../utils/app_imports.dart';

class VideoScreen extends StatefulWidget {
  bool isComeHomeScreen;

  VideoScreen({super.key, this.isComeHomeScreen = true});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

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
                ),
              ),
              SizedBox(width: 15),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: _buildVideoPage()),
              Align(
                alignment: Alignment.bottomCenter,
                child: SmartMiniPlayer(),
              ),
            ],
          ),
        ),
      );
    else
      return Column(
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
                  onTap: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  child: AppImage(
                    src: _isGridView ? AppSvg.listIcon : AppSvg.gridIcon,
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _buildVideoPage()),
          Align(alignment: Alignment.bottomCenter, child: SmartMiniPlayer()),
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
                    begin: const Offset(0.0, 0.02), // àª¸àª¹à«‡àªœ àª¨à«€àªšà«‡àª¥à«€ àª‰àªªàª° àª†àªµàª¶à«‡
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

      itemCount: hasMore ? entitiesToShow.length + 1 : entitiesToShow.length,
      itemBuilder: (context, index) {
        // âœ… FIRST CHECK LOADER
        if (index >= entitiesToShow.length) {
          return const Center(child: CustomLoader());
        }

        final entity = entitiesToShow[index];

        return AppTransition(
          index: index % 10,
          columnCount: 2,
          child: GestureDetector(
            onTap: () async {
              final entity = entitiesToShow[index];

              if (entity is AssetEntity) {
                List<AssetEntity> videoList = entitiesToShow
                    .whereType<AssetEntity>()
                    .toList();

                int actualIndex = videoList.indexOf(entity);

                _navigateToPlayer(context, videoList, actualIndex, entity);
              }
            },
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
                        size: ThumbnailSize.square(300),
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
    return ListView.builder(
      key: key,
      controller: _scrollController,
      padding: const EdgeInsets.all(4),
      itemCount: hasMore ? entitiesToShow.length + 1 : entitiesToShow.length,
      itemBuilder: (context, index) {
        // âœ… FIRST CHECK LOADER
        if (index >= entitiesToShow.length) {
          return const Padding(
            padding: EdgeInsets.all(0),
            child: Center(child: CustomLoader()),
          );
        }
        final entity = entitiesToShow[index];

        return AppTransition(
          index: index % 10,
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
            option: const ThumbnailOption(size: ThumbnailSize.square(300)),
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

    // ðŸ”¹ Update Hive
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

    // ðŸ”¹ Update system favourite
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

    // ðŸ”¹ Reload entity
    final AssetEntity? newEntity = await entity.obtainForNewProperties();
    if (!mounted || newEntity == null) return;

    // ðŸ”¹ Update UI list
    // readPathProvider(context).list[index] = newEntity;
    context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));

    setState(() {});
  }

  void _navigateToPlayer(
      BuildContext context,
      List<AssetEntity> allEntities,
      int currentIndex,
      AssetEntity video,
      ) async {
    // GlobalPlayer().initAndPlay(entities: allEntities, selectedId: video.id);
    // final entity = allEntities[currentIndex];
    final file = await video.file;

    if (file == null || !file.existsSync()) return;

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => PlayerScreen(
    //       entity: entity,
    //       item: MediaItem(
    //         isFavourite: entity.isFavorite,
    //         id: entity.id,
    //         path: file.path,
    //         isNetwork: false,
    //         type: 'video',
    //       ),
    //       // index: currentIndex,
    //       entityList: allEntities, // àª†àª–à«€ àª²àª¿àª¸à«àªŸ àª®à«‹àª•àª²à«‹ àªœà«‡àª¥à«€ Next/Prev àªšàª¾àª²à«‡
    //     ),
    //   ),
    // ).then((value) {
    //   // àªªà«àª²à«‡àª¯àª° àª®àª¾àª‚àª¥à«€ àªªàª¾àª›àª¾ àª†àªµà«àª¯àª¾ àªªàª›à«€ àª²àª¿àª¸à«àªŸ àª°àª¿àª«à«àª°à«‡àª¶ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡
    //   context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
    // });

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
        ),
      ),
    ).then((_) {
      context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
    });
  }
}