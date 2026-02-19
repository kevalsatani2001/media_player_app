import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AppTransition extends StatelessWidget {
  final int index;
  final Widget child;
  final int? columnCount; // જો Grid હોય તો જ આપવું

  const AppTransition({
    super.key,
    required this.index,
    required this.child,
    this.columnCount,
  });

  @override
  Widget build(BuildContext context) {
    // જો columnCount હોય તો Grid એનિમેશન, નહીંતર List એનિમેશન
    return columnCount != null
        ? AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 400),
      columnCount: columnCount!,
      child: _buildEffect(),
    )
        : AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 400),
      child: _buildEffect(),
    );
  }

  Widget _buildEffect() {
    return SlideAnimation(
      verticalOffset: 50.0, // નીચેથી ઉપર આવશે
      child: FadeInAnimation(
        child: child,
      ),
    );
  }
}