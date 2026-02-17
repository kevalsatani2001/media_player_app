///////////////////////////////////////////////////////////////

import 'package:hive/hive.dart';

part 'media_item.g.dart';

@HiveType(typeId: 1) // ⚠ choose unique number (not 47!)
class MediaItem extends HiveObject {

  @HiveField(0)
  final String path;

  @HiveField(1)
  final bool isNetwork;

  @HiveField(2)
  final String type;

  @HiveField(3)
  String? id;

  @HiveField(4)
  bool? isFavourite;

  MediaItem({
    required this.path,
    required this.isNetwork,
    required this.type,
    this.id,
    this.isFavourite,
  });

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'isNetwork': isNetwork,
      'type': type,
      'id': id,
      'isFavourite': isFavourite,
    };
  }


  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      path: map['path'],
      isNetwork: map['isNetwork'],
      type: map['type'],
      id: map['id'],
      isFavourite: map['isFavourite'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MediaItem && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;
}


