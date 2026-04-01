import '../utils/app_imports.dart';

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
  Future<void> _initFavState() async {
    final file = await widget.entity.file;
    if (file == null) return;

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

    if (mounted) {
      setState(() {
        favState = newFavState;
      });

      try {
        final audioBloc = context.read<AudioBloc>();
        final state = audioBloc.state;

        if (state is AudioLoaded) {
          final listIndex = state.entities.indexWhere(
                (element) => element.id == widget.entity.id,
          );

          if (listIndex != -1) {
            final AssetEntity? newEntity = await widget.entity
                .obtainForNewProperties();

            if (newEntity != null) {
              final updatedEntities = List<AssetEntity>.from(state.entities);

              updatedEntities[listIndex] = newEntity;

              audioBloc.emit(state.copyWith(entities: updatedEntities));
            }
          }
        }
      } catch (e) {
        print("Error while updating bloc directly: $e");

        context.read<AudioBloc>().add(LoadAudios(showLoading: false));
      }
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
            color: favState ? null : colors.blackColor,
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