import '../services/ads_service.dart';
import '../utils/app_imports.dart';

class PlaylistScreen extends StatelessWidget {
  int _clickCounter = 0;

  PlaylistScreen({super.key});

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
            child: AppImage(
              src: AppSvg.backArrowIcon,
              height: 20,
              width: 20,
              color: colors.blackColor,
            ),
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
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ValueListenableBuilder(
                  valueListenable: box.listenable(),
                  builder: (_, Box box, __) {
                    final List<PlaylistModel> playlists = box.values
                        .cast<PlaylistModel>()
                        .toList();

                    if (playlists.isEmpty) {
                      return const Center(child: AppText("noPlaylistsFound"));
                    }

                    const int adInterval = 4;
                    int totalCount =
                        playlists.length + (playlists.length ~/ adInterval);

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      itemCount: totalCount,
                      // itemCount: playlists.length,
                      itemBuilder: (_, index) {
                        // Ã°Å¸Å¸Â¢ AD CHECK: Darek 5mi position par (index 4, 9, 14...)
                        // 1. àªàª¡ àªšà«‡àª• (àª¦àª° 5àª®à«€ àªªà«‹àªàª¿àª¶àª¨ àªªàª°)
                        if (index != 0 && (index + 1) % (adInterval + 1) == 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: AdHelper.bannerAdWidget(size: AdSize.banner),
                          );
                        }

                        // 2. àª¡à«‡àªŸàª¾ àª‡àª¨à«àª¡à«‡àª•à«àª¸ àª•à«‡àª²à«àª•à«àª¯à«àª²à«‡àª¶àª¨
                        final int actualIndex =
                            index - (index ~/ (adInterval + 1));
                        if (actualIndex >= playlists.length)
                          return const SizedBox.shrink();

                        final playlist = playlists[actualIndex];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7.5),
                          child: AppTransition(
                            index: index,
                            child: GestureDetector(
                              onTap: () {
                                _clickCounter++;

                                // àª¨à«‡àªµàª¿àª—à«‡àª¶àª¨ àª«àª‚àª•à«àª¶àª¨
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

                                // àª¦àª° 3 àª•à«àª²àª¿àª• àªªàª° àªàª¡ àª¬àª¤àª¾àªµà«‹
                                if (_clickCounter % 3 == 0) {
                                  // àª…àª¹àª¿àª¯àª¾àª‚ Callback àªªàª¾àª¸ àª•àª°àªµà«‹ àªœàª°à«‚àª°à«€ àª›à«‡
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
                                // height: 100,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    top: 10,
                                    bottom: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            // Row Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â¾ Thumbnail Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¶Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ¢â‚¬Å¡
                                            Container(
                                              width: 80,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(8),
                                                color: colors.primary
                                                    .withOpacity(0.1),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: Icon(
                                                Icons.playlist_play,
                                                color: colors.primary,
                                                size: 30,
                                              ),
                                            ),
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
                                                    color:
                                                    colors.textFieldBorder,
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        shadowColor: Colors.black.withOpacity(
                                          0.60,
                                        ),
                                        offset: Offset(0, 0),
                                        // splashRadius: 15,
                                        icon: AppImage(
                                          src: AppSvg.dropDownMenuDot,
                                          color: colors.blackColor,
                                        ),
                                        menuPadding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        onSelected: (action) {
                                          switch (action) {
                                            case PlaylistMenuAction.rename:
                                              _showRenameDialog(
                                                context,
                                                box,
                                                index,
                                                playlist.name,
                                              );
                                              break;
                                            case PlaylistMenuAction.delete:
                                              _confirmDelete(
                                                context,
                                                box,
                                                index,
                                                playlist.name,
                                              );
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
                const SmartMiniPlayer(forceMiniMode: true),
              ],
            ),
          ),
          // Ã°Å¸Å¸Â¢ BOTTOM STICKY AD (Optional: Jo vadhare revenue joie to)
          // AdHelper.adaptiveBannerWidget(context),
        ],
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
                        // ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ Success Toast
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
      // Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¾ Ãƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ…Â¸ Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ…Â¡Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹
      final file = File(item.path);
      if (item.path.isNotEmpty && file.existsSync()) {
        files.add(XFile(item.path));
      } else {
        // Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â¥ Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â¾ Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â³Ãƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚Â«Ã¢â‚¬Â¹ AssetEntity Ãƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚Â«Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‹â€ Ãƒ Ã‚ÂªÃ‚Â² Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â³Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã¢â‚¬Â¹
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
    // WhatsApp Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ…Â¸ Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚Â«Ã¢â‚¬Â¡ max 10 Ãƒ Ã‚ÂªÃ‚Â«Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‹â€ Ãƒ Ã‚ÂªÃ‚Â²
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
  int _playClickCount = 0;
  bool favState = false;

  @override
  void initState() {
    super.initState();
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
            child: AppImage(
              src: AppSvg.backArrowIcon,
              height: 20,
              width: 20,
              color: colors.blackColor,
            ),
          ),
        ),
        title: AppText(widget.name, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      body: widget.items.isEmpty
          ? const Center(child: AppText("playlistEmpty", fontSize: 16))
          : GlobalPlayer().currentType == "video"
          ? Stack(
        children: [
          _buildItemList(),
          const SmartMiniPlayer(forceMiniMode: true),
        ],
      )
          : Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildItemList()),
              // àªœà«‹ àª¤àª®àª¾àª°à«‡ àª¨à«€àªšà«‡ àª¬à«‡àª¨àª° àªàª¡ àª¬àª¤àª¾àªµàªµà«€ àª¹à«‹àª¯ àª¤à«‹ àª…àª¹à«€àª‚ àª®à«‚àª•à«€ àª¶àª•àª¾àª¯
              AdHelper.bannerAdWidget(),
            ],
          ),
          const SmartMiniPlayer(forceMiniMode: true),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    const int adInterval = 4;
    int totalCount = widget.items.length + (widget.items.length ~/ adInterval);

    return ListView.builder(
      itemCount: totalCount,
      padding: const EdgeInsets.only(top: 10),
      itemBuilder: (_, i) {
        // àªàª¡ àª¬àª¤àª¾àªµàªµàª¾ àª®àª¾àªŸà«‡àª¨à«€ àª•àª¨à«àª¡àª¿àª¶àª¨
        if (i != 0 && (i + 1) % (adInterval + 1) == 0) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 7.5, horizontal: 0),
            alignment: Alignment.center,
            child: AdHelper.bannerAdWidget(size: AdSize.banner),
          );
        }

        // àª“àª°àª¿àªœàª¿àª¨àª² àª¡à«‡àªŸàª¾àª¨à«‹ àª‡àª¨à«àª¡à«‡àª•à«àª¸ àª¶à«‹àª§à«‹
        final int actualIndex = i - (i ~/ (adInterval + 1));
        if (actualIndex >= widget.items.length) return const SizedBox.shrink();

        final item = widget.items[actualIndex];
        return AppTransition(
          index: i,
          child: _buildMediaCard(context, item, colors, actualIndex),
        );
      },
    );
  }

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
              // Ãƒ Ã‚ÂªÃ¢â‚¬  Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬â€œÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¯ Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ¢â‚¬ÂºÃƒ Ã‚Â«Ã¢â‚¬Â¡
              children: [
                // Ãƒ Ã‚Â«Ã‚Â§. Thumbnail Image (Ãƒ Ã‚ÂªÃ‚Â«Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¸ Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¥)
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

                // Ãƒ Ã‚Â«Ã‚Â¨. Details (Expanded Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã¢â€šÂ¬Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚ÂªÃ‚Â§Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚ÂªÃ¢â‚¬â€Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚ÂªÃ‚Â¾ Ãƒ Ã‚ÂªÃ…â€œ Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã¢â‚¬Â¡)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    // Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Å¡Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ¢â‚¬ÂºÃƒ Ã‚Â«Ã¢â‚¬Â¡
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
                          _buildFileSize(item, colors, context),
                        ],
                      ),
                    ],
                  ),
                ),

                // Ãƒ Ã‚Â«Ã‚Â©. PopupMenuButton (Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Å¡Ãƒ Ã‚ÂªÃ‚Â° Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ…â€œÃƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚ÂªÃ¢â‚¬â€Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚ÂªÃ‚Â¾ Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¶Ãƒ Ã‚Â«Ã¢â‚¬Â¡)
                PopupMenuButton<MediaMenuAction>(
                  elevation: 15,
                  color: colors.dropdownBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  icon: AppImage(
                    src: AppSvg.dropDownMenuDot,
                    color: colors.blackColor,
                  ),
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
      AppToast.show(
        context,
        context.tr("fileNotFoundMsg"),
        type: ToastType.error,
      );
      return;
    }

    final playlistService = PlaylistService();
    final newFavState = await playlistService.toggleFavourite(entity);

    setState(() {
      currentItems[index].isFavourite = newFavState;
    });

    AppToast.show(
      context,
      newFavState
          ? "${context.tr("addedToFavourite")}"
          : "${context.tr("removedFromFavourites")}",
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

      // ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ SnackBar Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚ÂªÃ¢â‚¬â€Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â Toast
      AppToast.show(
        context,
        "${context.tr("removedFromPlaylist")}",
        type: ToastType.info,
      );
    }
  }

  // Duration Helper
  Widget _buildDuration(MediaItem item, AppThemeColors colors) {
    return FutureBuilder<AssetEntity?>(
      future: AssetEntity.fromId(item.id),
      // ID Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ¢â‚¬ Ãƒ Ã‚ÂªÃ¢â‚¬â€œÃƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚ÂÃƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¡ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const AppText("00:00", fontSize: 10);

        final entity = snapshot.data!;
        // Ãƒ Ã‚ÂªÃ¢â‚¬Â¦Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â€šÂ¬Ãƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¶Ãƒ Ã‚ÂªÃ‚Â¨ Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â³Ãƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ¢â‚¬ÂºÃƒ Ã‚Â«Ã¢â‚¬Â¡
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
  Widget _buildFileSize(
      MediaItem item,
      AppThemeColors colors,
      BuildContext context,
      ) {
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
        return AppText(
          formatSize(bytes, context),
          // '${mb.toStringAsFixed(1)} MB',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colors.appBarTitleColor,
        );
      },
    );
  }

  void _handlePlay(BuildContext context, MediaItem item) {
    _playClickCount++; // àª•à«àª²àª¿àª• àª•àª¾àª‰àª¨à«àªŸ àªµàª§àª¾àª°à«‹

    // àª¨à«‡àªµàª¿àª—à«‡àª¶àª¨ àª®àª¾àªŸà«‡àª¨à«àª‚ àª«àª‚àª•à«àª¶àª¨
    void startNavigation() {
      int index = widget.items.indexOf(item);
      final player = Provider.of<GlobalPlayer>(context, listen: false);

      List<AssetEntity> entityList = widget.items.map((media) {
        return AssetEntity(
          id: media.id,
          typeInt: media.type == "video" ? 2 : (media.type == "audio" ? 3 : 1),
          width: 0,
          height: 0,
          duration: 0,
          title: media.path.split("/").last,
        );
      }).toList();

      player.currentIndex = index;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            item: item,
            index: index,
            entityList: entityList,
            isPlaylist: true,
            entity: entityList[index],
          ),
        ),
      );
    }

    // àª¦àª° 3 àª•à«àª²àª¿àª• àªªàª° àªàª¡ àª¬àª¤àª¾àªµà«‹
    if (_playClickCount % 3 == 0) {
      AdHelper.showInterstitialAd(() {
        startNavigation(); // àªàª¡ àª¬àª‚àª§ àª¥àª¾àª¯ àªªàª›à«€ àªªà«àª²à«‡àª¯àª° àª–à«‹àª²à«‹
      });
    } else {
      startNavigation(); // àª¸à«€àª§à«àª‚ àªªà«àª²à«‡àª¯àª° àª–à«‹àª²à«‹
    }
  }

  Future<void> routeToDetailPage(
      BuildContext context,
      AssetEntity entity,
      ) async {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => DetailPage(entity: entity)),
    );
  }

  // PlaylistItemsScreen Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ¢â‚¬Â¦Ãƒ Ã‚ÂªÃ¢â‚¬Å¡Ãƒ Ã‚ÂªÃ‚Â¦Ãƒ Ã‚ÂªÃ‚Â° Ãƒ Ã‚ÂªÃ¢â‚¬  Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚ÂªÃ‚Â¡ Ãƒ Ã‚ÂªÃ¢â‚¬Â°Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹/Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â§Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹
  Future<void> _shareSingleItem(AssetEntity entity) async {
    try {
      final File? file = await entity.file;
      if (file != null && await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
          '${context.tr("sharing")} ${entity.title ?? "${context.tr("mediaFile")}"}',
        );
      } else {
        AppToast.show(
          context,
          "${context.tr("filePathIsBroken")}",
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint("Error sharing: $e");
    }
  }
}

enum PlaylistMenuAction { rename, delete, share }