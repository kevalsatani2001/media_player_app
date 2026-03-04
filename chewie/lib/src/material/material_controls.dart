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

import '../../widgets/custom_loader.dart';

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
  Color get primaryColor =>
      isDarkMode ? const Color(0XFF3D57F9) : const Color(0XFF3D57F9);

  Color get backgroundColor => isDarkMode ? Colors.black : Colors.white;

  Color get textColor => isDarkMode ? Colors.white : const Color(0XFF222222);

  Color get iconColor => isDarkMode ? Colors.white : const Color(0XFF222222);

  Color get progressBgColor => isDarkMode ? Colors.white24 : Colors.black26;
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
    if (!controller.value.isInitialized) {
      return const Center(child: CustomLoader());
    }
    // à«¨. àªµà«€àª¡àª¿àª¯à«‹ àªªà« àª²à«‡àª¯àª°àª¨à«€ àªµà«‡àª²à« àª¯à« àª àª²à«‹ (àª¸à«‡àª« àª°à«€àª¤à«‡)
    final videoValue = chewieController.videoPlayerController.value;

    if (videoValue.hasError) {
      return chewieController.errorBuilder?.call(
            context,
            videoValue.errorDescription!,
          ) ??
          const Center(child: Icon(Icons.error, color: Colors.white));
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
              // _buildLockButton(),
              AbsorbPointer(
                absorbing: notifier.hideStuff,
                child: Column(children: []),
              ),
              if (_displayBufferingIndicator)
                _chewieController?.bufferingBuilder?.call(context) ??
                    const Center(child: CustomLoader())
              else
                // _buildHitArea(),
                _buildActionBar(),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (_subtitleOn)
                    Transform.translate(
                      offset: Offset(0.0, notifier.hideStuff ? 0.8 : 0.0),
                      child: _buildSubtitles(
                        context,
                        chewieController.subtitle!,
                      ),
                    ),
                  // ensure the hit area gets a finite height by expanding to
                  // fill available space above the bottom bar. without this
                  // the Container inside _buildHitArea receives an
                  // unbounded vertical constraint when in full screen which
                  // causes the layout assertion seen in the bug report.
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

  void performControllOperation(
    ControlType? type,
    OptionItem option,
    context,
  ) async {
    switch (type) {
      case ControlType.info:
        option.onTap;
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
        setState(() {
          isShuffle = !isShuffle;
        });
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
        controller.removeListener(_updateState);

        // નેક્સ્ટ વીડિયો કોલ કરો
        chewieController.onNextVideo?.call();

        // નવું કંટ્રોલર મેળવો (જે ChewieController માં અપડેટ થયું હશે)
        controller = chewieController.videoPlayerController;

        // નવા કંટ્રોલર પર લિસનર લગાવો
        controller.addListener(_updateState);

        // ફરીથી ઈનિશિયલાઈઝ કરો જેથી UI રિફ્રેશ થાય
        _initialize();
        break;

      case ControlType.prevVideo:
        chewieController.onPreviousVideo?.call();
        _updateState();
        break;

      case ControlType.loop:
        setState(() {
          loop = !loop;
        });
        await chewieController.setLooping(loop);
        print("loop==>");
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
      case ControlType.zoomScreen:
        return "assets/svg_icon/ic_zoomin.svg";
      case ControlType.smallScreen:
        return "assets/svg_icon/ic_zoomout.svg";
      case ControlType.miniVideo:
        return "assets/svg_icon/ic_miniscreen.svg";
      case ControlType.volume:
        return videoPlayerLatestValue.volume > 0
            ? "assets/svg_icon/ic_volumeon.svg"
            : "assets/svg_icon/ic_volumeoff.svg";
      case ControlType.shuffle:
        return isShuffle
            ? "assets/svg_icon/ic_shuffle_active.svg"
            : "assets/svg_icon/ic_shuffle.svg";
      case ControlType.playbackSpeed:
        return "assets/svg_icon/ic_2x.svg";
      case ControlType.theme:
        return !isDarkMode
            ? "assets/svg_icon/ic_dark_active.svg"
            : "assets/svg_icon/ic_darkmode.svg";
      case ControlType.loop:
        return loop
            ? "assets/svg_icon/ic_loop_active.svg"
            : "assets/svg_icon/ic_loop.svg";
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
    // àª¬àª§àª¾ àªŸàª¾àªˆàª®àª° àªªàª¹à«‡àª²àª¾ àª¬àª‚àª§ àª•àª°à«‹
    _hideTimer?.cancel();
    _initTimer?.cancel();

    // àª²àª¿àª¸àª¨àª°àª¨à«‡ àª°à«€àª®à«àªµ àª•àª°à«‹ àªœà«‡àª¥à«€ àªàª°àª° àª¨ àª†àªµà«‡
    try {
      controller.removeListener(_updateState);
    } catch (_) {}

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

    if (oldController != _chewieController) {
      // à«§. àªœà«‚àª¨àª¾ àª•àª‚àªŸà«àª°à«‹àª²àª°àª®àª¾àª‚àª¥à«€ àª²àª¿àª¸àª¨àª° àª¦à«‚àª° àª•àª°à«‹ àªœà«‡àª¥à«€ àª àªœà«‚àª¨à«€ àª®à«‡àª®àª°à«€àª®àª¾àª‚ àªàª°àª° àª¨ àª«à«‡àª‚àª•à«‡
      oldController?.videoPlayerController.removeListener(_updateState);

      // à«¨.The most important thing is to be able to do it.
      controller = chewieController.videoPlayerController;

      // to«©. àª¨àªµàª¾ àª•àª‚àªŸà« àª°à«‹àª²àª° àªªàª° àª²àª¿àª¸àª¨àª° àª²àª—àª¾àªµà«‹
      controller.removeListener(_updateState);
      controller.addListener(_updateState);

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
    return AnimatedOpacity(
      // hideStuff true opacity 0 (default), 1.0 (default)
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: AbsorbPointer(
        // notifier controls opacity àª¤à«‡ àª®àª¾àªŸà«‡
        absorbing: notifier.hideStuff,
        child: GestureDetector(
          onTap: () {
            setState(() {
              isLocked = !isLocked; // Toggle Lock
            });
            // Toggle Lock is a gesture that is used to indicate that the device is locked. àªœà«‹ àª¤àª®à«‡ àªˆàªšà« àª›à«‹ àª•à«‡ àª²à«‹àª• àª•àª°à« àª¯àª¾ àªªàª›à«€ àª•àª‚àªŸà« àª°à«‹àª²à« àª¸ àª¤àª°àª¤ àª›à« àªªàª¾àªˆ àªœàª¾àª¯:
            if (isLocked) {
              cancelAndRestartTimer();
            }
          },
          child: AppImage(
            height: 40,
            width: 40,
            src: isLocked
                ? "assets/svg_icon/ic_lock.svg" // àª²à«‹àª• àª¹à«‹àª¯ àª¤à« àª¯àª¾àª°à«‡ àª²à«‹àª• àª†àªˆàª•à«‹àª¨
                : "assets/svg_icon/ic_unlock.svg", // àª…àª¨àª²à«‹àª• àª¹à«‹àª¯ àª¤à« àª¯àª¾àª°à«‡ àª…àª¨àª²à«‹àª• àª†àªˆàª•à«‹àª¨
          ),
        ),
      ),
    );
  }

  List<OptionItem> _buildOptions(BuildContext context) {
    final options = <OptionItem>[
      // OptionItem(
      // onTap: (context) async {
      // Navigator.pop(context);
      // _onSpeedButtonTap();
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
                  // AppImage(src: "assets/svg_icon/ic_on.svg"),
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

                  // AppImage(src: "assets/svg_icon/ic_off.svg"),
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
        decoration: BoxDecoration(color: backgroundColor.withOpacity(0.95)),
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
                        Text(
                          formatDuration(videoPlayerLatestValue.position),
                          style: TextStyle(
                            fontSize: 15,
                            color: textColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(width: 10),
                        _buildProgressBar(),
                        SizedBox(width: 10),
                        Text(
                          formatDuration(videoPlayerLatestValue.duration),
                          style: TextStyle(
                            fontSize: 15,
                            color: textColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
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
            height: 40,
            width: 40,
            src: chewieController.isFullScreen
                ? getIcon(ControlType.smallScreen)
                : getIcon(ControlType.zoomScreen),
          ),
        ),
      ),
    );
  }

  Widget _buildHitArea() {
    return GestureDetector(
      onTap: () {
        // ટેપ કરવા પર કંટ્રોલ્સ હાઈડ/શો કરવા માટે
        cancelAndRestartTimer();
      },
      child: Container(
        alignment: Alignment.center,
        color: Colors.transparent, // આખી સ્ક્રીન પર ટેપ ડિટેક્ટ કરવા માટે
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          // FittedBox ને બદલે સીધું Row વાપરો અથવા જો સ્કેલિંગ જોઈતું હોય તો Spacer કાઢી નાખો
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // બટનોને સેન્ટરમાં રાખવા માટે
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLockButton(),
              const SizedBox(width: 20),

              if (!chewieController.isLive)
                AbsorbPointer(
                  absorbing: isLocked,
                  child: CenterSeekButton(
                    iconData: Icons.replay_10,
                    backgroundColor: primaryColor,
                    iconColor: Colors.white,
                    show: !notifier.hideStuff,
                    onPressed: _seekBackward,
                  ),
                ),

              const SizedBox(width: 20),

              AbsorbPointer(
                absorbing: isLocked,
                child: CenterPlayButton(
                  backgroundColor: const Color(0XFF3D57F9),
                  iconColor: Colors.white,
                  isFinished: (videoPlayerLatestValue.position >= videoPlayerLatestValue.duration),
                  isPlaying: controller.value.isPlaying,
                  show: !notifier.hideStuff,
                  onPressed: _playPause,
                ),
              ),

              const SizedBox(width: 20),

              if (!chewieController.isLive)
                AbsorbPointer(
                  absorbing: isLocked,
                  child: CenterSeekButton(
                    iconData: Icons.forward_10,
                    backgroundColor: const Color(0XFF3D57F9),
                    iconColor: Colors.white,
                    show: !notifier.hideStuff,
                    onPressed: _seekForward,
                  ),
                ),

              const SizedBox(width: 20),
              _buildExpandButton(),
            ],
          ),
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
        selectedSpeed: videoPlayerLatestValue.playbackSpeed,
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
    if (!mounted)
      return; // àª† àª²àª¾àªˆàª¨ àª¸à«Œàª¥à«€ àª®àª¹àª¤à«àªµàª¨à«€ àª›à«‡

    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      try {
        // àªšà«‡àª• àª•àª°à«‹ àª•à«‡ notifier àª–àª°à«‡àª–àª° àª…àª¸à«àª¤àª¿àª¤à«àªµàª®àª¾àª‚ àª›à«‡ àª…àª¨à«‡ àª¡àª¿àª¸à«àªªà«‹àª àª¨àª¥à«€ àª¥àª¯à«‹
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
      // à«§. Notifier àªšà«‡àª•
      try {
        if (mounted) notifier.hideStuff = true;
      } catch (e) {
        debugPrint("Notifier disposed");
      }

      // à«¨. ChewieController àªšà«‡àª• - àª† àª¸à«Œàª¥à«€ àª®àª¹àª¤à«àªµàª¨à«àª‚ àª›à«‡
      try {
        // chewieController (getter) àªµàª¾àªªàª°àªµàª¾àª¨à«‡ àª¬àª¦àª²à«‡ _chewieController (variable) àªµàª¾àªªàª°à«‹
        if (_chewieController != null) {
          _chewieController!.toggleFullScreen();
        }
      } catch (e) {
        debugPrint("ChewieController was already disposed, ignoring toggle.");
        // àªœà«‹ àª•àª‚àªŸà«àª°à«‹àª²àª° àª¡àª¿àª¸à«àªªà«‹àª àª¹à«‹àª¯, àª¤à«‹ àª®à«‡àª¨à«àª¯à«àª…àª²à«€ àªªà«‹àªª àª•àª°à«‹ (àªœà«‹ àª«à«‚àª² àª¸à«àª•à«àª°à«€àª¨àª®àª¾àª‚ àª«àª¸àª¾àªˆ àª—àª¯àª¾ àª¹à«‹àª¯ àª¤à«‹)
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        return; // àª†àª—àª³ àªµàª§àª¶à«‹ àª¨àª¹à«€àª‚
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

  // material_controls.dart àª®àª¾àª‚ _playPause àª®à«‡àª¥àª¡ àª¸à«àª§àª¾àª°à«‹
  void _playPause() {
    if (!_isControllerAlive)
      return; // àªœà«‹ àª•àª‚àªŸà«àª°à«‹àª²àª° àª®àª°à«€ àª—àª¯à«‹ àª¹à«‹àª¯ àª¤à«‹ àª…àª¹à«€àª‚àª¥à«€ àªœ àªªàª¾àª›àª¾ àªµàª³à«€ àªœàª¾àª“

    final videoController = chewieController.videoPlayerController;
    final bool isFinished =
        videoPlayerLatestValue.position >= videoPlayerLatestValue.duration;

    if (videoController.value.isPlaying) {
      if (mounted) notifier.hideStuff = false;
      _hideTimer?.cancel();

      // àª…àª¤à«àª¯àª‚àª¤ àª¸à«àª°àª•à«àª·àª¿àª¤ àª°à«€àª¤à«‡ Pause àª•àª°à«‹
      chewieController.videoPlayerController.pause();
    } else {
      cancelAndRestartTimer();

      if (isFinished) {
        videoController.seekTo(Duration.zero);
      }
      chewieController.videoPlayerController.play();
    }

    if (mounted) setState(() {});
  }

  bool get _isControllerAlive {
    try {
      // àªœà«‹ àª•àª‚àªŸà«àª°à«‹àª²àª° àª¡àª¿àª¸à«àªªà«‹àª àª¹àª¶à«‡ àª¤à«‹ .value àªàª•à«àª¸à«‡àª¸ àª•àª°àª¤àª¾ àªœ àªàª°àª° àª†àªµàª¶à«‡
      // àª…àª¨à«‡ àª†àªªàª£à«‡ àªàª¨à«‡ catch àª®àª¾àª‚ àªªàª•àª¡à«€ àª²àªˆàª¶à«àª‚.
      return mounted &&
          _chewieController != null &&
          chewieController.videoPlayerController.value.isInitialized;
    } catch (_) {
      return false;
    }
  }

  void _seekRelative(Duration relativeSeek) {
    // àª¸à«€àª• àª•àª°àªµàª¾ àª®àª¾àªŸà«‡ àªªàª£ àªªàª¹à«‡àª²àª¾ àªšà«‡àª• àª•àª°à«‹
    if (!_isControllerAlive) return;

    cancelAndRestartTimer();
    final videoController = chewieController.videoPlayerController;
    final position = videoController.value.position + relativeSeek;
    final duration = videoController.value.duration;

    if (position < Duration.zero) {
      videoController.seekTo(Duration.zero);
    } else if (position > duration) {
      videoController.seekTo(duration);
    } else {
      videoController.seekTo(position);
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
    setState(() {
      videoPlayerLatestValue = controller.value;
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
  zoomScreen,
  smallScreen,
}
