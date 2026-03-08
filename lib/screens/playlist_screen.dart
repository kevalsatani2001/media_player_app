




import '../services/ads_service.dart';
import '../utils/app_imports.dart';


int _clickCounter = 0;
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
                    // ðŸŸ¢ Ad Logic
                    const int adInterval = 4; // Darek 4 playlist pachi ek ad
                    int totalCount = playlists.length + (playlists.length ~/ adInterval);

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      itemCount: totalCount,
                      // itemCount: playlists.length,
                      itemBuilder: (_, index) {
                        // ðŸŸ¢ AD CHECK: Darek 5mi position par (index 4, 9, 14...)
                        if (index != 0 && (index + 1) % (adInterval + 1) == 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: AdHelper.bannerAdWidget(size: AdSize.banner),
                          );
                        }
                        // ðŸŸ¢ ACTUAL DATA INDEX
                        final int actualIndex = index - (index ~/ (adInterval + 1));
                        if (actualIndex >= playlists.length) return const SizedBox.shrink();

                        final playlist = playlists[actualIndex];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7.5),
                          child: AppTransition(
                            index: index,
                            child: GestureDetector(
                              onTap: () {
                                _clickCounter++;
                                if (_clickCounter % 3 == 0) {
                                  AdHelper.showInterstitialAd();
                                }
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
                                            // Row Ã ÂªÂ¨Ã ÂªÂ¾ Thumbnail Ã ÂªÂ¸Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¶Ã ÂªÂ¨Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š
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
                const SmartMiniPlayer(forceMiniMode: true),
              ],
            ),
          ),
          // ðŸŸ¢ BOTTOM STICKY AD (Optional: Jo vadhare revenue joie to)
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
                        // Ã¢Å“â€¦ Success Toast
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
      // Ã ÂªÂªÃ ÂªÂ¹Ã Â«â€¡Ã ÂªÂ²Ã ÂªÂ¾ Ã ÂªÂ¡Ã ÂªÂ¾Ã ÂªÂ¯Ã ÂªÂ°Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÂªÃ ÂªÂ¾Ã ÂªÂ¥Ã ÂªÂ¥Ã Â«â‚¬ Ã ÂªÅ¡Ã Â«â€¡Ã Âªâ€¢ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
      final file = File(item.path);
      if (item.path.isNotEmpty && file.existsSync()) {
        files.add(XFile(item.path));
      } else {
        // Ã ÂªÅ“Ã Â«â€¹ Ã ÂªÂªÃ ÂªÂ¾Ã ÂªÂ¥ Ã ÂªÂ¨Ã ÂªÂ¾ Ã ÂªÂ®Ã ÂªÂ³Ã Â«â€¡ Ã ÂªÂ¤Ã Â«â€¹ AssetEntity Ã ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ«Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ² Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ³Ã ÂªÂµÃ Â«â€¹
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
    // WhatsApp Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ®Ã ÂªÂ¿Ã ÂªÅ¸ Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡ max 10 Ã ÂªÂ«Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ²
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
  bool favState = false; // Ã ÂªÂ²Ã Â«â€¹Ã Âªâ€¢Ã ÂªÂ² Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸

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
          const SmartMiniPlayer(forceMiniMode: true),
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
          const SmartMiniPlayer(forceMiniMode: true),
        ],
      ),

    );
  }

  // Ã ÂªÂ¸Ã ÂªÂ°Ã Â«ÂÃ ÂªÅ¡ Ã ÂªÂ¸Ã Â«ÂÃ Âªâ€¢Ã Â«ÂÃ ÂªÂ°Ã Â«â‚¬Ã ÂªÂ¨ Ã ÂªÅ“Ã Â«â€¡Ã ÂªÂµÃ Â«ÂÃ Âªâ€š Ã ÂªÅ“ Ã Âªâ€¢Ã ÂªÂ¾Ã ÂªÂ°Ã Â«ÂÃ ÂªÂ¡ Ã ÂªÂµÃ ÂªÂ¿Ã ÂªÅ“Ã Â«â€¡Ã ÂªÅ¸
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
              // Ã Âªâ€  Ã ÂªÂ®Ã Â«ÂÃ Âªâ€“Ã Â«ÂÃ ÂªÂ¯ Ã ÂªÂ°Ã Â«â€¹ Ã Âªâ€ºÃ Â«â€¡
              children: [
                // Ã Â«Â§. Thumbnail Image (Ã ÂªÂ«Ã ÂªÂ¿Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¸ Ã ÂªÂµÃ ÂªÂ¿Ã ÂªÂ¡Ã Â«ÂÃ ÂªÂ¥)
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

                // Ã Â«Â¨. Details (Expanded Ã ÂªÅ“Ã Â«â€¡Ã ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ¤Ã Â«â€¡ Ã ÂªÂ¬Ã ÂªÂ¾Ã Âªâ€¢Ã Â«â‚¬Ã ÂªÂ¨Ã Â«â‚¬ Ã ÂªÂµÃ ÂªÂ§Ã Â«â€¡Ã ÂªÂ²Ã Â«â‚¬ Ã ÂªÅ“Ã Âªâ€”Ã Â«ÂÃ ÂªÂ¯Ã ÂªÂ¾ Ã ÂªÅ“ Ã ÂªÂ°Ã Â«â€¹Ã Âªâ€¢Ã Â«â€¡)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Ã ÂªÅ“Ã ÂªÂ°Ã Â«â€šÃ ÂªÂ°Ã Â«â‚¬ Ã Âªâ€ºÃ Â«â€¡
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

                // Ã Â«Â©. PopupMenuButton (Ã ÂªÂªÃ Â«â€¹Ã ÂªÂ¤Ã ÂªÂ¾Ã ÂªÂ¨Ã Â«â‚¬ Ã ÂªÅ“Ã ÂªÂ°Ã Â«â€šÃ ÂªÂ° Ã ÂªÂ®Ã Â«ÂÃ ÂªÅ“Ã ÂªÂ¬Ã ÂªÂ¨Ã Â«â‚¬ Ã ÂªÅ“Ã Âªâ€”Ã Â«ÂÃ ÂªÂ¯Ã ÂªÂ¾ Ã ÂªÂ²Ã Â«â€¡Ã ÂªÂ¶Ã Â«â€¡)
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

    // Ã¢Å“â€¦ Toast Feedback
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

      // Ã¢Å“â€¦ SnackBar Ã ÂªÂ¨Ã Â«â‚¬ Ã ÂªÅ“Ã Âªâ€”Ã Â«ÂÃ ÂªÂ¯Ã ÂªÂ¾Ã ÂªÂ Toast
      AppToast.show(context, "${context.tr("removedFromPlaylist")}", type: ToastType.info);
    }
  }

  // Duration Helper
  Widget _buildDuration(MediaItem item, AppThemeColors colors) {
    return FutureBuilder<AssetEntity?>(
      future: AssetEntity.fromId(item.id), // ID Ã ÂªÂªÃ ÂªÂ°Ã ÂªÂ¥Ã Â«â‚¬ Ã Âªâ€ Ã Âªâ€“Ã Â«â‚¬ Ã ÂªÂÃ ÂªÂ¨Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ¿Ã ÂªÅ¸Ã Â«â‚¬ Ã ÂªÂ²Ã Â«â€¹Ã ÂªÂ¡ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const AppText("00:00", fontSize: 10);

        final entity = snapshot.data!;
        // Ã Âªâ€¦Ã ÂªÂ¹Ã Â«â‚¬Ã Âªâ€š Ã ÂªÂ¡Ã Â«ÂÃ ÂªÂ¯Ã Â«ÂÃ ÂªÂ°Ã Â«â€¡Ã ÂªÂ¶Ã ÂªÂ¨ Ã ÂªÂ¸Ã Â«â€¡Ã Âªâ€¢Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¡Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã ÂªÂ®Ã ÂªÂ³Ã Â«â€¡ Ã Âªâ€ºÃ Â«â€¡
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
    // Ã Â«Â§. Ã Âªâ€ Ã ÂªË†Ã ÂªÅ¸Ã ÂªÂ®Ã ÂªÂ¨Ã Â«â€¹ Ã ÂªË†Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¡Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¸ Ã ÂªÂ¶Ã Â«â€¹Ã ÂªÂ§Ã Â«â€¹
    int index = widget.items.indexOf(item);
    final player = Provider.of<GlobalPlayer>(context, listen: false);

    // Ã Â«Â¨. MediaItem Ã ÂªÂ¨Ã ÂªÂ¾ Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ¨Ã Â«â€¡ AssetEntity Ã ÂªÂ¨Ã ÂªÂ¾ Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã Âªâ€¢Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂµÃ ÂªÂ°Ã Â«ÂÃ ÂªÅ¸ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
    List<AssetEntity> entityList = widget.items.map((media) {
      return AssetEntity(
        id: media.id,
        // type Ã ÂªÂ®Ã Â«ÂÃ ÂªÅ“Ã ÂªÂ¬ typeInt Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÅ¸ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹ (Video: 1, Audio: 2/3, Image: 1)
        // Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¯ Ã ÂªÂ°Ã Â«â‚¬Ã ÂªÂ¤Ã Â«â€¡ photo_manager Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š: Image = 1, Video = 2, Audio = 3
        typeInt: media.type == "video" ? 2 : (media.type == "audio" ? 3 : 1),
        width: 0,
        height: 0,
        duration: 0,
        title: media.path.split("/").last,
      );
    }).toList();

    // Ã Â«Â©. Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ¯Ã ÂªÂ°Ã ÂªÂ¨Ã Â«â‚¬ Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¯Ã Â«Â (Queue) Ã Âªâ€¦Ã ÂªÂ¨Ã Â«â€¡ Ã Âªâ€¡Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¡Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¸ Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÅ¸ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
    // player.queue = entityList;
    player.currentIndex = index;

    print("Playing Item ID: ${item.id}");
    print("Total Items in Queue: ${entityList.length}");

    // Ã Â«Âª. Ã ÂªÂ¨Ã Â«â€¡Ã ÂªÂµÃ ÂªÂ¿Ã Âªâ€”Ã Â«â€¡Ã ÂªÅ¸ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          item: item,
          index: index,
          entityList: entityList, // Ã ÂªÂ¤Ã Â«Ë†Ã ÂªÂ¯Ã ÂªÂ¾Ã ÂªÂ° Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¡Ã ÂªÂ²Ã Â«ÂÃ Âªâ€š Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸ Ã Âªâ€¦Ã ÂªÂ¹Ã Â«â‚¬Ã Âªâ€š Ã ÂªÂ®Ã Â«â€¹Ã Âªâ€¢Ã ÂªÂ²Ã Â«â€¹
          isPlaylist: true,
          entity: entityList[index], // Ã ÂªÂµÃ ÂªÂ°Ã Â«ÂÃ ÂªÂ¤Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÂ¨ Ã ÂªÂÃ ÂªÂ¨Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ¿Ã ÂªÅ¸Ã Â«â‚¬
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

  // PlaylistItemsScreen Ã ÂªÂ¨Ã Â«â‚¬ Ã Âªâ€¦Ã Âªâ€šÃ ÂªÂ¦Ã ÂªÂ° Ã Âªâ€  Ã ÂªÂ¨Ã ÂªÂµÃ Â«â‚¬ Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ¥Ã ÂªÂ¡ Ã Âªâ€°Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ°Ã Â«â€¹/Ã ÂªÂ¸Ã Â«ÂÃ ÂªÂ§Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â€¹
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




/*
import '../utils/app_imports.dart';

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
      body: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (_, Box box, __) {
              final List<PlaylistModel> playlists = box.values
                  .cast<PlaylistModel>()
                  .toList();

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
                                      // Row Ã ÂªÂ¨Ã ÂªÂ¾ Thumbnail Ã ÂªÂ¸Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¶Ã ÂªÂ¨Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š
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
          const SmartMiniPlayer(forceMiniMode: true),
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
                        // Ã¢Å“â€¦ Success Toast
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
      // Ã ÂªÂªÃ ÂªÂ¹Ã Â«â€¡Ã ÂªÂ²Ã ÂªÂ¾ Ã ÂªÂ¡Ã ÂªÂ¾Ã ÂªÂ¯Ã ÂªÂ°Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÂªÃ ÂªÂ¾Ã ÂªÂ¥Ã ÂªÂ¥Ã Â«â‚¬ Ã ÂªÅ¡Ã Â«â€¡Ã Âªâ€¢ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
      final file = File(item.path);
      if (item.path.isNotEmpty && file.existsSync()) {
        files.add(XFile(item.path));
      } else {
        // Ã ÂªÅ“Ã Â«â€¹ Ã ÂªÂªÃ ÂªÂ¾Ã ÂªÂ¥ Ã ÂªÂ¨Ã ÂªÂ¾ Ã ÂªÂ®Ã ÂªÂ³Ã Â«â€¡ Ã ÂªÂ¤Ã Â«â€¹ AssetEntity Ã ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ«Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ² Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ³Ã ÂªÂµÃ Â«â€¹
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
    // WhatsApp Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ®Ã ÂªÂ¿Ã ÂªÅ¸ Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡ max 10 Ã ÂªÂ«Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ²
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
  bool favState = false; // Ã ÂªÂ²Ã Â«â€¹Ã Âªâ€¢Ã ÂªÂ² Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸

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
          const SmartMiniPlayer(forceMiniMode: true),
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
          const SmartMiniPlayer(forceMiniMode: true),
        ],
      ),

    );
  }

  // Ã ÂªÂ¸Ã ÂªÂ°Ã Â«ÂÃ ÂªÅ¡ Ã ÂªÂ¸Ã Â«ÂÃ Âªâ€¢Ã Â«ÂÃ ÂªÂ°Ã Â«â‚¬Ã ÂªÂ¨ Ã ÂªÅ“Ã Â«â€¡Ã ÂªÂµÃ Â«ÂÃ Âªâ€š Ã ÂªÅ“ Ã Âªâ€¢Ã ÂªÂ¾Ã ÂªÂ°Ã Â«ÂÃ ÂªÂ¡ Ã ÂªÂµÃ ÂªÂ¿Ã ÂªÅ“Ã Â«â€¡Ã ÂªÅ¸
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
              // Ã Âªâ€  Ã ÂªÂ®Ã Â«ÂÃ Âªâ€“Ã Â«ÂÃ ÂªÂ¯ Ã ÂªÂ°Ã Â«â€¹ Ã Âªâ€ºÃ Â«â€¡
              children: [
                // Ã Â«Â§. Thumbnail Image (Ã ÂªÂ«Ã ÂªÂ¿Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¸ Ã ÂªÂµÃ ÂªÂ¿Ã ÂªÂ¡Ã Â«ÂÃ ÂªÂ¥)
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

                // Ã Â«Â¨. Details (Expanded Ã ÂªÅ“Ã Â«â€¡Ã ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ¤Ã Â«â€¡ Ã ÂªÂ¬Ã ÂªÂ¾Ã Âªâ€¢Ã Â«â‚¬Ã ÂªÂ¨Ã Â«â‚¬ Ã ÂªÂµÃ ÂªÂ§Ã Â«â€¡Ã ÂªÂ²Ã Â«â‚¬ Ã ÂªÅ“Ã Âªâ€”Ã Â«ÂÃ ÂªÂ¯Ã ÂªÂ¾ Ã ÂªÅ“ Ã ÂªÂ°Ã Â«â€¹Ã Âªâ€¢Ã Â«â€¡)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Ã ÂªÅ“Ã ÂªÂ°Ã Â«â€šÃ ÂªÂ°Ã Â«â‚¬ Ã Âªâ€ºÃ Â«â€¡
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

                // Ã Â«Â©. PopupMenuButton (Ã ÂªÂªÃ Â«â€¹Ã ÂªÂ¤Ã ÂªÂ¾Ã ÂªÂ¨Ã Â«â‚¬ Ã ÂªÅ“Ã ÂªÂ°Ã Â«â€šÃ ÂªÂ° Ã ÂªÂ®Ã Â«ÂÃ ÂªÅ“Ã ÂªÂ¬Ã ÂªÂ¨Ã Â«â‚¬ Ã ÂªÅ“Ã Âªâ€”Ã Â«ÂÃ ÂªÂ¯Ã ÂªÂ¾ Ã ÂªÂ²Ã Â«â€¡Ã ÂªÂ¶Ã Â«â€¡)
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

    // Ã¢Å“â€¦ Toast Feedback
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

      // Ã¢Å“â€¦ SnackBar Ã ÂªÂ¨Ã Â«â‚¬ Ã ÂªÅ“Ã Âªâ€”Ã Â«ÂÃ ÂªÂ¯Ã ÂªÂ¾Ã ÂªÂ Toast
      AppToast.show(context, "${context.tr("removedFromPlaylist")}", type: ToastType.info);
    }
  }

  // Duration Helper
  Widget _buildDuration(MediaItem item, AppThemeColors colors) {
    return FutureBuilder<AssetEntity?>(
      future: AssetEntity.fromId(item.id), // ID Ã ÂªÂªÃ ÂªÂ°Ã ÂªÂ¥Ã Â«â‚¬ Ã Âªâ€ Ã Âªâ€“Ã Â«â‚¬ Ã ÂªÂÃ ÂªÂ¨Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ¿Ã ÂªÅ¸Ã Â«â‚¬ Ã ÂªÂ²Ã Â«â€¹Ã ÂªÂ¡ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const AppText("00:00", fontSize: 10);

        final entity = snapshot.data!;
        // Ã Âªâ€¦Ã ÂªÂ¹Ã Â«â‚¬Ã Âªâ€š Ã ÂªÂ¡Ã Â«ÂÃ ÂªÂ¯Ã Â«ÂÃ ÂªÂ°Ã Â«â€¡Ã ÂªÂ¶Ã ÂªÂ¨ Ã ÂªÂ¸Ã Â«â€¡Ã Âªâ€¢Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¡Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã ÂªÂ®Ã ÂªÂ³Ã Â«â€¡ Ã Âªâ€ºÃ Â«â€¡
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
    // Ã Â«Â§. Ã Âªâ€ Ã ÂªË†Ã ÂªÅ¸Ã ÂªÂ®Ã ÂªÂ¨Ã Â«â€¹ Ã ÂªË†Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¡Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¸ Ã ÂªÂ¶Ã Â«â€¹Ã ÂªÂ§Ã Â«â€¹
    int index = widget.items.indexOf(item);
    final player = Provider.of<GlobalPlayer>(context, listen: false);

    // Ã Â«Â¨. MediaItem Ã ÂªÂ¨Ã ÂªÂ¾ Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ¨Ã Â«â€¡ AssetEntity Ã ÂªÂ¨Ã ÂªÂ¾ Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã Âªâ€¢Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂµÃ ÂªÂ°Ã Â«ÂÃ ÂªÅ¸ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
    List<AssetEntity> entityList = widget.items.map((media) {
      return AssetEntity(
        id: media.id,
        // type Ã ÂªÂ®Ã Â«ÂÃ ÂªÅ“Ã ÂªÂ¬ typeInt Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÅ¸ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹ (Video: 1, Audio: 2/3, Image: 1)
        // Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¯ Ã ÂªÂ°Ã Â«â‚¬Ã ÂªÂ¤Ã Â«â€¡ photo_manager Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š: Image = 1, Video = 2, Audio = 3
        typeInt: media.type == "video" ? 2 : (media.type == "audio" ? 3 : 1),
        width: 0,
        height: 0,
        duration: 0,
        title: media.path.split("/").last,
      );
    }).toList();

    // Ã Â«Â©. Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ¯Ã ÂªÂ°Ã ÂªÂ¨Ã Â«â‚¬ Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¯Ã Â«Â (Queue) Ã Âªâ€¦Ã ÂªÂ¨Ã Â«â€¡ Ã Âªâ€¡Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¡Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¸ Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÅ¸ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
    // player.queue = entityList;
    player.currentIndex = index;

    print("Playing Item ID: ${item.id}");
    print("Total Items in Queue: ${entityList.length}");

    // Ã Â«Âª. Ã ÂªÂ¨Ã Â«â€¡Ã ÂªÂµÃ ÂªÂ¿Ã Âªâ€”Ã Â«â€¡Ã ÂªÅ¸ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          item: item,
          index: index,
          entityList: entityList, // Ã ÂªÂ¤Ã Â«Ë†Ã ÂªÂ¯Ã ÂªÂ¾Ã ÂªÂ° Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¡Ã ÂªÂ²Ã Â«ÂÃ Âªâ€š Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸ Ã Âªâ€¦Ã ÂªÂ¹Ã Â«â‚¬Ã Âªâ€š Ã ÂªÂ®Ã Â«â€¹Ã Âªâ€¢Ã ÂªÂ²Ã Â«â€¹
          isPlaylist: true,
          entity: entityList[index], // Ã ÂªÂµÃ ÂªÂ°Ã Â«ÂÃ ÂªÂ¤Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÂ¨ Ã ÂªÂÃ ÂªÂ¨Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ¿Ã ÂªÅ¸Ã Â«â‚¬
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

  // PlaylistItemsScreen Ã ÂªÂ¨Ã Â«â‚¬ Ã Âªâ€¦Ã Âªâ€šÃ ÂªÂ¦Ã ÂªÂ° Ã Âªâ€  Ã ÂªÂ¨Ã ÂªÂµÃ Â«â‚¬ Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ¥Ã ÂªÂ¡ Ã Âªâ€°Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ°Ã Â«â€¹/Ã ÂªÂ¸Ã Â«ÂÃ ÂªÂ§Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â€¹
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
 */