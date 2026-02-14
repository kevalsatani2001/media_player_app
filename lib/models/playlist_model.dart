import 'package:hive/hive.dart';
import 'media_item.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: 2)
class PlaylistModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<MediaItem> items;

  PlaylistModel({
    required this.name,
    required this.items,
  });
}
