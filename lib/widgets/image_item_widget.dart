import 'dart:io';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import '../core/constants.dart';
import '../screens/home_screen.dart';
import '../utils/app_colors.dart';
import 'common_methods.dart';
import 'image_widget.dart';
import 'safe_asset_thumbnail.dart';

enum MediaMenuAction {
  detail,
  info,
  thumb,
  delete,
  share,
  addToFavourite,
  addToPlaylist,
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
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    if (widget.entity.type == AssetType.audio) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: colors.videoGridBgColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: widget.entity is AssetEntity
                    ? Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                        left: 10,
                        right: 10,
                        bottom: 5,
                      ),
                      child: Container(
                          height: double.infinity,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: colors.audioGridBgColor,
                          ),
                          child: Center(child: Icon(Icons.audiotrack, size: 30))),
                    ),
                    if (widget.entity.isFavorite)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.blackColor,
                              shape: BoxShape.circle,
                            ),
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
                    : Container(color: Colors.black12),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AppText(
                            widget.entity.title ?? "",
                            maxLines: 1,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          SizedBox(height: 8),
                          // if (widget.entity is AssetEntity) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                formatDuration(widget.entity.duration),
                                maxLines: 2,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: colors.textFieldBorder,
                              ),

                              SizedBox(width: 0),

                              FutureBuilder<File?>(
                                future: widget.entity.file,
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData ||
                                      snapshot.data == null) {
                                    return const SizedBox(height: 14);
                                  }

                                  final file = snapshot.data!;

                                  if (!file.existsSync()) {
                                    return AppText(
                                      'unavailable',
                                      fontSize: 11,
                                      color:Colors.redAccent,
                                    );
                                  }

                                  final bytes = file.lengthSync();

                                  return AppText(
                                    formatSize(bytes,context),
                                    maxLines: 2,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textFieldBorder,
                                  );
                                },
                              ),
                            ],
                          ),
                          // ],
                        ],
                      ),
                    ),
                    SizedBox(width: 0),
                    _dropDownButton(widget.entity),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widget.isGrid
        ? _buildGridItem(widget.entity)
        : _buildListItem(widget.entity);
  }

  Widget _buildListItem(dynamic entity) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    print("entity is ========= ${entity.title}");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.5),
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        // height: 100,
        child: Padding(
          padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                // Ã°Å¸â€â€˜ important
                child: SafeAssetThumbnail(
                  entity: entity,
                  thumbnailSize: const ThumbnailSize(160, 120),
                  fit: BoxFit.cover,
                  placeholder: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
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
                          formatDuration(entity.duration),
                          maxLines: 2,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colors.appBarTitleColor,
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
                              return  AppText(
                                'unavailable',
                                fontSize: 11,
                                color:Colors.redAccent,
                              );
                            }

                            final bytes = file.lengthSync();

                            return AppText(
                              formatSize(bytes,context),
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
              _dropDownButton(widget.entity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(dynamic entity) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colors.videoGridBgColor,
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
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 10,
                      right: 10,
                      bottom: 5,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: colors.textFieldFill,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: assetAntityImage(entity),
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
                            shape: BoxShape.circle,
                          ),
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
                      SizedBox(height: 4),
                      if (entity is AssetEntity) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Row(
                            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                formatDuration(entity.duration),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: colors.textFieldBorder,
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
                                    return  AppText(
                                      'unavailable',
                                      fontSize: 11,
                                      color:Colors.redAccent,
                                    );
                                  }

                                  final bytes = file.lengthSync();

                                  return AppText(
                                    formatSize(bytes,context),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textFieldBorder,
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
                _dropDownButton(widget.entity),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // String _formatDuration(int seconds) {
  //   final m = seconds ~/ 60;
  //   final s = seconds % 60;
  //   return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  // }

  Widget _dropDownButton(AssetEntity entity) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return PopupMenuButton<MediaMenuAction>(
      elevation: 15,
      color: colors.dropdownBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.black.withOpacity(0.60),
      offset: Offset(0, 0),
      // splashRadius: 15,
      icon: AppImage(src: AppSvg.dropDownMenuDot,color: colors.blackColor,),
      menuPadding: EdgeInsets.symmetric(horizontal: 10),

      onSelected: (action) => widget.onMenuSelected?.call(action),
      itemBuilder: (context) => [
        _buildItem(
          MediaMenuAction.addToFavourite,
          widget.entity.isFavorite ? 'removeToFavourite' : 'addToFavourite',
        ),
        const PopupMenuDivider(height: 0.5),
        _buildItem(MediaMenuAction.delete, 'delete'),
        const PopupMenuDivider(height: 0.5),
        _buildItem(MediaMenuAction.share, 'share'),
        const PopupMenuDivider(height: 0.5),
        if (entity.type == AssetType.video) ...[
          const PopupMenuDivider(height: 0.5),
          PopupMenuItem(
            value: MediaMenuAction.thumb,
            child: Center(
              child: AppText(
                'showThumb500',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.appBarTitleColor,
              ),
            ),
          ),
        ],
        const PopupMenuDivider(height: 0.5),
        _buildItem(MediaMenuAction.detail, 'showDetail'),
        const PopupMenuDivider(height: 0.5),
        _buildItem(MediaMenuAction.addToPlaylist, 'addToPlaylist'),
      ],
    );
  }

  _buildItem(MediaMenuAction action, String title) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return PopupMenuItem(
      value: action,
      child: Center(
        child: AppText(
          title,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.appBarTitleColor,
        ),
      ),
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
}

Widget videoPlaceholder({bool? isAudio = false}) {
  return Container(
    color: Colors.black12,
    child: Center(
      child: Icon(
        isAudio! ? Icons.audio_file : Icons.videocam,
        size: 40,
        color: Colors.grey,
      ),
    ),
  );
}

Widget? assetAntityImage(AssetEntity entity) {
  if (entity.typeInt == 3 || entity.type == AssetType.audio) {
    return videoPlaceholder(isAudio: true);
  }

  return SafeAssetThumbnail(
    entity: entity,
    thumbnailSize: const ThumbnailSize.square(150),
    format: ThumbnailFormat.jpeg,
    width: double.infinity,
    fit: BoxFit.cover,
    placeholder: videoPlaceholder(isAudio: false),
  );
}