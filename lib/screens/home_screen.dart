import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:media_player/screens/search_screen.dart';
import 'package:media_player/screens/setting_screen.dart';
import 'package:media_player/widgets/app_bar.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
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
import '../widgets/app_toast.dart';
import '../widgets/app_transition.dart';
import '../widgets/common_methods.dart';
import '../widgets/custom_loader.dart';
import '../widgets/gallary_item_widget.dart';
import '../widgets/home_card.dart';
import '../widgets/image_item_widget.dart';
import '../widgets/image_widget.dart';
import '../widgets/shimmer_effect.dart';
import 'bottom_bar_screen.dart';
import 'detail_screen.dart';
import 'home_screen.dart';
import 'mini_player.dart';

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
          return const MediaShimmerLoading();
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
                          shareItem(context, entity);
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
      AppToast.show(context, context.tr("removedFromFavourites"), type: ToastType.info);
    } else {
      favBox.put(key, {
        "id":entity.id,
        "path": file.path,
        "isNetwork": false,
        "isFavourite":isFavorite,
        "type": entity.type == AssetType.audio ? "audio" : "video",
      });
      AppToast.show(context, context.tr("addedToFavourite"), type: ToastType.success);
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


}


