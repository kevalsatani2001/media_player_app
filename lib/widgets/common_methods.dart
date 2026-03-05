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
import 'package:share_plus/share_plus.dart';
import '../blocs/video/video_bloc.dart';
import '../blocs/video/video_event.dart';
import '../screens/detail_screen.dart';
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
                  textColor: Colors.white,
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

  // âœ… Correct delete API
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

  // AssetEntity.duration àª¸à«€àª§à«àª‚ àª¸à«‡àª•àª¨à«àª¡àª®àª¾àª‚ àªœ àª¹à«‹àª¯ àª›à«‡,
  // àªàªŸàª²à«‡ ~/ 1000 àª•àª°àªµàª¾àª¨à«€ àªœàª°à«‚àª° àª¨àª¥à«€.

  final int hours = secondsInput ~/ 3600;
  final int minutes = (secondsInput % 3600) ~/ 60;
  final int seconds = secondsInput % 60;

  if (hours > 0) {
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  } else {
    // àªœà«‹ àª•àª²àª¾àª• àª¨àª¾ àª¹à«‹àª¯ àª¤à«‹ àª«àª•à«àª¤ MM:SS àª¬àª¤àª¾àªµàªµà«àª‚ àª¹à«‹àª¯ àª¤à«‹:
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}
Future<void> shareItem(BuildContext context, AssetEntity entity) async {
  try {
    // à«§. àªàª¸à«‡àªŸàª®àª¾àª‚àª¥à«€ àª«àª¾àªˆàª² àª®à«‡àª³àªµà«‹
    final File? file = await entity.file;

    if (file != null && await file.exists()) {
      // à«¨. àª«àª¾àªˆàª²àª¨à«‹ àªªàª¾àª¥ àªšà«‡àª• àª•àª°à«‹
      debugPrint("Sharing file path: ${file.path}");

      // à«©. ShareXFiles àª¨à«‹ àª‰àªªàª¯à«‹àª— àª•àª°à«‹
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${context.tr("sharing")} ${entity.title ?? "${context.tr("mediaFile")}"}', // àª† àª®à«‡àª¸à«‡àªœ àª¸àª¾àª¥à«‡ àªœàª¶à«‡
      );
    } else {
      debugPrint("File not found or entity.file returned null");
      // àªœà«‹ àª«àª¾àªˆàª² àª¨àª¾ àª®àª³à«‡ àª¤à«‹ àª¯à«àªàª°àª¨à«‡ àª®à«‡àª¸à«‡àªœ àª¬àª¤àª¾àªµà«‹
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

  // àª¸àª¾àªˆàª àª®à«àªœàª¬ àª‡àª¨à«àª¡à«‡àª•à«àª¸ àª¨àª•à«àª•à«€ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡ log àªµàª¾àªªàª°à«€ àª¶àª•àª¾àª¯
  // àª…àª¥àªµàª¾ àª¸àª¾àª¦à«‹ logic:
  var i = (Math.log(bytes) / Math.log(1024)).floor();

  // àªœà«‹ àª‡àª¨à«àª¡à«‡àª•à«àª¸ àª²àª¿àª¸à«àªŸàª¨à«€ àª¬àª¹àª¾àª° àªœàª¤à«‹ àª¹à«‹àª¯ àª¤à«‹ àª›à«‡àª²à«àª²à«‹ àª¯à«àª¨àª¿àªŸ àª²à«‹
  if (i >= suffixes.length) i = suffixes.length - 1;

  final double size = bytes / Math.pow(1024, i);

  // àªœà«‹ àª¸àª¾àªˆàª àªªà«‚àª°à«àª£àª¾àª‚àª• àª¹à«‹àª¯ àª¤à«‹ àª¡à«‡àª¸àª¿àª®àª² àªµàª—àª° àª¬àª¤àª¾àªµà«‹, àª¨àª¹à«€àª‚àª¤àª° 1 àªªà«‹àªˆàª¨à«àªŸ àª¸àª¾àª¥à«‡
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

  // âœ… Correct delete API
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

  // AssetEntity.duration àª¸à«€àª§à«àª‚ àª¸à«‡àª•àª¨à«àª¡àª®àª¾àª‚ àªœ àª¹à«‹àª¯ àª›à«‡,
  // àªàªŸàª²à«‡ ~/ 1000 àª•àª°àªµàª¾àª¨à«€ àªœàª°à«‚àª° àª¨àª¥à«€.

  final int hours = secondsInput ~/ 3600;
  final int minutes = (secondsInput % 3600) ~/ 60;
  final int seconds = secondsInput % 60;

  if (hours > 0) {
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  } else {
    // àªœà«‹ àª•àª²àª¾àª• àª¨àª¾ àª¹à«‹àª¯ àª¤à«‹ àª«àª•à«àª¤ MM:SS àª¬àª¤àª¾àªµàªµà«àª‚ àª¹à«‹àª¯ àª¤à«‹:
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}
Future<void> shareItem(BuildContext context, AssetEntity entity) async {
  try {
    // à«§. àªàª¸à«‡àªŸàª®àª¾àª‚àª¥à«€ àª«àª¾àªˆàª² àª®à«‡àª³àªµà«‹
    final File? file = await entity.file;

    if (file != null && await file.exists()) {
      // à«¨. àª«àª¾àªˆàª²àª¨à«‹ àªªàª¾àª¥ àªšà«‡àª• àª•àª°à«‹
      debugPrint("Sharing file path: ${file.path}");

      // à«©. ShareXFiles àª¨à«‹ àª‰àªªàª¯à«‹àª— àª•àª°à«‹
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${context.tr("sharing")} ${entity.title ?? "${context.tr("mediaFile")}"}', // àª† àª®à«‡àª¸à«‡àªœ àª¸àª¾àª¥à«‡ àªœàª¶à«‡
      );
    } else {
      debugPrint("File not found or entity.file returned null");
      // àªœà«‹ àª«àª¾àªˆàª² àª¨àª¾ àª®àª³à«‡ àª¤à«‹ àª¯à«àªàª°àª¨à«‡ àª®à«‡àª¸à«‡àªœ àª¬àª¤àª¾àªµà«‹
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

  // àª¸àª¾àªˆàª àª®à«àªœàª¬ àª‡àª¨à«àª¡à«‡àª•à«àª¸ àª¨àª•à«àª•à«€ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡ log àªµàª¾àªªàª°à«€ àª¶àª•àª¾àª¯
  // àª…àª¥àªµàª¾ àª¸àª¾àª¦à«‹ logic:
  var i = (Math.log(bytes) / Math.log(1024)).floor();

  // àªœà«‹ àª‡àª¨à«àª¡à«‡àª•à«àª¸ àª²àª¿àª¸à«àªŸàª¨à«€ àª¬àª¹àª¾àª° àªœàª¤à«‹ àª¹à«‹àª¯ àª¤à«‹ àª›à«‡àª²à«àª²à«‹ àª¯à«àª¨àª¿àªŸ àª²à«‹
  if (i >= suffixes.length) i = suffixes.length - 1;

  final double size = bytes / Math.pow(1024, i);

  // àªœà«‹ àª¸àª¾àªˆàª àªªà«‚àª°à«àª£àª¾àª‚àª• àª¹à«‹àª¯ àª¤à«‹ àª¡à«‡àª¸àª¿àª®àª² àªµàª—àª° àª¬àª¤àª¾àªµà«‹, àª¨àª¹à«€àª‚àª¤àª° 1 àªªà«‹àªˆàª¨à«àªŸ àª¸àª¾àª¥à«‡
  return '${size.toStringAsFixed(size < 10 && i > 0 ? 1 : 0)} ${suffixes[i]}';
}
 */