//////////////////////////////////// part 1 new video trim scareen//////////////////////////////////////

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
  final GlobalKey _videoViewerKey = GlobalKey();
  final Trimmer _trimmer = Trimmer();
  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _isSaving = false;

  File? _selectedCoverFile;
  double _selectedCoverTime = 0.0;
  bool _isCoverSelecting = false;
  double _coverPos = 0.0;

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

  @override
  void initState() {
    super.initState();
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
            _loadError = "Video file not found.";
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
            _loadError = "Unable to initialize video preview.";
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
        final double durationInSeconds =
            controller.value.duration.inSeconds.toDouble();
        if (mounted) {
          setState(() {
            _originalFileSizeBytes = bytes.toDouble();
            _totalDurationMs = controller.value.duration.inMilliseconds.toDouble();
            _endValue = _totalDurationMs;

            if (durationInSeconds > 0) {
              double totalBits = _originalFileSizeBytes * 8;
              double bps = totalBits / durationInSeconds; // Bits per second
              double mbps = bps / (1024 * 1024); // Megabits per second
              _bitRate = "${mbps.toStringAsFixed(2)} Mbps";
            } else {
              _bitRate = "0 Mbps";
            }
            _resolution = "${controller.value.size.width.toInt()} * ${controller.value.size.height.toInt()}";
            _fileSize = "${(_originalFileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB";
            _isLoadingVideo = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoadingVideo = false;
          _loadError = "Video preview is not ready.";
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoadingVideo = false;
          _loadError = "Video loading timed out. Please try again.";
        });
      }
    } catch (e) {
      debugPrint("Error loading video: $e");
      if (mounted) {
        setState(() {
          _isLoadingVideo = false;
          _loadError = "Failed to load video.";
        });
      }
    }
  }

// àª† àª«àª‚àª•à«àª¶àª¨àª¨à«‡ àª•à«àª²àª¾àª¸àª®àª¾àª‚ àª…àª²àª—àª¥à«€ àª²àª–à«‹
  void _videoListener() {
    // àªœà«‹ àªµàª¿àªœà«‡àªŸ àª¹àªœà« àª¸à«àª•à«àª°à«€àª¨ àªªàª° àª¹à«‹àª¯ àª…àª¨à«‡ àª•àª‚àªŸà«àª°à«‹àª²àª° àª…àª¸à«àª¤àª¿àª¤à«àªµàª®àª¾àª‚ àª¹à«‹àª¯ àª¤à«‹ àªœ àª†àª—àª³ àªµàª§à«‹
    if (!mounted || _trimmer.videoPlayerController == null) return;

    try {
      final controller = _trimmer.videoPlayerController!;
      // àª…àª¹à«€àª‚ àªšà«‡àª• àª•àª°à«‹ àª•à«‡ àª•àª‚àªŸà«àª°à«‹àª²àª° àª‡àª¨àª¿àª¶àª¿àª¯àª²àª¾àª‡àªà«àª¡ àª›à«‡ àª•à«‡ àª¨àª¹à«€àª‚
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
    double estimatedBytes = (_originalFileSizeBytes / _totalDurationMs) * trimDurationMs;
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
        body:  _isSuccess ? _buildSuccessUI(): Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Center(
                child: (_trimmer.videoPlayerController != null &&
                    _trimmer.videoPlayerController!.value.isInitialized &&
                    !_isLoadingVideo)
                    ? VideoViewer(trimmer: _trimmer)
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_loadError == null)
                      const CircularProgressIndicator(color: Colors.blueAccent),
                    const SizedBox(height: 10),
                    Text(
                      _loadError ?? "Loading Video...",
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    if (_loadError != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _loadVideo,
                        child: const Text("Retry"),
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

                      // àªµàª¿àª¡àª¿àª¯à«‹ àªªà«‹àª àª•àª°àªµàª¾àª¨à«àª‚ àª²à«‹àªœàª¿àª•
                      final controller = _trimmer.videoPlayerController;
                      if (controller != null && controller.value.isPlaying) {
                        await controller.pause();
                        // Safe setState using addPostFrameCallback
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _isPlaying = false);
                        });
                      }

                      if (!_isTrimmed) {
                        _isTrimmed = true; // àªªà«‡àª²àª¾ àªµà«‡àª°à«€àªàª¬àª² àª¬àª¦àª²à«‹
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() {}); // àªªàª›à«€ àªàª• àªœ àªµàª¾àª° àª°àª¿àª¬àª¿àª²à«àª¡ àª•àª°à«‹
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
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      print("in side ontap ==> ");
                      final controller = _trimmer.videoPlayerController;
                      if (controller != null && controller.value.isInitialized) {
                        print("in side if 1 st==> ");
                        if (controller.value.isPlaying) {
                          print("in side if ==> ");
                          await controller.pause();
                        } else {
                          print("in side else ==> ");
                          // àªœà«‹ àªµàª¿àª¡àª¿àª¯à«‹ àª›à«‡àª²à«àª²à«€ àª°à«‡àª¨à«àªœ (endValue) àªªàª° àªªàª¹à«‹àª‚àªšà«€ àª—àª¯à«‹ àª¹à«‹àª¯, àª¤à«‹ àª«àª°à«€àª¥à«€ startValue àª¥à«€ àª¶àª°à«‚ àª•àª°à«‹
                          if (controller.value.position >= Duration(milliseconds: _endValue.toInt())) {
                            await controller.seekTo(Duration(milliseconds: _startValue.toInt()));
                          }
                          await controller.play();
                        }
                        setState(() {
                          _isPlaying = controller.value.isPlaying;
                        });
                      }
                      else {
                        _loadVideo();
                      }
                    },
                    child: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
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

  // Duration àª«à«‹àª°à«àª®à«‡àªŸ àª®àª¾àªŸà«‡ àª«àª‚àª•à«àª¶àª¨
  String _formatDuration(double milliseconds) {
    Duration duration = Duration(milliseconds: milliseconds.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
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
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text("Export Success",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                      const Icon(Icons.check_circle, color: Colors.greenAccent, size: 25),
                      SizedBox(width: 15,),
                      const Text("Saved Successfully!",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: FutureBuilder<Uint8List?>(
                              future: VideoThumbnail.thumbnailData(
                                video: _savedVideoPath,
                                imageFormat: ImageFormat.JPEG,
                                quality: 85,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                return Container(color: Colors.white10, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // HH:MM:SS àª«à«‹àª°à«àª®à«‡àªŸ àª…àª¹à«€àª‚ àªµàªªàª°àª¾àª¶à«‡
                              _buildDetailItem("DURATION", _formatDuration(_endValue - _startValue)),
                              _buildDetailItem("SIZE", _getEstimateSize()),
                              _buildDetailItem("FORMAT", "MP4"),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: AppText("File Location",color: Colors.white38,
                              fontSize: 10,
                              align: TextAlign.start,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 5),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: AppText(_savedVideoPath,color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,),
                          ),
                        ),
                        SizedBox(height: 10,),
                      ],
                    ),
                  ),
                  Spacer(),
                  // --- 5 Social Direct Buttons ---
                  AppButton(title: "share", onTap: () => Share.shareXFiles([XFile(_savedVideoPath)]),),
                  Spacer(),

                  // ElevatedButton.icon(
                  //   onPressed: () => Share.shareXFiles([XFile(_savedVideoPath)]),
                  //   icon: const Icon(Icons.share, size: 18),
                  //   label: const Text("Share"),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.blueAccent,
                  //     foregroundColor: Colors.white,
                  //     padding: const EdgeInsets.symmetric(vertical: 14),
                  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  //     elevation: 0,
                  //   ),
                  // ),

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
      crossAxisAlignment: CrossAxisAlignment.start, // àª²àª–àª¾àª£ àª¡àª¾àª¬à«€ àª¬àª¾àªœà« àª°àª¾àª–àªµàª¾
      mainAxisSize: MainAxisSize.min,
      children: [
        // àª‰àªªàª°àª¨à«àª‚ àª²à«‡àª¬àª² (àª¨àª¾àª¨àª¾ àª…àª•à«àª·àª°à«‹àª®àª¾àª‚)
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38, // àª†àª›à«‹ àª¸àª«à«‡àª¦ àª•àª²àª°
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        // àª¨à«€àªšà«‡àª¨à«€ àª•àª¿àª‚àª®àª¤ (àª˜àª¾àªŸàª¾ àª¸àª«à«‡àª¦ àª…àª•à«àª·àª°à«‹àª®àª¾àª‚)
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
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
            // onPressed: (!_isTrimmed || _isSaving) ? null : _showAdDialog,
            onPressed: (!_isTrimmed || _isSaving) ? null :()async{


              final controller = _trimmer.videoPlayerController;
              if (controller != null && controller.value.isInitialized) {
                if (controller.value.isPlaying) {
                  await controller.pause();
                } else {
                  await controller.play();
                }
                // setState àª•àª°àªµàª¾àª¨à«€ àªœàª°à«‚àª° àª¨àª¥à«€ àª•àª¾àª°àª£ àª•à«‡ àª†àªªàª£à«‡ controller.addListener àª‰àª®à«‡àª°à«àª¯à«àª‚ àª›à«‡
              }
              _showAdDialog();},

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
  //////////////////////////////////// part 2 new video trim scareen/////////////////////////////////////////////////////////////////////////////////////////////

  _saveVideo() async {
    _currentPercentage = 0.0;
    _showProcessingDialog();

    try {
      await _trimmer.saveTrimmedVideo(
        startValue: _startValue,
        endValue: _endValue,
        videoFileName: "trimmed_${DateTime.now().millisecondsSinceEpoch}",
        storageDir: StorageDir.temporaryDirectory,
        onSave: (outputPath) async {
          _progressTimer?.cancel();
          if (Navigator.canPop(context)) Navigator.pop(context); // àª²à«‹àª¡àª¿àª‚àª— àª¡àª¾àª¯àª²à«‹àª— àª¬àª‚àª§ àª•àª°à«‹

          if (outputPath != null && outputPath.isNotEmpty) {
            await Gal.putVideo(outputPath);
            setState(() {
              _isSuccess = true;
              _savedVideoPath = outputPath;
            });
          }
        },
      );
    } catch (e) {
      _progressTimer?.cancel();
      if (Navigator.canPop(context)) Navigator.pop(context);
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

            // Ã Â«Â¨. Title & Message
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
                      // Ã Â«Â§. Ã ÂªÂªÃ ÂªÂ¹Ã Â«â€¡Ã ÂªÂ²Ã ÂªÂ¾ Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡Ã ÂªÂ¯Ã ÂªÂ°Ã ÂªÂ¨Ã Â«â€¡ Ã ÂªÂ°Ã ÂªÂ¿Ã ÂªÂÃ Â«ÂÃ ÂªÂ¯Ã Â«ÂÃ ÂªÂ® Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹ Ã ÂªÅ“Ã Â«â€¡Ã ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ®Ã Â«â€¡Ã ÂªË†Ã ÂªÂ¨ Ã ÂªÂ¸Ã Â«ÂÃ Âªâ€¢Ã Â«ÂÃ ÂªÂ°Ã Â«â‚¬Ã ÂªÂ¨ Ã ÂªÂªÃ ÂªÂ° Ã ÂªÂ²Ã Â«â€¹Ã ÂªÂ¡Ã ÂªÂ° Ã ÂªÂ¨ Ã ÂªÂ«Ã ÂªÂ°Ã Â«â€¡
                      playerService.controller
                          ?.play(); // Ã Âªâ€œÃ ÂªÂ°Ã ÂªÂ¿Ã ÂªÅ“Ã ÂªÂ¿Ã ÂªÂ¨Ã ÂªÂ² Ã ÂªÂ«Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ² Ã ÂªÂ«Ã ÂªÂ°Ã Â«â‚¬ Ã ÂªÂªÃ Â«ÂÃ ÂªÂ²Ã Â«â€¡ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹

                      // Ã Â«Â¨. Ã ÂªÂ¡Ã ÂªÂ¾Ã ÂªÂ¯Ã ÂªÂ²Ã Â«â€¹Ã Âªâ€” Ã ÂªÂ¬Ã Âªâ€šÃ ÂªÂ§ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
                      Navigator.pop(context);

                      // Ã Â«Â©. Ã ÂªÂµÃ ÂªÂ¿Ã ÂªÂ¡Ã ÂªÂ¿Ã ÂªÂ¯Ã Â«â€¹ Ã ÂªÅ¸Ã Â«ÂÃ ÂªÂ°Ã Â«â‚¬Ã ÂªÂ® Ã ÂªÂ¸Ã Â«ÂÃ Âªâ€¢Ã Â«ÂÃ ÂªÂ°Ã Â«â‚¬Ã ÂªÂ¨ Ã ÂªÂ¬Ã Âªâ€šÃ ÂªÂ§ Ã Âªâ€¢Ã ÂªÂ°Ã Â«â€¹
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
    // à«§. àª¸à«Œàª¥à«€ àªªàª¹à«‡àª²àª¾ àªŸàª¾àªˆàª®àª° àª¬àª‚àª§ àª•àª°à«‹
    _progressTimer?.cancel();

    // à«¨. àª²àª¿àª¸àª¨àª° àª¹àªŸàª¾àªµà«‹ àªœà«‡àª¥à«€ àª•à«‹àªˆ àª¸à«àªŸà«‡àªŸ àª…àªªàª¡à«‡àªŸ àªŸà«àª°àª¿àª—àª° àª¨ àª¥àª¾àª¯
    _trimmer.videoPlayerController?.removeListener(_videoListener);
    _didAttachVideoListener = false;

    // à«©. àªµà«€àª¡àª¿àª¯à«‹ àª…àªŸàª•àª¾àªµà«‹ (àªœà«‹ àª•àª‚àªŸà«àª°à«‹àª²àª° àª…àª¸à«àª¤àª¿àª¤à«àªµàª®àª¾àª‚ àª¹à«‹àª¯ àª¤à«‹)
    if (_trimmer.videoPlayerController != null) {
      _trimmer.videoPlayerController!.pause();
    }

    // à«ª. àª¨à«‹àªŸàª¿àª«àª¾àª¯àª° àª•à«àª²à«€àª¨ àª•àª°à«‹
    _estimateSizeNotifier.dispose();
    _exportProgress.dispose();

    // à««. àª“àª°àª¿àªàª¨à«àªŸà«‡àª¶àª¨
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // à«¬. Trimmer àª¨à«‡ àª•à«àª²à«€àª¨ àª•àª°à«‹ (àª¨à«‹àª‚àª§: video_trimmer àª²àª¾àª‡àª¬à«àª°à«‡àª°à«€àª¨à«àª‚ àªªà«‹àª¤àª¾àª¨à«àª‚ àª‡àª¨à«àªŸàª°àª¨àª² àª®à«‡àª¨à«‡àªœàª®à«‡àª¨à«àªŸ àª¹à«‹àª¯ àª›à«‡)
    // àªœà«‹ àª¤àª®à«‡ àª®à«‡àª¨à«àª¯à«àª…àª²à«€ dispose àª•àª°à«‹ àª›à«‹ àª¤à«‹ àª¤à«‡àª¨à«‡ àª›à«‡àª²à«àª²à«‡ àª°àª¾àª–à«‹.
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

