import '../utils/app_imports.dart';

class VideoTrimScreen extends StatefulWidget {
  final File file;

  const VideoTrimScreen({super.key, required this.file});

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> {
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
        const SnackBar(content: Text("Cover frame captured! ðŸ“¸")),
      );
    }
  }

  void _loadVideo() async {
    await _trimmer.loadVideo(videoFile: widget.file);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Trim Video"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
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
                                "Video saved successfully to gallery! ✅",
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
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: VideoViewer(trimmer: _trimmer)),
          Center(
            child: TrimViewer(
              trimmer: _trimmer,
              viewerHeight: 50.0,
              viewerWidth: MediaQuery.of(context).size.width,
              onChangeStart: (value) => _startValue = value,
              onChangeEnd: (value) => _endValue = value,
              onChangePlaybackState: (value) =>
                  setState(() => _isPlaying = value),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_selectedCoverFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    _selectedCoverFile!,
                    height: 50,
                    width: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 20),

              GestureDetector(
                onTap: () async {
                  bool playbackState = await _trimmer.videoPlaybackControl(
                    startValue: _startValue,
                    endValue: _endValue,
                  );
                  setState(() => _isPlaying = playbackState);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),

              const SizedBox(width: 20),

              Column(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _setVideoCover,
                  ),
                  const Text(
                    "Cover",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
