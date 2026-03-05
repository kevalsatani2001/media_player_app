import '../utils/app_imports.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  List<MediaItem> _results = [];
  Timer? _debounce;

  void _performSearch(String query) async {
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() => _results = []);
      return;
    }

    final lowerQuery = query.toLowerCase();
    final videoBox = Hive.box('videos');
    final audioBox = Hive.box('audios');
    final playlistBox = Hive.box('playlists');

    List<MediaItem> searchTemp = [];

    final allIds = [
      ...videoBox.values.where((v) => v is String && !v.startsWith('data')),
      ...audioBox.values.where((v) => v is String && !v.startsWith('data')),
    ];

    for (var id in allIds) {
      if (!mounted) return;

      final entity = await AssetEntity.fromId(id as String);
      if (entity != null) {
        final file = await entity.file;
        if (file != null) {
          final fileName = file.path.split('/').last.toLowerCase();
          if (fileName.contains(lowerQuery)) {
            searchTemp.add(
              MediaItem(
                id: entity.id,
                path: file.path,
                type: entity.type == AssetType.audio ? 'audio' : 'video',
                isNetwork: false,
                isFavourite: entity.isFavorite,
              ),
            );
          }
        }
      }
    }

    final filteredPlaylists = playlistBox.values
        .cast<PlaylistModel>()
        .where((pl) => pl.name.toLowerCase().contains(lowerQuery))
        .map(
          (pl) => MediaItem(
        id: pl.name,
        path: pl.name,
        type: 'playlist',
        isNetwork: false,
        isFavourite: false,
      ),
    )
        .toList();

    if (!mounted) return;

    setState(() {
      _results = [...filteredPlaylists, ...searchTemp];
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20,color: colors.blackColor,),
            ),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7.5),
                  child: TextFormField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      fillColor: colors.textFieldFill,
                      filled: true,
                      hintText: context.tr("searchAnything"),
                      hintStyle: TextStyle(
                        fontFamily: "inter",
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: colors.textFieldBorder,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(8),
                        child: GestureDetector(
                          onTap: _query.isEmpty
                              ? null
                              : () {
                            setState(() {
                              _controller.clear();
                              _query = "";
                            });
                          },
                          child: AppImage(
                            src: _query.isEmpty
                                ? AppSvg.searchIconBorder
                                : AppSvg.closeIcon,
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: colors.textFieldFill),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colors.textFieldFill),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colors.primary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) {
                      _query = v;
                      setState(() {});

                      if (_debounce?.isActive ?? false) _debounce!.cancel();

                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        _performSearch(v);
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _query.isEmpty
                      ? const Center(
                    child: AppText(
                      "searchVideosAudios",
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  )
                      : _results.isEmpty
                      ? const Center(
                    child: AppText(
                      "noDataFound",
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  )
                      : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final item = _results[i];
                      PlaylistModel? playlist;
                      if (item.type == 'playlist') {
                        final playlistBox = Hive.box('playlists');
                        playlist = playlistBox.values
                            .cast<PlaylistModel>()
                            .firstWhere((pl) => pl.name == item.path);
                      }

                      return AppTransition(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 7.5,
                            horizontal: 15,
                          ),
                          child: GestureDetector(
                            onTap: () async {
                              if (item.type == 'playlist') {
                                final playlistBox = Hive.box('playlists');
                                playlist = playlistBox.values
                                    .cast<PlaylistModel>()
                                    .firstWhere((pl) => pl.name == item.path);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlaylistItemsScreen(
                                      name: playlist!.name,
                                      items: playlist!.items,
                                    ),
                                  ),
                                );
                              } else {
                                final file = File(item.path);
                                if (!await file.exists()) {
                                  AppToast.show(
                                    context,
                                    context.tr("fileNotFoundOrDeleted"),
                                    type: ToastType.error,
                                  );
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlayerScreen(
                                      item: item,
                                      entity: AssetEntity(
                                        id: item.id,
                                        typeInt: item.type == "audio" ? 3 : 2,
                                        width: 200,
                                        height: 200,
                                        isFavorite: item.isFavourite,
                                        title: item.path.split("/").last,
                                        relativePath: item.path,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.cardBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),

                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 10,
                                  top: 10,
                                  bottom: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: item.type == 'playlist'
                                            ? colors.primary.withOpacity(0.1)
                                            : Colors.transparent,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: item.type == 'playlist'
                                          ? Icon(
                                        Icons.playlist_play,
                                        color: colors.primary,
                                        size: 30,
                                      )
                                          : (item.type == 'audio'
                                          ? videoPlaceholder(
                                        isAudio: true,
                                      )
                                          : assetAntityImage(
                                        AssetEntity(
                                          relativePath: item.path,
                                          id: item.id!,
                                          typeInt: 2,
                                          width: 80,
                                          height: 80,
                                        ),
                                      )),
                                    ),
                                    SizedBox(width: 13),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          AppText(
                                            item.path.split('/').last,
                                            maxLines: 1,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          SizedBox(height: 7),
                                          AppText(
                                            item.type != "playlist"
                                                ? item.path
                                                : "${playlist!.items.length} ${context.tr("items")}",
                                            maxLines: 1,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: colors.textFieldBorder,
                                          ),
                                          SizedBox(height: 7),
                                          if (item.type != "playlist")
                                            Row(
                                              children: [
                                                AppText(
                                                  formatDuration(
                                                    AssetEntity(
                                                      relativePath: item.path,
                                                      id: item.id!,
                                                      typeInt:
                                                      item.type == 'audio'
                                                          ? 3
                                                          : 2,
                                                      width: 80,
                                                      height: 80,
                                                    ).duration,
                                                  ),
                                                  maxLines: 2,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                  colors.appBarTitleColor,
                                                ),
                                                SizedBox(width: 10),
                                                FutureBuilder<File?>(
                                                  future: AssetEntity(
                                                    relativePath: item.path,
                                                    id: item.id!,
                                                    typeInt:
                                                    item.type == 'audio'
                                                        ? 3
                                                        : 2,
                                                    width: 80,
                                                    height: 80,
                                                  ).file,
                                                  builder: (context, snapshot) {
                                                    if (!snapshot.hasData ||
                                                        snapshot.data == null) {
                                                      return const SizedBox(
                                                        height: 14,
                                                      );
                                                    }

                                                    final file = snapshot.data!;

                                                    if (!file.existsSync()) {
                                                      return AppText(
                                                        'unavailable',
                                                        fontSize: 11,
                                                        color: Colors.redAccent,
                                                      );
                                                    }

                                                    final bytes = file
                                                        .lengthSync();

                                                    return AppText(
                                                      formatSize(
                                                        bytes,
                                                        context,
                                                      ),
                                                      fontSize: 10,
                                                      fontWeight:
                                                      FontWeight.w500,
                                                      color: colors
                                                          .appBarTitleColor,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 13),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // àªœà«‹ àª•à«€àª¬à«‹àª°à«àª¡ àª–à«àª²à«àª²à«àª‚ àª¹à«‹àª¯ àª…àª¨à«‡ àªµà«€àª¡àª¿àª¯à«‹ àªšàª¾àª²àª¤à«‹ àª¹à«‹àª¯, àª¤à«‹ àª›à«àªªàª¾àªµà«€ àª¦à«‹
            if (!(isKeyboardOpen && GlobalPlayer().currentType == "video"))
              const SmartMiniPlayer(),
          ],
        )
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}