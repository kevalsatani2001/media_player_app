import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_player/widgets/text_widget.dart';
import '../models/media_item.dart';
import '../models/playlist_model.dart';
import '../utils/app_colors.dart';
import '../widgets/app_button.dart';

void addToPlaylist(MediaItem currentItem, BuildContext context) {
  final colors = Theme.of(context).extension<AppThemeColors>()!;
  final playlistBox = Hive.box('playlists');

  String newPlaylistName = '';
  dynamic selectedPlaylistIndex; // સિલેક્ટ થયેલ પ્લેલિસ્ટ ઇન્ડેક્સ રાખવા માટે

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      // StatefulBuilder જરૂરી છે જેથી ડ્રોપડાઉન સિલેક્શન વખતે UI અપડેટ થાય
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: colors.cardBackground,
          title: AppText(
            "Add to Playlist",
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
                // --- પ્લેલિસ્ટ ડ્રોપડાઉન ---
                if (playlistBox.isNotEmpty) ...[
                  AppText("Select Existing Playlist", fontSize: 14, color: colors.dialogueSubTitle),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.textFieldFill,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),),
                    ),
                    dropdownColor: colors.background,
                    hint: Text("Choose Playlist", style: TextStyle(color: colors.dialogueSubTitle)),
                    value: selectedPlaylistIndex,
                    items: List.generate(playlistBox.length, (index) {
                      final playlist = playlistBox.getAt(index)!;
                      return DropdownMenuItem(
                        alignment: AlignmentDirectional.centerStart, // મેનૂને ડાબી બાજુથી શરૂ કરશે
                        // મેનૂ આખું ડાયલોગ રોકી ન લે તે માટે તમે મેક્સ હાઈટ પણ આપી શકો
                        value: index,
                        child: Text(playlist.name, style: TextStyle(color: colors.appBarTitleColor)),
                      );
                    }),
                    onChanged: (value) => setState(() => selectedPlaylistIndex = value),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                ],

                // --- નવું પ્લેલિસ્ટ બનાવવાનું ફિલ્ડ ---
                AppText("Or Create New", fontSize: 14, color: colors.dialogueSubTitle),
                const SizedBox(height: 8),
                TextField(
                  style: TextStyle(color: colors.appBarTitleColor),
                  decoration: InputDecoration(
                    hintText: "Enter Name",
                    hintStyle: TextStyle(color: colors.dialogueSubTitle.withOpacity(0.5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      title: "Cancel",
                      backgroundColor: colors.whiteColor,
                      textColor: colors.dialogueSubTitle,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppButton(
                      title: "Add",
                      backgroundColor: colors.primary,
                      textColor: colors.whiteColor,
                      onTap: () {
                        // ૧. જો ડ્રોપડાઉનમાંથી સિલેક્ટ કર્યું હોય
                        if (selectedPlaylistIndex != null) {
                          final playlist = playlistBox.getAt(selectedPlaylistIndex)!;
                          if (!playlist.items.any((e) => e.path == currentItem.path)) {
                            playlist.items.add(currentItem);
                            playlistBox.putAt(selectedPlaylistIndex, playlist);
                          }
                          Navigator.pop(context);
                          _showSnackBar(context, "Added to ${playlist.name}");
                        }
                        // ૨. જો નવું નામ લખ્યું હોય
                        else if (newPlaylistName.trim().isNotEmpty) {
                          final newPlaylist = PlaylistModel(
                            name: newPlaylistName.trim(),
                            items: [currentItem],
                          );
                          playlistBox.add(newPlaylist);
                          Navigator.pop(context);
                          _showSnackBar(context, "New Playlist Created");
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      });
    },
  );
}

// સ્નેકબાર માટે હેલ્પર મેથડ
void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}