import 'package:package_info_plus/package_info_plus.dart';

import '../utils/app_imports.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    // Privacy Policy Content with Icons
    final List<Map<String, dynamic>> policyData = [
      {
        "title": context.tr("yourMediaYourPrivacy"),
        "content": context.tr("yourMediaYourPrivacyContent"),
        "icon": Icons.privacy_tip_rounded,
      },
      {
        "title": context.tr("offlineExperience"),
        "content": context.tr("offlineExperienceContent"),
        "icon": Icons.cloud_off_rounded,
      },
      {
        "title": context.tr("noPersonalTracking"),
        "content": context.tr("noPersonalTrackingContent"),
        "icon": Icons.track_changes_rounded,
      },
      {
        "title": context.tr("whyPermissions"),
        "content": context.tr("whyPermissionsContent"),
        "icon": Icons.vpn_key_rounded,
      },
      {
        "title": context.tr("securePrivate"),
        "content": context.tr("securePrivateContent"),
        "icon": Icons.security_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          // 1. Attractive AppBar with flexible space
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: colors.background,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: CircleAvatar(
                  backgroundColor: colors.cardBackground,
                  child: AppImage(src: AppSvg.backArrowIcon, height: 18, width: 18,color: colors.blackColor,),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: AppText(
                context.tr("privacyPolicy"),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.primary.withOpacity(0.1), colors.background],
                  ),
                ),
                child: Icon(Icons.verified_user_rounded, size: 80, color: colors.primary.withOpacity(0.2)),
              ),
            ),
          ),

          // 2. Policy Sections
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return _buildAttractiveSection(
                    index,
                    colors,
                    policyData[index]['title']!,
                    policyData[index]['content']!,
                    policyData[index]['icon']!,
                  );
                },
                childCount: policyData.length,
              ),
            ),
          ),

          // 3. Footer with App Version
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      String version = snapshot.hasData ? snapshot.data!.version : "...";
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AppText(
                          "${context.tr("appVersion")} $version",
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.secondaryText,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  AppText(
                    "Ã‚Â© ${DateTime.now().year} ${context.tr("allRightsReserved")}",
                    fontSize: 12,
                    color: colors.secondaryText.withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttractiveSection(int index, AppThemeColors colors, String title, String content, IconData icon) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 500 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(width: 1, color: colors.dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Circle
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 6),
                  AppText(
                    content,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: colors.secondaryText,
                    height: 1.5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/*
{
  "english"
  "arabic"
  "burmese" "filipino" "french"
  "german" "gujarati" "hindi"  "indonesian"  "italian"
  "japanese":
  "korean":
  "malay":
  "marathi":
  "persian":
  "polish":
  "portuguese":
  "spanish":
  "swedish":
  "tamil":
  "urdu":
}
 */