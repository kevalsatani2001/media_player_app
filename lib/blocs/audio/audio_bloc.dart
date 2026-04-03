import 'package:bloc/bloc.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';

part 'audio_event.dart';

part 'audio_state.dart';

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

      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.audio,
      );

      if (paths.isNotEmpty) {
        final AssetPathEntity mainPath = paths[0];
        final int totalCount = await mainPath.assetCountAsync;

        final List<AssetEntity> latestEntities = await mainPath.getAssetListRange(
          start: 0,
          end: totalCount,
        );

        latestEntities.sort((a, b) {
          String nameA = a.title ?? "";
          String nameB = b.title ?? "";
          return nameA.toLowerCase().compareTo(nameB.toLowerCase());
        });

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
      }
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
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.audio,
      );

      emit(AlbumsLoaded(paths));
    });
  }

  Future<void> _onLoadAudios(LoadAudios event, Emitter<AudioState> emit) async {
    if (event.showLoading ?? true) {
      emit(AudioLoading());
    }

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.audio,
      onlyAll: true,
    );

    if (paths.isNotEmpty) {
      final path = paths.first;

      final totalCount = await path.assetCountAsync;

      final entities = await path.getAssetListPaged(page: 0, size: 20);

      final audioBox = Hive.box('audios');
      await audioBox.clear();
      for (int i = 0; i < totalCount; i++) {
        audioBox.put('dummy_$i', 'data');
      }
      emit(AudioLoading(entities: entities));
      emit(
        AudioLoaded(
          entities: entities,
          path: path,
          page: 0,
          totalCount: totalCount,
          hasMore: entities.length < totalCount,
        ),
      );
    }
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


