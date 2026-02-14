import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import '../models/media_item.dart';
import '../models/playlist_model.dart';
import '../services/playlist_service.dart';
import 'player_screen.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('playlists');

    return Scaffold(
      appBar: AppBar(title: const Text("Playlists")),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (_, Box box, __) {
          final playlists = box.values.toList();

          if (playlists.isEmpty) {
            return const Center(child: Text("No playlists found."));
          }

          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (_, index) {
              final playlist = playlists[index];
              return ListTile(
                title: Text(playlist.name),
                subtitle: Text('${playlist.items.length} items'),
                trailing: PopupMenuButton<PlaylistMenuAction>(
                  onSelected: (action) {
                    switch (action) {
                      case PlaylistMenuAction.rename:
                        _showRenameDialog(context, box, index, playlist.name);
                        break;
                      case PlaylistMenuAction.delete:
                        _confirmDelete(context, box, index, playlist.name);
                        break;
                      case PlaylistMenuAction.share:
                        _sharePlaylist(playlist);
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: PlaylistMenuAction.rename,
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text("Rename"),
                      ),
                    ),
                    PopupMenuItem(
                      value: PlaylistMenuAction.share,
                      child: ListTile(
                        leading: Icon(Icons.share),
                        title: Text("Share"),
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: PlaylistMenuAction.delete,
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          "Delete",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaylistItemsScreen(
                        name: playlist.name,
                        items: playlist.items,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context,
      Box box,
      int index,
      String oldName,
      ) {
    final controller = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Rename Playlist"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Playlist name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              final playlist = box.getAt(index);
              if (playlist != null) {
                playlist.name = newName;
                playlist.save();
              }

              Navigator.pop(context);
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Box box, int index, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Playlist"),
        content: Text("Delete \"$name\" permanently?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              box.deleteAt(index);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePlaylist(PlaylistModel playlist) async {
    final List<XFile> files = [];

    for (final item in playlist.items) {
      if (item.path.isNotEmpty && File(item.path).existsSync()) {
        files.add(XFile(item.path));
      }
    }

    if (files.isEmpty) return;
    if (files.length > 10) {
      files.removeRange(10, files.length);
    }

    await Share.shareXFiles(
      files,
      text: files.length == 1
          ? "Sharing 1 file from ${playlist.name}"
          : "Sharing ${files.length} files from ${playlist.name}",
    );
  }
}

class PlaylistItemsScreen extends StatelessWidget {
  final String name;
  final List<MediaItem> items;

  const PlaylistItemsScreen({
    super.key,
    required this.name,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    // final mediaItems = items
    //     .map((e) => MediaItem.fromMap(Map<String, dynamic>.from(e)))
    //     .toList();

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: items.isEmpty
          ? const Center(child: Text("Playlist empty"))
          : ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return ListTile(
            leading: Icon(
              item.type == 'video' ? Icons.video_file : Icons.music_note,
            ),
            title: Text(item.path.split('/').last),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    entity: AssetEntity(
                      relativePath: item.path,
                      title: item.path,
                      id: item.id!,
                      typeInt: item.type == AssetType.audio ? 3 : 2,
                      width: 0,
                      height: 0,
                      isFavorite: item.isFavourite ?? false,
                    ),
                    item: MediaItem(
                      id: item.id,
                      path: item.path,
                      isNetwork: false,
                      isFavourite: item.isFavourite,
                      type: 'audio',
                    ),
                  ),
                ),
              ).then((value) {
                // context.read<AudioBloc>().add(LoadAudios(showLoading: false));
              });
            },
          );
        },
      ),
    );
  }
}

enum PlaylistMenuAction { rename, delete, share }