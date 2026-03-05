import '../utils/app_imports.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<AssetPathEntity> folderList = <AssetPathEntity>[];
  bool _isLoading = true; // Ã ÂªÂ²Ã Â«â€¹Ã ÂªÂ¡Ã ÂªÂ¿Ã Âªâ€šÃ Âªâ€” Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸Ã Â«â€¡Ã ÂªÅ¸ Ã Âªâ€°Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ°Ã Â«ÂÃ ÂªÂ¯Ã Â«ÂÃ Âªâ€š

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

    final List<AssetPathEntity> galleryList =
    await PhotoManager.getAssetPathList(
      type: RequestType.common, // Audio + Video Ã ÂªÂ¬Ã Âªâ€šÃ ÂªÂ¨Ã Â«â€¡ Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡
      filterOption: FilterOptionGroup(),
    );

    if (!mounted) return;

    setState(() {
      folderList = galleryList;
      _isLoading = false; // Ã ÂªÂ²Ã Â«â€¹Ã ÂªÂ¡Ã ÂªÂ¿Ã Âªâ€šÃ Âªâ€” Ã ÂªÂªÃ Â«â€šÃ ÂªÂ°Ã Â«ÂÃ Âªâ€š Ã ÂªÂ¥Ã ÂªÂ¯Ã Â«ÂÃ Âªâ€š
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
            child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20,color: colors.blackColor,),
          ),
        ),
        centerTitle: true,
        title: AppText("folder", fontSize: 20, fontWeight: FontWeight.w500),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      ) // Ã ÂªÂ²Ã Â«â€¹Ã ÂªÂ¡Ã ÂªÂ¿Ã Âªâ€šÃ Âªâ€” Ã ÂªÂ¸Ã ÂªÂ®Ã ÂªÂ¯Ã Â«â€¡ Ã ÂªÂ²Ã Â«â€¹Ã ÂªÂ¡Ã ÂªÂ° Ã ÂªÂ¬Ã ÂªÂ¤Ã ÂªÂ¾Ã ÂªÂµÃ Â«â€¹
          : folderList.isEmpty
          ? Center(child: AppText("noFoldersFound", color: colors.whiteColor))
          : SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: folderList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 15,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final item = folderList[index];
            return AppTransition(
              index: index,
              child: GalleryItemWidget(path: item, setState: setState),
            );
          },
        ),
      ),
    );
  }
}