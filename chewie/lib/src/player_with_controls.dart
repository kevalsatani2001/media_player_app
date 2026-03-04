import 'dart:ui' as ui;

import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/helpers/adaptive_controls.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../widgets/custom_loader.dart';

// PlayerWithControls.dart

// ... બાકીના ઈમ્પોર્ટસ

class PlayerWithControls extends StatelessWidget {
  const PlayerWithControls({super.key});

  @override
  Widget build(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);
    final controller = chewieController.videoPlayerController;

    // વીડિયો પૂરો થાય ત્યારે પોપ કરવા માટેનું ફંક્શન
    void handleVideoEnd(VideoPlayerValue value) {
      if (value.isInitialized && value.position >= value.duration && value.duration != Duration.zero) {
        // Build મેથડ ચાલતી હોય ત્યારે સીધું Pop ના કરી શકાય, એટલે microtask વાપરવું
        Future.microtask(() {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      }
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Center(
          child: SizedBox(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            child: ValueListenableBuilder(
              // અહીં hashCode વાપરવાથી જ્યારે કંટ્રોલર બદલાશે ત્યારે નવો બિલ્ડર બનશે
              key: ValueKey(controller.hashCode),
              valueListenable: controller,
              builder: (context, VideoPlayerValue value, child) {

                // ૧. જો કંટ્રોલર dispose થઈ ગયું હોય તો અહીં જ અટકી જાવ
                // (ValueListenableBuilder કેટલીકવાર જૂની વેલ્યુ મોકલે છે)

                // ૨. વીડિયો પૂરો થયો છે કે નહીં તે ચેક કરો
                handleVideoEnd(value);

                if (!value.isInitialized) {
                  return const Center(child: CustomLoader());
                }

                return AspectRatio(
                  aspectRatio: value.aspectRatio,
                  child: buildPlayerWithControls(chewieController, context),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // buildPlayerWithControls ફંક્શનને થોડું સાફ (Clean) કરીએ
  Widget buildPlayerWithControls(ChewieController chewieController, BuildContext context) {
    final videoKey = ValueKey(chewieController.videoPlayerController.hashCode);

    return Stack(
      children: [
        // ડાયનેમિક બેકગ્રાઉન્ડ
        Positioned.fill(
          child: ClipRect(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Transform.scale(
                scale: 1.5,
                child: VideoPlayer(chewieController.videoPlayerController, key: videoKey),
              ),
            ),
          ),
        ),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.4))),

        // મેઈન પ્લેયર
        Center(
          child: AspectRatio(
            aspectRatio: chewieController.videoPlayerController.value.aspectRatio,
            child: VideoPlayer(chewieController.videoPlayerController, key: videoKey),
          ),
        ),

        // કંટ્રોલ્સ
        if (!chewieController.isFullScreen)
          _buildControls(context, chewieController)
        else
          SafeArea(child: _buildControls(context, chewieController)),
      ],
    );
  }

  Widget _buildControls(BuildContext context, ChewieController chewieController) {
    return chewieController.showControls
        ? chewieController.customControls ?? const AdaptiveControls()
        : const SizedBox();
  }
}