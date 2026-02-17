import 'package:hive/hive.dart';

part 'player_data.g.dart';

@HiveType(typeId: 3)
class PlayerState extends HiveObject {
  @HiveField(0)
  List<String> paths = []; // file paths of all MediaItems

  @HiveField(1)
  int currentIndex = 0;

  @HiveField(2)
  String currentType = "audio"; // "audio" or "video"

  @HiveField(3)
  int currentPositionMs = 0; // optional: save current position
}
