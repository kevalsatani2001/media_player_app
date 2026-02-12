import 'package:equatable/equatable.dart';

import '../../models/media_item.dart';

class MediaState extends Equatable {
  final List<MediaItem> items;

  const MediaState(this.items);

  @override
  List<Object?> get props => [items];
}
