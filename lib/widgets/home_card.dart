import 'package:flutter/material.dart';
import 'package:media_player/widgets/image_widget.dart';
import 'package:media_player/widgets/text_widget.dart';

import '../utils/app_colors.dart';

class HomeCard extends StatelessWidget {
  final String title;
  final String icon;
  final String route;
  final int count;
  // VoidCallback àªµàª¾àªªàª°àªµà«àª‚ àª¸à«Œàª¥à«€ àª¬à«‡àª¸à«àªŸ àª›à«‡ àª°àª¿àª«à«àª°à«‡àª¶ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡
  final VoidCallback? onBack;

  const HomeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.route,
    required this.count,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return InkWell(
      // ðŸ”´ àª…àª¹à«€àª‚ àª«à«‡àª°àª«àª¾àª° àª›à«‡: .then() àª‰àª®à«‡àª°à«àª¯à«àª‚
      onTap: () {
        Navigator.pushNamed(context, route)
            .then((_) {
          // àªœà«àª¯àª¾àª°à«‡ àª¯à«àªàª° àªªàª¾àª›à«‹ àª†àªµà«‡ àª¤à«àª¯àª¾àª°à«‡ àª† àª«àª‚àª•à«àª¶àª¨ àªšàª¾àª²àª¶à«‡
          if (onBack != null) {
            onBack!();
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: colors.cardBackground
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 19),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppImage(src: icon, height: 35, width: 35,),
              const SizedBox(height: 10),
              AppText(title, fontSize: 20, fontWeight: FontWeight.w500),
              AppText(
                "$count items",
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textFieldBorder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
// import '../blocs/video/video_bloc.dart';
//
// class HomeCard extends StatelessWidget {
//   final String title;
//   final String icon;
//   final String route;
//   final int count;
//   Future<void> loadCounts;
//
//   HomeCard({
//     super.key,
//     required this.title,
//     required this.icon,
//     required this.route,
//     required this.count,
//     required this.loadCounts,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: () => Navigator.pushNamed(context, route).then((value) => loadCounts),
//       child: Card(
//         color: Colors.grey.shade900,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, size: 40, color: Colors.red),
//               const SizedBox(height: 8),
//               Text(
//                 title,
//                 style: const TextStyle(color: Colors.white, fontSize: 16),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 "$count items",
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.7),
//                   fontSize: 13,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }