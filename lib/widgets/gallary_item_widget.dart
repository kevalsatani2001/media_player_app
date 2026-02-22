import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:photo_manager/photo_manager.dart';

import '../core/constants.dart';
import '../screens/bottom_bar_screen.dart';
import '../screens/gallary_content_list_screen.dart';
import '../utils/app_colors.dart';
import 'image_widget.dart';

class GalleryItemWidget extends StatelessWidget {
  const GalleryItemWidget({
    super.key,
    required this.path,
    required this.setState,
  });

  final AssetPathEntity path;
  final ValueSetter<VoidCallback> setState;

  Widget buildGalleryItemWidget(AssetPathEntity item, BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final navigator = Navigator.of(context);
    return InkWell(
      onTap: () async {
        if (item.albumType == 2) {
          Fluttertoast.showToast(msg: "The folder can't get asset");
          return;
        }
        if (await item.assetCountAsync == 0) {
          Fluttertoast.showToast(msg: 'The asset count is 0.');
          return;
        }
        navigator.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => GalleryContentListPage(path: item),
          ),
        );
      },
      onLongPress: () => Platform.isIOS || Platform.isMacOS
          ? showDialog<void>(
        context: context,
        builder: (_) {
          return ListDialog(
            children: <Widget>[
              if (Platform.isIOS || Platform.isMacOS) ...[
                ElevatedButton(
                  child: Text('Delete self (${item.name})'),
                  onPressed: () async {
                    if (!(Platform.isIOS || Platform.isMacOS)) {
                      Fluttertoast.showToast(
                        msg: 'The function only support iOS.',
                      );
                      return;
                    }
                    PhotoManager.editor.darwin.deletePath(path);
                  },
                ),
              ],
            ],
          );
        },
      )
          : SizedBox(),
      child: Container(
        decoration: BoxDecoration(
          color: colors.textFieldFill,
          borderRadius: BorderRadius.circular(15.92),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppImage(src: AppSvg.folderIcon),
              SizedBox(height: 21.22),
              AppText(
                item.name,
                align: TextAlign.center,
                maxLines: 1,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.appBarTitleColor,
              ),
              SizedBox(height: 2.41),
              FutureBuilder<int>(
                future: item.assetCountAsync,
                builder: (_, AsyncSnapshot<int> data) {
                  if (data.hasData) {
                    return AppText(
                      maxLines: 1,
                      align: TextAlign.center,
                      '${data.data} items',
                      fontSize: 12,
                      color: colors.textFieldBorder,
                      fontWeight: FontWeight.w400,
                    );
                    // Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   mainAxisSize: MainAxisSize.min,
                    //   children: [
                    //     Text('${data.data} items'),
                    //     FutureBuilder<String?>(
                    //       future: item.relativePathAsync,
                    //       builder: (_, AsyncSnapshot<String?> pathData) {
                    //         if (pathData.connectionState == ConnectionState.done) {
                    //           final path = pathData.data;
                    //           if (path != null) {
                    //             return Text(
                    //               'path: $path',
                    //               style: TextStyle(
                    //                 fontSize: 12,
                    //                 color: Colors.grey[600],
                    //               ),
                    //             );
                    //           }
                    //         }
                    //         return const SizedBox.shrink();
                    //       },
                    //     ),
                    //   ],
                    // );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),

      //
      // ListTile(
      //   title: Text(item.name),
      //   subtitle: FutureBuilder<int>(
      //     future: item.assetCountAsync,
      //     builder: (_, AsyncSnapshot<int> data) {
      //       if (data.hasData) {
      //         return Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           mainAxisSize: MainAxisSize.min,
      //           children: [
      //             Text('count : ${data.data}'),
      //             FutureBuilder<String?>(
      //               future: item.relativePathAsync,
      //               builder: (_, AsyncSnapshot<String?> pathData) {
      //                 if (pathData.connectionState == ConnectionState.done) {
      //                   final path = pathData.data;
      //                   if (path != null) {
      //                     return Text(
      //                       'path: $path',
      //                       style: TextStyle(
      //                         fontSize: 12,
      //                         color: Colors.grey[600],
      //                       ),
      //                     );
      //                   }
      //                 }
      //                 return const SizedBox.shrink();
      //               },
      //             ),
      //           ],
      //         );
      //       }
      //       return const SizedBox.shrink();
      //     },
      //   ),
      // ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildGalleryItemWidget(path, context);
  }
}