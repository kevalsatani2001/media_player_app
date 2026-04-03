import 'package:on_audio_query_forked/on_audio_query.dart';
import '../utils/app_imports.dart';
import 'album_details_screen.dart';

class AudioAlbumScreen extends StatelessWidget {
  AudioAlbumScreen({super.key});

  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    context.read<AudioBloc>().add(LoadAlbums());

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
        title: AppText("Albums", fontSize: 20, fontWeight: FontWeight.w500),
      ),
      body: BlocBuilder<AudioBloc, AudioState>(
        builder: (context, state) {
          if (state is AlbumsLoaded) {
            final List<AssetPathEntity> sortedAlbums = List.from(state.albums)
              ..sort(
                    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );

            return GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 22,
                childAspectRatio: 0.76,
              ),
              itemCount: sortedAlbums.length,
              itemBuilder: (context, index) {
                final album = sortedAlbums[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlbumDetailsScreen(albumPath: album),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: FutureBuilder<List<AssetEntity>>(
                              future: album.getAssetListRange(start: 0, end: 1),
                              builder: (context, snapshot) {
                                if (snapshot.hasData &&
                                    snapshot.data!.isNotEmpty) {
                                  final firstAsset = snapshot.data!.first;
                                  final int audioId = Platform.isIOS
                                      ? firstAsset.id.hashCode
                                      : int.tryParse(firstAsset.id) ?? 0;

                                  return FutureBuilder<Uint8List?>(
                                    future: _audioQuery.queryArtwork(
                                      audioId,
                                      ArtworkType.AUDIO,
                                      format: ArtworkFormat.JPEG,
                                      size: 500,
                                    ),
                                    builder: (context, artworkSnapshot) {
                                      if (artworkSnapshot.hasData &&
                                          artworkSnapshot.data != null &&
                                          artworkSnapshot.data!.isNotEmpty) {
                                        return Image.memory(
                                          artworkSnapshot.data!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return _buildDefaultIcon(colors);
                                    },
                                  );
                                }
                                return _buildDefaultIcon(colors);
                              },
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                album.name,
                                maxLines: 1,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.blackColor,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.audiotrack_rounded,
                                    size: 14,
                                    color: colors.textFieldBorder,
                                  ),
                                  const SizedBox(width: 4),
                                  FutureBuilder<int>(
                                    future: album.assetCountAsync,
                                    builder: (context, snapshot) => AppText(
                                      "${snapshot.data ?? 0} Songs",
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: colors.textFieldBorder,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return Center(child: CustomLoader());
        },
      ),
    );
  }

  Widget _buildDefaultIcon(AppThemeColors colors) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: colors.blackColor.withOpacity(0.04),
      child: Center(
        child: Icon(
          Icons.album_rounded,
          size: 55,
          color: colors.primary.withOpacity(0.4),
        ),
      ),
    );
  }
}