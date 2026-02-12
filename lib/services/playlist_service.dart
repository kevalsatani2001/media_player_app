import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
import '../models/media_item.dart';

import 'package:bloc/bloc.dart';

class FavouriteChangeBloc
    extends Bloc<FavouriteChangeEvent, FavouriteChangeState> {
  FavouriteChangeBloc() : super(FavouriteChangeInitial()) {
    on<FavouriteUpdated>((event, emit) {
      emit(FavouriteChanged(entity: event.entity));
    });
  }
}

abstract class FavouriteChangeEvent {}

class FavouriteUpdated extends FavouriteChangeEvent {
  final AssetEntity entity;

  FavouriteUpdated(this.entity);
}

abstract class FavouriteChangeState {}

class FavouriteChangeInitial extends FavouriteChangeState {}

class FavouriteChanged extends FavouriteChangeState {
  final AssetEntity entity;

  FavouriteChanged({required this.entity});
}

class PlaylistService {
  static final Box _box = Hive.box('playlists');
  final FavouriteChangeBloc favouriteChangeBloc;

  PlaylistService({required this.favouriteChangeBloc});

  /// Create playlist with name
  static void createPlaylist(String name, MediaItem? firstItem) {
    if (name.trim().isEmpty) return;

    _box.add({
      'name': name.trim(),
      'items': firstItem == null ? [] : [firstItem],
    });
  }

  /// Add media to existing playlist (NO duplicates)
  static void addToPlaylist(dynamic key, MediaItem item) {
    final playlist = _box.get(key);
    final List items = List<Map>.from(playlist['items']);

    final exists = items.any((e) => e['path'] == item.path);
    if (exists) return;

    items.add(item);

    _box.put(key, {'name': playlist['name'], 'items': items});
  }

  static List getPlaylists() => _box.values.toList();

  /*
    Future<void> _toggleFavourite(
      BuildContext context,
      AssetEntity entity,
      int index,
      ) async {
    final favBox = Hive.box('favourites');
    final bool isFavorite = entity.isFavorite;

    final file = await entity.file;
    if (file == null) return;

    final key = file.path;

    // 🔹 Update Hive
    if (isFavorite) {
      favBox.delete(key);
    } else {
      favBox.put(key, {
        "path": file.path,
        "isNetwork": false,
        "type": entity.type == AssetType.audio ? "audio" : "video",
      });
    }

    // 🔹 Update system favourite
    if (PlatformUtils.isOhos) {
      await PhotoManager.editor.ohos.favoriteAsset(
        entity: entity,
        favorite: !isFavorite,
      );
    } else if (Platform.isAndroid) {
      await PhotoManager.editor.android.favoriteAsset(
        entity: entity,
        favorite: !isFavorite,
      );
    } else {
      await PhotoManager.editor.darwin.favoriteAsset(
        entity: entity,
        favorite: !isFavorite,
      );
    }

    // 🔹 Reload entity
    final AssetEntity? newEntity = await entity.obtainForNewProperties();
    if (!mounted || newEntity == null) return;

    // 🔹 Update UI list
    // readPathProvider(context).list[index] = newEntity;
    context.read<AudioBloc>().add(LoadAudios(showLoading: false));

    setState(() {});
  }
   */

  /// Toggle favourite in playlist & sync with device
  Future<void> toggleFavourite(AssetEntity entity) async {
    final favBox = Hive.box('favourites');
    final bool isFavorite = entity.isFavorite;

    final file = await entity.file;
    if (file == null) return;
    final key = file.path;

    // Update Hive favourites
    // if (isFavorite) {
    //   favBox.delete(key);
    // } else {
    //   favBox.put(key, {
    //     "path": file.path,
    //     "isNetwork": false,
    //     "type": entity.type == AssetType.audio ? "audio" : "video",
    //   });
    // }

    // Update system favourite
    if (PlatformUtils.isOhos) {
      await PhotoManager.editor.ohos.favoriteAsset(
        entity: entity,
        favorite: !isFavorite,
      );
    } else if (Platform.isAndroid) {
      print("In side updation =========${isFavorite}");
      await PhotoManager.editor.android.favoriteAsset(
        entity: entity,
        favorite: !isFavorite,
      );
    } else {
      await PhotoManager.editor.darwin.favoriteAsset(
        entity: entity,
        favorite: !isFavorite,
      );
    }

    // Notify other blocs / screens
    favouriteChangeBloc.add(FavouriteUpdated(entity));

    // Update playlists
    final playlists = _box.values.toList();
    for (var i = 0; i < playlists.length; i++) {
      final playlist = playlists[i];
      final items = List<Map>.from(playlist['items']);
      final index = items.indexWhere((e) => e['path'] == entity.relativePath);
      if (index != -1) {
        items[index]['isFavourite'] = !isFavorite;
        _box.putAt(i, {'name': playlist['name'], 'items': items});
      }
    }
  }
}




// import 'dart:io';
//
// import 'package:flutter/cupertino.dart';
// import 'package:hive/hive.dart';
// import 'package:photo_manager/photo_manager.dart';
// import 'package:photo_manager/platform_utils.dart';
// import '../blocs/favourite_change/favourite_change_bloc.dart';
// import '../blocs/favourite_change/favourite_change_state.dart';
// import '../models/media_item.dart';
//
//
//
//
//
//
// class PlaylistService {
//   static final Box _box = Hive.box('playlists');
//   final FavouriteChangeBloc favouriteChangeBloc;
//
//   PlaylistService({required this.favouriteChangeBloc});
//
//   /// Create playlist with name
//   static void createPlaylist(String name, MediaItem? firstItem) {
//     if (name.trim().isEmpty) return;
//
//     _box.add({
//       'name': name.trim(),
//       'items': firstItem == null ? [] : [firstItem.toMap()],
//     });
//   }
//
//   /// Add media to existing playlist (NO duplicates)
//   static void addToPlaylist(dynamic key, MediaItem item) {
//     final playlist = _box.get(key);
//     final List items = List<Map>.from(playlist['items']);
//
//     final exists = items.any((e) => e['path'] == item.path);
//     if (exists) return;
//
//     items.add(item.toMap());
//
//     _box.put(key, {'name': playlist['name'], 'items': items});
//   }
//
//   static List getPlaylists() => _box.values.toList();
//
//   /*
//     Future<void> _toggleFavourite(
//       BuildContext context,
//       AssetEntity entity,
//       int index,
//       ) async {
//     final favBox = Hive.box('favourites');
//     final bool isFavorite = entity.isFavorite;
//
//     final file = await entity.file;
//     if (file == null) return;
//
//     final key = file.path;
//
//     // 🔹 Update Hive
//     if (isFavorite) {
//       favBox.delete(key);
//     } else {
//       favBox.put(key, {
//         "path": file.path,
//         "isNetwork": false,
//         "type": entity.type == AssetType.audio ? "audio" : "video",
//       });
//     }
//
//     // 🔹 Update system favourite
//     if (PlatformUtils.isOhos) {
//       await PhotoManager.editor.ohos.favoriteAsset(
//         entity: entity,
//         favorite: !isFavorite,
//       );
//     } else if (Platform.isAndroid) {
//       await PhotoManager.editor.android.favoriteAsset(
//         entity: entity,
//         favorite: !isFavorite,
//       );
//     } else {
//       await PhotoManager.editor.darwin.favoriteAsset(
//         entity: entity,
//         favorite: !isFavorite,
//       );
//     }
//
//     // 🔹 Reload entity
//     final AssetEntity? newEntity = await entity.obtainForNewProperties();
//     if (!mounted || newEntity == null) return;
//
//     // 🔹 Update UI list
//     // readPathProvider(context).list[index] = newEntity;
//     context.read<AudioBloc>().add(LoadAudios(showLoading: false));
//
//     setState(() {});
//   }
//    */
//
//   /// Toggle favourite in playlist & sync with device
//   Future<void> toggleFavourite(AssetEntity entity) async {
//     final favBox = Hive.box('favourites');
//     final bool isFavorite = entity.isFavorite;
//
//     final file = await entity.file;
//     if (file == null) return;
//     final key = file.path;
//
//     // Update Hive favourites
//     // if (isFavorite) {
//     //   favBox.delete(key);
//     // } else {
//     //   favBox.put(key, {
//     //     "path": file.path,
//     //     "isNetwork": false,
//     //     "type": entity.type == AssetType.audio ? "audio" : "video",
//     //   });
//     // }
//
//     // Update system favourite
//     if (PlatformUtils.isOhos) {
//       await PhotoManager.editor.ohos.favoriteAsset(
//         entity: entity,
//         favorite: !isFavorite,
//       );
//     } else if (Platform.isAndroid) {
//       print("In side updation =========${isFavorite}");
//       await PhotoManager.editor.android.favoriteAsset(
//
//         entity: entity,
//         favorite: !isFavorite,
//       );
//     } else {
//       await PhotoManager.editor.darwin.favoriteAsset(
//         entity: entity,
//         favorite: !isFavorite,
//       );
//     }
//
//     // Notify other blocs / screens
//     favouriteChangeBloc.add(FavouriteUpdated(entity));
//
//     // Update playlists
//     final playlists = _box.values.toList();
//     for (var i = 0; i < playlists.length; i++) {
//       final playlist = playlists[i];
//       final items = List<Map>.from(playlist['items']);
//       final index = items.indexWhere((e) => e['path'] == entity.relativePath);
//       if (index != -1) {
//         items[index]['isFavourite'] = !isFavorite;
//         _box.putAt(i, {'name': playlist['name'], 'items': items});
//       }
//     }
//   }
// }
