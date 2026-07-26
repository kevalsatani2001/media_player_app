/////////common methods


import 'dart:math' as Math;
import 'dart:ui' as ui;
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_player/utils/app_string.dart';
import 'package:media_player/widgets/app_button.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:share_plus/share_plus.dart';
import '../blocs/video/video_bloc.dart';
import '../blocs/video/video_event.dart';
import '../screens/detail_screen.dart';
import '../utils/app_colors.dart';
import '../widgets/app_toast.dart';
import 'custom_loader.dart';


import 'package:flutter/services.dart';

Future<bool?> deleteCurrentItem(BuildContext context, AssetEntity entity) async {
  final colors = Theme.of(context).extension<AppThemeColors>()!;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final bool? confirm = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      contentPadding: const EdgeInsets.fromLTRB(33, 40, 33, 20),
      backgroundColor: colors.dropdownBg,
      title: AppText(
        'deleteThisFile',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: colors.appBarTitleColor,
        align: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            'areYouSureWantDeleteThisFile',
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: colors.dialogueSubTitle,
            align: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  title: "yes",
                  textColor: colors.dialogueSubTitle,
                  backgroundColor: colors.whiteColor,
                  onTap: () => Navigator.pop(context, true),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AppButton(
                  title: "no",
                  textColor: Colors.white,
                  backgroundColor: colors.primary,
                  onTap: () => Navigator.pop(context, false),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  if (confirm != true) return false;

  // 3. Native File Delete
  final List<String> result = await PhotoManager.editor.deleteWithIds([entity.id]);

  if (result.isNotEmpty) {
    context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
    AppToast.show(context, context.tr("fileDeletedSuccessfully"), type: ToastType.error);
    return true; // àª¸àª«àª³àª¤àª¾àªªà«‚àª°à«àªµàª• àª¡àª¿àª²à«€àªŸ àª¥àª¯à«àª‚
  } else {
    AppToast.show(context, context.tr("failedToDeleteFile"), type: ToastType.error);
    return false;
  }
}
String formatDuration(int secondsInput) {
  if (secondsInput <= 0) return "00:00:00";

  final int hours = secondsInput ~/ 3600;
  final int minutes = (secondsInput % 3600) ~/ 60;
  final int seconds = secondsInput % 60;

  if (hours > 0) {
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  } else {
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}
Future<void> shareItem(BuildContext context, AssetEntity entity) async {
  try {
    // Ã Â«Â§. Ã ÂªÂÃ ÂªÂ¸Ã Â«â€¡Ã ÂªÅ¸Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€šÃ ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ«Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ² Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ³Ã ÂªÂµÃ Â«â€¹
    final File? file = await entity.file;

    if (file != null && await file.exists()) {
      // Ã Â«Â¨. Ã ÂªÂ«Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ²Ã ÂªÂ¨Ã Â«â€¹ Ã ÂªÂªÃ ÂªÂ¾Ã ÂªÂ¥ Ã ÂªÅ¡Ã Â«â€¡Ã Âªâ€¢ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
      debugPrint("Sharing file path: ${file.path}");

      // Ã Â«Â©. ShareXFiles Ã ÂªÂ¨Ã Â«â€¹ Ã Âªâ€°Ã ÂªÂªÃ ÂªÂ¯Ã Â«â€¹Ã Âªâ€” Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${context.tr("sharing")} ${entity.title ?? "${context.tr("mediaFile")}"}', // Ã Âªâ€  Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÅ“ Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªÂ¥Ã Â«â€¡ Ã ÂªÅ“Ã ÂªÂ¶Ã Â«â€¡
      );
    } else {
      debugPrint("File not found or entity.file returned null");
      // Ã ÂªÅ“Ã Â«â€¹ Ã ÂªÂ«Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ² Ã ÂªÂ¨Ã ÂªÂ¾ Ã ÂªÂ®Ã ÂªÂ³Ã Â«â€¡ Ã ÂªÂ¤Ã Â«â€¹ Ã ÂªÂ¯Ã Â«ÂÃ ÂªÂÃ ÂªÂ°Ã ÂªÂ¨Ã Â«â€¡ Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÅ“ Ã ÂªÂ¬Ã ÂªÂ¤Ã ÂªÂ¾Ã ÂªÂµÃ Â«â€¹
      AppToast.show(context, context.tr("fileCanNotBeLoaded"), type: ToastType.error);
    }
  } catch (e) {
    AppToast.show(context, context.tr("errorSharingFile"), type: ToastType.error);
  }
}
Future<void> routeToDetailPage(BuildContext context, AssetEntity entity) async {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => DetailPage(entity: entity)),
  );
}

Future<void> showThumb(
    BuildContext context,
    AssetEntity entity,
    int size,
    ) async {
  final String title;
  if (entity.title?.isEmpty != false) {
    title = await entity.titleAsync;
  } else {
    title = entity.title!;
  }
  print('entity.title = $title');
  return showDialog(
    context: context,
    builder: (_) {
      return FutureBuilder<Uint8List?>(
        future: entity.thumbnailDataWithOption(
          ThumbnailOption.ios(
            size: const ThumbnailSize.square(500),
            // resizeContentMode: ResizeContentMode.fill,
          ),
        ),
        builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
          Widget w;
          if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
          } else if (snapshot.hasData) {
            final Uint8List data = snapshot.data!;
            ui.decodeImageFromList(data, (ui.Image result) {
              print('result size: ${result.width}x${result.height}');
              // for 4288x2848
            });
            w = Image.memory(data);
          } else {
            w = Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: const CustomLoader(),
              ),
            );
          }
          return GestureDetector(
            child: w,
            onTap: () => Navigator.pop(context),
          );
        },
      );
    },
  );
}

String formatSize(int bytes,BuildContext context) {
  if (bytes <= 0) return "0 B";

  // const suffixes = ["B", "KB", "MB", "GB", "TB"];
  final suffixes = [
    context.tr("b"),
    context.tr("kb"),
    context.tr("mb"),
    context.tr("gb"),
    context.tr("tb")
  ];

  var i = (Math.log(bytes) / Math.log(1024)).floor();

  if (i >= suffixes.length) i = suffixes.length - 1;

  final double size = bytes / Math.pow(1024, i);

  return '${size.toStringAsFixed(size < 10 && i > 0 ? 1 : 0)} ${suffixes[i]}';
}

/*
/////////common methods


import 'dart:math' as Math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_player/screens/setting_screen.dart';
import 'package:media_player/widgets/app_button.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../blocs/video/video_bloc.dart';
import '../blocs/video/video_event.dart';
import '../screens/detail_screen.dart';
import '../services/global_player.dart';
import '../utils/app_colors.dart';
import '../widgets/app_toast.dart';
import 'custom_loader.dart';



Future<void> deleteCurrentItem(BuildContext context, AssetEntity entity) async {
  final colors = Theme.of(context).extension<AppThemeColors>()!;
  if (!Platform.isAndroid && !Platform.isIOS) return;

  final bool? confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      actionsPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: 36),
      contentPadding: EdgeInsets.only(left: 33,right: 33,bottom: 20,top: 40),
      backgroundColor: colors.cardBackground,
      title: AppText(
        'deleteThisFile',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: colors.appBarTitleColor,
        align: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            'areYouSureWantDeleteThisFile',
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: colors.dialogueSubTitle,
            align: TextAlign.center,
          ),
          SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  title: "yes",
                  textColor: colors.dialogueSubTitle,
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  backgroundColor: colors.whiteColor,
                  onTap: () => Navigator.pop(context, true),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: AppButton(
                  title: "no",
                  textColor: colors.whiteColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  backgroundColor: colors.primary,
                  onTap: () => Navigator.pop(context, false),
                ),
              ),
            ],
          ),
        ],
      ),

      // content: const Text('Are you sure you want to delete this file?'),
    ),
  );

  if (confirm != true) return;

  // Ã¢Å“â€¦ Correct delete API
  final result = await PhotoManager.editor.deleteWithIds([entity.id]);

  if (result.isNotEmpty) {
    context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
    AppToast.show(context, context.tr("fileDeletedSuccessfully"), type: ToastType.error);
  }else{
    AppToast.show(context, context.tr("failedToDeleteFile"), type: ToastType.error);
  }
}

String formatDuration(int secondsInput) {
  if (secondsInput <= 0) return "00:00:00";

  // AssetEntity.duration Ã ÂªÂ¸Ã Â«â‚¬Ã ÂªÂ§Ã Â«ÂÃ Âªâ€š Ã ÂªÂ¸Ã Â«â€¡Ã Âªâ€¢Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¡Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã ÂªÅ“ Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ¯ Ã Âªâ€ºÃ Â«â€¡,
  // Ã ÂªÂÃ ÂªÅ¸Ã ÂªÂ²Ã Â«â€¡ ~/ 1000 Ã Âªâ€¢Ã ÂªÂ°Ã ÂªÂµÃ ÂªÂ¾Ã ÂªÂ¨Ã Â«â‚¬ Ã ÂªÅ“Ã ÂªÂ°Ã Â«â€šÃ ÂªÂ° Ã ÂªÂ¨Ã ÂªÂ¥Ã Â«â‚¬.

  final int hours = secondsInput ~/ 3600;
  final int minutes = (secondsInput % 3600) ~/ 60;
  final int seconds = secondsInput % 60;

  if (hours > 0) {
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  } else {
    // Ã ÂªÅ“Ã Â«â€¹ Ã Âªâ€¢Ã ÂªÂ²Ã ÂªÂ¾Ã Âªâ€¢ Ã ÂªÂ¨Ã ÂªÂ¾ Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ¯ Ã ÂªÂ¤Ã Â«â€¹ Ã ÂªÂ«Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¤ MM:SS Ã ÂªÂ¬Ã ÂªÂ¤Ã ÂªÂ¾Ã ÂªÂµÃ ÂªÂµÃ Â«ÂÃ Âªâ€š Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ¯ Ã ÂªÂ¤Ã Â«â€¹:
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}
Future<void> shareItem(BuildContext context, AssetEntity entity) async {
  try {
    // Ã Â«Â§. Ã ÂªÂÃ ÂªÂ¸Ã Â«â€¡Ã ÂªÅ¸Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€šÃ ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ«Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ² Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ³Ã ÂªÂµÃ Â«â€¹
    final File? file = await entity.file;

    if (file != null && await file.exists()) {
      // Ã Â«Â¨. Ã ÂªÂ«Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ²Ã ÂªÂ¨Ã Â«â€¹ Ã ÂªÂªÃ ÂªÂ¾Ã ÂªÂ¥ Ã ÂªÅ¡Ã Â«â€¡Ã Âªâ€¢ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
      debugPrint("Sharing file path: ${file.path}");

      // Ã Â«Â©. ShareXFiles Ã ÂªÂ¨Ã Â«â€¹ Ã Âªâ€°Ã ÂªÂªÃ ÂªÂ¯Ã Â«â€¹Ã Âªâ€” Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${context.tr("sharing")} ${entity.title ?? "${context.tr("mediaFile")}"}', // Ã Âªâ€  Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÅ“ Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªÂ¥Ã Â«â€¡ Ã ÂªÅ“Ã ÂªÂ¶Ã Â«â€¡
      );
    } else {
      debugPrint("File not found or entity.file returned null");
      // Ã ÂªÅ“Ã Â«â€¹ Ã ÂªÂ«Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ² Ã ÂªÂ¨Ã ÂªÂ¾ Ã ÂªÂ®Ã ÂªÂ³Ã Â«â€¡ Ã ÂªÂ¤Ã Â«â€¹ Ã ÂªÂ¯Ã Â«ÂÃ ÂªÂÃ ÂªÂ°Ã ÂªÂ¨Ã Â«â€¡ Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÅ“ Ã ÂªÂ¬Ã ÂªÂ¤Ã ÂªÂ¾Ã ÂªÂµÃ Â«â€¹
      AppToast.show(context, context.tr("fileCanNotBeLoaded"), type: ToastType.error);
    }
  } catch (e) {
    AppToast.show(context, context.tr("errorSharingFile"), type: ToastType.error);
  }
}
Future<void> routeToDetailPage(BuildContext context, AssetEntity entity) async {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => DetailPage(entity: entity)),
  );
}

Future<void> showThumb(
    BuildContext context,
    AssetEntity entity,
    int size,
    ) async {
  final String title;
  if (entity.title?.isEmpty != false) {
    title = await entity.titleAsync;
  } else {
    title = entity.title!;
  }
  print('entity.title = $title');
  return showDialog(
    context: context,
    builder: (_) {
      return FutureBuilder<Uint8List?>(
        future: entity.thumbnailDataWithOption(
          ThumbnailOption.ios(
            size: const ThumbnailSize.square(500),
            // resizeContentMode: ResizeContentMode.fill,
          ),
        ),
        builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
          Widget w;
          if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
          } else if (snapshot.hasData) {
            final Uint8List data = snapshot.data!;
            ui.decodeImageFromList(data, (ui.Image result) {
              print('result size: ${result.width}x${result.height}');
              // for 4288x2848
            });
            w = Image.memory(data);
          } else {
            w = Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: const CustomLoader(),
              ),
            );
          }
          return GestureDetector(
            child: w,
            onTap: () => Navigator.pop(context),
          );
        },
      );
    },
  );
}

String formatSize(int bytes,BuildContext context) {
  if (bytes <= 0) return "0 B";

  // const suffixes = ["B", "KB", "MB", "GB", "TB"];
  final suffixes = [
  context.tr("b"),
    context.tr("kb"),
    context.tr("mb"),
    context.tr("gb"),
    context.tr("tb")
  ];

  // Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ Ã ÂªÂ®Ã Â«ÂÃ ÂªÅ“Ã ÂªÂ¬ Ã Âªâ€¡Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¡Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¸ Ã ÂªÂ¨Ã Âªâ€¢Ã Â«ÂÃ Âªâ€¢Ã Â«â‚¬ Ã Âªâ€¢Ã ÂªÂ°Ã ÂªÂµÃ ÂªÂ¾ Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡ log Ã ÂªÂµÃ ÂªÂ¾Ã ÂªÂªÃ ÂªÂ°Ã Â«â‚¬ Ã ÂªÂ¶Ã Âªâ€¢Ã ÂªÂ¾Ã ÂªÂ¯
  // Ã Âªâ€¦Ã ÂªÂ¥Ã ÂªÂµÃ ÂªÂ¾ Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªÂ¦Ã Â«â€¹ logic:
  var i = (Math.log(bytes) / Math.log(1024)).floor();

  // Ã ÂªÅ“Ã Â«â€¹ Ã Âªâ€¡Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¡Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¸ Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ¨Ã Â«â‚¬ Ã ÂªÂ¬Ã ÂªÂ¹Ã ÂªÂ¾Ã ÂªÂ° Ã ÂªÅ“Ã ÂªÂ¤Ã Â«â€¹ Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ¯ Ã ÂªÂ¤Ã Â«â€¹ Ã Âªâ€ºÃ Â«â€¡Ã ÂªÂ²Ã Â«ÂÃ ÂªÂ²Ã Â«â€¹ Ã ÂªÂ¯Ã Â«ÂÃ ÂªÂ¨Ã ÂªÂ¿Ã ÂªÅ¸ Ã ÂªÂ²Ã Â«â€¹
  if (i >= suffixes.length) i = suffixes.length - 1;

  final double size = bytes / Math.pow(1024, i);

  // Ã ÂªÅ“Ã Â«â€¹ Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ Ã ÂªÂªÃ Â«â€šÃ ÂªÂ°Ã Â«ÂÃ ÂªÂ£Ã ÂªÂ¾Ã Âªâ€šÃ Âªâ€¢ Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ¯ Ã ÂªÂ¤Ã Â«â€¹ Ã ÂªÂ¡Ã Â«â€¡Ã ÂªÂ¸Ã ÂªÂ¿Ã ÂªÂ®Ã ÂªÂ² Ã ÂªÂµÃ Âªâ€”Ã ÂªÂ° Ã ÂªÂ¬Ã ÂªÂ¤Ã ÂªÂ¾Ã ÂªÂµÃ Â«â€¹, Ã ÂªÂ¨Ã ÂªÂ¹Ã Â«â‚¬Ã Âªâ€šÃ ÂªÂ¤Ã ÂªÂ° 1 Ã ÂªÂªÃ Â«â€¹Ã ÂªË†Ã ÂªÂ¨Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªÂ¥Ã Â«â€¡
  return '${size.toStringAsFixed(size < 10 && i > 0 ? 1 : 0)} ${suffixes[i]}';
}
 */