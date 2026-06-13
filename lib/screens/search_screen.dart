import 'package:media_player/screens/playlist_item_screen.dart';
import 'package:media_player/screens/audio_player_screen.dart';

import '../services/ads_service.dart';
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
  final Map<String, Future<AssetEntity?>> _entityFutureCache = {};

  Future<AssetEntity?> _resolveEntity(String id) {
    return _entityFutureCache.putIfAbsent(id, () => AssetEntity.fromId(id));
  }

  Future<List<AssetEntity>> _resolveAudioQueueFromResults() async {
    final ids = _results
        .where((it) => it.type == 'audio')
        .map((it) => it.id)
        .toList();
    final resolved = await Future.wait(ids.map(_resolveEntity));
    return resolved.whereType<AssetEntity>().toList();
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() => _results = []);
      return;
    }

    final lowerQuery = query.toLowerCase();
    
    // 1. Get cached lists of AssetEntity from Blocs when loaded (extremely fast, memory lookup)
    final audioState = context.read<AudioBloc>().state;
    final videoState = context.read<VideoBloc>().state;

    List<AssetEntity> audioEntities = [];
    if (audioState is AudioLoaded) {
      audioEntities = audioState.entities;
    } else {
      final audioBox = Hive.box('audios');
      final audioIds = audioBox.values.whereType<String>().toList();
      final fetched = await Future.wait(audioIds.map((id) => AssetEntity.fromId(id)));
      audioEntities = fetched.whereType<AssetEntity>().toList();
    }

    List<AssetEntity> videoEntities = [];
    if (videoState is VideoLoaded) {
      videoEntities = videoState.entities;
    } else {
      final videoBox = Hive.box('videos');
      final videoIds = videoBox.values.whereType<String>().toList();
      final fetched = await Future.wait(videoIds.map((id) => AssetEntity.fromId(id)));
      videoEntities = fetched.whereType<AssetEntity>().toList();
    }

    // 2. Perform in-memory filter matching title names (filenames)
    final List<AssetEntity> allEntities = [...audioEntities, ...videoEntities];
    final List<AssetEntity> matchingEntities = allEntities.where((entity) {
      final title = (entity.title ?? '').toLowerCase();
      return title.contains(lowerQuery);
    }).toList();

    // 3. Resolve files in parallel only for the matches
    final List<MediaItem> searchTemp = [];
    final resolvedMatches = await Future.wait(
      matchingEntities.map((entity) async {
        final file = await entity.file;
        if (file != null) {
          return MediaItem(
            id: entity.id,
            path: file.path,
            type: entity.type == AssetType.audio ? 'audio' : 'video',
            isNetwork: false,
            isFavourite: entity.isFavorite,
          );
        }
        return null;
      }),
    );
    searchTemp.addAll(resolvedMatches.whereType<MediaItem>());

    // 4. Resolve playlists
    final playlistBox = Hive.box('playlists');
    final filteredPlaylists = playlistBox.values
        .cast<PlaylistModel>()
        .where((pl) => pl.name.toLowerCase().contains(lowerQuery))
        .map(
          (pl) => MediaItem(
            id: pl.name,
            path: pl.name,
            type: pl.type == 'audio' ? 'playlist_audio' : 'playlist_video',
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
            child: AppImage(
              src: AppSvg.backArrowIcon,
              height: 20,
              width: 20,
              color: colors.blackColor,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7.5,
                ),
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
                  child: AppText("noDataFound", fontSize: 18),
                )
                    : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final item = _results[i];
                    final int actualIndex = i;
                    bool isPlaylist = item.type.startsWith(
                      'playlist',
                    ); // àª¨àªµà«€ àª°à«€àª¤
                    PlaylistModel? playlist;

                    if (isPlaylist) {
                      final playlistBox = Hive.box('playlists');
                      final targetType = item.type == 'playlist_audio'
                          ? 'audio'
                          : 'video';

                      playlist = playlistBox.values
                          .cast<PlaylistModel>()
                          .firstWhere(
                            (pl) =>
                        pl.name == item.path &&
                            pl.type == targetType,
                      );
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
                            if (isPlaylist) {
                              final targetType =
                              item.type == 'playlist_audio'
                                  ? 'audio'
                                  : 'video';
                              playlist = Hive.box('playlists').values
                                  .cast<PlaylistModel>()
                                  .firstWhere(
                                    (pl) =>
                                pl.name == item.path &&
                                    pl.type == targetType,
                              );

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
                              if (item.type == 'audio') {
                                final audio = await _resolveEntity(item.id);
                                if (audio == null) {
                                  AppToast.show(
                                    context,
                                    context.tr("fileNotFoundOrDeleted"),
                                    type: ToastType.error,
                                  );
                                  return;
                                }
                                final file = await audio.file;
                                if (file == null || !await file.exists()) {
                                  AppToast.show(
                                    context,
                                    context.tr("fileNotFoundOrDeleted"),
                                    type: ToastType.error,
                                  );
                                  return;
                                }

                                final queue = await _resolveAudioQueueFromResults();
                                final selectedIndex = queue.indexWhere(
                                  (e) => e.id == audio.id,
                                );

                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                    ) =>
                                        AudioPlayerScreen(
                                      entityList: queue,
                                      entity: audio,
                                      index: selectedIndex >= 0 ? selectedIndex : 0,
                                      item: MediaItem(
                                        isFavourite: audio.isFavorite,
                                        id: audio.id,
                                        path: file.path,
                                        isNetwork: false,
                                        type: 'audio',
                                      ),
                                    ),
                                    transitionsBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      const begin = Offset(0.0, 1.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOut;

                                      final tween = Tween(
                                        begin: begin,
                                        end: end,
                                      ).chain(CurveTween(curve: curve));
                                      final offsetAnimation =
                                          animation.drive(tween);

                                      return SlideTransition(
                                        position: offsetAnimation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(
                                      milliseconds: 400,
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
                                      entity: AssetEntity(
                                        id: item.id,
                                        typeInt: 2,
                                        width: 200,
                                        height: 200,
                                        isFavorite: item.isFavourite,
                                        title: item.path.split("/").last,
                                        relativePath: item.path,
                                      ),
                                      index: actualIndex,
                                      entityList: const [],
                                    ),
                                  ),
                                );
                              }
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
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ),
                                      color:
                                      item.type == 'playlist_video' ||
                                          item.type ==
                                              'playlist_audio'
                                          ? colors.primary.withOpacity(
                                        0.1,
                                      )
                                          : Colors.transparent,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child:
                                    item.type == 'playlist_video' ||
                                        item.type == 'playlist_audio'
                                        ? Icon(
                                      item.type == 'playlist_audio'
                                          ? Icons.music_note
                                          : Icons.playlist_play,
                                      color: colors.primary,
                                      size: 30,
                                    )
                                        : (item.type == 'audio'
                                        ? videoPlaceholder(
                                      isAudio: true,
                                    )
                                        : assetAntityImage(
                                      AssetEntity(
                                        relativePath:
                                        item.path,
                                        id: item.id,
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
                                                    relativePath:
                                                    item.path,
                                                    id: item.id,
                                                    typeInt:
                                                    item.type ==
                                                        'audio'
                                                        ? 3
                                                        : 2,
                                                    width: 80,
                                                    height: 80,
                                                  ).duration,
                                                ),
                                                maxLines: 2,
                                                fontSize: 10,
                                                fontWeight:
                                                FontWeight.w500,
                                                color: colors
                                                    .appBarTitleColor,
                                              ),
                                              SizedBox(width: 10),
                                              FutureBuilder<File?>(
                                                future: AssetEntity(
                                                  relativePath: item.path,
                                                  id: item.id,
                                                  typeInt:
                                                  item.type == 'audio'
                                                      ? 3
                                                      : 2,
                                                  width: 80,
                                                  height: 80,
                                                ).file,
                                                builder: (context, snapshot) {
                                                  if (!snapshot.hasData ||
                                                      snapshot.data ==
                                                          null) {
                                                    return const SizedBox(
                                                      height: 14,
                                                    );
                                                  }

                                                  final file =
                                                  snapshot.data!;

                                                  if (!file
                                                      .existsSync()) {
                                                    return AppText(
                                                      'unavailable',
                                                      fontSize: 11,
                                                      color: Colors
                                                          .redAccent,
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

          if (!(isKeyboardOpen && GlobalPlayer().currentType == "video"))
            const SmartMiniPlayer(forceMiniMode: true),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}

class AdPlaceholder {
  const AdPlaceholder();
}