import 'dart:ui' as ui;
import 'package:media_player/screens/search_screen.dart';

import '../models/media_item.dart' as my;
import '../services/ads_service.dart';
import '../utils/app_imports.dart';

class VideoScreen extends StatefulWidget {
  bool isComeHomeScreen;
  /// When false, no in-screen mini player (e.g. main shell provides one — avoids duplicate [Hero] tags in [IndexedStack]).
  final bool showMiniPlayer;

  VideoScreen({
    super.key,
    this.isComeHomeScreen = true,
    this.showMiniPlayer = true,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}


class _VideoScreenState extends State<VideoScreen> {
  String _searchQuery = '';
  bool _isGridView = true;
  String _selectedLetter = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) {
      try {
        final state = context.read<VideoBloc>().state;
        if (state is VideoLoaded && state.hasMore) {
          context.read<VideoBloc>().add(LoadMoreVideos());
        }
      } catch (e) {
        print("Error in scroll: $e");
      }
    }

    final state = context.read<VideoBloc>().state;
    if (state is VideoLoaded) {
      double currentOffset = _scrollController.offset;
      double itemHeight = _isGridView ? 190.0 : 90.0;

      int currentIndex;
      if (_isGridView) {
        int currentRow = (currentOffset / itemHeight).floor();
        currentIndex = currentRow * 2;
      } else {
        currentIndex = (currentOffset / itemHeight).floor();
      }

      if (currentIndex >= 0 && currentIndex < state.entities.length) {
        final entity = state.entities[currentIndex];
        final name = entity.title ?? "";

        if (name.isNotEmpty) {
          String firstChar = name[0].toUpperCase();
          String currentLetter =
          RegExp(r'^\p{L}', unicode: true).hasMatch(firstChar)
              ? firstChar
              : '#';

          if (_selectedLetter != currentLetter) {
            setState(() {
              _selectedLetter = currentLetter;
            });
          }
        }
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

    if (widget.isComeHomeScreen) {
      return Scaffold(
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
          title: AppText(
            "videos",
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
          child: widget.showMiniPlayer
              ? Stack(
                  children: [
                    Column(
                      children: [
                        AdHelper.adaptiveBannerWidget(context),
                        Expanded(child: _buildVideoPage()),
                      ],
                    ),
                    SmartMiniPlayer(forceMiniMode: true),
                  ],
                )
              : Column(
                  children: [
                    AdHelper.adaptiveBannerWidget(context),
                    Expanded(child: _buildVideoPage()),
                  ],
                ),
        ),
      );
    } else {
      final content = Column(
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
          AdHelper.adaptiveBannerWidget(context),
          Expanded(child: _buildVideoPage()),
        ],
      );
      if (!widget.showMiniPlayer) return content;
      return Stack(
        children: [
          content,
          SmartMiniPlayer(forceMiniMode: true),
        ],
      );
    }
  }

  List<String> _getAlphabetList(List<AssetEntity> entities) {
    Set<String> letters = {};

    for (var entity in entities) {
      String name = entity.title ?? "";
      if (name.isEmpty) {
        name = entity.id;
      }

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

  void _scrollToLetter(String letter, List<dynamic> entities) {
    setState(() {
      _selectedLetter = letter;
    });

    int targetIndex = -1;

    for (int i = 0; i < entities.length; i++) {
      String name = "";
      if (entities[i] is AssetEntity) {
        name = entities[i].title ?? "";
      } else {
        name = entities[i].path.split('/').last;
      }

      if (name.isNotEmpty && name[0].toUpperCase() == letter) {
        targetIndex = i;
        break;
      }
    }

    if (targetIndex != -1) {
      double itemHeight = _isGridView ? 180.0 : 80.0;
      double offset = (targetIndex / (_isGridView ? 2 : 1)) * itemHeight;

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildVideoPage() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return BlocBuilder<VideoBloc, VideoState>(
      buildWhen: (previous, current) =>
          current is VideoLoaded ||
          current is VideoLoading ||
          current is VideoError ||
          current is VideoInitial,
      builder: (context, state) {
        if (state is VideoInitial || state is VideoLoading) {
          return const MediaShimmerLoading();
        }

        if (state is VideoError) {
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
                      context.read<VideoBloc>().add(
                            LoadVideosFromGallery(
                              showLoading: true,
                              isRefresh: true,
                            ),
                          );
                    },
                    icon: const Icon(Icons.refresh),
                    label: AppText('retry', fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is VideoLoaded) {
          List<AssetEntity> entitiesToShow = _searchQuery.isEmpty
              ? List.from(state.entities)
              : state.entities.where((e) {
            final name = (e.title ?? '');
            return name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
          }).toList();

          entitiesToShow.sort((a, b) {
            String nameA = (a.title ?? "");
            String nameB = (b.title ?? "");

            return nameA.toLowerCase().compareTo(nameB.toLowerCase());
          });

          if (entitiesToShow.isEmpty && _searchQuery.isNotEmpty) {
            return const Center(child: AppText("noResultFound"));
          }

          final alphabetList = _getAlphabetList(entitiesToShow);

          return Stack(
            children: [
              Positioned.fill(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent - 200) {
                      if (state.hasMore) {
                        context.read<VideoBloc>().add(LoadMoreVideos());
                      }
                    }
                    return true;
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
                ),
              ),

              Positioned(
                right: 6,
                top: 50,
                child: Container(
                  width: 22,
                  decoration: BoxDecoration(
                    color: colors.blackColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: alphabetList.map((letter) {
                      bool isActive = _selectedLetter == letter;
                      return GestureDetector(
                        onTap: () => _scrollToLetter(letter, entitiesToShow),
                        child: Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.symmetric(vertical: 1.5),
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
            ],
          );
        }
        return const MediaShimmerLoading();
      },
    );
  }

  _buildGridView(List<dynamic> entitiesToShow, bool hasMore, {Key? key}) {
    final List<Widget> slivers = [];
    const int chunkSize = 16;

    for (int i = 0; i < entitiesToShow.length; i += chunkSize) {
      final int currentChunkSize = chunkSize < entitiesToShow.length - i
          ? chunkSize
          : entitiesToShow.length - i;
      final int startOffset = i;

      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final int actualIndex = startOffset + index;
                final entity = entitiesToShow[actualIndex];

                return AppTransition(
                  index: actualIndex % 10,
                  columnCount: 2,
                  child: GestureDetector(
                    onTap: () async {
                      if (entity is AssetEntity) {
                        List<AssetEntity> videoList = entitiesToShow
                            .whereType<AssetEntity>()
                            .toList();
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
                                      actualIndex,
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
              childCount: currentChunkSize,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 15,
              childAspectRatio: 1.05,
            ),
          ),
        ),
      );

      if (i + chunkSize < entitiesToShow.length) {
        slivers.add(
          SliverToBoxAdapter(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AdHelper.bannerAdWidget(size: AdSize.largeBanner),
            ),
          ),
        );
      }
    }

    if (hasMore) {
      slivers.add(
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CustomLoader()),
          ),
        ),
      );
    }

    return CustomScrollView(
      key: key,
      controller: _scrollController,
      slivers: slivers,
    );
  }

  _buildListView(List<dynamic> entitiesToShow, bool hasMore, {Key? key}) {
    final List<dynamic> displayItems = [];
    const int adInterval = 15;
    for (int i = 0; i < entitiesToShow.length; i++) {
      if (i > 0 && i % adInterval == 0) {
        displayItems.add(const AdPlaceholder());
      }
      displayItems.add(entitiesToShow[i]);
    }

    final int totalCount = displayItems.length + (hasMore ? 1 : 0);

    return ListView.builder(
      key: key,
      controller: _scrollController,
      padding: const EdgeInsets.all(4),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (hasMore && index == totalCount - 1) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CustomLoader()),
          );
        }

        final item = displayItems[index];

        if (item is AdPlaceholder) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AdHelper.bannerAdWidget(size: AdSize.banner),
          );
        }

        final entity = item;
        final int actualIndex = entitiesToShow.indexOf(entity);

        if (actualIndex >= entitiesToShow.length || actualIndex == -1) {
          return const SizedBox.shrink();
        }

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
                  await _toggleFavourite(context, entity, actualIndex);
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
              _navigateToPlayer(
                context,
                entitiesToShow.cast<AssetEntity>(),
                actualIndex,
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
            ThumbnailOption.ios(size: const ThumbnailSize.square(150)),
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

  void _navigateToPlayer(
      BuildContext context,
      List<dynamic> allEntities,
      int currentIndex,
      dynamic currentItem,
      ) async {
    void moveNext() async {
      bool isAudio = false;
      if (currentItem is AssetEntity) {
        isAudio = currentItem.type == AssetType.audio;
      } else if (currentItem is my.MediaItem) {
        isAudio = currentItem.type == 'audio';
      }

      if (isAudio) {
        final audioPlayer = GlobalPlayer();

        List<AssetEntity> entities = allEntities
            .whereType<AssetEntity>()
            .toList();

        await audioPlayer.initAndPlay(
          entities: entities,
          selectedId: (currentItem is AssetEntity)
              ? currentItem.id
              : currentItem.id,
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              entityList: allEntities.cast<AssetEntity>(),
              entity: currentItem as AssetEntity,
              index: currentIndex,
            ),
          ),
        );
      }
    }

    AdHelper.showInterstitialAd(() => moveNext());
  }
}

class AdPlaceholder {
  const AdPlaceholder();
}