import 'dart:ui' as ui;

import '../services/ads_service.dart';
import '../utils/app_imports.dart';

class GalleryContentListPage extends StatefulWidget {
  const GalleryContentListPage({super.key, required this.path});

  final AssetPathEntity path;

  @override
  State<GalleryContentListPage> createState() => _GalleryContentListPageState();
}

class _GalleryContentListPageState extends State<GalleryContentListPage> {
  AssetPathEntity get path => widget.path;

  AssetPathProvider readPathProvider(BuildContext context) =>
      context.read<AssetPathProvider>();

  AssetPathProvider watchPathProvider(BuildContext c) =>
      c.watch<AssetPathProvider>();

  @override
  void initState() {
    super.initState();
    path.getAssetListRange(start: 0, end: 1).then((List<AssetEntity> value) {
      if (value.isEmpty) {
        return;
      }
      if (mounted) {
        return;
      }
      PhotoCachingManager().requestCacheAssets(
        assets: value,
        option: thumbOption,
      );
    });
  }

  @override
  void dispose() {
    PhotoCachingManager().cancelCacheRequest();
    super.dispose();
  }

  ThumbnailOption get thumbOption => ThumbnailOption(
    size: const ThumbnailSize.square(150),
    format: thumbFormat,
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return ChangeNotifierProvider<AssetPathProvider>(
      create: (_) => AssetPathProvider(widget.path),
      builder: (BuildContext context, _) => Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20),
            ),
          ),
          centerTitle: true,
          title: AppText(path.name, fontSize: 20, fontWeight: FontWeight.w500),
        ),
        body: Column(
          children: [
            Expanded(
              child: buildRefreshIndicator(context), // àª—à«àª°à«€àª¡ àª…àª¹à«€àª‚ àª†àªµàª¶à«‡
            ),
            // âœ¨ Bottom Sticky Ad
            AdHelper.bannerAdWidget(size: AdSize.banner),
          ],
        ),
      ),
    );
  }

  Widget buildRefreshIndicator(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Consumer<AssetPathProvider>(
          builder: (BuildContext c, AssetPathProvider p, _) {
            const int adInterval = 5;
            int listLength = p.showItemCount;

             int adCount = listLength ~/ adInterval;
            if (listLength > 0 && listLength < adInterval) {
              adCount = 1;
            }

            return CustomScrollView(
              slivers: <Widget>[
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      bool isAdPosition = (index != 0 && (index + 1) % (adInterval + 1) == 0);
                      bool isLastAdForSmallList = (listLength < adInterval && index == listLength);

                      if (isAdPosition || isLastAdForSmallList) {
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

                      final int actualIndex = index - (index ~/ (adInterval + 1));
                      if (actualIndex >= listLength) return const SizedBox.shrink();

                      return _buildItem(context, actualIndex);
                    },
                    childCount: listLength + adCount,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.05,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final List<AssetEntity> list = watchPathProvider(context).list;
    if (list.length == index) {
      onLoadMore(context);
      return loadWidget;
    }

    if (index > list.length) {
      return const SizedBox.shrink();
    }

    AssetEntity entity = list[index];
    return ImageItemWidget(
      key: ValueKey<int>(entity.hashCode),
      entity: entity,
      option: thumbOption,
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
            _shareItem(context, entity);
            break;

          case MediaMenuAction.delete:
            _deleteCurrent(context, entity);
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
        final file = await entity.file;
     if (file == null || !file.existsSync()) return;

        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => PlayerScreen(
        //       entity: entity, entityList: [], index: null,
        //       // item: MediaItem(
        //       //   path: file.path,
        //       //   isNetwork: false,
        //       //   type: 'video',
        //       //   id: entity.id,
        //       //   isFavourite: entity.isFavorite,
        //       // ),
        //     ),
        //   ),
        // );
      },
    );
  }

  Widget _buildItemWithAd(BuildContext context, int index, int adInterval, int listLength) {
    bool isAdPosition = (index != 0 && (index + 1) % (adInterval + 1) == 0);
    bool isLastAdForSmallList = (listLength < adInterval && index == listLength);

    if (isAdPosition || isLastAdForSmallList) {
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

    final int actualIndex = index - (index ~/ (adInterval + 1));

    if (actualIndex >= listLength) return const SizedBox.shrink();

    return _buildItem(context, actualIndex);
  }

  int findChildIndexBuilder({
    required String id,
    required List<AssetEntity> assets,
  }) {
    return assets.indexWhere((AssetEntity e) => e.id == id);
  }

  Future<void> getFile(AssetEntity entity) async {
    final file = await entity.file;
    print(file);
  }

  Future<void> getFileWithMP4(AssetEntity entity) async {
    final file = await entity.loadFile(
      isOrigin: false,
      withSubtype: true,
      darwinFileType: PMDarwinAVFileType.mp4,
    );
    print(file);
  }

  Future<void> getDurationOfLivePhoto(AssetEntity entity) async {
    final duration = await entity.durationWithOptions(withSubtype: true);
    print(duration);
  }

  Future<void> routeToDetailPage(AssetEntity entity) async {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => DetailPage(entity: entity)),
    );
  }

  Future<void> onLoadMore(BuildContext context) async {
    if (!mounted) {
      return;
    }
    await readPathProvider(context).onLoadMore();
  }

  Future<void> _onRefresh(BuildContext context) async {
    if (!mounted) {
      return;
    }
    await readPathProvider(context).onRefresh();
  }

  Future<void> _shareItem(BuildContext context, AssetEntity entity) async {
    final file = await entity.file;
    await Share.shareXFiles([XFile(file!.path)], text: entity.title);
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
    } else {
      favBox.put(key, {
        "path": file.path,
        "isNetwork": false,
        "type": entity.type == AssetType.audio ? "audio" : "video",
      });
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

    readPathProvider(context).list[index] = newEntity;
    setState(() {});
  }

  Future<void> _deleteCurrent(BuildContext context, AssetEntity entity) async {
    if (Platform.isAndroid) {
      final AlertDialog dialog = AlertDialog(
        title: const AppText('deleteTheAsset'),
        actions: <Widget>[
          TextButton(
            child: const AppText('delete', color: Colors.red),
            onPressed: () async {
              readPathProvider(context).delete(entity);
              await _onRefresh(context);
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const AppText('cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
      showDialog<void>(context: context, builder: (_) => dialog);
    } else {
      readPathProvider(context).delete(entity);
    }
  }

  Future<void> showOriginBytes(AssetEntity entity) async {
    final String title;
    if (entity.title?.isEmpty != false) {
      title = await entity.titleAsync;
    } else {
      title = entity.title!;
    }
    print('entity.title = $title');
    showDialog<void>(
      context: context,
      builder: (_) {
        return FutureBuilder<Uint8List?>(
          future: entity.originBytes,
          builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
            Widget w;
            if (snapshot.hasError) {
              return ErrorWidget(snapshot.error!);
            } else if (snapshot.hasData) {
              w = Image.memory(snapshot.data!);
            } else {
              w = Center(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: CustomLoader(),
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

  // Future<void> copyToAnotherPath(AssetEntity entity) {
  //   return Navigator.push(
  //     context,
  //     MaterialPageRoute<void>(
  //       builder: (_) => CopyToAnotherGalleryPage(assetEntity: entity),
  //     ),
  //   );
  // }
  //
  // Widget _buildRemoveInAlbumWidget(AssetEntity entity) {
  //   if (!(Platform.isIOS || Platform.isMacOS)) {
  //     return Container();
  //   }
  //
  //   return ElevatedButton(
  //     child: const Text('Remove in album'),
  //     onPressed: () => deleteAssetInAlbum(entity),
  //   );
  // }

  // void deleteAssetInAlbum(AssetEntity entity) {
  //   readPathProvider(context).removeInAlbum(entity);
  // }
  //
  // Widget _buildMoveAnotherPath(AssetEntity entity) {
  //   if (!Platform.isAndroid) {
  //     return Container();
  //   }
  //   return ElevatedButton(
  //     onPressed: () =>
  //         Navigator.push<void>(
  //           context,
  //           MaterialPageRoute<void>(
  //             builder: (_) => MoveToAnotherExample(entity: entity),
  //           ),
  //         ),
  //     child: const Text('Move to another gallery.'),
  //   );
  // }

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
                  child: const CircularProgressIndicator(),
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

// Future<void> testProgressHandler(AssetEntity entity) async {
//   final PMProgressHandler progressHandler = PMProgressHandler();
//   progressHandler.stream.listen((PMProgressState event) {
//     final double progress = event.progress;
//     print('progress state onChange: ${event.state}, progress: $progress');
//   });
//   // final file = await entity.loadFile(progressHandler: progressHandler);
//   // print('file = $file');
//
//   // final thumb = await entity.thumbDataWithSize(
//   //   300,
//   //   300,
//   //   progressHandler: progressHandler,
//   // );
//
//   // print('thumb length = ${thumb.length}');
//
//   final File? file = await entity.loadFile(
//     progressHandler: progressHandler,
//   );
//   print('file = $file');
// }
//
// Future<void> testThumbSize(AssetEntity entity, List<int> list) async {
//   for (final int size in list) {
//     // final data = await entity.thumbDataWithOption(ThumbOption.ios(
//     //   width: size,
//     //   height: size,
//     //   resizeMode: ResizeMode.exact,
//     // ));
//     final Uint8List? data = await entity.thumbnailDataWithSize(
//       ThumbnailSize.square(size),
//     );
//
//     if (data == null) {
//       return;
//     }
//     ui.decodeImageFromList(data, (ui.Image result) {
//       print(
//         'size: $size, '
//             'length: ${data.length}, '
//             'width*height: ${result.width}x${result.height}',
//       );
//     });
//   }
// }
//
// Future<void> showLivePhotoInfo(AssetEntity entity) async {
//   final fileWithSubtype = await entity.originFile;
//   final originFileWithSubtype = await entity.originFileWithSubtype;
//
//   print('fileWithSubtype = $fileWithSubtype');
//   print('originFileWithSubtype = $originFileWithSubtype');
// }
}