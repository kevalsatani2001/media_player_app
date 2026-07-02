import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'custom_loader.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});


  @override
  Widget build(BuildContext context) {
    return  Center(
      child: CustomLoader(),
    );
  }
}