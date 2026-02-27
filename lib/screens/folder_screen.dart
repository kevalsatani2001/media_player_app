import '../utils/app_imports.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<AssetPathEntity> folderList = <AssetPathEntity>[];
  bool _isLoading = true; // àª²à«‹àª¡àª¿àª‚àª— àª¸à«àªŸà«‡àªŸ àª‰àª®à«‡àª°à«àª¯à«àª‚

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
      type: RequestType.common, // Audio + Video àª¬àª‚àª¨à«‡ àª®àª¾àªŸà«‡
      filterOption: FilterOptionGroup(),
    );

    if (!mounted) return;

    setState(() {
      folderList = galleryList;
      _isLoading = false; // àª²à«‹àª¡àª¿àª‚àª— àªªà«‚àª°à«àª‚ àª¥àª¯à«àª‚
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
            child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20),
          ),
        ),
        centerTitle: true,
        title: AppText("folder", fontSize: 20, fontWeight: FontWeight.w500),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      ) // àª²à«‹àª¡àª¿àª‚àª— àª¸àª®àª¯à«‡ àª²à«‹àª¡àª° àª¬àª¤àª¾àªµà«‹
          : folderList.isEmpty
          ? Center(child: AppText("noFoldersFound", color: colors.whiteColor))
          : SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(15),
          // physics àª¹àªµà«‡ àª•àª¾àª¢à«€ àª¨àª¾àª–à«àª¯à«àª‚ àª›à«‡ àªœà«‡àª¥à«€ àª¸à«àª•à«àª°à«‹àª²àª¿àª‚àª— àª¥àª¾àª¯
          itemCount: folderList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 15,
            childAspectRatio: 1.0, // àªšà«‹àª°àª¸ àª°àª¾àª–àªµàª¾ àª®àª¾àªŸà«‡ 1.0 àª¬à«‡àª¸à«àªŸ àª›à«‡
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