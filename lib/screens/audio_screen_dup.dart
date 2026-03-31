import '../services/ads_service.dart';
import '../utils/app_imports.dart';
import 'audio_player_screen.dart';

int _audioClickCount = 0;

class AudioScreen extends StatefulWidget {
  bool isComeHomeScreen;

  AudioScreen({super.key, this.isComeHomeScreen = true});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final GlobalPlayer player = GlobalPlayer();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    // Use the global `AudioBloc` provided in `main.dart` so this screen
    // does not reload every time you navigate back.
    return widget.isComeHomeScreen
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
              color: colors.blackColor,
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
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, double val, child) =>
                  Transform.scale(scale: val, child: child),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: colors.textFieldFill,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: AppImage(
                    src: AppSvg.searchIcon,
                    color: colors.blackColor,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 15),
        ],
      ),
      body: SafeArea(
        child: GlobalPlayer().currentType == "video"
            ? Stack(
          children: [
            Column(children: [Expanded(child: _AudioBody())]),
            const SmartMiniPlayer(),
          ],
        )
            : Column(
          children: [
            Expanded(child: _AudioBody()),
            Align(
              alignment: Alignment.bottomCenter,
              child: const SmartMiniPlayer(),
            ),
          ],
        ),
      ),
    )
        : GlobalPlayer().currentType == "video"
        ? Stack(
      children: [
        Column(
          children: [
            CommonAppBar(
              title: "videMusicPlayer",
              subTitle: "mediaPlayer",
              actionWidget: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SearchScreen(),
                    ),
                  );
                },
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, double val, child) =>
                      Transform.scale(scale: val, child: child),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: colors.textFieldFill,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: AppImage(
                        src: AppSvg.searchIcon,
                        color: colors.blackColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Divider(color: colors.dividerColor),
            Expanded(child: _AudioBody()),
          ],
        ),
        const SmartMiniPlayer(),
      ],
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
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, double val, child) =>
                  Transform.scale(scale: val, child: child),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: colors.textFieldFill,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: AppImage(
                    src: AppSvg.searchIcon,
                    color: colors.blackColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        Divider(color: colors.dividerColor),
        Expanded(child: _AudioBody()),
        Align(
          alignment: Alignment.bottomCenter,
          child: const SmartMiniPlayer(),
        ),
      ],
    );
  }
}

class _AudioBody extends StatefulWidget {
  const _AudioBody();

  @override
  State<_AudioBody> createState() => _AudioBodyState();
}


class _AudioBodyState extends State<_AudioBody>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  String _selectedLetter = '';

  final Map<String, int> _letterIndices = {};

  final double _itemHeight = 80.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _getAlphabetList(List<AssetEntity> entities) {
    Set<String> letters = {};
    for (var entity in entities) {
      String name = entity.title ?? "";
      if (name.isEmpty) name = entity.id;

      if (name.isNotEmpty) {
        String firstChar = name[0].toUpperCase();
        if (RegExp(r'^\p{L}', unicode: true).hasMatch(firstChar)) {
          letters.add(firstChar);
        } else {
          letters.add('#');
        }
      }
    }
    List<String> sortedLetters = letters.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });
    return sortedLetters;
  }

  void _scrollToLetter(String letter) {
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

      setState(() {
        _selectedLetter = letter;
      });
    }
  }

  void _calculateLetterIndices(List<AssetEntity> entities, int adInterval) {
    _letterIndices.clear();
    String currentProcessedLetter = '';

    for (int i = 0; i < entities.length; i++) {
      final audio = entities[i];
      String name = audio.title ?? "";
      String firstChar = name.isNotEmpty ? name[0].toUpperCase() : '#';
      String letter = RegExp(r'^\p{L}', unicode: true).hasMatch(firstChar) ? firstChar : '#';

      if (letter != currentProcessedLetter) {
        currentProcessedLetter = letter;

        int adOffset = i ~/ adInterval;
        int actualUiIndex = i + adOffset;

        _letterIndices[letter] = actualUiIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {
        List<AssetEntity> entities = [];

        if (state is AudioLoading) {
          return Center(child: CustomLoader());
        } else if (state is AudioLoaded) {
          entities = List.from(state.entities);
          entities.sort((a, b) => (a.title ?? "")
              .toLowerCase()
              .compareTo((b.title ?? "").toLowerCase()));
        } else if (state is AudioError) {
          return Center(child: Text(state.message));
        }

        if (entities.isEmpty) return const SizedBox();

        const int adInterval = 5;
        final alphabetList = _getAlphabetList(entities);

        _calculateLetterIndices(entities, adInterval);

        return Stack(
          children: [
            _buildAudioList(entities, adInterval),

            // Alphabet Sidebar
            Positioned(
              right: 6,
              top: 50,
              bottom: 100,
              child: Center(
                child: Container(
                  width: 24,
                  decoration: BoxDecoration(
                    color: colors.blackColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: alphabetList.map((letter) {
                        bool isActive = _selectedLetter == letter;
                        return GestureDetector(
                          onTap: () => _scrollToLetter(letter),
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
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w500,
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
            )
          ],
        );
      },
    );
  }

  Widget _buildAudioList(List<AssetEntity> entities, int adInterval) {
    int adCount = entities.length ~/ adInterval;
    if (entities.isNotEmpty && entities.length < adInterval) {
      adCount = 1;
    }
    int totalCount = entities.length + adCount + 1;

    return AnimationLimiter(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: totalCount,
        itemBuilder: (context, index) {
          final colors = Theme.of(context).extension<AppThemeColors>()!;

          if (index == totalCount - 1) {
            return const SizedBox(height: 100);
          }

          bool isAdPosition =
          (index != 0 && (index + 1) % (adInterval + 1) == 0);
          bool isLastAdForSmallList =
          (entities.length < adInterval && index == entities.length);

          if (isAdPosition || isLastAdForSmallList) {
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
                      if (!snapshot.hasData) {
                        return ListTile(
                          leading: Icon(
                            Icons.music_note,
                            color: colors.blackColor,
                          ),
                          title: AppText("loading"),
                        );
                      }
                      final file = snapshot.data!;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7.5),
                        child: GestureDetector(
                          onTap: () => _handleOnTap(entities, audio, file),
                          child: Container(
                            padding: const EdgeInsets.only(
                                top: 10, left: 10, bottom: 10),
                            decoration: BoxDecoration(
                              color: colors.cardBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: isCurrentPlaying
                                  ? Border.all(
                                  color: colors.primary, width: 0.5)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                _buildLeadingIcon(
                                    audio, colors, isCurrentPlaying),
                                const SizedBox(width: 12),
                                _buildTitleAndDuration(audio, file, colors),
                                _buildPopupMenu(audio, index),
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

  void _handleOnTap(List<AssetEntity> entities, AssetEntity audio, File file) {

    void openAudioPlayer() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AudioPlayerScreen(
            entityList: entities,
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
      ).then((_) {
        if (mounted) {
          context.read<AudioBloc>().add(LoadAudios(showLoading: false));
        }
      });
    }

    _audioClickCount++;

    if (_audioClickCount % 4 == 0) {
      debugPrint("Showing Interstitial Ad before audio player...");

      AdHelper.showInterstitialAd(() {
        openAudioPlayer();
      });
    } else {
      openAudioPlayer();
    }
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          AppImage(
            src: AppSvg.musicUnselected,
            height: 22,
            color: colors.whiteColor,
          ),
          if (isPlaying)
            AppImage(
              src: GlobalPlayer().isPlaying
                  ? AppSvg.playerPause
                  : AppSvg.playerResume,
              height: 18,
            ),
        ],
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

  Widget _buildPopupMenu(AssetEntity audio, int index) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return PopupMenuButton<MediaMenuAction>(
      elevation: 15,
      color: colors.dropdownBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.black.withOpacity(0.60),
      offset: Offset(0, 0),
      // splashRadius: 15,
      icon: AppImage(src: AppSvg.dropDownMenuDot, color: colors.blackColor),
      menuPadding: EdgeInsets.symmetric(horizontal: 10),
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

  void handleMenuAction(
      BuildContext context,
      AssetEntity audio,
      MediaMenuAction action,
      int index,
      ) async
  {
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
    context.read<AudioBloc>().add(LoadAudios(showLoading: false));

    setState(() {});
  }
}
/*
AudioPlayerScreen(
          entity: player.currentEntity!,
          // item: player.currentMediaItem!,
          index: player.currentIndex,
          entityList: const [], item: player.currentMediaItem!,
        )
 */









// import '../services/ads_service.dart';
// import '../utils/app_imports.dart';
// import 'audio_player_screen.dart';
//
// int _audioClickCount = 0;
//
// class AudioScreen extends StatefulWidget {
//   bool isComeHomeScreen;
//
//   AudioScreen({super.key, this.isComeHomeScreen = true});
//
//   @override
//   State<AudioScreen> createState() => _AudioScreenState();
// }
//
// class _AudioScreenState extends State<AudioScreen> {
//   final ScrollController _scrollController = ScrollController();
//   final GlobalPlayer player = GlobalPlayer();
//
//   @override
//   void initState() {
//     super.initState();
//
//     _scrollController.addListener(() {
//       if (_scrollController.position.pixels >=
//           _scrollController.position.maxScrollExtent - 200) {
//         context.read<AudioBloc>().add(LoadMoreAudios());
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final colors = Theme.of(context).extension<AppThemeColors>()!;
//     final box = Hive.box('audios');
//
//     return BlocProvider(
//       create: (_) => AudioBloc(box)..add(LoadAudios()),
//       child: widget.isComeHomeScreen
//           ? Scaffold(
//         appBar: AppBar(
//           leading: Padding(
//             padding: const EdgeInsets.all(16),
//             child: GestureDetector(
//               onTap: () => Navigator.pop(context),
//               child: AppImage(
//                 src: AppSvg.backArrowIcon,
//                 height: 20,
//                 width: 20,
//                 color: colors.blackColor,
//               ),
//             ),
//           ),
//           centerTitle: true,
//           title: AppText(
//             "audio",
//             fontSize: 20,
//             fontWeight: FontWeight.w500,
//           ),
//
//           actions: [
//             GestureDetector(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const SearchScreen()),
//                 );
//               },
//               child: TweenAnimationBuilder(
//                 tween: Tween<double>(begin: 0.8, end: 1.0),
//                 duration: const Duration(milliseconds: 500),
//                 builder: (context, double val, child) =>
//                     Transform.scale(scale: val, child: child),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8),
//                     color: colors.textFieldFill,
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(8),
//                     child: AppImage(
//                       src: AppSvg.searchIcon,
//                       color: colors.blackColor,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(width: 15),
//           ],
//         ),
//         body: SafeArea(
//           child: GlobalPlayer().currentType == "video"
//               ? Stack(
//             children: [
//               Column(children: [Expanded(child: _AudioBody())]),
//               const SmartMiniPlayer(),
//             ],
//           )
//               : Column(
//             children: [
//               Expanded(child: _AudioBody()),
//               Align(
//                 alignment: Alignment.bottomCenter,
//                 child: const SmartMiniPlayer(),
//               ),
//             ],
//           ),
//         ),
//
//         // floatingActionButton: FloatingActionButton(
//         //   onPressed: () => context.read<AudioBloc>().add(LoadAudios()),
//         //   child: const Icon(Icons.refresh),
//         // ),
//       )
//           : GlobalPlayer().currentType == "video"
//           ? Stack(
//         children: [
//           Column(
//             children: [
//               CommonAppBar(
//                 title: "videMusicPlayer",
//                 subTitle: "mediaPlayer",
//                 actionWidget: GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const SearchScreen(),
//                       ),
//                     );
//                   },
//                   child: TweenAnimationBuilder(
//                     tween: Tween<double>(begin: 0.8, end: 1.0),
//                     duration: const Duration(milliseconds: 500),
//                     builder: (context, double val, child) =>
//                         Transform.scale(scale: val, child: child),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                         color: colors.textFieldFill,
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(8),
//                         child: AppImage(
//                           src: AppSvg.searchIcon,
//                           color: colors.blackColor,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               Divider(color: colors.dividerColor),
//               Expanded(child: _AudioBody()),
//             ],
//           ),
//           const SmartMiniPlayer(),
//         ],
//       )
//           : Column(
//         children: [
//           CommonAppBar(
//             title: "videMusicPlayer",
//             subTitle: "mediaPlayer",
//             actionWidget: GestureDetector(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const SearchScreen()),
//                 );
//               },
//               child: TweenAnimationBuilder(
//                 tween: Tween<double>(begin: 0.8, end: 1.0),
//                 duration: const Duration(milliseconds: 500),
//                 builder: (context, double val, child) =>
//                     Transform.scale(scale: val, child: child),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8),
//                     color: colors.textFieldFill,
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(8),
//                     child: AppImage(
//                       src: AppSvg.searchIcon,
//                       color: colors.blackColor,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Divider(color: colors.dividerColor),
//           Expanded(child: _AudioBody()),
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: const SmartMiniPlayer(),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _AudioBody extends StatefulWidget {
//   const _AudioBody();
//
//   @override
//   State<_AudioBody> createState() => _AudioBodyState();
// }
//
//
// class _AudioBodyState extends State<_AudioBody>
//     with AutomaticKeepAliveClientMixin {
//   final ScrollController _scrollController = ScrollController();
//
//   @override
//   bool get wantKeepAlive => true;
//
//   // @override
//   // void initState() {
//   //   super.initState();
//   //   _scrollController.addListener(() {
//   //     if (_scrollController.position.pixels >=
//   //         _scrollController.position.maxScrollExtent - 200) {
//   //       context.read<AudioBloc>().add(LoadMoreAudios());
//   //     }
//   //   });
//   // }
//
//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_onScroll); // àª…àª¹à«€àª‚ àª®à«‡àª¥àª¡ àªàªŸà«‡àªš àª•àª°à«‹
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   List<String> _getAlphabetList(List<AssetEntity> entities) {
//     Set<String> letters = {};
//     for (var entity in entities) {
//       String name = entity.title ?? "";
//       if (name.isEmpty) {
//         // àªœà«‹ àªŸàª¾àªˆàªŸàª² àª¨ àª¹à«‹àª¯ àª¤à«‹ àªªàª¾àª¥ àªªàª°àª¥à«€ àª¨àª¾àª® àª²à«‹
//         name = entity.id; // àª…àª¥àªµàª¾ àª¤àª®àª¾àª°à«€ àªªàª¾àª¸à«‡ àªœà«‡ àª°à«€àª¤à«‡ àª¨àª¾àª® àª†àªµàª¤à«àª‚ àª¹à«‹àª¯
//       }
//
//       if (name.isNotEmpty) {
//         String firstChar = name[0].toUpperCase();
//         if (RegExp(r'^[A-Z]').hasMatch(firstChar)) {
//           letters.add(firstChar);
//         } else {
//           letters.add('#');
//         }
//       }
//     }
//     List<String> sortedLetters = letters.toList()..sort((a, b) {
//       if (a == '#') return 1;
//       if (b == '#') return -1;
//       return a.compareTo(b);
//     });
//     return sortedLetters;
//   }
//
//   void _scrollToLetter(String letter, List<AssetEntity> entities) {
//     int targetIndex = -1;
//     for (int i = 0; i < entities.length; i++) {
//       String name = entities[i].title ?? "";
//       if (name.isNotEmpty && name[0].toUpperCase() == letter) {
//         targetIndex = i;
//         break;
//       }
//     }
//
//     if (targetIndex != -1) {
//       // Audio list item height àª…àª‚àª¦àª¾àªœà«‡ 75-80 àª›à«‡
//       double itemHeight = 75.0;
//       // Ads àª…àª¨à«‡ Padding àª§à«àª¯àª¾àª¨àª®àª¾àª‚ àª²à«‡àª¤àª¾ àª…àª‚àª¦àª¾àªœàª¿àª¤ àª“àª«àª¸à«‡àªŸ
//       double offset = targetIndex * itemHeight;
//
//       _scrollController.animateTo(
//         offset,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//
//       setState(() {
//         _selectedLetter = letter;
//       });
//     }
//   }
//
//   String _selectedLetter = ''; // àª†àª¨à«‡ àª¸à«àªŸà«‡àªŸàª®àª¾àª‚ àª‰àªªàª° àªœàª¾àª¹à«‡àª° àª•àª°àªœà«‹
//
//
//
//   void _onScroll() {
//     /*
//     if (_scrollController.position.pixels >=
//           _scrollController.position.maxScrollExtent - 200) {
//         context.read<AudioBloc>().add(LoadMoreAudios());
//       }
//      */
//     // --- 1. LOAD MORE LOGIC ---
//     if (_scrollController.position.extentAfter < 500) {
//       try {
//         final state = context.read<AudioBloc>().state;
//         if (state is AudioLoaded && state.hasMore) {
//           context.read<AudioBloc>().add(LoadMoreAudios());
//         }
//       } catch (e) {
//         debugPrint("Error in scroll: $e");
//       }
//     }
//
//     // --- 2. AUTO SELECT LETTER LOGIC ---
//     final state = context.read<AudioBloc>().state;
//     if (state is AudioLoaded) {
//       double currentOffset = _scrollController.offset;
//
//       // àª“àª¡àª¿àª¯à«‹ àª²àª¿àª¸à«àªŸ àª†àªˆàªŸàª®àª¨à«€ àª…àª‚àª¦àª¾àªœàª¿àª¤ àª¹àª¾àªˆàªŸ (Padding àª…àª¨à«‡ Margin àª¸àª¾àª¥à«‡)
//       // ListTile + Padding = àª…àª‚àª¦àª¾àªœà«‡ 75.0 àª¥à«€ 80.0
//       double itemHeight = 75.0;
//
//       // àª…àª¤à«àª¯àª¾àª°à«‡ àª•àª¯àª¾ àª‡àª¨à«àª¡à«‡àª•à«àª¸ àªªàª° àª¯à«àªàª° àª›à«‡ àª¤à«‡ àª¶à«‹àª§à«‹
//       int currentIndex = (currentOffset / itemHeight).floor();
//
//       // àª°à«‡àª¨à«àªœ àªšà«‡àª•
//       if (currentIndex >= 0 && currentIndex < state.entities.length) {
//         final entity = state.entities[currentIndex];
//
//         // àª¨àª¾àª® àª®à«‡àª³àªµà«‹ (title àª…àª¥àªµàª¾ àª«àª¾àªˆàª² àª¨à«‡àª®)
//         String name = entity.title ?? "";
//
//         if (name.isNotEmpty) {
//           String firstChar = name[0].toUpperCase();
//           String currentLetter = RegExp(r'^[A-Z]').hasMatch(firstChar) ? firstChar : '#';
//
//           // àªªàª°àª«à«‹àª°à«àª®àª¨à«àª¸ àª®àª¾àªŸà«‡: àªœà«‹ àª…àª•à«àª·àª° àª¬àª¦àª²àª¾àª¯ àª¤à«‹ àªœ àª¸à«àªŸà«‡àªŸ àª…àªªàª¡à«‡àªŸ àª•àª°à«‹
//           if (_selectedLetter != currentLetter) {
//             setState(() {
//               _selectedLetter = currentLetter;
//             });
//           }
//         }
//       }
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     final colors = Theme.of(context).extension<AppThemeColors>()!;
//
//     return BlocBuilder<AudioBloc, AudioState>(
//       builder: (context, state) {
//         List<AssetEntity> entities = [];
//
//         if (state is AudioLoading) {
//           return Center(child: CustomLoader());
//         } else if (state is AudioLoaded) {
//           entities = List.from(state.entities);
//           // 1. A to Z àª¸à«‹àª°à«àªŸàª¿àª‚àª—
//           entities.sort((a, b) => (a.title ?? "").toLowerCase().compareTo((b.title ?? "").toLowerCase()));
//         } else if (state is AudioError) {
//           return Center(child: Text(state.message));
//         }
//
//         if (entities.isEmpty) return const SizedBox();
//
//         final alphabetList = _getAlphabetList(entities);
//
//         return Stack(
//           children: [
//             // àª®à«‡àªˆàª¨ àª“àª¡àª¿àª¯à«‹ àª²àª¿àª¸à«àªŸ
//             _buildAudioList(entities),
//
//             // 2. Alphabet Sidebar
//             Positioned(
//               right: 5,
//               top: 50,
//               bottom: 120, // MiniPlayer àª®àª¾àªŸà«‡ àªœàª—à«àª¯àª¾ àª›à«‹àª¡àªµàª¾
//               child: Container(
//                 width: 30,
//                 decoration: BoxDecoration(
//                   color: colors.blackColor.withOpacity(0.05),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: LayoutBuilder(
//                   builder: (context, constraints) {
//                     return FittedBox(
//                       fit: BoxFit.contain,
//                       child: IntrinsicWidth(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: alphabetList.map((letter) {
//                             bool isActive = _selectedLetter == letter;
//                             return GestureDetector(
//                               onTap: () => _scrollToLetter(letter, entities),
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   color: isActive ? colors.primary.withOpacity(0.2) : Colors.transparent,
//                                 ),
//                                 child: Text(
//                                   letter,
//                                   style: TextStyle(
//                                     fontSize: isActive ? 16 : 12,
//                                     fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//                                     color: isActive ? colors.primary : colors.blackColor.withOpacity(0.5),
//                                   ),
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildAudioList(List<AssetEntity> entities) {
//     const int adInterval = 5;
//
//
//     int adCount = entities.length ~/ adInterval;
//
//     if (entities.isNotEmpty && entities.length < adInterval) {
//       adCount = 1;
//     }
//
//     int totalCount = entities.length + adCount + 1;
//
//     return AnimationLimiter(
//       child: ListView.builder(
//         controller: _scrollController,
//
//         itemCount: totalCount,
//         // itemCount: entities.length,
//         itemBuilder: (context, index) {
//           final colors = Theme.of(context).extension<AppThemeColors>()!;
//
//           if (index == totalCount - 1) {
//             return const SizedBox(height: 100);
//           }
//
//           bool isAdPosition =
//           (index != 0 && (index + 1) % (adInterval + 1) == 0);
//           bool isLastAdForSmallList =
//           (entities.length < adInterval && index == entities.length);
//
//           if (isAdPosition || isLastAdForSmallList) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 10),
//               child: AdHelper.bannerAdWidget(size: AdSize.banner),
//             );
//           }
//
//
//           final int actualIndex = index - (index ~/ (adInterval + 1));
//
//           if (actualIndex >= entities.length) return const SizedBox.shrink();
//
//           final audio = entities[actualIndex];
//           return Consumer<GlobalPlayer>(
//             builder: (context, player, child) {
//               final bool isCurrentPlaying =
//                   player.currentEntity?.id == audio.id;
//
//               return Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 15),
//                 child: AppTransition(
//                   index: index,
//                   child: FutureBuilder<File?>(
//                     future: audio.file,
//                     builder: (context, snapshot) {
//                       if (!snapshot.hasData) {
//                         return ListTile(
//                           leading: Icon(
//                             Icons.music_note,
//                             color: colors.blackColor,
//                           ),
//                           title: AppText("loading"),
//                         );
//                       }
//                       final file = snapshot.data!;
//
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 7.5),
//                         child: GestureDetector(
//                           onTap: () => _handleOnTap(entities, audio, file),
//                           child: Container(
//                             padding: const EdgeInsets.only(
//                               top: 10,
//                               left: 10,
//                               bottom: 10,
//                             ),
//                             decoration: BoxDecoration(
//                               color: colors.cardBackground,
//                               borderRadius: BorderRadius.circular(10),
//                               border: isCurrentPlaying
//                                   ? Border.all(
//                                 color: colors.primary,
//                                 width: 0.5,
//                               )
//                                   : null,
//                             ),
//                             child: Row(
//                               children: [
//                                 _buildLeadingIcon(
//                                   audio,
//                                   colors,
//                                   isCurrentPlaying,
//                                 ),
//                                 const SizedBox(width: 12),
//                                 _buildTitleAndDuration(audio, file, colors),
//                                 _buildPopupMenu(audio, index),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   void _handleOnTap(List<AssetEntity> entities, AssetEntity audio, File file) {
//
//     void openAudioPlayer() {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => AudioPlayerScreen(
//             entityList: entities,
//             entity: audio,
//             item: MediaItem(
//               isFavourite: audio.isFavorite,
//               id: audio.id,
//               path: file.path,
//               isNetwork: false,
//               type: 'audio',
//             ),
//           ),
//         ),
//       ).then((_) {
//         if (mounted) {
//           context.read<AudioBloc>().add(LoadAudios(showLoading: false));
//         }
//       });
//     }
//
//     _audioClickCount++;
//
//     if (_audioClickCount % 4 == 0) {
//       debugPrint("Showing Interstitial Ad before audio player...");
//
//       AdHelper.showInterstitialAd(() {
//         openAudioPlayer();
//       });
//     } else {
//       openAudioPlayer();
//     }
//   }
//
//   Widget _buildLeadingIcon(
//       AssetEntity audio,
//       AppThemeColors colors,
//       bool isPlaying,
//       ) {
//     return Container(
//       height: 50,
//       width: 50,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(10),
//         color: colors.blackColor.withOpacity(0.38),
//       ),
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           AppImage(
//             src: AppSvg.musicUnselected,
//             height: 22,
//             color: colors.whiteColor,
//           ),
//           if (isPlaying)
//             AppImage(
//               src: GlobalPlayer().isPlaying
//                   ? AppSvg.playerPause
//                   : AppSvg.playerResume,
//               height: 18,
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTitleAndDuration(
//       AssetEntity audio,
//       File file,
//       AppThemeColors colors,
//       ) {
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           AppText(
//             file.path.split('/').last,
//             maxLines: 1,
//             fontSize: 15,
//             fontWeight: FontWeight.w500,
//           ),
//           const SizedBox(height: 6),
//           AppText(
//             formatDuration(audio.duration),
//             fontSize: 13,
//             color: colors.textFieldBorder,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPopupMenu(AssetEntity audio, int index) {
//     final colors = Theme.of(context).extension<AppThemeColors>()!;
//     return PopupMenuButton<MediaMenuAction>(
//       elevation: 15,
//       color: colors.dropdownBg,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       shadowColor: Colors.black.withOpacity(0.60),
//       offset: Offset(0, 0),
//       // splashRadius: 15,
//       icon: AppImage(src: AppSvg.dropDownMenuDot, color: colors.blackColor),
//       menuPadding: EdgeInsets.symmetric(horizontal: 10),
//       onSelected: (action) => handleMenuAction(context, audio, action, index),
//       itemBuilder: (context) => [
//         _buildPopupItem(
//           MediaMenuAction.addToFavourite,
//           audio.isFavorite ? 'removeToFavourite' : 'addToFavourite',
//         ),
//         const PopupMenuDivider(height: 0.5),
//         _buildPopupItem(MediaMenuAction.delete, 'delete'),
//         const PopupMenuDivider(height: 0.5),
//         _buildPopupItem(MediaMenuAction.share, 'share'),
//         const PopupMenuDivider(height: 0.5),
//         _buildPopupItem(MediaMenuAction.detail, 'showDetail'),
//         const PopupMenuDivider(height: 0.5),
//         _buildPopupItem(MediaMenuAction.addToPlaylist, 'addToPlaylist'),
//       ],
//     );
//   }
//
//   PopupMenuItem<MediaMenuAction> _buildPopupItem(
//       MediaMenuAction action,
//       String title,
//       ) {
//     return PopupMenuItem(
//       value: action,
//       child: Center(child: AppText(title, fontSize: 12)),
//     );
//   }
//
//   void handleMenuAction(
//       BuildContext context,
//       AssetEntity audio,
//       MediaMenuAction action,
//       int index,
//       ) async
//   {
//     switch (action) {
//       case MediaMenuAction.detail:
//         routeToDetailPage(context, audio);
//         break;
//       case MediaMenuAction.info:
//         showInfoDialog(context, audio);
//         break;
//       case MediaMenuAction.share:
//         shareItem(context, audio);
//         break;
//       case MediaMenuAction.delete:
//         deleteCurrentItem(context, audio);
//         break;
//       case MediaMenuAction.addToFavourite:
//         await _toggleFavourite(context, audio, index);
//         break;
//       case MediaMenuAction.addToPlaylist:
//         final file = await audio.file;
//         if (file != null) {
//           addToPlaylist(
//             MediaItem(
//               path: file.path,
//               isNetwork: false,
//               type: "audio",
//               id: audio.id,
//               isFavourite: audio.isFavorite,
//             ),
//             context,
//           );
//         }
//         break;
//       case MediaMenuAction.thumb:
//         showThumb(context, audio, 500);
//         break;
//     }
//   }
//
//   Future<void> _toggleFavourite(
//       BuildContext context,
//       AssetEntity entity,
//       int index,
//       ) async {
//     final favBox = Hive.box('favourites');
//     final bool isFavorite = entity.isFavorite;
//
//     final file = await entity.file;
//     if (file == null) return;
//
//     final key = file.path;
//
//     if (isFavorite) {
//       favBox.delete(key);
//       AppToast.show(
//         context,
//         context.tr("removedFromFavourites"),
//         type: ToastType.info,
//       );
//     } else {
//       favBox.put(key, {
//         "id": entity.id,
//         "path": file.path,
//         "isNetwork": false,
//         "isFavourite": isFavorite,
//         "type": entity.type == AssetType.audio ? "audio" : "video",
//       });
//       AppToast.show(
//         context,
//         context.tr("addedToFavourite"),
//         type: ToastType.success,
//       );
//     }
//
//     if (PlatformUtils.isOhos) {
//       await PhotoManager.editor.ohos.favoriteAsset(
//         entity: entity,
//         favorite: !isFavorite,
//       );
//     } else if (Platform.isAndroid) {
//       await PhotoManager.editor.android.favoriteAsset(
//         entity: entity,
//         favorite: !isFavorite,
//       );
//     } else {
//       await PhotoManager.editor.darwin.favoriteAsset(
//         entity: entity,
//         favorite: !isFavorite,
//       );
//     }
//
//     final AssetEntity? newEntity = await entity.obtainForNewProperties();
//     if (!mounted || newEntity == null) return;
//     if (GlobalPlayer().currentEntity?.id == entity.id) {
//       await GlobalPlayer().refreshCurrentEntity();
//     }
//     context.read<AudioBloc>().add(LoadAudios(showLoading: false));
//
//     setState(() {});
//   }
// }