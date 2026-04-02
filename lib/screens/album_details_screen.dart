import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../services/ads_service.dart';
import '../utils/app_imports.dart';
import 'audio_player_screen.dart';

class AlbumDetailsScreen extends StatefulWidget {
  final AssetPathEntity albumPath;

  const AlbumDetailsScreen({super.key, required this.albumPath});

  @override
  State<AlbumDetailsScreen> createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final ScrollController _scrollController = ScrollController();
  int _albumAudioClickCount = 0;
  String _selectedLetter = '';
  final Map<String, int> _letterIndices = {};
  final double _itemHeight = 80.0;

  List<String> _getAlphabetList(List<AssetEntity> entities) {
    Set<String> letters = {};
    for (var entity in entities) {
      String name = entity.title ?? "";
      if (name.isEmpty) name = entity.id;
      String firstChar = name.isNotEmpty ? name[0].toUpperCase() : '#';
      if (RegExp(r'^\p{L}', unicode: true).hasMatch(firstChar)) {
        letters.add(firstChar);
      } else {
        letters.add('#');
      }
    }
    return letters.toList()
      ..sort((a, b) => a == '#' ? 1 : (b == '#' ? -1 : a.compareTo(b)));
  }

  void _scrollToLetter(String letter, int adInterval) {
    final targetIndex = _letterIndices[letter];
    if (targetIndex != null) {
      double scrollOffset = targetIndex * _itemHeight;
      if (scrollOffset > _scrollController.position.maxScrollExtent) {
        scrollOffset = _scrollController.position.maxScrollExtent;
      }
      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _selectedLetter = letter);
    }
  }

  void _calculateLetterIndices(List<AssetEntity> entities, int adInterval) {
    _letterIndices.clear();
    String currentLetter = '';
    for (int i = 0; i < entities.length; i++) {
      String name = entities[i].title ?? "";
      String firstChar = name.isNotEmpty ? name[0].toUpperCase() : '#';
      String letter = RegExp(r'^\p{L}', unicode: true).hasMatch(firstChar)
          ? firstChar
          : '#';
      if (letter != currentLetter) {
        currentLetter = letter;
        _letterIndices[letter] = i + (i ~/ adInterval);
      }
    }
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
        centerTitle: true,
        title: AppText(
          widget.albumPath.name,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      body: SafeArea(
        child: GlobalPlayer().currentType == "video"
            ? Stack(
          children: [
            Column(children: [Expanded(child: _buildMainBody(colors))]),
            const SmartMiniPlayer(),
          ],
        )
            : Column(
          children: [
            Expanded(child: _buildMainBody(colors)),
            Align(
              alignment: Alignment.bottomCenter,
              child:
              const SmartMiniPlayer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainBody(AppThemeColors colors) {
    return FutureBuilder<List<AssetEntity>>(
      future: widget.albumPath.getAssetListRange(start: 0, end: 500),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CustomLoader());

        final List<AssetEntity> entities = snapshot.data!;
        entities.sort(
              (a, b) => (a.title ?? "").toLowerCase().compareTo(
            (b.title ?? "").toLowerCase(),
          ),
        );

        const int adInterval = 5;
        final alphabetList = _getAlphabetList(entities);
        _calculateLetterIndices(entities, adInterval);

        return Stack(
          children: [
            _buildAudioList(entities, adInterval),

            // Alphabet Sidebar
            Positioned(
              right: 6,
              top: 20,
              bottom: 20,
              child: Center(
                child: Container(
                  width: 24,
                  decoration: BoxDecoration(
                    color: colors.blackColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SingleChildScrollView(
                    child: Column(
                      children: alphabetList.map((letter) {
                        bool isActive = _selectedLetter == letter;
                        return GestureDetector(
                          onTap: () => _scrollToLetter(letter, adInterval),
                          child: Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.symmetric(vertical: 2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? colors.primary
                                  : Colors.transparent,
                            ),
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? Colors.white
                                    : colors.blackColor.withOpacity(0.6),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioList(List<AssetEntity> entities, int adInterval) {
    int totalCount = entities.length + (entities.length ~/ adInterval) + 1;

    return AnimationLimiter(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: totalCount,
        itemBuilder: (context, index) {
          final colors = Theme.of(context).extension<AppThemeColors>()!;
          if (index == totalCount - 1) return const SizedBox(height: 100);

          if (index != 0 && (index + 1) % (adInterval + 1) == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AdHelper.bannerAdWidget(size: AdSize.banner),
            );
          }

          final int actualIndex = index - (index ~/ (adInterval + 1));
          if (actualIndex >= entities.length) return const SizedBox.shrink();
          final audio = entities[actualIndex];

          return Consumer<GlobalPlayer>(
            builder: (context, player, child) {
              final bool isCurrentPlaying =
                  player.currentEntity?.id == audio.id;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: AppTransition(
                  index: index,
                  child: FutureBuilder<File?>(
                    future: audio.file,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox(height: 80);
                      final file = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7.5),
                        child: GestureDetector(
                          onTap: () => _handleOnTap(entities, audio, file),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors.cardBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: isCurrentPlaying
                                  ? Border.all(
                                color: colors.primary,
                                width: 0.5,
                              )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                _buildLeadingIcon(
                                  audio,
                                  colors,
                                  isCurrentPlaying,
                                ),
                                const SizedBox(width: 12),
                                _buildTitleAndDuration(audio, file, colors),
                                _buildPopupMenu(audio, actualIndex),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPopupMenu(AssetEntity audio, int index) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return PopupMenuButton<MediaMenuAction>(
      elevation: 15,
      color: colors.dropdownBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.black.withOpacity(0.60),
      icon: AppImage(src: AppSvg.dropDownMenuDot, color: colors.blackColor),
      onSelected: (action) => handleMenuAction(context, audio, action, index),
      itemBuilder: (context) => [
        _buildPopupItem(
          MediaMenuAction.addToFavourite,
          audio.isFavorite ? 'removeToFavourite' : 'addToFavourite',
        ),
        const PopupMenuDivider(height: 0.5),
        _buildPopupItem(MediaMenuAction.delete, 'delete'),
        const PopupMenuDivider(height: 0.5),
        _buildPopupItem(MediaMenuAction.share, 'share'),
        const PopupMenuDivider(height: 0.5),
        _buildPopupItem(MediaMenuAction.detail, 'showDetail'),
        const PopupMenuDivider(height: 0.5),
        _buildPopupItem(MediaMenuAction.addToPlaylist, 'addToPlaylist'),
      ],
    );
  }

  PopupMenuItem<MediaMenuAction> _buildPopupItem(
      MediaMenuAction action,
      String title,
      ) {
    return PopupMenuItem(
      value: action,
      child: Center(child: AppText(title, fontSize: 12)),
    );
  }

  Widget _buildLeadingIcon(
      AssetEntity audio,
      AppThemeColors colors,
      bool isPlaying,
      ) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colors.blackColor.withOpacity(0.38),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            FutureBuilder<Uint8List?>(
              future: _audioQuery.queryArtwork(
                Platform.isIOS
                    ? audio.id.hashCode
                    : int.tryParse(audio.id) ?? 0,
                ArtworkType.AUDIO,
                format: ArtworkFormat.JPEG,
                size: 200,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.isNotEmpty) {
                  return Image.memory(
                    snapshot.data!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  );
                }
                return AppImage(
                  src: AppSvg.musicUnselected,
                  height: 22,
                  color: colors.whiteColor,
                );
              },
            ),
            if (isPlaying)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: AppImage(
                  src: GlobalPlayer().isPlaying
                      ? AppSvg.playerPause
                      : AppSvg.playerResume,
                  height: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndDuration(
      AssetEntity audio,
      File file,
      AppThemeColors colors,
      ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            file.path.split('/').last,
            maxLines: 1,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          const SizedBox(height: 6),
          AppText(
            formatDuration(audio.duration),
            fontSize: 13,
            color: colors.textFieldBorder,
          ),
        ],
      ),
    );
  }

  void _handleOnTap(List<AssetEntity> entities, AssetEntity audio, File file) {
    void openPlayer() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AudioPlayerScreen(
            entityList: entities,
            entity: audio,
            item: MediaItem(
              id: audio.id,
              path: file.path,
              isNetwork: false,
              type: 'audio',
              isFavourite: audio.isFavorite,
            ),
          ),
        ),
      );
    }

    _albumAudioClickCount++;
    if (_albumAudioClickCount % 4 == 0) {
      AdHelper.showInterstitialAd(() => openPlayer());
    } else {
      openPlayer();
    }
  }

  String formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    return "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
  }

  void handleMenuAction(
      BuildContext context,
      AssetEntity audio,
      MediaMenuAction action,
      int index,
      ) async {
    switch (action) {
      case MediaMenuAction.detail:
        routeToDetailPage(context, audio);
        break;
      case MediaMenuAction.info:
        showInfoDialog(context, audio);
        break;
      case MediaMenuAction.share:
        shareItem(context, audio);
        break;
      case MediaMenuAction.delete:
        deleteCurrentItem(context, audio);
        break;
      case MediaMenuAction.addToFavourite:
        await _toggleFavourite(context, audio, index);
        break;
      case MediaMenuAction.addToPlaylist:
        final file = await audio.file;
        if (file != null) {
          addToPlaylist(
            MediaItem(
              path: file.path,
              isNetwork: false,
              type: "audio",
              id: audio.id,
              isFavourite: audio.isFavorite,
            ),
            context,
          );
        }
        break;
      case MediaMenuAction.thumb:
        showThumb(context, audio, 500);
        break;
    }
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
    print("result is ===> ${Hive.box('favourites').containsKey(file.path)}");

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
        "isFavourite": true,
        "type": entity.type == AssetType.audio ? "audio" : "video",
      });
      AppToast.show(
        context,
        context.tr("addedToFavourite"),
        type: ToastType.success,
      );
    }

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

    final AssetEntity? newEntity = await entity.obtainForNewProperties();

    if (!mounted || newEntity == null) return;

    if (GlobalPlayer().currentEntity?.id == entity.id) {
      await GlobalPlayer().refreshCurrentEntity();
    }

    final state = context.read<AudioBloc>().state;
    if (state is AudioLoaded) {
      final listIndex = state.entities.indexWhere(
            (element) => element.id == entity.id,
      );
      if (listIndex != -1) {
        state.entities[listIndex] = newEntity;
      }
    }
    context.read<FavouriteChangeBloc>().add(FavouriteUpdated(newEntity));

    setState(() {});

    // context.read<AudioBloc>().add(LoadAudios(showLoading: false));
  }
}