import 'dart:async';
import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../core/constants.dart';
import '../models/media_item.dart';
class GlobalPlayer extends ChangeNotifier {
  MaterialControlsState materialControlsState = MaterialControlsState();
  static final GlobalPlayer _instance = GlobalPlayer._internal();

  factory GlobalPlayer() => _instance;

  GlobalPlayer._internal();

  VideoPlayerController? controller;
  ChewieController? chewie;
  String? currentPath;
  bool isLandscape = false;
  bool isNetwork = false;
  String? currentType; // "audio" or "video"
  bool isLooping = false;

  List<MediaItem> queue = [];
  List<MediaItem> originalQueue = [];
  int currentIndex = -1;
  bool isShuffle = false;

  void toggleShuffle() {
    print("call ssss========$isShuffle");
    isShuffle = !isShuffle;
    print("call ssss========$isShuffle");

    final currentItem = queue[currentIndex];

    if (isShuffle) {
      queue.shuffle();
    } else {
      queue = List.from(originalQueue);
    }

    currentIndex = queue.indexOf(currentItem);

    notifyListeners();
  }

  void setQueue(List<MediaItem> items, int startIndex) {
    originalQueue = List.from(items);
    queue = List.from(items);
    currentIndex = startIndex;
  }

  Future<void> toggleRotation() async {
    isLandscape = !isLandscape;

    if (isLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    notifyListeners();
  }

  Future<void> playNext() async {
    print("queue length is ===> ${queue.length}");
    print("queue length is ===> ${queue}");
    if (queue.isEmpty) return;
    if (currentIndex + 1 >= queue.length) return;

    currentIndex++;
    final item = queue[currentIndex];
    await play(item.path, network: item.isNetwork, type: item.type);
  }

  Future<void> playPrevious() async {
    if (queue.isEmpty) return;
    if (currentIndex - 1 < 0) return;

    currentIndex--;
    final item = queue[currentIndex];
    await play(item.path, network: item.isNetwork, type: item.type);
  }

  void toggleLoop() {
    isLooping = !isLooping;
    controller?.setLooping(isLooping);
  }

  Future<void> play(
      String path, {
        bool network = false,
        required String type,
      }) async {
    if (currentPath == path && controller != null) {
      controller!.play();
      return;
    }

    await controller?.dispose();

    currentPath = path;
    isNetwork = network;
    currentType = type;

    controller = isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(path))
        : VideoPlayerController.file(File(path));

    await controller!.initialize();

    // 🔥 ADD LISTENER HERE
    controller!.addListener(() {
      final value = controller!.value;
      if (value.isInitialized &&
          value.position >= value.duration &&
          !isLooping) {
        playNext();
      }
    });

    chewie = type == "video"
        ? ChewieController(
      zoomAndPan: true,
      deviceOrientationsOnEnterFullScreen: [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],

      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
      additionalOptions: (context) {
        return [
          // OptionItem(
          //   onTap: (context) {
          //     toggleRotation();
          //     Navigator.pop(context);
          //   },
          //   iconData: Icons.screen_rotation,
          //   title: isLandscape ? "Portrait Mode" : "Landscape Mode",
          // ),
          OptionItem(
            controlType: ControlType.miniVideo,
            onTap: (context) {
              Navigator.pop(context);
            },
            iconData: Icons.screen_rotation,
            title: "Mini Screen",
            iconImage: AppSvg.icMiniScreen,
          ),
          OptionItem(
            controlType: ControlType.volume,
            onTap: (context) {
              // toggleRotation();
              // Navigator.pop(context);
            },
            iconData: Icons.screen_rotation,
            title: "Volume",
            iconImage: AppSvg.icVolumeOff,
          ),

          OptionItem(
            controlType: ControlType.shuffle,
            onTap: (context) => toggleShuffle,
            iconData: Icons.shuffle,
            title: "Shuffle",
            iconImage: AppSvg.icShuffle,
          ),
          OptionItem(
            controlType: ControlType.playbackSpeed,
            onTap: (context) {
              // toggleShuffle();
            },
            iconData: Icons.shuffle,
            title: "video speed",
            iconImage: AppSvg.ic2x,
          ),
          OptionItem(
            controlType: ControlType.theme,
            onTap: (context) {
              toggleShuffle();
            },
            iconData: Icons.shuffle,
            title: "dark",
            iconImage: AppSvg.icDarkMode,
          ),
          OptionItem(
            controlType: ControlType.info,
            onTap: (context) {
              toggleShuffle();
            },
            iconData: Icons.shuffle,
            title: "info",
            iconImage: AppSvg.icInfo,
          ),
          OptionItem(
            controlType: ControlType.prev10,
            onTap: (context) {
              toggleShuffle();
            },
            iconData: Icons.shuffle,
            title: "prev10",
            iconImage: AppSvg.ic10Prev,
          ),
          OptionItem(
            controlType: ControlType.next10,
            onTap: (context) {
              toggleShuffle();
            },
            iconData: Icons.shuffle,
            title: "next10",
            iconImage: AppSvg.ic10Next,
          ),

          OptionItem(
            onTap: (context) {
              // chewie!.videoPlayerController.value.cancelAndRestartTimer();
              //
              // if (videoPlayerLatestValue.volume == 0) {
              //   chewie!.videoPlayerController.setVolume(chewie.videoPlayerController.videoPlayerOptions.);
              //   // controller.setVolume(_latestVolume ?? 0.5);
              // } else {
              //   _latestVolume = controller.value.volume;
              //   controller.setVolume(0.0);
              // }
            },
            controlType: ControlType.loop,
            iconData: Icons.shuffle,
            title: "Loop",
            iconImage: AppSvg.icLoop,
          ),
          OptionItem(
            controlType: ControlType.playbackSpeed,
            onTap: (context) async {
              final newPos =
                  (controller!.value.position) - Duration(seconds: 10);
              controller!.seekTo(
                newPos > Duration.zero ? newPos : Duration.zero,
              );
            },
            iconData: Icons.replay_10,
            title: "kk",
            iconImage: AppSvg.ic10Prev,
          ),
          OptionItem(
            onTap: (context) async {},
            controlType: ControlType.miniVideo,
            iconData: Icons.replay_10,
            title: "miniScreen",
            iconImage: AppSvg.icMiniScreen,
          ),
        ];
      },
      materialProgressColors: ChewieProgressColors(
        playedColor: Color(0XFF3D57F9),
        backgroundColor: Color(0XFFF6F6F6),
      ),

      looping: true,
      onSufflePressed: () {
        toggleShuffle();
      },
      videoPlayerController: controller!,
      // onPressedLooping: (){},
      autoPlay: true,
      allowFullScreen: true,
      onNextVideo: () async {
        await playNext();
      },
      onPreviousVideo: () async {
        await playPrevious();
      },
    )
        : null;
  }

  void pause() => controller?.pause();

  void resume() => controller?.play();

  void stop() {
    controller?.pause();
    controller?.seekTo(Duration.zero);
  }

  bool get isPlaying => controller?.value.isPlaying ?? false;
}