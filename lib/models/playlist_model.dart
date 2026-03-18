import 'package:hive/hive.dart';
import 'media_item.dart';

part 'playlist_model.g.dart';


// playlist_model.dart
@HiveType(typeId: 2)
class PlaylistModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<MediaItem> items;

  @HiveField(2)
  String type; // 'audio' àª…àª¥àªµàª¾ 'video'

  PlaylistModel({required this.name, required this.items, required this.type});
}

//flutter pub run build_runner build --delete-conflicting-outputs

/*
  better_player_plus:
  flick_video_player:
  visibility_detector:
  screen_brightness:
  volume_controller: ^2.0.3
 */