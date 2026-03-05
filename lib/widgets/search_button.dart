import '../utils/app_imports.dart';

class SearchButton extends StatelessWidget {
  SearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
      },
      child: Container(
        height: 24,
        width: 24,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AppImage(
            src: "assets/svg_icon/search_icon.svg",
            height: 24,
            width: 24,
            color: colors.blackColor,
          ),
        ),
      ),
    );
  }
}