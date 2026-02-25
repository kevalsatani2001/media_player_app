import 'package:bloc/bloc.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../models/media_item.dart';

part 'audio_event.dart';

part 'audio_state.dart';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final Box box;

  AudioBloc(this.box) : super(AudioInitial()) {
    // audio_bloc.dart
    on<LoadAudios>((event, emit) async {
      // ૧. Hive માંથી જૂના IDs લાવો
      final List<String> cachedIds = box.values.cast<String>().toList();
      List<AssetEntity> cachedEntities = [];

      if (cachedIds.isNotEmpty) {
        for (String id in cachedIds) {
          final entity = await AssetEntity.fromId(id);
          if (entity != null) cachedEntities.add(entity);
        }
        // ૨. તરત જ Loading સ્ટેટમાં જૂનો ડેટા બતાવો (સ્ક્રીન ખાલી નહીં થાય)
        emit(AudioLoading(entities: cachedEntities));
      } else if (event.showLoading!) {
        emit(AudioLoading());
      }

      // ૩. હવે PhotoManager થી સાચો પાથ અને નવો ડેટા લાવો
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.audio,
      );

      if (paths.isNotEmpty) {
        final AssetPathEntity mainPath = paths[0]; // "All Audios" પાથ
        final int totalCount = await mainPath.assetCountAsync;
        final List<AssetEntity> latestEntities = await mainPath.getAssetListRange(
          start: 0,
          end: 50, // શરૂઆતના ૫૦ ગીતો
        );

        // ૪. Hive અપડેટ કરો
        await box.clear();
        await box.addAll(latestEntities.map((e) => e.id).toList());

        // ૫. હવે તમારી બધી Required પ્રોપર્ટીઝ સાથે AudioLoaded ઈમિટ કરો
        emit(AudioLoaded(
          entities: latestEntities,
          path: mainPath,
          page: 0,
          totalCount: totalCount,
          hasMore: latestEntities.length < totalCount,
        ));
      }
    });
    on<LoadMoreAudios>(_onLoadMoreAudios);
    on<UpdateAudioItem>((event, emit) {
      if (state is AudioLoaded) {
        final currentState = state as AudioLoaded;
// જૂની લિસ્ટની કોપી બનાવો
        List<AssetEntity> updatedList = List.from(currentState.entities);
// ફક્ત તે ચોક્કસ ઇન્ડેક્સ પર નવી એન્ટિટી મૂકો
        updatedList[event.index] = event.entity;

        emit(currentState.copyWith(entities: updatedList));
      }
    });
  }

  Future<void> _onLoadAudios(LoadAudios event, Emitter<AudioState> emit) async {
    if(event.showLoading??true){
      emit(AudioLoading());}

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.audio,
      onlyAll: true,
    );

    if (paths.isNotEmpty) {
      final path = paths.first;

      // 🔴 અહીં ટ્રીક છે: 'totalCount' આખા ફોનનો આંકડો લેશે (જેમ કે 3)
      final totalCount = await path.assetCountAsync;

      // જ્યારે લિસ્ટ લોડ કરો ત્યારે ફક્ત ૧ કે ૨૦ આઈટમ લો (Pagination માટે)
      final entities = await path.getAssetListPaged(page: 0, size: 10);

      // 🔴 હોમ સ્ક્રીન માટે Hive માં ડમી ડેટા ભરો (ફક્ત કાઉન્ટ માટે)
      final audioBox = Hive.box('audios');
      await audioBox.clear();
      for (int i = 0; i < totalCount; i++) {
        audioBox.put('dummy_$i', 'data'); // આનાથી હોમ સ્ક્રીન પર '3' બતાવશે
      }
      emit(AudioLoading(entities: entities));
      emit(AudioLoaded(
        entities: entities,
        path: path,
        page: 0,
        totalCount: totalCount,
        hasMore: entities.length < totalCount,
      ));
    }
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
      size: 10,
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
/*

part of 'audio_bloc.dart';

abstract class AudioEvent {}

// class LoadAudios extends AudioEvent {}
class LoadAudios extends AudioEvent {
  bool? showLoading;
  LoadAudios({this.showLoading = true});
}
// audio_event.dart માં ઉમેરો
class UpdateAudioItem extends AudioEvent {
  final AssetEntity entity;
  final int index;
  UpdateAudioItem(this.entity, this.index);
}

// audio_bloc.dart માં આ હેન્ડલર ઉમેરો

 */




/*




 */







// import 'package:bloc/bloc.dart';
// import 'package:hive/hive.dart';
// import 'package:photo_manager/photo_manager.dart';
// import '../../models/media_item.dart';
//
// part 'audio_event.dart';
//
// part 'audio_state.dart';
//
// class AudioBloc extends Bloc<AudioEvent, AudioState> {
//   final Box box;
//
//   AudioBloc(this.box) : super(AudioInitial()) {
//     on<LoadAudios>(_onLoadAudios);
//     on<LoadMoreAudios>(_onLoadMoreAudios);
//   }
//
//   // Future<void> _onLoadAudios(LoadAudios event, Emitter<AudioState> emit) async {
//   //   if (event.showLoading ?? true) {
//   //     emit(AudioLoading());
//   //   }
//   //
//   //   PermissionState ps;
//   //   try {
//   //     ps = await PhotoManager.requestPermissionExtend(
//   //       requestOption: PermissionRequestOption(
//   //         androidPermission: AndroidPermission(
//   //           type: RequestType.audio,
//   //           mediaLocation: true,
//   //         ),
//   //       ),
//   //     );
//   //   } catch (e) {
//   //     emit(AudioError('Permission request failed'));
//   //     return;
//   //   }
//   //
//   //   if (!ps.hasAccess) {
//   //     emit(AudioError('Permission denied'));
//   //     return;
//   //   }
//   //
//   //   final filter = FilterOptionGroup(
//   //     videoOption: const FilterOption(
//   //       sizeConstraint: SizeConstraint(ignoreSize: true),
//   //     ),
//   //   );
//   //
//   //   final paths = await PhotoManager.getAssetPathList(
//   //     onlyAll: true,
//   //     type: RequestType.audio,
//   //     filterOption: filter,
//   //   );
//   //
//   //   if (paths.isEmpty) {
//   //     emit(AudioError('No audios found'));
//   //     return;
//   //   }
//   //
//   //   final path = paths.first;
//   //   final total = await path.assetCountAsync;
//   //   final entities = await path.getAssetListPaged(page: 0, size: 50);
//   //
//   //   await box.clear();
//   //   for (final entity in entities) {
//   //     final file = await entity.file;
//   //     if (file != null) {
//   //       box.put(
//   //         file.path,
//   //         MediaItem(
//   //           id: entity.id,
//   //           path: file.path,
//   //           isNetwork: false,
//   //           type: 'audio',
//   //           isFavourite: entity.isFavorite,
//   //         ),
//   //       );
//   //     }
//   //   }
//   //
//   //   emit(
//   //     AudioLoaded(
//   //       entities: entities,
//   //       path: path,
//   //       page: 0,
//   //       totalCount: total,
//   //       hasMore: entities.length < total,
//   //     ),
//   //   );
//   // }
//
//   Future<void> _onLoadAudios(
//       LoadAudios event,
//       Emitter<AudioState> emit,
//       ) async {
//
//     if (event.showLoading ?? true) {
//       emit(AudioLoading());
//     }
//
//     final ps = await PhotoManager.requestPermissionExtend(
//       requestOption: PermissionRequestOption(
//         androidPermission: AndroidPermission(
//           type: RequestType.audio,
//           mediaLocation: true,
//         ),
//       ),
//     );
//
//     if (!ps.hasAccess) {
//       emit(AudioError('Permission denied'));
//       return;
//     }
//
//     final paths = await PhotoManager.getAssetPathList(
//       onlyAll: true,
//       type: RequestType.audio,
//     );
//
//     if (paths.isEmpty) {
//       emit(AudioError('No audios found'));
//       return;
//     }
//
//     final path = paths.first;
//     final total = await path.assetCountAsync;
//
//     final entities = await path.getAssetListPaged(page: 0, size: 50);
//     await box.clear();
//     for (final entity in entities) {
//       final file = await entity.file;
//       if (file != null) {
//         box.put(
//           file.path,
//           MediaItem(path: file.path, isNetwork: false, type: 'audio',id: entity.id, isFavourite: entity.isFavorite).toMap(),
//         );
//       }
//     }
//
//     emit(AudioLoaded(
//       entities: entities,
//       path: path,
//       page: 0,
//       totalCount: total,
//       hasMore: entities.length < total,
//     ));
//   }
//
//   Future<void> _onLoadMoreAudios(
//       LoadMoreAudios event,
//       Emitter<AudioState> emit,
//       ) async {
//     final currentState = state;
//
//     if (currentState is! AudioLoaded) return;
//     if (!currentState.hasMore) return;
//     if (currentState.isLoadingMore) return;
//
//     emit(currentState.copyWith(isLoadingMore: true));
//
//     final nextPage = currentState.page + 1;
//
//     final newEntities = await currentState.path.getAssetListPaged(
//       page: nextPage,
//       size: 50,
//     );
//
//     final allEntities = [
//       ...currentState.entities,
//       ...newEntities,
//     ];
//
//     emit(currentState.copyWith(
//       entities: allEntities,
//       page: nextPage,
//       hasMore: allEntities.length < currentState.totalCount,
//       isLoadingMore: false,
//     ));
//   }
//
//
// }
//
// ////////////////////////////////////////////
//
// /////////////////////////////////////////////////////////////
