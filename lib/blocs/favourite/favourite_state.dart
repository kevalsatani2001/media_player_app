import 'package:photo_manager/photo_manager.dart';
import '../../models/media_item.dart';

abstract class FavouriteState {
  const FavouriteState();
}

class FavouriteInitial extends FavouriteState {}

class FavouriteLoading extends FavouriteState {}

class FavouriteLoaded extends FavouriteState {
  final List<AssetEntity> entities;
  final AssetPathEntity path;
  final int page;
  final int totalCount;
  final bool hasMore;

  FavouriteLoaded({
    required this.entities,
    required this.path,
    required this.page,
    required this.totalCount,
    required this.hasMore,
  });

  FavouriteLoaded copyWith({
    List<AssetEntity>? entities,
    AssetPathEntity? path,
    int? page,
    int? totalCount,
    bool? hasMore,
  }) {
    return FavouriteLoaded(
      entities: entities ?? this.entities,
      path: path ?? this.path,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class FavouriteError extends FavouriteState {
  final String message;

  const FavouriteError(this.message);
}

// When Hive is updated (new picked videos)
class HiveFavouriteUpdated extends FavouriteState {
  final List<MediaItem> favourites;
  HiveFavouriteUpdated(this.favourites);
}

