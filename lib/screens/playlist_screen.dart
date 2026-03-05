import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_player/screens/setting_screen.dart';
import 'package:media_player/widgets/search_button.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants.dart';
import '../models/media_item.dart';
import '../models/playlist_model.dart';
import '../services/global_player.dart';
import '../services/playlist_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_imports.dart';
import '../widgets/app_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_transition.dart';
import '../widgets/common_methods.dart';
import '../widgets/image_item_widget.dart';
import '../widgets/image_widget.dart';
import '../widgets/text_widget.dart';
import 'detail_screen.dart';
import 'player_screen.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final box = Hive.box('playlists');

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20,color: colors.blackColor,),
          ),
        ),
        title: AppText("playlist", fontSize: 20, fontWeight: FontWeight.w500),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: SearchButton(),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (_, Box box, __) {
          final List<PlaylistModel> playlists = box.values
              .cast<PlaylistModel>()
              .toList();

          // 2. àª•àª¨à«àª¸à«‹àª²àª®àª¾àª‚ àª¦àª°à«‡àª• àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àª…àª¨à«‡ àª¤à«‡àª¨àª¾ àª†àªˆàªŸàª®à«àª¸ àªªà«àª°àª¿àª¨à«àªŸ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡
          for (var playlist in playlists) {
            print("--- Playlist: ${playlist.name} ---");
            print("--- Playlist: ${playlists} ---");
            print("Total items: ${playlist.items.length}");

            for (var item in playlist.items) {
              print(
                "Item ID: ${item.id}, Path: ${item.path}, Type: ${item.type}--- -------${item.isFavourite}",
              );
            }
          }
          if (playlists.isEmpty) {
            return const Center(child: AppText("noPlaylistsFound"));
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 15),
            itemCount: playlists.length,
            itemBuilder: (_, index) {
              final playlist = playlists[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7.5),
                child: AppTransition(
                  index: index,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistItemsScreen(
                            name: playlist.name,
                            items: playlist.items,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      // height: 100,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          top: 10,
                          bottom: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  // Row àª¨àª¾ Thumbnail àª¸à«‡àª•à«àª¶àª¨àª®àª¾àª‚
                                  Container(
                                      width: 80,
                                      height: 60,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: colors.primary.withOpacity(0.1)
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child:
                                      Icon(Icons.playlist_play, color: colors.primary, size: 30)),
                                  SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          playlist.name,
                                          maxLines: 1,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        SizedBox(height: 7),
                                        AppText(
                                          "${playlist.items.length} ${context.tr("items")}",
                                          maxLines: 1,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                          color: colors.textFieldBorder,
                                        ),
                                        SizedBox(height: 7),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 13),
                                ],
                              ),
                            ),
                            PopupMenuButton<PlaylistMenuAction>(
                              elevation: 15,
                              color: colors.dropdownBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadowColor: Colors.black.withOpacity(0.60),
                              offset: Offset(0, 0),
                              // splashRadius: 15,
                              icon: AppImage(src: AppSvg.dropDownMenuDot,color: colors.blackColor,),
                              menuPadding: EdgeInsets.symmetric(horizontal: 10),
                              onSelected: (action) {
                                switch (action) {
                                  case PlaylistMenuAction.rename:
                                    _showRenameDialog(context, box, index, playlist.name);
                                    break;
                                  case PlaylistMenuAction.delete:
                                    _confirmDelete(context, box, index, playlist.name);
                                    break;
                                  case PlaylistMenuAction.share:
                                    _sharePlaylist(context, playlist);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: PlaylistMenuAction.rename,
                                  child: Center(
                                    child: AppText(
                                      'rename',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: colors.appBarTitleColor,
                                    ),
                                  ),
                                ),
                                const PopupMenuDivider(height: 0.5),
                                PopupMenuItem(
                                  value: PlaylistMenuAction.share,
                                  child: Center(
                                    child: AppText(
                                      'share',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: colors.appBarTitleColor,
                                    ),
                                  ),
                                ),
                                const PopupMenuDivider(height: 0.5),
                                PopupMenuItem(
                                  value: PlaylistMenuAction.delete,
                                  child: Center(
                                    child: AppText(
                                      'delete',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: colors.appBarTitleColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),








                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context,
      Box box,
      int index,
      String oldName,
      ) {
    final controller = TextEditingController(text: oldName);
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        actionsPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(20),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 36),
        contentPadding: EdgeInsets.only(
          left: 33,
          right: 33,
          bottom: 20,
          top: 40,
        ),
        backgroundColor: colors.dropdownBg,
        title: AppText(
          'renamePlaylist',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: colors.appBarTitleColor,
          align: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration:  InputDecoration(
                border: OutlineInputBorder(),
                labelText: context.tr("playlistName"),
              ),
            ),
            SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    title: "cancel",
                    textColor: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                    backgroundColor: colors.primary,
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: AppButton(
                    title: "rename",
                    textColor: colors.dialogueSubTitle,
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                    backgroundColor: colors.whiteColor,
                    onTap: () {
                      final newName = controller.text.trim();
                      if (newName.isEmpty) {
                        AppToast.show(
                          context,
                          context.tr("pleaseEnterName"),
                          type: ToastType.error,
                        );
                        return;
                      }

                      final playlist = box.getAt(index);
                      if (playlist != null) {
                        playlist.name = newName;
                        playlist.save();
                        Navigator.pop(context);
                        // âœ… Success Toast
                        AppToast.show(
                          context,
                          "${context.tr("playlistRenamedTo")} $newName",
                          type: ToastType.success,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Box box, int index, String name) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        actionsPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(20),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 36),
        contentPadding: EdgeInsets.only(
          left: 33,
          right: 33,
          bottom: 20,
          top: 40,
        ),
        backgroundColor: colors.cardBackground,
        title: AppText(
          'deletePlaylist',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: colors.appBarTitleColor,
          align: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              '${context.tr('delete')} \"$name\" ${context.tr("permanently")}',
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: colors.dialogueSubTitle,
              align: TextAlign.center,
            ),
            SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    title: "cancel",
                    textColor: colors.whiteColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                    backgroundColor: colors.primary,
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: AppButton(
                    title: "delete",
                    textColor: colors.dialogueSubTitle,
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                    backgroundColor: colors.whiteColor,
                    onTap: () {
                      box.deleteAt(index);
                      Navigator.pop(context);
                      AppToast.show(
                        context,
                        "${context.tr("playlist")} '$name' ${context.tr("deleted")}",
                        type: ToastType.error,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePlaylist(
      BuildContext context,
      PlaylistModel playlist,
      ) async {
    final List<XFile> files = [];

    for (final item in playlist.items) {
      // àªªàª¹à«‡àª²àª¾ àª¡àª¾àª¯àª°à«‡àª•à«àªŸ àªªàª¾àª¥àª¥à«€ àªšà«‡àª• àª•àª°à«‹
      final file = File(item.path);
      if (item.path.isNotEmpty && file.existsSync()) {
        files.add(XFile(item.path));
      } else {
        // àªœà«‹ àªªàª¾àª¥ àª¨àª¾ àª®àª³à«‡ àª¤à«‹ AssetEntity àª¥à«€ àª«àª¾àªˆàª² àª®à«‡àª³àªµà«‹
        final entity = AssetEntity(
          id: item.id,
          typeInt: item.type == "audio" ? 3 : 2,
          width: 100,
          height: 100,
        );
        final File? assetFile = await entity.file;
        if (assetFile != null && assetFile.existsSync()) {
          files.add(XFile(assetFile.path));
        }
      }
    }

    if (files.isEmpty) {
      AppToast.show(context, "${context.tr("noShareableFilesFound")}", type: ToastType.error);
      return;
    }
    // WhatsApp àª²àª¿àª®àª¿àªŸ àª®àª¾àªŸà«‡ max 10 àª«àª¾àªˆàª²
    final shareableFiles = files.length > 10 ? files.sublist(0, 10) : files;

    await Share.shareXFiles(
      shareableFiles,
      text: "${context.tr("sharingPlaylist")} ${playlist.name}",
    );
  }
}

class PlaylistItemsScreen extends StatefulWidget {
  final String name;
  final List<MediaItem> items;

  const PlaylistItemsScreen({
    super.key,
    required this.name,
    required this.items,
  });

  @override
  State<PlaylistItemsScreen> createState() => _PlaylistItemsScreenState();
}

class _PlaylistItemsScreenState extends State<PlaylistItemsScreen> {
  late List<MediaItem> currentItems;
  bool favState = false; // àª²à«‹àª•àª² àª²àª¿àª¸à«àªŸ

  @override
  void initState() {
    super.initState();
    // àª¶àª°à«‚àª†àª¤àª®àª¾àª‚ àªªà«àª°à«‹àªªà«àª¸àª®àª¾àª‚àª¥à«€ àª†àªµàª¤àª¾ àª†àªˆàªŸàª®à«àª¸ àª•à«‹àªªà«€ àª•àª°à«‹
    currentItems = List.from(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20,color: colors.blackColor,),
          ),
        ),
        title: AppText(widget.name, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      body: widget.items.isEmpty
          ? const Center(child: AppText("playlistEmpty", fontSize: 16))
          : GlobalPlayer().currentType == "video"
          ?Stack(
        children: [
          ListView.builder(
            itemCount: widget.items.length,
            padding: const EdgeInsets.only(top: 10),
            itemBuilder: (_, i) {
              final item = widget.items[i];
              return AppTransition(
                index: i,
                child: _buildMediaCard(context, item, colors, i),
              );
            },
          ),
          const SmartMiniPlayer(),
        ],
      ):
      Column(
        children: [
          Expanded(child: ListView.builder(
            itemCount: widget.items.length,
            padding: const EdgeInsets.only(top: 10),
            itemBuilder: (_, i) {
              final item = widget.items[i];
              return AppTransition(
                index: i,
                child: _buildMediaCard(context, item, colors, i),
              );
            },
          ),),
          const SmartMiniPlayer(),
        ],
      ),

    );
  }

  // àª¸àª°à«àªš àª¸à«àª•à«àª°à«€àª¨ àªœà«‡àªµà«àª‚ àªœ àª•àª¾àª°à«àª¡ àªµàª¿àªœà«‡àªŸ
  Widget _buildMediaCard(
      BuildContext context,
      MediaItem item,
      AppThemeColors colors,
      int index,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.5, horizontal: 15),
      child: GestureDetector(
        onTap: () => _handlePlay(context, item),
        child: Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              // àª† àª®à«àª–à«àª¯ àª°à«‹ àª›à«‡
              children: [
                // à«§. Thumbnail Image (àª«àª¿àª•à«àª¸ àªµàª¿àª¡à«àª¥)
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: assetAntityImage(
                    AssetEntity(
                      id: item.id ?? "",
                      typeInt: item.type == 'audio' ? 3 : 2,
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
                const SizedBox(width: 13),

                // à«¨. Details (Expanded àªœà«‡àª¥à«€ àª¤à«‡ àª¬àª¾àª•à«€àª¨à«€ àªµàª§à«‡àª²à«€ àªœàª—à«àª¯àª¾ àªœ àª°à«‹àª•à«‡)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // àªœàª°à«‚àª°à«€ àª›à«‡
                    children: [
                      AppText(
                        item.path.split('/').last,
                        maxLines: 1,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 5),
                      AppText(
                        item.path,
                        maxLines: 1,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: colors.textFieldBorder,
                      ),
                      const SizedBox(height: 5),
                      // Duration & Size Row
                      Row(
                        children: [
                          _buildDuration(item, colors),
                          const SizedBox(width: 15),
                          _buildFileSize(item, colors,context),
                        ],
                      ),
                    ],
                  ),
                ),

                // à«©. PopupMenuButton (àªªà«‹àª¤àª¾àª¨à«€ àªœàª°à«‚àª° àª®à«àªœàª¬àª¨à«€ àªœàª—à«àª¯àª¾ àª²à«‡àª¶à«‡)
                PopupMenuButton<MediaMenuAction>(
                  elevation: 15,
                  color: colors.dropdownBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  icon: AppImage(src: AppSvg.dropDownMenuDot,color: colors.blackColor),
                  onSelected: (action) async {
                    AssetEntity entity = AssetEntity(
                      id: item.id,
                      typeInt: item.type == "audio" ? 3 : 2,
                      width: 200,
                      height: 200,
                      isFavorite: item.isFavourite,
                      title: item.path,
                    );
                    switch (action) {
                      case MediaMenuAction.detail:
                        routeToDetailPage(context, entity);
                        break;
                      case MediaMenuAction.delete:
                        _removeFromPlaylist(index);
                        break;
                      case MediaMenuAction.addToFavourite:
                        _toggleFavourite(context, entity, index);
                        break;
                      case MediaMenuAction.share:
                        _shareSingleItem(entity);
                        break;
                      default:
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    _buildPopupItem(
                      MediaMenuAction.detail,
                      'showDetail',
                      colors,
                    ),
                    const PopupMenuDivider(height: 0.5),
                    _buildPopupItem(MediaMenuAction.share, 'share', colors),
                    const PopupMenuDivider(height: 0.5),
                    _buildPopupItem(
                      MediaMenuAction.addToFavourite,
                      !item.isFavourite
                          ? 'addToFavourite'
                          : "removeToFavourite",
                      colors,
                    ),
                    const PopupMenuDivider(height: 0.5),
                    _buildPopupItem(
                      MediaMenuAction.delete,
                      'removeFromPlayList',
                      colors,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavourite(
      BuildContext context,
      AssetEntity entity,
      int index,
      ) async {
    final file = await entity.file;
    if (file == null) {
      AppToast.show(context, context.tr("fileNotFoundMsg"), type: ToastType.error);
      return;
    }

    final playlistService = PlaylistService();
    final newFavState = await playlistService.toggleFavourite(entity);

    setState(() {
      currentItems[index].isFavourite = newFavState;
    });

    // âœ… Toast Feedback
    AppToast.show(
      context,
      newFavState ? "${context.tr("addedToFavourite")}" : "${context.tr("removedFromFavourites")}",
      type: newFavState ? ToastType.success : ToastType.info,
    );
  }

  PopupMenuItem<MediaMenuAction> _buildPopupItem(
      MediaMenuAction action,
      String title,
      AppThemeColors colors,
      ) {
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

  void _removeFromPlaylist(int index) {
    final playlistBox = Hive.box('playlists');
    final playlistList = playlistBox.values.toList();
    final int playlistIndex = playlistList.indexWhere(
          (element) => element.name == widget.name,
    );

    if (playlistIndex != -1) {
      final playlist = playlistBox.getAt(playlistIndex);
      playlist.items.removeAt(index);
      playlistBox.putAt(playlistIndex, playlist);

      setState(() {
        currentItems.removeAt(index);
      });

      // âœ… SnackBar àª¨à«€ àªœàª—à«àª¯àª¾àª Toast
      AppToast.show(context, "${context.tr("removedFromPlaylist")}", type: ToastType.info);
    }
  }

  // Duration Helper
  Widget _buildDuration(MediaItem item, AppThemeColors colors) {
    return FutureBuilder<AssetEntity?>(
      future: AssetEntity.fromId(item.id), // ID àªªàª°àª¥à«€ àª†àª–à«€ àªàª¨à«àªŸàª¿àªŸà«€ àª²à«‹àª¡ àª•àª°à«‹
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const AppText("00:00", fontSize: 10);

        final entity = snapshot.data!;
        // àª…àª¹à«€àª‚ àª¡à«àª¯à«àª°à«‡àª¶àª¨ àª¸à«‡àª•àª¨à«àª¡àª®àª¾àª‚ àª®àª³à«‡ àª›à«‡
        return AppText(
          formatDuration(entity.duration),
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colors.appBarTitleColor,
        );
      },
    );
  }

  // File Size Helper
  Widget _buildFileSize(MediaItem item, AppThemeColors colors,BuildContext context) {
    return FutureBuilder<File?>(
      future: AssetEntity(
        id: item.id ?? "",
        typeInt: item.type == 'audio' ? 3 : 2,
        width: 80,
        height: 80,
      ).file,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return const SizedBox();
        final bytes = snapshot.data!.lengthSync();
        final mb = bytes / (1024 * 1024);
        return AppText(formatSize(bytes,context),
          // '${mb.toStringAsFixed(1)} MB',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colors.appBarTitleColor,
        );
      },
    );
  }

  void _handlePlay(BuildContext context, MediaItem item) {
    // à«§. àª†àªˆàªŸàª®àª¨à«‹ àªˆàª¨à«àª¡à«‡àª•à«àª¸ àª¶à«‹àª§à«‹
    int index = widget.items.indexOf(item);
    final player = Provider.of<GlobalPlayer>(context, listen: false);

    // à«¨. MediaItem àª¨àª¾ àª²àª¿àª¸à«àªŸàª¨à«‡ AssetEntity àª¨àª¾ àª²àª¿àª¸à«àªŸàª®àª¾àª‚ àª•àª¨à«àªµàª°à«àªŸ àª•àª°à«‹
    List<AssetEntity> entityList = widget.items.map((media) {
      return AssetEntity(
        id: media.id,
        // type àª®à«àªœàª¬ typeInt àª¸à«‡àªŸ àª•àª°à«‹ (Video: 1, Audio: 2/3, Image: 1)
        // àª¸àª¾àª®àª¾àª¨à«àª¯ àª°à«€àª¤à«‡ photo_manager àª®àª¾àª‚: Image = 1, Video = 2, Audio = 3
        typeInt: media.type == "video" ? 2 : (media.type == "audio" ? 3 : 1),
        width: 0,
        height: 0,
        duration: 0,
        title: media.path.split("/").last,
      );
    }).toList();

    // à«©. àªªà«àª²à«‡àª¯àª°àª¨à«€ àª•à«àª¯à« (Queue) àª…àª¨à«‡ àª‡àª¨à«àª¡à«‡àª•à«àª¸ àª¸à«‡àªŸ àª•àª°à«‹
    // player.queue = entityList;
    player.currentIndex = index;

    print("Playing Item ID: ${item.id}");
    print("Total Items in Queue: ${entityList.length}");

    // à«ª. àª¨à«‡àªµàª¿àª—à«‡àªŸ àª•àª°à«‹
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          item: item,
          index: index,
          entityList: entityList, // àª¤à«ˆàª¯àª¾àª° àª•àª°à«‡àª²à«àª‚ àª²àª¿àª¸à«àªŸ àª…àª¹à«€àª‚ àª®à«‹àª•àª²à«‹
          isPlaylist: true,
          entity: entityList[index], // àªµàª°à«àª¤àª®àª¾àª¨ àªàª¨à«àªŸàª¿àªŸà«€
        ),
      ),
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

  // PlaylistItemsScreen àª¨à«€ àª…àª‚àª¦àª° àª† àª¨àªµà«€ àª®à«‡àª¥àª¡ àª‰àª®à«‡àª°à«‹/àª¸à«àª§àª¾àª°à«‹
  Future<void> _shareSingleItem(AssetEntity entity) async {
    try {
      final File? file = await entity.file;
      if (file != null && await file.exists()) {
        await Share.shareXFiles([
          XFile(file.path),
        ], text: '${context.tr("sharing")} ${entity.title ?? "${context.tr("mediaFile")}"}');
      } else {
        AppToast.show(context, "${context.tr("filePathIsBroken")}", type: ToastType.error);
      }
    } catch (e) {
      debugPrint("Error sharing: $e");
    }
  }
}

enum PlaylistMenuAction { rename, delete, share }