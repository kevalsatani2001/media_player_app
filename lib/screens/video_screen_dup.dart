import 'dart:ui' as ui;
import '../models/media_item.dart' as my;
import '../services/ads_service.dart';
import '../utils/app_imports.dart';

class VideoScreen extends StatefulWidget {
  bool isComeHomeScreen;

  VideoScreen({super.key, this.isComeHomeScreen = true});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

int _videoClickCount = 0;

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
        var entity = state.entities[currentIndex];
        String name = (entity is AssetEntity)
            ? (entity.title ?? "")
            : (entity as my.MediaItem).path.split('/').last;

        if (name.isNotEmpty) {
          String firstChar = name[0].toUpperCase();
          String currentLetter = RegExp(r'^\p{L}', unicode: true).hasMatch(firstChar) ? firstChar : '#';

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
      // Use the global `VideoBloc` provided in `main.dart` so this screen
      // does not reload every time you navigate back.
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
          child: Stack(
            children: [
              Column(
                children: [
                  AdHelper.adaptiveBannerWidget(context),
                  Expanded(child: _buildVideoPage()),
                ],
              ),
              SmartMiniPlayer(forceMiniMode: true),
              // Aa widget potani rite handle karshe
            ],
          ),
        ),
      );
    }


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

              AdHelper.adaptiveBannerWidget(context),

              Expanded(child: _buildVideoPage()),
            ],
          ),
          SmartMiniPlayer(forceMiniMode: true),
        ],
      );
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

    List<String> sortedLetters = letters.toList()..sort((a, b) {
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
          current is VideoError,
      builder: (context, state) {
        if (state is VideoLoading) {
          return const MediaShimmerLoading();
        }

        if (state is VideoError) {
          return Center(child: Text(state.message));
        }

        if (state is VideoLoaded) {
          List<AssetEntity> entitiesToShow = _searchQuery.isEmpty
              ? List.from(state.entities)
              : state.entities.where((e) {
            final name = (e.title ?? '');
            return name.toLowerCase().contains(_searchQuery.toLowerCase());
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
                      if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
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
                  )
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
                            color: isActive ? colors.primary : Colors.transparent,
                          ),
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive ? Colors.white : colors.blackColor.withOpacity(0.6),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  _buildGridView(List<dynamic> entitiesToShow, bool hasMore, {Key? key}) {
    const int adIndexInterval = 4;
    int adCount = entitiesToShow.length ~/ adIndexInterval;
    int totalItems = entitiesToShow.length + adCount;

    int finalItemCount = hasMore ? totalItems + 1 : totalItems;

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

      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (hasMore && index == finalItemCount - 1) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CustomLoader(),
            ),
          );
        }

        if (index != 0 && (index + 1) % (adIndexInterval + 1) == 0) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: AdHelper.bannerAdWidget(size: AdSize.mediumRectangle),
                ),
              ),
            ),
          );
        }

        final int actualIndex = index - (index ~/ (adIndexInterval + 1));

        if (actualIndex >= entitiesToShow.length) {
          return const SizedBox.shrink();
        }

        final entity = entitiesToShow[actualIndex];

        return AppTransition(
          index: index % 10,
          columnCount: 2,
          child: GestureDetector(
            onTap: () async {
              if (entity is AssetEntity) {
                List<AssetEntity> videoList = entitiesToShow
                    .whereType<AssetEntity>()
                    .toList();

                final entity = entitiesToShow[actualIndex];
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
    const int adIndexInterval = 5;

    int adCount = entitiesToShow.length ~/ adIndexInterval;
    int totalItems = entitiesToShow.length + adCount;
    int finalItemCount = hasMore ? totalItems + 1 : totalItems;

    return ListView.builder(
      key: key,
      controller: _scrollController,
      padding: const EdgeInsets.all(4),
      itemCount:
      (hasMore ? entitiesToShow.length + 1 : entitiesToShow.length) +
          (entitiesToShow.length ~/ adIndexInterval),
      itemBuilder: (context, index) {
        if (hasMore && index == finalItemCount - 1) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CustomLoader()),
          );
        }

        if (index != 0 && (index + 1) % (adIndexInterval + 1) == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AdHelper.bannerAdWidget(size: AdSize.banner),
          );
        }

        final int actualIndex = index - (index ~/ (adIndexInterval + 1));
        if (actualIndex >= entitiesToShow.length) {
          return const SizedBox.shrink();
        }

        final entity = entitiesToShow[actualIndex];

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

    context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));

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

    _videoClickCount++;
    if (_videoClickCount % 3 == 0) {
      AdHelper.showInterstitialAd(() => moveNext());
    } else {
      moveNext();
    }
  }
}











//
//
// import 'dart:ui' as ui;
// import '../models/media_item.dart' as my;
// import '../services/ads_service.dart';
// import '../utils/app_imports.dart';
//
// class VideoScreen extends StatefulWidget {
//   bool isComeHomeScreen;
//
//   VideoScreen({super.key, this.isComeHomeScreen = true});
//
//   @override
//   State<VideoScreen> createState() => _VideoScreenState();
// }
//
// // 1. Class ni upar ek global variable banavo counter mate
// int _videoClickCount = 0;
//
// class _VideoScreenState extends State<VideoScreen> {
//   String _searchQuery = '';
//   bool _isGridView = true;
//   String _selectedLetter = '';
//   final ScrollController _scrollController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_onScroll);
//   }
//
//   void _onScroll() {
//     // --- LOAD MORE LOGIC (àª¤àª®àª¾àª°à«‹ àªœà«‚àª¨à«‹ àª•à«‹àª¡) ---
//     if (_scrollController.position.extentAfter < 500) {
//       try {
//         final state = context.read<VideoBloc>().state;
//         if (state is VideoLoaded && state.hasMore) {
//           context.read<VideoBloc>().add(LoadMoreVideos());
//         }
//       } catch (e) {
//         print("Error in scroll: $e");
//       }
//     }
//
//     // --- AUTO SELECT LETTER LOGIC (àª¨àªµà«‹ àª•à«‹àª¡) ---
//     final state = context.read<VideoBloc>().state;
//     if (state is VideoLoaded) {
//       double currentOffset = _scrollController.offset;
//       double itemHeight = _isGridView ? 190.0 : 90.0; // àª¤àª®àª¾àª°à«€ àª†àªˆàªŸàª®àª¨à«€ àª…àª‚àª¦àª¾àªœàª¿àª¤ àªŠàª‚àªšàª¾àªˆ
//
//       // àª…àª¤à«àª¯àª¾àª°à«‡ àª•àª¯àª¾ àª‡àª¨à«àª¡à«‡àª•à«àª¸ àªªàª° àª¯à«àªàª° àª›à«‡ àª¤à«‡ àª¶à«‹àª§à«‹
//       int currentIndex;
//       if (_isGridView) {
//         // GridView àª®àª¾àª‚ 2 àª•à«‹àª²àª® àª›à«‡ àªàªŸàª²à«‡ àª°à«‹ àª—àª£à«‹
//         int currentRow = (currentOffset / itemHeight).floor();
//         currentIndex = currentRow * 2;
//       } else {
//         currentIndex = (currentOffset / itemHeight).floor();
//       }
//
//       // àª‡àª¨à«àª¡à«‡àª•à«àª¸ àª²àª¿àª¸à«àªŸàª¨à«€ àª°à«‡àª¨à«àªœàª®àª¾àª‚ àª›à«‡ àª•à«‡ àª¨àª¹à«€àª‚ àª¤à«‡ àªšà«‡àª• àª•àª°à«‹
//       if (currentIndex >= 0 && currentIndex < state.entities.length) {
//         var entity = state.entities[currentIndex];
//         String name = (entity is AssetEntity)
//             ? (entity.title ?? "")
//             : (entity as my.MediaItem).path.split('/').last;
//
//         if (name.isNotEmpty) {
//           String firstChar = name[0].toUpperCase();
//           String currentLetter = RegExp(r'^[A-Z]').hasMatch(firstChar) ? firstChar : '#';
//
//           // àªœà«‹ àª…àª•à«àª·àª° àª¬àª¦àª²àª¾àª¯à«‹ àª¹à«‹àª¯ àª¤à«‹ àªœ setState àª•àª°à«‹ (àªªàª°àª«à«‹àª°à«àª®àª¨à«àª¸ àª®àª¾àªŸà«‡)
//           if (_selectedLetter != currentLetter) {
//             setState(() {
//               _selectedLetter = currentLetter;
//             });
//           }
//         }
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   final GlobalPlayer player = GlobalPlayer();
//
//   @override
//   Widget build(BuildContext context) {
//     final colors = Theme.of(context).extension<AppThemeColors>()!;
//     final box = Hive.box('videos');
//
//
//     if (widget.isComeHomeScreen) {
//       return BlocProvider(
//         create: (_) => VideoBloc(Hive.box('videos'))
//           ..add(LoadVideosFromGallery(showLoading: false)),
//         child: Builder( // Builder Ã ÂªÂµÃ ÂªÂ¾Ã ÂªÂªÃ ÂªÂ°Ã ÂªÂµÃ Â«â€¹ Ã ÂªÅ“Ã ÂªÂ°Ã Â«â€šÃ ÂªÂ°Ã Â«â‚¬ Ã Âªâ€ºÃ Â«â€¡ Ã ÂªÅ“Ã Â«â€¡Ã ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ¨Ã ÂªÂµÃ Â«â€¹ Context Ã ÂªÂ®Ã ÂªÂ³Ã Â«â€¡
//           builder: (context) {
//             return Scaffold(
//               appBar: AppBar(
//                 leading: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: AppImage(
//                       src: AppSvg.backArrowIcon,
//                       color: colors.blackColor,
//                       height: 20,
//                       width: 20,
//                     ),
//                   ),
//                 ),
//                 centerTitle: true,
//                 title: AppText("videos", fontSize: 20, fontWeight: FontWeight.w500),
//
//                 actions: [
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const SearchScreen()),
//                       );
//                     },
//                     child: Container(
//                       height: 24,
//                       width: 24,
//                       child: Padding(
//                         padding: const EdgeInsets.all(2),
//                         child: AppImage(
//                           src: "assets/svg_icon/search_icon.svg",
//                           height: 24,
//                           width: 24,
//                           color: colors.blackColor,
//                         ),
//                       ),
//                     ),
//                   ),
//                   // Builder(builder: (context) {
//                   //   return IconButton(
//                   //     icon: const Icon(Icons.add),
//                   //     onPressed: () {
//                   //       context.read<VideoBloc>().add(
//                   //         PickVideos(() async {}),
//                   //       );
//                   //     },
//                   //   );
//                   // }),
//                   SizedBox(width: 12),
//                   GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         _isGridView = !_isGridView;
//                       });
//                     },
//                     child: AppImage(
//                       src: _isGridView ? AppSvg.listIcon : AppSvg.gridIcon,
//                       color: colors.blackColor,
//                     ),
//                   ),
//                   SizedBox(width: 15),
//                 ],
//               ),
//               body: SafeArea(
//                 child: Stack(
//                   children: [
//                     Column(
//                       children: [
//                         AdHelper.adaptiveBannerWidget(context),
//                         Expanded(child: _buildVideoPage()),
//                       ],
//                     ),
//                     SmartMiniPlayer(forceMiniMode: true),
//                     // Aa widget potani rite handle karshe
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       );
//     }
//
//
//     else
//       return Stack(
//         children: [
//           Column(
//             children: [
//               CommonAppBar(
//                 title: "videMusicPlayer",
//                 subTitle: "mediaPlayer",
//                 actionWidget: Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8),
//                     color: colors.textFieldFill,
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(8),
//                     child: GestureDetector(
//                       onTap: () => setState(() => _isGridView = !_isGridView),
//                       child: AppImage(
//                         src: _isGridView ? AppSvg.listIcon : AppSvg.gridIcon,
//                         color: colors.blackColor,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               Divider(color: colors.dividerColor),
//
//               AdHelper.adaptiveBannerWidget(context),
//
//               Expanded(child: _buildVideoPage()),
//               // Audio chaltu hoy to niche space khali karva mate:
//             ],
//           ),
//           SmartMiniPlayer(forceMiniMode: true),
//         ],
//       );
//   }
//
//   List<String> _getAlphabetList(List<dynamic> entities) {
//     Set<String> letters = {};
//     for (var entity in entities) {
//       String name = "";
//       if (entity is AssetEntity) {
//         name = entity.title ?? "";
//       } else if (entity is MediaItem) {
//         name = entity.path.split('/').last;
//       }
//
//       if (name.isNotEmpty) {
//         // àªªàª¹à«‡àª²à«‹ àª…àª•à«àª·àª° àª®à«‡àª³àªµà«‹ àª…àª¨à«‡ UpperCase àª•àª°à«‹
//         String firstChar = name[0].toUpperCase();
//         // àªœà«‹ àª…àª•à«àª·àª° A-Z àª®àª¾àª‚ àª¨ àª¹à«‹àª¯ àª¤à«‹ '#' àªµàª¾àªªàª°à«‹
//         if (RegExp(r'^[A-Z]').hasMatch(firstChar)) {
//           letters.add(firstChar);
//         } else {
//           letters.add('#');
//         }
//       }
//     }
//     List<String> sortedLetters = letters.toList()..sort();
//     return sortedLetters;
//   }
//
//   void _scrollToLetter(String letter, List<dynamic> entities) {
//     setState(() {
//       _selectedLetter = letter; // àªàª•à«àªŸàª¿àªµ àª²à«‡àªŸàª° àª¸à«‡àªŸ àª•àª°à«‹
//     });
//
//     int targetIndex = -1;
//
//     for (int i = 0; i < entities.length; i++) {
//       String name = "";
//       if (entities[i] is AssetEntity) {
//         name = entities[i].title ?? "";
//       } else {
//         name = entities[i].path.split('/').last;
//       }
//
//       if (name.isNotEmpty && name[0].toUpperCase() == letter) {
//         targetIndex = i;
//         break;
//       }
//     }
//
//     if (targetIndex != -1) {
//       // GridView àª®àª¾àª‚ àªàª• àª°à«‹ àª®àª¾àª‚ 2 àª†àªˆàªŸàª® àª›à«‡, àªàªŸàª²à«‡ àª‡àª¨à«àª¡à«‡àª•à«àª¸àª¨à«‡ 2 àªµàª¡à«‡ àª­àª¾àª—àªµà«‹ àªªàª¡àª¶à«‡
//       // àª…àª‚àª¦àª¾àªœàª¿àª¤ àª¹àª¾àªˆàªŸ àª®à«àªœàª¬ àª¸à«àª•à«àª°à«‹àª² àª²à«‹àªœàª¿àª•:
//       double itemHeight = _isGridView ? 180.0 : 80.0; // àª¤àª®àª¾àª°à«€ àª†àªˆàªŸàª®àª¨à«€ àª…àª‚àª¦àª¾àªœàª¿àª¤ àªŠàª‚àªšàª¾àªˆ
//       double offset = (targetIndex / (_isGridView ? 2 : 1)) * itemHeight;
//
//       _scrollController.animateTo(
//         offset,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     }
//   }
//
//   Widget _buildVideoPage() {
//     final colors = Theme.of(context).extension<AppThemeColors>()!;
//     return BlocBuilder<VideoBloc, VideoState>(
//       buildWhen: (previous, current) =>
//       current is VideoLoaded ||
//           current is VideoLoading ||
//           current is VideoError,
//       builder: (context, state) {
//         if (state is VideoLoading) {
//           return const MediaShimmerLoading();
//         }
//
//         if (state is VideoError) {
//           return Center(child: Text(state.message));
//         }
//
//         if (state is VideoLoaded) {
//           // 1. àª«àª¿àª²à«àªŸàª° àª•àª°à«‡àª²à«àª‚ àª²àª¿àª¸à«àªŸ àª®à«‡àª³àªµà«‹
//           List<dynamic> entitiesToShow = _searchQuery.isEmpty
//               ? List.from(state.entities) // Original list ni copy banao sorted karva mate
//               : state.entities.where((e) {
//             final name = (e is AssetEntity)
//                 ? (e.title ?? '')
//                 : (e as my.MediaItem).path.split('/').last;
//             return name.toLowerCase().contains(_searchQuery.toLowerCase());
//           }).toList();
//
//           // 2. A to Z àª¸à«‹àª°à«àªŸ àª•àª°à«‹ (àª…àª¹à«€àª‚ àª«à«‡àª°àª«àª¾àª° àª›à«‡)
//           entitiesToShow.sort((a, b) {
//             String nameA = (a is AssetEntity) ? (a.title ?? "") : (a as my.MediaItem).path.split('/').last;
//             String nameB = (b is AssetEntity) ? (b.title ?? "") : (b as my.MediaItem).path.split('/').last;
//
//             // àª•à«‡àª¸ àª¸à«‡àª¨à«àª¸àª¿àªŸàª¿àªµàª¿àªŸà«€ àªµàª—àª° àª¸àª°àª–àª¾àª®àª£à«€ àª•àª°à«‹
//             return nameA.toLowerCase().compareTo(nameB.toLowerCase());
//           });
//
//           if (entitiesToShow.isEmpty && _searchQuery.isNotEmpty) {
//             return const Center(child: AppText("noResultFound"));
//           }
//
//           final alphabetList = _getAlphabetList(entitiesToShow);
//
//           return Stack(
//             children: [
//               // àª¤àª®àª¾àª°à«àª‚ àª®à«‡àªˆàª¨ àª²àª¿àª¸à«àªŸ
//               Positioned.fill(
//                   child: NotificationListener<ScrollNotification>(
//                     onNotification: (ScrollNotification scrollInfo) {
//                       // Ã ÂªÅ“Ã Â«â€¹ Ã ÂªÂ¯Ã Â«ÂÃ ÂªÂÃ ÂªÂ° Ã Âªâ€ºÃ Â«â€¡Ã ÂªÂ²Ã Â«ÂÃ ÂªÂ²Ã Â«â€¡ Ã ÂªÂªÃ ÂªÂ¹Ã Â«â€¹Ã Âªâ€šÃ ÂªÅ¡Ã Â«â€¡ (80% Ã ÂªÂ¸Ã Â«ÂÃ Âªâ€¢Ã Â«ÂÃ ÂªÂ°Ã Â«ÂÃ ÂªÂ°Ã Â«â€¹Ã ÂªÂ² Ã ÂªÂ¥Ã ÂªÂ¾Ã ÂªÂ¯ Ã ÂªÂ¤Ã Â«ÂÃ ÂªÂ¯Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â€¡ Ã ÂªÅ“ Ã ÂªÂ²Ã Â«â€¹Ã ÂªÂ¡ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹)
//                       if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
//                         if (state.hasMore) {
//                           context.read<VideoBloc>().add(LoadMoreVideos());
//                         }
//                       }
//                       return true;
//                     },
//                     child: _isGridView
//                         ? _buildGridView(
//                       entitiesToShow,
//                       state.hasMore,
//                       key: const ValueKey('grid'),
//                     )
//                         : _buildListView(
//                       entitiesToShow,
//                       state.hasMore,
//                       key: const ValueKey('list'),
//                     ),
//                   )
//               ),
//
//               // Alphabet Side Bar (àªœàª®àª£à«€ àª¬àª¾àªœà«)
//               Positioned(
//                 right: 5,
//                 top: 50,
//                 bottom: 250,
//                 child: Container(
//                   width: 15, // àªµàª¿àª¡à«àª¥ àª«àª¿àª•à«àª¸ àª•àª°à«€ àª¦à«‹
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                   decoration: BoxDecoration(
//                     color: colors.dividerColor,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: LayoutBuilder(
//                     builder: (context, constraints) {
//                       return FittedBox(
//                         fit: BoxFit.contain,
//                         alignment: Alignment.center,
//                         child: IntrinsicWidth( // àª† àªµàª¿àªœà«‡àªŸ àª…àª‚àª¦àª°àª¨àª¾ àª¬àª¾àª³àª•à«‹àª¨à«€ àªœàª°à«‚àª°àª¿àª¯àª¾àª¤ àª®à«àªœàª¬ àªµàª¿àª¡à«àª¥ àª¸à«‡àªŸ àª•àª°àª¶à«‡
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             mainAxisSize: MainAxisSize.min, // àª•à«‹àª²àª®àª¨à«‡ àªœà«‡àªŸàª²à«€ àªœàª°à«‚àª° àª¹à«‹àª¯ àªàªŸàª²à«€ àªœ àªœàª—à«àª¯àª¾ àª²à«‡àªµàª¾ àª¦à«‹
//                             children: alphabetList.map((letter) {
//                               bool isActive = _selectedLetter == letter;
//
//                               return Padding(
//                                 padding: const EdgeInsets.all(1),
//                                 child: GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () => _scrollToLetter(letter, entitiesToShow),
//                                   child: Text(
//                                     letter,
//                                     style: TextStyle(
//                                       fontSize:5,
//                                       fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//                                       color: isActive ? colors.primary : colors.blackColor.withOpacity(0.6),
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           );
//
//           return NotificationListener<ScrollNotification>(
//             onNotification: (ScrollNotification scrollInfo) {
//               // Ã ÂªÅ“Ã Â«â€¹ Ã ÂªÂ¯Ã Â«ÂÃ ÂªÂÃ ÂªÂ° Ã Âªâ€ºÃ Â«â€¡Ã ÂªÂ²Ã Â«ÂÃ ÂªÂ²Ã Â«â€¡ Ã ÂªÂªÃ ÂªÂ¹Ã Â«â€¹Ã Âªâ€šÃ ÂªÅ¡Ã Â«â€¡ (80% Ã ÂªÂ¸Ã Â«ÂÃ Âªâ€¢Ã Â«ÂÃ ÂªÂ°Ã Â«ÂÃ ÂªÂ°Ã Â«â€¹Ã ÂªÂ² Ã ÂªÂ¥Ã ÂªÂ¾Ã ÂªÂ¯ Ã ÂªÂ¤Ã Â«ÂÃ ÂªÂ¯Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â€¡ Ã ÂªÅ“ Ã ÂªÂ²Ã Â«â€¹Ã ÂªÂ¡ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹)
//               if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
//                 if (state.hasMore) {
//                   context.read<VideoBloc>().add(LoadMoreVideos());
//                 }
//               }
//               return true;
//             },
//             child: _isGridView
//                 ? _buildGridView(
//               entitiesToShow,
//               state.hasMore,
//               key: const ValueKey('grid'),
//             )
//                 : _buildListView(
//               entitiesToShow,
//               state.hasMore,
//               key: const ValueKey('list'),
//             ),
//           );
//         }
//         return const SizedBox();
//       },
//     );
//   }
//
//   _buildGridView(List<dynamic> entitiesToShow, bool hasMore, {Key? key}) {
//     const int adIndexInterval = 4;
//     int adCount = entitiesToShow.length ~/ adIndexInterval;
//     int totalItems = entitiesToShow.length + adCount;
//
//     int finalItemCount = hasMore ? totalItems + 1 : totalItems;
//
//     return GridView.builder(
//       key: key,
//       controller: _scrollController,
//       padding: const EdgeInsets.all(15),
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 15,
//         childAspectRatio: 1.05,
//       ),
//
//       itemCount: totalItems,
//       // itemCount: hasMore ? entitiesToShow.length + 1 : entitiesToShow.length,
//       itemBuilder: (context, index) {
//         // Ã°Å¸â€™Â¡ Ã ÂªÂ®Ã ÂªÂ¹Ã ÂªÂ¤Ã Â«ÂÃ ÂªÂµÃ ÂªÂ¨Ã Â«â€¹ Ã ÂªÂ¸Ã Â«ÂÃ ÂªÂ§Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â€¹: Ã ÂªÅ“Ã Â«â€¹ Ã Âªâ€  Ã Âªâ€ºÃ Â«â€¡Ã ÂªÂ²Ã Â«ÂÃ ÂªÂ²Ã Â«â€¹ Ã Âªâ€ Ã ÂªË†Ã ÂªÅ¸Ã ÂªÂ® Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ¯ Ã Âªâ€¦Ã ÂªÂ¨Ã Â«â€¡ hasMore Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªÅ¡Ã Â«ÂÃ Âªâ€š Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ¯ Ã ÂªÂ¤Ã Â«â€¹ Ã ÂªÅ“ Ã ÂªÂ²Ã Â«â€¹Ã ÂªÂ¡Ã ÂªÂ° Ã ÂªÂ¬Ã ÂªÂ¤Ã ÂªÂ¾Ã ÂªÂµÃ Â«â€¹
//         if (hasMore && index == finalItemCount - 1) {
//           return const Center(
//             child: Padding(
//               padding: EdgeInsets.all(8.0),
//               child: CustomLoader(), // Ã Âªâ€¦Ã ÂªÂ¥Ã ÂªÂµÃ ÂªÂ¾ CircularProgressIndicator()
//             ),
//           );
//         }
//
//         if (index != 0 && (index + 1) % (adIndexInterval + 1) == 0) {
//           return Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.grey.withOpacity(0.2)),
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Center(
//                 child: FittedBox(
//                   fit: BoxFit.contain,
//                   child: AdHelper.bannerAdWidget(size: AdSize.mediumRectangle),
//                 ),
//               ),
//             ),
//           );
//         }
//
//         final int actualIndex = index - (index ~/ (adIndexInterval + 1));
//
//         if (actualIndex >= entitiesToShow.length) {
//           return const SizedBox.shrink();
//         }
//
//         final entity = entitiesToShow[actualIndex];
//
//         return AppTransition(
//           index: index % 10,
//           columnCount: 2,
//           child: GestureDetector(
//             onTap: () async {
//               if (entity is AssetEntity) {
//                 List<AssetEntity> videoList = entitiesToShow
//                     .whereType<AssetEntity>()
//                     .toList();
//
//                 final entity = entitiesToShow[actualIndex];
//                 _navigateToPlayer(context, videoList, actualIndex, entity);
//               }
//             },
//             child: Padding(
//               padding: const EdgeInsets.all(4.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: entity is AssetEntity
//                         ? ImageItemWidget(
//                       onMenuSelected: (action) async {
//                         switch (action) {
//                           case MediaMenuAction.detail:
//                             routeToDetailPage(context, entity);
//                             break;
//
//                           case MediaMenuAction.info:
//                             showInfoDialog(context, entity);
//                             break;
//
//                           case MediaMenuAction.thumb:
//                             showThumb(entity, 500);
//                             break;
//
//                           case MediaMenuAction.share:
//                             shareItem(context, entity);
//                             break;
//
//                           case MediaMenuAction.delete:
//                             deleteCurrentItem(context, entity);
//                             break;
//
//                           case MediaMenuAction.addToFavourite:
//                             await _toggleFavourite(
//                               context,
//                               entity,
//                               index,
//                             );
//                             break;
//                           case MediaMenuAction.addToPlaylist:
//                             final file = await entity.file;
//                             addToPlaylist(
//                               MediaItem(
//                                 path: file!.path,
//                                 isNetwork: false,
//                                 type: entity.type == AssetType.audio
//                                     ? "audio"
//                                     : "video",
//                                 id: entity.id,
//                                 isFavourite: entity.isFavorite,
//                               ),
//                               context,
//                             );
//                             break;
//                         }
//                       },
//                       onTap: null,
//                       entity: entity,
//                       option: const ThumbnailOption(
//                         size: ThumbnailSize.square(150),
//                       ),
//                     )
//                         : Container(
//                       color: Colors.black12,
//                       child: Center(
//                         child: Text(
//                           (entity as MediaItem).path.split('/').last,
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   _buildListView(List<dynamic> entitiesToShow, bool hasMore, {Key? key}) {
//     const int adIndexInterval = 5; // àª¦àª° 5 àªµà«€àª¡àª¿àª¯à«‹ àªªàª›à«€ àªàª• àªàª¡
//
//     // àªàª¡ àª¸àª¾àª¥à«‡ àª•à«àª² àª•à«‡àªŸàª²à«€ àª†àªˆàªŸàª® àª¥àª¶à«‡ àª¤à«‡àª¨à«€ àª—àª£àª¤àª°à«€
//     int adCount = entitiesToShow.length ~/ adIndexInterval;
//     int totalItems = entitiesToShow.length + adCount;
//
//     // àªœà«‹ àª¹àªœà«€ àª¡à«‡àªŸàª¾ àª¬àª¾àª•à«€ àª¹à«‹àª¯ (hasMore), àª¤à«‹ àª›à«‡àª²à«àª²à«‡ àª²à«‹àª¡àª° àª®àª¾àªŸà«‡ +1
//     int finalItemCount = hasMore ? totalItems + 1 : totalItems;
//
//     return ListView.builder(
//       key: key,
//       controller: _scrollController,
//       padding: const EdgeInsets.all(4),
//       itemCount:
//       (hasMore ? entitiesToShow.length + 1 : entitiesToShow.length) +
//           (entitiesToShow.length ~/ adIndexInterval),
//       itemBuilder: (context, index) {
//         // 1. àª²à«‹àª¡àª° (Loading More) àª¬àª¤àª¾àªµàªµàª¾ àª®àª¾àªŸà«‡
//         if (hasMore && index == finalItemCount - 1) {
//           return const Padding(
//             padding: EdgeInsets.symmetric(vertical: 20),
//             child: Center(child: CustomLoader()),
//           );
//         }
//
//         // 2. àªàª¡ (Ads) àª¬àª¤àª¾àªµàªµàª¾ àª®àª¾àªŸà«‡àª¨à«àª‚ àª²à«‹àªœàª¿àª•
//         // (index + 1) % 6 == 0 -> àª¦àª° 6àª à«àª à«€ àªªà«‹àªàª¿àª¶àª¨ àªªàª° àªàª¡ (5 àª¡à«‡àªŸàª¾ + 1 àªàª¡)
//         if (index != 0 && (index + 1) % (adIndexInterval + 1) == 0) {
//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             child: AdHelper.bannerAdWidget(size: AdSize.banner),
//           );
//         }
//
//         // 3. àª¸àª¾àªšà«‹ àªµà«€àª¡àª¿àª¯à«‹ àª‡àª¨à«àª¡à«‡àª•à«àª¸ (actualIndex) àª¶à«‹àª§àªµàª¾ àª®àª¾àªŸà«‡
//         // àª…àª¤à«àª¯àª¾àª° àª¸à«àª§à«€àª®àª¾àª‚ àª•à«‡àªŸàª²à«€ àªàª¡à«àª¸ àª†àªµà«€ àª—àªˆ àª¤à«‡ àª¬àª¾àª¦ àª•àª°à«‹
//         final int actualIndex = index - (index ~/ (adIndexInterval + 1));
//
//         // àª¸à«àª°àª•à«àª·àª¾ àªšà«‡àª•: àªœà«‹ àª‡àª¨à«àª¡à«‡àª•à«àª¸ àª²àª¿àª¸à«àªŸàª¨à«€ àª¬àª¹àª¾àª° àªœàª¤à«‹ àª¹à«‹àª¯
//         if (actualIndex >= entitiesToShow.length) {
//           return const SizedBox.shrink();
//         }
//
//         final entity = entitiesToShow[actualIndex];
//
//         return AppTransition(
//           index: actualIndex % 10,
//           child: ImageItemWidget(
//             onMenuSelected: (action) async {
//               switch (action) {
//                 case MediaMenuAction.detail:
//                   routeToDetailPage(context, entity);
//                   break;
//
//                 case MediaMenuAction.info:
//                   showInfoDialog(context, entity);
//                   break;
//
//                 case MediaMenuAction.thumb:
//                   showThumb(entity, 500);
//                   break;
//
//                 case MediaMenuAction.share:
//                   shareItem(context, entity);
//                   break;
//
//                 case MediaMenuAction.delete:
//                   deleteCurrentItem(context, entity);
//                   break;
//
//                 case MediaMenuAction.addToFavourite:
//                   await _toggleFavourite(context, entity, index);
//                   break;
//                 case MediaMenuAction.addToPlaylist:
//                   final file = await entity.file;
//                   addToPlaylist(
//                     MediaItem(
//                       path: file!.path,
//                       isNetwork: false,
//                       type: entity.type == AssetType.audio ? "audio" : "video",
//                       id: entity.id,
//                       isFavourite: entity.isFavorite,
//                     ),
//                     context,
//                   );
//                   break;
//               }
//             },
//             onTap: () async {
//               print("vudio====${entity.typeInt}");
//               // final file = await entity.file;
//               // if (file == null || !file.existsSync()) return;
//               _navigateToPlayer(
//                 context,
//                 entitiesToShow.cast<AssetEntity>(),
//                 index,
//                 entity,
//               );
//             },
//             isGrid: _isGridView,
//             entity: entity,
//             option: const ThumbnailOption(size: ThumbnailSize.square(150)),
//           ),
//         );
//       },
//     );
//   }
//
//   Future<void> showThumb(AssetEntity entity, int size) async {
//     final String title;
//     if (entity.title?.isEmpty != false) {
//       title = await entity.titleAsync;
//     } else {
//       title = entity.title!;
//     }
//     print('entity.title = $title');
//     return showDialog(
//       context: context,
//       builder: (_) {
//         return FutureBuilder<Uint8List?>(
//           future: entity.thumbnailDataWithOption(
//             ThumbnailOption.ios(
//               size: const ThumbnailSize.square(150),
//               // resizeContentMode: ResizeContentMode.fill,
//             ),
//           ),
//           builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
//             Widget w;
//             if (snapshot.hasError) {
//               return ErrorWidget(snapshot.error!);
//             } else if (snapshot.hasData) {
//               final Uint8List data = snapshot.data!;
//               ui.decodeImageFromList(data, (ui.Image result) {
//                 print('result size: ${result.width}x${result.height}');
//                 // for 4288x2848
//               });
//               w = Image.memory(data);
//             } else {
//               w = Center(
//                 child: Container(
//                   color: Colors.white,
//                   padding: const EdgeInsets.all(20),
//                   child: const CustomLoader(),
//                 ),
//               );
//             }
//             return GestureDetector(
//               child: w,
//               onTap: () => Navigator.pop(context),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Future<void> _toggleFavourite(
//       BuildContext context,
//       AssetEntity entity,
//       int index,
//       ) async {
//     final favBox = Hive.box('favourites');
//     final bool isFavorite = entity.isFavorite;
//
//     final file = await entity.file;
//     if (file == null) return;
//
//     final key = file.path;
//
//     if (isFavorite) {
//       favBox.delete(key);
//       AppToast.show(
//         context,
//         context.tr("removedFromFavourites"),
//         type: ToastType.info,
//       );
//     } else {
//       favBox.put(key, {
//         "id": entity.id,
//         "path": file.path,
//         "isNetwork": false,
//         "isFavourite": isFavorite,
//         "type": entity.type == AssetType.audio ? "audio" : "video",
//       });
//       AppToast.show(
//         context,
//         context.tr("addedToFavourite"),
//         type: ToastType.success,
//       );
//     }
//
//     if (PlatformUtils.isOhos) {
//       await PhotoManager.editor.ohos.favoriteAsset(
//         entity: entity,
//         favorite: !isFavorite,
//       );
//     } else if (Platform.isAndroid) {
//       await PhotoManager.editor.android.favoriteAsset(
//         entity: entity,
//         favorite: !isFavorite,
//       );
//     } else {
//       await PhotoManager.editor.darwin.favoriteAsset(
//         entity: entity,
//         favorite: !isFavorite,
//       );
//     }
//
//     final AssetEntity? newEntity = await entity.obtainForNewProperties();
//     if (!mounted || newEntity == null) return;
//
//     context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
//
//     setState(() {});
//   }
//
//   void _navigateToPlayer(
//       BuildContext context,
//       List<dynamic> allEntities,
//       int currentIndex,
//       dynamic currentItem,
//       ) async {
//     void moveNext() async {
//       bool isAudio = false;
//       if (currentItem is AssetEntity) {
//         isAudio = currentItem.type == AssetType.audio;
//       } else if (currentItem is my.MediaItem) {
//         isAudio = currentItem.type == 'audio';
//       }
//
//       if (isAudio) {
//         // --- AUDIO PLAYER MATE ---
//         final audioPlayer = GlobalPlayer();
//
//         List<AssetEntity> entities = allEntities
//             .whereType<AssetEntity>()
//             .toList();
//
//         await audioPlayer.initAndPlay(
//           entities: entities,
//           selectedId: (currentItem is AssetEntity)
//               ? currentItem.id
//               : currentItem.id,
//         );
//       } else {
//         // --- VIDEO PLAYER MATE ---
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => PlayerScreen(
//               entityList: allEntities.cast<AssetEntity>(),
//               entity: currentItem as AssetEntity,
//               index: currentIndex,
//             ),
//           ),
//         );
//       }
//     }
//
//     _videoClickCount++;
//     if (_videoClickCount % 3 == 0) {
//       AdHelper.showInterstitialAd(() => moveNext());
//     } else {
//       moveNext();
//     }
//   }
// }