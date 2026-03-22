import 'dart:math' as Math;

import '../services/ads_service.dart';
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
  bool _isTrimmed = false; // àª¶à«àª‚ àª¯à«àªàª°à«‡ àªŸà«àª°à«€àª®àª¿àª‚àª— àª•àª°à«àª¯à«àª‚ àª›à«‡?

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadVideo();
  }

  // àª† àª«àª‚àª•à«àª¶àª¨ àªŸà«àª°à«€àª® àª•àª°à«‡àª²àª¾ àª­àª¾àª—àª¨à«€ àª¸àª¾àªˆàª àª—àª£àª¶à«‡
  String get _estimateSize {
    if (_totalDurationMs <= 0) return "0 B";

    // àªŸà«àª°à«€àª® àª•àª°à«‡àª²à«‹ àª¸àª®àª¯: (End - Start)
    double trimDurationMs = _endValue - _startValue;

    // àª¸à«‚àª¤à«àª°: (àª•à«àª² àª¬àª¾àªˆàªŸà«àª¸ / àª•à«àª² àª¸àª®àª¯) * àªŸà«àª°à«€àª® àª•àª°à«‡àª²à«‹ àª¸àª®àª¯
    double estimatedBytes =
        (_originalFileSizeBytes / _totalDurationMs) * trimDurationMs;

    // àªœà«‹ àªŸà«àª°à«€àª® àª•àª°à«‡àª²à«€ àª¸àª¾àªˆàª àª¨à«‡àª—à«‡àªŸàª¿àªµ àª•à«‡ àª…àªœà«€àª¬ àª¹à«‹àª¯ àª¤à«‹ àª¸à«‡àª«à«àªŸà«€ àªšà«‡àª•
    if (estimatedBytes < 0) return "0 B";

    // àª†àªªà«‹àª†àªª KB, MB àª•à«‡ GB àª®àª¾àª‚ àª•àª¨à«àªµàª°à«àªŸ àª•àª°àª¶à«‡
    return _formatBytes(estimatedBytes);
  }

  String _formatBytes(double bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (Math.log(bytes) / Math.log(1024)).floor();
    return "${(bytes / Math.pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}";
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
        const SnackBar(content: Text("Cover frame captured! Ã°Å¸â€œÂ¸")),
      );
    }
  }

  void _loadVideo() async {
    try {
      // àªµàª¿àª¡àª¿àª¯à«‹ àª²à«‹àª¡ àª•àª°àªµàª¾àª¨à«àª‚ àª¶àª°à«‚ àª•àª°à«‹
      await _trimmer.loadVideo(videoFile: widget.file);

      // àª•àª‚àªŸà«àª°à«‹àª²àª° àª¤à«ˆàª¯àª¾àª° àª¥àª¾àª¯ àª¤à«àª¯àª¾àª‚ àª¸à«àª§à«€ àª°àª¾àª¹ àªœà«àª“
      int retryCount = 0;
      while (_trimmer.videoPlayerController == null ||
          !_trimmer.videoPlayerController!.value.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 200));
        retryCount++;
        if (retryCount > 25) break; // 5 àª¸à«‡àª•àª¨à«àª¡ àªªàª›à«€ àª…àªŸàª•à«€ àªœàª¶à«‡
      }

      final controller = _trimmer.videoPlayerController;
      if (controller != null && mounted) {
        final num bytes = await widget.file.length();
        final duration = controller.value.duration;

        setState(() {
          _originalFileSizeBytes = bytes.toDouble();
          _totalDurationMs = duration.inMilliseconds.toDouble();
          _endValue = _totalDurationMs;

          // Bitrate & Resolution
          double mbps = (bytes * 8) / (duration.inSeconds * 1024 * 1024);
          _bitRate = "${mbps.toStringAsFixed(2)} Mbps";
          _resolution =
          "${controller.value.size.width.toInt()} * ${controller.value.size.height.toInt()}";
          _fileSize =
          "${(_originalFileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB";
        });
      }
    } catch (e) {
      debugPrint("Error loading video: $e");
    }
  }

  String _getEstimateSize() {
    if (_trimmer.videoPlayerController == null) return _fileSize;

    final totalDurationMs =
        _trimmer.videoPlayerController!.value.duration.inMilliseconds;
    final trimDurationMs = _endValue - _startValue;

    if (totalDurationMs <= 0) return _fileSize;

    // àªŸà«àª°à«€àª® àª•àª°à«‡àª²àª¾ àª­àª¾àª—àª¨à«€ àª¸àª¾àªˆàª àª—àª£à«‹
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

    // àª†àª¨àª¾àª¥à«€ àª®àª¾àª¤à«àª° àª®à«‡àª¨à«àª¨à«€ àª…àª‚àª¦àª°àª¨à«€ àªŸà«‡àª•à«àª¸à«àªŸ àª¬àª¦àª²àª¾àª¶à«‡, àª†àª–à«àª‚ UI àª¨àª¹à«€àª‚
    _estimateSizeNotifier.value = "${estimatedMB.toStringAsFixed(2)} MB";
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return WillPopScope(
      onWillPop: () async {
        if (_isTrimmed) {
          _showDiscardDialog();
          return false;
        } else {
          // àªœà«‹ àª•à«‹àªˆ àªšà«‡àª¨à«àªœ àª¨àª¥à«€ àª…àª¨à«‡ àª¡àª¾àª¯àª°à«‡àª•à«àªŸ àª¬à«‡àª• àªœàª¾àª¯ àª›à«‡, àª¤à«‹ àªªàª£ àªªà«àª²à«‡àª¯àª° àªšàª¾àª²à« àª•àª°à«€ àª¦à«‡àªµà«‹
          playerService.controller!.play();
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,

        body: Column(
          children: [
            _buildTopBar(),
            // build àª®à«‡àª¥àª¡àª¨à«€ àª…àª‚àª¦àª°:
            Expanded(
              child:
              _trimmer.videoPlayerController != null &&
                  _trimmer.videoPlayerController!.value.isInitialized
                  ? RepaintBoundary(child: VideoViewer(trimmer: _trimmer))
                  : const Center(
                child: CircularProgressIndicator(
                  color: Colors.blueAccent,
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),

              child: Column(
                children: [
                  SizedBox(height: 16),
                  Center(
                    child: TrimViewer(
                      editorProperties: TrimEditorProperties(
                        borderPaintColor: colors.primary,
                        scrubberWidth: 2,
                      ),
                      trimmer: _trimmer,
                      viewerWidth: MediaQuery.of(context).size.width,
                     onChangeStart: (value) {
                        _startValue = value;
                        _updateEstimate();
                        if (!_isTrimmed)
                          setState(
                                () => _isTrimmed = true,
                          );
                        },
                      onChangeEnd: (value) {
                        _endValue = value;
                        _updateEstimate();
                        if (!_isTrimmed) setState(() => _isTrimmed = true);
                      },
                      onChangePlaybackState: (value) =>
                          setState(() => _isPlaying = value),
                    ),
                  ),
                  SizedBox(height: 16),
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
                          bool playbackState = await _trimmer
                              .videoPlaybackControl(
                            startValue: _startValue,
                            endValue: _endValue,
                          );
                          setState(() => _isPlaying = playbackState);
                        },
                        child: AppImage(
                          src: _isPlaying ? AppSvg.pauseVid : AppSvg.playVid,
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
            ),
          ],
        ),
      ),
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
            onPressed: () {
              if (_isTrimmed) {
                _showDiscardDialog();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Spacer(),

          // --- Export Settings Dropdown ---
          // --- Export Settings Dropdown ---
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: Colors.grey[900],
            ),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(
                  context,
                ).size.width,
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
                  Text(
                    "Export Settings",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
                _buildPopupItem("Resolution", _resolution),
                _buildPopupItem("Frame Rate", "30 FPS"),
                _buildPopupItem("Format", "MP4"),
                _buildPopupItem("Bit Rate", _bitRate),
                // const PopupMenuDivider(height: 20),
                 _buildPopupItem("Estimate Size", _estimateSize, isBold: true),
              ],
            ),
          ),

          const Spacer(),
          TextButton(
            onPressed: (!_isTrimmed || _isSaving) ? null : _showAdDialog,
            child: Text(
              "SAVE",
              style: TextStyle(
                color: (!_isTrimmed || _isSaving)
                    ? Colors.grey
                    : Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
            Text(title, style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
              ),
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
      builder: (context) {
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
                    const Text(
                      "Exporting Video...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Percentage Text
                    Text(
                      "${_currentPercentage.toInt()}%",
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _currentPercentage / 100,
                        backgroundColor: Colors.white10,
                        color: Colors.blueAccent,
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Processing... Please do not close the app",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
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

  _saveVideo() async {
    _currentPercentage = 0.0; // Reset
    _showProcessingDialog();

    try {
      await _trimmer.saveTrimmedVideo(
        startValue: _startValue,
        endValue: _endValue,
        videoFileName: "trimmed_${DateTime.now().millisecondsSinceEpoch}",
        storageDir: StorageDir.temporaryDirectory,
        onSave: (outputPath) async {
          _progressTimer?.cancel();

          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          if (outputPath != null && outputPath.isNotEmpty) {
            try {
              await Gal.putVideo(outputPath);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Video saved to gallery! âœ…"),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );

              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  Navigator.pop(
                    context,
                    outputPath,
                  );
                }
              });
            } catch (e) {
              debugPrint("Gallery Save Error: $e");
            }
          }
        },
      );
    } catch (e) {
      _progressTimer?.cancel();
      Navigator.pop(context);
      debugPrint("Error: $e");
    }
  }

  void _showAdDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            // 1. Save Icon
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.save_alt, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 20),

            // 2. Title & Message
            const Text(
              "Save Video",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Watch Ad to Save 1 video(s)",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 25),

            // 3. Watch Ad Button
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isPlaying = false);
                Navigator.pop(context);
                _playRewardedAd();
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_circle_fill, color: Colors.white),
              label: const Text(
                "Watch Ad to proceed",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 4. Cancel Button (Optional)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Maybe Later",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
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
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
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
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            // à«¨. Title & Message
            const Text(
              "Discard changes?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your trimming progress will be lost. Are you sure you want to exit?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 30),

            // à«©. Buttons Row
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
                    child: const Text(
                      "Keep Editing",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Discard Button (Confirm)
                // Discard Button (Confirm)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // à«§. àªªàª¹à«‡àª²àª¾ àªªà«àª²à«‡àª¯àª°àª¨à«‡ àª°àª¿àªà«àª¯à«àª® àª•àª°à«‹ àªœà«‡àª¥à«€ àª®à«‡àªˆàª¨ àª¸à«àª•à«àª°à«€àª¨ àªªàª° àª²à«‹àª¡àª° àª¨ àª«àª°à«‡
                      playerService.controller
                          ?.play(); // àª“àª°àª¿àªœàª¿àª¨àª² àª«àª¾àªˆàª² àª«àª°à«€ àªªà«àª²à«‡ àª•àª°à«‹

                      // à«¨. àª¡àª¾àª¯àª²à«‹àª— àª¬àª‚àª§ àª•àª°à«‹
                      Navigator.pop(context);

                      // à«©. àªµàª¿àª¡àª¿àª¯à«‹ àªŸà«àª°à«€àª® àª¸à«àª•à«àª°à«€àª¨ àª¬àª‚àª§ àª•àª°à«‹
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Discard",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
    _progressTimer?.cancel();
    _estimateSizeNotifier.dispose();
    _exportProgress.dispose();
    // Trimmer àª†àª‚àª¤àª°àª¿àª• àª•àª‚àªŸà«àª°à«‹àª²àª°àª¨à«‡ àª¹à«‡àª¨à«àª¡àª² àª•àª°à«‡ àª›à«‡, àªªàª£ àª¸à«‡àª«à«àªŸà«€ àª®àª¾àªŸà«‡:
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
        const SnackBar(content: Text("Cover frame captured! Ã°Å¸â€œÂ¸")),
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
      //                           "Video saved successfully to gallery! âœ…",
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
                        "Video saved successfully to gallery! âœ…",
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


