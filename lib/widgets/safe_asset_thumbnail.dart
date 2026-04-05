import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

ThumbnailOption _thumbOptionForPlatform(
  ThumbnailSize size,
  ThumbnailFormat format, {
  int frame = 0,
}) {
  if (Platform.isIOS || Platform.isMacOS) {
    return ThumbnailOption.ios(size: size, format: format);
  }
  return ThumbnailOption(size: size, format: format, frame: frame);
}

/// Loads gallery thumbnail bytes without [AssetEntityImageProvider], so
/// Android Glide / MediaMetadataRetriever failures are caught in Dart
/// instead of being reported as Flutter image stream errors.
Future<Uint8List?> loadAssetThumbnailBytesSafe(
  AssetEntity entity, {
  required ThumbnailSize thumbnailSize,
  ThumbnailFormat format = ThumbnailFormat.jpeg,
  int frame = 0,
}) async {
  if (entity.type == AssetType.audio || entity.type == AssetType.other) {
    return null;
  }
  try {
    final option =
        _thumbOptionForPlatform(thumbnailSize, format, frame: frame);
    final data = await entity.thumbnailDataWithOption(option);
    if (data == null || data.isEmpty) return null;
    return data;
  } on PlatformException catch (e) {
    debugPrint('Thumbnail PlatformException: ${e.code} ${e.message}');
    return null;
  } catch (e) {
    debugPrint('Thumbnail load failed: $e');
    return null;
  }
}

class SafeAssetThumbnail extends StatefulWidget {
  const SafeAssetThumbnail({
    super.key,
    required this.entity,
    required this.thumbnailSize,
    this.format = ThumbnailFormat.jpeg,
    this.frame = 0,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.loading,
  });

  final AssetEntity entity;
  final ThumbnailSize thumbnailSize;
  final ThumbnailFormat format;
  final int frame;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? loading;

  @override
  State<SafeAssetThumbnail> createState() => _SafeAssetThumbnailState();
}

class _SafeAssetThumbnailState extends State<SafeAssetThumbnail> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant SafeAssetThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entity.id != widget.entity.id ||
        oldWidget.thumbnailSize != widget.thumbnailSize ||
        oldWidget.format != widget.format ||
        oldWidget.frame != widget.frame) {
      _future = _load();
    }
  }

  Future<Uint8List?> _load() => loadAssetThumbnailBytesSafe(
        widget.entity,
        thumbnailSize: widget.thumbnailSize,
        format: widget.format,
        frame: widget.frame,
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loading ??
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return widget.placeholder ??
              const ColoredBox(
                color: Color(0xFF1A1A1A),
                child: Center(
                  child: Icon(Icons.broken_image, color: Colors.white54),
                ),
              );
        }
        final fallback = widget.placeholder ??
            const ColoredBox(
              color: Color(0xFF1A1A1A),
              child: Center(
                child: Icon(Icons.broken_image, color: Colors.white54),
              ),
            );
        return Image.memory(
          bytes,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback,
        );
      },
    );
  }
}
