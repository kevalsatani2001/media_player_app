import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:media_player/main.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
import '../models/media_item.dart';

import 'package:bloc/bloc.dart';

import '../models/playlist_model.dart';

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
  PlaylistService();

  static Box get _box => Hive.box('playlists');

  static List getPlaylists() => _box.values.toList();
  static final Box favBox = Hive.box('favourites');



  /// Toggle favourite in playlist & sync with device
  /// Returns new favourite state
  Future<bool> toggleFavourite(AssetEntity entity) async {
    // Use the global FavouriteChangeBloc instead of creating a new one each time
    FavouriteChangeBloc favouriteChangeBloc = FavouriteChangeBloc();

    final file = await entity.file;
    if (file == null) return false;

    final key = file.path;
    final bool isCurrentlyFav = favBox.containsKey(key);

    // 1️⃣ Update Hive favourites
    if (isCurrentlyFav) {
      await favBox.delete(key);
    } else {
      await favBox.put(key, {
        "id": entity.id,
        "path": file.path,
        "isNetwork": false,
        "type": entity.type == AssetType.audio ? "audio" : "video",
      });
    }

    // 2️⃣ Update system gallery favourite
    if (PlatformUtils.isOhos) {
      await PhotoManager.editor.ohos.favoriteAsset(
        entity: entity,
        favorite: !isCurrentlyFav,
      );
    } else if (Platform.isAndroid) {
      await PhotoManager.editor.android.favoriteAsset(
        entity: entity,
        favorite: !isCurrentlyFav,
      );
    } else {
      await PhotoManager.editor.darwin.favoriteAsset(
        entity: entity,
        favorite: !isCurrentlyFav,
      );
    }

    // 3️⃣ Update playlists: mark matching MediaItems as favourite or not
    for (int i = 0; i < _box.length; i++) {
      final playlist = _box.getAt(i);
      if (playlist == null) continue;

      bool updated = false;
      for (var item in playlist.items) {
        if (item.path == file.path) {
          item.isFavourite = !isCurrentlyFav;
          updated = true;
        }
      }

      if (updated) {
        // Save playlist back to Hive
        playlist.save();
      }
    }

    // 4️⃣ Notify listeners
    favouriteChangeBloc.add(FavouriteUpdated(entity));

    return !isCurrentlyFav;
  }

  static void addPlaylist(PlaylistModel playlist) {
    _box.add(playlist);
  }

  static void deletePlaylist(int index) {
    _box.deleteAt(index);
  }

  static void renamePlaylist(int index, String newName) {
    final playlist = _box.getAt(index);
    if (playlist != null) {
      playlist.name = newName;
      playlist.save();
    }
  }

  void addToPlaylist(String playlistName, MediaItem item) {
    final box = Hive.box<PlaylistModel>('playlists');

    // Check if playlist exists
    final playlistKey = box.keys.firstWhere(
            (k) => box.get(k)?.name == playlistName,
        orElse: () => null);

    if (playlistKey != null) {
      final playlist = box.get(playlistKey)!;
      if (!playlist.items.any((e) => e.path == item.path)) {
        playlist.items.add(item);
        box.put(playlistKey, playlist); // update
      }
    } else {
      // Create new playlist
      final newPlaylist = PlaylistModel(name: playlistName, items: [item]);
      box.add(newPlaylist);
    }
  }



//
// static void createPlaylist(String name, MediaItem? firstItem) {
//   final box = Hive.box('playlists');
//
//   box.add({
//     'name': name,
//     'items': firstItem != null ? [firstItem.toMap()] : [],
//   });
// }
//
//
// static void addToPlaylist(dynamic key, MediaItem item) {
//   final playlistBox = Hive.box<List<MediaItem>>('playlists');
//   final playlist = playlistBox.get(key, defaultValue: <MediaItem>[])!;
//
//   final exists = playlist.any((e) => e.path == item.path);
//   if (exists) return;
//
//   playlist.add(item);
//   playlistBox.put(key, playlist);
// }




//
// static List getPlaylists() => _box.values.toList();
}