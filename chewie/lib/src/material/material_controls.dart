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
              // _buildActionBar(),

                Positioned.fill(
                  child: Container(
                    height: double.infinity,
                    width: double.infinity,
                    child: Row(
                      children: [
                        // àª¡àª¾àª¬à«€ àª¬àª¾àªœà« - 10, 20, 30 sec Backward
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque, // àª†àª¨àª¾àª¥à«€ àª–àª¾àª²à«€ àªœàª—à«àª¯àª¾àª®àª¾àª‚ àªªàª£ àªŸàªš àª¥àª¶à«‡
                            onTap: cancelAndRestartTimer,
                            onDoubleTap: () {
                              _backwardTimer?.cancel();
                              setState(() {
                                _backwardSeekAmount += 10;
                                _seekBackward();
                              });
                              _backwardTimer = Timer(const Duration(milliseconds: 700), () {
                                if (mounted) setState(() => _backwardSeekAmount = 0);
                              });
                            },
                            child: _buildSeekAnimation(isForward: false, amount: _backwardSeekAmount),
                          ),
                        ),
                        // àªœàª®àª£à«€ àª¬àª¾àªœà« - 10, 20, 30 sec Forward
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: cancelAndRestartTimer,
                            onDoubleTap: () {
                              _forwardTimer?.cancel();
                              setState(() {
                                _forwardSeekAmount += 10;
                                _seekForward();
                              });
                              _forwardTimer = Timer(const Duration(milliseconds: 700), () {
                                if (mounted) setState(() => _forwardSeekAmount = 0);
                              });
                            },
                            child: _buildSeekAnimation(isForward: true, amount: _forwardSeekAmount),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                  if(!_displayBufferingIndicator)
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
      ) async
  {
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

        // àª¨à«‡àª•à«àª¸à«àªŸ àªµà«€àª¡àª¿àª¯à«‹ àª•à«‹àª² àª•àª°à«‹
        chewieController.onNextVideo?.call();

        // àª¨àªµà«àª‚ àª•àª‚àªŸà«àª°à«‹àª²àª° àª®à«‡àª³àªµà«‹ (àªœà«‡ ChewieController àª®àª¾àª‚ àª…àªªàª¡à«‡àªŸ àª¥àª¯à«àª‚ àª¹àª¶à«‡)
        controller = chewieController.videoPlayerController;

        // àª¨àªµàª¾ àª•àª‚àªŸà«àª°à«‹àª²àª° àªªàª° àª²àª¿àª¸àª¨àª° àª²àª—àª¾àªµà«‹
        controller.addListener(_updateState);

        // àª«àª°à«€àª¥à«€ àªˆàª¨àª¿àª¶àª¿àª¯àª²àª¾àªˆàª àª•àª°à«‹ àªœà«‡àª¥à«€ UI àª°àª¿àª«à«àª°à«‡àª¶ àª¥àª¾àª¯
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
    _hideTimer?.cancel();
    _initTimer?.cancel();
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
      oldController?.videoPlayerController.removeListener(_updateState);

      controller = chewieController.videoPlayerController;

      controller.removeListener(_updateState);
      controller.addListener(_updateState);

      _initialize();
    }
    super.didChangeDependencies();
  }

  Widget _buildActionBar() {
    return AbsorbPointer(absorbing: isLocked, child: _buildOptionsButton());
  }

  Widget _buildLockButton() {
    return AnimatedOpacity(
      // hideStuff true opacity 0 (default), 1.0 (default)
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: AbsorbPointer(
        absorbing: notifier.hideStuff,
        child: GestureDetector(
          onTap: () {
            setState(() {
              isLocked = !isLocked; // Toggle Lock
            });
            if (isLocked) {
              cancelAndRestartTimer();
            }
          },
          child: AppImage(
            height: 40,
            width: 40,
            src: isLocked
                ? "assets/svg_icon/ic_lock.svg"
                : "assets/svg_icon/ic_unlock.svg",
          ),
        ),
      ),
    );
  }

  List<OptionItem> _buildOptions(BuildContext context) {
    final options = <OptionItem>[
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
      ),
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
        width: double.infinity,
        decoration: BoxDecoration(color: backgroundColor.withOpacity(0.40)),
        height: barHeight + (chewieController.isFullScreen ? 2.0 : 0),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: !chewieController.isFullScreen ? 0.0 : 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Flexible(
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: <Widget>[
            //     ],
            //   ),
            // ),
            // SizedBox(height: chewieController.isFullScreen ? 15.0 : 0),
            if (!chewieController.isLive)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
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
/*
    Widget _buildHitArea() {
    return Expanded(
      child: Row(
        children: [
          // àª¡àª¾àª¬à«€ àª¬àª¾àªœà«àª¨à«‹ àª­àª¾àª— (Double Tap for Backward)
          Expanded(
            child: GestureDetector(
              onTap: () => cancelAndRestartTimer(),
              onDoubleTap: _seekBackward, // 10 sec àªªàª¾àª›àª³
              child: Container(color: Colors.transparent),
            ),
          ),

          // àªµàªšà«àªšà«‡àª¨à«‹ àª­àª¾àª— (Play/Pause àª¬àªŸàª¨ àª®àª¾àªŸà«‡)
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

          // àªœàª®àª£à«€ àª¬àª¾àªœà«àª¨à«‹ àª­àª¾àª— (Double Tap for Forward)
          Expanded(
            child: GestureDetector(
              onTap: () => cancelAndRestartTimer(),
              onDoubleTap: _seekForward, // 10 sec àª†àª—àª³
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
   */
  int _backwardSeekAmount = 0;
  int _forwardSeekAmount = 0;
  Timer? _backwardTimer;
  Timer? _forwardTimer;

  Widget _buildHitArea() {
    return IgnorePointer(
      ignoring: notifier.hideStuff, // àªœà«‹ àª•àª‚àªŸà«àª°à«‹àª²à«àª¸ àª¹àª¾àªˆàª¡ àª¹à«‹àª¯ àª¤à«‹ àª¬àªŸàª¨ àªªàª° àª•à«àª²àª¿àª• àª¨ àª¥àª¾àª¯
      child: AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                    show: true, // àª…àª¹à«€àª‚ true àª°àª¾àª–àªµà«àª‚ àª•àª¾àª°àª£ àª•à«‡ àªªà«‡àª°à«‡àª¨à«àªŸàª®àª¾àª‚ Opacity àª›à«‡
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
                  show: true,
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
                    show: true,
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

  Widget _buildSeekAnimation({required bool isForward, required int amount}) {
    if (amount == 0) return const SizedBox.expand();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // GIF àªœà«‡àªµà«àª‚ àªàª¨àª¿àª®à«‡àª¶àª¨ àª†àªªàªµàª¾ àª®àª¾àªŸà«‡ TweenAnimationBuilder
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: (value * 2 % 1.0), // àª†àª¨àª¾àª¥à«€ àª†àªˆàª•àª¨ àª¬à«àª²àª¿àª‚àª• àª¥àª¶à«‡
                child: Transform.scale(
                  scale: 0.8 + (value * 0.4), // àª¥à«‹àª¡à«àª‚ àªà«‚àª®-àªˆàª¨ àªàª¨àª¿àª®à«‡àª¶àª¨
                  child: Icon(
                    isForward ? Icons.fast_forward : Icons.fast_rewind,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            "$amount Seconds",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              shadows: [Shadow(blurRadius: 5, color: Colors.black)],
            ),
          ),
        ],
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
      return;

    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      try {
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
      try {
        if (mounted) notifier.hideStuff = true;
      } catch (e) {
        debugPrint("Notifier disposed");
      }

      try {
        if (_chewieController != null) {
          _chewieController!.toggleFullScreen();
        }
      } catch (e) {
        debugPrint("ChewieController was already disposed, ignoring toggle.");
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        return;
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

  void _playPause() {
    if (!_isControllerAlive)
      return;
    final videoController = chewieController.videoPlayerController;
    final bool isFinished =
        videoPlayerLatestValue.position >= videoPlayerLatestValue.duration;

    if (videoController.value.isPlaying) {
      if (mounted) notifier.hideStuff = false;
      _hideTimer?.cancel();

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
      return mounted &&
          _chewieController != null &&
          chewieController.videoPlayerController.value.isInitialized;
    } catch (_) {
      return false;
    }
  }

  void _seekRelative(Duration relativeSeek) {
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