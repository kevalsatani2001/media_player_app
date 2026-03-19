import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_player/screens/setting_screen.dart';
import 'package:media_player/widgets/text_widget.dart';
import '../models/media_item.dart';
import '../models/playlist_model.dart';
import '../utils/app_colors.dart';
import '../widgets/app_button.dart';
import 'app_toast.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_player/screens/setting_screen.dart';
import 'package:media_player/widgets/text_widget.dart';
import '../models/media_item.dart';
import '../models/playlist_model.dart';
import '../utils/app_colors.dart';
import '../widgets/app_button.dart';
import 'app_toast.dart';



import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_player/screens/setting_screen.dart';
import 'package:media_player/widgets/text_widget.dart';
import '../models/media_item.dart';
import '../models/playlist_model.dart';
import '../utils/app_colors.dart';
import '../widgets/app_button.dart';
import 'app_toast.dart';

void addToPlaylist(MediaItem currentItem, BuildContext context) {
  final colors = Theme.of(context).extension<AppThemeColors>()!;
  final playlistBox = Hive.box('playlists');

  // Ã¢Å“â€¦ Ã Â«Â§. Ã Âªâ€¢Ã ÂªÂ°Ã Âªâ€šÃ ÂªÅ¸ Ã Âªâ€ Ã ÂªË†Ã ÂªÅ¸Ã ÂªÂ®Ã ÂªÂ¨Ã ÂªÂ¾ Ã ÂªÅ¸Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂª Ã ÂªÂ®Ã Â«ÂÃ ÂªÅ“Ã ÂªÂ¬ Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÂ«Ã ÂªÂ¿Ã ÂªÂ²Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ° Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
  // Ã ÂªÂ§Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â€¹ Ã Âªâ€¢Ã Â«â€¡ currentItem.type Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š 'audio' Ã Âªâ€¦Ã ÂªÂ¥Ã ÂªÂµÃ ÂªÂ¾ 'video' Ã Âªâ€ Ã ÂªÂµÃ Â«â€¡ Ã Âªâ€ºÃ Â«â€¡.
  final filteredPlaylists = playlistBox.values.where((playlist) {
    return (playlist as PlaylistModel).type == currentItem.type;
  }).toList();

  String newPlaylistName = '';
  dynamic selectedPlaylistIndex;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: colors.dropdownBg,
            title: AppText(
              "addToPlaylist",
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colors.appBarTitleColor,
              align: TextAlign.center,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ã¢Å“â€¦ Ã Â«Â¨. Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÂ¤Ã Â«ÂÃ ÂªÂ° Ã ÂªÂ«Ã ÂªÂ¿Ã ÂªÂ²Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ° Ã ÂªÂ¥Ã ÂªÂ¯Ã Â«â€¡Ã ÂªÂ²Ã Â«â‚¬ Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÅ“ Ã ÂªÂ¡Ã Â«ÂÃ ÂªÂ°Ã Â«â€¹Ã ÂªÂªÃ ÂªÂ¡Ã ÂªÂ¾Ã Âªâ€°Ã ÂªÂ¨Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã ÂªÂ¬Ã ÂªÂ¤Ã ÂªÂ¾Ã ÂªÂµÃ Â«â€¹
                  if (filteredPlaylists.isNotEmpty) ...[
                    AppText("selectExistingPlaylist", fontSize: 14, color: colors.dialogueSubTitle),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colors.textFieldFill,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      dropdownColor: colors.background,
                      hint: AppText(
                        "choosePlaylist",
                        color: colors.dialogueSubTitle,
                      ),
                      value: selectedPlaylistIndex,
                      items: List.generate(filteredPlaylists.length, (index) {
                        final playlist = filteredPlaylists[index] as PlaylistModel;
                        return DropdownMenuItem(
                          value: index,
                          child: Text(playlist.name, style: TextStyle(color: colors.appBarTitleColor)),
                        );
                      }),
                      onChanged: (value) => setState(() => selectedPlaylistIndex = value),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                  ],

                  AppText("orCreateNew", fontSize: 14, color: colors.dialogueSubTitle),
                  const SizedBox(height: 8),
                  TextField(
                    style: TextStyle(color: colors.appBarTitleColor),
                    decoration: InputDecoration(
                      hintText: "enterName",
                      hintStyle: TextStyle(
                        color: colors.dialogueSubTitle.withOpacity(0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) => newPlaylistName = v,
                  ),
                ],
              ),
            ),

            actions: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        title: "cancel",
                        backgroundColor: colors.whiteColor,
                        textColor: colors.dialogueSubTitle,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AppButton(
                        title: "add",
                        onTap: () {
                          if (selectedPlaylistIndex != null) {
                            // Ã¢Å“â€¦ Ã Â«Â©. Ã ÂªÂ¸Ã ÂªÂ¿Ã ÂªÂ²Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÅ¸ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¡Ã ÂªÂ²Ã Â«â‚¬ Ã ÂªÂ«Ã ÂªÂ¿Ã ÂªÂ²Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ° Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€š Ã ÂªÂÃ ÂªÂ¡ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
                            final playlist = filteredPlaylists[selectedPlaylistIndex] as PlaylistModel;

                            if (!playlist.items.any((e) => e.path == currentItem.path)) {
                              playlist.items.add(currentItem);
                              playlist.save(); // HiveObject Ã ÂªÂµÃ ÂªÂ¾Ã ÂªÂªÃ ÂªÂ°Ã ÂªÂ¤Ã ÂªÂ¾ Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂµ Ã ÂªÂ¤Ã Â«â€¹ save() Ã ÂªÅ¡Ã ÂªÂ¾Ã ÂªÂ²Ã Â«â€¡

                              Navigator.pop(context);
                              AppToast.show(context, "${context.tr("addedTo")} ${playlist.name}", type: ToastType.success);
                            } else {
                              AppToast.show(context, "${context.tr("alreadyExistIn")} ${playlist.name}", type: ToastType.info);
                            }
                          }
                          else if (newPlaylistName.trim().isNotEmpty) {
                            final name = newPlaylistName.trim();

                            // Ã¢Å“â€¦ Ã Â«Âª. Ã ÂªÂ¨Ã ÂªÂµÃ Â«â‚¬ Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÂ¬Ã ÂªÂ¨Ã ÂªÂ¾Ã ÂªÂµÃ ÂªÂ¤Ã Â«â‚¬ Ã ÂªÂµÃ Âªâ€“Ã ÂªÂ¤Ã Â«â€¡ Ã ÂªÅ¸Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂª Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸Ã Â«â€¹Ã ÂªÂ° Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
                            final newPlaylist = PlaylistModel(
                              name: name,
                              items: [currentItem],
                              type: currentItem.type, // 'audio' Ã Âªâ€¦Ã ÂªÂ¥Ã ÂªÂµÃ ÂªÂ¾ 'video'
                            );
                            playlistBox.add(newPlaylist);

                            Navigator.pop(context);
                            AppToast.show(context, context.tr("newPlaylistCreated"), type: ToastType.success);
                          }
                          // ... (error handling)
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  );
}


void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}








// void addToPlaylist(MediaItem currentItem, BuildContext context) {
//   final colors = Theme.of(context).extension<AppThemeColors>()!;
//   final playlistBox = Hive.box('playlists');
//
//   String newPlaylistName = '';
//   dynamic selectedPlaylistIndex; // Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ…Â¸ Ãƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â² Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ…Â¸ Ãƒ Ã‚ÂªÃ¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¸ Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ¢â‚¬â€œÃƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚ÂªÃ‚Â¾ Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚Â«Ã¢â‚¬Â¡
//
//   showDialog(
//     context: context,
//     barrierDismissible: true,
//     builder: (context) {
//       // StatefulBuilder Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Å¡Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ¢â‚¬ÂºÃƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ¢â‚¬Â°Ãƒ Ã‚ÂªÃ‚Â¨ Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¶Ãƒ Ã‚ÂªÃ‚Â¨ Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚ÂªÃ¢â‚¬â€œÃƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚Â«Ã¢â‚¬Â¡ UI Ãƒ Ã‚ÂªÃ¢â‚¬Â¦Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ…Â¸ Ãƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â¯
//       return StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             backgroundColor: colors.dropdownBg,
//             title: AppText(
//               "addToPlaylist",
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: colors.appBarTitleColor,
//               align: TextAlign.center,
//             ),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // --- Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ…Â¸ Ãƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ¢â‚¬Â°Ãƒ Ã‚ÂªÃ‚Â¨ ---
//                   if (playlistBox.isNotEmpty) ...[
//                     AppText(
//                       "selectExistingPlaylist",
//                       fontSize: 14,
//                       color: colors.dialogueSubTitle,
//                     ),
//                     const SizedBox(height: 8),
//                     DropdownButtonFormField<int>(
//                       isExpanded: true,
//                       decoration: InputDecoration(
//                         filled: true,
//                         fillColor: colors.textFieldFill,
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       dropdownColor: colors.background,
//                       hint: AppText(
//                         "choosePlaylist",
//                         color: colors.dialogueSubTitle,
//                       ),
//                       value: selectedPlaylistIndex,
//                       items: List.generate(playlistBox.length, (index) {
//                         final playlist = playlistBox.getAt(index)!;
//                         return DropdownMenuItem(
//                           alignment: AlignmentDirectional.centerStart,
//                           // Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â‚¬Å¡Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚Â¶Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚ÂªÃ‚Â¶Ãƒ Ã‚Â«Ã¢â‚¬Â¡
//                           // Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ¢â‚¬ Ãƒ Ã‚ÂªÃ¢â‚¬â€œÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ¢â‚¬â€ Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚Â¨ Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¸ Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‹â€ Ãƒ Ã‚ÂªÃ…Â¸ Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚ÂªÃ‚Â£ Ãƒ Ã‚ÂªÃ¢â‚¬ Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚Â¶Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã¢â‚¬Â¹
//                           value: index,
//                           child: Text(
//                             playlist.name,
//                             style: TextStyle(color: colors.appBarTitleColor),
//                           ),
//                         );
//                       }),
//                       onChanged: (value) =>
//                           setState(() => selectedPlaylistIndex = value),
//                     ),
//                     const SizedBox(height: 20),
//                     const Divider(),
//                     const SizedBox(height: 10),
//                   ],
//
//                   // --- Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ…Â¸ Ãƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚Â«Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¡ ---
//                   AppText(
//                     "orCreateNew",
//                     fontSize: 14,
//                     color: colors.dialogueSubTitle,
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     style: TextStyle(color: colors.appBarTitleColor),
//                     decoration: InputDecoration(
//                       hintText: "enterName",
//                       hintStyle: TextStyle(
//                         color: colors.dialogueSubTitle.withOpacity(0.5),
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onChanged: (v) => newPlaylistName = v,
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               Padding(
//                 padding: const EdgeInsets.all(15),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: AppButton(
//                         title: "cancel",
//                         backgroundColor: colors.whiteColor,
//                         textColor: colors.dialogueSubTitle,
//                         onTap: () => Navigator.pop(context),
//                       ),
//                     ),
//                     const SizedBox(width: 14),
//                     Expanded(
//                       child: AppButton(
//                         title: "add",
//                         backgroundColor: colors.primary,
//                         textColor: Colors.white,
//
//                         onTap: () {
//                           // Ãƒ Ã‚Â«Ã‚Â§. Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ¢â‚¬Â°Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ¢â‚¬Å¡Ãƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ…Â¸ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¯
//                           if (selectedPlaylistIndex != null) {
//                             final playlist = playlistBox.getAt(
//                               selectedPlaylistIndex,
//                             )!;
//
//                             if (!playlist.items.any(
//                                   (e) => e.path == currentItem.path,
//                             )) {
//                               playlist.items.add(currentItem);
//                               playlistBox.putAt(
//                                 selectedPlaylistIndex,
//                                 playlist,
//                               );
//
//                               Navigator.pop(context);
//                               AppToast.show(
//                                 context,
//                                 "${context.tr("addedTo")} ${playlist.name}",
//                                 type: ToastType.success,
//                               );
//                             } else {
//                               AppToast.show(
//                                 context,
//                                 "${context.tr("alreadyExistIn")} ${playlist.name}",
//                                 type: ToastType.info,
//                               );
//                             }
//                           }
//                           // Ãƒ Ã‚Â«Ã‚Â¨. Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â® Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ¢â‚¬â€œÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¯
//                           else if (newPlaylistName.trim().isNotEmpty) {
//                             final name = newPlaylistName.trim();
//
//                             // ÃƒÂ°Ã…Â¸Ã¢â‚¬ÂÃ‚Â Ãƒ Ã‚ÂªÃ¢â‚¬Â¦Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â€šÂ¬Ãƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ…Â¡Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ¢â‚¬  Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ…Â¸ Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ¢â‚¬ÂºÃƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â€šÂ¬Ãƒ Ã‚ÂªÃ¢â‚¬Å¡
//                             bool exists = playlistBox.values.any(
//                                   (element) =>
//                               element.name.toLowerCase() ==
//                                   name.toLowerCase(),
//                             );
//
//                             if (exists) {
//                               // ÃƒÂ¢Ã…Â¡ ÃƒÂ¯Ã‚Â¸Ã‚Â Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â® Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¯ Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ‚ÂÃƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚ÂªÃ‚Â° Ãƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã¢â‚¬Â¹
//                               AppToast.show(
//                                 context,
//                                 "${context.tr("playlist")} '$name' ${context.tr("alreadyExists")}",
//                                 type: ToastType.error,
//                               );
//                             } else {
//                               // ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¯ Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ…â€œ Ãƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã¢â‚¬Â¹
//                               final newPlaylist = PlaylistModel(
//                                 name: name,
//                                 items: [currentItem],
//                               );
//                               playlistBox.add(newPlaylist);
//
//                               Navigator.pop(context);
//                               AppToast.show(
//                                 context,
//                                 context.tr("newPlaylistCreated"),
//                                 type: ToastType.success,
//                               );
//                             }
//                           } else {
//                             AppToast.show(
//                               context,
//                               context.tr("pleaseSelectEnterPlaylistName"),
//                               type: ToastType.error,
//                             );
//                           }
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       );
//     },
//   );
// }
//
// // Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â° Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚ÂªÃ‚Â° Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¥Ãƒ Ã‚ÂªÃ‚Â¡
// void _showSnackBar(BuildContext context, String message) {
//   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
// }