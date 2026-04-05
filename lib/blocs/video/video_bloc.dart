import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:media_player/blocs/video/video_event.dart';
import 'package:media_player/blocs/video/video_state.dart';
import 'package:photo_manager/photo_manager.dart';


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
    // Avoid reloading every time screen is revisited.
    if (!event.isRefresh && state is VideoLoaded) return;

    final List<String> cachedIds = box.values.cast<String>().toList();
    List<AssetEntity> cachedEntities = [];
    if (cachedIds.isNotEmpty) {
      for (String id in cachedIds) {
        final entity = await AssetEntity.fromId(id);
        if (entity != null) cachedEntities.add(entity);
      }
      // ૨. તરત જ Loading સ્ટેટમાં જૂનો ડેટા બતાવો (સ્ક્રીન ખાલી નહીં થાય)
      // emit(VideoLoading(entities: cachedEntities));
    } else if (event.showLoading) {
      emit(VideoLoading());
    }

    final perm = await PhotoManager.requestPermissionExtend(
      requestOption: PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.fromTypes([RequestType.audio, RequestType.video]),
          mediaLocation: false,
        ),
      ),
    );
    if (!perm.hasAccess) {
      emit(VideoError(
        'Video access denied. Open Settings → Permissions, allow Photos & video, then retry.',
      ));
      return;
    }

    Future<List<AssetPathEntity>> loadPaths({required bool onlyAll}) {
      return PhotoManager.getAssetPathList(
        type: RequestType.video,
        hasAll: true,
        onlyAll: onlyAll,
      );
    }

    var paths = await loadPaths(onlyAll: true);
    if (paths.isEmpty) {
      paths = await loadPaths(onlyAll: false);
    }

    if (paths.isEmpty) {
      emit(VideoError(
        'No videos found. If files are on an SD card, wait for media scan then retry.',
      ));
      return;
    }

    var bestIdx = 0;
    var bestCount = await paths[0].assetCountAsync;
    for (var i = 1; i < paths.length; i++) {
      final c = await paths[i].assetCountAsync;
      if (c > bestCount) {
        bestCount = c;
        bestIdx = i;
      }
    }

    List<AssetEntity> latestEntities;
    AssetPathEntity mainPath;

    if (bestCount > 0) {
      mainPath = paths[bestIdx];
      latestEntities =
          await mainPath.getAssetListRange(start: 0, end: bestCount);
    } else {
      final byId = <String, AssetEntity>{};
      for (final p in paths) {
        final n = await p.assetCountAsync;
        if (n == 0) continue;
        final chunk = await p.getAssetListRange(start: 0, end: n);
        for (final e in chunk) {
          if (e.type == AssetType.video) {
            byId[e.id] = e;
          }
        }
      }
      latestEntities = byId.values.toList();
      mainPath = paths.first;
    }

    if (latestEntities.isEmpty) {
      emit(VideoError(
        'No videos found. If files are on an SD card, wait for media scan then retry.',
      ));
      return;
    }

    latestEntities.sort((a, b) {
      final na = (a.title ?? a.id).toLowerCase();
      final nb = (b.title ?? b.id).toLowerCase();
      return na.compareTo(nb);
    });

    await box.clear();
    await box.addAll(latestEntities.map((e) => e.id).toList());

    emit(VideoLoaded(
      entities: latestEntities,
      path: mainPath,
      page: 0,
      totalCount: latestEntities.length,
      hasMore: false,
    ));
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:media_player/blocs/video/video_event.dart';
import 'package:media_player/blocs/video/video_state.dart';
import 'package:media_player/widgets/common_methods.dart';
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
    final List<String> cachedIds = box.values.cast<String>().toList();
    List<AssetEntity> cachedEntities = [];
    if (cachedIds.isNotEmpty) {
      for (String id in cachedIds) {
        final entity = await AssetEntity.fromId(id);
        if (entity != null) cachedEntities.add(entity);
      }
      // ૨. તરત જ Loading સ્ટેટમાં જૂનો ડેટા બતાવો (સ્ક્રીન ખાલી નહીં થાય)
      // emit(VideoLoading(entities: cachedEntities));
    } else if (event.showLoading) {
      emit(VideoLoading());
    }
    // ૩. હવે PhotoManager થી સાચો પાથ અને નવો ડેટા લાવો
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.video,
    );

    if (paths.isNotEmpty) {
      final AssetPathEntity mainPath = paths[0]; // "All Audios" પાથ
      final int totalCount = await mainPath.assetCountAsync;
      final List<AssetEntity> latestEntities = await mainPath.getAssetListRange(
        start: 0,
        end: 20, // શરૂઆતના ૫૦ ગીતો
      );

      // ૪. Hive અપડેટ કરો
      await box.clear();
      await box.addAll(latestEntities.map((e) => e.id).toList());

      // ૫. હવે તમારી બધી Required પ્રોપર્ટીઝ સાથે AudioLoaded ઈમિટ કરો
      emit(VideoLoaded(
        entities: latestEntities,
        path: mainPath,
        page: 0,
        totalCount: totalCount,
        hasMore: latestEntities.length < totalCount,
      ));
    }
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
 */