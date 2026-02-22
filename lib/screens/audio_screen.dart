import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive/hive.dart';
import 'package:media_player/screens/mini_player.dart';
import 'package:media_player/screens/search_screen.dart';
import 'package:media_player/screens/setting_screen.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
import 'package:share_plus/share_plus.dart';

import '../blocs/audio/audio_bloc.dart';
import '../core/constants.dart';
import '../models/media_item.dart';
import '../models/media_item.dart' as my;
import '../services/global_player.dart';
import '../utils/app_colors.dart';
import '../widgets/add_to_playlist.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_transition.dart';
import '../widgets/common_methods.dart';
import '../widgets/custom_loader.dart';
import '../widgets/image_item_widget.dart';
import '../widgets/image_widget.dart';
import 'bottom_bar_screen.dart';
import 'detail_screen.dart';
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
          title: AppText(
            "audio",
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
                  ),
                ),
              ),
            ),
            SizedBox(width: 15),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _AudioBody()),
            Align(
              alignment: Alignment.bottomCenter,
              child: SmartMiniPlayer(),
            ),
          ],
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () => context.read<AudioBloc>().add(LoadAudios()),
        //   child: const Icon(Icons.refresh),
        // ),
      )
          : Column(
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
          SmartMiniPlayer(),
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
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {
        if (state is AudioLoading) {
          return Center(child: CustomLoader());
        }

        if (state is AudioError) {
          return Center(child: Text(state.message));
        }

        if (state is AudioLoaded) {
          if (state.entities.isEmpty) {
            return const Center(child: AppText("noAudioFileFound"));
          }

          return AnimationLimiter(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 15),
              itemCount: state.entities.length,
              itemBuilder: (context, index) {
                final audio = state.entities[index];
                final colors = Theme.of(context).extension<AppThemeColors>()!;
                return AppTransition(
                  index: index,
                  child: FutureBuilder<File?>(
                    future: audio.file,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const ListTile(
                          leading: Icon(Icons.music_note),
                          title: AppText("loading"),
                        );
                      }

                      final file = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7.5),
                        child: GestureDetector(
                          onTap: () {
                            print("audio====${audio.typeInt}");
                            // ૧. આખા લિસ્ટને MediaItem માં કન્વર્ટ કરો
                            List<MediaItem> audioList = state.entities.map((e) => MediaItem(
                              path: file.path, // ખાતરી કરો કે 'path' સાચો છે
                              type: 'audio',
                              id: e.id,
                              isFavourite: e.isFavorite, isNetwork: e.isFavorite,
                            )).toList();

                            // ૨. પ્લેયરની ક્યુ સેટ કરો (આનાથી જૂનો ડેટા નીકળી જશે)
                            GlobalPlayer().setQueue(audioList, index);

                            // ૩. હવે પ્લે ફંક્શન કોલ કરો
                            GlobalPlayer().play(
                              audio.relativePath!,
                              type: 'audio',
                              isFavourite: audio.isFavorite,
                              id: audio.id,
                              fromPlaylist: true,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlayerScreen(
                                  entityList: state.entities,
                                  entity: audio,
                                  item: MediaItem(
                                    isFavourite: audio.isFavorite,
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
                                        src:
                                        GlobalPlayer().currentPath ==
                                            file.path
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
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                  elevation: 15,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  shadowColor: Colors.black.withOpacity(0.60),
                                  offset: Offset(0, 0),
                                  // splashRadius: 15,
                                  icon: AppImage(src: AppSvg.dropDownMenuDot),
                                  menuPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
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
                                        shareItem(context, audio);
                                        break;
                                      case MediaMenuAction.delete:
                                        deleteCurrentItem(context, audio);
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
                                            type: audio.type == AssetType.audio
                                                ? "audio"
                                                : "video",
                                            id: audio.id,
                                            isFavourite: audio.isFavorite,
                                          ),
                                          context,
                                        );
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    _buildItem(
                                      MediaMenuAction.addToFavourite,
                                      audio.isFavorite ? 'removeToFavourite' : 'addToFavourite',
                                    ),
                                    const PopupMenuDivider(height: 0.5),
                                    _buildItem(MediaMenuAction.delete, 'delete'),
                                    const PopupMenuDivider(height: 0.5),
                                    _buildItem(MediaMenuAction.share, 'share'),
                                    const PopupMenuDivider(height: 0.5),
                                    _buildItem(MediaMenuAction.detail, 'showDetail'),
                                    const PopupMenuDivider(height: 0.5),
                                    _buildItem(MediaMenuAction.addToPlaylist, 'addToPlaylist'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ), // તમારી ઓડિયો લિસ્ટ આઈટમ
                );
              },
            ),
          );
        }

        return const SizedBox();
      },
    );
  }


  _buildItem(MediaMenuAction action, String title) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return PopupMenuItem(
      value: action,
      child: Center(
        child: AppText(
          title,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.appBarTitleColor,
        ),
      ),
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

    // 🔹 Update Hive
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
}
