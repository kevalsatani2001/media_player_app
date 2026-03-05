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

  String newPlaylistName = '';
  dynamic selectedPlaylistIndex; // àª¸àª¿àª²à«‡àª•à«àªŸ àª¥àª¯à«‡àª² àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àª‡àª¨à«àª¡à«‡àª•à«àª¸ àª°àª¾àª–àªµàª¾ àª®àª¾àªŸà«‡

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      // StatefulBuilder àªœàª°à«‚àª°à«€ àª›à«‡ àªœà«‡àª¥à«€ àª¡à«àª°à«‹àªªàª¡àª¾àª‰àª¨ àª¸àª¿àª²à«‡àª•à«àª¶àª¨ àªµàª–àª¤à«‡ UI àª…àªªàª¡à«‡àªŸ àª¥àª¾àª¯
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àª¡à«àª°à«‹àªªàª¡àª¾àª‰àª¨ ---
                  if (playlistBox.isNotEmpty) ...[
                    AppText(
                      "selectExistingPlaylist",
                      fontSize: 14,
                      color: colors.dialogueSubTitle,
                    ),
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
                      items: List.generate(playlistBox.length, (index) {
                        final playlist = playlistBox.getAt(index)!;
                        return DropdownMenuItem(
                          alignment: AlignmentDirectional.centerStart,
                          // àª®à«‡àª¨à«‚àª¨à«‡ àª¡àª¾àª¬à«€ àª¬àª¾àªœà«àª¥à«€ àª¶àª°à«‚ àª•àª°àª¶à«‡
                          // àª®à«‡àª¨à«‚ àª†àª–à«àª‚ àª¡àª¾àª¯àª²à«‹àª— àª°à«‹àª•à«€ àª¨ àª²à«‡ àª¤à«‡ àª®àª¾àªŸà«‡ àª¤àª®à«‡ àª®à«‡àª•à«àª¸ àª¹àª¾àªˆàªŸ àªªàª£ àª†àªªà«€ àª¶àª•à«‹
                          value: index,
                          child: Text(
                            playlist.name,
                            style: TextStyle(color: colors.appBarTitleColor),
                          ),
                        );
                      }),
                      onChanged: (value) =>
                          setState(() => selectedPlaylistIndex = value),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                  ],

                  // --- àª¨àªµà«àª‚ àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àª¬àª¨àª¾àªµàªµàª¾àª¨à«àª‚ àª«àª¿àª²à«àª¡ ---
                  AppText(
                    "orCreateNew",
                    fontSize: 14,
                    color: colors.dialogueSubTitle,
                  ),
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
                        backgroundColor: colors.primary,
                        textColor: Colors.white,

                        onTap: () {
                          // à«§. àªœà«‹ àª¡à«àª°à«‹àªªàª¡àª¾àª‰àª¨àª®àª¾àª‚àª¥à«€ àª¸àª¿àª²à«‡àª•à«àªŸ àª•àª°à«àª¯à«àª‚ àª¹à«‹àª¯
                          if (selectedPlaylistIndex != null) {
                            final playlist = playlistBox.getAt(
                              selectedPlaylistIndex,
                            )!;

                            if (!playlist.items.any(
                                  (e) => e.path == currentItem.path,
                            )) {
                              playlist.items.add(currentItem);
                              playlistBox.putAt(
                                selectedPlaylistIndex,
                                playlist,
                              );

                              Navigator.pop(context);
                              AppToast.show(
                                context,
                                "${context.tr("addedTo")} ${playlist.name}",
                                type: ToastType.success,
                              );
                            } else {
                              AppToast.show(
                                context,
                                "${context.tr("alreadyExistIn")} ${playlist.name}",
                                type: ToastType.info,
                              );
                            }
                          }
                          // à«¨. àªœà«‹ àª¨àªµà«àª‚ àª¨àª¾àª® àª²àª–à«àª¯à«àª‚ àª¹à«‹àª¯
                          else if (newPlaylistName.trim().isNotEmpty) {
                            final name = newPlaylistName.trim();

                            // ðŸ” àª…àª¹à«€àª‚ àªšà«‡àª• àª•àª°à«‹ àª•à«‡ àª† àª¨àª¾àª®àª¨à«àª‚ àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àªªàª¹à«‡àª²à«‡àª¥à«€ àª›à«‡ àª•à«‡ àª¨àª¹à«€àª‚
                            bool exists = playlistBox.values.any(
                                  (element) =>
                              element.name.toLowerCase() ==
                                  name.toLowerCase(),
                            );

                            if (exists) {
                              // âš ï¸ àªœà«‹ àª¨àª¾àª® àªªàª¹à«‡àª²à«‡àª¥à«€ àª¹à«‹àª¯ àª¤à«‹ àªàª°àª° àª¬àª¤àª¾àªµà«‹
                              AppToast.show(
                                context,
                                "${context.tr("playlist")} '$name' ${context.tr("alreadyExists")}",
                                type: ToastType.error,
                              );
                            } else {
                              // âœ… àªœà«‹ àª¨àªµà«àª‚ àª¹à«‹àª¯ àª¤à«‹ àªœ àª¬àª¨àª¾àªµà«‹
                              final newPlaylist = PlaylistModel(
                                name: name,
                                items: [currentItem],
                              );
                              playlistBox.add(newPlaylist);

                              Navigator.pop(context);
                              AppToast.show(
                                context,
                                context.tr("newPlaylistCreated"),
                                type: ToastType.success,
                              );
                            }
                          } else {
                            AppToast.show(
                              context,
                              context.tr("pleaseSelectEnterPlaylistName"),
                              type: ToastType.error,
                            );
                          }
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

// àª¸à«àª¨à«‡àª•àª¬àª¾àª° àª®àª¾àªŸà«‡ àª¹à«‡àª²à«àªªàª° àª®à«‡àª¥àª¡
void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}