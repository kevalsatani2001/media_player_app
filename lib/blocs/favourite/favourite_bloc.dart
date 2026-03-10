import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
import '../../models/media_item.dart';
import 'favourite_state.dart';

part 'favourite_event.dart';

class FavouriteBloc extends Bloc<FavouriteEvent, FavouriteState> {
  final Box box;

  FavouriteBloc(this.box) : super(FavouriteInitial()) {
    on<LoadFavourite>(_onLoadFavourite);
    on<LoadMoreFavourites>(_onLoadMoreFavourites);
    on<ToggleFavourite>(_onToggleFavourite);
  }

  // ================= LOAD FAVOURITES =================

  Future<void> _onToggleFavourite(
      ToggleFavourite event,
      Emitter<FavouriteState> emit,
      ) async {
    if (state is! FavouriteLoaded) return;

    final current = state as FavouriteLoaded;
    final entity = event.entity;

    final updatedEntities = List<AssetEntity>.from(current.entities);

    final existingIndex =
    updatedEntities.indexWhere((e) => e.id == entity.id);

    // ðŸ§  If unfavourite â†’ remove
    if (entity.isFavorite) {
      if (existingIndex != -1) {
        updatedEntities.removeAt(existingIndex);
      }
    } else {
      // â¤ï¸ Favourite
      if (existingIndex == -1) {
        updatedEntities.add(entity.copyWith(isFavorite: true));
      } else {
        updatedEntities[existingIndex] =
            entity.copyWith(isFavorite: true);
      }
    }

    // âœ… Instant UI update
    emit(current.copyWith(entities: updatedEntities));

    try {
      final file = await entity.file;
      if (file == null) return;

      if (entity.isFavorite) {
        box.delete(file.path);
      } else {
        box.put(file.path, {
          "path": file.path,
          "isNetwork": false,
          "type": entity.type == AssetType.audio ? "audio" : "video",
        });
      }

      // ðŸ” Sync system favourite silently
      if (PlatformUtils.isOhos) {
        await PhotoManager.editor.ohos.favoriteAsset(
          entity: entity,
          favorite: !entity.isFavorite,
        );
      } else if (Platform.isAndroid) {
        await PhotoManager.editor.android.favoriteAsset(
          entity: entity,
          favorite: !entity.isFavorite,
        );
      } else {
        await PhotoManager.editor.darwin.favoriteAsset(
          entity: entity,
          favorite: !entity.isFavorite,
        );
      }
    } catch (_) {
      // ðŸ”™ rollback
      emit(current);
    }
  }


  Future<void> _onLoadFavourite(LoadFavourite event, Emitter<FavouriteState> emit) async {
    print("Load fav STARTING... ðŸš€"); // àª† àªªà«àª°àª¿àª¨à«àªŸ àªšà«‡àª• àª•àª°à«‹

    try {
      // àªªàª°àª®àª¿àª¶àª¨ àªšà«‡àª•
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.hasAccess) return;

      // 'Recent' àª†àª²à«àª¬àª® àª²à«‹
      final paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.fromTypes([RequestType.audio, RequestType.video]),
      );

      if (paths.isEmpty) return;

      final recentPath = paths.first;
      final int totalCount = await recentPath.assetCountAsync;

      // âœ¨ àª¯à«àª•à«àª¤àª¿: à«¨à«¦ àª¨à«‡ àª¬àª¦àª²à«‡ àª®à«‹àªŸàª¾ àª­àª¾àª—àª¨à«‹ àª¡à«‡àªŸàª¾ àªàª•àª¸àª¾àª¥à«‡ àªšà«‡àª• àª•àª°à«‹ (àª®àª¾àª¤à«àª° àª®à«‡àªŸàª¾àª¡à«‡àªŸàª¾ àª›à«‡, àª²à«‹àª¡ àª¨àª¹à«€àª‚ àªªàª¡à«‡)
      // àªœà«‹ àª¤àª®àª¾àª°à«€ àªªàª¾àª¸à«‡ à«§à«¦à«¦à«¦ àª†àªˆàªŸàª® àª¹à«‹àª¯ àª¤à«‹ àª…àª¹à«€àª‚ à«§à«¦à«¦à«¦ àª²àª–à«‹
      final List<AssetEntity> allEntities = await recentPath.getAssetListRange(
        start: 0,
        end: totalCount,
      );

      // àª¸àª¿àª¸à«àªŸàª® àª«à«‡àªµàª°àª¿àªŸ àª«àª¿àª²à«àªŸàª° àª•àª°à«‹
      final List<AssetEntity> favouriteEntities = allEntities
          .where((e) => e.isFavorite)
          .toList();

      // Hive àª¸àª¿àª‚àª• àª•àª°à«‹
      await box.clear();
      await _saveToHive(favouriteEntities);

      print("Total Favourites Found: ${favouriteEntities.length}");

      emit(FavouriteLoaded(
        entities: favouriteEntities,
        path: recentPath,
        page: 0,
        totalCount: totalCount,
        hasMore: false,
      ));
    } catch (e) {
      print("Error in LoadFavourite: $e");
    }
  }

  // ================= LOAD MORE =================

  Future<void> _onLoadMoreFavourites(
      LoadMoreFavourites event,
      Emitter<FavouriteState> emit,
      ) async {
    if (state is! FavouriteLoaded) return;

    final current = state as FavouriteLoaded;
    final nextPage = current.page + 1;

    final List<AssetEntity> pageEntities = await current.path.getAssetListPaged(
      page: nextPage,
      size: 20,
    );

    // ðŸ”¹ Filter favourites ONLY
    final List<AssetEntity> favouriteEntities = pageEntities
        .where((e) => e.isFavorite)
        .toList();

    await _saveToHive(favouriteEntities);

    emit(
      current.copyWith(
        entities: [...current.entities, ...favouriteEntities],
        page: nextPage,
        hasMore:
        current.entities.length + favouriteEntities.length <
            current.totalCount,
      ),
    );
  }

  // ================= HIVE SYNC =================

  Future<void> _saveToHive(List<AssetEntity> entities) async {
    for (final entity in entities) {
      final file = await entity.file;
      if (file != null) {
        box.put(
          file.path,
          MediaItem(
            id: entity.id,
            path: file.path,
            isNetwork: false,
            type: entity.type == AssetType.video ? 'video' : 'audio', isFavourite: entity.isFavorite,
          ).toMap(),
        );
      }
    }
  }
}