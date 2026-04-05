import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

/// Persists JPEG paths so the video grid can show the user-picked cover frame
/// (gallery/OS thumbnails are always from the encoded video, not our trim UI).
class CustomVideoThumbnailStore {
  CustomVideoThumbnailStore._();

  static const String boxName = 'custom_video_thumbs';

  static String _normTitle(String raw) {
    var s = raw.toLowerCase().trim();
    if (s.endsWith('.mp4') ||
        s.endsWith('.mov') ||
        s.endsWith('.m4v') ||
        s.endsWith('.mkv')) {
      s = s.substring(0, s.lastIndexOf('.'));
    }
    return s.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static String _displayTitle(AssetEntity e) {
    final t = e.title?.trim();
    if (t != null && t.isNotEmpty) return t;
    final rp = e.relativePath?.trim();
    if (rp != null && rp.isNotEmpty) {
      final i = rp.replaceAll(r'\', '/').lastIndexOf('/');
      return i >= 0 ? rp.substring(i + 1) : rp;
    }
    return '';
  }

  /// Resolved override: absolute path to JPEG for this gallery asset id.
  static String? pathFor(String assetId) {
    if (!Hive.isBoxOpen(boxName)) return null;
    final v = Hive.box(boxName).get(assetId);
    if (v is! String || v.isEmpty) return null;
    if (!File(v).existsSync()) return null;
    return v;
  }

  static List<Map<String, dynamic>> _readPending(Box box) {
    final raw = box.get('__pending__');
    if (raw is! String || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writePending(Box box, List<Map<String, dynamic>> q) async {
    if (q.isEmpty) {
      await box.delete('__pending__');
    } else {
      await box.put('__pending__', jsonEncode(q));
    }
  }

  /// Call after export succeeds, before gallery refresh. [baseName] = file name
  /// without extension (same as passed to [saveTrimmedVideo]).
  static Future<void> registerPendingOverride({
    required String baseName,
    required List<int> jpegBytes,
  }) async {
    if (jpegBytes.isEmpty) return;
    final box = Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await Hive.openBox(boxName);
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/custom_video_thumbs');
    if (!dir.existsSync()) await dir.create(recursive: true);
    final file = File(
      '${dir.path}/cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(jpegBytes, flush: true);

    final norm = _normTitle(baseName);
    if (norm.isEmpty) return;

    final q = _readPending(box);
    q.add({
      'norm': norm,
      'path': file.path,
      // Wide window: gallery indexing can lag after [Gal.putVideo].
      'afterMs': DateTime.now().millisecondsSinceEpoch - 120000,
    });
    await _writePending(box, q);
  }

  /// Match pending entries to freshly loaded gallery entities.
  static Future<void> resolvePendingForList(List<AssetEntity> entities) async {
    if (!Hive.isBoxOpen(boxName)) return;
    final box = Hive.box(boxName);
    var q = _readPending(box);
    if (q.isEmpty) return;

    final resolvedIdx = <int>[];

    for (var i = 0; i < q.length; i++) {
      final norm = q[i]['norm'] as String? ?? '';
      final path = q[i]['path'] as String? ?? '';
      final afterMs = q[i]['afterMs'] as int? ?? 0;
      if (norm.isEmpty || path.isEmpty || !File(path).existsSync()) {
        resolvedIdx.add(i);
        continue;
      }

      final candidates = entities.where((e) {
        if (e.type != AssetType.video) return false;
        final title = _displayTitle(e);
        if (title.isEmpty) return false;
        if (_normTitle(title) != norm) return false;
        return e.createDateTime.millisecondsSinceEpoch >= afterMs;
      }).toList();

      if (candidates.isEmpty) continue;

      candidates.sort(
        (a, b) => b.createDateTime.compareTo(a.createDateTime),
      );
      final winner = candidates.first;
      await box.put(winner.id, path);
      resolvedIdx.add(i);
    }

    if (resolvedIdx.isEmpty) return;
    for (final i in resolvedIdx.reversed) {
      q.removeAt(i);
    }
    await _writePending(box, q);
  }
}
