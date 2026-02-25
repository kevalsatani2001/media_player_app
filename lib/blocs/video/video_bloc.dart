import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:media_player/blocs/video/video_event.dart';
import 'package:media_player/blocs/video/video_state.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../models/media_item.dart';


class VideoBloc extends Bloc<VideoEvent, VideoState> {
  final Box box;
  int videoCount = 0;
  int audioCount = 0;
  int favouriteCount = 0;
  int playlistCount = 0;

  VideoBloc(this.box) : super(VideoInitial()) {
    on<LoadVideosFromGallery>(_onLoadVideosFromGallery);
    on<LoadMoreVideos>(_onLoadMoreVideos);
    on<RefreshCounts>(_onRefreshCounts);
  }

  Future<void> _onRefreshCounts(
      RefreshCounts event, Emitter<VideoState> emit) async {
    try {

      favouriteCount = Hive.box('favourites').length;
      playlistCount = Hive.box('playlists').length;
      videoCount =Hive.box('videos').length;
      audioCount = Hive.box('audios').length;
      if (state is VideoLoaded) {
        emit((state as VideoLoaded).copyWith(
          videoCount: videoCount,
          audioCount: audioCount,
          favouriteCount: favouriteCount,
          playlistCount: playlistCount,
        ));
      } else {
        emit(VideoInitial()); // fallback
      }
    } catch (e) {
      print("Failed to refresh counts: $e");
    }
  }

  // Load videos from gallery
  Future<void> _onLoadVideosFromGallery(
      LoadVideosFromGallery event,
      Emitter<VideoState> emit,
      ) async {

    if (event.showLoading ?? true) {
      emit(VideoLoading());
    }

    // ૧. પરમિશન અને પાથ મેળવો
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.video,
    );

    if (paths.isEmpty) {
      emit(VideoError('No videos found'));
      return;
    }

    final path = paths.first;
    final total = await path.assetCountAsync; // આખા ફોનના કુલ વીડિયો (દા.ત. 50)

    // ૨. પેજિનેશન માટે ડેટા લો (size વધારીને 20-50 કરી શકો છો)
    final entities = await path.getAssetListPaged(page: 0, size: 20);

    // ૩. 🔴 ડમી કાઉન્ટ લોજિક (આનાથી હોમ સ્ક્રીન પર સાચો આંકડો આવશે)
    // અહીં આપણે await entity.file નથી કરતા, એટલે લોડિંગનો ઇસ્યુ નહીં આવે
    final videoBox = Hive.box('videos');
    await videoBox.clear();

    for (int i = 0; i < total; i++) {
      // આપણે ફક્ત બોક્સની length વધારવી છે
      videoBox.put('video_dummy_$i', 'count_only');
    }

    // ૪. ડેટા ઈમિટ કરો
    emit(
      VideoLoaded(
        entities: entities,
        path: path,
        page: 0,
        totalCount: total,
        hasMore: entities.length < total,
      ),
    );
  }

  Future<void> _onLoadMoreVideos(LoadMoreVideos event, Emitter<VideoState> emit) async {
    final current = state;
    // જો પહેલેથી લોડિંગ ચાલતું હોય અથવા આપણે છેલ્લે પહોંચી ગયા હોઈએ તો અટકી જવું
    if (current is! VideoLoaded || !current.hasMore) return;

    // Pagination લોજિકમાં ચેક ઉમેરો કે શું આપણે ઓલરેડી લોડ કરી રહ્યા છીએ?
    // આ માટે તમે VideoState માં 'isLoadingMore' જેવો ફ્લેગ પણ રાખી શકો.

    const pageSize = 20;
    final nextPage = current.page + 1;

    final moreEntities = await current.path.getAssetListPaged(
      page: nextPage,
      size: pageSize,
    );

    if (moreEntities.isEmpty) {
      emit(current.copyWith(hasMore: false));
      return;
    }

    emit(current.copyWith(
      entities: [...current.entities, ...moreEntities],
      page: nextPage,
      hasMore: (current.entities.length + moreEntities.length) < current.totalCount,
    ));
  }

}



/*
abstract class VideoEvent{}

class LoadVideosFromGallery extends VideoEvent {
  final bool showLoading;
  final bool isRefresh;

  LoadVideosFromGallery({
    this.showLoading = true,
    this.isRefresh = false,
  });
}


class PickVideos extends VideoEvent {
  final Future<List<String>?> Function() filePicker;
  PickVideos(this.filePicker);
}

class LoadMoreVideos extends VideoEvent {}

class RefreshCounts extends VideoEvent {}
 */




/*
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
 */

















// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hive/hive.dart';
// import 'package:media_player/blocs/video/video_event.dart';
// import 'package:media_player/blocs/video/video_state.dart';
// import 'package:photo_manager/photo_manager.dart';
//
// import '../../models/media_item.dart';
//
//
// class VideoBloc extends Bloc<VideoEvent, VideoState> {
//   final Box box;
//   int videoCount = 0;
//   int audioCount = 0;
//   int favouriteCount = 0;
//   int playlistCount = 0;
//
//   VideoBloc(this.box) : super(VideoInitial()) {
//     on<LoadVideosFromGallery>(_onLoadVideosFromGallery);
//     // on<PickVideos>(_onPickVideos);
//     on<LoadMoreVideos>(_onLoadMoreVideos);
//     on<RefreshCounts>(_onRefreshCounts);
//   }
//
//   Future<void> _onRefreshCounts(
//       RefreshCounts event, Emitter<VideoState> emit) async {
//     try {
//       // final granted = await PhotoManager.requestPermissionExtend(
//       //   requestOption: PermissionRequestOption(
//       //     androidPermission: AndroidPermission(
//       //       type: RequestType.all,
//       //       mediaLocation: true,
//       //     ),
//       //   ),
//       // );
//       // if (!granted.hasAccess) {
//       //   videoCount = 0;
//       //   audioCount = 0;
//       favouriteCount = Hive.box('favourites').length;
//       playlistCount = Hive.box('playlists').length;
//       videoCount =Hive.box('videos').length;
//       audioCount = Hive.box('audios').length;
//       // } else {
//       //   videoCount = await PhotoManager.getAssetCount(type: RequestType.video);
//       //   audioCount = await PhotoManager.getAssetCount(type: RequestType.audio);
//       //   favouriteCount = Hive.box('favourites').length;
//       //   playlistCount = Hive.box('playlists').length;
//       // }
//
//       // ✅ Re-emit the current state to rebuild UI without losing video list
//       if (state is VideoLoaded) {
//         emit((state as VideoLoaded).copyWith(
//           videoCount: videoCount,
//           audioCount: audioCount,
//           favouriteCount: favouriteCount,
//           playlistCount: playlistCount,
//         ));
//       } else {
//         emit(VideoInitial()); // fallback
//       }
//     } catch (e) {
//       print("Failed to refresh counts: $e");
//     }
//   }
//
//   // Load videos from gallery
//   Future<void> _onLoadVideosFromGallery(
//       LoadVideosFromGallery event,
//       Emitter<VideoState> emit,
//       ) async {
//
//     if (event.showLoading ?? true) {
//       emit(VideoLoading());
//     }
//     if (event.isRefresh ?? false) {
//       await box.clear();
//     }
//
//     PermissionState ps;
//     try {
//       ps = await PhotoManager.requestPermissionExtend(
//         requestOption: PermissionRequestOption(
//           androidPermission: AndroidPermission(
//             type: RequestType.video,
//             mediaLocation: true,
//           ),
//         ),
//       );
//     } catch (e) {
//       emit(VideoError('Permission request failed'));
//       return;
//     }
//
//     if (!ps.hasAccess) {
//       emit(VideoError('Permission denied'));
//       return;
//     }
//
//     final filter = FilterOptionGroup(
//       videoOption: const FilterOption(
//         sizeConstraint: SizeConstraint(ignoreSize: true),
//       ),
//     );
//
//     final paths = await PhotoManager.getAssetPathList(
//       onlyAll: true,
//       type: RequestType.video,
//       filterOption: filter,
//     );
//
//     if (paths.isEmpty) {
//       emit(VideoError('No videos found'));
//       return;
//     }
//
//     final path = paths.first;
//     final total = await path.assetCountAsync;
//     final entities = await path.getAssetListPaged(page: 0, size: 2000);
//
//     await box.clear();
//     for (final entity in entities) {
//       final file = await entity.file;
//       if (file != null) {
//         box.put(
//           file.path,
//           MediaItem(path: file.path, isNetwork: false, type: 'video',id: entity.id,isFavourite: entity.isFavorite).toMap(),
//         );
//       }
//     }
//     emit(
//       VideoLoaded(
//
//         entities: entities,
//         path: path,
//         page: 0,
//         totalCount: total,
//         hasMore: entities.length < total,
//       ),
//     );
//
//   }
//
//
//
//
//   // Pick videos from file picker
//   // Future<void> _onPickVideos(PickVideos event, Emitter<VideoState> emit) async {
//   //   final result = await event.filePicker();
//   //   if (result == null) return;
//   //
//   //   for (final path in result) {
//   //     final item = MediaItem(path: path, isNetwork: false, type: 'video',isFavourite: );
//   //     box.put(path, item.toMap());
//   //   }
//   //
//   //   // Refresh current list from Hive
//   //   final videos = box.values
//   //       .map((e) => MediaItem.fromMap(Map<String, dynamic>.from(e)))
//   //       .toList();
//   //   emit(HiveVideoUpdated(videos));
//   // }
//
//   // Load more assets (pagination)
//   // Future<void> _onLoadMoreVideos(
//   //     LoadMoreVideos event,
//   //     Emitter<VideoState> emit,
//   //     ) async {
//   //   if (state is! VideoLoaded) return;
//   //
//   //   final current = state as VideoLoaded;
//   //   final nextPage = current.page + 1;
//   //
//   //   final moreEntities = await current.path.getAssetListPaged(
//   //     page: nextPage,
//   //     size: 50,
//   //   );
//   //
//   //   emit(
//   //     current.copyWith(
//   //       entities: [...current.entities, ...moreEntities],
//   //       page: nextPage,
//   //       hasMore:
//   //       current.entities.length + moreEntities.length < current.totalCount,
//   //     ),
//   //   );
//   // }
//   Future<void> _onLoadMoreVideos(LoadMoreVideos event, Emitter<VideoState> emit) async {
//     final current = state;
//     // જો પહેલેથી લોડિંગ ચાલતું હોય અથવા આપણે છેલ્લે પહોંચી ગયા હોઈએ તો અટકી જવું
//     if (current is! VideoLoaded || !current.hasMore) return;
//
//     // Pagination લોજિકમાં ચેક ઉમેરો કે શું આપણે ઓલરેડી લોડ કરી રહ્યા છીએ?
//     // આ માટે તમે VideoState માં 'isLoadingMore' જેવો ફ્લેગ પણ રાખી શકો.
//
//     const pageSize = 2000;
//     final nextPage = current.page + 1;
//
//     final moreEntities = await current.path.getAssetListPaged(
//       page: nextPage,
//       size: pageSize,
//     );
//
//     if (moreEntities.isEmpty) {
//       emit(current.copyWith(hasMore: false));
//       return;
//     }
//
//     emit(current.copyWith(
//       entities: [...current.entities, ...moreEntities],
//       page: nextPage,
//       hasMore: (current.entities.length + moreEntities.length) < current.totalCount,
//     ));
//   }
//
// }