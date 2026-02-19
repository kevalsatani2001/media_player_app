import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:media_player/screens/setting_screen.dart';
import 'package:media_player/services/hive_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../blocs/favourite_change/favourite_change_bloc.dart';
import '../blocs/video/video_bloc.dart';
import '../blocs/video/video_event.dart';
import '../blocs/video/video_state.dart';
import '../core/constants.dart';
import '../models/media_item.dart';
import '../utils/app_colors.dart';
import '../widgets/add_to_playlist.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/image_item_widget.dart';
import '../widgets/image_widget.dart';
import '../widgets/text_widget.dart';
import 'bottom_bar_screen.dart';
import 'detail_screen.dart';
import 'home_screen.dart';
// import 'mini_player.dart';
import 'mini_player.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }


  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) { // થોડું વહેલું લોડ કરો જેથી યુઝરને વેટ ન કરવો પડે
      final state = context.read<VideoBloc>().state;
      if (state is VideoLoaded && state.hasMore) {
        // અહીં વારંવાર કોલ ન થાય તે માટે Bloc જ હેન્ડલ કરશે
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

    return widget.isComeHomeScreen?Scaffold(
      appBar:AppBar(
        title: !_isSearching
            ? const AppText('videos')
            : TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: context.tr("searchVideos"),
            hintStyle: const TextStyle(color: Colors.white54),
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
      body:Column(
        children: [
          Expanded(child:  _buildVideoPage()),
          Align(
              alignment: Alignment.bottomCenter,
              child: SmartMiniPlayer()
          ),
        ],
      ),


    ):Column(
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
                  onTap: (){
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  child: AppImage(src: _isGridView ?AppSvg.listIcon:AppSvg.gridIcon)),
            ),
          ),),
        Expanded(child: _buildVideoPage()),
        Align(
            alignment: Alignment.bottomCenter,
            child: SmartMiniPlayer()
        ),
      ],
    );



  }
  Widget _buildVideoPage() {
    return BlocBuilder<VideoBloc, VideoState>(
      buildWhen: (previous, current) => current is VideoLoaded || current is VideoLoading || current is VideoError,
      builder: (context, state) {
        if (state is VideoLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.red,));
        }
        if (state is VideoError) {
          return Center(child: Text(state.message));
        }

        if (state is VideoLoaded) {
          // ફિલ્ટર કરેલું લિસ્ટ
          final entitiesToShow = _searchQuery.isEmpty
              ? state.entities
              : state.entities.where((e) {
            final name = (e is AssetEntity) ? (e.title ?? '') : (e as MediaItem).path.split('/').last;
            return name.toLowerCase().contains(_searchQuery);
          }).toList();

          if (entitiesToShow.isEmpty && _searchQuery.isNotEmpty) {
            return const Center(child: AppText("noResultFound"));
          }

          return _isGridView
              ? _buildGridView(entitiesToShow, state.hasMore)
              : _buildListView(entitiesToShow, state.hasMore);
        }
        return const SizedBox();
      },
    );
  }



  _buildGridView(List<dynamic> entitiesToShow, bool hasMore){
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(15),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 15,
        childAspectRatio: 1.05,
      ),

      itemCount: hasMore
          ? entitiesToShow.length + 1
          : entitiesToShow.length,
      itemBuilder: (context, index) {
        // ✅ FIRST CHECK LOADER
        if (index >= entitiesToShow.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final entity = entitiesToShow[index];
        print("Enti =====> $entity");

        // if (state is VideoLoaded &&
        //     entity is AssetEntity &&
        //     index == state.entities.length - 8 &&
        //     state.hasMore) {
        //   context.read<VideoBloc>().add(LoadMoreVideos());
        // }

        return GestureDetector(
          onTap: () async {
            if (entity is AssetEntity) {
              final file = await entity.file;
              if (file == null || !file.existsSync()) return;
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 300),
                  reverseTransitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return PlayerScreen(
                      item: MediaItem(
                        isFavourite: entity.isFavorite,
                        id: entity.id,
                        path: file.path,
                        isNetwork: false,
                        type: 'video',
                      ),
                    );
                  },
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    final tween = Tween<Offset>(
                      begin: const Offset(0, -1), // 👈 from TOP
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeOut));

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );


              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (_) => PlayerScreen(
              //       item: MediaItem(
              //         id: entity.id,
              //         path: file.path,
              //         isNetwork: false,
              //         type: 'video',
              //       ),
              //     ),
              //   ),
              // );
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
                        case MediaMenuAction.addToPlaylist:
                          final file = await entity.file;
                          addToPlaylist(
                            MediaItem(
                              path: file!.path,
                              isNetwork: false,
                              type: entity.type==AssetType.audio?"audio":"video",
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
                      final file = await entity.file;
                      if (file == null ||
                          !file.existsSync())
                        return;
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (_) => PlayerScreen(
                      //       entity: entity,
                      //       item: MediaItem(
                      //         id: entity.id,
                      //         path: file.path,
                      //         isNetwork: false,
                      //         type:
                      //         entity.type ==
                      //             AssetType.video
                      //             ? 'video'
                      //             : 'audio',
                      //       ),
                      //     ),
                      //   ),
                      // )

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                              value: context.read<FavouriteChangeBloc>(),
                              child: PlayerScreen(
                                entity: entity,
                                item: MediaItem(
                                  isFavourite: entity.isFavorite,
                                  id: entity.id,
                                  path: file.path,
                                  isNetwork: false,
                                  type:
                                  entity.type ==
                                      AssetType.video
                                      ? 'video'
                                      : 'audio',
                                ),
                              )
                          ),
                        ),
                      )
                          .then((value) {
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
    );
  }

  _buildListView(List<dynamic> entitiesToShow, bool hasMore){
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(4),
      itemCount: hasMore
          ? entitiesToShow.length + 1
          : entitiesToShow.length,
      itemBuilder: (context, index) {
// ✅ FIRST CHECK LOADER
        if (index >= entitiesToShow.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
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
              case MediaMenuAction.addToPlaylist:
                final file = await entity.file;
                addToPlaylist(
                  MediaItem(
                    path: file!.path,
                    isNetwork: false,
                    type: entity.type==AssetType.audio?"audio":"video",
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
  }
  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} ${context.tr("mb")}';
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
}
