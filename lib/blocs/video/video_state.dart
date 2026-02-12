// part of 'video_bloc.dart';
//
// abstract class VideoState {}
//
// class VideoInitial extends VideoState {}
//
// class VideoLoading extends VideoState {}
//
// class VideoError extends VideoState {
//   final String message;
//   VideoError(this.message);
// }
//
// class VideoLoaded extends VideoState {
//   final List<AssetEntity> entities;
//   final AssetPathEntity path;
//   final int page;
//   final int totalCount;
//   final bool hasMore;
//
//   VideoLoaded({
//     required this.entities,
//     required this.path,
//     required this.page,
//     required this.totalCount,
//     required this.hasMore,
//   });
//
//   VideoLoaded copyWith({
//     List<AssetEntity>? entities,
//     AssetPathEntity? path,
//     int? page,
//     int? totalCount,
//     bool? hasMore,
//   }) {
//     return VideoLoaded(
//       entities: entities ?? this.entities,
//       path: path ?? this.path,
//       page: page ?? this.page,
//       totalCount: totalCount ?? this.totalCount,
//       hasMore: hasMore ?? this.hasMore,
//     );
//   }
// }
//
// // When Hive is updated (new picked videos)
// class HiveVideoUpdated extends VideoState {
//   final List<MediaItem> videos;
//   HiveVideoUpdated(this.videos);
// }

// part of 'video_bloc.dart';

import 'package:photo_manager/photo_manager.dart';

import '../../models/media_item.dart';

abstract class VideoState {}

class VideoInitial extends VideoState {}

class VideoLoading extends VideoState {}

class VideoError extends VideoState {
  final String message;
  VideoError(this.message);
}

class VideoLoaded extends VideoState {
  final List<AssetEntity> entities;
  final AssetPathEntity path;
  final int page;
  final int totalCount;
  final bool hasMore;

  final int videoCount;
  final int audioCount;
  final int favouriteCount;
  final int playlistCount;

  VideoLoaded({
    required this.entities,
    required this.path,
    required this.page,
    required this.totalCount,
    required this.hasMore,
    this.videoCount = 0,
    this.audioCount = 0,
    this.favouriteCount = 0,
    this.playlistCount = 0,
  });

  VideoLoaded copyWith({
    List<AssetEntity>? entities,
    AssetPathEntity? path,
    int? page,
    int? totalCount,
    bool? hasMore,
    int? videoCount,
    int? audioCount,
    int? favouriteCount,
    int? playlistCount,
  }) {
    return VideoLoaded(
      entities: entities ?? this.entities,
      path: path ?? this.path,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      videoCount: videoCount ?? this.videoCount,
      audioCount: audioCount ?? this.audioCount,
      favouriteCount: favouriteCount ?? this.favouriteCount,
      playlistCount: playlistCount ?? this.playlistCount,
    );
  }
}


class CountsUpdated extends VideoState {
  final int videoCount;
  final int audioCount;
  final int favouriteCount;
  final int playlistCount;

  CountsUpdated({
    required this.videoCount,
    required this.audioCount,
    required this.favouriteCount,
    required this.playlistCount,
  });
}



// When Hive is updated (new picked videos)
class HiveVideoUpdated extends VideoState {
  final List<MediaItem> videos;

  HiveVideoUpdated(this.videos);
}