// import 'dart:async';
// import 'package:bloc/bloc.dart';
// import 'package:hive/hive.dart';
// import 'package:media_player/blocs/video/video_event.dart';
// import 'package:media_player/blocs/video/video_state.dart';
// import 'package:photo_manager/photo_manager.dart';
// import '../../models/media_item.dart';
//
// class VideoBloc extends Bloc<VideoEvent, VideoState> {
//   final Box box;
//
//   VideoBloc(this.box) : super(VideoInitial()) {
//     on<LoadVideosFromGallery>(_onLoadVideosFromGallery);
//     on<PickVideos>(_onPickVideos);
//     on<LoadMoreVideos>(_onLoadMoreVideos);
//   }
//
//   // Load videos from gallery
//   Future<void> _onLoadVideosFromGallery(
//       LoadVideosFromGallery event,
//       Emitter<VideoState> emit,
//       ) async {
//     if (event.showLoading ?? true) {
//       emit(VideoLoading());
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
//     final entities = await path.getAssetListPaged(page: 0, size: 50);
//
//     await box.clear();
//     for (final entity in entities) {
//       final file = await entity.file;
//       if (file != null) {
//         box.put(
//           file.path,
//           MediaItem(path: file.path, isNetwork: false, type: 'video',id: entity.id).toMap(),
//         );
//       }
//     }
//
//     emit(
//       VideoLoaded(
//         entities: entities,
//         path: path,
//         page: 0,
//         totalCount: total,
//         hasMore: entities.length < total,
//       ),
//     );
//   }
//
//   // Pick videos from file picker
//   Future<void> _onPickVideos(PickVideos event, Emitter<VideoState> emit) async {
//     final result = await event.filePicker();
//     if (result == null) return;
//
//     for (final path in result) {
//       final item = MediaItem(path: path, isNetwork: false, type: 'video',);
//       box.put(path, item.toMap());
//     }
//
//     // Refresh current list from Hive
//     final videos = box.values
//         .map((e) => MediaItem.fromMap(Map<String, dynamic>.from(e)))
//         .toList();
//     emit(HiveVideoUpdated(videos));
//   }
//
//   // Load more assets (pagination)
//   Future<void> _onLoadMoreVideos(
//       LoadMoreVideos event,
//       Emitter<VideoState> emit,
//       ) async {
//     if (state is! VideoLoaded) return;
//
//     final current = state as VideoLoaded;
//     final nextPage = current.page + 1;
//
//     final moreEntities = await current.path.getAssetListPaged(
//       page: nextPage,
//       size: 50,
//     );
//
//     emit(
//       current.copyWith(
//         entities: [...current.entities, ...moreEntities],
//         page: nextPage,
//         hasMore:
//         current.entities.length + moreEntities.length < current.totalCount,
//       ),
//     );
//   }
// }

//////////////////////////////////////////////////////////////////////////////////




/////////////////////////////////////////////////////////////////////////////////////







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
    on<PickVideos>(_onPickVideos);
    on<LoadMoreVideos>(_onLoadMoreVideos);
    on<RefreshCounts>(_onRefreshCounts);
  }

  Future<void> _onRefreshCounts(
      RefreshCounts event, Emitter<VideoState> emit) async {
    try {
      // final granted = await PhotoManager.requestPermissionExtend(
      //   requestOption: PermissionRequestOption(
      //     androidPermission: AndroidPermission(
      //       type: RequestType.all,
      //       mediaLocation: true,
      //     ),
      //   ),
      // );
      // if (!granted.hasAccess) {
      //   videoCount = 0;
      //   audioCount = 0;
      favouriteCount = Hive.box('favourites').length;
      playlistCount = Hive.box('playlists').length;
      videoCount =Hive.box('videos').length;
      audioCount = Hive.box('audios').length;
      // } else {
      //   videoCount = await PhotoManager.getAssetCount(type: RequestType.video);
      //   audioCount = await PhotoManager.getAssetCount(type: RequestType.audio);
      //   favouriteCount = Hive.box('favourites').length;
      //   playlistCount = Hive.box('playlists').length;
      // }

      // ✅ Re-emit the current state to rebuild UI without losing video list
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

    PermissionState ps;
    try {
      ps = await PhotoManager.requestPermissionExtend(
        requestOption: PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.video,
            mediaLocation: true,
          ),
        ),
      );
    } catch (e) {
      emit(VideoError('Permission request failed'));
      return;
    }

    if (!ps.hasAccess) {
      emit(VideoError('Permission denied'));
      return;
    }

    final filter = FilterOptionGroup(
      videoOption: const FilterOption(
        sizeConstraint: SizeConstraint(ignoreSize: true),
      ),
    );

    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.video,
      filterOption: filter,
    );

    if (paths.isEmpty) {
      emit(VideoError('No videos found'));
      return;
    }

    final path = paths.first;
    final total = await path.assetCountAsync;
    final entities = await path.getAssetListPaged(page: 0, size: 50);

    await box.clear();
    for (final entity in entities) {
      final file = await entity.file;
      if (file != null) {
        box.put(
          file.path,
          MediaItem(path: file.path, isNetwork: false, type: 'video',id: entity.id).toMap(),
        );
      }
    }
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




  // Pick videos from file picker
  Future<void> _onPickVideos(PickVideos event, Emitter<VideoState> emit) async {
    final result = await event.filePicker();
    if (result == null) return;

    for (final path in result) {
      final item = MediaItem(path: path, isNetwork: false, type: 'video',);
      box.put(path, item.toMap());
    }

    // Refresh current list from Hive
    final videos = box.values
        .map((e) => MediaItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    emit(HiveVideoUpdated(videos));
  }

  // Load more assets (pagination)
  Future<void> _onLoadMoreVideos(
      LoadMoreVideos event,
      Emitter<VideoState> emit,
      ) async {
    if (state is! VideoLoaded) return;

    final current = state as VideoLoaded;
    final nextPage = current.page + 1;

    final moreEntities = await current.path.getAssetListPaged(
      page: nextPage,
      size: 50,
    );

    emit(
      current.copyWith(
        entities: [...current.entities, ...moreEntities],
        page: nextPage,
        hasMore:
        current.entities.length + moreEntities.length < current.totalCount,
      ),
    );
  }}