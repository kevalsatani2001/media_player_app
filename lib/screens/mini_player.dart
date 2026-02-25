



import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_player/core/constants.dart';
import 'package:media_player/screens/player_screen.dart';
import 'package:media_player/widgets/favourite_button.dart';
import 'package:media_player/widgets/image_widget.dart';
import 'package:media_player/widgets/text_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import '../blocs/audio/audio_bloc.dart';
import '../models/media_item.dart';
import '../services/global_player.dart';
import '../widgets/common_methods.dart';

class SmartMiniPlayer extends StatefulWidget {
  const SmartMiniPlayer({super.key});

  @override
  State<SmartMiniPlayer> createState() => _SmartMiniPlayerState();
}

class _SmartMiniPlayerState extends State<SmartMiniPlayer> {
  final GlobalPlayer player = GlobalPlayer();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // વીડિયો પોઝિશન અપડેટ કરવા માટે ટાઈમર
    player.restoreLastSession();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      // સુધારેલું: player.videoController વાપરો
      if (player.currentType == "video" &&
          player.videoController != null &&
          player.videoController!.value.isInitialized) {
        if (mounted) setState(() {});
      }
    });
  }

  /*
  @override
void initState() {
  super.initState();
  // પ્લેયરને છેલ્લી પોઝિશનથી લોડ કરવા માટે
  player.restoreLastSession();

  _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
    // તમારો જૂનો ટાઈમર કોડ...
  });
}
   */

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 360;

    return SafeArea(
      child: AnimatedBuilder(
          animation: player,
          builder: (context, child) {
            // આ શરત સૌથી મહત્વની છે
            if (player.currentIndex == -1 ||player.currentMediaItem == null || player.currentEntity == null) {
              return const SizedBox.shrink();
            }

            // વીડિયો પ્લેયર માટેની શરત
            if (player.currentType == "video") {
              if (player.videoController == null || !player.videoController!.value.isInitialized) {
                return const SizedBox.shrink();
              }
              return _buildVideoMiniPlayer(
                size: size,
                isSmall: isSmallScreen,
                // ID અને Favourite સ્ટેટ સાથેની કી
                key: ValueKey('video_${player.currentEntity!.id}'),
              );
            } else {
              // ઓડિયો પ્લેયર
              return _buildAudioMiniPlayer(
                key: ValueKey('audio_${player.currentEntity!.id}'),
                size: size,
                isSmall: isSmallScreen,
              );
            }
          }
      ),
    );
  }

  Widget _buildAudioMiniPlayer({
    required Size size,
    required bool isSmall,
    Key? key,
  }) {
    final item = player.currentMediaItem!;
    return _wrapper(
      key: key,
      isAudio: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: 12,
            ),
            child: Row(
              children: [
                AppImage(
                  src: AppSvg.musicUnselected,
                  height: isSmall ? 18 : 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _titleText(),
                      AppText(
                        "playingFromLocal",
                        fontSize: isSmall ? 10 : 12,
                      ),
                    ],
                  ),
                ),
                // ફેવરિટ બટન: લાઈવ એન્ટિટી વાપરો
                if(player.currentEntity!=null)
                  FavouriteButton(
                    key: ValueKey('${player.currentEntity?.id}_${player.currentEntity?.isFavorite}'),
                    entity: player.currentEntity!, // GlobalPlayer માંથી એન્ટિટી લો
                  ),
                _closeButton(Colors.black),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.topCenter,
            children: [
              ClipPath(
                clipper: NativeClipper(),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.03),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoButton(
                            onPressed: () => player.playPrevious(),
                            child: AppImage(src: AppSvg.skipPrev),
                          ),
                          _playPauseButton(Colors.black),
                          CupertinoButton(
                            onPressed: () => player.playNext(),
                            child: AppImage(src: AppSvg.skipNext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 0),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: _audioProgressBar(),
              ),
            ],
          ),
        ],
      ),
    );
  }


// --- ઓડિયો પ્રોગ્રેસ બાર (int position/duration નો ઉપયોગ કરીને) ---
  Widget _audioProgressBar() {
    // અહીં આપણે AnimatedBuilder વાપરી શકીએ અથવા StreamBuilder
    // જો તમે player.position (int) ને AnimatedBuilder સાથે સિંક કર્યું હોય તો:


    return StreamBuilder<Duration>(
        stream: player.audioPlayer.positionStream,
        builder: (context, snapshot) {
          final int positionMs = snapshot.data?.inMilliseconds ?? 0; // Fix Line 170
          final int durationMs = player.audioPlayer.duration?.inMilliseconds ?? 0; // Fix Line 171

          double progress = 0.0;
          if (durationMs > 0) {
            progress = (positionMs / durationMs).clamp(0.0, 1.0);
          }
          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              final box = context.findRenderObject() as RenderBox;
              final localOffset = box.globalToLocal(details.globalPosition);
              final double relativeProgress = (localOffset.dx / box.size.width).clamp(0.0, 1.0);

              // int મિલીસેકન્ડમાં કન્વર્ટ કરીને સીક (Seek) કરો
              final int newPosMs = (durationMs * relativeProgress).toInt();
              player.audioPlayer.seek(Duration(milliseconds: newPosMs));
            },
            child: Container(
              width: double.infinity,
              height: 30,
              color: Colors.transparent,
              child: CustomPaint(painter: CurveProgressPainter(progress)),
            ),
          );
        }
    );
  }

// --- વીડિયો મિની પ્લેયર (int position/duration નો ઉપયોગ કરીને) ---
  Widget _buildVideoMiniPlayer({
    required Size size,
    required bool isSmall,
    Key? key,
  }) {
    // માત્ર initialized જ નહીં, પણ controller નલ ન હોવો જોઈએ તે પણ ચેક કરો
    if (player.videoController == null ||
        !player.videoController!.value.isInitialized ||
        player.currentType != "video") {
      return const SizedBox.shrink();
    }

    // ValueListenableBuilder વીડિયો સ્મૂધ રાખવા માટે જરૂરી છે
    return ValueListenableBuilder(
      valueListenable: player.videoController!,
      builder: (context, VideoPlayerValue value, child) {
        // અહીં ખાતરી કરો કે controller નલ નથી
        final controller = player.videoController;
        if (controller == null || !controller.value.isInitialized) {
          return const SizedBox.shrink();
        }
        if (value.hasError) return const SizedBox.shrink();
        // અહીં પણ આપણે player.position/duration (int) વાપરી શકીએ
        final int pos = value.position.inMilliseconds; // .inMilliseconds ઉમેરો
        final int dur = value.duration.inMilliseconds; // .inMilliseconds ઉમેરો

        double progress = 0.0;
        if (dur > 0) {
          progress = (pos / dur).clamp(0.0, 1.0);
        }

        return _wrapper(
          key: key,
          isAudio: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 120, height: 70,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: value.size.width,
                        height: value.size.height,
                        child: VideoPlayer(player.videoController!,
                          key: ValueKey(player.videoController.hashCode),),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        player.currentMediaItem?.path.split('/').last ?? "",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress, // int માંથી ગણેલ લાઈવ પ્રોગ્રેસ
                          backgroundColor: Colors.white24,
                          color: Colors.redAccent,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${formatDuration(pos)} / ${formatDuration(dur)}", // સીધું int પાસ કરો
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white, size: 22),
                      onPressed: () {
                        player.videoController!.seekTo(Duration(milliseconds: pos - 10000));
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: Colors.white, size: 35,
                      ),
                      onPressed: () => value.isPlaying ? player.pause() : player.resume(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white, size: 22),
                      onPressed: () {
                        player.videoController!.seekTo(Duration(milliseconds: pos + 10000));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _wrapper({required Widget child, required bool isAudio, Key? key}) {
    final item = player.currentMediaItem;
    return GestureDetector(
      key: key,
      onTap: () {
        if (item == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              entity: player.currentEntity!, // લાઈવ એન્ટિટી મોકલો
              item: item,
              index: player.currentIndex,
              entityList: const [], // જરૂર હોય તો આખું લિસ્ટ મોકલી શકાય
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isAudio ? Colors.grey[300] : Colors.black87,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            topLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _titleText({Color color = Colors.black}) {
    final path = player.currentMediaItem?.path;
    final String fileName = path != null ? path.split('/').last : "noMedia";
    return AppText(fileName, maxLines: 2, color: color, fontWeight: FontWeight.w700);
  }

  Widget _playPauseButton(Color color) {
    return CupertinoButton(
      child: AppImage(
        src: player.isPlaying ? AppSvg.pauseVid : AppSvg.playVid,
        height: 45, width: 45,
      ),
      onPressed: () => player.isPlaying ? player.pause() : player.resume(),
    );
  }

  Widget _closeButton(Color color) {
    return IconButton(
      icon: AppImage(src: AppSvg.closeIcon),
      onPressed: () {
        // પ્લેયરને બંધ કરીને ડેટા ક્લિયર કરો
        player.stopAndClose();
      },
    );
  }

}

class CurveProgressPainter extends CustomPainter {
  final double progress;

  CurveProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    Paint progressPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // આ એક કર્વ (Arc) દોરશે.
    // -1.2 થી 1.2 સુધીની વેલ્યુથી તે ઉપરની તરફ વળેલો દેખાશે.
    Path path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      -size.height,
      size.width,
      size.height,
    );

    canvas.drawPath(path, backgroundPaint);

    // પ્રોગ્રેસ મુજબ લાઈન દોરવા માટે
    ui.PathMetrics pathMetrics = path.computeMetrics();
    for (ui.PathMetric pathMetric in pathMetrics) {
      canvas.drawPath(
        pathMetric.extractPath(0, pathMetric.length * progress),
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NativeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    // ૧. શરૂઆત નીચે ડાબી બાજુથી (Bottom Left)
    path.moveTo(0, size.height);

    // ૨. ઉપર ડાબી બાજુ સુધી લાઈન દોરો, પણ થોડી જગ્યા છોડો (દા.ત. 50px)
    path.lineTo(0, 48);

    // ૩. ઉપરની બાજુ કર્વ દોરો
    // size.width / 2 એ સેન્ટર છે અને બીજો 0 એ સૌથી ઉપરનો પોઈન્ટ (Peak) છે
    path.quadraticBezierTo(size.width / 2, 0, size.width, 48);

    // ૪. જમણી બાજુ નીચે સુધી લાઈન
    path.lineTo(size.width, size.height);

    // ૫. પાથ બંધ કરો
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}




















//
//
//
//
// import 'dart:async';
// import 'dart:ui' as ui;
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:media_player/core/constants.dart';
// import 'package:media_player/screens/player_screen.dart';
// import 'package:media_player/widgets/favourite_button.dart';
// import 'package:media_player/widgets/image_widget.dart';
// import 'package:media_player/widgets/text_widget.dart';
// import 'package:photo_manager/photo_manager.dart';
// import 'package:video_player/video_player.dart';
// import '../blocs/audio/audio_bloc.dart';
// import '../models/media_item.dart';
// import '../services/global_player.dart';
// import '../widgets/common_methods.dart';
//
// class SmartMiniPlayer extends StatefulWidget {
//   const SmartMiniPlayer({super.key});
//
//   @override
//   State<SmartMiniPlayer> createState() => _SmartMiniPlayerState();
// }
//
// class _SmartMiniPlayerState extends State<SmartMiniPlayer> {
//   final GlobalPlayer player = GlobalPlayer();
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     // વીડિયો પોઝિશન અપડેટ કરવા માટે ટાઈમર
//     player.restoreLastSession();
//     _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
//       // સુધારેલું: player.videoController વાપરો
//       if (player.currentType == "video" &&
//           player.videoController != null &&
//           player.videoController!.value.isInitialized) {
//         if (mounted) setState(() {});
//       }
//     });
//   }
//
//   /*
//   @override
// void initState() {
//   super.initState();
//   // પ્લેયરને છેલ્લી પોઝિશનથી લોડ કરવા માટે
//   player.restoreLastSession();
//
//   _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
//     // તમારો જૂનો ટાઈમર કોડ...
//   });
// }
//    */
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final bool isSmallScreen = size.width < 360;
//
//     return SafeArea(
//       child: AnimatedBuilder(
//           animation: player,
//           builder: (context, child) {
//             // આ શરત સૌથી મહત્વની છે
//             if (player.currentIndex == -1 ||player.currentMediaItem == null || player.currentEntity == null) {
//               return const SizedBox.shrink();
//             }
//
//             // વીડિયો પ્લેયર માટેની શરત
//             if (player.currentType == "video") {
//               if (player.videoController == null || !player.videoController!.value.isInitialized) {
//                 return const SizedBox.shrink();
//               }
//               return _buildVideoMiniPlayer(
//                 size: size,
//                 isSmall: isSmallScreen,
//                 // ID અને Favourite સ્ટેટ સાથેની કી
//                 key: ValueKey('video_${player.currentEntity!.id}'),
//               );
//             } else {
//               // ઓડિયો પ્લેયર
//               return _buildAudioMiniPlayer(
//                 key: ValueKey('audio_${player.currentEntity!.id}'),
//                 size: size,
//                 isSmall: isSmallScreen,
//               );
//             }
//           }
//       ),
//     );
//   }
//
//   Widget _buildAudioMiniPlayer({
//     required Size size,
//     required bool isSmall,
//     Key? key,
//   }) {
//     final item = player.currentMediaItem!;
//     return _wrapper(
//       key: key,
//       isAudio: true,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: size.width * 0.04,
//               vertical: 12,
//             ),
//             child: Row(
//               children: [
//                 AppImage(
//                   src: AppSvg.musicUnselected,
//                   height: isSmall ? 18 : 22,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _titleText(),
//                       AppText(
//                         "playingFromLocal",
//                         fontSize: isSmall ? 10 : 12,
//                       ),
//                     ],
//                   ),
//                 ),
//                 // ફેવરિટ બટન: લાઈવ એન્ટિટી વાપરો
//                 if(player.currentEntity!=null)
//                   FavouriteButton(
//                     key: ValueKey('${player.currentEntity?.id}_${player.currentEntity?.isFavorite}'),
//                     entity: player.currentEntity!, // GlobalPlayer માંથી એન્ટિટી લો
//                   ),
//                 _closeButton(Colors.black),
//               ],
//             ),
//           ),
//           Stack(
//             alignment: Alignment.topCenter,
//             children: [
//               ClipPath(
//                 clipper: NativeClipper(),
//                 child: Container(
//                   width: double.infinity,
//                   color: Colors.white,
//                   child: Column(
//                     children: [
//                       SizedBox(height: size.height * 0.03),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           CupertinoButton(
//                             onPressed: () => player.playPrevious(),
//                             child: AppImage(src: AppSvg.skipPrev),
//                           ),
//                           _playPauseButton(Colors.black),
//                           CupertinoButton(
//                             onPressed: () => player.playNext(),
//                             child: AppImage(src: AppSvg.skipNext),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 0),
//                     ],
//                   ),
//                 ),
//               ),
//               Positioned(
//                 top: 20,
//                 left: 0,
//                 right: 0,
//                 child: _audioProgressBar(),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//
// // --- ઓડિયો પ્રોગ્રેસ બાર (int position/duration નો ઉપયોગ કરીને) ---
//   Widget _audioProgressBar() {
//     // અહીં આપણે AnimatedBuilder વાપરી શકીએ અથવા StreamBuilder
//     // જો તમે player.position (int) ને AnimatedBuilder સાથે સિંક કર્યું હોય તો:
//
//
//     return StreamBuilder<Duration>(
//         stream: player.audioPlayer.positionStream,
//         builder: (context, snapshot) {
//           final int positionMs = snapshot.data?.inMilliseconds ?? 0; // Fix Line 170
//           final int durationMs = player.audioPlayer.duration?.inMilliseconds ?? 0; // Fix Line 171
//
//           double progress = 0.0;
//           if (durationMs > 0) {
//             progress = (positionMs / durationMs).clamp(0.0, 1.0);
//           }
//           return GestureDetector(
//             onHorizontalDragUpdate: (details) {
//               final box = context.findRenderObject() as RenderBox;
//               final localOffset = box.globalToLocal(details.globalPosition);
//               final double relativeProgress = (localOffset.dx / box.size.width).clamp(0.0, 1.0);
//
//               // int મિલીસેકન્ડમાં કન્વર્ટ કરીને સીક (Seek) કરો
//               final int newPosMs = (durationMs * relativeProgress).toInt();
//               player.audioPlayer.seek(Duration(milliseconds: newPosMs));
//             },
//             child: Container(
//               width: double.infinity,
//               height: 30,
//               color: Colors.transparent,
//               child: CustomPaint(painter: CurveProgressPainter(progress)),
//             ),
//           );
//         }
//     );
//   }
//
// // --- વીડિયો મિની પ્લેયર (int position/duration નો ઉપયોગ કરીને) ---
//   Widget _buildVideoMiniPlayer({
//     required Size size,
//     required bool isSmall,
//     Key? key,
//   }) {
//     // માત્ર initialized જ નહીં, પણ controller નલ ન હોવો જોઈએ તે પણ ચેક કરો
//     if (player.videoController == null ||
//         !player.videoController!.value.isInitialized ||
//         player.currentType != "video") {
//       return const SizedBox.shrink();
//     }
//
//     // ValueListenableBuilder વીડિયો સ્મૂધ રાખવા માટે જરૂરી છે
//     return ValueListenableBuilder(
//       valueListenable: player.videoController!,
//       builder: (context, VideoPlayerValue value, child) {
//         // અહીં ખાતરી કરો કે controller નલ નથી
//         final controller = player.videoController;
//         if (controller == null || !controller.value.isInitialized) {
//           return const SizedBox.shrink();
//         }
//         if (value.hasError) return const SizedBox.shrink();
//         // અહીં પણ આપણે player.position/duration (int) વાપરી શકીએ
//         final int pos = value.position.inMilliseconds; // .inMilliseconds ઉમેરો
//         final int dur = value.duration.inMilliseconds; // .inMilliseconds ઉમેરો
//
//         double progress = 0.0;
//         if (dur > 0) {
//           progress = (pos / dur).clamp(0.0, 1.0);
//         }
//
//         return _wrapper(
//           key: key,
//           isAudio: false,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
//             child: Row(
//               children: [
//                 SizedBox(
//                   width: 120, height: 70,
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: FittedBox(
//                       fit: BoxFit.cover,
//                       child: SizedBox(
//                         width: value.size.width,
//                         height: value.size.height,
//                         child: VideoPlayer(player.videoController!,
//                           key: ValueKey(player.videoController.hashCode),),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         player.currentMediaItem?.path.split('/').last ?? "",
//                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 4),
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(10),
//                         child: LinearProgressIndicator(
//                           value: progress, // int માંથી ગણેલ લાઈવ પ્રોગ્રેસ
//                           backgroundColor: Colors.white24,
//                           color: Colors.redAccent,
//                           minHeight: 6,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         "${formatDuration(pos)} / ${formatDuration(dur)}", // સીધું int પાસ કરો
//                         style: const TextStyle(color: Colors.white70, fontSize: 11),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.replay_10, color: Colors.white, size: 22),
//                       onPressed: () {
//                         player.videoController!.seekTo(Duration(milliseconds: pos - 10000));
//                       },
//                     ),
//                     IconButton(
//                       icon: Icon(
//                         value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
//                         color: Colors.white, size: 35,
//                       ),
//                       onPressed: () => value.isPlaying ? player.pause() : player.resume(),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.forward_10, color: Colors.white, size: 22),
//                       onPressed: () {
//                         player.videoController!.seekTo(Duration(milliseconds: pos + 10000));
//                       },
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _wrapper({required Widget child, required bool isAudio, Key? key}) {
//     final item = player.currentMediaItem;
//     return GestureDetector(
//       key: key,
//       onTap: () {
//         if (item == null) return;
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => PlayerScreen(
//               entity: player.currentEntity!, // લાઈવ એન્ટિટી મોકલો
//               item: item,
//               index: player.currentIndex,
//               entityList: const [], // જરૂર હોય તો આખું લિસ્ટ મોકલી શકાય
//             ),
//           ),
//         );
//       },
//       child: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: isAudio ? Colors.grey[300] : Colors.black87,
//           borderRadius: const BorderRadius.only(
//             topRight: Radius.circular(20),
//             topLeft: Radius.circular(20),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               blurRadius: 4,
//               offset: const Offset(0, -3),
//             ),
//           ],
//         ),
//         child: child,
//       ),
//     );
//   }
//
//   Widget _titleText({Color color = Colors.black}) {
//     final path = player.currentMediaItem?.path;
//     final String fileName = path != null ? path.split('/').last : "noMedia";
//     return AppText(fileName, maxLines: 2, color: color, fontWeight: FontWeight.w700);
//   }
//
//   Widget _playPauseButton(Color color) {
//     return CupertinoButton(
//       child: AppImage(
//         src: player.isPlaying ? AppSvg.pauseVid : AppSvg.playVid,
//         height: 45, width: 45,
//       ),
//       onPressed: () => player.isPlaying ? player.pause() : player.resume(),
//     );
//   }
//
//   Widget _closeButton(Color color) {
//     return IconButton(
//       icon: AppImage(src: AppSvg.closeIcon),
//       onPressed: () {
//         // પ્લેયરને બંધ કરીને ડેટા ક્લિયર કરો
//         player.stopAndClose();
//       },
//     );
//   }
//
// }
//
// class CurveProgressPainter extends CustomPainter {
//   final double progress;
//
//   CurveProgressPainter(this.progress);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint backgroundPaint = Paint()
//       ..color = Colors.blue.withOpacity(0.1)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 4
//       ..strokeCap = StrokeCap.round;
//
//     Paint progressPaint = Paint()
//       ..color = Colors.blueAccent
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 5
//       ..strokeCap = StrokeCap.round;
//
//     // આ એક કર્વ (Arc) દોરશે.
//     // -1.2 થી 1.2 સુધીની વેલ્યુથી તે ઉપરની તરફ વળેલો દેખાશે.
//     Path path = Path();
//     path.moveTo(0, size.height);
//     path.quadraticBezierTo(
//       size.width / 2,
//       -size.height,
//       size.width,
//       size.height,
//     );
//
//     canvas.drawPath(path, backgroundPaint);
//
//     // પ્રોગ્રેસ મુજબ લાઈન દોરવા માટે
//     ui.PathMetrics pathMetrics = path.computeMetrics();
//     for (ui.PathMetric pathMetric in pathMetrics) {
//       canvas.drawPath(
//         pathMetric.extractPath(0, pathMetric.length * progress),
//         progressPaint,
//       );
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
//
// class NativeClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     Path path = Path();
//
//     // ૧. શરૂઆત નીચે ડાબી બાજુથી (Bottom Left)
//     path.moveTo(0, size.height);
//
//     // ૨. ઉપર ડાબી બાજુ સુધી લાઈન દોરો, પણ થોડી જગ્યા છોડો (દા.ત. 50px)
//     path.lineTo(0, 48);
//
//     // ૩. ઉપરની બાજુ કર્વ દોરો
//     // size.width / 2 એ સેન્ટર છે અને બીજો 0 એ સૌથી ઉપરનો પોઈન્ટ (Peak) છે
//     path.quadraticBezierTo(size.width / 2, 0, size.width, 48);
//
//     // ૪. જમણી બાજુ નીચે સુધી લાઈન
//     path.lineTo(size.width, size.height);
//
//     // ૫. પાથ બંધ કરો
//     path.close();
//
//     return path;
//   }
//
//   @override
//   bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
// }
//
