import '../services/ads_service.dart';
import '../utils/app_imports.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<AssetPathEntity> folderList = <AssetPathEntity>[];
  bool _isLoading = true;

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
      type: RequestType.common, // Audio + Video ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¬ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¨ÃƒÆ’ Ãƒâ€šÃ‚Â«ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¡ ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â®ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¾ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€¦Ã‚Â¸ÃƒÆ’ Ãƒâ€šÃ‚Â«ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¡
      filterOption: FilterOptionGroup(),
    );

    if (!mounted) return;

    setState(() {
      folderList = galleryList;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    final List<Widget> slivers = [];
    const int chunkSize = 16;
    for (int i = 0; i < folderList.length; i += chunkSize) {
      final int currentChunkSize = chunkSize < folderList.length - i
          ? chunkSize
          : folderList.length - i;
      final int startOffset = i;

      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.all(15),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final int actualIndex = startOffset + index;
                if (actualIndex >= folderList.length) return const SizedBox.shrink();

                final item = folderList[actualIndex];
                return AppTransition(
                  index: actualIndex,
                  child: GalleryItemWidget(path: item, setState: setState),
                );
              },
              childCount: currentChunkSize,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 15,
              childAspectRatio: 1.0,
            ),
          ),
        ),
      );

      if (i + chunkSize < folderList.length) {
        slivers.add(
          SliverToBoxAdapter(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AdHelper.bannerAdWidget(size: AdSize.largeBanner),
            ),
          ),
        );
      }
    }

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
      ) : folderList.isEmpty
          ? Center(child: AppText("noFoldersFound", color: colors.whiteColor))
          : SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: slivers,
              ),
            ),
            // ✨ હંમેશા નીચે દેખાતી એડ
            AdHelper.bannerAdWidget(size: AdSize.banner),
          ],
        ),
      ),
    );
  }
}