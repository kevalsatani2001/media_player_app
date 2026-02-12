import '../../models/media_item.dart';

abstract class PlayerEvent {}

class PlayMedia extends PlayerEvent {
  final MediaItem item;

  PlayMedia(this.item);
}

class ToggleLike extends PlayerEvent {
  final MediaItem item;

  ToggleLike(this.item);
}
