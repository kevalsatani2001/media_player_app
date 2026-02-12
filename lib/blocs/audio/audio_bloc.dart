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
  }

  // Future<void> _onLoadAudios(LoadAudios event, Emitter<AudioState> emit) async {
  //   emit(AudioLoading());
  //
  //   final PermissionState ps = await PhotoManager.requestPermissionExtend(
  //     requestOption: PermissionRequestOption(
  //       androidPermission: AndroidPermission(
  //         type: RequestType.audio,
  //         mediaLocation: true,
  //       ),
  //     ),
  //   );
  //
  //   if (!ps.hasAccess) {
  //     emit(const AudioError("Permission denied for accessing media files."));
  //     return;
  //   }
  //
  //   final filter = FilterOptionGroup(
  //     audioOption: const FilterOption(
  //       sizeConstraint: SizeConstraint(ignoreSize: true),
  //     ),
  //   );
  //
  //   final paths = await PhotoManager.getAssetPathList(
  //     type: RequestType.audio,
  //     onlyAll: true,
  //     filterOption: filter,
  //   );
  //
  //   if (paths.isEmpty) {
  //     emit(const AudioLoaded([]));
  //     return;
  //   }
  //
  //   final path = paths.first;
  //   final total = await path.assetCountAsync;
  //   final entities = await path.getAssetListPaged(page: 0, size: total);
  //
  //   // Clear old Hive data
  //   await box.clear();
  //
  //   final List<MediaItem> audios = [];
  //
  //   for (final entity in entities) {
  //     final file = await entity.file;
  //     if (file != null && file.existsSync()) {
  //       final item = MediaItem(
  //         path: file.path,
  //         isNetwork: false,
  //         type: 'audio',
  //       );
  //       box.put(file.path, item.toMap());
  //       audios.add(item);
  //     }
  //   }
  //
  //   emit(AudioLoaded(audios));
  // }

  Future<void> _onLoadAudios(LoadAudios event, Emitter<AudioState> emit) async {
    if (event.showLoading ?? true) {
      emit(AudioLoading());
    }

    PermissionState ps;
    try {
      ps = await PhotoManager.requestPermissionExtend(
        requestOption: PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.audio,
            mediaLocation: true,
          ),
        ),
      );
    } catch (e) {
      emit(AudioError('Permission request failed'));
      return;
    }

    if (!ps.hasAccess) {
      emit(AudioError('Permission denied'));
      return;
    }

    final filter = FilterOptionGroup(
      videoOption: const FilterOption(
        sizeConstraint: SizeConstraint(ignoreSize: true),
      ),
    );

    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.audio,
      filterOption: filter,
    );

    if (paths.isEmpty) {
      emit(AudioError('No audios found'));
      return;
    }

    final path = paths.first;
    final total = await path.assetCountAsync;
    final entities = await path.getAssetListPaged(page: 0, size: 50);

    await box.clear();
    for (final entity in entities) {
      final file = await entity.file;
      if (file != null) {
        box.put(
          file.path,
          MediaItem(
            id: entity.id,
            path: file.path,
            isNetwork: false,
            type: 'audio',
            isFavourite: entity.isFavorite,
          ),
        );
      }
    }

    emit(
      AudioLoaded(
        entities: entities,
        path: path,
        page: 0,
        totalCount: total,
        hasMore: entities.length < total,
      ),
    );
  }
}

////////////////////////////////////////////


/////////////////////////////////////////////////////////////



