import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppImage extends StatelessWidget {
  final String src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;
  final Color? color;

  const AppImage({
    super.key,
    required this.src,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
    this.color,
  });

  bool get _isNetwork => src.startsWith('http');
  bool get _isSvg => src.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (_isSvg && _isNetwork) {
      /// 🌐 Network SVG
      image = SvgPicture.network(
        src,
        width: width,
        height: height,
        fit: fit,
        colorFilter:
        color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      );
    } else if (_isSvg) {
      /// 📦 Asset SVG
      image = SvgPicture.asset(
        src,
        width: width,
        height: height,
        fit: fit,
        colorFilter:
        color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      );
    } else if (_isNetwork) {
      /// 🌐 Network Image
      image = Image.network(
        src,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else {
      /// 📦 Asset Image
      image = Image.asset(
        src,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return radius == null
        ? image
        : ClipRRect(borderRadius: radius!, child: image);
  }
}
