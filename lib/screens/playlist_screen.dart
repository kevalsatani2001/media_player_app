import 'package:media_player/screens/playlist_item_screen.dart';

import '../services/ads_service.dart';
import '../utils/app_imports.dart';

class PlaylistScreen extends StatelessWidget {
  int _clickCounter = 0;

  PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final box = Hive.box('playlists');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: AppText("playlist", fontSize: 20, fontWeight: FontWeight.w500),
          leading: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: AppImage(
                src: AppSvg.backArrowIcon,
                height: 20,
                width: 20,
                color: colors.blackColor,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: SearchButton(),
            ),
          ],

           bottom: TabBar(
            indicatorColor: colors.primary,
            labelColor: colors.primary,
            unselectedLabelColor: colors.textFieldBorder,
            tabs: [
              Tab(text: context.tr("video")),
              Tab(text: context.tr("audio")),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPlaylistList(box, "video", colors, context),
            _buildPlaylistList(box, "audio", colors, context),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistList(
      Box box,
      String type,
      AppThemeColors colors,
      BuildContext context,
      ) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (_, Box box, __) {
        final List<PlaylistModel> playlists = box.values
            .cast<PlaylistModel>()
            .where((p) => p.type == type)
            .toList();

        if (playlists.isEmpty) {
          return Center(
            child: AppText(
              "no${type == 'audio' ? 'Audio' : 'Video'}PlaylistsFound",
            ),
          );
        }

        const int adInterval = 4;
        int totalCount = playlists.length + (playlists.length ~/ adInterval);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            if (index != 0 && (index + 1) % (adInterval + 1) == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: AdHelper.bannerAdWidget(size: AdSize.banner),
              );
            }

            final int actualIndex = index - (index ~/ (adInterval + 1));
            if (actualIndex >= playlists.length) return const SizedBox.shrink();

            final playlist = playlists[actualIndex];
            return _buildPlaylistItem(playlist, index, colors, context, box);
          },
        );
      },
    );
  }

  Widget _buildPlaylistItem(
      PlaylistModel playlist,
      int index,
      AppThemeColors colors,
      BuildContext context,
      Box box,
      ) {
    bool isAudio = playlist.type == "audio";
    final dynamic originalKey = box.keys.firstWhere(
          (k) => box.get(k) == playlist,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.5),
      child: GestureDetector(
        onTap: () {
          _clickCounter++;

          void goToPlaylist() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistItemsScreen(
                  name: playlist.name,
                  items: playlist.items,
                ),
              ),
            );
          }

          if (_clickCounter % 3 == 0) {
            AdHelper.showInterstitialAd(() {
              goToPlaylist();
            });
          } else {
            goToPlaylist();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: colors.primary.withOpacity(0.1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Icon(
                          isAudio ? Icons.music_note : Icons.playlist_play,
                          color: colors.primary,
                        ),
                      ),
                      SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                  icon: AppImage(
                    src: AppSvg.dropDownMenuDot,
                    color: colors.blackColor,
                  ),
                  menuPadding: EdgeInsets.symmetric(horizontal: 10),
                  onSelected: (action) {
                    switch (action) {
                      case PlaylistMenuAction.rename:
                        _showRenameDialog(context, box, originalKey, playlist.name);
                        break;
                      case PlaylistMenuAction.delete:
                        _confirmDelete(context, box, originalKey, playlist.name);
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
    );
  }

  void _showRenameDialog(
      BuildContext context,
      Box box, dynamic playlistKey,
      String oldName,
      )
  {
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
              decoration: InputDecoration(
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
                        AppToast.show(context, context.tr("pleaseEnterName"), type: ToastType.error);
                        return;
                      }

                      final playlist = box.get(playlistKey) as PlaylistModel?;
                      if (playlist != null) {
                        playlist.name = newName;
                        box.put(playlistKey, playlist);
                        Navigator.pop(context);
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

  void _confirmDelete(BuildContext context, Box box, dynamic playlistKey, String name) {
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
                      box.delete(playlistKey);
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
      final file = File(item.path);
      if (item.path.isNotEmpty && file.existsSync()) {
        files.add(XFile(item.path));
      } else {
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
      AppToast.show(
        context,
        "${context.tr("noShareableFilesFound")}",
        type: ToastType.error,
      );
      return;
    }
    final shareableFiles = files.length > 10 ? files.sublist(0, 10) : files;

    await Share.shareXFiles(
      shareableFiles,
      text: "${context.tr("sharingPlaylist")} ${playlist.name}",
    );
  }
}

