import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});


  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return  Center(
      child: CircularProgressIndicator(color: colors.primary),
    );
  }
}