import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:media_player/screens/search_screen.dart';
import 'package:media_player/widgets/app_bar.dart';
import 'package:media_player/widgets/app_button.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:media_player/screens/player_screen.dart';

import '../blocs/home/home_tab_bloc.dart';
import '../blocs/home/home_tab_event.dart';
import '../blocs/home/home_tab_state.dart';
import '../blocs/video/video_bloc.dart';
import '../blocs/video/video_event.dart';
import '../blocs/video/video_state.dart';
import '../core/constants.dart';
import '../main.dart';
import '../models/media_item.dart';
import '../utils/app_colors.dart';
import '../widgets/add_to_playlist.dart';
import '../widgets/app_transition.dart';
import '../widgets/home_card.dart';
import '../widgets/image_item_widget.dart';
import '../widgets/image_widget.dart';
import 'bottom_bar_screen.dart';
import 'detail_screen.dart';
import 'home_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware{
  AssetPathProvider readPathProvider(BuildContext c) =>
      c.read<AssetPathProvider>();

  AssetPathProvider watchPathProvider(BuildContext c) =>
      c.watch<AssetPathProvider>();
  List<AssetPathEntity> folderList = <AssetPathEntity>[];

  /////// 11/2
  int videoCount = 0;
  int audioCount = 0;
  int favouriteCount = 0;
  int playlistCount = 0;

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   routeObserver.subscribe(this, ModalRoute.of(context)!);
  // }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadCounts(); // <-- refresh counts when coming back
    context.read<VideoBloc>().add(LoadVideosFromGallery()); // optional: refresh video list
  }

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadCounts();
    _loadFolders();
    // });
  }
  Future<void> _loadCounts() async {
    final favBox = Hive.box('favourites');
    final videoBox = Hive.box('videos');
    final audioBox = Hive.box('audios');
    final playListBox = Hive.box('playlists');

    if (!mounted) return;

    setState(() {
      videoCount = videoBox.length;
      audioCount = audioBox.length;
      favouriteCount = favBox.length;
      playlistCount = playListBox.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildHomePageWidget();
  }

  Widget _buildHomePageWidget() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Column(
      children: [
        CommonAppBar(
          title: "videMusicPlayer",
          subTitle: "mediaPlayer",
          actionWidget: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: colors.textFieldFill,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: AppImage(src: AppSvg.searchIcon),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Grid of Cards
                //state.entitie
                Row(
                  children: [
                    Expanded(
                      child: HomeCard(
                        title: "video",
                        icon: AppSvg.videoIcon,
                        route: "/video",
                        count: videoCount,
                        loadCounts: Future(() => context.read<VideoBloc>().add(RefreshCounts())),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: HomeCard(
                        title: "audio",
                        icon: AppSvg.audioIcon,
                        route: "/audio",
                        count: audioCount,
                        loadCounts: Future(() => context.read<VideoBloc>().add(RefreshCounts())),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: HomeCard(
                        title: "playlist",
                        icon: AppSvg.playlistIcon,
                        route: "/playlist",
                        count: playlistCount,
                        loadCounts: Future(() => context.read<VideoBloc>().add(RefreshCounts())),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: HomeCard(
                        title: "favourite",
                        icon: AppSvg.favouriteIcon,
                        route: "/favourite",
                        count: favouriteCount,
                        loadCounts: Future(() => context.read<VideoBloc>().add(RefreshCounts())),
                      ),
                    ),
                  ],
                ),
                // GridView.count(
                //   shrinkWrap: true,
                //   physics: const NeverScrollableScrollPhysics(),
                //   crossAxisCount: 2,
                //   crossAxisSpacing: 16,
                //   mainAxisSpacing: 16,
                //   padding: const EdgeInsets.all(12),
                //   children: const [
                //
                //
                //     HomeCard(
                //       title: "Recent",
                //       icon: AppSvg.audioIcon,
                //       route: "/recent",
                //     ),
                //   ],
                // ),
                // Custom Tab Bar
                Padding(
                  padding: const EdgeInsets.only(
                    left: 0,
                    right: 0,
                    top: 21,
                    bottom: 15,
                  ),
                  child: Row(
                    children: [
                      _buildTab(context, "video", 0),
                      const SizedBox(width: 25),
                      _buildTab(context, "folder", 1),
                    ],
                  ),
                ),
                // Tab Content
                Padding(
                  padding: const EdgeInsets.all(0),
                  child: BlocBuilder<HomeTabBloc, HomeTabState>(
                    builder: (context, state) {
                      if (state.selectedIndex == 0) {
                        return SingleChildScrollView(
                          child: _buildVideoSection(),
                        );
                      } else {
                        return _buildFolderSection();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(BuildContext context, String title, int index) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return BlocBuilder<HomeTabBloc, HomeTabState>(
      builder: (context, state) {
        final isActive = state.selectedIndex == index;

        return GestureDetector(
          onTap: () async {
            context.read<HomeTabBloc>().add(SelectTab(index));
            if (index == 1) {
              await _loadFolders();
            } else if (index == 0) {
              context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText(
                title,
                color: isActive
                    ? colors.appBarTitleColor
                    : colors.textFieldBorder,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 3,
                width: isActive ? 30 : 0,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Video Section using VideoBloc
  Widget _buildVideoSection() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        if (state is VideoLoading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (state is VideoError) {
          return Center(child: Text(state.message));
        }

        if (state is VideoLoaded) {
          final entities = state.entities;
          if (entities.isEmpty) {
            return  AppText("noVideosFound",color: colors.whiteColor,);
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entities.length,
            itemBuilder: (context, index) {
              final entity = entities[index];
              return AppTransition(
                  index: index,
                  child: ImageItemWidget(
                    onMenuSelected: (action) async {
                      switch (action) {
                        case MediaMenuAction.detail:
                          routeToDetailPage(entity);
                          break;

                        case MediaMenuAction.info:
                          showInfoDialog(context, entity);
                          break;

                        case MediaMenuAction.thumb:
                          showThumb(entity, 500);
                          break;

                        case MediaMenuAction.share:
                          _shareItem(context, entity);
                          break;

                        case MediaMenuAction.delete:
                          deleteCurrentItem(context, entity);
                          break;

                        case MediaMenuAction.addToFavourite:
                          await _toggleFavourite(context, entity, index);
                          break;
                        case MediaMenuAction.addToPlaylist:
                          final file = await entity.file;
                          addToPlaylist(
                            MediaItem(
                              path: file!.path,
                              isNetwork: false,
                              type: entity.type==AssetType.audio?"audio":"video",
                              id: entity.id,
                              isFavourite: entity.isFavorite,
                            ),
                            context,
                          );
                          break;
                      }
                    },
                    onTap: () async {
                      print("vudio====${entity.typeInt}");
                      final file = await entity.file;
                      if (file == null || !file.existsSync()) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(
                            entity: entity,
                            item: MediaItem(
                              isFavourite: entity.isFavorite,
                              id: entity.id,
                              path: file.path,
                              isNetwork: false,
                              type: entity.type == AssetType.video
                                  ? 'video'
                                  : 'audio',
                            ),
                          ),
                        ),
                      ).then((value) {
                        context.read<VideoBloc>().add(
                          LoadVideosFromGallery(showLoading: false),
                        );
                      });
                    },
                    isGrid: false,
                    entity: entity,
                    option: const ThumbnailOption(size: ThumbnailSize.square(300)),
                  )// તમારી ઓડિયો લિસ્ટ આઈટમ
              );

            },
          );
        }

        return const SizedBox();
      },
    );
  }


  Future<void> _toggleFavourite(
      BuildContext context,
      AssetEntity entity,
      int index,
      ) async {
    final favBox = Hive.box('favourites');
    final bool isFavorite = entity.isFavorite;

    final file = await entity.file;
    if (file == null) return;

    final key = file.path;

    // 🔹 Update Hive
    if (isFavorite) {
      favBox.delete(key);
    } else {
      favBox.put(key, {
        "path": file.path,
        "isNetwork": false,
        "type": entity.type == AssetType.audio ? "audio" : "video",
      });
    }

    // 🔹 Update system favourite
    if (PlatformUtils.isOhos) {
      await PhotoManager.editor.ohos.favoriteAsset(
        entity: entity,
        favorite: !isFavorite,
      );
    } else if (Platform.isAndroid) {
      await PhotoManager.editor.android.favoriteAsset(
        entity: entity,
        favorite: !isFavorite,
      );
    } else {
      await PhotoManager.editor.darwin.favoriteAsset(
        entity: entity,
        favorite: !isFavorite,
      );
    }

    // 🔹 Reload entity
    final AssetEntity? newEntity = await entity.obtainForNewProperties();
    if (!mounted || newEntity == null) return;

    // 🔹 Update UI list
    // readPathProvider(context).list[index] = newEntity;
    context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));

    setState(() {});
  }

  // Folder Section
  Widget _buildFolderSection() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    if (folderList.isEmpty) {
      return  AppText(
          "noFoldersFound",
          color: colors.whiteColor
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: folderList.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 15,
        childAspectRatio: 1.05,
      ),itemBuilder: (context, index) {
      final item = folderList[index];
      return AppTransition(
        index: index,
        columnCount: 3, // અહીં ગ્રીડની કોલમ લખો
        child: GalleryItemWidget(path: item, setState: setState), // તમારો વીડિયો કે ફોટો વિજેટ
      );



    },);
  }

  // Load folders using PhotoManager
  Future<void> _loadFolders() async {
    final permission = await PhotoManager.requestPermissionExtend(
      requestOption: PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.fromTypes([RequestType.audio, RequestType.video]),
          mediaLocation: true,
        ),
      ),
    );

    if (!permission.hasAccess) return;

    final List<AssetPathEntity> galleryList =
    await PhotoManager.getAssetPathList(
      type: RequestType.fromTypes([RequestType.audio, RequestType.video]),
      filterOption: FilterOptionGroup(),
      pathFilterOption: PMPathFilter(
        darwin: PMDarwinPathFilter(
          type: [PMDarwinAssetCollectionType.album],
        ),
      ),
    );

    if (!mounted) return;   // ✅ VERY IMPORTANT

    setState(() {
      folderList = galleryList;
    });
  }


  Future<void> routeToDetailPage(AssetEntity entity) async {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => DetailPage(entity: entity)),
    );
  }

  Future<void> showThumb(AssetEntity entity, int size) async {
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
                  child: const CircularProgressIndicator(),
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

  Future<void> _shareItem(BuildContext context, AssetEntity entity) async {
    try {
      // ૧. એસેટમાંથી ફાઈલ મેળવો
      final File? file = await entity.file;

      if (file != null && await file.exists()) {
        // ૨. ફાઈલનો પાથ ચેક કરો
        debugPrint("Sharing file path: ${file.path}");

        // ૩. ShareXFiles નો ઉપયોગ કરો
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Sharing: ${entity.title ?? "Media File"}', // આ મેસેજ સાથે જશે
        );
      } else {
        debugPrint("File not found or entity.file returned null");
        // જો ફાઈલ ના મળે તો યુઝરને મેસેજ બતાવો
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File cannot be loaded for sharing")),
        );
      }
    } catch (e) {
      debugPrint("Error sharing file: $e");
    }
  }
}


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
        'Delete this file?',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: colors.appBarTitleColor,
        align: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            'Are you sure to delete this selected files?',
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
                  title: "Yes",
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
                  title: "No",
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

  // ✅ Correct delete API
  final result = await PhotoManager.editor.deleteWithIds([entity.id]);

  if (result.isNotEmpty) {
    context.read<VideoBloc>().add(LoadVideosFromGallery(showLoading: false));
  }
}

String formatDuration(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}