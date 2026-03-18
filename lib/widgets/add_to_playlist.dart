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

  // âœ… à«§. àª•àª°àª‚àªŸ àª†àªˆàªŸàª®àª¨àª¾ àªŸàª¾àªˆàªª àª®à«àªœàª¬ àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àª«àª¿àª²à«àªŸàª° àª•àª°à«‹
  // àª§àª¾àª°à«‹ àª•à«‡ currentItem.type àª®àª¾àª‚ 'audio' àª…àª¥àªµàª¾ 'video' àª†àªµà«‡ àª›à«‡.
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
                  // âœ… à«¨. àª®àª¾àª¤à«àª° àª«àª¿àª²à«àªŸàª° àª¥àª¯à«‡àª²à«€ àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àªœ àª¡à«àª°à«‹àªªàª¡àª¾àª‰àª¨àª®àª¾àª‚ àª¬àª¤àª¾àªµà«‹
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
                            // âœ… à«©. àª¸àª¿àª²à«‡àª•à«àªŸ àª•àª°à«‡àª²à«€ àª«àª¿àª²à«àªŸàª° àªªà«àª²à«‡àª²àª¿àª¸à«àªŸàª®àª¾àª‚ àªàª¡ àª•àª°à«‹
                            final playlist = filteredPlaylists[selectedPlaylistIndex] as PlaylistModel;

                            if (!playlist.items.any((e) => e.path == currentItem.path)) {
                              playlist.items.add(currentItem);
                              playlist.save(); // HiveObject àªµàª¾àªªàª°àª¤àª¾ àª¹à«‹àªµ àª¤à«‹ save() àªšàª¾àª²à«‡

                              Navigator.pop(context);
                              AppToast.show(context, "${context.tr("addedTo")} ${playlist.name}", type: ToastType.success);
                            } else {
                              AppToast.show(context, "${context.tr("alreadyExistIn")} ${playlist.name}", type: ToastType.info);
                            }
                          }
                          else if (newPlaylistName.trim().isNotEmpty) {
                            final name = newPlaylistName.trim();

                            // âœ… à«ª. àª¨àªµà«€ àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àª¬àª¨àª¾àªµàª¤à«€ àªµàª–àª¤à«‡ àªŸàª¾àªˆàªª àª¸à«àªŸà«‹àª° àª•àª°à«‹
                            final newPlaylist = PlaylistModel(
                              name: name,
                              items: [currentItem],
                              type: currentItem.type, // 'audio' àª…àª¥àªµàª¾ 'video'
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
//   dynamic selectedPlaylistIndex; // Ã ÂªÂ¸Ã ÂªÂ¿Ã ÂªÂ²Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÂ¥Ã ÂªÂ¯Ã Â«â€¡Ã ÂªÂ² Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸ Ã Âªâ€¡Ã ÂªÂ¨Ã Â«ÂÃ ÂªÂ¡Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¸ Ã ÂªÂ°Ã ÂªÂ¾Ã Âªâ€“Ã ÂªÂµÃ ÂªÂ¾ Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡
//
//   showDialog(
//     context: context,
//     barrierDismissible: true,
//     builder: (context) {
//       // StatefulBuilder Ã ÂªÅ“Ã ÂªÂ°Ã Â«â€šÃ ÂªÂ°Ã Â«â‚¬ Ã Âªâ€ºÃ Â«â€¡ Ã ÂªÅ“Ã Â«â€¡Ã ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ¡Ã Â«ÂÃ ÂªÂ°Ã Â«â€¹Ã ÂªÂªÃ ÂªÂ¡Ã ÂªÂ¾Ã Âªâ€°Ã ÂªÂ¨ Ã ÂªÂ¸Ã ÂªÂ¿Ã ÂªÂ²Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¶Ã ÂªÂ¨ Ã ÂªÂµÃ Âªâ€“Ã ÂªÂ¤Ã Â«â€¡ UI Ã Âªâ€¦Ã ÂªÂªÃ ÂªÂ¡Ã Â«â€¡Ã ÂªÅ¸ Ã ÂªÂ¥Ã ÂªÂ¾Ã ÂªÂ¯
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
//                   // --- Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÂ¡Ã Â«ÂÃ ÂªÂ°Ã Â«â€¹Ã ÂªÂªÃ ÂªÂ¡Ã ÂªÂ¾Ã Âªâ€°Ã ÂªÂ¨ ---
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
//                           // Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ¨Ã Â«â€šÃ ÂªÂ¨Ã Â«â€¡ Ã ÂªÂ¡Ã ÂªÂ¾Ã ÂªÂ¬Ã Â«â‚¬ Ã ÂªÂ¬Ã ÂªÂ¾Ã ÂªÅ“Ã Â«ÂÃ ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ¶Ã ÂªÂ°Ã Â«â€š Ã Âªâ€¢Ã ÂªÂ°Ã ÂªÂ¶Ã Â«â€¡
//                           // Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ¨Ã Â«â€š Ã Âªâ€ Ã Âªâ€“Ã Â«ÂÃ Âªâ€š Ã ÂªÂ¡Ã ÂªÂ¾Ã ÂªÂ¯Ã ÂªÂ²Ã Â«â€¹Ã Âªâ€” Ã ÂªÂ°Ã Â«â€¹Ã Âªâ€¢Ã Â«â‚¬ Ã ÂªÂ¨ Ã ÂªÂ²Ã Â«â€¡ Ã ÂªÂ¤Ã Â«â€¡ Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡ Ã ÂªÂ¤Ã ÂªÂ®Ã Â«â€¡ Ã ÂªÂ®Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÂ¸ Ã ÂªÂ¹Ã ÂªÂ¾Ã ÂªË†Ã ÂªÅ¸ Ã ÂªÂªÃ ÂªÂ£ Ã Âªâ€ Ã ÂªÂªÃ Â«â‚¬ Ã ÂªÂ¶Ã Âªâ€¢Ã Â«â€¹
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
//                   // --- Ã ÂªÂ¨Ã ÂªÂµÃ Â«ÂÃ Âªâ€š Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÂ¬Ã ÂªÂ¨Ã ÂªÂ¾Ã ÂªÂµÃ ÂªÂµÃ ÂªÂ¾Ã ÂªÂ¨Ã Â«ÂÃ Âªâ€š Ã ÂªÂ«Ã ÂªÂ¿Ã ÂªÂ²Ã Â«ÂÃ ÂªÂ¡ ---
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
//                           // Ã Â«Â§. Ã ÂªÅ“Ã Â«â€¹ Ã ÂªÂ¡Ã Â«ÂÃ ÂªÂ°Ã Â«â€¹Ã ÂªÂªÃ ÂªÂ¡Ã ÂªÂ¾Ã Âªâ€°Ã ÂªÂ¨Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€šÃ ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ¸Ã ÂªÂ¿Ã ÂªÂ²Ã Â«â€¡Ã Âªâ€¢Ã Â«ÂÃ ÂªÅ¸ Ã Âªâ€¢Ã ÂªÂ°Ã Â«ÂÃ ÂªÂ¯Ã Â«ÂÃ Âªâ€š Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ¯
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
//                           // Ã Â«Â¨. Ã ÂªÅ“Ã Â«â€¹ Ã ÂªÂ¨Ã ÂªÂµÃ Â«ÂÃ Âªâ€š Ã ÂªÂ¨Ã ÂªÂ¾Ã ÂªÂ® Ã ÂªÂ²Ã Âªâ€“Ã Â«ÂÃ ÂªÂ¯Ã Â«ÂÃ Âªâ€š Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ¯
//                           else if (newPlaylistName.trim().isNotEmpty) {
//                             final name = newPlaylistName.trim();
//
//                             // Ã°Å¸â€Â Ã Âªâ€¦Ã ÂªÂ¹Ã Â«â‚¬Ã Âªâ€š Ã ÂªÅ¡Ã Â«â€¡Ã Âªâ€¢ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹ Ã Âªâ€¢Ã Â«â€¡ Ã Âªâ€  Ã ÂªÂ¨Ã ÂªÂ¾Ã ÂªÂ®Ã ÂªÂ¨Ã Â«ÂÃ Âªâ€š Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ²Ã ÂªÂ¿Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸ Ã ÂªÂªÃ ÂªÂ¹Ã Â«â€¡Ã ÂªÂ²Ã Â«â€¡Ã ÂªÂ¥Ã Â«â‚¬ Ã Âªâ€ºÃ Â«â€¡ Ã Âªâ€¢Ã Â«â€¡ Ã ÂªÂ¨Ã ÂªÂ¹Ã Â«â‚¬Ã Âªâ€š
//                             bool exists = playlistBox.values.any(
//                                   (element) =>
//                               element.name.toLowerCase() ==
//                                   name.toLowerCase(),
//                             );
//
//                             if (exists) {
//                               // Ã¢Å¡ Ã¯Â¸Â Ã ÂªÅ“Ã Â«â€¹ Ã ÂªÂ¨Ã ÂªÂ¾Ã ÂªÂ® Ã ÂªÂªÃ ÂªÂ¹Ã Â«â€¡Ã ÂªÂ²Ã Â«â€¡Ã ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ¯ Ã ÂªÂ¤Ã Â«â€¹ Ã ÂªÂÃ ÂªÂ°Ã ÂªÂ° Ã ÂªÂ¬Ã ÂªÂ¤Ã ÂªÂ¾Ã ÂªÂµÃ Â«â€¹
//                               AppToast.show(
//                                 context,
//                                 "${context.tr("playlist")} '$name' ${context.tr("alreadyExists")}",
//                                 type: ToastType.error,
//                               );
//                             } else {
//                               // Ã¢Å“â€¦ Ã ÂªÅ“Ã Â«â€¹ Ã ÂªÂ¨Ã ÂªÂµÃ Â«ÂÃ Âªâ€š Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ¯ Ã ÂªÂ¤Ã Â«â€¹ Ã ÂªÅ“ Ã ÂªÂ¬Ã ÂªÂ¨Ã ÂªÂ¾Ã ÂªÂµÃ Â«â€¹
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
// // Ã ÂªÂ¸Ã Â«ÂÃ ÂªÂ¨Ã Â«â€¡Ã Âªâ€¢Ã ÂªÂ¬Ã ÂªÂ¾Ã ÂªÂ° Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÅ¸Ã Â«â€¡ Ã ÂªÂ¹Ã Â«â€¡Ã ÂªÂ²Ã Â«ÂÃ ÂªÂªÃ ÂªÂ° Ã ÂªÂ®Ã Â«â€¡Ã ÂªÂ¥Ã ÂªÂ¡
// void _showSnackBar(BuildContext context, String message) {
//   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
// }