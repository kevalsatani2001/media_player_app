import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
import '../../models/media_item.dart';
import '../../models/playlist_model.dart';
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
      ) async
  {
    if (state is! FavouriteLoaded) return;

    final current = state as FavouriteLoaded;
    final entity = event.entity;
    final file = await entity.file;
    if (file == null) return;

    final updatedEntities = List<AssetEntity>.from(current.entities);
    final existingIndex = updatedEntities.indexWhere((e) => e.id == entity.id);

    // àª¨àªµà«€ àª«à«‡àªµàª°àª¿àªŸ àªµà«‡àª²à«àª¯à« (àªœà«‹ àª…àª¤à«àª¯àª¾àª°à«‡ àª«à«‡àªµàª°àª¿àªŸ àª¹à«‹àª¯ àª¤à«‹ àª¹àªµà«‡ false àª¥àª¶à«‡)
    final bool newFavouriteStatus = !entity.isFavorite;

    // 1ï¸âƒ£ UI Update (Favourite Screen àª®àª¾àªŸà«‡)
    if (entity.isFavorite) {
      if (existingIndex != -1) updatedEntities.removeAt(existingIndex);
    } else {
      if (existingIndex == -1) updatedEntities.add(entity.copyWith(isFavorite: true));
    }
    emit(current.copyWith(entities: updatedEntities));

    try {
      // 2ï¸âƒ£ Favourites Box Update
      if (entity.isFavorite) {
        box.delete(file.path);
      } else {
        box.put(file.path, {
          "path": file.path,
          "isNetwork": false,
          "type": entity.type == AssetType.audio ? "audio" : "video",
        });
      }

      // 3ï¸âƒ£ ðŸ”¥ àª…àª—àª¤à«àª¯àª¨à«àª‚: Playlists Box Update àª•àª°à«‹
      final playlistBox = Hive.box('playlists');
      for (var playlist in playlistBox.values) {
        if (playlist is PlaylistModel) {
          bool needsSaving = false;
          for (var item in playlist.items) {
            if (item.path == file.path) {
              item.isFavourite = newFavouriteStatus; // àª…àª¹à«€àª‚ àª¸à«àªŸà«‡àªŸàª¸ àª…àªªàª¡à«‡àªŸ àª¥àª¶à«‡
              needsSaving = true;
            }
          }
          if (needsSaving) {
            await playlist.save(); // àªªà«àª²à«‡àª²àª¿àª¸à«àªŸàª¨à«‡ àª¸à«‡àªµ àª•àª°à«‹
          }
        }
      }

      // 4ï¸âƒ£ Sync system favourite
      if (PlatformUtils.isOhos) {
        await PhotoManager.editor.ohos.favoriteAsset(entity: entity, favorite: newFavouriteStatus);
      } else if (Platform.isAndroid) {
        await PhotoManager.editor.android.favoriteAsset(entity: entity, favorite: newFavouriteStatus);
      } else {
        await PhotoManager.editor.darwin.favoriteAsset(entity: entity, favorite: newFavouriteStatus);
      }

    } catch (_) {
      emit(current); // Rollback if error
    }
  }


  Future<void> _onLoadFavourite(LoadFavourite event, Emitter<FavouriteState> emit) async {
    print("Load fav STARTING... Ã°Å¸Å¡â‚¬"); // Ã Âªâ€  Ã ÂªÂªÃ Â«ÂÃ ÂªÂ°Ã ÂªÂ¿Ã ÂªÂ¨Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÅ¡Ã Â«â€¡Ã Âªâ€¢ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹

    try {
      // Ã ÂªÂªÃ ÂªÂ°Ã ÂªÂ®Ã ÂªÂ¿Ã ÂªÂ¶Ã ÂªÂ¨ Ã ÂªÅ¡Ã Â«â€¡Ã Âªâ€¢
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.hasAccess) return;

      // 'Recent' Ã Âªâ€ Ã ÂªÂ²Ã Â«ÂÃ ÂªÂ¬Ã ÂªÂ® Ã ÂªÂ²Ã Â«â€¹
      final paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.fromTypes([RequestType.audio, RequestType.video]),
      );

      if (paths.isEmpty) return;

      final recentPath = paths.first;
      final int totalCount = await recentPath.assetCountAsync;

      // Ã¢Å“Â¨ Ã ÂªÂ¯Ã Â«ÂÃ Âªâ€¢Ã Â«ÂÃ ÂªÂ¤Ã ÂªÂ¿: Ã Â«Â¨Ã Â«Â¦ Ã ÂªÂ¨Ã Â«â€¡ Ã ÂªÂ¬Ã ÂªÂ¦Ã ÂªÂ²Ã Â«â€¡ Ã ÂªÂ®Ã Â«â€¹Ã ÂªÅ¸Ã ÂªÂ¾ Ã ÂªÂ­Ã ÂªÂ¾Ã Âªâ€”Ã ÂªÂ¨Ã Â«â€¹ Ã ÂªÂ¡Ã Â«â€¡Ã ÂªÅ¸Ã ÂªÂ¾ Ã ÂªÂÃ Âªâ€¢Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªÂ¥Ã Â«â€¡ Ã ÂªÅ¡Ã Â«â€¡Ã Âªâ€¢ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹ (Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÂ¤Ã Â«ÂÃ ÂªÂ° Ã ÂªÂ®Ã Â«â€¡Ã ÂªÅ¸Ã ÂªÂ¾Ã ÂªÂ¡Ã Â«â€¡Ã ÂªÅ¸Ã ÂªÂ¾ Ã Âªâ€ºÃ Â«â€¡, Ã ÂªÂ²Ã Â«â€¹Ã ÂªÂ¡ Ã ÂªÂ¨Ã ÂªÂ¹Ã Â«â‚¬Ã Âªâ€š Ã ÂªÂªÃ ÂªÂ¡Ã Â«â€¡)
      // Ã ÂªÅ“Ã Â«â€¹ Ã ÂªÂ¤Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â‚¬ Ã ÂªÂªÃ ÂªÂ¾Ã ÂªÂ¸Ã Â«â€¡ Ã Â«Â§Ã Â«Â¦Ã Â«Â¦Ã Â«Â¦ Ã Âªâ€ Ã ÂªË†Ã ÂªÅ¸Ã ÂªÂ® Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ¯ Ã ÂªÂ¤Ã Â«â€¹ Ã Âªâ€¦Ã ÂªÂ¹Ã Â«â‚¬Ã Âªâ€š Ã Â«Â§Ã Â«Â¦Ã Â«Â¦Ã Â«Â¦ Ã ÂªÂ²Ã Âªâ€“Ã Â«â€¹
      final List<AssetEntity> allEntities = await recentPath.getAssetListRange(
        start: 0,
        end: totalCount,
      );

      // Ã ÂªÂ¸Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ® Ã ÂªÂ«Ã Â«â€¡Ã ÂªÂµÃ ÂªÂ°Ã ÂªÂ¿Ã ÂªÅ¸ Ã ÂªÂ«Ã ÂªÂ¿Ã ÂªÂ²Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ° Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
      final List<AssetEntity> favouriteEntities = allEntities
          .where((e) => e.isFavorite)
          .toList();

      // Hive Ã ÂªÂ¸Ã ÂªÂ¿Ã Âªâ€šÃ Âªâ€¢ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
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

    // Ã°Å¸â€Â¹ Filter favourites ONLY
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