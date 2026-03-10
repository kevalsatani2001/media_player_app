import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';

import 'count_event.dart';
import 'count_state.dart';

class HomeCountBloc extends Bloc<HomeCountEvent, HomeCountState> {
  StreamSubscription? _recent;
  StreamSubscription? _videoSub;
  StreamSubscription? _audioSub;
  StreamSubscription? _favSub;
  StreamSubscription? _playlistSub;

  HomeCountBloc() : super(HomeCountState.initial()) {
    // count_bloc.dart
    void silentSyncWithHive(int v, int a) async {
      final vBox = Hive.box('videos');
      final aBox = Hive.box('audios');

      if (vBox.length != v) {
        await vBox.clear();
        for (int i = 0; i < v; i++) vBox.put('v_$i', 'c');
      }

      if (aBox.length != a) {
        await aBox.clear();
        for (int i = 0; i < a; i++) aBox.put('a_$i', 'c');
      }
    }
    // âœ¨ àª…àª¹à«€àª‚ àª•à«‹àª² àª•àª°à«‹: àª†àª¨àª¾àª¥à«€ àª¬à«àª²à«‹àª• àª¬àª¨àª¤àª¾àª¨à«€ àª¸àª¾àª¥à«‡ àªœ àª²àª¿àª¸àª¨àª¿àª‚àª— àªšàª¾àª²à« àª¥àª¶à«‡
    _listenHive();
    on<LoadCounts>((event, emit) {
      // à«§. àªªàª¹à«‡àª²àª¾ àªœà«‡ Hive àª®àª¾àª‚ àªªàª¡à«àª¯à«àª‚ àª¹à«‹àª¯ àª¤à«‡ àª¤àª°àª¤ àª¬àª¤àª¾àªµà«€ àª¦à«‹ (Zero lag)
      _emitCounts(emit);

      // à«¨. ðŸ”´ UI àª¨à«‡ àª¬à«àª²à«‹àª• àª•àª°à«àª¯àª¾ àªµàª—àª° àª¬à«‡àª•àª—à«àª°àª¾àª‰àª¨à«àª¡àª®àª¾àª‚ àª—àª£àª¤àª°à«€ àªšàª¾àª²à« àª•àª°à«‹
      // àª…àª¹à«€àª‚ await àª¨àª¥à«€ àªàªŸàª²à«‡ UI àª…àªŸàª•àª¶à«‡ àª¨àª¹à«€àª‚
      PhotoManager.getAssetCount(type: RequestType.video).then((vCount) {
        PhotoManager.getAssetCount(type: RequestType.audio).then((aCount) {

          // à«©. àªœà«àª¯àª¾àª°à«‡ àª¡à«‡àªŸàª¾ àª®àª³à«€ àªœàª¾àª¯ àª¤à«àª¯àª¾àª°à«‡ 'RefreshCountsWithData' àª‡àªµà«‡àª¨à«àªŸ àª«àª¾àª¯àª° àª•àª°à«‹
          // àª† àª‡àªµà«‡àª¨à«àªŸ àª†àªªàª£à«‡ àª…àª—àª¾àª‰ àª¬àª¨àª¾àªµà«àª¯à«‹ àª¹àª¤à«‹
          if (!isClosed) {
            add(RefreshCountsWithData(vCount, aCount));
          }

          // à«ª. (Optional) Hive àª®àª¾àª‚ àª¡àª®à«€ àª¡à«‡àªŸàª¾ àª­àª°à«€ àª¦à«‡àªµà«‹ àªœà«‡àª¥à«€ àª¨à«‡àª•à«àª¸à«àªŸ àªŸàª¾àªˆàª® àªàªª àª–à«‹àª²à«‹ àª¤à«àª¯àª¾àª°à«‡ àª¸à«€àª§à«‹ àª†àª‚àª•àª¡à«‹ àª®àª³à«‡
          silentSyncWithHive(vCount, aCount);
        });
      });
    });

// àª† àª«àª‚àª•à«àª¶àª¨ àª¬à«‡àª•àª—à«àª°àª¾àª‰àª¨à«àª¡àª®àª¾àª‚ Hive àª…àªªàª¡à«‡àªŸ àª•àª°àª¶à«‡

    on<RefreshCountsWithData>((event, emit) {
      emit(state.copyWith(
        videoCount: event.vCount,
        audioCount: event.aCount,
      ));
    });

    on<RefreshCounts>((event, emit) async{
      // await _emitCounts(emit);
    });
  }
  void _syncWithHive(int v, int a) async {
    final vBox = Hive.box('videos');
    final aBox = Hive.box('audios');

    if(vBox.length != v) {
      await vBox.clear();
      for(int i=0; i<v; i++) vBox.put('v_$i', 'c');
    }

    if(aBox.length != a) {
      await aBox.clear();
      for(int i=0; i<a; i++) aBox.put('a_$i', 'c');
    }
  }
  // count_bloc.dart

  // count_bloc.dart
  void _emitCounts(Emitter<HomeCountState> emit) {
    // àª•à«‹àªˆ await àª¨àª¹à«€àª‚, àª«àª•à«àª¤ Hive àª®àª¾àª‚àª¥à«€ àª¡à«‡àªŸàª¾ àª²à«‹
    emit(HomeCountState(
        videoCount: Hive.box('videos').length,
        audioCount: Hive.box('audios').length,
        favouriteCount: Hive.box('favourites').length,
        playlistCount: Hive.box('playlists').length,
        recentCount: Hive.box('recents').length
    ));
  }

  Future<void> silentMediaSync() async {
    // à«§. àªªàª°àª®àª¿àª¶àª¨ àªšà«‡àª•
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) return;

    // à«¨. àªµàª¿àª¡àª¿àª¯à«‹ àª…àª¨à«‡ àª“àª¡àª¿àª¯à«‹àª¨àª¾ àª†àªˆàª¡à«€ àª®à«‡àª³àªµà«‹
    // àª…àª¹à«€àª‚ àª†àªªàª£à«‡ 'onlyAll: true' àªµàª¾àªªàª°à«€àª¶à«àª‚ àªœà«‡àª¥à«€ àªàª• àªœ àªµàª¾àª°àª®àª¾àª‚ àª¬àª§à«àª‚ àª®àª³à«€ àªœàª¾àª¯
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.fromTypes([RequestType.video, RequestType.audio]),
      onlyAll: true,
    );

    if (paths.isEmpty) return;

    final recentPath = paths.first;
    final int totalCount = await recentPath.assetCountAsync;

    // à«©. àª¡à«‡àªŸàª¾ àª«à«‡àªš àª•àª°à«‹ (àª…àª¹à«€àª‚ àªŸà«àª°à«€àª• àª›à«‡: àª†àªªàª£à«‡ Pagination àª¨àª¥à«€ àª•àª°àª¤àª¾, àªªàª£ àª¸à«€àª§àª¾ IDs àª²àªˆàª àª›à«€àª)
    final List<AssetEntity> entities = await recentPath.getAssetListRange(
      start: 0,
      end: totalCount,
    );

    final videoBox = Hive.box('videos');
    final audioBox = Hive.box('audios');

    // àªœà«‚àª¨à«‹ àª¡à«‡àªŸàª¾ àª•à«àª²à«€àª¨ àª•àª°à«€àª¨à«‡ àª¨àªµà«‹ àª¡à«‡àªŸàª¾ àª­àª°à«‹
    // àª¨à«‹àª‚àª§: àª…àª¹à«€àª‚ .file àª•à«‡ thumbnail àª¨àª¥à«€ àª²à«‡àª¤àª¾ àªàªŸàª²à«‡ àª²à«‹àª¡ àª¨àª¹à«€àª‚ àªªàª¡à«‡
    await videoBox.clear();
    await audioBox.clear();

    for (var entity in entities) {
      if (entity.type == AssetType.video) {
        videoBox.put(entity.id, entity.title);
      } else if (entity.type == AssetType.audio) {
        audioBox.put(entity.id, entity.title);
      }
    }
  }

  void _listenHive() {
    _videoSub = Hive.box('videos').watch().listen((_) {
      if (!isClosed) add(RefreshCounts()); // àª¬à«àª²à«‹àª• àª–à«àª²à«àª²à«‹ àª¹à«‹àª¯ àª¤à«‹ àªœ àª‡àªµà«‡àª¨à«àªŸ àªàª¡ àª•àª°à«‹
    });

    _audioSub = Hive.box('audios').watch().listen((_) {
      if (!isClosed) add(RefreshCounts());
    });

    Hive.box('favourites').watch().listen((event) {
      // àªœà«‡àªµà«àª‚ àª«à«‡àªµàª°àª¿àªŸ àª¬à«‹àª•à«àª¸àª®àª¾àª‚ àª¡à«‡àªŸàª¾ àª¸à«‡àªµ àª¥àª¶à«‡, àª† àª¤àª°àª¤ àª¹à«‹àª® àªªà«‡àªœ àª…àªªàª¡à«‡àªŸ àª•àª°àª¶à«‡
      if (!isClosed) add(RefreshCounts());
    });

    _playlistSub = Hive.box('playlists').watch().listen((_) {
      if (!isClosed) add(RefreshCounts());
    });
  }


  @override
  Future<void> close() {
    _videoSub?.cancel();
    _audioSub?.cancel();
    _favSub?.cancel();
    _playlistSub?.cancel();
    _recent?.cancel(); // àª† àªªàª£ àª‰àª®à«‡àª°à«€ àª¦à«‹
    return super.close();
  }

}


////////////////////////////


/*
abstract class HomeCountEvent {}

class LoadCounts extends HomeCountEvent {}

class RefreshCounts extends HomeCountEvent {}
class RefreshCountsWithData extends HomeCountEvent {
  final int vCount;
  final int aCount;

  RefreshCountsWithData(this.vCount, this.aCount);
}
 */





/*

 */





// import 'dart:async';
//
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hive/hive.dart';
//
// import 'count_event.dart';
// import 'count_state.dart';
//
// class HomeCountBloc extends Bloc<HomeCountEvent, HomeCountState> {
//   StreamSubscription? _recent;
//   StreamSubscription? _videoSub;
//   StreamSubscription? _audioSub;
//   StreamSubscription? _favSub;
//   StreamSubscription? _playlistSub;
//
//   HomeCountBloc() : super(HomeCountState.initial()) {
//     on<LoadCounts>((event, emit) {
//       _emitCounts(emit);
//       _listenHive(); // start listening
//     });
//
//     on<RefreshCounts>((event, emit) {
//       _emitCounts(emit);
//     });
//   }
//
//   void _emitCounts(Emitter<HomeCountState> emit) {
//     final recentCount = Hive.box('recents').length;
//     final videoCount = Hive.box('videos').length;
//     final audioCount = Hive.box('audios').length;
//     final favouriteCount = Hive.box('favourites').length;
//     final playlistCount = Hive.box('playlists').length;
//
//     emit(HomeCountState(
//         videoCount: videoCount,
//         audioCount: audioCount,
//         favouriteCount: favouriteCount,
//         playlistCount: playlistCount,
//         recentCount: recentCount
//
//     ));
//   }
//
//   void _listenHive() {
//     _videoSub = Hive.box('videos').watch().listen((_) {
//       add(RefreshCounts());
//     });
//
//     _audioSub = Hive.box('audios').watch().listen((_) {
//       add(RefreshCounts());
//     });
//
//     _favSub = Hive.box('favourites').watch().listen((_) {
//       add(RefreshCounts());
//     });
//
//     _playlistSub = Hive.box('playlists').watch().listen((_) {
//       add(RefreshCounts());
//     });
//   }
//
//   @override
//   Future<void> close() {
//     _videoSub?.cancel();
//     _audioSub?.cancel();
//     _favSub?.cancel();
//     _playlistSub?.cancel();
//     return super.close();
//   }
// }
//
//
// ////////////////////////////
//
//
//
// ////////////////////////////////////
//
//
//