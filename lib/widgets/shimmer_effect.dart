import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class MediaShimmerLoading extends StatelessWidget {
  const MediaShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    // તમારા AppThemeColors માંથી ગ્રે કલર મેળવો
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Shimmer.fromColors(
      baseColor: colors.cardBackground, // થોડો ડાર્ક ગ્રે
      highlightColor: colors.cardBackground.withOpacity(0.5), // લાઈટ ગ્રે
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8, // 8 આઈટમ બતાવો
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                // Thumbnail Skeleton
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 15),
                // Text Skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}