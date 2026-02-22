import 'package:bloc/bloc.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../models/media_item.dart';

part 'audio_event.dart';

part 'audio_state.dart';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final Box box;

  AudioBloc(this.box) : super(AudioInitial()) {
    on<LoadAudios>(_onLoadAudios);
    on<LoadMoreAudios>(_onLoadMoreAudios);
  }

  // Future<void> _onLoadAudios(LoadAudios event, Emitter<AudioState> emit) async {
  //   if (event.showLoading ?? true) {
  //     emit(AudioLoading());
  //   }
  //
  //   PermissionState ps;
  //   try {
  //     ps = await PhotoManager.requestPermissionExtend(
  //       requestOption: PermissionRequestOption(
  //         androidPermission: AndroidPermission(
  //           type: RequestType.audio,
  //           mediaLocation: true,
  //         ),
  //       ),
  //     );
  //   } catch (e) {
  //     emit(AudioError('Permission request failed'));
  //     return;
  //   }
  //
  //   if (!ps.hasAccess) {
  //     emit(AudioError('Permission denied'));
  //     return;
  //   }
  //
  //   final filter = FilterOptionGroup(
  //     videoOption: const FilterOption(
  //       sizeConstraint: SizeConstraint(ignoreSize: true),
  //     ),
  //   );
  //
  //   final paths = await PhotoManager.getAssetPathList(
  //     onlyAll: true,
  //     type: RequestType.audio,
  //     filterOption: filter,
  //   );
  //
  //   if (paths.isEmpty) {
  //     emit(AudioError('No audios found'));
  //     return;
  //   }
  //
  //   final path = paths.first;
  //   final total = await path.assetCountAsync;
  //   final entities = await path.getAssetListPaged(page: 0, size: 50);
  //
  //   await box.clear();
  //   for (final entity in entities) {
  //     final file = await entity.file;
  //     if (file != null) {
  //       box.put(
  //         file.path,
  //         MediaItem(
  //           id: entity.id,
  //           path: file.path,
  //           isNetwork: false,
  //           type: 'audio',
  //           isFavourite: entity.isFavorite,
  //         ),
  //       );
  //     }
  //   }
  //
  //   emit(
  //     AudioLoaded(
  //       entities: entities,
  //       path: path,
  //       page: 0,
  //       totalCount: total,
  //       hasMore: entities.length < total,
  //     ),
  //   );
  // }

  Future<void> _onLoadAudios(
      LoadAudios event,
      Emitter<AudioState> emit,
      ) async {

    if (event.showLoading ?? true) {
      emit(AudioLoading());
    }

    final ps = await PhotoManager.requestPermissionExtend(
      requestOption: PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.audio,
          mediaLocation: true,
        ),
      ),
    );

    if (!ps.hasAccess) {
      emit(AudioError('Permission denied'));
      return;
    }

    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.audio,
    );

    if (paths.isEmpty) {
      emit(AudioError('No audios found'));
      return;
    }

    final path = paths.first;
    final total = await path.assetCountAsync;

    final entities = await path.getAssetListPaged(page: 0, size: 2000);
    await box.clear();
    for (final entity in entities) {
      final file = await entity.file;
      if (file != null) {
        box.put(
          file.path,
          MediaItem(path: file.path, isNetwork: false, type: 'audio',id: entity.id, isFavourite: entity.isFavorite).toMap(),
        );
      }
    }

    emit(AudioLoaded(
      entities: entities,
      path: path,
      page: 0,
      totalCount: total,
      hasMore: entities.length < total,
    ));
  }

  Future<void> _onLoadMoreAudios(
      LoadMoreAudios event,
      Emitter<AudioState> emit,
      ) async {
    final currentState = state;

    if (currentState is! AudioLoaded) return;
    if (!currentState.hasMore) return;
    if (currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.page + 1;

    final newEntities = await currentState.path.getAssetListPaged(
      page: nextPage,
      size: 2000,
    );

    final allEntities = [
      ...currentState.entities,
      ...newEntities,
    ];

    emit(currentState.copyWith(
      entities: allEntities,
      page: nextPage,
      hasMore: allEntities.length < currentState.totalCount,
      isLoadingMore: false,
    ));
  }


}

////////////////////////////////////////////

/////////////////////////////////////////////////////////////
