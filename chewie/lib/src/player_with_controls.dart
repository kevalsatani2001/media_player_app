import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/helpers/adaptive_controls.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../widgets/custom_loader.dart';

class PlayerWithControls extends StatelessWidget {
  const PlayerWithControls({super.key});

  @override
  Widget build(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);
    if (chewieController.videoPlayerController.value.isInitialized == false) {
      return const Center(child: CustomLoader());
    }
    double calculateAspectRatio(BuildContext context) {
      final size = MediaQuery.of(context).size;
      final width = size.width;
      final height = size.height;

      return width > height ? width / height : height / width;
    }

    Widget buildControls(
        BuildContext context,
        ChewieController chewieController,
        ) {
      return chewieController.showControls
          ? chewieController.customControls ?? const AdaptiveControls()
          : const SizedBox();
    }

    Widget buildPlayerWithControls(
        ChewieController chewieController,
        BuildContext context,
        ) {
      final playerNotifier = context.read<PlayerNotifier>();

      // 1. પહેલા માત્ર વિડિયો લેયર બનાવો જેને આપણે ઝૂમ કરવો છે
      Widget videoWidget = Center(
        child: AspectRatio(
          aspectRatio: chewieController.aspectRatio ??
              chewieController.videoPlayerController.value.aspectRatio,
          child: VideoPlayer(
            chewieController.videoPlayerController,
            key: ValueKey(chewieController.videoPlayerController.hashCode),
          ),
        ),
      );

      // 2. જો Zoom એનેબલ હોય, તો માત્ર વિડિયો વિજેટને જ InteractiveViewer માં લપેટો
      if (chewieController.zoomAndPan || chewieController.transformationController != null) {
        videoWidget = InteractiveViewer(
          transformationController: chewieController.transformationController,
          maxScale: chewieController.maxScale,
          panEnabled: chewieController.zoomAndPan,
          scaleEnabled: chewieController.zoomAndPan,
          onInteractionUpdate: chewieController.zoomAndPan
              ? (_) => playerNotifier.hideStuff = true
              : null,
          onInteractionEnd: chewieController.zoomAndPan
              ? (_) => playerNotifier.hideStuff = false
              : null,
          child: videoWidget, // માત્ર વિડિયો ઝૂમ થશે
        );
      }

      // 3. હવે મેઈન સ્ટેક બનાવો જ્યાં કંટ્રોલ્સ ઝૂમની બહાર હશે
      return Stack(
        children: [
          if (chewieController.placeholder != null) chewieController.placeholder!,

          // ઝૂમ થતો વિડિયો (સૌથી નીચેનું લેયર)
          videoWidget,

          if (chewieController.overlay != null) chewieController.overlay!,

          // કંટ્રોલ્સની પાછળનું બ્લેક બેકગ્રાઉન્ડ (જ્યારે કંટ્રોલ્સ દેખાય ત્યારે)
          if (Theme.of(context).platform != TargetPlatform.iOS)
            Consumer<PlayerNotifier>(
              builder: (context, notifier, child) => Visibility(
                visible: !notifier.hideStuff,
                child: AnimatedOpacity(
                  opacity: notifier.hideStuff ? 0.0 : 0.8,
                  duration: const Duration(milliseconds: 250),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black54),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ),

          // કંટ્રોલ્સ લેયર (ઝૂમની બહાર હોવાથી આઈકોન સ્થિર રહેશે)
          if (!chewieController.isFullScreen)
            buildControls(context, chewieController)
          else
            SafeArea(
              bottom: false,
              child: buildControls(context, chewieController),
            ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Center(
          child: SizedBox(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            child: AspectRatio(
              aspectRatio: calculateAspectRatio(context),
              child: buildPlayerWithControls(chewieController, context),
            ),
          ),
        );
      },
    );
  }
}
