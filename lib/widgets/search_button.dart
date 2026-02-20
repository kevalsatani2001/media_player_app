import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../screens/search_screen.dart';
import 'image_widget.dart';

class SearchButton extends StatelessWidget {
  SearchButton({super.key});

  @override
  Widget build(BuildContext context) {
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
          ),
        ),
      ),
    );
  }
}
