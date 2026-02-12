/*import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:media_player/screens/search_screen.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
import 'package:share_plus/share_plus.dart';
import '../blocs/video/video_bloc.dart';
import '../models/media_item.dart';
import '../widgets/image_item_widget.dart';
import 'bottom_bar_screen.dart';
import 'home_screen.dart';
import 'player_screen.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('videos');

    return BlocProvider(
      create: (_) => VideoBloc(box)..add(LoadVideosFromGallery()),
      child: Scaffold(
        appBar: AppBar(
          title: !_isSearching
              ? const Text('Videos')
              : TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Search videos...',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          actions: [
            !_isSearching
                ? IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
            )
                : IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),

            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () =>
                  context.read<VideoBloc>().add(LoadVideosFromGallery()),
              child: const Icon(Icons.developer_board),
            );
          },
        ),
        body: BlocBuilder<VideoBloc, VideoState>(
          builder: (context, state) {
            if (state is VideoLoading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            if (state is VideoError) {
              return Center(child: Text(state.message));
            }

            List<dynamic> entitiesToShow = [];

            if (state is VideoLoaded) {
              entitiesToShow = state.entities;
            } else if (state is HiveVideoUpdated) {
              entitiesToShow = state.videos;
            }

            // Apply search filter if query exists
            if (_searchQuery.isNotEmpty) {
              entitiesToShow = entitiesToShow.where((e) {
                String name;
                if (e is AssetEntity) {
                  name = e.title ?? '';
                } else if (e is MediaItem) {
                  name = e.path.split('/').last;
                } else {
                  name = '';
                }
                return name.toLowerCase().contains(_searchQuery);
              }).toList();
            }

            return _isGridView
                ? GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1.3,
              ),
              itemCount: entitiesToShow.length,
              itemBuilder: (context, index) {
                final entity = entitiesToShow[index];

                if (state is VideoLoaded &&
                    entity is AssetEntity &&
                    index == state.entities.length - 8 &&
                    state.hasMore) {
                  context.read<VideoBloc>().add(LoadMoreVideos());
                }

                return GestureDetector(
                  onTap: () async {
                    if (entity is AssetEntity) {
                      final file = await entity.file;
                      if (file == null || !file.existsSync()) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(
                            item: MediaItem(
                              id: entity.id,
                              path: file.path,
                              isNetwork: false,
                              type: 'video',
                            ),
                          ),
                        ),
                      );
                    } else if (entity is MediaItem) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(item: entity),
                        ),
                      );
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
                                  await _toggleFavourite(
                                    context,
                                    entity,
                                    index,
                                  );
                                  break;
                              }
                            },
                            onTap: () async {
                              print("vudio====${entity.typeInt}");
                              final file = await entity.file;
                              if (file == null ||
                                  !file.existsSync())
                                return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlayerScreen(
                                    entity: entity,
                                    item: MediaItem(
                                      id: entity.id,
                                      path: file.path,
                                      isNetwork: false,
                                      type:
                                      entity.type ==
                                          AssetType.video
                                          ? 'video'
                                          : 'audio',
                                    ),
                                  ),
                                ),
                              ).then((value) {
                                context.read<VideoBloc>().add(
                                  LoadVideosFromGallery(
                                    showLoading: false,
                                  ),
                                );
                              });
                            },
                            entity: entity,
                            option: const ThumbnailOption(
                              size: ThumbnailSize.square(300),
                            ),
                          )
                              : Container(
                            color: Colors.black12,
                            child: Center(
                              child: Text(
                                (entity as MediaItem).path
                                    .split('/')
                                    .last,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
                : ListView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: entitiesToShow.length,
              itemBuilder: (context, index) {
                final entity = entitiesToShow[index];
                return ImageItemWidget(
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
                    }
                  },
                  onTap: () async {
                    print("vudio====${entity.typeInt}");
                    final file = await entity.file;
                    if (file == null || !file.existsSync()) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerScreen(
                          entity: entity,
                          item: MediaItem(
                            id: entity.id,
                            path: file.path,
                            isNetwork: false,
                            type: entity.type == AssetType.video
                                ? 'video'
                                : 'audio',
                          ),
                        ),
                      ),
                    ).then((value) {
                      context.read<VideoBloc>().add(
                        LoadVideosFromGallery(showLoading: false),
                      );
                    });
                  },
                  isGrid: _isGridView,
                  entity: entity,
                  option: const ThumbnailOption(
                    size: ThumbnailSize.square(300),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
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

    // 🔹 Update Hive
    if (isFavorite) {
      favBox.delete(key);
    } else {
      favBox.put(key, {
        "id": entity.id,
        "path": file.path,
        "isNetwork": false,
        "type": entity.type == AssetType.audio ? "audio" : "video",
      });
    }

    // 🔹 Update system favourite
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

    // 🔹 Reload entity
    final AssetEntity? newEntity = await entity.obtainForNewProperties();
    if (!mounted || newEntity == null) return;

    // 🔹 Update UI list
    // readPathProvider(context).list[index] = newEntity;
    context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));

    setState(() {});
  }

  Future<void> _deleteCurrent(BuildContext context, AssetEntity entity) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete media'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // ✅ Correct delete API
    final result = await PhotoManager.editor.deleteWithIds([entity.id]);

    if (result.isNotEmpty) {
      context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
    }
  }
}*/






import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../blocs/video/video_bloc.dart';
import '../blocs/video/video_event.dart';
import '../blocs/video/video_state.dart';
import '../core/constants.dart';
import '../models/media_item.dart';
import '../utils/app_colors.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/image_item_widget.dart';
import '../widgets/image_widget.dart';
import '../widgets/text_widget.dart';
import 'bottom_bar_screen.dart';
import 'home_screen.dart';
import 'player_screen.dart';

class VideoScreen extends StatefulWidget {
  bool isComeHomeScreen;
   VideoScreen({super.key,this.isComeHomeScreen=true});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final box = Hive.box('videos');

    return BlocProvider(
      create: (_) => VideoBloc(box)..add(LoadVideosFromGallery(showLoading: false)),
      child: widget.isComeHomeScreen?Scaffold(
        appBar: AppBar(
          title: !_isSearching
              ? const Text('Videos')
              : TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Search videos...',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          actions: [
            !_isSearching
                ? IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            )
                : IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
            Builder(builder: (context) {
              return IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  context.read<VideoBloc>().add(
                    PickVideos(() async {}),
                  );
                },
              );
            }),
          ],
        ),
        // floatingActionButton: Builder(builder: (context) {
        //   return FloatingActionButton(
        //     onPressed: () => context.read<VideoBloc>().add(LoadVideosFromGallery()),
        //     child: const Icon(Icons.developer_board),
        //   );
        // }),
        body:_buildVideoPage(),
      ):Column(
        children: [
          CommonAppBar(
            title: "Video & Music Player",
            subTitle: "MEDIA PLAYER",
            actionWidget: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: colors.textFieldFill,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                    onTap: (){
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                    child: AppImage(src: _isGridView ?AppSvg.listIcon:AppSvg.gridIcon)),
              ),
            ),),
          Expanded(child: _buildVideoPage())
          /*
                    actions: [
            !_isSearching
                ? IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
            )
                : IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),

            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
          ],
           */
        ],
      ),
    );



  }
  Widget _buildVideoPage(){
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        if (state is VideoLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is VideoError) {
          return Center(child: Text(state.message));
        }

        List<dynamic> entitiesToShow = [];

        if (state is VideoLoaded) {
          entitiesToShow = state.entities;
        } else if (state is HiveVideoUpdated) {
          entitiesToShow = state.videos;
        }

        // Apply search filter if query exists
        if (_searchQuery.isNotEmpty) {
          entitiesToShow = entitiesToShow.where((e) {
            String name;
            if (e is AssetEntity) {
              name = e.title ?? '';
            } else if (e is MediaItem) {
              name = e.path.split('/').last;
            } else {
              name = '';
            }
            return name.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        return _isGridView
            ? GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 15,
            childAspectRatio: 1.05,
          ),
          itemCount: entitiesToShow.length,
          itemBuilder: (context, index) {
            final entity = entitiesToShow[index];

            if (state is VideoLoaded &&
                entity is AssetEntity &&
                index == state.entities.length - 8 &&
                state.hasMore) {
              context.read<VideoBloc>().add(LoadMoreVideos());
            }

            return GestureDetector(
              onTap: () async {
                if (entity is AssetEntity) {
                  final file = await entity.file;
                  if (file == null || !file.existsSync()) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        item: MediaItem(
                          id: entity.id,
                          path: file.path,
                          isNetwork: false,
                          type: 'video',
                        ),
                      ),
                    ),
                  );
                } else if (entity is MediaItem) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(item: entity),
                    ),
                  );
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
                              deleteCurrentItem(context, entity);
                              break;

                            case MediaMenuAction.addToFavourite:
                              await _toggleFavourite(
                                context,
                                entity,
                                index,
                              );
                              break;
                          }
                        },
                        onTap: () async {
                          print("vudio====${entity.typeInt}");
                          final file = await entity.file;
                          if (file == null ||
                              !file.existsSync())
                            return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(
                                entity: entity,
                                item: MediaItem(
                                  id: entity.id,
                                  path: file.path,
                                  isNetwork: false,
                                  type:
                                  entity.type ==
                                      AssetType.video
                                      ? 'video'
                                      : 'audio',
                                ),
                              ),
                            ),
                          ).then((value) {
                            context.read<VideoBloc>().add(
                              LoadVideosFromGallery(
                                showLoading: false,
                              ),
                            );
                          });
                        },
                        entity: entity,
                        option: const ThumbnailOption(
                          size: ThumbnailSize.square(300),
                        ),
                      )
                          : Container(
                        color: Colors.black12,
                        child: Center(
                          child: Text(
                            (entity as MediaItem).path
                                .split('/')
                                .last,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        )
            : ListView.builder(
          padding: const EdgeInsets.all(4),
          itemCount: entitiesToShow.length,
          itemBuilder: (context, index) {
            final entity = entitiesToShow[index];
            return ImageItemWidget(
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
                    deleteCurrentItem(context, entity);
                    break;

                  case MediaMenuAction.addToFavourite:
                    await _toggleFavourite(context, entity, index);
                    break;
                }
              },
              onTap: () async {
                print("vudio====${entity.typeInt}");
                final file = await entity.file;
                if (file == null || !file.existsSync()) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerScreen(
                      entity: entity,
                      item: MediaItem(
                        id: entity.id,
                        path: file.path,
                        isNetwork: false,
                        type: entity.type == AssetType.video
                            ? 'video'
                            : 'audio',
                      ),
                    ),
                  ),
                ).then((value) {
                  context.read<VideoBloc>().add(
                    LoadVideosFromGallery(showLoading: false),
                  );
                });
              },
              isGrid: _isGridView,
              entity: entity,
              option: const ThumbnailOption(
                size: ThumbnailSize.square(300),
              ),
            );
          },
        );

        //   GridView.builder(
        //   padding: const EdgeInsets.all(4),
        //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        //     crossAxisCount: 1,
        //     crossAxisSpacing: 4,
        //     mainAxisSpacing: 4,
        //   ),
        //   itemCount: entitiesToShow.length,
        //   itemBuilder: (context, index) {
        //     final entity = entitiesToShow[index];
        //
        //     if (state is VideoLoaded &&
        //         entity is AssetEntity &&
        //         index == state.entities.length - 8 &&
        //         state.hasMore) {
        //       context.read<VideoBloc>().add(LoadMoreVideos());
        //     }
        //
        //     return
        //     GestureDetector(
        //       onTap: () async {
        //         if (entity is AssetEntity) {
        //           final file = await entity.file;
        //           if (file == null || !file.existsSync()) return;
        //
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (_) => PlayerScreen(
        //                 item: MediaItem(
        //                   id: entity.id,
        //                   path: file.path,
        //                   isNetwork: false,
        //                   type: 'video',
        //                 ),
        //               ),
        //             ),
        //           );
        //         } else if (entity is MediaItem) {
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (_) => PlayerScreen(item: entity),
        //             ),
        //           );
        //         }
        //       },
        //       child: Padding(
        //         padding: const EdgeInsets.all(4.0),
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Expanded(
        //               child: entity is AssetEntity
        //                   ? ImageItemWidget(
        //                 onMenuSelected: (action) async {
        //                   switch (action) {
        //                     case MediaMenuAction.detail:
        //                       routeToDetailPage(entity);
        //                       break;
        //
        //                     case MediaMenuAction.info:
        //                       showInfoDialog(context, entity);
        //                       break;
        //
        //                     case MediaMenuAction.thumb:
        //                       showThumb(entity, 500);
        //                       break;
        //
        //                     case MediaMenuAction.share:
        //                       _shareItem(context, entity);
        //                       break;
        //
        //                     case MediaMenuAction.delete:
        //                       _deleteCurrent(context, entity);
        //                       break;
        //
        //                     case MediaMenuAction.addToFavourite:
        //                       await _toggleFavourite(context, entity, index);
        //                       break;
        //                   }
        //                 },
        //                 onTap: () async {
        //                   print("vudio====${entity.typeInt}");
        //                   final file = await entity.file;
        //                   if (file == null || !file.existsSync()) return;
        //                   Navigator.push(
        //                     context,
        //                     MaterialPageRoute(
        //                       builder: (_) => PlayerScreen(
        //                         entity: entity,
        //                         item: MediaItem(
        //                           id: entity.id,
        //                           path: file.path,
        //                           isNetwork: false,
        //                           type: entity.type == AssetType.video ? 'video' : 'audio',
        //                         ),
        //                       ),
        //                     ),
        //                   ).then((value) {
        //                     context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
        //                   },);
        //                 },
        //                 entity: entity,
        //                 option: const ThumbnailOption(
        //                   size: ThumbnailSize.square(300),
        //                 ),
        //               )
        //                   : Container(
        //                 color: Colors.black12,
        //                 child: Center(
        //                   child: Text(
        //                     (entity as MediaItem)
        //                         .path
        //                         .split('/')
        //                         .last,
        //                     textAlign: TextAlign.center,
        //                   ),
        //                 ),
        //               ),
        //             ),
        //             if (entity is AssetEntity) ...[
        //               Text(
        //                 _formatDuration(entity.duration),
        //                 style: const TextStyle(
        //                   color: Colors.white,
        //                   fontSize: 12,
        //                 ),
        //               ),
        //               FutureBuilder<File?>(
        //                 future: entity.file,
        //                 builder: (context, snapshot) {
        //                   if (!snapshot.hasData || snapshot.data == null) {
        //                     return const SizedBox(height: 14);
        //                   }
        //
        //                   final file = snapshot.data!;
        //
        //                   if (!file.existsSync()) {
        //                     return const Text(
        //                       'Unavailable',
        //                       style: TextStyle(
        //                         color: Colors.redAccent,
        //                         fontSize: 11,
        //                       ),
        //                     );
        //                   }
        //
        //                   final bytes = file.lengthSync();
        //
        //                   return Text(
        //                     _formatSize(bytes),
        //                     style: const TextStyle(
        //                       color: Colors.white70,
        //                       fontSize: 11,
        //                     ),
        //                   );
        //                 },
        //               ),
        //
        //             ],
        //           ],
        //         ),
        //       ),
        //     );
        //   },
        // );
      },
    );
  }
  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
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

    // 🔹 Update Hive
    if (isFavorite) {
      favBox.delete(key);
    } else {
      favBox.put(key, {
        "id":entity.id,
        "path": file.path,
        "isNetwork": false,
        "type": entity.type == AssetType.audio ? "audio" : "video",
      });
    }

    // 🔹 Update system favourite
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

    // 🔹 Reload entity
    final AssetEntity? newEntity = await entity.obtainForNewProperties();
    if (!mounted || newEntity == null) return;

    // 🔹 Update UI list
    // readPathProvider(context).list[index] = newEntity;
    context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));

    setState(() {});
  }

  Future<void> _deleteCurrents(
      BuildContext context,
      AssetEntity entity,
      ) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete media'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // ✅ Correct delete API
    final result = await PhotoManager.editor.deleteWithIds([entity.id]);

    if (result.isNotEmpty) {
      context
          .read<VideoBloc>()
          .add(LoadVideosFromGallery(showLoading: false));
    }
  }
}
