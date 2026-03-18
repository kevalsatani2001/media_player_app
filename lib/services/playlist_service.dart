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

  // static Box get _box => Hive.box('playlists');
  static Box<PlaylistModel> get _box => Hive.box<PlaylistModel>('playlists');

  // âœ… àªŸàª¾àªˆàªª àª®à«àªœàª¬ àª«àª¿àª²à«àªŸàª° àª•àª°à«‡àª²à«€ àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àª®à«‡àª³àªµà«‹
  static List<PlaylistModel> getPlaylistsByType(String type) {
    return _box.values.where((playlist) => playlist.type == type).toList();
  }

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

    // 1ï¸âƒ£ Update Hive favourites
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

    // 2ï¸âƒ£ Update system gallery favourite
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

    // 3ï¸âƒ£ Update playlists: mark matching MediaItems as favourite or not
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

    // 4ï¸âƒ£ Notify listeners
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

  void addToPlaylist(String playlistName, MediaItem item, String mediaType) {
    final box = Hive.box<PlaylistModel>('playlists');

    // àªŸàª¾àªˆàªŸàª² àª…àª¨à«‡ àªŸàª¾àªˆàªª àª¬àª‚àª¨à«‡ àª®à«‡àªš àª¥àªµàª¾ àªœà«‹àªˆàª
    final playlistKey = box.keys.firstWhere(
          (k) {
        final p = box.get(k);
        return p?.name == playlistName && p?.type == mediaType;
      },
      orElse: () => null,
    );

    if (playlistKey != null) {
      final playlist = box.get(playlistKey)!;
      if (!playlist.items.any((e) => e.path == item.path)) {
        playlist.items.add(item);
        playlist.save(); // âœ… box.put àª•àª°àª¤àª¾ playlist.save() àªµàª§àª¾àª°à«‡ àª¸àª¾àª°à«àª‚ àª›à«‡
      }
    } else {
      // àª¨àªµà«€ àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àª¬àª¨àª¾àªµà«‹ àª¤à«àª¯àª¾àª°à«‡ àªŸàª¾àªˆàªª àª†àªªà«‹
      final newPlaylist = PlaylistModel(
        name: playlistName,
        items: [item],
        type: mediaType, // âœ… 'audio' àª…àª¥àªµàª¾ 'video'
      );
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