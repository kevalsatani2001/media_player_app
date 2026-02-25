import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import '../core/constants.dart';
import '../models/media_item.dart';
import '../services/global_player.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_loader.dart';
import '../widgets/customa_shape.dart';
import '../widgets/favourite_button.dart';
import '../widgets/image_widget.dart';

class PlayerScreen extends StatefulWidget {
  final MediaItem item;
  final int? index;
  final AssetEntity entity;
  final List<AssetEntity>? entityList;
  bool isPlaylist;

  PlayerScreen({
    super.key,
    required this.item,
    this.index = 0,
    required this.entity,
    this.entityList = const [],
    this.isPlaylist = false,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  // GlobalPlayer ની ઇન્સ્ટન્સ લો
  final GlobalPlayer player = GlobalPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // પ્લેયર સેટઅપ: જો નવું આઈટમ હોય તો જ પ્લે કરો
    _setupInitialPlayer();
  }

  // Future<void> _setupInitialPlayer() async {
  //   // જો તે જ આઈટમ અત્યારે વાગી રહી હોય, તો ફરીથી init કરવાની જરૂર નથી
  //   if (player.currentMediaItem?.id == widget.entity.id) {
  //     return;
  //   }
  //
  //   if (widget.entityList != null && widget.entityList!.isNotEmpty) {
  //     await player.initAndPlay(
  //       entities: widget.entityList!,
  //       selectedId: widget.entity.id,
  //     );
  //   }
  // }

  Future<void> _setupInitialPlayer() async {
    // ૧. જો તે જ આઈટમ અત્યારે વાગી રહી હોય, તો ફરીથી લોડ ન કરો
    if (player.currentEntity?.id == widget.entity.id) {
      return;
    }

    // ૨. પ્લેલિસ્ટ માટે લિસ્ટ પાસ કરો
    if (widget.entityList != null && widget.entityList!.isNotEmpty) {
      await player.initAndPlay(
        entities: widget.entityList!,
        selectedId: widget.entity.id,
      );
    } else {
      // જો સિંગલ આઈટમ હોય તો પણ તેને લિસ્ટ તરીકે મોકલો
      await player.initAndPlay(
        entities: [widget.entity],
        selectedId: widget.entity.id,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (player.currentType == "video") {
        player.pause();
      }
    }
  }

  // ટાઇટલ મેળવવા માટે સીધું પ્લેયરનો ડેટા વાપરો
  String getTitle() {
    final activeItem = player.currentMediaItem ?? widget.item;
    return activeItem.path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return AnimatedBuilder(
      animation: player, // પ્લેયરના દરેક ફેરફાર પર UI અપડેટ થશે
      builder: (context, _) {
        // લાઈવ ડેટા
        final activeItem = player.currentMediaItem ?? widget.item;
        final bool isAudio = activeItem.type == "audio";

        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: AppText(
              isAudio ? "audio" : getTitle(),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            leading: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: AppImage(
                  src: AppSvg.backArrowIcon,
                  height: 20,
                  width: 20,
                ),
              ),
            ),
            centerTitle: true,
            actions: [
              // ફેવરિટ બટન: પ્લેયરની લાઈવ એન્ટિટી વાપરો
              if ((player.currentEntity ?? widget.entity).typeInt == 2)
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: FavouriteButton(
                    entity: player.currentEntity ?? widget.entity,
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: isAudio
                    ? _buildAudioPlayer() // લોજિક આની અંદર બદલાશે
                    : _buildVideoPlayer(),
              ),
              if (false) // isLocked લોજિક જો જોઈતું હોય તો
                const Positioned(
                  top: 16,
                  right: 16,
                  child: Icon(Icons.lock, color: Colors.white),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudioPlayer() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: colors.whiteColor),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 70),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56),
            child: SizedBox(
              height: 345,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: 320,
                    decoration: ShapeDecoration(
                      shape: CustomShape(),
                      color: colors.background,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(23),
                      child:
                      AppImage(
                        src: AppSvg.musicSelected,
                        fit: BoxFit.cover,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.whiteColor,
                          boxShadow: [
                            BoxShadow(
                              offset: const Offset(0, 0),
                              blurRadius: 15,
                              color: colors.blackColor.withOpacity(0.20),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: FavouriteButton(
                            key: ValueKey(
                              player.currentEntity?.id ?? widget.entity.id,
                            ),
                            entity: player.currentEntity ?? widget.entity,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 62),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppText(
              getTitle(),
              fontSize: 18,
              maxLines: 2,
              fontWeight: FontWeight.w600,
              color: colors.grey1,
              align: TextAlign.center,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: StreamBuilder<Duration>(
              stream: player.audioPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = player.audioPlayer.duration ?? Duration.zero;

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: SliderComponentShape.noThumb,
                        trackHeight: 2,
                        activeTrackColor: colors.primary,
                        inactiveTrackColor: colors.textFieldBorder,
                      ),
                      child: Slider(
                        min: 0,
                        max: duration.inMilliseconds.toDouble().clamp(
                          1,
                          double.infinity,
                        ),
                        value: position.inMilliseconds.toDouble().clamp(
                          0,
                          duration.inMilliseconds.toDouble(),
                        ),
                        onChanged: (v) {
                          player.audioPlayer.seek(
                            Duration(milliseconds: v.toInt()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          _fmt(position),
                          color: colors.primary2,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          onPressed: () => player.playPrevious(), // નવું લોજિક
                          child: AppImage(src: AppSvg.skipPrev),
                        ),
                        const SizedBox(width: 8),
                        StreamBuilder<bool>(
                          stream: player.audioPlayer.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            return IconButton(
                              iconSize: 64,
                              icon: AppImage(
                                src: isPlaying
                                    ? AppSvg.pauseVid
                                    : AppSvg.playVid,
                                height: 61,
                                width: 61,
                              ),
                              onPressed: () =>
                              isPlaying ? player.pause() : player.resume(),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          onPressed: () => player.playNext(), // નવું લોજિક
                          child: AppImage(src: AppSvg.skipNext),
                        ),
                        const SizedBox(width: 8),
                        AppText(
                          _fmt(duration),
                          color: colors.primary2,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                    const SizedBox(height: 62),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    // નવા પ્લેયરમાં videoController અને chewieController ના નામ છે
    if (player.chewieController == null ||
        player.videoController == null ||
        !player.videoController!.value.isInitialized) {
      return _buildVideoLoadingPlaceholder();
    }
    return Chewie(controller: player.chewieController!);
  }

  String _fmt(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  Widget _buildVideoLoadingPlaceholder() {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withOpacity(0.30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(child: CustomLoader()),
    );
  }
}