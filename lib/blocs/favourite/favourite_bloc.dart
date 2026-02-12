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

    // 🧠 If unfavourite → remove
    if (entity.isFavorite) {
      if (existingIndex != -1) {
        updatedEntities.removeAt(existingIndex);
      }
    } else {
      // ❤️ Favourite
      if (existingIndex == -1) {
        updatedEntities.add(entity.copyWith(isFavorite: true));
      } else {
        updatedEntities[existingIndex] =
            entity.copyWith(isFavorite: true);
      }
    }

    // ✅ Instant UI update
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

      // 🔁 Sync system favourite silently
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
      // 🔙 rollback
      emit(current);
    }
  }


  Future<void> _onLoadFavourite(
      LoadFavourite event,
      Emitter<FavouriteState> emit,
      ) async {
    if (state is FavouriteInitial) {
      emit(FavouriteLoading());
    }

    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend(
        requestOption: PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.fromTypes([RequestType.audio, RequestType.video]),
            mediaLocation: true,
          ),
        ),
      );

      if (!ps.hasAccess) {
        emit(FavouriteError('Permission denied'));
        return;
      }

      final filter = FilterOptionGroup(
        videoOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        audioOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
      );

      final paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.fromTypes([RequestType.audio, RequestType.video]),
        filterOption: filter,
      );

      if (paths.isEmpty) {
        emit(FavouriteError('No media found'));
        return;
      }

      final path = paths.first;
      final totalCount = await path.assetCountAsync;

      // 🔹 Load first page
      final List<AssetEntity> pageEntities = await path.getAssetListPaged(
        page: 0,
        size: 50,
      );

      // 🔹 Filter favourites ONLY (FIX)
      final List<AssetEntity> favouriteEntities = pageEntities
          .where((e) => e.isFavorite)
          .toList();

      // 🔹 Sync Hive
      await box.clear();
      await _saveToHive(favouriteEntities);

      emit(
        FavouriteLoaded(
          entities: favouriteEntities,
          path: path,
          page: 0,
          totalCount: totalCount,
          hasMore: favouriteEntities.length < totalCount,
        ),
      );
    } catch (e) {
      emit(FavouriteError(e.toString()));
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
      size: 50,
    );

    // 🔹 Filter favourites ONLY
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
            type: entity.type == AssetType.video ? 'video' : 'audio',
          ).toMap(),
        );
      }
    }
  }
}