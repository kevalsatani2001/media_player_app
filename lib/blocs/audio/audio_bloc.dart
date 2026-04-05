import 'package:bloc/bloc.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';

part 'audio_event.dart';

part 'audio_state.dart';

/// Android 13+ / OEM devices: explicit [requestPermissionExtend] for audio,
/// then `onlyAll`, largest album, or merged albums if the first path is empty.
Future<
    ({
      bool accessDenied,
      List<AssetEntity> entities,
      AssetPathEntity? path,
    })> _resolveAudioLibrary() async {
  final perm = await PhotoManager.requestPermissionExtend(
    requestOption: PermissionRequestOption(
      androidPermission: AndroidPermission(
        type: RequestType.fromTypes([RequestType.audio, RequestType.video]),
        mediaLocation: false,
      ),
    ),
  );
  if (!perm.hasAccess) {
    return (
      accessDenied: true,
      entities: <AssetEntity>[],
      path: null,
    );
  }

  Future<List<AssetPathEntity>> loadPaths({required bool onlyAll}) {
    return PhotoManager.getAssetPathList(
      type: RequestType.audio,
      hasAll: true,
      onlyAll: onlyAll,
    );
  }

  var paths = await loadPaths(onlyAll: true);
  if (paths.isEmpty) {
    paths = await loadPaths(onlyAll: false);
  }
  if (paths.isEmpty) {
    return (
      accessDenied: false,
      entities: <AssetEntity>[],
      path: null,
    );
  }

  var bestIdx = 0;
  var bestCount = await paths[0].assetCountAsync;
  for (var i = 1; i < paths.length; i++) {
    final c = await paths[i].assetCountAsync;
    if (c > bestCount) {
      bestCount = c;
      bestIdx = i;
    }
  }

  if (bestCount > 0) {
    final mainPath = paths[bestIdx];
    final list =
        await mainPath.getAssetListRange(start: 0, end: bestCount);
    return (accessDenied: false, entities: list, path: mainPath);
  }

  final byId = <String, AssetEntity>{};
  for (final p in paths) {
    final n = await p.assetCountAsync;
    if (n == 0) continue;
    final chunk = await p.getAssetListRange(start: 0, end: n);
    for (final e in chunk) {
      if (e.type == AssetType.audio) {
        byId[e.id] = e;
      }
    }
  }
  final merged = byId.values.toList();
  return (
    accessDenied: false,
    entities: merged,
    path: paths.first,
  );
}

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final Box box;

  AudioBloc(this.box) : super(AudioInitial()) {
    on<LoadAudios>((event, emit) async {
      final List<String> cachedIds = box.values.cast<String>().toList();
      List<AssetEntity> cachedEntities = [];

      if (cachedIds.isNotEmpty) {
        for (String id in cachedIds) {
          final entity = await AssetEntity.fromId(id);
          if (entity != null) cachedEntities.add(entity);
        }
        cachedEntities.sort((a, b) => (a.title ?? "").toLowerCase().compareTo((b.title ?? "").toLowerCase()));
      } else if (event.showLoading ?? true) {
        emit(AudioLoading());
      }

      final resolved = await _resolveAudioLibrary();

      if (resolved.accessDenied) {
        emit(const AudioError(
          'Audio access denied. Open Settings → Permissions, allow Music and audio, then tap retry.',
        ));
        return;
      }

      if (resolved.path == null || resolved.entities.isEmpty) {
        emit(const AudioError(
          'No audio files found. If you use SD card or a new folder, tap retry after files are scanned.',
        ));
        return;
      }

      final latestEntities = List<AssetEntity>.from(resolved.entities);
      latestEntities.sort((a, b) {
        String nameA = a.title ?? "";
        String nameB = b.title ?? "";
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });

      final mainPath = resolved.path!;
      final totalCount = latestEntities.length;

      await box.clear();
      await box.addAll(latestEntities.map((e) => e.id).toList());

      emit(
        AudioLoaded(
          entities: latestEntities,
          path: mainPath,
          page: 0,
          totalCount: totalCount,
          hasMore: false,
        ),
      );
    });
    on<LoadMoreAudios>(_onLoadMoreAudios);
    on<UpdateAudioItem>((event, emit) {
      if (state is AudioLoaded) {
        final currentState = state as AudioLoaded;
        List<AssetEntity> updatedList = List.from(currentState.entities);
        updatedList[event.index] = event.entity;

        emit(currentState.copyWith(entities: updatedList));
      }
    });
    on<LoadAlbums>((event, emit) async {
      final perm = await PhotoManager.requestPermissionExtend(
        requestOption: PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.fromTypes([RequestType.audio, RequestType.video]),
            mediaLocation: false,
          ),
        ),
      );
      if (!perm.hasAccess) {
        emit(AlbumsLoaded([]));
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
      emit(AlbumsLoaded(paths));
    });
  }

  Future<void> _onLoadMoreAudios(
      LoadMoreAudios event,
      Emitter<AudioState> emit,
      ) async {
    // final currentState = state;
    //
    // if (currentState is! AudioLoaded) return;
    // if (!currentState.hasMore) return;
    // if (currentState.isLoadingMore) return;
    //
    // emit(currentState.copyWith(isLoadingMore: true));
    //
    // final nextPage = currentState.page + 1;
    //
    // final newEntities = await currentState.path.getAssetListPaged(
    //   page: nextPage,
    //   size: 20,
    // );
    //
    // final allEntities = [...currentState.entities, ...newEntities];
    //
    // emit(
    //   currentState.copyWith(
    //     entities: allEntities,
    //     page: nextPage,
    //     hasMore: allEntities.length < currentState.totalCount,
    //     isLoadingMore: false,
    //   ),
    // );
  }
}




/*






 */

/*
@override
void initState() {
  super.initState();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}
 */


