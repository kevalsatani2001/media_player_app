import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_player/widgets/text_widget.dart';
import '../models/media_item.dart';
import '../models/playlist_model.dart';
import '../utils/app_colors.dart';
import '../widgets/app_button.dart';

void addToPlaylist(MediaItem currentItem,BuildContext context) {
  final colors = Theme.of(context).extension<AppThemeColors>()!;
  final playlistBox = Hive.box('playlists');
  String newPlaylistName = '';

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return AlertDialog(
        actionsPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(20),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 36),
        contentPadding: EdgeInsets.only(
          left: 33,
          right: 33,
          bottom: 20,
          top: 40,
        ),
        backgroundColor: colors.cardBackground,
        title: AppText(
          "Add to Playlist",
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: colors.appBarTitleColor,
          align: TextAlign.center,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Existing playlists
                if (playlistBox.isNotEmpty)
                  ...List.generate(playlistBox.length, (index) {
                    final playlist = playlistBox.getAt(index)!;
                    return ListTile(
                      leading: const Icon(Icons.queue_music),
                      title: Text(playlist.name),
                      onTap: () {
                        // Add currentItem to the existing playlist
                        if (!playlist.items.any(
                              (e) => e.path == currentItem.path,
                        )) {
                          playlist.items.add(currentItem);
                          playlistBox.putAt(
                            index,
                            playlist,
                          ); // ✅ put updated PlaylistModel
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Added to ${playlist.name}"),
                          ),
                        );
                      },
                    );
                  }),

                if (playlistBox.isNotEmpty) const Divider(),

                // Create new playlist
                TextField(
                  decoration: InputDecoration(
                    labelText: "New Playlist Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => newPlaylistName = v,
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    title: "Cancel",
                    textColor: colors.dialogueSubTitle,
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                    backgroundColor: colors.whiteColor,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: AppButton(
                    title: "Create",
                    textColor: colors.whiteColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                    backgroundColor: colors.primary,
                    onTap: () {
                      if (newPlaylistName.trim().isEmpty) return;

                      final newPlaylist = PlaylistModel(
                        name: newPlaylistName.trim(),
                        items: [currentItem],
                      );
                      playlistBox.add(newPlaylist);

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Playlist \"$newPlaylistName\" created",
                          ),
                        ),
                      );
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
}