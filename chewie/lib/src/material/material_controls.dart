// material_controls....

import 'dart:async';
import 'package:chewie/src/center_play_button.dart';
import 'package:chewie/src/center_seek_button.dart';
import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/helpers/utils.dart';
import 'package:chewie/src/material/material_progress_bar.dart';
import 'package:chewie/src/material/widgets/options_dialog.dart';
import 'package:chewie/src/material/widgets/playback_speed_dialog.dart';
import 'package:chewie/src/models/option_item.dart';
import 'package:chewie/src/models/subtitle_model.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:chewie/widgets/image_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class MaterialControls extends StatefulWidget {
  const MaterialControls({this.showPlayButton = true, super.key});

  final bool showPlayButton;

  @override
  State<StatefulWidget> createState() {
    return MaterialControlsState();
  }
}

class MaterialControlsState extends State<MaterialControls>
    with SingleTickerProviderStateMixin {
  bool isOptionOpen = false;

  // MaterialControlsState
  bool isLocked = false; // Controls Lock state

  bool loop = false;
  bool isShuffle = false;
  late PlayerNotifier notifier;
  late VideoPlayerValue videoPlayerLatestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  Timer? _initTimer;
  late var _subtitlesPosition = Duration.zero;
  bool _subtitleOn = false;
  Timer? _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;
  Timer? _bufferingDisplayTimer;
  bool _displayBufferingIndicator = false;

  final barHeight = 48.0 * 1.5;
  final marginSize = 5.0;

  late VideoPlayerController controller;
  ChewieController? _chewieController;

  // We know that _chewieController is set in didChangeDependencies
  ChewieController get chewieController => _chewieController!;

  @override
  void initState() {
    super.initState();
    notifier = Provider.of<PlayerNotifier>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    if (videoPlayerLatestValue.hasError) {
      return chewieController.errorBuilder?.call(
            context,
            chewieController.videoPlayerController.value.errorDescription!,
          ) ??
          const Center(child: Icon(Icons.error, color: Colors.white, size: 42));
    }

    return MouseRegion(
      onHover: (_) {
        cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () => cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: notifier.hideStuff,
          child: Stack(
            children: [
              // _buildLockButton()
              AbsorbPointer(
                absorbing: notifier.hideStuff,
                child: Column(children: []),
              ),
              if (_displayBufferingIndicator)
                _chewieController?.bufferingBuilder?.call(context) ??
                    const Center(child: CircularProgressIndicator())
              else
                // _buildHitArea(),
                _buildActionBar(),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (_subtitleOn)
                    Transform.translate(
                      offset: Offset(
                        0.0,
                        notifier.hideStuff ? barHeight * 0.8 : 0.0,
                      ),
                      child: _buildSubtitles(
                        context,
                        chewieController.subtitle!,
                      ),
                    ),
                  _buildHitArea(),
                  _buildBottomBar(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isDarkMode = true;

  void performControllOperation(ControlType? type, OptionItem option, context) {
    switch (type) {
      case ControlType.info:
        () {};
        break;
      case ControlType.miniVideo:
        Navigator.pop(context);
        break;
      case ControlType.volume:
        cancelAndRestartTimer();

        if (videoPlayerLatestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
        break;
      case ControlType.shuffle:
        option.onTap;
        break;
      case ControlType.playbackSpeed:
        // _onSpeedButtonTap;
        // Navigator.pop(context);
        _onSpeedButtonTap();
        // _seekBackward;
        //_seekForward;
        break;

      case ControlType.prev10:
        _seekBackward();
        //_seekForward;
        break;
      case ControlType.next10:
        _seekForward();
        break;
      case ControlType.theme:
        setState(() {
          isDarkMode = !isDarkMode;
        });
        break;
      case ControlType.nextVideo:
        chewieController.onNextVideo?.call();
        _updateState();
        break;

      case ControlType.prevVideo:
        chewieController.onPreviousVideo?.call();
        _updateState();
        break;

      case ControlType.loop:
        () async {
          setState(() {
            loop = !loop;
          });
          await chewieController.setLooping(loop);
        };
        break;
      default:
        () {};
        break;
    }
  }

  String getIcon(ControlType? type) {
    switch (type) {
      case ControlType.info:
        return "assets/svg_icon/ic_info.svg";
      case ControlType.miniVideo:
        return "assets/svg_icon/ic_miniscreen.svg";
      case ControlType.volume:
        return videoPlayerLatestValue.volume > 0
            ? "assets/svg_icon/ic_volumeon.svg"
            : "assets/svg_icon/ic_volumeoff.svg";
      case ControlType.shuffle:
        return "assets/svg_icon/ic_shuffle.svg";
      case ControlType.playbackSpeed:
        return "assets/svg_icon/ic_2x.svg";
      case ControlType.theme:
        return isDarkMode
            ? "assets/svg_icon/ic_10_sec_prev.svg"
            : "assets/svg_icon/ic_darkmode.svg";
      case ControlType.loop:
        return "assets/svg_icon/ic_loop.svg";
      case ControlType.prev10:
        return "assets/svg_icon/ic_10_sec_prev.svg";
      case ControlType.next10:
        return "assets/svg_icon/ic_10_sec_next.svg";
      default:
        return "assets/svg_icon/ic_loop.svg";
    }
  }

  @override
  void dispose() {
    _showAfterExpandCollapseTimer?.cancel();
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final oldController = _chewieController;
    _chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    // Notifier ને અહીં ફરીથી મેળવો જેથી તે લેટેસ્ટ રહે
    notifier = Provider.of<PlayerNotifier>(context, listen: false);

    if (oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildActionBar() {
    return AbsorbPointer(absorbing: isLocked, child: _buildOptionsButton());
  }

  /*Widget _buildActionBar() {
    return AbsorbPointer(
      absorbing: isLocked,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // _buildSubtitleToggle(),
          _buildOptionsButton(),
           // <-- Lock button added
        ],
      ),
    );
  }*/

  Widget _buildLockButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isLocked = !isLocked; // Toggle Lock
        });
      },
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          isLocked ? Icons.lock : Icons.lock_open,
          color: Colors.white,
        ),
      ),
    );
  }

  List<OptionItem> _buildOptions(BuildContext context) {
    final options = <OptionItem>[
      // OptionItem(
      //   onTap: (context) async {
      //     Navigator.pop(context);
      //     _onSpeedButtonTap();
      //   },
      //   iconImage: "assets/svg_icon/ic_on.svg",
      //   iconData: Icons.speed,
      //   title:
      //       chewieController.optionsTranslation?.playbackSpeedButtonText ??
      //       'Playback speed',
      // ),
    ];

    if (chewieController.additionalOptions != null &&
        chewieController.additionalOptions!(context).isNotEmpty) {
      options.addAll(chewieController.additionalOptions!(context));
    }
    return options;
  }

  Widget _buildOptionsButton() {
    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: GestureDetector(
        onTap: () async {
          _hideTimer?.cancel();

          if (chewieController.optionsBuilder != null) {
            await chewieController.optionsBuilder!(
              context,
              _buildOptions(context),
            );
          } else {
            await showModalBottomSheet<OptionItem>(
              context: context,
              isScrollControlled: true,
              useRootNavigator: chewieController.useRootNavigator,
              builder: (context) => OptionsDialog(
                options: _buildOptions(context),
                cancelButtonText:
                    chewieController.optionsTranslation?.cancelButtonText,
              ),
            );
          }

          if (videoPlayerLatestValue.isPlaying) {
            _startHideTimer();
          }
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppImage(src: "assets/svg_icon/ic_on.svg"),

                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: _buildOptions(context).map((option) {
                        return GestureDetector(
                          // onTap:  performControllOperation(option.controlType,option,context),
                          onTap: () {
                            // option.onTap(context);
                            performControllOperation(
                              option.controlType,
                              option,
                              context,
                            );
                          },
                          child: AppImage(src: getIcon(option.controlType)),

                          // Container(
                          //   padding: const EdgeInsets.symmetric(
                          //       horizontal: 10, vertical: 6),
                          //   decoration: BoxDecoration(
                          //     color: Colors.white.withOpacity(0.1),
                          //     borderRadius: BorderRadius.circular(6),
                          //   ),
                          //   child:
                          //
                          //
                          //   Row(
                          //     mainAxisSize: MainAxisSize.min,
                          //     children: [
                          //       Icon(
                          //         option.iconData,
                          //         size: 16,
                          //         color: Colors.white,
                          //       ),
                          //       const SizedBox(width: 4),
                          //       Text(
                          //         option.title,
                          //         style: const TextStyle(
                          //           color: Colors.white,
                          //           fontSize: 12,
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        );
                      }).toList(),
                    ),
                  ),

                  AppImage(src: "assets/svg_icon/ic_off.svg"),
                ],
              ),
            ),
          ),
        ),

        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     // AppImage(src: "assets/svg_icon/ic_on.svg"),
        //     AppImage(src: "assets/svg_icon/ic_on.svg"),
        //
        //     LayoutBuilder(
        //       builder: (context, constraints) {
        //         double boxSize = constraints.maxWidth / 22;
        //
        //         return Row(
        //           children: List.generate(
        //             20,
        //                 (index) => Container(
        //               height: boxSize,
        //               width: boxSize,
        //               color: Colors.red,
        //             ),
        //           ),
        //         );
        //       },
        //     ),
        //
        //     AppImage(src: "assets/svg_icon/ic_off.svg"),
        //
        //     // AppImage(src: "assets/svg_icon/ic_off.svg"),
        //   ],
        // ),
      ),

      // IconButton(
      //   onPressed: () async {
      //     _hideTimer?.cancel();
      //
      //     if (chewieController.optionsBuilder != null) {
      //       await chewieController.optionsBuilder!(
      //         context,
      //         _buildOptions(context),
      //       );
      //     } else {
      //       await showModalBottomSheet<OptionItem>(
      //         context: context,
      //         isScrollControlled: true,
      //         useRootNavigator: chewieController.useRootNavigator,
      //         builder: (context) => OptionsDialog(
      //           options: _buildOptions(context),
      //           cancelButtonText:
      //           chewieController.optionsTranslation?.cancelButtonText,
      //         ),
      //       );
      //     }
      //
      //     if (_latestValue.isPlaying) {
      //       _startHideTimer();
      //     }
      //   },
      //   icon: const Icon(Icons.more_vert, color: Colors.white),
      // ),
    );
  }

  Widget _buildSubtitles(BuildContext context, Subtitles subtitles) {
    if (!_subtitleOn) {
      return const SizedBox();
    }
    final currentSubtitle = subtitles.getByPosition(_subtitlesPosition);
    if (currentSubtitle.isEmpty) {
      return const SizedBox();
    }

    if (chewieController.subtitleBuilder != null) {
      return chewieController.subtitleBuilder!(
        context,
        currentSubtitle.first!.text,
      );
    }

    return Padding(
      padding: EdgeInsets.all(marginSize),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0x96000000),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          currentSubtitle.first!.text.toString(),
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  AnimatedOpacity _buildBottomBar(BuildContext context) {
    final iconColor = Theme.of(context).textTheme.labelLarge!.color;

    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: barHeight + (chewieController.isFullScreen ? 5.0 : 0),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: !chewieController.isFullScreen ? 0.0 : 0,
        ),
        child: SafeArea(
          top: false,
          bottom: chewieController.isFullScreen,
          minimum: chewieController.controlsSafeAreaMinimum,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    // if (chewieController.isLive)
                    //   const Expanded(child: Text('LIVE'))
                    // else
                    //   _buildPosition(iconColor),
                    // if (chewieController.allowMuting)
                    // _buildMuteButton(controller),
                    // const Spacer(),
                    // if (chewieController.allowFullScreen) _buildExpandButton(),
                    // IconButton(
                    //   icon: Icon(
                    //     Icons.repeat,
                    //     color: loop ? Colors.blue : Colors.white,
                    //   ),
                    //   onPressed: () async {
                    //     setState(() {
                    //       loop = !loop;
                    //     });
                    //     await chewieController.setLooping(loop);
                    //   },
                    // ),

                    // IconButton(
                    //   icon: const Icon(Icons.replay_10, color: Colors.white),
                    //   onPressed: () => _seekBackward,
                    // ),
                    // IconButton(
                    //   icon: const Icon(Icons.forward_10, color: Colors.white),
                    //   onPressed: () => _seekForward,
                    // ),

                    // IconButton(
                    //   icon: Icon(
                    //     Icons.shuffle,
                    //     color: isShuffle ? Colors.blue : Colors.black54,
                    //   ),
                    //   onPressed: () {
                    //     print("before== ====== $isShuffle");
                    //     setState(() {
                    //       isShuffle = !isShuffle;
                    //
                    //     });
                    //     chewieController.onSufflePressed.call();
                    //     print("after== ====== $isShuffle");
                    //     // print("before ====== ${materialControlsState.isShuffle}");
                    //   },
                    // ),
                  ],
                ),
              ),
              SizedBox(height: chewieController.isFullScreen ? 15.0 : 0),
              if (!chewieController.isLive)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Text(formatDuration(videoPlayerLatestValue.position)),
                        SizedBox(width: 10),
                        _buildProgressBar(),
                        SizedBox(width: 10),
                        Text(formatDuration(videoPlayerLatestValue.duration)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(VideoPlayerController controller) {
    return GestureDetector(
      onTap: () {
        cancelAndRestartTimer();

        if (videoPlayerLatestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            height: barHeight,
            padding: const EdgeInsets.only(left: 6.0),
            child: Icon(
              videoPlayerLatestValue.volume > 0
                  ? Icons.volume_up
                  : Icons.volume_off,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return AbsorbPointer(
      absorbing: isLocked,
      child: GestureDetector(
        onTap: _onExpandCollapse,
        child: AnimatedOpacity(
          opacity: notifier.hideStuff ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: AppImage(
            src: chewieController.isFullScreen
                ? "assets/svg_icon/ic_bigscreen.svg"
                : "assets/svg_icon/ic_miniscreen.svg",
          ),
        ),
      ),
    );
  }

  Widget _buildHitArea() {
    final bool isFinished =
        (videoPlayerLatestValue.position >= videoPlayerLatestValue.duration) &&
        videoPlayerLatestValue.duration.inSeconds > 0;
    final bool showPlayButton =
        widget.showPlayButton && !_dragging && !notifier.hideStuff;

    return GestureDetector(
      onTap: () {
        if (videoPlayerLatestValue.isPlaying) {
          if (_chewieController?.pauseOnBackgroundTap ?? false) {
            _playPause();
            cancelAndRestartTimer();
          } else {
            if (_displayTapped) {
              setState(() {
                notifier.hideStuff = true;
              });
            } else {
              cancelAndRestartTimer();
            }
          }
        } else {
          _playPause();

          setState(() {
            notifier.hideStuff = true;
          });
        }
      },
      child: Container(
        alignment: Alignment.center,
        color: Colors.transparent,
        // The Gesture Detector doesn't expand to the full size of the container without this; Not sure why!
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // IconButton(
            //   icon: const Icon(Icons.skip_previous, color: Colors.white),
            //   onPressed: chewieController.onPreviousVideo,
            // ),
            //
            // IconButton(
            //   icon: const Icon(Icons.skip_next, color: Colors.white),
            //   onPressed: chewieController.onNextVideo,
            // ),
            _buildLockButton(),
            if (!isFinished && !chewieController.isLive)
              AbsorbPointer(
                absorbing: isLocked,
                child: CenterSeekButton(
                  iconData: Icons.replay_10,
                  backgroundColor: Colors.black54,
                  iconColor: Colors.white,
                  show: showPlayButton,
                  fadeDuration: chewieController.materialSeekButtonFadeDuration,
                  iconSize: chewieController.materialSeekButtonSize,
                  onPressed: _seekBackward,
                ),
              ),
            AbsorbPointer(
              absorbing: isLocked,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: marginSize),
                child: CenterPlayButton(
                  backgroundColor: Colors.black54,
                  iconColor: Colors.white,
                  isFinished: isFinished,
                  isPlaying: controller.value.isPlaying,
                  show: showPlayButton,
                  onPressed: _playPause,
                ),
              ),
            ),
            if (!isFinished && !chewieController.isLive)
              AbsorbPointer(
                absorbing: isLocked,
                child: CenterSeekButton(
                  iconData: Icons.forward_10,
                  backgroundColor: Colors.black54,
                  iconColor: Colors.white,
                  show: showPlayButton,
                  fadeDuration: chewieController.materialSeekButtonFadeDuration,
                  iconSize: chewieController.materialSeekButtonSize,
                  onPressed: _seekForward,
                ),
              ),

            _buildExpandButton(),
          ],
        ),
      ),
    );
  }

  Future<void> _onSpeedButtonTap() async {
    _hideTimer?.cancel();

    final chosenSpeed = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: chewieController.useRootNavigator,
      builder: (context) => PlaybackSpeedDialog(
        speeds: chewieController.playbackSpeeds,
        selected: videoPlayerLatestValue.playbackSpeed,
      ),
    );

    if (chosenSpeed != null) {
      controller.setPlaybackSpeed(chosenSpeed);
    }

    if (videoPlayerLatestValue.isPlaying) {
      _startHideTimer();
    }
  }

  Widget _buildPosition(Color? iconColor) {
    final position = videoPlayerLatestValue.position;
    final duration = videoPlayerLatestValue.duration;

    return RichText(
      text: TextSpan(
        text: '${formatDuration(position)} ',
        children: <InlineSpan>[
          TextSpan(
            text: '/ ${formatDuration(duration)}',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.white.withValues(alpha: .75),
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
        style: const TextStyle(
          fontSize: 14.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubtitleToggle() {
    // if don't have subtitle hiden button
    if (chewieController.subtitle?.isEmpty ?? true) {
      return const SizedBox();
    }
    return GestureDetector(
      onTap: _onSubtitleTap,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(left: 12.0, right: 12.0),
        child: Icon(
          _subtitleOn
              ? Icons.closed_caption
              : Icons.closed_caption_off_outlined,
          color: _subtitleOn ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  void _onSubtitleTap() {
    setState(() {
      _subtitleOn = !_subtitleOn;
    });
  }

  void cancelAndRestartTimer() {
    if (!mounted) return; // આ લાઈન સૌથી મહત્વની છે

    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      try {
        // ચેક કરો કે notifier ખરેખર અસ્તિત્વમાં છે અને ડિસ્પોઝ નથી થયો
        if (mounted) {
          notifier.hideStuff = false;
        }
      } catch (e) {
        debugPrint("Error updating notifier: $e");
      }
      _displayTapped = true;
    });
  }

  void _startHideTimer() {
    final hideControlsTimer = chewieController.hideControlsTimer.isNegative
        ? ChewieController.defaultHideControlsTimer
        : chewieController.hideControlsTimer;

    _hideTimer = Timer(hideControlsTimer, () {
      if (mounted) {
        setState(() {
          try {
            notifier.hideStuff = true;
          } catch (e) {
            // ignore
          }
        });
      }
    });
  }

  Future<void> _initialize() async {
    _subtitleOn =
        chewieController.showSubtitles &&
        (chewieController.subtitle?.isNotEmpty ?? false);
    controller.addListener(_updateState);

    _updateState();

    if (controller.value.isPlaying || chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          notifier.hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    if (!mounted) return;

    setState(() {
      // ૧. Notifier ચેક
      try {
        if (mounted) notifier.hideStuff = true;
      } catch (e) {
        debugPrint("Notifier disposed");
      }

      // ૨. ChewieController ચેક - આ સૌથી મહત્વનું છે
      try {
        // chewieController (getter) વાપરવાને બદલે _chewieController (variable) વાપરો
        if (_chewieController != null) {
          _chewieController!.toggleFullScreen();
        }
      } catch (e) {
        debugPrint("ChewieController was already disposed, ignoring toggle.");
        // જો કંટ્રોલર ડિસ્પોઝ હોય, તો મેન્યુઅલી પોપ કરો (જો ફૂલ સ્ક્રીનમાં ફસાઈ ગયા હોય તો)
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        return; // આગળ વધશો નહીં
      }

      _showAfterExpandCollapseTimer?.cancel();
      _showAfterExpandCollapseTimer = Timer(
        const Duration(milliseconds: 300),
            () {
          if (mounted) {
            setState(() {
              cancelAndRestartTimer();
            });
          }
        },
      );
    });
  }
  // material_controls.dart માં _playPause મેથડ સુધારો
  void _playPause() {
    if (!mounted) return; // વિજેટ છે કે નહીં તે ચેક કરો

    final bool isFinished =
        (videoPlayerLatestValue.position >= videoPlayerLatestValue.duration) &&
        videoPlayerLatestValue.duration.inSeconds > 0;

    setState(() {
      if (controller.value.isPlaying) {
        // અહીં ફેરફાર: notifier ડિસ્પોઝ નથી થયો ને તે ચેક કરો
        if (mounted) {
          notifier.hideStuff = false;
        }
        _hideTimer?.cancel();
        controller.pause();
      } else {
        cancelAndRestartTimer();

        if (!controller.value.isInitialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration.zero);
          }
          controller.play();
        }
      }
    });
  }

  void _seekRelative(Duration relativeSeek) {
    cancelAndRestartTimer();
    final position = videoPlayerLatestValue.position + relativeSeek;
    final duration = videoPlayerLatestValue.duration;

    if (position < Duration.zero) {
      controller.seekTo(Duration.zero);
    } else if (position > duration) {
      controller.seekTo(duration);
    } else {
      controller.seekTo(position);
    }
  }

  void _seekBackward() {
    _seekRelative(const Duration(seconds: -10));
  }

  void _seekForward() {
    _seekRelative(const Duration(seconds: 10));
  }

  void _bufferingTimerTimeout() {
    _displayBufferingIndicator = true;
    if (mounted) {
      setState(() {});
    }
  }

  void _updateState() {
    if (!mounted) return;

    final bool buffering = getIsBuffering(controller);

    // display the progress bar indicator only after the buffering delay if it has been set
    if (chewieController.progressIndicatorDelay != null) {
      if (buffering) {
        _bufferingDisplayTimer ??= Timer(
          chewieController.progressIndicatorDelay!,
          _bufferingTimerTimeout,
        );
      } else {
        _bufferingDisplayTimer?.cancel();
        _bufferingDisplayTimer = null;
        _displayBufferingIndicator = false;
      }
    } else {
      _displayBufferingIndicator = buffering;
    }

    setState(() {
      videoPlayerLatestValue = controller.value;
      _subtitlesPosition = controller.value.position;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: MaterialVideoProgressBar(
        controller,
        onDragStart: () {
          setState(() {
            _dragging = true;
          });

          _hideTimer?.cancel();
        },
        onDragUpdate: () {
          _hideTimer?.cancel();
        },
        onDragEnd: () {
          setState(() {
            _dragging = false;
          });

          _startHideTimer();
        },
        colors:
            chewieController.materialProgressColors ??
            ChewieProgressColors(
              playedColor: Theme.of(context).colorScheme.secondary,
              handleColor: Theme.of(context).colorScheme.secondary,
              bufferedColor: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.5),
              backgroundColor: Theme.of(
                context,
              ).disabledColor.withValues(alpha: .5),
            ),
        draggableProgressBar: chewieController.draggableProgressBar,
      ),
    );
  }
}

enum ControlType {
  miniVideo,
  volume,
  shuffle,
  playbackSpeed,
  next10,
  prev10,
  theme,
  info,
  loop,
  nextVideo,
  prevVideo,
}
