import '../services/ads_service.dart';
import '../utils/app_imports.dart';
import 'audio_player_screen.dart';

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
        if (i != 0 && (i + 1) % (adInterval + 1) == 0) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 7.5, horizontal: 0),
            alignment: Alignment.center,
            child: AdHelper.bannerAdWidget(size: AdSize.banner),
          );
        }

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
              children: [
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

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const AppText("00:00", fontSize: 10);

        final entity = snapshot.data!;
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
    _playClickCount++;

    void startNavigation() async {
      int index = widget.items.indexOf(item);

      List<AssetEntity> entityList = widget.items.map((media) {
        return AssetEntity(
          id: media.id,
          typeInt: media.type == "audio" ? 3 : 2,
          width: 0,
          height: 0,
          duration: 0,
          title: media.path.split("/").last,
        );
      }).toList();

      if (!mounted) return;

      if (item.type == "audio") {
         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPlayerScreen(
              entityList: entityList,
              entity: entityList[index],
              item: widget.items[index],
              index: index,
              isPlaylist:
              true,
            ),
          ),
        ).then((_) {
          if (mounted) setState(() {});
        });
      } else {
         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              entityList: entityList,
              entity: entityList[index],
              index: index,
            ),
          ),
        ).then((_) {
          if (mounted) setState(() {});
        });
      }
    }

    if (_playClickCount % 3 == 0) {
      AdHelper.showInterstitialAd(() => startNavigation());
    } else {
      startNavigation();
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