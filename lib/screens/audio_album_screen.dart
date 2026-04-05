import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:photo_manager/photo_manager.dart';

import '../utils/app_imports.dart';
import 'album_details_screen.dart';

/// Loads album paths locally so opening this screen does not replace
/// [AudioBloc] state (which would break the main Audio tab list).
class AudioAlbumScreen extends StatefulWidget {
  const AudioAlbumScreen({super.key});

  @override
  State<AudioAlbumScreen> createState() => _AudioAlbumScreenState();
}

class _AudioAlbumScreenState extends State<AudioAlbumScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<AssetPathEntity> _albums = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    try {
      final perm = await PhotoManager.requestPermissionExtend(
        requestOption: PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.fromTypes([RequestType.audio, RequestType.video]),
            mediaLocation: false,
          ),
        ),
      );
      if (!perm.hasAccess) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error =
              'Media access denied. Allow Music & audio in Settings, then retry.';
        });
        return;
      }

      var paths = await PhotoManager.getAssetPathList(
        type: RequestType.audio,
        hasAll: true,
        onlyAll: false,
      );
      if (paths.isEmpty) {
        paths = await PhotoManager.getAssetPathList(
          type: RequestType.audio,
          hasAll: true,
          onlyAll: true,
        );
      }

      if (!mounted) return;
      setState(() {
        _albums = List.from(paths)
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
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
        title: AppText("Albums", fontSize: 20, fontWeight: FontWeight.w500),
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(AppThemeColors colors) {
    if (_loading) {
      return const Center(child: CustomLoader());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadAlbums();
                },
                icon: const Icon(Icons.refresh),
                label: AppText('retry', fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }
    if (_albums.isEmpty) {
      return Center(
        child: AppText(
          'noResultFound',
          fontSize: 15,
          color: colors.blackColor.withOpacity(0.6),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 18,
        mainAxisSpacing: 22,
        childAspectRatio: 0.76,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];

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
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
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
