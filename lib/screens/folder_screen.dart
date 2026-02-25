import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../core/constants.dart';
import '../utils/app_colors.dart';
import '../widgets/app_transition.dart';
import '../widgets/gallary_item_widget.dart';
import '../widgets/image_widget.dart';
import '../widgets/text_widget.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<AssetPathEntity> folderList = <AssetPathEntity>[];
  bool _isLoading = true; // લોડિંગ સ્ટેટ ઉમેર્યું

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final permission = await PhotoManager.requestPermissionExtend();

    if (!permission.hasAccess) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final List<AssetPathEntity> galleryList = await PhotoManager.getAssetPathList(
      type: RequestType.common, // Audio + Video બંને માટે
      filterOption: FilterOptionGroup(),
    );

    if (!mounted) return;

    setState(() {
      folderList = galleryList;
      _isLoading = false; // લોડિંગ પૂરું થયું
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: AppImage(
              src: AppSvg.backArrowIcon,
              height: 20,
              width: 20,
            ),
          ),
        ),
        centerTitle: true,
        title: AppText("folder", fontSize: 20, fontWeight: FontWeight.w500),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // લોડિંગ સમયે લોડર બતાવો
          : folderList.isEmpty
          ? Center(child: AppText("noFoldersFound", color: colors.whiteColor))
          : SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(15),
          // physics હવે કાઢી નાખ્યું છે જેથી સ્ક્રોલિંગ થાય
          itemCount: folderList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 15,
            childAspectRatio: 1.0, // ચોરસ રાખવા માટે 1.0 બેસ્ટ છે
          ),
          itemBuilder: (context, index) {
            final item = folderList[index];
            return AppTransition(
              index: index,
              child: GalleryItemWidget(
                path: item,
                setState: setState,
              ),
            );
          },
        ),
      ),
    );
  }
}
