import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../blocs/video/video_bloc.dart';
import '../core/constants.dart';
import '../models/media_item.dart';
import '../screens/home_screen.dart';
import '../utils/app_colors.dart';
import 'image_widget.dart';

enum MediaMenuAction {
  detail,
  info,
  thumb,
  delete,
  share,
  addToFavourite
}


class ImageItemWidget extends StatefulWidget {
  ImageItemWidget({
    super.key,
    required this.entity,
    required this.option,
    this.onTap,
    this.onMenuSelected,
    this.isGrid = true,
  });

  final AssetEntity entity;
  final ThumbnailOption option;
  final GestureTapCallback? onTap;
  final bool isGrid;
  final void Function(MediaMenuAction action)? onMenuSelected;

  @override
  State<ImageItemWidget> createState() => _ImageItemWidgetState();
}

class _ImageItemWidgetState extends State<ImageItemWidget> {
  Widget buildContent(BuildContext context) {
    if (widget.entity.type == AssetType.audio) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: widget.entity is AssetEntity
                  ? Stack(
                children: [
                  Center(
                    child: Icon(Icons.audiotrack, size: 30),
                  ),
                  if (widget.entity.isFavorite)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle),
                          height: 20,
                          width: 20,

                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.all(0),
                          child: Center(
                            child: Icon(
                              Icons.favorite,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )


              // ImageItemWidget(
              //   isGrid: isGrid,
              //   onMenuSelected:onMenuSelected,
              //   onTap: onTap,
              //   entity: entity,
              //   option: const ThumbnailOption(
              //     size: ThumbnailSize.square(300),
              //   ),
              // )
                  : Container(color: Colors.black12),
            ),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AppText(
                        widget.entity.title ?? "",
                        maxLines: 1,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      // Text(
                      //   widget.entity.title??"",
                      //   maxLines: 2,
                      //   style: const TextStyle(color: Colors.white, fontSize: 12),
                      // ),
                      SizedBox(height: 8,),
                      if (widget.entity is AssetEntity) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(widget.entity.duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),

                            SizedBox(width: 0),

                            FutureBuilder<File?>(
                              future: widget.entity.file,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData || snapshot.data == null) {
                                  return const SizedBox(height: 14);
                                }

                                final file = snapshot.data!;

                                if (!file.existsSync()) {
                                  return const Text(
                                    'Unavailable',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 11,
                                    ),
                                  );
                                }

                                final bytes = file.lengthSync();

                                return Text(
                                  _formatSize(bytes),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 0),
                _dropDownButton()
              ],
            ),
          ],
        ),
      );






      Stack(
        children: <Widget>[
          const Center(
            child: Icon(Icons.audiotrack, size: 30),
          ),
          // 🔴 3-dot menu button (TOP RIGHT)
          _dropDownButton(),
          if (widget.entity.isFavorite)
            Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(4),
              // decoration: BoxDecoration(
              //   color: Colors.white,
              //   // shape: BoxShape.circle,
              // ),
              child: const Icon(
                Icons.favorite,
                color: Colors.redAccent,
                size: 16,
              ),
            ),
        ],
      );
    }
    return widget.isGrid?_buildGridItem(widget.entity):_buildListItem(widget.entity);
  }

  Widget _buildListItem(dynamic entity) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    print("entity is ========= ${entity.title}");
    return

      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7.5),
        child: Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          // height: 100,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 10,
              top: 10,
              bottom: 10,
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  // 🔑 important
                  child: AssetEntityImage(
                    entity,
                    thumbnailSize: const ThumbnailSize(160, 120),
                    // 2x for quality
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 20,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        entity.title ?? "",
                        maxLines: 1,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      SizedBox(height: 7),
                      AppText(
                        entity.relativePath ?? "",
                        maxLines: 1,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: colors.textFieldBorder,
                      ),
                      SizedBox(height: 7),
                      Row(
                        children: [
                          AppText(
                            _formatDuration(entity.duration),
                            maxLines: 2,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: colors.appBarTitleColor,
                          ),
                          SizedBox(width: 10),
                          FutureBuilder<File?>(
                            future: entity.file,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData ||
                                  snapshot.data == null) {
                                return const SizedBox(height: 14);
                              }

                              final file = snapshot.data!;

                              if (!file.existsSync()) {
                                return const Text(
                                  'Unavailable',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 11,
                                  ),
                                );
                              }

                              final bytes = file.lengthSync();

                              return AppText(
                                _formatSize(bytes),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: colors.appBarTitleColor,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 13),
_dropDownButton(),
                // PopupMenuButton<MediaMenuAction>(
                //   elevation: 10,
                //   color: Colors.white,
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   shadowColor: Colors.black.withOpacity(0.15),
                //   icon: AppImage(src: AppSvg.dropDownMenuDot),
                //   menuPadding: EdgeInsets.zero,
                //   // onSelected: (action) => onMenuSelected?.call(action),
                //   itemBuilder: (context) => [
                //     PopupMenuItem(
                //       value: MediaMenuAction.detail,
                //       child: Center(
                //         child: AppText(
                //           'Show detail page',
                //           fontSize: 12,
                //           fontWeight: FontWeight.w500,
                //           color: colors.appBarTitleColor,
                //         ),
                //       ),
                //     ),
                //
                //     const PopupMenuDivider(height: 0.5,),
                //     PopupMenuItem(
                //       value: MediaMenuAction.detail,
                //       child: Center(
                //         child: AppText(
                //           'Show detail page',
                //           fontSize: 12,
                //           fontWeight: FontWeight.w500,
                //           color: colors.appBarTitleColor,
                //         ),
                //       ),
                //     ),
                //
                //     const PopupMenuDivider(height: 0.5,),
                //     PopupMenuItem(
                //       value: MediaMenuAction.info,
                //       child:Center(
                //         child: AppText(
                //           'Show info dialog',
                //           fontSize: 12,
                //           fontWeight: FontWeight.w500,
                //           color: colors.appBarTitleColor,
                //         ),
                //       ),
                //     ),
                //
                //     if (entity.type == AssetType.video) ...[
                //       const PopupMenuDivider(height: 0.5,),
                //       PopupMenuItem(
                //         value: MediaMenuAction.thumb,
                //         child: Center(
                //           child: AppText(
                //             'Show 500 size thumb',
                //             fontSize: 12,
                //             fontWeight: FontWeight.w500,
                //             color: colors.appBarTitleColor,
                //           ),
                //         ),
                //       ),
                //     ],
                //
                //     // const PopupMenuDivider(height: 0.5,),
                //     //  PopupMenuItem(
                //     //   value: MediaMenuAction.share,
                //     //   child:Center(
                //     //     child: AppText(
                //     //       'Share',
                //     //       fontSize: 12,
                //     //       fontWeight: FontWeight.w500,
                //     //       color: colors.appBarTitleColor,
                //     //     ),
                //     //   ),
                //     // ),
                //
                //     const PopupMenuDivider(height: 0.5,),
                //
                //     PopupMenuItem(
                //       value: MediaMenuAction.addToFavourite,
                //       child:Center(
                //         child: AppText(
                //           entity.isFavorite
                //               ? 'Remove from Favourite'
                //               : 'Add to Favourite',
                //           fontSize: 12,
                //           fontWeight: FontWeight.w500,
                //           color: colors.appBarTitleColor,
                //         ),
                //       ),
                //     ),
                //
                //     const PopupMenuDivider(height: 0.5,),
                //
                //     PopupMenuItem(
                //       value: MediaMenuAction.delete,
                //       child: Center(
                //         child: AppText(
                //           'Delete',
                //           fontSize: 12,
                //           fontWeight: FontWeight.w500,
                //           color: colors.appBarTitleColor,
                //         ),
                //       ),
                //     ),
                //   ],
                // ),

                /*PopupMenuButton<MediaMenuAction>(
                          borderRadius: BorderRadius.circular(10),
                          color: colors.whiteColor,
                          shadowColor: colors.blackColor.withOpacity(0.20),
                          icon: AppImage(src: AppSvg.dropDownMenuDot),
                          // onSelected: (action) => onMenuSelected?.call(action),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: MediaMenuAction.detail,
                              child: Text('Show detail page'),
                            ),

                            const PopupMenuDivider(),

                            const PopupMenuItem(
                              value: MediaMenuAction.info,
                              child: Text('Show info dialog'),
                            ),

                            if (entity.type == AssetType.video) ...[
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: MediaMenuAction.thumb,
                                child: Text('Show 500 size thumb'),
                              ),
                            ],

                            const PopupMenuDivider(),

                            const PopupMenuItem(
                              value: MediaMenuAction.share,
                              child: Text('Share'),
                            ),

                            const PopupMenuDivider(),

                            PopupMenuItem(
                              value: MediaMenuAction.addToFavourite,
                              child: Text(
                                entity.isFavorite
                                    ? 'Remove from Favourite'
                                    : 'Add to Favourite',
                              ),
                            ),

                            const PopupMenuDivider(),

                            const PopupMenuItem(
                              value: MediaMenuAction.delete,
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),*/
              ],
            ),
          ),
        ),
      );
      // Card(
      //   child: ListTile(
      //     contentPadding: EdgeInsets.only(left: 15),
      //     leading: entity is AssetEntity
      //         ? SizedBox(
      //         width: 80,
      //         height: 80,
      //         child: AssetEntityImage(
      //           width: double.infinity,
      //           entity,
      //           isOriginal: false,
      //           thumbnailSize: option.size,
      //           thumbnailFormat: option.format,
      //           fit: BoxFit.cover,
      //           errorBuilder: (context, e, s) => Text(e.toString()),
      //         )
      //     )
      //         : const Icon(Icons.video_file),
      //     trailing: _dropDownButton(),
      //
      //     title: Text(
      //       entity is AssetEntity
      //           ? (entity.title ?? 'Video')
      //           : (entity as MediaItem).path.split('/').last,
      //       maxLines: 1,
      //     ),
      //
      //     subtitle: entity is AssetEntity
      //         ? Text(_formatDuration(entity.duration))
      //         : null,
      //
      //     // onTap: () async {
      //     //   if (entity is AssetEntity) {
      //     //     final file = await entity.file;
      //     //     if (file == null) return;
      //     //
      //     //     Navigator.push(
      //     //       context,
      //     //       MaterialPageRoute(
      //     //         builder: (_) => PlayerScreen(
      //     //           item: MediaItem(
      //     //             id: entity.id,
      //     //             path: file.path,
      //     //             isNetwork: false,
      //     //             type: 'video',
      //     //           ),
      //     //         ),
      //     //       ),
      //     //     );
      //     //   }
      //     // },
      //   ),
      // );
  }

  Widget _buildGridItem(dynamic entity) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colors.textFieldFill
      ),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: entity is AssetEntity
                  ? Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10,left: 10,right: 10,bottom: 5),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: colors.textFieldFill
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _assetAntityImage(entity)

                    ),
                  ),
                  if (entity.isFavorite)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle),
                          height: 20,
                          width: 20,

                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.all(0),
                          child: Center(
                            child: Icon(
                              Icons.favorite,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )


              // ImageItemWidget(
              //   isGrid: isGrid,
              //   onMenuSelected:onMenuSelected,
              //   onTap: onTap,
              //   entity: entity,
              //   option: const ThumbnailOption(
              //     size: ThumbnailSize.square(300),
              //   ),
              // )
                  : Container(color: Colors.black12),
            ),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: AppText(
                          widget.entity.title ?? "",
                          maxLines: 1,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Text(
                      //   entity.title??"",
                      //   maxLines: 2,
                      //   style: const TextStyle(color: Colors.white, fontSize: 12),
                      // ),
                      SizedBox(height: 4,),
                      if (entity is AssetEntity) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Row(
                            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                formatDuration(entity.duration),
                                fontSize: 10,fontWeight: FontWeight.w500,color: colors.textFieldBorder,
                              ),

                              SizedBox(width: 10),

                              FutureBuilder<File?>(
                                future: entity.file,
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.data == null) {
                                    return const SizedBox(height: 14);
                                  }

                                  final file = snapshot.data!;

                                  if (!file.existsSync()) {
                                    return const Text(
                                      'Unavailable',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 11,
                                      ),
                                    );
                                  }

                                  final bytes = file.lengthSync();

                                  return AppText(
                                    _formatSize(bytes),
                                    fontSize: 10,fontWeight: FontWeight.w500,color: colors.textFieldBorder,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 0),
                _dropDownButton()
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _videoPlaceholder() {
    return Container(
      color: Colors.black12,
      child: const Center(
        child: Icon(
          Icons.videocam,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  Widget _buildImageWidget(
      BuildContext context,
      AssetEntity entity,
      ThumbnailOption option,
      ) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: AssetEntityImage(
            // width: d
            entity,
            isOriginal: false,
            thumbnailSize: option.size,
            thumbnailFormat: option.format,
            fit: BoxFit.cover,
            errorBuilder: (context, e, s) => Text(e.toString()),
          ),
        ),
        // 🔴 3-dot menu button (TOP RIGHT)
        Positioned(
            top: 4,
            right: 4,
            child:
            _dropDownButton()),


        PositionedDirectional(
          bottom: 4,
          start: 0,
          end: 0,
          child: Row(
            children: [
              if (entity.isFavorite)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (entity.isLivePhoto)
                      Container(
                        margin: const EdgeInsetsDirectional.only(end: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                          color: Theme.of(context).cardColor,
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    Icon(
                          () {
                        switch (entity.type) {
                          case AssetType.other:
                            return Icons.abc;
                          case AssetType.image:
                            return Icons.image;
                          case AssetType.video:
                            return Icons.video_file;
                          case AssetType.audio:
                            return Icons.audiotrack;
                        }
                      }(),
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dropDownButton(){
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return



      PopupMenuButton<MediaMenuAction>(
          elevation: 15,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.black.withOpacity(0.60),
          offset: Offset(0, 0),
          // splashRadius: 15,
          icon: AppImage(src: AppSvg.dropDownMenuDot),
          menuPadding: EdgeInsets.symmetric(horizontal: 10),

      onSelected: (action) => widget.onMenuSelected?.call(action),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: MediaMenuAction.addToFavourite,
          child:Center(
            child: AppText(
              widget.entity.isFavorite
                  ? 'Remove from Favourite'
                  : 'Add to Favourite',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.appBarTitleColor,
            ),
          ),
        ),

        const PopupMenuDivider(height: 0.5,),
        PopupMenuItem(
          value: MediaMenuAction.delete,
          child: Center(
            child: AppText(
              'Delete',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.appBarTitleColor,
            ),
          ),
        ),
        const PopupMenuDivider(height: 0.5,),
        PopupMenuItem(
          value: MediaMenuAction.share,
          child:Center(
            child: AppText(
              'Share',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.appBarTitleColor,
            ),
          ),
        ),
        const PopupMenuDivider(height: 0.5,),
        PopupMenuItem(
          value: MediaMenuAction.detail,
          child: Center(
            child: AppText(
              'Show detail page',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.appBarTitleColor,
            ),
          ),
        ),

        // const PopupMenuDivider(height: 0.5,),
        // PopupMenuItem(
        //   value: MediaMenuAction.detail,
        //   child: Center(
        //     child: AppText(
        //       'Show detail page',
        //       fontSize: 12,
        //       fontWeight: FontWeight.w500,
        //       color: colors.appBarTitleColor,
        //     ),
        //   ),
        // ),
        //
        // const PopupMenuDivider(height: 0.5,),
        // PopupMenuItem(
        //   value: MediaMenuAction.info,
        //   child:Center(
        //     child: AppText(
        //       'Show info dialog',
        //       fontSize: 12,
        //       fontWeight: FontWeight.w500,
        //       color: colors.appBarTitleColor,
        //     ),
        //   ),
        // ),
        //
        // // if (widget.entity.type == AssetType.video) ...[
        //   const PopupMenuDivider(height: 0.5,),
        //   PopupMenuItem(
        //     value: MediaMenuAction.thumb,
        //     child: Center(
        //       child: AppText(
        //         'Show 500 size thumb',
        //         fontSize: 12,
        //         fontWeight: FontWeight.w500,
        //         color: colors.appBarTitleColor,
        //       ),
        //     ),
        //   ),
        // ],

        // const PopupMenuDivider(height: 0.5,),




      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: buildContent(context),
    );
  }

  Widget? _assetAntityImage(AssetEntity entity) {
    return FutureBuilder<File?>(
      future: entity.file,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return _videoPlaceholder();
        }

        final file = snapshot.data!;

        if (!file.existsSync() || file.lengthSync() == 0) {
          return _videoPlaceholder();
        }

        return AssetEntityImage(
          entity,
          width: double.infinity,
          isOriginal: false,
          thumbnailSize: const ThumbnailSize.square(300),
          thumbnailFormat: ThumbnailFormat.jpeg,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _videoPlaceholder();
          },
        );
      },
    );
  }
}







// import 'package:flutter/material.dart';
// import 'package:photo_manager/photo_manager.dart';
// import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
//
// enum MediaMenuAction { detail, info, thumb, delete, share, addToFavourite }
//
// class ImageItemWidget extends StatelessWidget {
//   const ImageItemWidget({
//     super.key,
//     required this.entity,
//     required this.option,
//     this.onTap,
//     this.onMenuSelected,
//   });
//
//   final AssetEntity entity;
//   final ThumbnailOption option;
//   final GestureTapCallback? onTap;
//   final void Function(MediaMenuAction action)? onMenuSelected;
//
//   @override
//   Widget build(BuildContext context) {
//     if (entity.type == AssetType.audio) {
//        Center(child: Icon(Icons.audiotrack, size: 30));
//     }
//
//     return GestureDetector(
//       behavior: HitTestBehavior.opaque,
//       onTap: onTap,
//       child: buildContent(context),
//     );
//   }
//
//   Widget buildContent(BuildContext context) {
//     if (entity.type == AssetType.audio) {
//       return Stack(
//         children: <Widget>[
//           const Center(child: Icon(Icons.audiotrack, size: 30)),
//           _dropDownButton(),
//           if (entity.isFavorite)
//             Align(
//               alignment: Alignment.bottomLeft,
//               child: Container(
//                 padding: const EdgeInsets.all(4),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.favorite,
//                   color: Colors.redAccent,
//                   size: 18,
//                 ),
//               ),
//             ),
//
//
//         ],
//       );
//     }
//     return _buildImageWidget(context, entity, option);
//   }
//
//   Widget _buildImageWidget(
//     BuildContext context,
//     AssetEntity entity,
//     ThumbnailOption option,
//   ) {
//     return Stack(
//       children: [
//         Positioned.fill(
//           child: AssetEntityImage(
//             entity,
//             isOriginal: false,
//             thumbnailSize: option.size,
//             thumbnailFormat: option.format,
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) =>
//                 Center(child: Text(error.toString())),
//           ),
//         ),
//         _dropDownButton(),
//         PositionedDirectional(
//           bottom: 4,
//           start: 4,
//           end: 0,
//           child: Row(
//             children: [
//               if (entity.isFavorite)
//                 Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).cardColor,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.favorite,
//                     color: Colors.redAccent,
//                     size: 18,
//                   ),
//                 ),
//               Expanded(
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     if (entity.isLivePhoto)
//                       Container(
//                         margin: const EdgeInsetsDirectional.only(end: 4),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 4,
//                           vertical: 2,
//                         ),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(4),
//                           color: Theme.of(context).cardColor,
//                         ),
//                         child: const Text(
//                           'LIVE',
//                           style: TextStyle(
//                             color: Colors.black,
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold,
//                             height: 1,
//                           ),
//                         ),
//                       ),
//                     Icon(
//                       _getIconByType(entity.type),
//                       color: Colors.white,
//                       size: 16,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   IconData _getIconByType(AssetType type) {
//     switch (type) {
//       case AssetType.image:
//         return Icons.image;
//       case AssetType.video:
//         return Icons.videocam;
//       case AssetType.audio:
//         return Icons.audiotrack;
//       case AssetType.other:
//       default:
//         return Icons.error;
//     }
//   }
//
//   Widget _dropDownButton() {
//     return Positioned(
//       top: 4,
//       right: 4,
//       child: PopupMenuButton<MediaMenuAction>(
//         icon: Container(
//           padding: const EdgeInsets.all(6),
//           decoration: BoxDecoration(
//             color: Colors.black.withOpacity(0.5),
//             shape: BoxShape.circle,
//           ),
//           child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
//         ),
//         onSelected: (action) => onMenuSelected?.call(action),
//         itemBuilder: (context) => [
//           const PopupMenuItem(
//             value: MediaMenuAction.detail,
//             child: Text('Show detail page'),
//           ),
//           const PopupMenuItem(
//             value: MediaMenuAction.info,
//             child: Text('Show info dialog'),
//           ),
//           if (entity.type == AssetType.video)
//             const PopupMenuItem(
//               value: MediaMenuAction.thumb,
//               child: Text('Show 500 size thumb'),
//             ),
//           const PopupMenuItem(
//             value: MediaMenuAction.share,
//             child: Text('Share'),
//           ),
//            PopupMenuItem(
//             value: MediaMenuAction.addToFavourite,
//             child: Text(entity.isFavorite?"Remove to Favourite":'Add to Favourite'),
//           ),
//           const PopupMenuItem(
//             value: MediaMenuAction.delete,
//             child: Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }
// }
