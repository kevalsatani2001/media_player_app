
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
        appBar: AppBar(leading: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20),
          ),
        ),
          centerTitle: true,
          title: AppText("favourite", fontSize: 20, fontWeight: FontWeight.w500),),
        body: BlocBuilder<FavouriteBloc, FavouriteState>(
          builder: (context, state) {
            if (state is FavouriteLoading) {
              return  Center(child: CustomLoader());
            }

            if (state is FavouriteError) {
              return Center(child: Text(state.message));
            }

            if (state is FavouriteLoaded) {
              if (state.entities.isEmpty) {
                return Center(
                  child:


                  Text(
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
      gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(
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

        return _FavouriteItem(entity: entities[index], index: index);
      },
    );
  }
}

class _FavouriteItem extends StatelessWidget {
  final AssetEntity entity;
  final int index;

  const _FavouriteItem({required this.entity, required this.index});

  ThumbnailOption get _thumbOption =>
      const ThumbnailOption(size: ThumbnailSize.square(200));

  @override
  Widget build(BuildContext context) {
    return ImageItemWidget(
      key: ValueKey(entity.id),
      entity: entity,
      option: _thumbOption,
      onMenuSelected: (action) async{
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
                type: entity.type==AssetType.audio?"audio":"video",
                id: entity.id,
                isFavourite: entity.isFavorite,
              ),
              context,
            );
            break;
        }
      },
      onTap: () async {
        final file = await entity.file;
        if (file == null || !file.existsSync()) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<FavouriteBloc>(), // reuse the existing bloc
              child: PlayerScreen(
                item: MediaItem(id:entity.id,path: file.path, isNetwork: false, type: 'video',isFavourite: entity.isFavorite),
                index: index,
                entity: entity,
              ),
            ),
          ),
        );


        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => PlayerScreen(
        //
        //       item: MediaItem(path: file.path, isNetwork: false, type: 'video',isFavourite: entity.isFavorite),
        //     ),
        //   ),
        // );
      },
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
        return  Center(child: CustomLoader());
      },
    ),
  );
}