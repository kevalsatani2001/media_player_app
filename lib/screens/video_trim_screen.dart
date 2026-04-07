import 'dart:math' as Math;
import 'dart:typed_data';

import '../services/ads_service.dart';
import '../services/custom_video_thumbnail_store.dart';
import '../utils/app_imports.dart';

class _CoverStripSlot {
  _CoverStripSlot({required this.timeMs});

  final double timeMs;

  /// In-memory JPEG bytes — [VideoThumbnail.thumbnailFile] reuses one path per
  /// video and overwrites; [thumbnailData] gives a distinct frame per slot.
  Uint8List? thumbBytes;
}

class VideoTrimScreen extends StatefulWidget {
  final File file;

  const VideoTrimScreen({super.key, required this.file});

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> {
  final playerService = GlobalPlayerService();
  final GlobalKey _videoViewerKey = GlobalKey();
  final Trimmer _trimmer = Trimmer();
  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _isSaving = false;

  File? _selectedCoverFile;

  /// JPEG bytes for the chosen cover; success screen uses this so preview works
  /// even if temp files are missing or [Image.file] fails on some devices.
  Uint8List? _selectedCoverPreviewBytes;
  double _selectedCoverTime = 0.0;
  final List<_CoverStripSlot> _coverStrip = [];
  bool _coverStripLoading = false;
  int _selectedCoverStripIndex = 0;

  bool _isSuccess = false;
  String _savedVideoPath = "";

  final ValueNotifier<String> _estimateSizeNotifier = ValueNotifier<String>(
    "0 MB",
  );
  String _resolution = "---";
  String _fps = "30 FPS"; // Default 30 FPS
  String _bitRate = "---";
  String _fileSize = "---";
  String _format = "MP4";
  double _originalFileSizeBytes = 0;
  double _totalDurationMs = 1;
  final ValueNotifier<double> _exportProgress = ValueNotifier<double>(0.0);

  double _currentPercentage = 0.0;
  Timer? _progressTimer;
  bool _isTrimmed = false;
  bool _isLoadingVideo = true;
  String? _loadError;
  bool _didAttachVideoListener = false;

  late final TextEditingController _exportFileNameController;

  /// Sanitized base name for the next export (set from save dialog).
  String? _pendingExportBaseName;

  @override
  void initState() {
    super.initState();
    _exportFileNameController = TextEditingController(
      text: _defaultExportBaseName(),
    );
    playerService.pauseVideo();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadVideo();
    });
  }

  String get _estimateSize {
    if (_totalDurationMs <= 0) return "0 B";

    double trimDurationMs = _endValue - _startValue;

    double estimatedBytes =
        (_originalFileSizeBytes / _totalDurationMs) * trimDurationMs;

    if (estimatedBytes < 0) return "0 B";

    return _formatBytes(estimatedBytes);
  }

  String _formatBytes(double bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (Math.log(bytes) / Math.log(1024)).floor();
    return "${(bytes / Math.pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}";
  }

  String _defaultExportBaseName() {
    final p = widget.file.path.replaceAll(r'\', '/');
    final slash = p.lastIndexOf('/');
    final name = slash >= 0 ? p.substring(slash + 1) : p;
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    final safe = _sanitizeExportBaseName(base);
    return '${safe}_trim';
  }

  String _sanitizeExportBaseName(String raw) {
    var s = raw.trim();
    final lower = s.toLowerCase();
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v')) {
      s = s.substring(0, s.length - 4);
    }
    if (s.isEmpty) return 'trimmed_${DateTime.now().millisecondsSinceEpoch}';
    s = s.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
    s = s.replaceAll(RegExp(r'\s+'), '_');
    if (s.startsWith('.')) s = s.substring(1);
    if (s.isEmpty) return 'trimmed_${DateTime.now().millisecondsSinceEpoch}';
    if (s.length > 80) s = s.substring(0, 80);
    return s;
  }

  /// How many strip thumbnails to generate: spread across whole video (~1 per 0.8s),
  /// bounded so UX stays scrollable and devices don’t choke.
  int _coverStripThumbnailCount(double totalMs) {
    if (totalMs < 80) return 8;
    const minN = 16;
    const maxN = 100;
    int n = (totalMs / 800).ceil();
    if (n < minN) n = minN;
    if (n > maxN) n = maxN;
    return n;
  }

  Future<File> _writeCoverBytesToTempFile(int index, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final f = File(
      '${dir.path}/trim_cover_${index}_${_coverStrip[index].timeMs.toInt()}.jpg',
    );
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  Future<void> _syncSelectedCoverFileFromStrip() async {
    final i = _selectedCoverStripIndex;
    if (i < 0 || i >= _coverStrip.length) return;
    final bytes = _coverStrip[i].thumbBytes;
    if (bytes == null) return;
    final f = await _writeCoverBytesToTempFile(i, bytes);
    if (mounted) {
      setState(() {
        _selectedCoverFile = f;
        _selectedCoverPreviewBytes = Uint8List.fromList(bytes);
        _selectedCoverTime = _coverStrip[i].timeMs;
      });
    }
  }

  Future<void> _generateCoverStrip() async {
    if (!mounted || _totalDurationMs < 50) return;
    final int count = _coverStripThumbnailCount(_totalDurationMs);

    setState(() {
      _coverStripLoading = true;
      _coverStrip.clear();
      for (var i = 0; i < count; i++) {
        final t = count <= 1
            ? 0.0
            : (_totalDurationMs * i / (count - 1)).clamp(
          0.0,
          _totalDurationMs - 1,
        );
        _coverStrip.add(_CoverStripSlot(timeMs: t));
      }
      _selectedCoverStripIndex = count ~/ 2;
    });

    const int parallel = 3;
    for (var batch = 0; batch < _coverStrip.length; batch += parallel) {
      if (!mounted) return;
      final end = Math.min(batch + parallel, _coverStrip.length);
      final results = await Future.wait(
        List.generate(end - batch, (j) async {
          final i = batch + j;
          try {
            final data = await VideoThumbnail.thumbnailData(
              video: widget.file.path,
              imageFormat: ImageFormat.JPEG,
              timeMs: _coverStrip[i].timeMs.toInt(),
              quality: 60,
            );
            return MapEntry(i, data);
          } catch (e) {
            debugPrint('Cover strip thumb $i: $e');
            return MapEntry(i, null);
          }
        }),
      );

      if (!mounted) return;
      setState(() {
        for (final e in results) {
          final i = e.key;
          _coverStrip[i].thumbBytes = e.value;
        }
      });
    }

    if (mounted) {
      await _syncSelectedCoverFileFromStrip();
      setState(() => _coverStripLoading = false);
    }
  }

  Future<void> _onSelectCoverStripIndex(int i) async {
    if (i < 0 || i >= _coverStrip.length) return;
    final bytes = _coverStrip[i].thumbBytes;
    if (bytes == null) return;

    final f = await _writeCoverBytesToTempFile(i, bytes);
    if (!mounted) return;

    setState(() {
      _selectedCoverStripIndex = i;
      _selectedCoverFile = f;
      _selectedCoverPreviewBytes = Uint8List.fromList(bytes);
      _selectedCoverTime = _coverStrip[i].timeMs;
    });

    final c = _trimmer.videoPlayerController;
    if (c != null && c.value.isInitialized) {
      await c.pause();
      await c.seekTo(Duration(milliseconds: _coverStrip[i].timeMs.toInt()));
      if (mounted) setState(() => _isPlaying = false);
    }

    if (mounted) {
      AppToast.show(
        context,
        context.tr('coverFrameUpdated'),
        type: ToastType.success,
      );
    }
  }

  Widget _buildCoverThumbnailStrip() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    if (_isLoadingVideo || _loadError != null) return const SizedBox.shrink();
    if (_coverStrip.isEmpty && !_coverStripLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.collections_outlined,
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppText(
                    'coverThumbnail',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 62,
            child:
            _coverStripLoading &&
                _coverStrip.every((e) => e.thumbBytes == null)
                ? Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              ),
            )
                : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _coverStrip.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final item = _coverStrip[i];
                final sel = i == _selectedCoverStripIndex;
                return GestureDetector(
                  onTap: () => _onSelectCoverStripIndex(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? colors.primary : Colors.white24,
                        width: sel ? 2.5 : 1,
                      ),
                      boxShadow: sel
                          ? [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.35),
                          blurRadius: 8,
                        ),
                      ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.thumbBytes == null
                          ? ColoredBox(
                        color: colors.textFieldFill,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      )
                          : Image.memory(
                        item.thumbBytes!,
                        fit: BoxFit.cover,
                        width: 56,
                        height: 56,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: AppText(
              'selectCoverHint',
              fontSize: 11,
              color: colors.dialogueSubTitle,
            ),
          ),
        ],
      ),
    );
  }

  void _loadVideo() async {
    if (!mounted) return;
    setState(() {
      _isLoadingVideo = true;
      _loadError = null;
      _isTrimmed = false;
      _startValue = 0.0;
      _currentPercentage = 0.0;
      _isPlaying = false;
    });

    try {
      if (!await widget.file.exists()) {
        if (mounted) {
          setState(() {
            _isLoadingVideo = false;
            // ✅ Localization Key
            _loadError = context.tr("videoFileNotFound");
          });
        }
        return;
      }

      // Trimmer load can occasionally stall on some codecs/filesystems.
      await _trimmer
          .loadVideo(videoFile: widget.file)
          .timeout(const Duration(seconds: 20));

      int retry = 0;
      while (_trimmer.videoPlayerController == null && retry < 15) {
        await Future.delayed(const Duration(milliseconds: 200));
        retry++;
      }

      if (_trimmer.videoPlayerController == null) {
        if (mounted) {
          setState(() {
            _isLoadingVideo = false;
            // ✅ Localization Key
            _loadError = context.tr("unableToInitializePreview");
          });
        }
        return;
      }

      final controller = _trimmer.videoPlayerController!;
      if (!_didAttachVideoListener) {
        controller.addListener(_videoListener);
        _didAttachVideoListener = true;
      }

      if (controller.value.isInitialized) {
        final num bytes = await widget.file.length();
        final double durationInSeconds = controller.value.duration.inSeconds
            .toDouble();
        if (mounted) {
          setState(() {
            _originalFileSizeBytes = bytes.toDouble();
            _totalDurationMs = controller.value.duration.inMilliseconds
                .toDouble();
            _endValue = _totalDurationMs;

            if (durationInSeconds > 0) {
              double totalBits = _originalFileSizeBytes * 8;
              double bps = totalBits / durationInSeconds; // Bits per second
              double mbps = bps / (1024 * 1024); // Megabits per second
              _bitRate = "${mbps.toStringAsFixed(2)} Mbps";
            } else {
              _bitRate = "0 Mbps";
            }
            _resolution =
            "${controller.value.size.width.toInt()} * ${controller.value.size.height.toInt()}";

            // ✅ ડાયનેમિક સાઈઝ ફોર્મેટર ફંક્શન કોલ
            _fileSize = _getFormattedFileSize(_originalFileSizeBytes);

            _isLoadingVideo = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _generateCoverStrip();
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoadingVideo = false;
          // ✅ Localization Key
          _loadError = context.tr("videoPreviewNotReady");
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoadingVideo = false;
          // ✅ Localization Key
          _loadError = context.tr("videoLoadTimedOut");
        });
      }
    } catch (e) {
      debugPrint("Error loading video: $e");
      if (mounted) {
        setState(() {
          _isLoadingVideo = false;
          // ✅ Localization Key
          _loadError = context.tr("failedToLoadVideo");
        });
      }
    }
  }

  String _getFormattedFileSize(double bytes) {
    if (bytes < 1024) {
      return "${bytes.toStringAsFixed(2)} B";
    } else if (bytes < 1024 * 1024) {
      return "${(bytes / 1024).toStringAsFixed(2)} KB";
    } else if (bytes < 1024 * 1024 * 1024) {
      return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
    } else {
      return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
    }
  }

  void _videoListener() {
    if (!mounted || _trimmer.videoPlayerController == null) return;

    try {
      final controller = _trimmer.videoPlayerController!;
      if (controller.value.isInitialized) {
        if (_isPlaying != controller.value.isPlaying) {
          setState(() {
            _isPlaying = controller.value.isPlaying;
          });
        }
      }
    } catch (e) {
      debugPrint("Listener error catch: $e");
    }
  }

  String _getEstimateSize() {
    if (_trimmer.videoPlayerController == null) return _fileSize;

    final totalDurationMs =
        _trimmer.videoPlayerController!.value.duration.inMilliseconds;
    final trimDurationMs = _endValue - _startValue;

    if (totalDurationMs <= 0) return _fileSize;

    double estimatedBytes =
        (_originalFileSizeBytes / totalDurationMs) * trimDurationMs;
    double estimatedMB = estimatedBytes / (1024 * 1024);

    return "${estimatedMB.toStringAsFixed(2)} MB";
  }

  void _updateEstimate() {
    if (_totalDurationMs <= 0) return;
    double trimDurationMs = _endValue - _startValue;
    double estimatedBytes =
        (_originalFileSizeBytes / _totalDurationMs) * trimDurationMs;
    double estimatedMB = estimatedBytes / (1024 * 1024);
    _estimateSizeNotifier.value = "${estimatedMB.toStringAsFixed(2)} MB";
  }

  @override
  Widget build(BuildContext context) {
    // AppThemeColors colors = Theme.of(context).extension<AppThemeColors>()!;

    return WillPopScope(
      onWillPop: () async {
        await _trimmer.videoPlayerController?.pause();
        if (_isTrimmed) {
          _showDiscardDialog();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isSuccess
            ? _buildSuccessUI()
            : Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Center(
                child:
                (_trimmer.videoPlayerController != null &&
                    _trimmer
                        .videoPlayerController!
                        .value
                        .isInitialized &&
                    !_isLoadingVideo)
                    ? VideoViewer(trimmer: _trimmer)
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_loadError == null)
                      const CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    const SizedBox(height: 10),
                    AppText(
                      _loadError ?? "loadingVideo",
                      color: Colors.white,
                      align: TextAlign.center,
                    ),
                    if (_loadError != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _loadVideo,
                        child: const AppText("retry"),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  TrimViewer(
                    trimmer: _trimmer,
                    viewerWidth: MediaQuery.of(context).size.width,
                    onChangeStart: (value) async {
                      _startValue = value;
                      _updateEstimate();

                      final controller = _trimmer.videoPlayerController;
                      if (controller != null &&
                          controller.value.isPlaying) {
                        await controller.pause();
                        // Safe setState using addPostFrameCallback
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _isPlaying = false);
                        });
                      }

                      if (!_isTrimmed) {
                        _isTrimmed = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() {});
                        });
                      }
                    },
                    onChangeEnd: (value) {
                      _endValue = value;
                      _updateEstimate();

                      if (!_isTrimmed) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _isTrimmed = true);
                        });
                      }
                    },
                    onChangePlaybackState: (value) {
                      // Safe setState for playback state
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _isPlaying = value;
                          });
                        }
                      });
                    },
                  ),
                  _buildCoverThumbnailStrip(),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      print("in side ontap ==> ");
                      final controller = _trimmer.videoPlayerController;
                      if (controller != null &&
                          controller.value.isInitialized) {
                        print("in side if 1 st==> ");
                        if (controller.value.isPlaying) {
                          print("in side if ==> ");
                          await controller.pause();
                        } else {
                          print("in side else ==> ");
                          if (controller.value.position >=
                              Duration(milliseconds: _endValue.toInt())) {
                            await controller.seekTo(
                              Duration(milliseconds: _startValue.toInt()),
                            );
                          }
                          await controller.play();
                        }
                        setState(() {
                          _isPlaying = controller.value.isPlaying;
                        });
                      } else {
                        _loadVideo();
                      }
                    },
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  String _formatDuration(double milliseconds) {
    Duration duration = Duration(milliseconds: milliseconds.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  /// Uses the cover the user picked; falls back to first frame of saved file.
  Widget _buildSuccessCoverPreview() {
    final mem = _selectedCoverPreviewBytes;
    if (mem != null && mem.isNotEmpty) {
      return Image.memory(
        mem,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildSuccessCoverFromExportedVideo(),
      );
    }
    final f = _selectedCoverFile;
    if (f != null && f.existsSync()) {
      return Image.file(
        f,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildSuccessCoverFromExportedVideo(),
      );
    }
    return _buildSuccessCoverFromExportedVideo();
  }

  Widget _buildSuccessCoverFromExportedVideo() {
    return FutureBuilder<Uint8List?>(
      future: VideoThumbnail.thumbnailData(
        video: _savedVideoPath,
        imageFormat: ImageFormat.JPEG,
        quality: 85,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(
          color: Colors.white10,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

  Widget _buildSuccessUI() {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          // --- Top Bar ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                  const Expanded(
                    child: AppText(
                      "exportSuccess",
                      align: TextAlign.center,
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // --- Main Content Area ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: 25,
                      ),
                      SizedBox(width: 15),
                      const AppText(
                        "savedSuccessfully",
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Video Card with Thumbnail
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: _buildSuccessCoverPreview(),
                          ),
                        ),
                        if (_selectedCoverFile != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${context.tr('coverPreviewAt')} ${_formatDuration(_selectedCoverTime)}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildDetailItem(
                                "durationUpper",
                                _formatDuration(_endValue - _startValue),
                              ),
                              _buildDetailItem("sizeUpper", _getEstimateSize()),
                              _buildDetailItem("format", "mp4"),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: AppText(
                              "fileLocation",
                              color: Colors.white38,
                              fontSize: 10,
                              align: TextAlign.start,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: AppText(
                              _savedVideoPath,
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                  Spacer(),
                  // --- 5 Social Direct Buttons ---
                  AppButton(
                    title: "share",
                    onTap: () => Share.shareXFiles([XFile(_savedVideoPath)]),
                  ),
                  Spacer(),
                ],
              ),
            ),
          ),

          // --- Ad Section ---
          Container(
            width: double.infinity,
            // height: 250,
            margin: const EdgeInsets.only(bottom: 10),
            child: Center(
              child: SizedBox(
                width: double.infinity,
                child: AdHelper.bannerAdWidget(size: AdSize.mediumRectangle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          label,
          color: Colors.white38,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
        const SizedBox(height: 4),
        AppText(
          value,
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      height: isLandscape ? 60 : 100,
      padding: EdgeInsets.only(top: isLandscape ? 0 : 30, left: 10, right: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
            onPressed: () async {
              final controller = _trimmer.videoPlayerController;
              if (controller != null && controller.value.isInitialized) {
                if (controller.value.isPlaying) {
                  await controller.pause();
                }
              }
              if (_isTrimmed) {
                _showDiscardDialog();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Spacer(),

          // --- Export Settings Dropdown ---
          Theme(
            data: Theme.of(context).copyWith(cardColor: Colors.grey[900]),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
                maxWidth: MediaQuery.of(context).size.width,
              ),
              menuPadding: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              splashRadius: 0.0,
              color: colors.grey1,
              popUpAnimationStyle: AnimationStyle(
                curve: Curves.easeOutQuart,
                duration: const Duration(milliseconds: 400),
                reverseCurve: Curves.easeInQuart,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    "exportSettings",
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),

              itemBuilder: (context) => [
                _buildPopupItem("resolution", _resolution),
                _buildPopupItem("frameRate", "fps30"),
                _buildPopupItem("format", "mp4"),
                _buildPopupItem("bitRate", _bitRate),
                // const PopupMenuDivider(height: 20),
                _buildPopupItem("estimateSize", _estimateSize, isBold: true),
              ],
            ),
          ),

          const Spacer(),
          TextButton(
            onPressed: (!_isTrimmed || _isSaving)
                ? null
                : () async {
              final controller = _trimmer.videoPlayerController;
              if (controller != null &&
                  controller.value.isInitialized &&
                  controller.value.isPlaying) {
                await controller.pause();
                if (mounted) setState(() => _isPlaying = false);
              }
              _showAdDialog();
            },

            child: AppText(
              "saveUpper",

              color: (!_isTrimmed || _isSaving) ? Colors.grey : colors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      String title,
      String value, {
        bool isBold = false,
      }) {
    return PopupMenuItem(
      enabled: false,
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(context.tr(title), color: Colors.white70, fontSize: 12),
            AppText(
              value,

              color: Colors.white,
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
            ),
          ],
        ),
      ),
    );
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final themeColors = Theme.of(
          dialogContext,
        ).extension<AppThemeColors>()!;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            _progressTimer?.cancel();
            _progressTimer = Timer.periodic(const Duration(milliseconds: 600), (
                timer,
                ) {
              if (_currentPercentage < 95) {
                if (mounted) {
                  setDialogState(() {
                    _currentPercentage += 2.0;
                  });
                }
              }
            });

            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                backgroundColor: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppText(
                      "exportingVideo",
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 25),

                    // Percentage Text
                    AppText(
                      "${_currentPercentage.toInt()}%",

                      color: themeColors.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 15),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _currentPercentage / 100,
                        backgroundColor: Colors.white10,
                        color: themeColors.primary,
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppText(
                      "processingPleaseDoNotClose",
                      align: TextAlign.center,
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //////////////////////////////////// part 2 new video trim scareen/////////////////////////////////////////////////////////////////////////////////////////////

  _saveVideo() async {
    final exportBase =
        _pendingExportBaseName ??
            'trimmed_${DateTime.now().millisecondsSinceEpoch}';

    _currentPercentage = 0.0;
    if (!mounted) return;
    setState(() => _isSaving = true);
    await _trimmer.videoPlayerController?.pause();
    if (mounted) setState(() => _isPlaying = false);
    _showProcessingDialog();

    try {
      await _trimmer.saveTrimmedVideo(
        startValue: _startValue,
        endValue: _endValue,
        videoFileName: exportBase,
        storageDir: StorageDir.temporaryDirectory,
        onSave: (outputPath) async {
          _progressTimer?.cancel();
          if (Navigator.canPop(context)) Navigator.pop(context);

          if (!mounted) return;
          if (outputPath != null && outputPath.isNotEmpty) {
            try {
              await Gal.putVideo(outputPath);
              final mem = _selectedCoverPreviewBytes;
              if (mem != null && mem.isNotEmpty) {
                await CustomVideoThumbnailStore.registerPendingOverride(
                  baseName: exportBase,
                  jpegBytes: mem,
                );
              }
              if (mounted) {
                setState(() {
                  _isSuccess = true;
                  _savedVideoPath = outputPath;
                  _isSaving = false;
                });
              }
            } catch (e) {
              debugPrint('Gal.putVideo: $e');
              if (mounted) {
                setState(() => _isSaving = false);
                AppToast.show(
                  context,
                  context.tr("failedToSaveVideoGallery"),
                  type: ToastType.error,
                );
              }
            }
          } else {
            if (mounted) setState(() => _isSaving = false);
          }
        },
      );
    } catch (e) {
      debugPrint('saveTrimmedVideo: $e');
      _progressTimer?.cancel();
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.show(
          context,
          context.tr("couldNotExportVideo"),
          type: ToastType.error,
        );
      }
    } finally {
      _pendingExportBaseName = null;
    }
  }

  void _showAdDialog() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    if (_exportFileNameController.text.trim().isEmpty) {
      _exportFileNameController.text = _defaultExportBaseName();
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              CircleAvatar(
                radius: 30,
                backgroundColor: colors.primary,
                child: const Icon(
                  Icons.save_alt,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const AppText(
                "saveVideo",
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: AppText(
                  'trimExportFileName',
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _exportFileNameController,
                style: const TextStyle(color: Colors.white),
                cursorColor: colors.primary,
                decoration: InputDecoration(
                  hintText: context.tr('trimExportFileNameHint'),
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const AppText(
                "watchAddToSaveVideos",
                align: TextAlign.center,
                color: Colors.white70,
                fontSize: 14,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final sanitized = _sanitizeExportBaseName(
                    _exportFileNameController.text,
                  );
                  if (sanitized.isEmpty ||
                      sanitized.replaceAll('_', '').isEmpty) {
                    AppToast.show(
                      context,
                      context.tr('trimExportInvalidName'),
                      type: ToastType.error,
                    );
                    return;
                  }
                  _pendingExportBaseName = sanitized;
                  FocusManager.instance.primaryFocus?.unfocus();
                  await _trimmer.videoPlayerController?.pause();
                  if (mounted) setState(() => _isPlaying = false);
                  Navigator.pop(dialogContext);
                  _playRewardedAd();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.whiteColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                label: AppText(
                  context.tr('trimExportContinue'),

                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const AppText("mayBeLater", color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playRewardedAd() {
    AdHelper.showRewardedAd(
      context,
          () {
        _actualSaveProcess();
      },
      errorFunction: () {
        _actualSaveProcess();
      },
    );
  }

  void _actualSaveProcess() {
    _saveVideo();
  }

  void _showDiscardDialog() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 25,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: colors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            // Ã Â«Â¨. Title & Message
            const AppText(
              "discardChanges",
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 12),
            AppText(
              "yourTimingProgressWillBeLost",
              align: TextAlign.center,

              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
            const SizedBox(height: 30),

            // Ã Â«Â©. Buttons Row
            Row(
              children: [
                // Keep Editing Button (Cancel)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: AppText(
                      "keepEditing",
                      color: colors.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Discard Button (Confirm)
                // Discard Button (Confirm)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      playerService.controller?.play();
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: AppText(
                      "discard",
                      color: colors.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _exportFileNameController.dispose();
    _progressTimer?.cancel();

    _trimmer.videoPlayerController?.removeListener(_videoListener);
    _didAttachVideoListener = false;

    if (_trimmer.videoPlayerController != null) {
      _trimmer.videoPlayerController!.pause();
    }

    _estimateSizeNotifier.dispose();
    _exportProgress.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }
}



/*
import '../utils/app_imports.dart';

class VideoTrimScreen extends StatefulWidget {
  final File file;

  const VideoTrimScreen({super.key, required this.file});

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> {
  final playerService = GlobalPlayerService();
  final Trimmer _trimmer = Trimmer();
  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _isSaving = false;

  File? _selectedCoverFile;
  double _selectedCoverTime = 0.0;
  bool _isCoverSelecting = false;
  double _coverPos = 0.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadVideo();
  }

  void _setVideoCover() async {
    final String? path = await VideoThumbnail.thumbnailFile(
      video: widget.file.path,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.JPEG,
      timeMs: _startValue.toInt(),
      quality: 90,
    );

    if (mounted && path != null) {
      setState(() {
        _selectedCoverFile = File(path);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cover frame captured! ÃƒÂ°Ã…Â¸Ã¢â‚¬Å“Ã‚Â¸")),
      );
    }
  }

  void _loadVideo() async {
    await _trimmer.loadVideo(videoFile: widget.file);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Scaffold(
      backgroundColor: Colors.black,
      // appBar: AppBar(
      //   title: const Text("Trim Video"),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.check),
      //       onPressed: () async {
      //         setState(() => _isSaving = true);
      //
      //         final directory = await getTemporaryDirectory();
      //         final String fileName =
      //             "trimmed_video_${DateTime.now().millisecondsSinceEpoch}.mp4";
      //         final String savePath = directory.path;
      //
      //         try {
      //           await _trimmer.saveTrimmedVideo(
      //             startValue: _startValue,
      //             endValue: _endValue,
      //             videoFileName: fileName,
      //             storageDir: StorageDir.temporaryDirectory,
      //
      //             onSave: (outputPath) async {
      //               if (mounted) {
      //                 setState(() => _isSaving = false);
      //
      //                 if (outputPath != null && outputPath.isNotEmpty) {
      //                   try {
      //                     // Check for Gallery Access
      //                     bool hasAccess = await Gal.hasAccess();
      //                     if (!hasAccess) {
      //                       await Gal.requestAccess();
      //                     }
      //
      //                     // Save Video to Gallery
      //                     await Gal.putVideo(outputPath);
      //
      //                     // Success Message
      //                     ScaffoldMessenger.of(context).showSnackBar(
      //                       const SnackBar(
      //                         content: Text(
      //                           "Video saved successfully to gallery! Ã¢Å“â€¦",
      //                         ),
      //                         backgroundColor: Colors.green,
      //                         behavior: SnackBarBehavior
      //                             .floating, // Option: Looks better on modern UI
      //                       ),
      //                     );
      //
      //                     Navigator.pop(context, outputPath);
      //                   } catch (e) {
      //                     // Error during saving process
      //                     AppToast.show(
      //                       context,
      //                       "Failed to save video to gallery. Please try again.",
      //                       type: ToastType.error,
      //                     );
      //                     // Optional: Log the error for debugging
      //                     debugPrint("Gallery Save Error: $e");
      //                   }
      //                 } else {
      //                   // Path not found error
      //                   AppToast.show(
      //                     context,
      //                     "Save failed: The output file path is missing.",
      //                     type: ToastType.error,
      //                   );
      //                 }
      //               }
      //             },
      //           );
      //         } catch (e) {
      //           if (mounted) {
      //             setState(() => _isSaving = false);
      //             AppToast.show(
      //               context,
      //               "Trimming Error: $e",
      //               type: ToastType.error,
      //             );
      //           }
      //         }
      //       },
      //     ),
      //   ],
      // ),
      body: Column(
        children: [

          _buildTopBar(),
          Expanded(child: VideoViewer(trimmer: _trimmer)),
          SizedBox(height: 16,),
          Container(
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(12),topRight: Radius.circular(12))),

            child: Column(
              children: [
                SizedBox(height: 16,),
                Center(
                  child: TrimViewer(
                    editorProperties: TrimEditorProperties(borderPaintColor:colors.primary,scrubberWidth: 2,),
                    trimmer: _trimmer,
                    // viewerHeight: 50.0,

                    viewerWidth: MediaQuery.of(context).size.width,
                    onChangeStart: (value) => _startValue = value,
                    onChangeEnd: (value) => _endValue = value,
                    onChangePlaybackState: (value) =>
                        setState(() => _isPlaying = value),
                  ),
                ),
                 SizedBox(height: 16,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // if (_selectedCoverFile != null)
                    //   ClipRRect(
                    //     borderRadius: BorderRadius.circular(4),
                    //     child: Image.file(
                    //       _selectedCoverFile!,
                    //       height: 50,
                    //       width: 40,
                    //       fit: BoxFit.cover,
                    //     ),
                    //   ),
                    // const SizedBox(width: 20),

                    GestureDetector(
                      onTap: () async {
                        bool playbackState = await _trimmer.videoPlaybackControl(
                          startValue: _startValue,
                          endValue: _endValue,
                        );
                        setState(() => _isPlaying = playbackState);
                      },
                      child:  AppImage(
                        src: _isPlaying
                            ? AppSvg.pauseVid
                            : AppSvg.playVid,
                        height: 45,
                        width: 45,
                      ),
                    ),

                    // const SizedBox(width: 20),
                    //
                    // Column(
                    //   children: [
                    //     IconButton(
                    //       icon: const Icon(
                    //         Icons.add_a_photo_outlined,
                    //         color: Colors.white,
                    //         size: 30,
                    //       ),
                    //       onPressed: _setVideoCover,
                    //     ),
                    //     const Text(
                    //       "Cover",
                    //       style: TextStyle(color: Colors.white, fontSize: 10),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          )

        ],
      ),
    );
  }


  Widget _buildTopBar() {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      height: isLandscape ? 60 : 100,
      padding: EdgeInsets.only(top: isLandscape ? 0 : 30, left: 0, right: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              playerService.playlist[playerService.currentIndex].title ??
                  "Playing Video",
              style: TextStyle(
                color: Colors.white,
                fontSize: isLandscape ? 16 : 18,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          TextButton(
            onPressed: _isSaving ? null : _saveVideo,
            child: const Text("SAVE", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  _saveVideo()async{

      setState(() => _isSaving = true);

      final directory = await getTemporaryDirectory();
      final String fileName =
          "trimmed_video_${DateTime.now().millisecondsSinceEpoch}.mp4";
      final String savePath = directory.path;

      try {
        await _trimmer.saveTrimmedVideo(
          startValue: _startValue,
          endValue: _endValue,
          videoFileName: fileName,
          storageDir: StorageDir.temporaryDirectory,

          onSave: (outputPath) async {
            if (mounted) {
              setState(() => _isSaving = false);

              if (outputPath != null && outputPath.isNotEmpty) {
                try {
                  // Check for Gallery Access
                  bool hasAccess = await Gal.hasAccess();
                  if (!hasAccess) {
                    await Gal.requestAccess();
                  }

                  // Save Video to Gallery
                  await Gal.putVideo(outputPath);

                  // Success Message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Video saved successfully to gallery! Ã¢Å“â€¦",
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior
                          .floating, // Option: Looks better on modern UI
                    ),
                  );

                  Navigator.pop(context, outputPath);
                } catch (e) {
                  // Error during saving process
                  AppToast.show(
                    context,
                    "Failed to save video to gallery. Please try again.",
                    type: ToastType.error,
                  );
                  // Optional: Log the error for debugging
                  debugPrint("Gallery Save Error: $e");
                }
              } else {
                // Path not found error
                AppToast.show(
                  context,
                  "Save failed: The output file path is missing.",
                  type: ToastType.error,
                );
              }
            }
          },
        );
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          AppToast.show(
            context,
            "Trimming Error: $e",
            type: ToastType.error,
          );
        }
      }
  }
}

 */

