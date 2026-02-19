import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:media_player/blocs/theme/theme_event.dart';
import 'package:media_player/core/constants.dart';
import 'package:media_player/screens/audio_screen.dart';
import 'package:media_player/screens/setting_screen.dart';
import 'package:media_player/screens/video_screen.dart';
import 'package:media_player/widgets/image_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../blocs/bottom_nav/bottom_nav_event.dart';
import '../blocs/bottom_nav/bottom_nav_state.dart';
import '../blocs/bottom_nav/botton_nav_bloc.dart';
import '../blocs/home/home_tab_bloc.dart';
import '../blocs/home/home_tab_event.dart';
import '../blocs/home/home_tab_state.dart';
import '../blocs/local/local_bloc.dart';
import '../blocs/local/local_event.dart';
import '../blocs/local/local_state.dart';
import '../blocs/theme/theme_bloc.dart';
import '../blocs/theme/theme_state.dart';
import '../blocs/video/video_event.dart';
import '../blocs/video/video_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_string.dart';
import '../widgets/add_to_playlist.dart';
import '../widgets/app_button.dart';
import '../widgets/home_card.dart';
import '../blocs/video/video_bloc.dart';
import '../widgets/image_item_widget.dart';
import '../models/media_item.dart';
import '../widgets/text_widget.dart';
import 'detail_screen.dart';
import 'home_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AssetPathEntity> folderList = <AssetPathEntity>[];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LocaleBloc()),
        BlocProvider(create: (_) => HomeTabBloc()),
        BlocProvider(create: (_) => BottomNavBloc()), // Bottom nav bloc
        BlocProvider(
          create: (_) =>
          VideoBloc(Hive.box('videos'))..add(LoadVideosFromGallery()),
        ), // Bottom nav bloc
      ],
      child: BlocBuilder<BottomNavBloc, BottomNavState>(
        builder: (context, bottomState) {
          return WillPopScope(
            onWillPop: () async{
              if(bottomState.selectedIndex==0){
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    actionsPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(20)),
                    insetPadding: EdgeInsets.symmetric(horizontal: 36),
                    contentPadding: EdgeInsets.only(left: 33,right: 33,bottom: 20,top: 40),
                    backgroundColor: colors.cardBackground,
                    title: AppText(
                      'Exit app?',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: colors.appBarTitleColor,
                      align: TextAlign.center,
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          'Oh no! you are leave this application?',
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
                                onTap: () =>SystemNavigator.pop(),
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
                                onTap: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // content: const Text('Are you sure you want to delete this file?'),
                  ),
                );
              }
              else{
                context.read<BottomNavBloc>().add(
                  SelectBottomTab(0),
                );
              }
              return true;
            },
            child: Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    // Padding(
                    //   padding: const EdgeInsets.only(top: 10),
                    //   child: Padding(
                    //     padding: const EdgeInsets.symmetric(horizontal: 15),
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //       children: [
                    //         Row(
                    //           children: [
                    //             AppImage(src: AppSvg.appBarIcon),
                    //             SizedBox(width: 8),
                    //             Column(
                    //               crossAxisAlignment: CrossAxisAlignment.start,
                    //               children: [
                    //                 AppText(
                    //                   "Video & Music Player",
                    //                   fontFamily: AppFontFamily.oleoScript,
                    //                   fontSize: 23,
                    //                   fontWeight: FontWeight.w400,
                    //                   color: colors.appBarTitleColor,
                    //                 ),
                    //                 AppText(
                    //                   "MEDIA PLAYER",
                    //                   fontSize: 14,
                    //                   fontWeight: FontWeight.w600,
                    //                   color: colors.textFieldBorder,
                    //                 ),
                    //               ],
                    //             ),
                    //           ],
                    //         ),
                    //         Container(
                    //           decoration: BoxDecoration(
                    //             borderRadius: BorderRadius.circular(8),
                    //             color: colors.textFieldFill,
                    //           ),
                    //           child: Padding(
                    //             padding: const EdgeInsets.all(8),
                    //             child: AppImage(src: AppSvg.searchIcon),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    Expanded(
                      child: _buildBodyForBottomTab(bottomState.selectedIndex),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(13.73),
                          topRight: Radius.circular(13.73),
                        ),
                        color: colors.whiteColor,
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(0, -4),
                            blurRadius: 9,
                            color: colors.blackColor.withOpacity(0.10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 27,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBottomNavItem(
                                  () {
                                context.read<BottomNavBloc>().add(
                                  SelectBottomTab(0),
                                );
                              },
                              bottomState,
                              0,
                              AppSvg.homeSelected,
                              AppSvg.homeUnselected,
                            ),
                            _buildBottomNavItem(
                                  () {
                                context.read<BottomNavBloc>().add(
                                  SelectBottomTab(1),
                                );
                              },
                              bottomState,
                              1,
                              AppSvg.videoSelected,
                              AppSvg.videoUnselected,
                            ),
                            _buildBottomNavItem(
                                  () {
                                context.read<BottomNavBloc>().add(
                                  SelectBottomTab(2),
                                );
                              },
                              bottomState,
                              2,
                              AppSvg.musicSelected,
                              AppSvg.musicUnselected,
                            ),
                            _buildBottomNavItem(
                                  () {
                                context.read<BottomNavBloc>().add(
                                  SelectBottomTab(3),
                                );
                              },
                              bottomState,
                              3,
                              AppSvg.settingSelected,
                              AppSvg.settingUnselected,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LocaleBloc()),
        BlocProvider(create: (_) => HomeTabBloc()),
        BlocProvider(create: (_) => BottomNavBloc()), // Bottom nav bloc
        BlocProvider(
          create: (_) =>
          VideoBloc(Hive.box('videos'))..add(LoadVideosFromGallery()),
        ), // Bottom nav bloc
      ],
      child: BlocBuilder<BottomNavBloc, BottomNavState>(
        builder: (context, bottomState) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                bottomState.selectedIndex == 0
                    ? 'Media Player'
                    : bottomState.selectedIndex == 1
                    ? 'Videos'
                    : bottomState.selectedIndex == 2
                    ? 'Audio'
                    : 'Settings',
              ),
            ),
            body: _buildBodyForBottomTab(bottomState.selectedIndex),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: bottomState.selectedIndex,
              onTap: (index) =>
                  context.read<BottomNavBloc>().add(SelectBottomTab(index)),
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AppImage(src: AppSvg.homeUnselected),
                  ),
                  activeIcon: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AppImage(
                      src: AppSvg.homeSelected,
                      height: 30,
                      width: 30,
                    ),
                  ),
                  label: AppStrings.get(context, 'home'),
                ),
                BottomNavigationBarItem(
                  icon: AppImage(src: AppSvg.videoUnselected),
                  activeIcon: AppImage(src: AppSvg.videoSelected),
                  label: AppStrings.get(context, 'video'),
                ),
                BottomNavigationBarItem(
                  icon: AppImage(src: AppSvg.musicUnselected),
                  activeIcon: AppImage(src: AppSvg.musicSelected),
                  label: AppStrings.get(context, 'audio'),
                ),
                BottomNavigationBarItem(
                  icon: AppImage(src: AppSvg.settingUnselected),
                  activeIcon: AppImage(src: AppSvg.settingSelected),
                  label: AppStrings.get(context, 'settings'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  _buildBottomNavItem(
      void Function()? onTap,
      BottomNavState bottomState,
      int index,
      String selectedIcon,
      String unSelectedIcon,
      ) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: bottomState.selectedIndex == index
              ? colors.primary
              : Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: AppImage(
            src: bottomState.selectedIndex == index
                ? selectedIcon
                : unSelectedIcon,
          ),
        ),
      ),
    );
  }

  // Switch body content based on bottom nav index
  Widget _buildBodyForBottomTab(int index) {
    switch (index) {
      case 0:
        return HomePage();
    // return _buildHomeTab();
      case 1:
        return BlocProvider(
          create: (_) => VideoBloc(Hive.box('videos'))
            ..add(LoadVideosFromGallery(showLoading: false)),
          child: VideoScreen(isComeHomeScreen: false,)
        );
    // return VideoScreen(isComeHomeScreen: false);
    // return _buildVideoSection();
      case 2:
        return AudioScreen(isComeHomeScreen: false);
      case 3:
        return SettingScreen();
    // return _buildSettingsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BlocBuilder<ThemeBloc, ThemeState>(
          //   builder: (context, themeState) {
          //     return ListTile(
          //       leading: Icon(Icons.light_mode,
          //         // themeState.isDark ? Icons.dark_mode : Icons.light_mode,
          //       ),
          //       title: Text(AppStrings.get(context, 'theme')),
          //       trailing: Switch(
          //         value: themeState.isDark,
          //         onChanged: (_) =>
          //             context.read<ThemeBloc>().add(ToggleTheme()),
          //       ),
          //     );
          //   },
          // ),
          const SizedBox(height: 20),
          BlocBuilder<LocaleBloc, LocaleState>(
            builder: (context, localeState) {
              return Row(
                children: [
                  Text('${AppStrings.get(context, 'language')}: '),
                  const SizedBox(width: 16),
                  DropdownButton<Locale>(
                    value: localeState.locale,
                    items: AppStrings.translations.keys.map((langCode) {
                      // get the display name of the language from translations
                      final langName =
                          AppStrings.translations[langCode]?['language'] ??
                              langCode;
                      return DropdownMenuItem<Locale>(
                        value: Locale(langCode),
                        child: Text(langName),
                      );
                    }).toList(),
                    onChanged: (locale) {
                      if (locale != null) {
                        context.read<LocaleBloc>().add(ChangeLocale(locale));
                        setState(() {});
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // // Original Home tab content
  // Widget _buildHomeTab() {
  //   return SingleChildScrollView(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // Top Grid of Cards
  //         GridView.count(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           crossAxisCount: 2,
  //           padding: const EdgeInsets.all(12),
  //           children: const [
  //             HomeCard(
  //               title: 'Video',
  //               icon: Icons.video_library,
  //               route: '/video',
  //             ),
  //             HomeCard(title: 'Audio', icon: Icons.music_note, route: '/audio'),
  //             HomeCard(
  //               title: 'Playlist',
  //               icon: Icons.queue_music,
  //               route: '/playlist',
  //             ),
  //             HomeCard(
  //               title: 'Favourite',
  //               icon: Icons.favorite,
  //               route: '/favourite',
  //             ),
  //             HomeCard(title: 'Recent', icon: Icons.history, route: '/recent'),
  //           ],
  //         ),
  //
  //         // Custom Tab Bar
  //         Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //           child: Row(
  //             children: [
  //               Expanded(child: _buildTab(context, 'Video', 0)),
  //               const SizedBox(width: 16),
  //               Expanded(child: _buildTab(context, 'Folder', 1)),
  //             ],
  //           ),
  //         ),
  //
  //         // Tab Content
  //         Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: BlocBuilder<HomeTabBloc, HomeTabState>(
  //             builder: (context, state) {
  //               if (state.selectedIndex == 0) {
  //                 return _buildVideoSection();
  //               } else {
  //                 return _buildFolderSection();
  //               }
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTab(BuildContext context, String title, int index) {
    return BlocBuilder<HomeTabBloc, HomeTabState>(
      builder: (context, state) {
        final isActive = state.selectedIndex == index;

        return GestureDetector(
          onTap: () async {
            context.read<HomeTabBloc>().add(SelectTab(index));
            if (index == 1) {
              await _loadFolders();
            } else if (index == 0) {
              context.read<VideoBloc>().add(LoadVideosFromGallery());
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 18,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 3,
                width: isActive ? 30 : 0,
                decoration: BoxDecoration(
                  color: Colors.red,
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
            return const Text(
              "No videos found",
              style: TextStyle(color: Colors.white),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entities.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final entity = entities[index];
              return GestureDetector(
                onTap: () async {
                  final file = await entity.file;
                  if (file == null || !file.existsSync()) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        item: MediaItem(
                          path: file.path,
                          isNetwork: false,
                          type: 'video', id: entity.id, isFavourite: entity.isFavorite,
                        ),
                      ),
                    ),
                  );
                },
                child: ImageItemWidget(
                  entity: entity,
                  option: ThumbnailOption(size: ThumbnailSize.square(200)),
                ),
              );
            },
          );

          // return const SizedBox();
        }
        return SizedBox();
      },
    );
  }

  // Folder Section
  Widget _buildFolderSection() {
    if (folderList.isEmpty) {
      return const Text(
        "No folders found",
        style: TextStyle(color: Colors.white),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: folderList.length,
      itemBuilder: (context, index) {
        final item = folderList[index];
        return GalleryItemWidget(path: item, setState: setState);
      },
    );
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

    setState(() {
      folderList.clear();
      folderList.addAll(galleryList);
    });
  }
}

//////////////////////////////////////////////////////////////

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
              SizedBox(height: 21.22,),
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

//////////////////////////////////////////////////////////////

class SubFolderPage extends StatefulWidget {
  const SubFolderPage({super.key, required this.pathList, required this.title});

  final List<AssetPathEntity> pathList;
  final String title;

  @override
  State<SubFolderPage> createState() => _SubFolderPageState();
}

//////////////////////////////////////////////////////////////

class _SubFolderPageState extends State<SubFolderPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.builder(
        itemBuilder: _buildItem,
        itemCount: widget.pathList.length,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final AssetPathEntity item = widget.pathList[index];
    return GalleryItemWidget(path: item, setState: setState);
  }
}

class ListDialog extends StatefulWidget {
  const ListDialog({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  State<ListDialog> createState() => _ListDialogState();
}

class _ListDialogState extends State<ListDialog> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        padding: widget.padding,
        shrinkWrap: true,
        children: widget.children,
      ),
    );
  }
}

//////////////////////////////////////////////////////////////

ThumbnailFormat _thumbFormat = ThumbnailFormat.jpeg;

ThumbnailFormat get thumbFormat => _thumbFormat;

set thumbFormat(ThumbnailFormat thumbFormat) {
  _thumbFormat = thumbFormat;
}

class GalleryContentListPage extends StatefulWidget {
  const GalleryContentListPage({super.key, required this.path});

  final AssetPathEntity path;

  @override
  State<GalleryContentListPage> createState() => _GalleryContentListPageState();
}

class _GalleryContentListPageState extends State<GalleryContentListPage> {
  AssetPathEntity get path => widget.path;

  AssetPathProvider readPathProvider(BuildContext context) =>
      context.read<AssetPathProvider>();

  AssetPathProvider watchPathProvider(BuildContext c) =>
      c.watch<AssetPathProvider>();

  @override
  void initState() {
    super.initState();
    path.getAssetListRange(start: 0, end: 1).then((List<AssetEntity> value) {
      if (value.isEmpty) {
        return;
      }
      if (mounted) {
        return;
      }
      PhotoCachingManager().requestCacheAssets(
        assets: value,
        option: thumbOption,
      );
    });
  }

  @override
  void dispose() {
    PhotoCachingManager().cancelCacheRequest();
    super.dispose();
  }

  ThumbnailOption get thumbOption => ThumbnailOption(
    size: const ThumbnailSize.square(200),
    format: thumbFormat,
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return ChangeNotifierProvider<AssetPathProvider>(
      create: (_) => AssetPathProvider(widget.path),
      builder: (BuildContext context, _) => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: AppText(
            path.name,
            color: colors.appBarTitleColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        body: buildRefreshIndicator(context),
      ),
    );
  }

  Widget buildRefreshIndicator(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Scrollbar(
          child: CustomScrollView(
            slivers: <Widget>[
              Consumer<AssetPathProvider>(
                builder: (BuildContext c, AssetPathProvider p, _) => SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, int index) => Builder(
                      builder: (BuildContext c) => _buildItem(context, index),
                    ),
                    childCount: p.showItemCount,
                    findChildIndexCallback: (Key? key) {
                      if (key is ValueKey<String>) {
                        return findChildIndexBuilder(
                          id: key.value,
                          assets: p.list,
                        );
                      }
                      return null;
                    },
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.05,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final List<AssetEntity> list = watchPathProvider(context).list;
    if (list.length == index) {
      onLoadMore(context);
      return loadWidget;
    }

    if (index > list.length) {
      return const SizedBox.shrink();
    }

    AssetEntity entity = list[index];
    return ImageItemWidget(
      key: ValueKey<int>(entity.hashCode),
      entity: entity,
      option: thumbOption,
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
            _deleteCurrent(context, entity);
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
        final file = await entity.file;
        if (file == null || !file.existsSync()) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              item: MediaItem(path: file.path, isNetwork: false, type: 'video', id: entity.id, isFavourite: entity.isFavorite),
            ),
          ),
        );
      },
    );
  }

  int findChildIndexBuilder({
    required String id,
    required List<AssetEntity> assets,
  }) {
    return assets.indexWhere((AssetEntity e) => e.id == id);
  }

  Future<void> getFile(AssetEntity entity) async {
    final file = await entity.file;
    print(file);
  }

  Future<void> getFileWithMP4(AssetEntity entity) async {
    final file = await entity.loadFile(
      isOrigin: false,
      withSubtype: true,
      darwinFileType: PMDarwinAVFileType.mp4,
    );
    print(file);
  }

  Future<void> getDurationOfLivePhoto(AssetEntity entity) async {
    final duration = await entity.durationWithOptions(withSubtype: true);
    print(duration);
  }

  Future<void> routeToDetailPage(AssetEntity entity) async {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => DetailPage(entity: entity)),
    );
  }

  Future<void> onLoadMore(BuildContext context) async {
    if (!mounted) {
      return;
    }
    await readPathProvider(context).onLoadMore();
  }

  Future<void> _onRefresh(BuildContext context) async {
    if (!mounted) {
      return;
    }
    await readPathProvider(context).onRefresh();
  }

  Future<void> _shareItem(BuildContext context, AssetEntity entity) async {
    final file = await entity.file;
    await Share.shareXFiles([XFile(file!.path)], text: entity.title);
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
    readPathProvider(context).list[index] = newEntity;
    setState(() {});
  }

  Future<void> _deleteCurrent(BuildContext context, AssetEntity entity) async {
    if (Platform.isAndroid) {
      final AlertDialog dialog = AlertDialog(
        title: const Text('Delete the asset'),
        actions: <Widget>[
          TextButton(
            child: const Text('delete', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              readPathProvider(context).delete(entity);
              await _onRefresh(context);
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text('cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
      showDialog<void>(context: context, builder: (_) => dialog);
    } else {
      readPathProvider(context).delete(entity);
    }
  }

  Future<void> showOriginBytes(AssetEntity entity) async {
    final String title;
    if (entity.title?.isEmpty != false) {
      title = await entity.titleAsync;
    } else {
      title = entity.title!;
    }
    print('entity.title = $title');
    showDialog<void>(
      context: context,
      builder: (_) {
        return FutureBuilder<Uint8List?>(
          future: entity.originBytes,
          builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
            Widget w;
            if (snapshot.hasError) {
              return ErrorWidget(snapshot.error!);
            } else if (snapshot.hasData) {
              w = Image.memory(snapshot.data!);
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

  // Future<void> copyToAnotherPath(AssetEntity entity) {
  //   return Navigator.push(
  //     context,
  //     MaterialPageRoute<void>(
  //       builder: (_) => CopyToAnotherGalleryPage(assetEntity: entity),
  //     ),
  //   );
  // }
  //
  // Widget _buildRemoveInAlbumWidget(AssetEntity entity) {
  //   if (!(Platform.isIOS || Platform.isMacOS)) {
  //     return Container();
  //   }
  //
  //   return ElevatedButton(
  //     child: const Text('Remove in album'),
  //     onPressed: () => deleteAssetInAlbum(entity),
  //   );
  // }

  // void deleteAssetInAlbum(AssetEntity entity) {
  //   readPathProvider(context).removeInAlbum(entity);
  // }
  //
  // Widget _buildMoveAnotherPath(AssetEntity entity) {
  //   if (!Platform.isAndroid) {
  //     return Container();
  //   }
  //   return ElevatedButton(
  //     onPressed: () =>
  //         Navigator.push<void>(
  //           context,
  //           MaterialPageRoute<void>(
  //             builder: (_) => MoveToAnotherExample(entity: entity),
  //           ),
  //         ),
  //     child: const Text('Move to another gallery.'),
  //   );
  // }

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

  // Future<void> testProgressHandler(AssetEntity entity) async {
  //   final PMProgressHandler progressHandler = PMProgressHandler();
  //   progressHandler.stream.listen((PMProgressState event) {
  //     final double progress = event.progress;
  //     print('progress state onChange: ${event.state}, progress: $progress');
  //   });
  //   // final file = await entity.loadFile(progressHandler: progressHandler);
  //   // print('file = $file');
  //
  //   // final thumb = await entity.thumbDataWithSize(
  //   //   300,
  //   //   300,
  //   //   progressHandler: progressHandler,
  //   // );
  //
  //   // print('thumb length = ${thumb.length}');
  //
  //   final File? file = await entity.loadFile(
  //     progressHandler: progressHandler,
  //   );
  //   print('file = $file');
  // }
  //
  // Future<void> testThumbSize(AssetEntity entity, List<int> list) async {
  //   for (final int size in list) {
  //     // final data = await entity.thumbDataWithOption(ThumbOption.ios(
  //     //   width: size,
  //     //   height: size,
  //     //   resizeMode: ResizeMode.exact,
  //     // ));
  //     final Uint8List? data = await entity.thumbnailDataWithSize(
  //       ThumbnailSize.square(size),
  //     );
  //
  //     if (data == null) {
  //       return;
  //     }
  //     ui.decodeImageFromList(data, (ui.Image result) {
  //       print(
  //         'size: $size, '
  //             'length: ${data.length}, '
  //             'width*height: ${result.width}x${result.height}',
  //       );
  //     });
  //   }
  // }
  //
  // Future<void> showLivePhotoInfo(AssetEntity entity) async {
  //   final fileWithSubtype = await entity.originFile;
  //   final originFileWithSubtype = await entity.originFileWithSubtype;
  //
  //   print('fileWithSubtype = $fileWithSubtype');
  //   print('originFileWithSubtype = $originFileWithSubtype');
  // }
}

class AssetPathProvider extends ChangeNotifier {
  AssetPathProvider(this.path) {
    onRefresh();
  }

  static const int loadCount = 50;

  bool isInit = false;
  AssetPathEntity path;
  List<AssetEntity> list = <AssetEntity>[];
  int page = 0;

  int get assetCount => _assetCount!;
  int? _assetCount;

  int get showItemCount {
    if (_assetCount != null && list.length == _assetCount) {
      return assetCount;
    }
    return list.length + 1;
  }

  bool refreshing = false;

  Future<void> onRefresh() async {
    if (refreshing) {
      return;
    }
    refreshing = true;
    path = await path.obtainForNewProperties(maxDateTimeToNow: false);
    _assetCount = await path.assetCountAsync;
    final List<AssetEntity> list = await elapsedFuture(
      path.getAssetListPaged(page: 0, size: loadCount),
      prefix: 'Refresh assets list from path ${path.id}',
    );
    page = 0;
    this.list.clear();
    this.list.addAll(list);
    isInit = true;
    notifyListeners();
    printListLength('onRefresh');

    refreshing = false;
  }

  Future<void> onLoadMore() async {
    if (refreshing) {
      return;
    }
    if (showItemCount > assetCount) {
      print('already max');
      return;
    }
    final List<AssetEntity> list = await elapsedFuture(
      path.getAssetListPaged(page: page + 1, size: loadCount),
      prefix: 'Load more assets list from path ${path.id}',
    );
    if (list.isEmpty) {
      print('load error');
      return;
    }
    page = page + 1;
    this.list.addAll(list);
    notifyListeners();
    printListLength('loadmore');
  }

  final PhotoProvider provider = PhotoProvider();

  Future<void> delete(AssetEntity entity) async {
    final List<String> result = await PhotoManager.editor.deleteWithIds(
      <String>[entity.id],
    );
    if (result.isNotEmpty) {
      final int rangeEnd = this.list.length;
      await provider.refreshAllGalleryProperties();
      final List<AssetEntity> list = await elapsedFuture(
        path.getAssetListRange(start: 0, end: rangeEnd),
        prefix: 'Refresh assets list from path ${path.id} after delete',
      );
      this.list.clear();
      this.list.addAll(list);
      printListLength('deleted');
    }
  }

  Future<void> deleteSelectedAssets(List<AssetEntity> entity) async {
    final List<String> ids = entity.map((AssetEntity e) => e.id).toList();
    await PhotoManager.editor.deleteWithIds(ids);
    path = await path.obtainForNewProperties();
    notifyListeners();
  }

  Future<void> removeInAlbum(AssetEntity entity) async {
    if (await PhotoManager.editor.darwin.removeInAlbum(entity, path)) {
      final int rangeEnd = this.list.length;
      await provider.refreshAllGalleryProperties();
      final List<AssetEntity> list = await elapsedFuture(
        path.getAssetListRange(start: 0, end: rangeEnd),
        prefix: 'Refresh assets list from path ${path.id} when remove in album',
      );
      this.list.clear();
      this.list.addAll(list);
      printListLength('removeInAlbum');
    }
  }

  void printListLength(String tag) {
    print('$tag length : ${list.length}');
  }
}

Future<T> elapsedFuture<T>(Future<T> future, {String? prefix}) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  final T result = await future;
  stopwatch.stop();
  print('${prefix != null ? '$prefix: ' : ''}${stopwatch.elapsed}');
  return result;
}

final Center loadWidget = Center(
  child: SizedBox.fromSize(
    size: const Size.square(30),
    child: (Platform.isIOS || Platform.isMacOS)
        ? const CupertinoActivityIndicator()
        : const CircularProgressIndicator(),
  ),
);



Future<void> showResultDialog(
  BuildContext context,
  String title,
  Future<String> result,
) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder<String>(
        future: result,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          Widget w;
          if (snapshot.hasError) {
            w = Text(snapshot.error!.toString());
          } else if (snapshot.hasData) {
            w = Text(snapshot.data!);
          } else {
            w = const Center(child: CircularProgressIndicator());
          }
          return AlertDialog(
            title: Text(title),
            content: w,
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );
    },
  );
}

class VideoWidget extends StatefulWidget {
  const VideoWidget({
    super.key,
    required this.entity,
    this.usingMediaUri = true,
  });

  final AssetEntity entity;
  final bool usingMediaUri;

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  final Stopwatch _stopwatch = Stopwatch();
  VideoPlayerController? _controller;

  bool get isAudio => widget.entity.type == AssetType.audio;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    if (widget.usingMediaUri) {
      _initVideoWithMediaUri();
    } else {
      _initVideoWithFile();
    }
  }

  @override
  void didUpdateWidget(VideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entity == oldWidget.entity &&
        widget.usingMediaUri == oldWidget.usingMediaUri) {
      return;
    }
    _controller?.dispose();
    _controller = null;
    _stopwatch.start();
    if (widget.usingMediaUri) {
      _initVideoWithMediaUri();
    } else {
      _initVideoWithFile();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initVideoWithFile() {
    widget.entity.file.then((File? file) {
      _stopwatch.stop();
      print('Elapsed time for file: ${_stopwatch.elapsed}');
      if (!mounted || file == null) {
        return;
      }
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) => setState(() {}));
    });
  }

  void _initVideoWithMediaUri() {
    widget.entity.getMediaUrl().then((String? url) {
      _stopwatch.stop();
      print('Elapsed time for getMediaUrl: ${_stopwatch.elapsed}');
      if (!mounted || url == null) {
        return;
      }
      _controller = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) => setState(() {}));
    });
  }

  Widget buildVideoPlayer() {
    final VideoPlayerController controller = _controller!;
    return Stack(
      children: <Widget>[
        if (isAudio)
          Container(
            alignment: Alignment.center,
            color: Colors.white,
            child: const Icon(Icons.audiotrack, size: 200, color: Colors.grey),
          )
        else
          VideoPlayer(controller),
        if (!controller.value.isPlaying)
          IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller?.value.isInitialized != true) {
      return const SizedBox.shrink();
    }

    final VideoPlayerController c = _controller!;
    return AspectRatio(
      aspectRatio: isAudio ? 1 : c.value.aspectRatio,
      child: GestureDetector(
        child: buildVideoPlayer(),
        onTap: () {
          c.value.isPlaying ? c.pause() : c.play();
          setState(() {});
        },
      ),
    );
  }
}

class LivePhotosWidget extends StatefulWidget {
  const LivePhotosWidget({
    super.key,
    required this.entity,
    required this.useOrigin,
  });

  final AssetEntity entity;
  final bool useOrigin;

  @override
  State<LivePhotosWidget> createState() => _LivePhotosWidgetState();
}

class _LivePhotosWidgetState extends State<LivePhotosWidget> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    if (!await widget.entity.isLocallyAvailable(withSubtype: true)) {
      if (widget.useOrigin) {
        await widget.entity.originFileWithSubtype;
      } else {
        await widget.entity.fileWithSubtype;
      }
    }
    final String? url = await widget.entity.getMediaUrl();
    if (!mounted || url == null) {
      return;
    }
    _controller =
        VideoPlayerController.networkUrl(
            Uri.parse(url),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          )
          ..initialize()
          ..addListener(() {
            if (mounted) {
              setState(() {});
            }
          });
    setState(() {});
  }

  void _play() {
    _controller?.play();
  }

  Future<void> _stop() async {
    await _controller?.pause();
    await _controller?.seekTo(Duration.zero);
  }

  Widget _buildImage(BuildContext context) {
    return AssetEntityImage(
      widget.entity,
      isOriginal: widget.useOrigin == true,
      fit: BoxFit.contain,
      loadingBuilder: (_, Widget child, ImageChunkEvent? progress) {
        if (progress != null) {
          final double? value;
          if (progress.expectedTotalBytes != null) {
            value =
                progress.cumulativeBytesLoaded / progress.expectedTotalBytes!;
          } else {
            value = null;
          }
          return Center(
            child: SizedBox.fromSize(
              size: const Size.square(30),
              child: CircularProgressIndicator(value: value),
            ),
          );
        }
        return child;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _play(),
      onLongPressEnd: (_) => _stop(),
      child: AspectRatio(
        aspectRatio: widget.entity.size.aspectRatio,
        child: Stack(
          children: <Widget>[
            if (_controller?.value.isInitialized == true)
              Positioned.fill(child: VideoPlayer(_controller!)),
            if (_controller != null)
              Positioned.fill(
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller!,
                  builder: (_, VideoPlayerValue value, Widget? child) {
                    return AnimatedOpacity(
                      opacity: value.isPlaying ? 0 : 1,
                      duration: kThemeAnimationDuration,
                      child: child,
                    );
                  },
                  child: _buildImage(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CopyToAnotherGalleryPage extends StatefulWidget {
  const CopyToAnotherGalleryPage({super.key, required this.assetEntity});

  final AssetEntity assetEntity;

  @override
  State<CopyToAnotherGalleryPage> createState() =>
      _CopyToAnotherGalleryPageState();
}

class _CopyToAnotherGalleryPageState extends State<CopyToAnotherGalleryPage> {
  AssetPathEntity? targetGallery;

  @override
  Widget build(BuildContext context) {
    final PhotoProvider provider = Provider.of<PhotoProvider>(
      context,
      listen: false,
    );
    final List<AssetPathEntity> list = provider.list;
    return Scaffold(
      appBar: AppBar(title: const Text('move to another')),
      body: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: AssetEntityImage(
              widget.assetEntity,
              thumbnailSize: const ThumbnailSize.square(500),
              loadingBuilder: (_, Widget child, ImageChunkEvent? progress) {
                if (progress == null) {
                  return child;
                }
                final double? value;
                if (progress.expectedTotalBytes != null) {
                  value =
                      progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!;
                } else {
                  value = null;
                }
                return Center(
                  child: SizedBox.fromSize(
                    size: const Size.square(40),
                    child: CircularProgressIndicator(value: value),
                  ),
                );
              },
            ),
          ),
          DropdownButton<AssetPathEntity>(
            onChanged: (AssetPathEntity? value) {
              targetGallery = value;
              setState(() {});
            },
            value: targetGallery,
            hint: const Text('Select target gallery'),
            items: list.map<DropdownMenuItem<AssetPathEntity>>((
              AssetPathEntity item,
            ) {
              return _buildItem(item);
            }).toList(),
          ),
          _buildCopyButton(),
        ],
      ),
    );
  }

  DropdownMenuItem<AssetPathEntity> _buildItem(AssetPathEntity item) {
    return DropdownMenuItem<AssetPathEntity>(
      value: item,
      child: Text(item.name),
    );
  }

  Future<void> _copy() async {
    if (targetGallery == null) {
      return;
    }
    final AssetEntity result = await PhotoManager.editor.copyAssetToPath(
      asset: widget.assetEntity,
      pathEntity: targetGallery!,
    );

    print('copy result = $result');
  }

  Widget _buildCopyButton() {
    return ElevatedButton(
      onPressed: _copy,
      child: Text(
        targetGallery == null
            ? 'Please select gallery'
            : 'copy to ${targetGallery!.name}',
      ),
    );
  }
}

class PhotoProvider extends ChangeNotifier {
  bool showVerboseLog = false;

  List<AssetPathEntity> list = <AssetPathEntity>[];

  RequestType type = RequestType.common;

  bool hasAll = true;

  bool onlyAll = false;

  bool _notifying = false;

  bool _needTitle = false;

  bool get needTitle => _needTitle;

  set needTitle(bool? needTitle) {
    if (needTitle == null) {
      return;
    }
    _needTitle = needTitle;
    notifyListeners();
  }

  bool _containsPathModified = false;

  bool get containsPathModified => _containsPathModified;

  set containsPathModified(bool containsPathModified) {
    _containsPathModified = containsPathModified;
    notifyListeners();
  }

  bool _containsLivePhotos = true;

  bool get containsLivePhotos => _containsLivePhotos;

  set containsLivePhotos(bool value) {
    _containsLivePhotos = value;
    notifyListeners();
  }

  bool _onlyLivePhotos = false;

  bool get onlyLivePhotos => _onlyLivePhotos;

  set onlyLivePhotos(bool value) {
    _onlyLivePhotos = value;
    notifyListeners();
  }

  bool _includeHiddenAssets = false;

  bool get includeHiddenAssets => _includeHiddenAssets;

  set includeHiddenAssets(bool value) {
    _includeHiddenAssets = value;
    notifyListeners();
  }

  DateTime _startDt = DateTime(2005); // Default Before 8 years

  DateTime get startDt => _startDt;

  set startDt(DateTime startDt) {
    _startDt = startDt;
    notifyListeners();
  }

  DateTime _endDt = DateTime.now();

  DateTime get endDt => _endDt;

  set endDt(DateTime endDt) {
    _endDt = endDt;
    notifyListeners();
  }

  bool _asc = false;

  bool get asc => _asc;

  set asc(bool? asc) {
    if (asc == null) {
      return;
    }
    _asc = asc;
    notifyListeners();
  }

  ThumbnailFormat _thumbFormat = ThumbnailFormat.jpeg;

  ThumbnailFormat get thumbFormat => _thumbFormat;

  set thumbFormat(ThumbnailFormat thumbFormat) {
    _thumbFormat = thumbFormat;
    notifyListeners();
  }

  bool get notifying => _notifying;

  String minWidth = '0';
  String maxWidth = '10000';
  String minHeight = '0';
  String maxHeight = '10000';
  bool _ignoreSize = true;

  bool get ignoreSize => _ignoreSize;

  set ignoreSize(bool? ignoreSize) {
    if (ignoreSize == null) {
      return;
    }
    _ignoreSize = ignoreSize;
    notifyListeners();
  }

  Duration _minDuration = Duration.zero;

  Duration get minDuration => _minDuration;

  set minDuration(Duration minDuration) {
    _minDuration = minDuration;
    notifyListeners();
  }

  Duration _maxDuration = const Duration(hours: 1);

  Duration get maxDuration => _maxDuration;

  set maxDuration(Duration maxDuration) {
    _maxDuration = maxDuration;
    notifyListeners();
  }

  set notifying(bool? notifying) {
    if (notifying == null) {
      return;
    }
    _notifying = notifying;
    notifyListeners();
  }

  void changeType(RequestType type) {
    this.type = type;
    notifyListeners();
  }

  void changeHasAll(bool? value) {
    if (value == null) {
      return;
    }
    hasAll = value;
    notifyListeners();
  }

  void changeOnlyAll(bool? value) {
    if (value == null) {
      return;
    }
    onlyAll = value;
    notifyListeners();
  }

  void changeContainsPathModified(bool? value) {
    if (value == null) {
      return;
    }
    containsPathModified = value;
  }

  void changeIncludeHiddenAssets(bool? value) {
    if (value == null) {
      return;
    }
    includeHiddenAssets = value;
  }

  void reset() {
    list.clear();
  }

  Future<void> refreshGalleryList() async {
    final FilterOptionGroup option = makeOption();

    reset();
    final List<AssetPathEntity> galleryList = await elapsedFuture(
      PhotoManager.getAssetPathList(
        type: type,
        hasAll: hasAll,
        onlyAll: onlyAll,
        filterOption: option,
        pathFilterOption: pathFilterOption,
      ),
      prefix: 'Obtain path list duration',
    );
    list.clear();
    list.addAll(galleryList);
  }

  FilterOptionGroup makeOption() {
    final FilterOption filterOption = FilterOption(
      sizeConstraint: SizeConstraint(
        minWidth: int.tryParse(minWidth) ?? 0,
        maxWidth: int.tryParse(maxWidth) ?? 100000,
        minHeight: int.tryParse(minHeight) ?? 0,
        maxHeight: int.tryParse(maxHeight) ?? 100000,
        ignoreSize: _ignoreSize,
      ),
      durationConstraint: DurationConstraint(
        min: minDuration,
        max: maxDuration,
      ),
      needTitle: needTitle,
    );

    final DateTimeCond createDtCond = DateTimeCond(min: startDt, max: endDt);

    final FilterOptionGroup optionGroup = FilterOptionGroup(
      imageOption: filterOption,
      videoOption: filterOption,
      audioOption: filterOption,
      containsPathModified: containsPathModified,
      // ignore: deprecated_member_use
      containsLivePhotos: containsLivePhotos,
      onlyLivePhotos: onlyLivePhotos,
      createTimeCond: createDtCond,
      includeHiddenAssets: includeHiddenAssets, // iOS 平台特有
    );

    return optionGroup;
  }

  Future<void> refreshAllGalleryProperties() async {
    await Future.wait(
      List<Future<void>>.generate(list.length, (int i) async {
        final AssetPathEntity gallery = list[i];
        final AssetPathEntity newGallery = await elapsedFuture(
          AssetPathEntity.obtainPathFromProperties(
            id: gallery.id,
            albumType: gallery.albumType,
            type: gallery.type,
            optionGroup: gallery.filterOption,
          ),
          prefix: 'Refresh path entity ${gallery.id}',
        );
        list[i] = newGallery;
      }),
    );
    notifyListeners();
  }

  void changeThumbFormat() {
    if (thumbFormat == ThumbnailFormat.jpeg) {
      thumbFormat = ThumbnailFormat.png;
    } else {
      thumbFormat = ThumbnailFormat.jpeg;
    }
  }

  /// For path filter option
  PMPathFilter get pathFilterOption => _pathFilterOption;
  PMPathFilter _pathFilterOption = const PMPathFilter();

  List<PMDarwinAssetCollectionType> _pathTypeList =
      PMDarwinAssetCollectionType.values;

  List<PMDarwinAssetCollectionType> get pathTypeList => _pathTypeList;

  set pathTypeList(List<PMDarwinAssetCollectionType> value) {
    _pathTypeList = value;
    _onChangePathFilter();
  }

  late List<PMDarwinAssetCollectionSubtype> _pathSubTypeList =
      _pathFilterOption.darwin.subType;

  List<PMDarwinAssetCollectionSubtype> get pathSubTypeList => _pathSubTypeList;

  set pathSubTypeList(List<PMDarwinAssetCollectionSubtype> value) {
    _pathSubTypeList = value;
    _onChangePathFilter();
  }

  void _onChangePathFilter() {
    final darwinPathFilterOption = PMDarwinPathFilter(
      type: pathTypeList,
      subType: pathSubTypeList,
    );
    _pathFilterOption = PMPathFilter(darwin: darwinPathFilterOption);
    notifyListeners();
  }

  void changeVerboseLog(bool v) {
    showVerboseLog = v;
    notifyListeners();
  }
}

class MoveToAnotherExample extends StatefulWidget {
  const MoveToAnotherExample({super.key, required this.entity});

  final AssetEntity entity;

  @override
  State<MoveToAnotherExample> createState() => _MoveToAnotherExampleState();
}

class _MoveToAnotherExampleState extends State<MoveToAnotherExample> {
  List<AssetPathEntity> targetPathList = <AssetPathEntity>[];
  AssetPathEntity? target;

  @override
  void initState() {
    super.initState();
    PhotoManager.getAssetPathList(hasAll: false).then((
      List<AssetPathEntity> value,
    ) {
      targetPathList = value;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Move to another gallery')),
      body: Column(
        children: <Widget>[
          Center(
            child: Container(
              color: Colors.grey,
              width: 300,
              height: 300,
              child: _buildPreview(),
            ),
          ),
          buildTarget(),
          buildMoveButton(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return AssetEntityImage(
      widget.entity,
      thumbnailSize: const ThumbnailSize.square(500),
      loadingBuilder: (_, Widget child, ImageChunkEvent? progress) {
        if (progress == null) {
          return child;
        }
        final double? value;
        if (progress.expectedTotalBytes != null) {
          value = progress.cumulativeBytesLoaded / progress.expectedTotalBytes!;
        } else {
          value = null;
        }
        return Center(
          child: SizedBox.fromSize(
            size: const Size.square(40),
            child: CircularProgressIndicator(value: value),
          ),
        );
      },
    );
  }

  Widget buildTarget() {
    return DropdownButton<AssetPathEntity>(
      items: targetPathList.map((AssetPathEntity v) => _buildItem(v)).toList(),
      value: target,
      onChanged: (AssetPathEntity? value) {
        target = value;
        setState(() {});
      },
    );
  }

  DropdownMenuItem<AssetPathEntity> _buildItem(AssetPathEntity v) {
    return DropdownMenuItem<AssetPathEntity>(value: v, child: Text(v.name));
  }

  Widget buildMoveButton() {
    if (target == null) {
      return const SizedBox.shrink();
    }
    return ElevatedButton(
      onPressed: () {
        PhotoManager.editor.android.moveAssetToAnother(
          entity: widget.entity,
          target: target!,
        );
      },
      child: Text("Move to ' ${target!.name} '"),
    );
  }
}
