import 'media_item.dart';

class PlaylistModel {
  final String name;
  final List<MediaItem> items;

  PlaylistModel({required this.name, required this.items});

  Map<String, dynamic> toMap() => {'name': name, 'items': items};
}
