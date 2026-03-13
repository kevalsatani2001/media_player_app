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
      _isLoading = false; // ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â²ÃƒÆ’ Ãƒâ€šÃ‚Â«ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¹ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¡ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¿ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚ÂªÃƒÆ’ Ãƒâ€šÃ‚Â«ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â°ÃƒÆ’ Ãƒâ€šÃ‚Â«Ãƒâ€šÃ‚ÂÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¥ÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒâ€šÃ‚Â¯ÃƒÆ’ Ãƒâ€šÃ‚Â«Ãƒâ€šÃ‚ÂÃƒÆ’ Ãƒâ€šÃ‚ÂªÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    const int adInterval = 6;
    int totalCount = folderList.length + (folderList.length ~/ adInterval);
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
              child: GridView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: totalCount,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  if (index != 0 && (index + 1) % (adInterval + 1) == 0) {
                    return  Container(
                      decoration: BoxDecoration(
                        color: Colors.white, // Ã ÂªÂÃ ÂªÂ¡ Ã ÂªÂªÃ ÂªÂ¾Ã Âªâ€ºÃ ÂªÂ³ Ã ÂªÂµÃ Â«ÂÃ ÂªÂ¹Ã ÂªÂ¾Ã Âªâ€¡Ã ÂªÅ¸ Ã ÂªÂ¬Ã Â«â€¡Ã Âªâ€¢Ã Âªâ€”Ã Â«ÂÃ ÂªÂ°Ã ÂªÂ¾Ã Âªâ€°Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¡ Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªÂ°Ã Â«ÂÃ Âªâ€š Ã ÂªÂ²Ã ÂªÂ¾Ã Âªâ€”Ã ÂªÂ¶Ã Â«â€¡
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)), // Ã Âªâ€ Ã Âªâ€°Ã ÂªÅ¸Ã ÂªÂ²Ã ÂªÂ¾Ã Âªâ€¡Ã ÂªÂ¨
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.contain, // Ã Âªâ€  Ã ÂªÂÃ ÂªÂ¡Ã ÂªÂ¨Ã Â«â€¡ Ã ÂªÂ¬Ã Â«â€¹Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¸Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã ÂªÂ«Ã ÂªÂ¿Ã ÂªÅ¸ Ã Âªâ€¢Ã ÂªÂ°Ã ÂªÂ¶Ã Â«â€¡
                            child: AdHelper.bannerAdWidget(size: AdSize.mediumRectangle),
                          ),
                        ),
                      ),
                    );
                  }

                  final int actualIndex = index - (index ~/ (adInterval + 1));
                  if (actualIndex >= folderList.length) return const SizedBox.shrink();

                  final item = folderList[actualIndex];
                  return AppTransition(
                    index: index,
                    child: GalleryItemWidget(path: item, setState: setState),
                  );
                },
              ),
            ),
            // Ã¢Å“Â¨ Ã ÂªÂ¹Ã Âªâ€šÃ ÂªÂ®Ã Â«â€¡Ã ÂªÂ¶Ã ÂªÂ¾ Ã ÂªÂ¨Ã Â«â‚¬Ã ÂªÅ¡Ã Â«â€¡ Ã ÂªÂ¦Ã Â«â€¡Ã Âªâ€“Ã ÂªÂ¾Ã ÂªÂ¤Ã Â«â‚¬ Ã ÂªÂÃ ÂªÂ¡
            AdHelper.bannerAdWidget(size: AdSize.banner),
          ],
        ),
      ),
    );
  }
}