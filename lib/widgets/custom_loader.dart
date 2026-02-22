import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLoader extends StatelessWidget {
  final double? height; // નવી પ્રોપર્ટી
  final double? width;  // નવી પ્રોપર્ટી
  final Color? color;

  const CustomLoader({
    super.key,
    this.height = 100.0, // Default height
    this.width = 100.0,  // Default width
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/animation/loader.json',
        width: width,   // અહીં width સેટ થશે
        height: height, // અહીં height સેટ થશે
        fit: BoxFit.contain,
        delegates: color != null
            ? LottieDelegates(
          values: [
            ValueDelegate.color(
              const ['**'],
              value: color!,
            ),
          ],
        )
            : null,
        errorBuilder: (context, error, stackTrace) {
          return CircularProgressIndicator(color: color);
        },
      ),
    );
  }
}