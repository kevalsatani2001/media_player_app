import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
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
  static Box get _box => Hive.box('playlists');
  static final Box favBox = Hive.box('favourites');

  static List<PlaylistModel> getPlaylistsByType(String type) {
    return _box.values
        .where((p) => p is PlaylistModel && p.type == type)
        .cast<PlaylistModel>()
        .toList();
  }

  static List getPlaylists() => _box.values.toList();

  /// Toggle favourite in playlist & sync with device
  /// Returns new favourite state
  Future<bool> toggleFavourite(AssetEntity entity) async {
    FavouriteChangeBloc favouriteChangeBloc = FavouriteChangeBloc();

    final file = await entity.file;
    if (file == null) return false;

    final key = file.path;
    final bool isCurrentlyFav = favBox.containsKey(key);

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

    try {
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
    } catch (e) {
      debugPrint("System Favourite Error: $e");
    }

    for (var playlist in _box.values) {
      if (playlist is PlaylistModel) {
        bool updated = false;
        for (var item in playlist.items) {
          if (item.path == file.path) {
            item.isFavourite = !isCurrentlyFav;
            updated = true;
          }
        }
        if (updated) {
          await playlist.save();
        }
      }
    }

    favouriteChangeBloc.add(FavouriteUpdated(entity));
    return !isCurrentlyFav;
  }

  static void addPlaylist(PlaylistModel playlist) {
    _box.add(playlist);
  }

  static void deletePlaylist(dynamic key) {
    _box.delete(key);
  }

  static void renamePlaylist(dynamic key, String newName) {
    final playlist = _box.get(key);
    if (playlist != null) {
      playlist.name = newName;
      playlist.save();
    }
  }

  void addToPlaylist(String playlistName, MediaItem item, String mediaType) {
    final box = Hive.box<PlaylistModel>('playlists');

    final playlistKey = box.keys.firstWhere((k) {
      final p = box.get(k);
      return p?.name == playlistName && p?.type == mediaType;
    }, orElse: () => null);

    if (playlistKey != null) {
      final playlist = box.get(playlistKey)!;
      if (!playlist.items.any((e) => e.path == item.path)) {
        playlist.items.add(item);
        playlist.save();
      }
    } else {
      final newPlaylist = PlaylistModel(
        name: playlistName,
        items: [item],
        type: mediaType,
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
