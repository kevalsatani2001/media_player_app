import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:media_player/core/constants.dart';
import 'package:media_player/widgets/image_item_widget.dart';
import 'package:media_player/widgets/image_widget.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../models/media_item.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  List<MediaItem> _results = [];

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final lowerQuery = query.toLowerCase();

    // Hive boxes માંથી ડેટા મેળવો
    final videoBox = Hive.box('videos');
    final audioBox = Hive.box('audios');

    // વિડિયો અને ઓડિયો બંનેના ડેટાને એક લિસ્ટમાં ભેગો કરો
    final allItems = [
      ...videoBox.values.map(
            (e) => MediaItem.fromMap(Map<String, dynamic>.from(e)),
      ),
      ...audioBox.values.map(
            (e) => MediaItem.fromMap(Map<String, dynamic>.from(e)),
      ),
    ];

    // હવે પાથ (File Name) દ્વારા ફિલ્ટર કરો
    final filtered = allItems.where((item) {
      final fileName = item.path.split('/').last.toLowerCase();
      return fileName.contains(lowerQuery);
    }).toList();

    setState(() {
      _results = filtered;
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7.5),
            child: TextFormField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                // suffixIconConstraints: BoxConstraints(minWidth: 32,maxWidth: 32,minHeight:
                // 32,maxHeight: 32),
                fillColor: colors.textFieldFill,
                filled: true,
                hintText: 'Search anything....',
                hintStyle: TextStyle(
                  fontFamily: "inter",
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: colors.textFieldBorder,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: _query.isEmpty
                        ? null
                        : () {
                      setState(() {
                        _controller.clear();
                        _query = "";
                      });
                    },
                    child: AppImage(
                      src: _query.isEmpty
                          ? AppSvg.searchIconBorder
                          : AppSvg.closeIcon,
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.textFieldFill),
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.textFieldFill),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) {
                _query = v;
                _performSearch(v);
              },
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? const Center(
              child: AppText(
                "Search videos and audios",
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            )
                : _results.isEmpty
                ? const Center(
              child: AppText(
                "No Data found",
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            )
                :


            ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final item = _results[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 7.5,
                    horizontal: 15,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(item: item),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      // height: 100,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          top: 10,
                          bottom: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                                width: 80,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.antiAlias,
                                // 🔑 important
                                child: assetAntityImage(AssetEntity(
                                  relativePath: item.path,
                                  id: item.id!,
                                  typeInt: item.type == 'audio' ? 3 : 2,
                                  width: 80,
                                  height: 80,
                                ),)
                            ),
                            SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    item.path.split('/').last,
                                    maxLines: 1,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  SizedBox(height: 7),
                                  AppText(
                                    item.path,
                                    maxLines: 1,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: colors.textFieldBorder,
                                  ),
                                  SizedBox(height: 7),
                                  Row(
                                    children: [
                                      AppText(
                                        formatDuration(
                                          AssetEntity(
                                            relativePath: item.path,
                                            id: item.id!,
                                            typeInt: item.type == 'audio'
                                                ? 3
                                                : 2,
                                            width: 80,
                                            height: 80,
                                          ).duration,
                                        ),
                                        maxLines: 2,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: colors.appBarTitleColor,
                                      ),
                                      SizedBox(width: 10),
                                      FutureBuilder<File?>(
                                        future: AssetEntity(
                                          relativePath: item.path,
                                          id: item.id!,
                                          typeInt: item.type == 'audio'
                                              ? 3
                                              : 2,
                                          width: 80,
                                          height: 80,
                                        ).file,
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData ||
                                              snapshot.data == null) {
                                            return const SizedBox(
                                              height: 14,
                                            );
                                          }

                                          final file = snapshot.data!;

                                          if (!file.existsSync()) {
                                            return const Text(
                                              'Unavailable',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 11,
                                              ),
                                            );
                                          }

                                          final bytes = file.lengthSync();

                                          return AppText(
                                            _formatSize(bytes),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: colors.appBarTitleColor,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 13),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}