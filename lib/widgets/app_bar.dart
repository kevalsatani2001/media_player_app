// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:media_player/widgets/text_widget.dart';
// import '../utils/app_colors.dart';
//
// class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
//   final String? title;
//   final Widget? leading;
//   final List<Widget>? actions;
//   final bool centerTitle;
//
//
//   const CommonAppBar({
//     super.key,
//     this.title,
//     this.leading,
//     this.actions,
//     this.centerTitle = true,
//   });
//
//
//   @override
//   Widget build(BuildContext context) {
//     final colors = Theme.of(context).extension<AppThemeColors>()!;
//     return AppBar(
//       elevation: 0,
//       backgroundColor: colors.background,
//       centerTitle: centerTitle,
//       leading: leading,
//       actions: actions,
//       title: title == null
//           ? null
//           : AppText(
//         title!,
//         fontSize: 18,
//         fontWeight: FontWeight.w600,
//       ),
//       iconTheme:  IconThemeData(color: colors.textPrimary),
//     );
//   }
//
//
//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);
// }

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:media_player/widgets/text_widget.dart';

import '../core/constants.dart';
import '../utils/app_colors.dart';
import 'image_widget.dart';

class CommonAppBar extends StatefulWidget {
  Widget? actionWidget;
  String? title;
  String? subTitle;
   CommonAppBar({super.key,this.actionWidget,this.title,this.subTitle});

  @override
  State<CommonAppBar> createState() => _CommonAppBarState();
}

class _CommonAppBarState extends State<CommonAppBar> {

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AppImage(src: AppSvg.appBarIcon),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                     widget.title??"",
                      fontFamily: AppFontFamily.oleoScript,
                      fontSize: 23,
                      fontWeight: FontWeight.w400,
                      color: colors.appBarTitleColor,
                    ),
                    AppText(
                      widget.subTitle??"",
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textFieldBorder,
                    ),
                  ],
                ),
              ],
            ),
            widget.actionWidget??SizedBox()

          ],
        ),
      ),
    );
  }
}
