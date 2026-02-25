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
    on<LoadCounts>((event, emit) {
      // ૧. પહેલા જે Hive માં પડ્યું હોય તે તરત બતાવી દો (Zero lag)
      _emitCounts(emit);

      // ૨. 🔴 UI ને બ્લોક કર્યા વગર બેકગ્રાઉન્ડમાં ગણતરી ચાલુ કરો
      // અહીં await નથી એટલે UI અટકશે નહીં
      PhotoManager.getAssetCount(type: RequestType.video).then((vCount) {
        PhotoManager.getAssetCount(type: RequestType.audio).then((aCount) {

          // ૩. જ્યારે ડેટા મળી જાય ત્યારે 'RefreshCountsWithData' ઇવેન્ટ ફાયર કરો
          // આ ઇવેન્ટ આપણે અગાઉ બનાવ્યો હતો
          if (!isClosed) {
            add(RefreshCountsWithData(vCount, aCount));
          }

          // ૪. (Optional) Hive માં ડમી ડેટા ભરી દેવો જેથી નેક્સ્ટ ટાઈમ એપ ખોલો ત્યારે સીધો આંકડો મળે
          silentSyncWithHive(vCount, aCount);
        });
      });
    });

// આ ફંક્શન બેકગ્રાઉન્ડમાં Hive અપડેટ કરશે

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
    // કોઈ await નહીં, ફક્ત Hive માંથી ડેટા લો
    emit(HomeCountState(
        videoCount: Hive.box('videos').length,
        audioCount: Hive.box('audios').length,
        favouriteCount: Hive.box('favourites').length,
        playlistCount: Hive.box('playlists').length,
        recentCount: Hive.box('recents').length
    ));
  }

  Future<void> silentMediaSync() async {
    // ૧. પરમિશન ચેક
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) return;

    // ૨. વિડિયો અને ઓડિયોના આઈડી મેળવો
    // અહીં આપણે 'onlyAll: true' વાપરીશું જેથી એક જ વારમાં બધું મળી જાય
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.fromTypes([RequestType.video, RequestType.audio]),
      onlyAll: true,
    );

    if (paths.isEmpty) return;

    final recentPath = paths.first;
    final int totalCount = await recentPath.assetCountAsync;

    // ૩. ડેટા ફેચ કરો (અહીં ટ્રીક છે: આપણે Pagination નથી કરતા, પણ સીધા IDs લઈએ છીએ)
    final List<AssetEntity> entities = await recentPath.getAssetListRange(
      start: 0,
      end: totalCount,
    );

    final videoBox = Hive.box('videos');
    final audioBox = Hive.box('audios');

    // જૂનો ડેટા ક્લીન કરીને નવો ડેટા ભરો
    // નોંધ: અહીં .file કે thumbnail નથી લેતા એટલે લોડ નહીં પડે
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
      if (!isClosed) add(RefreshCounts()); // બ્લોક ખુલ્લો હોય તો જ ઇવેન્ટ એડ કરો
    });

    _audioSub = Hive.box('audios').watch().listen((_) {
      if (!isClosed) add(RefreshCounts());
    });

    _favSub = Hive.box('favourites').watch().listen((_) {
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
    _recent?.cancel(); // આ પણ ઉમેરી દો
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
