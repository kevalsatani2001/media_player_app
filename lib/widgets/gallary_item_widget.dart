import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/ads_service.dart';
import '../utils/app_imports.dart';

class GalleryItemWidget extends StatelessWidget {
  const GalleryItemWidget({
    super.key,
    required this.path,
    required this.setState,
  });

  final AssetPathEntity path;
  final ValueSetter<VoidCallback> setState;

  // âœ¨ àª¸à«àªŸà«‡àªŸàª¿àª• àª•àª¾àª‰àª¨à«àªŸàª°: àªœà«‡ àª®à«‡àª®àª°à«€àª®àª¾àª‚ àª¸à«àªŸà«‹àª° àª°àª¹à«‡àª¶à«‡ àª…àª¨à«‡ àª¦àª°à«‡àª• àª•à«àª²àª¿àª• àª—àª£àª¶à«‡
  static int _clickCount = 0;

  Widget buildGalleryItemWidget(AssetPathEntity item, BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final navigator = Navigator.of(context);

    return InkWell(
      onTap: () async {
        if (item.albumType == 2) {
          Fluttertoast.showToast(msg: "The folder can't get asset");
          return;
        }

        final count = await item.assetCountAsync;
        if (count == 0) {
          Fluttertoast.showToast(msg: 'The asset count is 0.');
          return;
        }

        // âœ¨ àª•à«àª²àª¿àª• àª•àª¾àª‰àª¨à«àªŸàª° àª²à«‹àªœàª¿àª•
        _clickCount++;

        if (_clickCount % 3 == 0) {
          // àª¦àª° à«© àªœà«€ àª•à«àª²àª¿àª• àªªàª° àªàª¡ àª¬àª¤àª¾àªµà«‹
          AdHelper.showInterstitialAd(() {
            navigator.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => GalleryContentListPage(path: item),
              ),
            );
          });
        } else {
          // àª¬àª¾àª•à«€àª¨à«€ àª•à«àª²àª¿àª• àªªàª° àª¸à«€àª§à«àª‚ àª¨à«‡àªµàª¿àª—à«‡àª¶àª¨
          navigator.push<void>(
            MaterialPageRoute<void>(
              builder: (_) => GalleryContentListPage(path: item),
            ),
          );
        }
      },
      onLongPress: () => (Platform.isIOS || Platform.isMacOS)
          ? showDialog<void>(
        context: context,
        builder: (_) {
          return ListDialog(
            children: <Widget>[
              ElevatedButton(
                child: Text('Delete self (${item.name})'),
                onPressed: () async {
                  PhotoManager.editor.darwin.deletePath(path);
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      )
          : const SizedBox.shrink(),
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(15.92),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppImage(src: AppSvg.folderIcon),
              const SizedBox(height: 21.22),
              AppText(
                item.name,
                align: TextAlign.center,
                maxLines: 1,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.appBarTitleColor,
              ),
              const SizedBox(height: 2.41),
              FutureBuilder<int>(
                future: item.assetCountAsync,
                builder: (_, AsyncSnapshot<int> data) {
                  if (data.hasData) {
                    return AppText(
                      '${data.data} items',
                      maxLines: 1,
                      align: TextAlign.center,
                      fontSize: 12,
                      color: colors.textFieldBorder,
                      fontWeight: FontWeight.w400,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildGalleryItemWidget(path, context);
  }
}