import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import '../core/constants.dart';
import '../services/playlist_service.dart';
import '../utils/app_colors.dart';
import '../widgets/image_widget.dart';


class FavouriteButton extends StatefulWidget {
  final AssetEntity entity;

  const FavouriteButton({super.key, required this.entity});

  @override
  State<FavouriteButton> createState() => _FavouriteButtonState();
}
class _FavouriteButtonState extends State<FavouriteButton> {
  late Box favBox;
  bool favState = false;

  @override
  void initState() {
    super.initState();
    favBox = Hive.box('favourites'); // Make sure Hive is opened
    _initFavState();
  }

  /// Initialize favourite state from Hive
  /// Initialize favourite state from Hive
  Future<void> _initFavState() async {
    final file = await widget.entity.file;
    if (file == null) return;

    // àªœà«‹ àªµàª¿àªœà«‡àªŸ àª¹àªœà«€ àª¸à«àª•à«àª°à«€àª¨ àªªàª° àª¹à«‹àª¯ (mounted àª¹à«‹àª¯), àª¤à«‹ àªœ setState àª•àª°àªµà«àª‚
    if (mounted) {
      setState(() {
        favState = favBox.containsKey(file.path);
      });
    }
  }

  /// Toggle favourite using PlaylistService
  Future<void> _toggleFavourite() async {
    final file = await widget.entity.file;
    if (file == null) return;

    final playlistService = PlaylistService();
    final newFavState = await playlistService.toggleFavourite(widget.entity);

    // àª…àª¹à«€àª‚ àªªàª£ mounted àªšà«‡àª• àª•àª°àªµà«àª‚ àªœàª°à«‚àª°à«€ àª›à«‡
    if (mounted) {
      setState(() {
        favState = newFavState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return ValueListenableBuilder(
      valueListenable: favBox.listenable(),
      builder: (context, Box box, _) {
        return GestureDetector(
          onTap: _toggleFavourite,
          child: AppImage(
            src: favState ? AppSvg.likeIcon : AppSvg.unlikeIcon,
            height: 20,
            width: 20,
            color: favState ?null:colors.blackColor,
          ),
        );

        IconButton(
          icon: Icon(favState ? Icons.favorite : Icons.favorite_border),
          onPressed: _toggleFavourite,
          color: favState ? Colors.red : null,
        );
      },
    );
  }
}