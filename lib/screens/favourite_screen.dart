import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:media_player/screens/search_screen.dart';
import 'package:media_player/screens/setting_screen.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import '../blocs/favourite/favourite_bloc.dart';
import '../blocs/favourite/favourite_state.dart';
import '../blocs/video/video_bloc.dart';
import '../blocs/video/video_event.dart';
import '../core/constants.dart';
import '../models/media_item.dart';
import '../widgets/add_to_playlist.dart';
import '../widgets/custom_loader.dart';
import '../widgets/image_item_widget.dart';
import '../widgets/image_widget.dart';
import '../widgets/text_widget.dart';
import 'bottom_bar_screen.dart';
import 'detail_screen.dart';
import 'player_screen.dart';
import 'home_screen.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  @override
  Widget build(BuildContext context) {
    final box = Hive.box('favourites');

    return BlocProvider(
      create: (_) => FavouriteBloc(box)..add(LoadFavourite()),
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20),
            ),
          ),
          centerTitle: true,
          title: AppText(
            "favourite",
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        body: BlocBuilder<FavouriteBloc, FavouriteState>(
          builder: (context, state) {
            if (state is FavouriteLoading) {
              return Center(child: CustomLoader());
            }

            if (state is FavouriteError) {
              return Center(child: Text(state.message));
            }

            if (state is FavouriteLoaded) {
              if (state.entities.isEmpty) {
                return Center(
                  child: Text(
                    "${context.tr("noFavouriteYet")}\n${context.tr("addSomeVideosOrAudio")}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return _FavouriteGrid(state: state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _FavouriteGrid extends StatelessWidget {
  final FavouriteLoaded state;

  const _FavouriteGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final entities = state.entities;

    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 15,
        childAspectRatio: 1.05,
      ),
      itemCount: entities.length,
      itemBuilder: (context, index) {
        if (index == entities.length - 8 && state.hasMore) {
          context.read<FavouriteBloc>().add(LoadMoreFavourites());
        }

        return GestureDetector(
          onTap: () {
            // ૧. લિસ્ટમાંથી માત્ર AssetEntity ફિલ્ટર કરો
            final List<AssetEntity> validEntities = entities
                .whereType<AssetEntity>()
                .toList();

            // ૨. સાચો ઇન્ડેક્સ શોધો
            final int actualIndex = validEntities.indexOf(
              entities[index] as AssetEntity,
            );
            print("index is ===> $actualIndex");
            print("index is ===> ${validEntities.length}");

            if (actualIndex != -1) {
              _navigateToPlayer(context, validEntities, actualIndex);
            }
          },
          child: _FavouriteItem(
            entity: entities[index],
            index: index,
            entityList: entities,
          ),
        );
      },
    );
  }

  void _navigateToPlayer(
      BuildContext context,
      List<AssetEntity> allEntities,
      int currentIndex,
      ) async {
    final entity = allEntities[currentIndex];
    final file = await entity.file;

    if (file == null || !file.existsSync()) return;
    print("ent===> ${entity.type}");
    print("ent===> ${entity.title}");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          entity: entity,
          item: MediaItem(
            isFavourite: entity.isFavorite,
            id: entity.id,
            path: file.path,
            isNetwork: false,
            // અહીં entity.type નો ઉપયોગ કરવો વધુ સુરક્ષિત છે
            type: entity.type == AssetType.audio ? "audio" : "video",
          ),
          index: currentIndex,
          entityList: allEntities,
        ),
      ),
    ).then((value) {
      // પાછા આવ્યા પછી ફેવરિટ લિસ્ટ રિફ્રેશ કરવા માટે
      context.read<FavouriteBloc>().add(LoadFavourite());
    });
  }
}

class _FavouriteItem extends StatelessWidget {
  final AssetEntity entity;
  List<AssetEntity> entityList;
  final int index;

  _FavouriteItem({
    required this.entity,
    required this.index,
    required this.entityList,
  });

  ThumbnailOption get _thumbOption =>
      const ThumbnailOption(size: ThumbnailSize.square(200));

  @override
  Widget build(BuildContext context) {
    return ImageItemWidget(
      key: ValueKey(entity.id),
      entity: entity,
      option: _thumbOption,
      onMenuSelected: (action) async {
        switch (action) {
          case MediaMenuAction.detail:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailPage(entity: entity)),
            );
            break;

          case MediaMenuAction.info:
            showInfoDialog(context, entity);
            break;

          case MediaMenuAction.thumb:
            _showThumb(context, entity);
            break;

          case MediaMenuAction.share:
            _share(entity);
            break;

          case MediaMenuAction.delete:
          // optional: implement delete via Bloc later
            break;

          case MediaMenuAction.addToFavourite:
            context.read<FavouriteBloc>().add(ToggleFavourite(entity, index));
            break;
          case MediaMenuAction.addToPlaylist:
            final file = await entity.file;
            addToPlaylist(
              MediaItem(
                path: file!.path,
                isNetwork: false,
                type: entity.type == AssetType.audio ? "audio" : "video",
                id: entity.id,
                isFavourite: entity.isFavorite,
              ),
              context,
            );
            break;
        }
      },
      onTap: null,
    );
  }
}

Future<void> _share(AssetEntity entity) async {
  final file = await entity.file;
  if (file == null) return;
  Share.shareXFiles([XFile(file.path)], text: entity.title);
}

Future<void> _showThumb(BuildContext context, AssetEntity entity) {
  return showDialog(
    context: context,
    builder: (_) => FutureBuilder<Uint8List?>(
      future: entity.thumbnailDataWithOption(
        const ThumbnailOption(size: ThumbnailSize.square(500)),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.memory(snapshot.data!),
          );
        }
        return Center(child: CustomLoader());
      },
    ),
  );
}




















// import 'dart:typed_data';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hive/hive.dart';
// import 'package:media_player/screens/search_screen.dart';
// import 'package:media_player/screens/setting_screen.dart';
// import 'package:photo_manager/photo_manager.dart';
// import 'package:share_plus/share_plus.dart';
// import '../blocs/favourite/favourite_bloc.dart';
// import '../blocs/favourite/favourite_state.dart';
// import '../blocs/video/video_bloc.dart';
// import '../blocs/video/video_event.dart';
// import '../core/constants.dart';
// import '../models/media_item.dart';
// import '../widgets/add_to_playlist.dart';
// import '../widgets/custom_loader.dart';
// import '../widgets/image_item_widget.dart';
// import '../widgets/image_widget.dart';
// import '../widgets/text_widget.dart';
// import 'bottom_bar_screen.dart';
// import 'detail_screen.dart';
// import 'player_screen.dart';
// import 'home_screen.dart';
//
// class FavouriteScreen extends StatefulWidget {
//   const FavouriteScreen({super.key});
//
//   @override
//   State<FavouriteScreen> createState() => _FavouriteScreenState();
// }
//
// class _FavouriteScreenState extends State<FavouriteScreen> {
//   @override
//   Widget build(BuildContext context) {
//     final box = Hive.box('favourites');
//
//     return BlocProvider(
//       create: (_) => FavouriteBloc(box)..add(LoadFavourite()),
//       child: Scaffold(
//         appBar: AppBar(
//           leading: Padding(
//             padding: const EdgeInsets.all(16),
//             child: GestureDetector(
//               onTap: () => Navigator.pop(context),
//               child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20),
//             ),
//           ),
//           centerTitle: true,
//           title: AppText(
//             "favourite",
//             fontSize: 20,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         body: BlocBuilder<FavouriteBloc, FavouriteState>(
//           builder: (context, state) {
//             if (state is FavouriteLoading) {
//               return Center(child: CustomLoader());
//             }
//
//             if (state is FavouriteError) {
//               return Center(child: Text(state.message));
//             }
//
//             if (state is FavouriteLoaded) {
//               if (state.entities.isEmpty) {
//                 return Center(
//                   child: Text(
//                     "${context.tr("noFavouriteYet")}\n${context.tr("addSomeVideosOrAudio")}",
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                 );
//               }
//
//               return _FavouriteGrid(state: state);
//             }
//
//             return const SizedBox.shrink();
//           },
//         ),
//       ),
//     );
//   }
// }
//
// class _FavouriteGrid extends StatelessWidget {
//   final FavouriteLoaded state;
//
//   const _FavouriteGrid({required this.state});
//
//   @override
//   Widget build(BuildContext context) {
//     final entities = state.entities;
//
//     return GridView.builder(
//       padding: const EdgeInsets.all(15),
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 15,
//         childAspectRatio: 1.05,
//       ),
//       itemCount: entities.length,
//       itemBuilder: (context, index) {
//         if (index == entities.length - 8 && state.hasMore) {
//           context.read<FavouriteBloc>().add(LoadMoreFavourites());
//         }
//
//         return GestureDetector(
//           onTap: () {
//             // ૧. લિસ્ટમાંથી માત્ર AssetEntity ફિલ્ટર કરો
//             final List<AssetEntity> validEntities = entities
//                 .whereType<AssetEntity>()
//                 .toList();
//
//             // ૨. સાચો ઇન્ડેક્સ શોધો
//             final int actualIndex = validEntities.indexOf(
//               entities[index] as AssetEntity,
//             );
//             print("index is ===> $actualIndex");
//             print("index is ===> ${validEntities.length}");
//
//             if (actualIndex != -1) {
//               _navigateToPlayer(context, validEntities, actualIndex);
//             }
//           },
//           child: _FavouriteItem(
//             entity: entities[index],
//             index: index,
//             entityList: entities,
//           ),
//         );
//       },
//     );
//   }
//
//   void _navigateToPlayer(
//     BuildContext context,
//     List<AssetEntity> allEntities,
//     int currentIndex,
//   ) async {
//     final entity = allEntities[currentIndex];
//     final file = await entity.file;
//
//     if (file == null || !file.existsSync()) return;
//     print("ent===> ${entity.type}");
//     print("ent===> ${entity.title}");
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => PlayerScreen(
//           entity: entity,
//           item: MediaItem(
//             isFavourite: entity.isFavorite,
//             id: entity.id,
//             path: file.path,
//             isNetwork: false,
//             // અહીં entity.type નો ઉપયોગ કરવો વધુ સુરક્ષિત છે
//             type: entity.type == AssetType.audio ? "audio" : "video",
//           ),
//           index: currentIndex,
//           entityList: allEntities,
//         ),
//       ),
//     ).then((value) {
//       // પાછા આવ્યા પછી ફેવરિટ લિસ્ટ રિફ્રેશ કરવા માટે
//       context.read<FavouriteBloc>().add(LoadFavourite());
//     });
//   }
// }
//
// class _FavouriteItem extends StatelessWidget {
//   final AssetEntity entity;
//   List<AssetEntity> entityList;
//   final int index;
//
//   _FavouriteItem({
//     required this.entity,
//     required this.index,
//     required this.entityList,
//   });
//
//   ThumbnailOption get _thumbOption =>
//       const ThumbnailOption(size: ThumbnailSize.square(200));
//
//   @override
//   Widget build(BuildContext context) {
//     return ImageItemWidget(
//       key: ValueKey(entity.id),
//       entity: entity,
//       option: _thumbOption,
//       onMenuSelected: (action) async {
//         switch (action) {
//           case MediaMenuAction.detail:
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => DetailPage(entity: entity)),
//             );
//             break;
//
//           case MediaMenuAction.info:
//             showInfoDialog(context, entity);
//             break;
//
//           case MediaMenuAction.thumb:
//             _showThumb(context, entity);
//             break;
//
//           case MediaMenuAction.share:
//             _share(entity);
//             break;
//
//           case MediaMenuAction.delete:
//             // optional: implement delete via Bloc later
//             break;
//
//           case MediaMenuAction.addToFavourite:
//             context.read<FavouriteBloc>().add(ToggleFavourite(entity, index));
//             break;
//           case MediaMenuAction.addToPlaylist:
//             final file = await entity.file;
//             addToPlaylist(
//               MediaItem(
//                 path: file!.path,
//                 isNetwork: false,
//                 type: entity.type == AssetType.audio ? "audio" : "video",
//                 id: entity.id,
//                 isFavourite: entity.isFavorite,
//               ),
//               context,
//             );
//             break;
//         }
//       },
//       onTap: null,
//     );
//   }
// }
//
// Future<void> _share(AssetEntity entity) async {
//   final file = await entity.file;
//   if (file == null) return;
//   Share.shareXFiles([XFile(file.path)], text: entity.title);
// }
//
// Future<void> _showThumb(BuildContext context, AssetEntity entity) {
//   return showDialog(
//     context: context,
//     builder: (_) => FutureBuilder<Uint8List?>(
//       future: entity.thumbnailDataWithOption(
//         const ThumbnailOption(size: ThumbnailSize.square(500)),
//       ),
//       builder: (context, snapshot) {
//         if (snapshot.hasData) {
//           return GestureDetector(
//             onTap: () => Navigator.pop(context),
//             child: Image.memory(snapshot.data!),
//           );
//         }
//         return Center(child: CustomLoader());
//       },
//     ),
//   );
// }
