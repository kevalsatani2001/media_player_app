import '../utils/app_imports.dart';

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
  static final Box favBox = Hive.box('favourites');

  static final ValueNotifier<String> favouriteSignal = ValueNotifier<String>(
    '',
  );

  static List<PlaylistModel> getPlaylistsByType(String type) {
    return _box.values
        .where((p) => p is PlaylistModel && p.type == type)
        .cast<PlaylistModel>()
        .toList();
  }

  static List getPlaylists() => _box.values.toList();

  Future<bool> toggleFavourite(AssetEntity entity) async {
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
    favouriteSignal.value =
    "${entity.id}_${DateTime.now().millisecondsSinceEpoch}";

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
}