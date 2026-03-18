import '../services/ads_service.dart';
import '../utils/app_imports.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final box = Hive.box('favourites');

    return BlocProvider(
      create: (_) => FavouriteBloc(box)..add(LoadFavourite()),
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20,color: colors.blackColor,),
            ),
          ),
          centerTitle: true,
          title: AppText(
            "favourite",
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        // àª…àª¹àª¿àª¯àª¾àª‚ àª¨à«€àªšà«‡ àª¬à«‡àª¨àª° àªàª¡ àª‰àª®à«‡àª°à«‹
        bottomNavigationBar: SizedBox(
          height: 60, // àªàª¡àª¨à«€ àª¹àª¾àªˆàªŸ àª®à«àªœàª¬
          child: AdHelper.bannerAdWidget(),
        ),
        body: BlocBuilder<FavouriteBloc, FavouriteState>(
          builder: (context, state) {

            if (state is FavouriteLoading) {
              return Center(child: CustomLoader());
            }

            if (state is FavouriteError) {
              return Center(child: Text(state.message));
            }

            if (state is FavouriteLoaded) {
              if (state.entities.isEmpty) {
                return Center(
                  child: Text(
                    "${context.tr("noFavouriteYet")}\n${context.tr("addSomeVideosOrAudio")}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return _FavouriteGrid(state: state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _FavouriteGrid extends StatelessWidget {
  final FavouriteLoaded state;
  final int adInterval = 5; // àª¦àª° 5 àª†àªˆàªŸàª® àªªàª›à«€ àªàª¡ àª¬àª¤àª¾àªµàªµà«€

  const _FavouriteGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final entities = state.entities;

    // àªœà«‹ àª¡à«‡àªŸàª¾ 5 àª¥à«€ àª“àª›à«‹ àª¹à«‹àª¯ àª¤à«‹ àªªàª£ 1 àªàª¡ àª¬àª¤àª¾àªµàªµàª¾ àª®àª¾àªŸà«‡:
    int adCount = (entities.length ~/ adInterval);
    if (entities.length > 0 && entities.length < adInterval) {
      adCount = 1; // 5 àª¥à«€ àª“àª›à«€ àª†àªˆàªŸàª® àª¹à«‹àª¯ àª¤à«‹ àªªàª£ 1 àªàª¡ àª‰àª®à«‡àª°àªµà«€
    }

    final int totalItemCount = entities.length + adCount;
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 15,
        childAspectRatio: 1.05,
      ),
      itemCount: totalItemCount,
      itemBuilder: (context, index) {

        // àªœà«‹ àª† àª‡àª¨à«àª¡à«‡àª•à«àª¸ àªàª¡ àª®àª¾àªŸà«‡ àª¹à«‹àª¯
        if ((entities.length < adInterval && index == entities.length)||(index + 1) % (adInterval + 1) == 0) {
          // àª…àª¹àª¿àª¯àª¾àª‚ àª¤àª®àª¾àª°à«àª‚ Native Ad àªµàª¿àªœà«‡àªŸ àª…àª¥àªµàª¾ Banner Ad àª¬àª¤àª¾àªµà«‹
          return Container(
            decoration: BoxDecoration(
              color: Colors.white, // àªàª¡ àªªàª¾àª›àª³ àªµà«àª¹àª¾àª‡àªŸ àª¬à«‡àª•àª—à«àª°àª¾àª‰àª¨à«àª¡ àª¸àª¾àª°à«àª‚ àª²àª¾àª—àª¶à«‡
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)), // àª†àª‰àªŸàª²àª¾àª‡àª¨
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain, // àª† àªàª¡àª¨à«‡ àª¬à«‹àª•à«àª¸àª®àª¾àª‚ àª«àª¿àªŸ àª•àª°àª¶à«‡
                  child: AdHelper.bannerAdWidget(size: AdSize.mediumRectangle),
                ),
              ),
            ),
          );
        }

        // àª…àª¸àª²à«€ àª¡à«‡àªŸàª¾àª¨à«‹ àª‡àª¨à«àª¡à«‡àª•à«àª¸ àª¶à«‹àª§à«‹
        final int actualDataIndex = index - (index ~/ (adInterval + 1));

        if (actualDataIndex >= entities.length) return const SizedBox.shrink();

        final entity = entities[actualDataIndex];
        if (actualDataIndex == entities.length - 8 && state.hasMore) {
          context.read<FavouriteBloc>().add(LoadMoreFavourites());
        }


        return GestureDetector(
          onTap: () async{
            final List<AssetEntity> validEntities = entities
                .whereType<AssetEntity>()
                .toList();

            final int actualIndex = validEntities.indexOf(
              entities[index] as AssetEntity,
            );
            print("index is ===> $actualIndex");
            print("index is ===> ${validEntities.length}");

            if (actualIndex != -1) {

              _navigateToPlayer(context, validEntities, actualIndex);
            }
          },
          child: _FavouriteItem(
            entity:entity,
            index: actualDataIndex,
            entityList: entities,
          ),
        );
      },
    );
  }

  void _navigateToPlayer(
      BuildContext context,
      List<AssetEntity> allEntities,
      int currentIndex,
      ) async {

    // àª«àª‚àª•à«àª¶àª¨ àªœà«‡ àª¨à«‡àªµàª¿àª—à«‡àª¶àª¨ àª¹à«‡àª¨à«àª¡àª² àª•àª°àª¶à«‡
    void moveNext() async {
      final entity = allEntities[currentIndex];
      final file = await entity.file;

      if (file == null || !file.existsSync()) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            entity: entity,
            // item: MediaItem(
            //   isFavourite: entity.isFavorite,
            //   id: entity.id,
            //   path: file.path,
            //   isNetwork: false,
            //   type: entity.type == AssetType.audio ? "audio" : "video",
            // ),
            index: currentIndex,
            entityList: allEntities,
          ),
        ),
      ).then((value) {
        context.read<FavouriteBloc>().add(LoadFavourite());
      });
    }

    // àªªàª¹à«‡àª²àª¾ àªàª¡ àª¬àª¤àª¾àªµà«‹, àªàª¡ àª¬àª‚àª§ àª¥àª¾àª¯ àªªàª›à«€ àªœ 'moveNext' àª°àª¨ àª¥àª¶à«‡
    AdHelper.showInterstitialAd(() {
      moveNext();
    });
  }
}

class _FavouriteItem extends StatelessWidget {
  final AssetEntity entity;
  List<AssetEntity> entityList;
  final int index;

  _FavouriteItem({
    required this.entity,
    required this.index,
    required this.entityList,
  });

  ThumbnailOption get _thumbOption =>
      const ThumbnailOption(size: ThumbnailSize.square(150));

  @override
  Widget build(BuildContext context) {
    return ImageItemWidget(
      key: ValueKey(entity.id),
      entity: entity,
      option: _thumbOption,
      onMenuSelected: (action) async {
        switch (action) {
          case MediaMenuAction.detail:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailPage(entity: entity)),
            );
            break;

          case MediaMenuAction.info:
            showInfoDialog(context, entity);
            break;

          case MediaMenuAction.thumb:
            _showThumb(context, entity);
            break;

          case MediaMenuAction.share:
            _share(entity);
            break;

          case MediaMenuAction.delete:
          // optional: implement delete via Bloc later
            break;

          case MediaMenuAction.addToFavourite:
            context.read<FavouriteBloc>().add(ToggleFavourite(entity, index));
            break;
          case MediaMenuAction.addToPlaylist:
            final file = await entity.file;
            addToPlaylist(
              MediaItem(
                path: file!.path,
                isNetwork: false,
                type: entity.type == AssetType.audio ? "audio" : "video",
                id: entity.id,
                isFavourite: entity.isFavorite,
              ),
              context,
            );
            break;
        }
      },
      onTap: null,
    );
  }
}

Future<void> _share(AssetEntity entity) async {
  final file = await entity.file;
  if (file == null) return;
  Share.shareXFiles([XFile(file.path)], text: entity.title);
}

Future<void> _showThumb(BuildContext context, AssetEntity entity) {
  return showDialog(
    context: context,
    builder: (_) => FutureBuilder<Uint8List?>(
      future: entity.thumbnailDataWithOption(
        const ThumbnailOption(size: ThumbnailSize.square(150)),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.memory(snapshot.data!),
          );
        }
        return Center(child: CustomLoader());
      },
    ),
  );
}