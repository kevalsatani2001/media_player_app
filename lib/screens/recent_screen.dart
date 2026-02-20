import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/media_item.dart';
import 'player_screen.dart';

class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('recents');

    final items = box.values.toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('No recent media'),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(
                    item.path.split('/').last,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerScreen(
                          item: item,  entity: AssetEntity(
                          id: item.id,
                          typeInt: item.type == "audio" ? 3 : 2,
                          width: 200,
                          height: 200,
                          isFavorite: item.isFavourite,
                          title: item.path.split("/").last,
                          relativePath: item.path,
                        ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
