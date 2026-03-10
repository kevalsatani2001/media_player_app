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
      type: RequestType.common, // Audio + Video Ãƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚ÂªÃ¢â‚¬Å¡Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚Â«Ã¢â‚¬Â¡
      filterOption: FilterOptionGroup(),
    );

    if (!mounted) return;

    setState(() {
      folderList = galleryList;
      _isLoading = false; // Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ¢â‚¬Å¡Ãƒ Ã‚ÂªÃ¢â‚¬â€ Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚Â«Ã¢â‚¬Å¡Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡
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
                  // âœ¨ àªàª¡ àª¬àª¤àª¾àªµàªµàª¾àª¨à«àª‚ àª²à«‹àªœàª¿àª•
                  if (index != 0 && (index + 1) % (adInterval + 1) == 0) {
                    // Grid àª®àª¾àª‚ àªàª¡ àª¬àª¤àª¾àªµàªµàª¾ àª®àª¾àªŸà«‡ àª¤à«‡àª¨à«‡ 'Sliver' àª…àª¥àªµàª¾ àª†àª–àª¾ Row àª®àª¾àª‚ àª²à«‡àªµà«€ àªªàª¡à«‡
                    // àªœà«‹ GridView àªµàª¾àªªàª°àª¤àª¾ àª¹à«‹àªµ àª¤à«‹ àªàª¡àª¨à«‡ àªàª• Grid Item àª¤àª°à«€àª•à«‡ àª¬àª¤àª¾àªµà«€ àª¶àª•àª¾àª¯
                    return Container(
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: AdHelper.bannerAdWidget(size: AdSize.mediumRectangle),
                      ),
                    );
                  }

                  // àª¸àª¾àªšà«‹ àª‡àª¨à«àª¡à«‡àª•à«àª¸
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
            // âœ¨ àª¹àª‚àª®à«‡àª¶àª¾ àª¨à«€àªšà«‡ àª¦à«‡àª–àª¾àª¤à«€ àªàª¡
            AdHelper.bannerAdWidget(size: AdSize.banner),
          ],
        ),
      ),
    );
  }
}