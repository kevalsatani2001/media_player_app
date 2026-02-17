import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:media_player/screens/mini_player.dart';
import 'package:media_player/screens/search_screen.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
import 'package:share_plus/share_plus.dart';

import '../blocs/audio/audio_bloc.dart';
import '../core/constants.dart';
import '../models/media_item.dart';
import '../services/global_player.dart';
import '../utils/app_colors.dart';
import '../widgets/add_to_playlist.dart';
import '../widgets/app_bar.dart';
import '../widgets/image_item_widget.dart';
import '../widgets/image_widget.dart';
import 'bottom_bar_screen.dart';
import 'home_screen.dart';
// import 'mini_player.dart';
import 'player_screen.dart';

class AudioScreen extends StatefulWidget {
  bool isComeHomeScreen;

  AudioScreen({super.key, this.isComeHomeScreen = true});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final ScrollController _scrollController = ScrollController();

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
          title: const Text("Audios"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  context.read<AudioBloc>().add(LoadAudios()),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _AudioBody()),
            Align(
                alignment: Alignment.bottomCenter,
                child: SmartMiniPlayer()
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.read<AudioBloc>().add(LoadAudios()),
          child: const Icon(Icons.refresh),
        ),
      )
          : Column(
        children: [
          CommonAppBar(
            title: "Video & Music Player",
            subTitle: "MEDIA PLAYER",
            actionWidget: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
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
          Divider(color: colors.dividerColor),
          Expanded(child: _AudioBody()),
          SmartMiniPlayer()
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

class _AudioBodyState extends State<_AudioBody> {
  final ScrollController _scrollController = ScrollController();

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
    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {
        if (state is AudioLoading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (state is AudioError) {
          return Center(child: Text(state.message));
        }

        if (state is AudioLoaded) {
          if (state.entities.isEmpty) {
            return const Center(child: Text("No audio files found"));
          }

          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: 15),
            itemCount: state.entities.length,
            itemBuilder: (context, index) {
              final audio = state.entities[index];
              final colors = Theme.of(context).extension<AppThemeColors>()!;
              return FutureBuilder<File?>(
                future: audio.file,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const ListTile(
                      leading: Icon(Icons.music_note),
                      title: Text("Loading..."),
                    );
                  }

                  final file = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7.5),
                    child: GestureDetector(
                      onTap: () {
                        print("audio====${audio.typeInt}");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(
                              entityList: state.entities,
                              entity: audio,
                              item: MediaItem(
                                id: audio.id,
                                path: file.path,
                                isNetwork: false,
                                type: 'audio',
                              ),
                            ),
                          ),
                        ).then((value) {
                          context.read<AudioBloc>().add(
                            LoadAudios(showLoading: false),
                          );
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colors.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            /// 🎵 Icon + Play overlay
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: colors.blackColor.withOpacity(0.38),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AppImage(
                                    src: AppSvg.musicUnselected,
                                    height: 22,
                                  ),
                                  AppImage(
                                    src: GlobalPlayer().currentPath == file.path
                                        ? AppSvg.playerPause
                                        : AppSvg.playerResume,
                                    height: 18,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            /// 🎶 Title + Duration
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppText(
                                    file.path.split('/').last,
                                    maxLines: 1,
                                    // overflow: TextOverflow.ellipsis,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  const SizedBox(height: 6),
                                  AppText(
                                    formatDuration(audio.duration),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textFieldBorder,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 6),

                            /// ⋮ Menu
                            PopupMenuButton<MediaMenuAction>(
                              padding: EdgeInsets.zero,
                              icon: AppImage(src: AppSvg.dropDownMenuDot),
                              onSelected: (action) async {
                                switch (action) {
                                  case MediaMenuAction.detail:
                                    routeToDetailPage(context, audio);
                                    break;
                                  case MediaMenuAction.info:
                                    showInfoDialog(context, audio);
                                    break;
                                  case MediaMenuAction.thumb:
                                    showThumb(context, audio, 500);
                                    break;
                                  case MediaMenuAction.share:
                                    _shareItem(context, audio);
                                    break;
                                  case MediaMenuAction.delete:
                                    _deleteCurrent(context, audio);
                                    break;
                                  case MediaMenuAction.addToFavourite:
                                    await _toggleFavourite(
                                      context,
                                      audio,
                                      index,
                                    );
                                    break;
                                  case MediaMenuAction.addToPlaylist:
                                    final file = await audio.file;
                                    addToPlaylist(
                                      MediaItem(
                                        path: file!.path,
                                        isNetwork: false,
                                        type: audio.type==AssetType.audio?"audio":"video",
                                        id: audio.id,
                                        isFavourite: audio.isFavorite,
                                      ),
                                      context,
                                    );
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: MediaMenuAction.detail,
                                  child: Text('Show detail page'),
                                ),
                                const PopupMenuItem(
                                  value: MediaMenuAction.info,
                                  child: Text('Show info dialog'),
                                ),
                                if (audio.type == AssetType.video)
                                  const PopupMenuItem(
                                    value: MediaMenuAction.thumb,
                                    child: Text('Show 500 size thumb'),
                                  ),
                                const PopupMenuItem(
                                  value: MediaMenuAction.share,
                                  child: Text('Share'),
                                ),
                                PopupMenuItem(
                                  value: MediaMenuAction.addToFavourite,
                                  child: Text(
                                    audio.isFavorite
                                        ? 'Remove from Favourite'
                                        : 'Add to Favourite',
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: MediaMenuAction.delete,
                                  child: Text('Delete'),
                                ),
                                const PopupMenuItem(
                                  value: MediaMenuAction.addToPlaylist,
                                  child: Text('Add to playlist'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  Future<void> routeToDetailPage(
      BuildContext context,
      AssetEntity entity,
      ) async {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => DetailPage(entity: entity)),
    );
  }

  Future<void> showThumb(
      BuildContext context,
      AssetEntity entity,
      int size,
      ) async {
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
    context.read<AudioBloc>().add(LoadAudios(showLoading: false));

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
      context.read<AudioBloc>().add(LoadAudios(showLoading: false));
    }
  }
}
