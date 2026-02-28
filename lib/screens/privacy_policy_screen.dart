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
      body: CustomScrollView( // Scrolling àª¨à«‡ àªµàª§à« àª¸à«àª®à«‚àª§ àª¬àª¨àª¾àªµàªµàª¾ àª®àª¾àªŸà«‡
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
                  child: AppImage(src: AppSvg.backArrowIcon, height: 18, width: 18),
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
                    "Â© ${DateTime.now().year} ${context.tr("allRightsReserved")}",
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
ðŸ“‚ 1. English (en.json)
JSON
"yourMediaYourPrivacy": "1. Your Media, Your Privacy",
"yourMediaYourPrivacyContent": "This app only plays files (Videos and Music) that are already on your phone. We do not look at your private photos or other personal documents.",
"offlineExperience": "2. Offline Experience",
"offlineExperienceContent": "All your created Playlists and Favorites are saved directly on your device. We do not upload your files or data to any website or server.",
"noPersonalTracking": "3. No Personal Tracking",
"noPersonalTrackingContent": "We don't ask for your name, email, or phone number. You can use all features of this app without ever creating an account.",
"whyPermissions": "4. Why we need Permissions?",
"whyPermissionsContent": "We ask for 'Storage Permission' only so the app can find your music and videos to play them. Without this, the app won't be able to show your files.",
"securePrivate": "5. Secure & Private",
"securePrivateContent": "Since everything is stored on your phone, your data is completely private. If you delete the app, your created playlists within the app will also be removed.",
"appVersion": "Version",
"allRightsReserved": "All Rights Reserved"
ðŸ“‚ 2. Arabic (ar.json)
JSON
"yourMediaYourPrivacy": "Ù¡. ÙˆØ³Ø§Ø¦Ø·ÙƒØŒ Ø®ØµÙˆØµÙŠØªÙƒ",
"yourMediaYourPrivacyContent": "ÙŠÙ‚ÙˆÙ… Ù‡Ø°Ø§ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ ÙÙ‚Ø· Ø¨ØªØ´ØºÙŠÙ„ Ø§Ù„Ù…Ù„ÙØ§Øª (Ù…Ù‚Ø§Ø·Ø¹ Ø§Ù„ÙÙŠØ¯ÙŠÙˆ ÙˆØ§Ù„Ù…ÙˆØ³ÙŠÙ‚Ù‰) Ø§Ù„Ù…ÙˆØ¬ÙˆØ¯Ø© Ø¨Ø§Ù„ÙØ¹Ù„ Ø¹Ù„Ù‰ Ù‡Ø§ØªÙÙƒ. Ù†Ø­Ù† Ù„Ø§ Ù†Ù†Ø¸Ø± Ø¥Ù„Ù‰ ØµÙˆØ±Ùƒ Ø§Ù„Ø®Ø§ØµØ© Ø£Ùˆ Ù…Ø³ØªÙ†Ø¯Ø§ØªÙƒ Ø§Ù„Ø£Ø®Ø±Ù‰.",
"offlineExperience": "Ù¢. ØªØ¬Ø±Ø¨Ø© Ø¨Ø¯ÙˆÙ† Ø§ØªØµØ§Ù„",
"offlineExperienceContent": "ÙŠØªÙ… Ø­ÙØ¸ Ø¬Ù…ÙŠØ¹ Ù‚ÙˆØ§Ø¦Ù… Ø§Ù„ØªØ´ØºÙŠÙ„ ÙˆØ§Ù„Ù…ÙØ¶Ù„Ø§Øª Ø§Ù„ØªÙŠ Ø£Ù†Ø´Ø£ØªÙ‡Ø§ Ù…Ø¨Ø§Ø´Ø±Ø© Ø¹Ù„Ù‰ Ø¬Ù‡Ø§Ø²Ùƒ. Ù†Ø­Ù† Ù„Ø§ Ù†Ø±ÙØ¹ Ù…Ù„ÙØ§ØªÙƒ Ø£Ùˆ Ø¨ÙŠØ§Ù†Ø§ØªÙƒ Ø¥Ù„Ù‰ Ø£ÙŠ Ø®Ø§Ø¯Ù….",
"noPersonalTracking": "Ù£. Ù„Ø§ ØªØªØ¨Ø¹ Ø´Ø®ØµÙŠ",
"noPersonalTrackingContent": "Ù†Ø­Ù† Ù„Ø§ Ù†Ø·Ù„Ø¨ Ø§Ø³Ù…Ùƒ Ø£Ùˆ Ø¨Ø±ÙŠØ¯Ùƒ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ Ø£Ùˆ Ø±Ù‚Ù… Ù‡Ø§ØªÙÙƒ. ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ø³ØªØ®Ø¯Ø§Ù… Ù…ÙŠØ²Ø§Øª Ù‡Ø°Ø§ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ø¯ÙˆÙ† Ø¥Ù†Ø´Ø§Ø¡ Ø­Ø³Ø§Ø¨.",
"whyPermissions": "Ù¤. Ù„Ù…Ø§Ø°Ø§ Ù†Ø­ØªØ§Ø¬ Ø¥Ù„Ù‰ Ø§Ù„Ø£Ø°ÙˆÙ†Ø§ØªØŸ",
"whyPermissionsContent": "Ù†Ø·Ù„Ø¨ 'Ø¥Ø°Ù† Ø§Ù„ØªØ®Ø²ÙŠÙ†' ÙÙ‚Ø· Ø­ØªÙ‰ ÙŠØªÙ…ÙƒÙ† Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ù…Ù† Ø§Ù„Ø¹Ø«ÙˆØ± Ø¹Ù„Ù‰ Ø§Ù„Ù…ÙˆØ³ÙŠÙ‚Ù‰ ÙˆÙ…Ù‚Ø§Ø·Ø¹ Ø§Ù„ÙÙŠØ¯ÙŠÙˆ Ø§Ù„Ø®Ø§ØµØ© Ø¨Ùƒ Ù„ØªØ´ØºÙŠÙ„Ù‡Ø§. ÙˆØ¨Ø¯ÙˆÙ† Ø°Ù„ÙƒØŒ Ù„Ù† ÙŠØªÙ…ÙƒÙ† Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ù…Ù† Ø¥Ø¸Ù‡Ø§Ø± Ù…Ù„ÙØ§ØªÙƒ.",
"securePrivate": "Ù¥. Ø¢Ù…Ù† ÙˆØ®Ø§Øµ",
"securePrivateContent": "Ø¨Ù…Ø§ Ø£Ù† ÙƒÙ„ Ø´ÙŠØ¡ Ù…Ø®Ø²Ù† Ø¹Ù„Ù‰ Ù‡Ø§ØªÙÙƒØŒ ÙØ¥Ù† Ø¨ÙŠØ§Ù†Ø§ØªÙƒ Ø®Ø§ØµØ© ØªÙ…Ø§Ù…Ù‹Ø§. Ø¥Ø°Ø§ Ù‚Ù…Øª Ø¨Ø­Ø°Ù Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ØŒ ÙØ³ÙŠØªÙ… Ø£ÙŠØ¶Ù‹Ø§ Ø¥Ø²Ø§Ù„Ø© Ù‚ÙˆØ§Ø¦Ù… Ø§Ù„ØªØ´ØºÙŠÙ„ Ø§Ù„Ø®Ø§ØµØ© Ø¨Ùƒ.",
"appVersion": "Ø§Ù„Ø¥ØµØ¯Ø§Ø±",
"allRightsReserved": "Ø¬Ù…ÙŠØ¹ Ø§Ù„Ø­Ù‚ÙˆÙ‚ Ù…Ø­ÙÙˆØ¸Ø©"
ðŸ“‚ 3. Burmese (my.json)
JSON
"yourMediaYourPrivacy": "áá‹ á€žá€„á€ºáá€™á€®á€’á€®á€šá€¬áŠ á€žá€„á€ºáá€€á€­á€¯á€šá€ºá€›á€±á€¸á€€á€­á€¯á€šá€ºá€á€¬",
"yourMediaYourPrivacyContent": "á€¤á€¡á€€á€ºá€•á€ºá€žá€Šá€º á€žá€„á€·á€ºá€–á€¯á€”á€ºá€¸á€‘á€²á€›á€¾á€­ á€–á€­á€¯á€„á€ºá€™á€»á€¬á€¸ (á€—á€®á€’á€®á€šá€­á€¯á€”á€¾á€„á€·á€º á€žá€®á€á€»á€„á€ºá€¸) á€€á€­á€¯á€žá€¬ á€–á€½á€„á€·á€ºá€•á€±á€¸á€•á€«á€žá€Šá€ºá‹ á€žá€„á€ºá á€€á€­á€¯á€šá€ºá€•á€­á€¯á€„á€ºá€“á€¬á€á€ºá€•á€¯á€¶á€™á€»á€¬á€¸á€€á€­á€¯ á€€á€»á€½á€”á€ºá€¯á€•á€ºá€á€­á€¯á€· á€™á€€á€¼á€Šá€·á€ºá€›á€¾á€¯á€•á€«á‹",
"offlineExperience": "á‚á‹ á€¡á€±á€¬á€·á€–á€ºá€œá€­á€¯á€„á€ºá€¸ á€¡á€á€½á€±á€·á€¡á€€á€¼á€¯á€¶",
"offlineExperienceContent": "á€žá€„á€ºá€–á€”á€ºá€á€®á€¸á€‘á€¬á€¸á€žá€±á€¬ á€žá€®á€á€»á€„á€ºá€¸á€…á€¬á€›á€„á€ºá€¸á€™á€»á€¬á€¸á€€á€­á€¯ á€žá€„á€·á€ºá€–á€¯á€”á€ºá€¸á€‘á€²á€™á€¾á€¬á€•á€² á€žá€­á€™á€ºá€¸á€†á€Šá€ºá€¸á€‘á€¬á€¸á€•á€«á€žá€Šá€ºá‹ á€™á€Šá€ºá€žá€Šá€·á€ºá€†á€¬á€—á€¬á€žá€­á€¯á€·á€™á€¾ á€•á€±á€¸á€•á€­á€¯á€·á€á€¼á€„á€ºá€¸á€™á€›á€¾á€­á€•á€«á‹",
"noPersonalTracking": "áƒá‹ á€á€¼á€±á€›á€¬á€á€¶á€á€¼á€„á€ºá€¸á€™á€›á€¾á€­",
"noPersonalTrackingContent": "á€”á€¬á€™á€Šá€º á€žá€­á€¯á€·á€™á€Ÿá€¯á€á€º á€¡á€®á€¸á€™á€±á€¸á€œá€º á€á€±á€¬á€„á€ºá€¸á€á€¶á€á€¼á€„á€ºá€¸á€™á€›á€¾á€­á€•á€«á‹ á€¡á€€á€±á€¬á€„á€·á€ºá€™á€›á€¾á€­á€˜á€² á€¡á€žá€¯á€¶á€¸á€•á€¼á€¯á€”á€­á€¯á€„á€ºá€•á€«á€žá€Šá€ºá‹",
"whyPermissions": "á„á‹ á€˜á€¬á€€á€¼á€±á€¬á€„á€·á€º á€á€½á€„á€·á€ºá€•á€¼á€¯á€á€»á€€á€ºá€œá€­á€¯á€¡á€•á€ºá€žá€œá€²?",
"whyPermissionsContent": "á€žá€„á€·á€ºá€–á€¯á€”á€ºá€¸á€‘á€²á€›á€¾á€­ á€–á€­á€¯á€„á€ºá€™á€»á€¬á€¸á€€á€­á€¯ á€›á€¾á€¬á€–á€½á€±á€›á€”á€ºá€¡á€á€½á€€á€ºá€žá€¬ 'Storage Permission' á€œá€­á€¯á€¡á€•á€ºá€•á€«á€žá€Šá€ºá‹",
"securePrivate": "á…á‹ á€œá€¯á€¶á€á€¼á€¯á€¶á€…á€­á€á€ºá€á€»á€›á€™á€¾á€¯",
"securePrivateContent": "á€¡á€á€»á€€á€ºá€¡á€œá€€á€ºá€¡á€¬á€¸á€œá€¯á€¶á€¸ á€žá€„á€·á€ºá€–á€¯á€”á€ºá€¸á€‘á€²á€™á€¾á€¬á€•á€²á€›á€¾á€­á€œá€­á€¯á€· á€œá€¯á€¶á€á€¼á€¯á€¶á€•á€«á€á€šá€ºá‹ á€¡á€€á€ºá€•á€ºá€€á€­á€¯ á€–á€»á€€á€ºá€œá€­á€¯á€€á€ºá€›á€„á€º á€žá€®á€á€»á€„á€ºá€¸á€…á€¬á€›á€„á€ºá€¸á€™á€»á€¬á€¸á€œá€Šá€ºá€¸ á€•á€»á€€á€ºá€žá€½á€¬á€¸á€•á€«á€œá€­á€™á€·á€ºá€™á€šá€ºá‹",
"appVersion": "á€—á€¬á€¸á€›á€¾á€„á€ºá€¸",
"allRightsReserved": "á€™á€°á€•á€­á€¯á€„á€ºá€á€½á€„á€·á€ºá€™á€»á€¬á€¸á€¡á€¬á€¸á€œá€¯á€¶á€¸ á€œá€€á€ºá€á€šá€ºá€›á€¾á€­á€žá€Šá€º"
ðŸ“‚ 4. Filipino (fil.json)
JSON
"yourMediaYourPrivacy": "1. Media Mo, Privacy Mo",
"yourMediaYourPrivacyContent": "Pinapatugtog lang ng app na ito ang mga file (Video at Musika) na nasa iyong phone. Hindi namin tinitingnan ang iyong mga personal na dokumento.",
"offlineExperience": "2. Offline Experience",
"offlineExperienceContent": "Ang iyong mga Playlist at Paborito ay naka-save lang sa iyong device. Hindi namin ina-upload ang iyong data sa anumang server.",
"noPersonalTracking": "3. Walang Personal Tracking",
"noPersonalTrackingContent": "Hindi kami nagtatanong ng pangalan o email. Magagamit mo ang app kahit walang account.",
"whyPermissions": "4. Bakit kailangan ng Permissions?",
"whyPermissionsContent": "Kailangan namin ng storage permission para mahanap ang iyong mga video at musika. Kung wala ito, hindi makikita ang iyong mga file.",
"securePrivate": "5. Ligtas at Pribado",
"securePrivateContent": "Dahil nasa phone mo lang ang lahat, pribado ang iyong data. Kapag binura ang app, mabubura rin ang iyong playlists.",
"appVersion": "Bersyon",
"allRightsReserved": "All Rights Reserved"
ðŸ“‚ 5. French (fr.json)
JSON
"yourMediaYourPrivacy": "1. Vos MÃ©dias, Votre Vie PrivÃ©e",
"yourMediaYourPrivacyContent": "Cette application ne lit que les fichiers (VidÃ©os et Musique) dÃ©jÃ  prÃ©sents sur votre tÃ©lÃ©phone. Nous ne regardons pas vos photos privÃ©es.",
"offlineExperience": "2. ExpÃ©rience Hors Ligne",
"offlineExperienceContent": "Toutes vos listes de lecture sont enregistrÃ©es sur votre appareil. Nous ne tÃ©lÃ©chargeons pas vos donnÃ©es sur un serveur.",
"noPersonalTracking": "3. Pas de Suivi Personnel",
"noPersonalTrackingContent": "Nous ne demandons pas votre nom ou email. Vous pouvez utiliser l'appli sans crÃ©er de compte.",
"whyPermissions": "4. Pourquoi des Autorisations ?",
"whyPermissionsContent": "Nous demandons l'autorisation de stockage uniquement pour trouver vos mÃ©dias.",
"securePrivate": "5. SÃ©curisÃ© et PrivÃ©",
"securePrivateContent": "Tout est stockÃ© sur votre tÃ©lÃ©phone. Si vous supprimez l'appli, vos listes seront supprimÃ©es.",
"appVersion": "Version",
"allRightsReserved": "Tous Droits RÃ©servÃ©s"
ðŸ“‚ 6. German (de.json)
JSON
"yourMediaYourPrivacy": "1. Ihre Medien, Ihre PrivatsphÃ¤re",
"yourMediaYourPrivacyContent": "Diese App spielt nur Dateien (Videos und Musik) ab, die sich bereits auf Ihrem Telefon befinden. Wir greifen nicht auf private Fotos zu.",
"offlineExperience": "2. Offline-Erlebnis",
"offlineExperienceContent": "Alle Playlists werden lokal auf Ihrem GerÃ¤t gespeichert. Wir laden keine Daten auf Server hoch.",
"noPersonalTracking": "3. Kein Tracking",
"noPersonalTrackingContent": "Wir fragen nicht nach Name oder E-Mail. Sie kÃ¶nnen die App ohne Konto nutzen.",
"whyPermissions": "4. Warum Berechtigungen?",
"whyPermissionsContent": "Wir benÃ¶tigen Zugriff auf den Speicher, um Ihre Medien abzuspielen.",
"securePrivate": "5. Sicher & Privat",
"securePrivateContent": "Ihre Daten sind privat. Wenn Sie die App lÃ¶schen, werden auch Ihre Playlists entfernt.",
"appVersion": "Version",
"allRightsReserved": "Alle Rechte vorbehalten"
ðŸ“‚ 7. Gujarati (gu.json)
JSON
"yourMediaYourPrivacy": "à«§. àª¤àª®àª¾àª°à«àª‚ àª®à«€àª¡àª¿àª¯àª¾, àª¤àª®àª¾àª°à«€ àªªà«àª°àª¾àªˆàªµàª¸à«€",
"yourMediaYourPrivacyContent": "àª† àªàªª àª«àª•à«àª¤ àª¤àª®àª¾àª°àª¾ àª«à«‹àª¨àª®àª¾àª‚ àª°àª¹à«‡àª²à«€ àª«àª¾àªˆàª²à«‹ (àªµà«€àª¡àª¿àª¯à«‹ àª…àª¨à«‡ àª®à«àª¯à«àªàª¿àª•) àªµàª—àª¾àª¡à«‡ àª›à«‡. àª…àª®à«‡ àª¤àª®àª¾àª°àª¾ àª–àª¾àª¨àª—à«€ àª«à«‹àªŸàª¾ àª•à«‡ àª…àª¨à«àª¯ àª¦àª¸à«àª¤àª¾àªµà«‡àªœà«‹ àªœà«‹àª¤àª¾ àª¨àª¥à«€.",
"offlineExperience": "à«¨. àª“àª«àª²àª¾àª‡àª¨ àª…àª¨à«àª­àªµ",
"offlineExperienceContent": "àª¤àª®àª¾àª°àª¾ àª¤àª®àª¾àª® àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àª…àª¨à«‡ àª«à«‡àªµàª°àª¿àªŸ àª¤àª®àª¾àª°àª¾ àª‰àªªàª•àª°àª£ àªªàª° àªœ àª¸àª¾àªšàªµàªµàª¾àª®àª¾àª‚ àª†àªµà«‡ àª›à«‡. àª…àª®à«‡ àª¡à«‡àªŸàª¾ àª¸àª°à«àªµàª° àªªàª° àª…àªªàª²à«‹àª¡ àª•àª°àª¤àª¾ àª¨àª¥à«€.",
"noPersonalTracking": "à«©. àª•à«‹àªˆ àªŸà«àª°à«‡àª•àª¿àª‚àª— àª¨àª¥à«€",
"noPersonalTrackingContent": "àª…àª®à«‡ àª¤àª®àª¾àª°à«àª‚ àª¨àª¾àª® àª•à«‡ àªˆàª®à«‡àª² àª®àª¾àª‚àª—àª¤àª¾ àª¨àª¥à«€. àª¤àª®à«‡ àªàª•àª¾àª‰àª¨à«àªŸ àªµàª—àª° àªœ àª¬àª§à«€ àª¸à«àªµàª¿àª§àª¾àª“ àªµàª¾àªªàª°à«€ àª¶àª•à«‹ àª›à«‹.",
"whyPermissions": "à«ª. àªªàª°àª®àª¿àª¶àª¨àª¨à«€ àªœàª°à«‚àª° àª¶àª¾ àª®àª¾àªŸà«‡?",
"whyPermissionsContent": "àª…àª®à«‡ àª«àª•à«àª¤ 'àª¸à«àªŸà«‹àª°à«‡àªœ àªªàª°àª®àª¿àª¶àª¨' àª®àª¾àª‚àª—à«€àª àª›à«€àª àªœà«‡àª¥à«€ àªàªª àª¤àª®àª¾àª°àª¾ àª®à«àª¯à«àªàª¿àª• àª…àª¨à«‡ àªµà«€àª¡àª¿àª¯à«‹ àª¶à«‹àª§à«€ àª¶àª•à«‡.",
"securePrivate": "à««. àª¸à«àª°àª•à«àª·àª¿àª¤ àª…àª¨à«‡ àª–àª¾àª¨àª—à«€",
"securePrivateContent": "àª¬àª§à«‹ àª¡à«‡àªŸàª¾ àª«à«‹àª¨àª®àª¾àª‚ àª¹à«‹àªµàª¾àª¥à«€ àª¸à«àª°àª•à«àª·àª¿àª¤ àª›à«‡. àªàªª àª¡àª¿àª²à«€àªŸ àª•àª°àª¶à«‹ àª¤à«‹ àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àªªàª£ àª¨à«€àª•àª³à«€ àªœàª¶à«‡.",
"appVersion": "àªµàª°à«àªàª¨",
"allRightsReserved": "àª¤àª®àª¾àª® àª¹àª•à«‹ àª¸à«àª°àª•à«àª·àª¿àª¤"
ðŸ“‚ 8. Hindi (hi.json)
JSON
"yourMediaYourPrivacy": "à¥§. à¤†à¤ªà¤•à¤¾ à¤®à¥€à¤¡à¤¿à¤¯à¤¾, à¤†à¤ªà¤•à¥€ à¤—à¥‹à¤ªà¤¨à¥€à¤¯à¤¤à¤¾",
"yourMediaYourPrivacyContent": "à¤¯à¤¹ à¤à¤ª à¤•à¥‡à¤µà¤² à¤†à¤ªà¤•à¥‡ à¤«à¥‹à¤¨ à¤®à¥‡à¤‚ à¤®à¥Œà¤œà¥‚à¤¦ à¤«à¤¾à¤‡à¤²à¥‹à¤‚ (à¤µà¥€à¤¡à¤¿à¤¯à¥‹ à¤”à¤° à¤¸à¤‚à¤—à¥€à¤¤) à¤•à¥‹ à¤šà¤²à¤¾à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤¹à¤® à¤†à¤ªà¤•à¥€ à¤¨à¤¿à¤œà¥€ à¤¤à¤¸à¥à¤µà¥€à¤°à¥‹à¤‚ à¤•à¥‹ à¤¨à¤¹à¥€à¤‚ à¤¦à¥‡à¤–à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤",
"offlineExperience": "à¥¨. à¤‘à¤«à¤²à¤¾à¤‡à¤¨ à¤…à¤¨à¥à¤­à¤µ",
"offlineExperienceContent": "à¤†à¤ªà¤•à¥€ à¤ªà¥à¤²à¥‡à¤²à¤¿à¤¸à¥à¤Ÿ à¤†à¤ªà¤•à¥‡ à¤¡à¤¿à¤µà¤¾à¤‡à¤¸ à¤ªà¤° à¤¹à¥€ à¤¸à¤¹à¥‡à¤œà¥€ à¤œà¤¾à¤¤à¥€ à¤¹à¥ˆà¤‚à¥¤ à¤¹à¤® à¤†à¤ªà¤•à¤¾ à¤¡à¥‡à¤Ÿà¤¾ à¤•à¤¿à¤¸à¥€ à¤¸à¤°à¥à¤µà¤° à¤ªà¤° à¤…à¤ªà¤²à¥‹à¤¡ à¤¨à¤¹à¥€à¤‚ à¤•à¤°à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤",
"noPersonalTracking": "à¥©. à¤•à¥‹à¤ˆ à¤Ÿà¥à¤°à¥ˆà¤•à¤¿à¤‚à¤— à¤¨à¤¹à¥€à¤‚",
"noPersonalTrackingContent": "à¤¹à¤® à¤†à¤ªà¤•à¤¾ à¤¨à¤¾à¤® à¤¯à¤¾ à¤ˆà¤®à¥‡à¤² à¤¨à¤¹à¥€à¤‚ à¤®à¤¾à¤‚à¤—à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤†à¤ª à¤¬à¤¿à¤¨à¤¾ à¤…à¤•à¤¾à¤‰à¤‚à¤Ÿ à¤¬à¤¨à¤¾à¤ à¤à¤ª à¤•à¤¾ à¤‰à¤ªà¤¯à¥‹à¤— à¤•à¤° à¤¸à¤•à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤",
"whyPermissions": "à¥ª. à¤…à¤¨à¥à¤®à¤¤à¤¿ à¤•à¥à¤¯à¥‹à¤‚ à¤šà¤¾à¤¹à¤¿à¤?",
"whyPermissionsContent": "à¤¹à¤®à¥‡à¤‚ à¤¸à¥à¤Ÿà¥‹à¤°à¥‡à¤œ à¤…à¤¨à¥à¤®à¤¤à¤¿ à¤•à¥€ à¤†à¤µà¤¶à¥à¤¯à¤•à¤¤à¤¾ à¤¹à¥ˆ à¤¤à¤¾à¤•à¤¿ à¤à¤ª à¤†à¤ªà¤•à¥‡ à¤¸à¤‚à¤—à¥€à¤¤ à¤”à¤° à¤µà¥€à¤¡à¤¿à¤¯à¥‹ à¤¢à¥‚à¤‚à¤¢ à¤¸à¤•à¥‡à¥¤",
"securePrivate": "à¥«. à¤¸à¥à¤°à¤•à¥à¤·à¤¿à¤¤ à¤”à¤° à¤¨à¤¿à¤œà¥€",
"securePrivateContent": "à¤†à¤ªà¤•à¤¾ à¤¡à¥‡à¤Ÿà¤¾ à¤†à¤ªà¤•à¥‡ à¤«à¥‹à¤¨ à¤¤à¤• à¤¸à¥€à¤®à¤¿à¤¤ à¤¹à¥ˆà¥¤ à¤à¤ª à¤¹à¤Ÿà¤¾à¤¨à¥‡ à¤ªà¤° à¤†à¤ªà¤•à¥€ à¤ªà¥à¤²à¥‡à¤²à¤¿à¤¸à¥à¤Ÿ à¤­à¥€ à¤¹à¤Ÿ à¤œà¤¾à¤à¤‚à¤—à¥€à¥¤",
"appVersion": "à¤µà¤°à¥à¤œà¤¨",
"allRightsReserved": "à¤¸à¤°à¥à¤µà¤¾à¤§à¤¿à¤•à¤¾à¤° à¤¸à¥à¤°à¤•à¥à¤·à¤¿à¤¤"
ðŸ“‚ 9. Indonesian (id.json)
JSON
"yourMediaYourPrivacy": "1. Media Anda, Privasi Anda",
"yourMediaYourPrivacyContent": "Aplikasi ini hanya memutar file (Video dan Musik) yang ada di ponsel Anda. Kami tidak melihat foto pribadi Anda.",
"offlineExperience": "2. Pengalaman Offline",
"offlineExperienceContent": "Daftar Putar disimpan di perangkat Anda. Kami tidak mengunggah data Anda ke server mana pun.",
"noPersonalTracking": "3. Tanpa Pelacakan",
"noPersonalTrackingContent": "Kami tidak meminta nama atau email Anda. Gunakan aplikasi tanpa membuat akun.",
"whyPermissions": "4. Mengapa Perlu Izin?",
"whyPermissionsContent": "Kami meminta izin penyimpanan untuk menemukan file media Anda.",
"securePrivate": "5. Aman & Pribadi",
"securePrivateContent": "Data Anda sepenuhnya pribadi. Jika aplikasi dihapus, daftar putar Anda juga akan hilang.",
"appVersion": "Versi",
"allRightsReserved": "Seluruh Hak Cipta"
ðŸ“‚ 10. Italian (it.json)
JSON
"yourMediaYourPrivacy": "1. I tuoi Media, la tua Privacy",
"yourMediaYourPrivacyContent": "Questa app riproduce solo i file (Video e Musica) giÃ  presenti sul tuo telefono. Non accediamo alle tue foto private.",
"offlineExperience": "2. Esperienza Offline",
"offlineExperienceContent": "Le tue playlist sono salvate sul dispositivo. Non carichiamo i tuoi dati su alcun server.",
"noPersonalTracking": "3. Nessun Tracciamento",
"noPersonalTrackingContent": "Non chiediamo nome o email. Puoi usare l'app senza creare un account.",
"whyPermissions": "4. PerchÃ© le Autorizzazioni?",
"whyPermissionsContent": "Chiediamo l'accesso alla memoria solo per trovare la tua musica e i tuoi video.",
"securePrivate": "5. Sicuro e Privato",
"securePrivateContent": "I tuoi dati sono privati. Se elimini l'app, le tue playlist verranno rimosse.",
"appVersion": "Versione",
"allRightsReserved": "Tutti i diritti riservati"
ðŸ“‚ 11. Japanese (ja.json)
JSON
"yourMediaYourPrivacy": "1. ã‚ãªãŸã®ãƒ¡ãƒ‡ã‚£ã‚¢ã€ã‚ãªãŸã®ãƒ—ãƒ©ã‚¤ãƒã‚·ãƒ¼",
"yourMediaYourPrivacyContent": "ã“ã®ã‚¢ãƒ—ãƒªã¯ãƒ‡ãƒã‚¤ã‚¹å†…ã®ãƒ•ã‚¡ã‚¤ãƒ«ï¼ˆå‹•ç”»ãƒ»éŸ³æ¥½ï¼‰ã®ã¿ã‚’å†ç”Ÿã—ã¾ã™ã€‚ãƒ—ãƒ©ã‚¤ãƒ™ãƒ¼ãƒˆãªå†™çœŸã«ã¯ã‚¢ã‚¯ã‚»ã‚¹ã—ã¾ã›ã‚“ã€‚",
"offlineExperience": "2. ã‚ªãƒ•ãƒ©ã‚¤ãƒ³æ©Ÿèƒ½",
"offlineExperienceContent": "ãƒ—ãƒ¬ã‚¤ãƒªã‚¹ãƒˆã¯ãƒ‡ãƒã‚¤ã‚¹ã«ã®ã¿ä¿å­˜ã•ã‚Œã¾ã™ã€‚ã‚µãƒ¼ãƒãƒ¼ã¸ã®é€ä¿¡ã¯è¡Œã„ã¾ã›ã‚“ã€‚",
"noPersonalTracking": "3. è¿½è·¡ãªã—",
"noPersonalTrackingContent": "åå‰ã‚„ãƒ¡ãƒ¼ãƒ«ã‚¢ãƒ‰ãƒ¬ã‚¹ã¯ä¸è¦ã§ã™ã€‚ã‚¢ã‚«ã‚¦ãƒ³ãƒˆãªã—ã§ã™ã¹ã¦ã®æ©Ÿèƒ½ã‚’åˆ©ç”¨ã§ãã¾ã™ã€‚",
"whyPermissions": "4. æ¨©é™ãŒå¿…è¦ãªç†ç”±",
"whyPermissionsContent": "ãƒ¡ãƒ‡ã‚£ã‚¢ã‚’å†ç”Ÿã™ã‚‹ãŸã‚ã«ã‚¹ãƒˆãƒ¬ãƒ¼ã‚¸æ¨©é™ãŒå¿…è¦ã§ã™ã€‚",
"securePrivate": "5. å®‰å…¨ãƒ»ãƒ—ãƒ©ã‚¤ãƒ™ãƒ¼ãƒˆ",
"securePrivateContent": "ãƒ‡ãƒ¼ã‚¿ã¯ãƒ‡ãƒã‚¤ã‚¹å†…ã«ã‚ã‚Šå®‰å…¨ã§ã™ã€‚ã‚¢ãƒ—ãƒªã‚’å‰Šé™¤ã™ã‚‹ã¨ãƒ—ãƒ¬ã‚¤ãƒªã‚¹ãƒˆã‚‚æ¶ˆåŽ»ã•ã‚Œã¾ã™ã€‚",
"appVersion": "ãƒãƒ¼ã‚¸ãƒ§ãƒ³",
"allRightsReserved": "ä¸è¨±è¤‡è£½ãƒ»ç„¡æ–­è»¢è¼‰ç¦æ­¢"
ðŸ“‚ 12. Korean (ko.json)
JSON
"yourMediaYourPrivacy": "1. ë‹¹ì‹ ì˜ ë¯¸ë””ì–´ì™€ ê°œì¸ì •ë³´",
"yourMediaYourPrivacyContent": "ì´ ì•±ì€ íœ´ëŒ€í°ì— ìžˆëŠ” íŒŒì¼(ë™ì˜ìƒ ë° ìŒì•…)ë§Œ ìž¬ìƒí•©ë‹ˆë‹¤. ê°œì¸ ì‚¬ì§„ì´ë‚˜ ë¬¸ì„œëŠ” ë³´ì§€ ì•ŠìŠµë‹ˆë‹¤.",
"offlineExperience": "2. ì˜¤í”„ë¼ì¸ í™˜ê²½",
"offlineExperienceContent": "í”Œë ˆì´ë¦¬ìŠ¤íŠ¸ëŠ” ê¸°ê¸°ì—ë§Œ ì €ìž¥ë©ë‹ˆë‹¤. ì„œë²„ë¡œ ë°ì´í„°ë¥¼ ì—…ë¡œë“œí•˜ì§€ ì•ŠìŠµë‹ˆë‹¤.",
"noPersonalTracking": "3. ì¶”ì  ì—†ìŒ",
"noPersonalTrackingContent": "ì´ë¦„ì´ë‚˜ ì´ë©”ì¼ì„ ìš”ì²­í•˜ì§€ ì•ŠìŠµë‹ˆë‹¤. ê³„ì • ì—†ì´ ëª¨ë“  ê¸°ëŠ¥ì„ ì‚¬ìš©í•  ìˆ˜ ìžˆìŠµë‹ˆë‹¤.",
"whyPermissions": "4. ê¶Œí•œì´ í•„ìš”í•œ ì´ìœ ",
"whyPermissionsContent": "ë¯¸ë””ì–´ íŒŒì¼ì„ ìž¬ìƒí•˜ê¸° ìœ„í•´ ì €ìž¥ê³µê°„ ê¶Œí•œì´ í•„ìš”í•©ë‹ˆë‹¤.",
"securePrivate": "5. ì•ˆì „í•œ ê°œì¸ì •ë³´ ë³´í˜¸",
"securePrivateContent": "ëª¨ë“  ë°ì´í„°ëŠ” ê¸°ê¸°ì— ì €ìž¥ë©ë‹ˆë‹¤. ì•± ì‚­ì œ ì‹œ í”Œë ˆì´ë¦¬ìŠ¤íŠ¸ë„ í•¨ê»˜ ì‚­ì œë©ë‹ˆë‹¤.",
"appVersion": "ë²„ì „",
"allRightsReserved": "ëª¨ë“  ê¶Œë¦¬ ë³´ìœ "
ðŸ“‚ 13. Malay (ms.json)
JSON
"yourMediaYourPrivacy": "1. Media Anda, Privasi Anda",
"yourMediaYourPrivacyContent": "Aplikasi ini hanya memainkan fail (Video dan Muzik) dalam telefon anda. Kami tidak melihat foto peribadi anda.",
"offlineExperience": "2. Pengalaman Luar Talian",
"offlineExperienceContent": "Senarai main anda disimpan dalam peranti. Kami tidak memuat naik data anda ke pelayan.",
"noPersonalTracking": "3. Tiada Penjejakan",
"noPersonalTrackingContent": "Kami tidak meminta nama atau e-mel. Anda boleh guna tanpa akaun.",
"whyPermissions": "4. Mengapa Perlu Kebenaran?",
"whyPermissionsContent": "Kami minta kebenaran storan hanya untuk mencari fail media anda.",
"securePrivate": "5. Selamat & Peribadi",
"securePrivateContent": "Data anda adalah peribadi. Jika aplikasi dipadam, senarai main anda juga akan dipadam.",
"appVersion": "Versi",
"allRightsReserved": "Hak Cipta Terpelihara"
ðŸ“‚ 14. Marathi (mr.json)
JSON
"yourMediaYourPrivacy": "à¥§. à¤¤à¥à¤®à¤šà¥‡ à¤®à¥€à¤¡à¤¿à¤¯à¤¾, à¤¤à¥à¤®à¤šà¥€ à¤—à¥‹à¤ªà¤¨à¥€à¤¯à¤¤à¤¾",
"yourMediaYourPrivacyContent": "à¤¹à¥‡ à¥²à¤ª àª«àª•à«àª¤ à¤¤à¥à¤®à¤šà¥à¤¯à¤¾ à¤«à¥‹à¤¨à¤®à¤§à¥€à¤² à¤«à¤¾à¤ˆà¤²à¥à¤¸ (à¤µà¥à¤¹à¤¿à¤¡à¤¿à¤“ à¤†à¤£à¤¿ à¤¸à¤‚à¤—à¥€à¤¤) à¤šà¤¾à¤²à¤µà¤¤à¥‡. à¤†à¤®à¥à¤¹à¥€ à¤¤à¥à¤®à¤šà¥‡ à¤–à¤¾à¤œà¤—à¥€ à¤«à¥‹à¤Ÿà¥‹ à¤ªà¤¾à¤¹à¤¤ à¤¨à¤¾à¤¹à¥€.",
"offlineExperience": "à¥¨. à¤‘à¤«à¤²à¤¾à¤‡à¤¨ à¤…à¤¨à¥à¤­à¤µ",
"offlineExperienceContent": "à¤¤à¥à¤®à¤šà¥à¤¯à¤¾ à¤ªà¥à¤²à¥‡à¤²à¤¿à¤¸à¥à¤Ÿ à¤¡à¤¿à¤µà¥à¤¹à¤¾à¤‡à¤¸à¤µà¤°à¤š à¤œà¤¤à¤¨ à¤•à¥‡à¤²à¥à¤¯à¤¾ à¤œà¤¾à¤¤à¤¾à¤¤. à¤†à¤®à¥à¤¹à¥€ à¤¡à¥‡à¤Ÿà¤¾ à¤…à¤ªà¤²à¥‹à¤¡ à¤•à¤°à¤¤ à¤¨à¤¾à¤¹à¥€.",
"noPersonalTracking": "à¥©. à¤Ÿà¥à¤°à¥…à¤•à¤¿à¤‚à¤— à¤¨à¤¾à¤¹à¥€",
"noPersonalTrackingContent": "à¤†à¤®à¥à¤¹à¥€ à¤¤à¥à¤®à¤šà¥‡ à¤¨à¤¾à¤µ à¤•à¤¿à¤‚à¤µà¤¾ à¤ˆà¤®à¥‡à¤² à¤®à¤¾à¤—à¤¤ à¤¨à¤¾à¤¹à¥€. à¤¤à¥à¤®à¥à¤¹à¥€ à¤–à¤¾à¤¤à¥‡ à¤¨ à¤‰à¤˜à¤¡à¤¤à¤¾ à¥²à¤ª à¤µà¤¾à¤ªà¤°à¥‚ à¤¶à¤•à¤¤à¤¾.",
"whyPermissions": "à¥ª. à¤ªà¤°à¤µà¤¾à¤¨à¤—à¥€ à¤•à¤¾ à¤¹à¤µà¥€?",
"whyPermissionsContent": "à¤†à¤®à¥à¤¹à¥€ à¤«à¤•à¥à¤¤ à¤µà¥à¤¹à¤¿à¤¡à¤¿à¤“ àª¶à«‹àª§àªµàª¾ àª®àª¾àªŸà«‡ àª¸à«àªŸà«‹àª°à«‡àªœ àªªàª°àª®àª¿àª¶àª¨ àª®àª¾àª‚àª—à«€àª àª›à«€àª.",
"securePrivate": "à¥«. à¤¸à¥à¤°à¤•à¥à¤·à¤¿à¤¤ à¤†à¤£à¤¿ à¤–à¤¾à¤œà¤—à¥€",
"securePrivateContent": "à¤¸à¤°à¥à¤µ à¤¡à¥‡à¤Ÿà¤¾ à¤«à¥‹à¤¨à¤µà¤° à¤…à¤¸à¤²à¥à¤¯à¤¾à¤¨à¥‡ à¤¤à¥‹ à¤¸à¥à¤°à¤•à¥à¤·à¤¿à¤¤ à¤†à¤¹à¥‡. à¥²à¤ª à¤¹à¤Ÿàªµàª²à«àª¯àª¾àª¸ àªªà«àª²à«‡àª²àª¿àª¸à«àªŸ àªªàª£ àª¨à«€àª•àª³à«€ àªœàª¶à«‡.",
"appVersion": "à¤†à¤µà¥ƒà¤¤à¥à¤¤à¥€",
"allRightsReserved": "à¤¸à¤°à¥à¤µ à¤¹à¤•à¥à¤• à¤°à¤¾à¤–à¥€à¤µ"
ðŸ“‚ 15. Persian (fa.json)
JSON
"yourMediaYourPrivacy": "Û±. Ø±Ø³Ø§Ù†Ù‡ Ø´Ù…Ø§ØŒ Ø­Ø±ÛŒÙ… Ø®ØµÙˆØµÛŒ Ø´Ù…Ø§",
"yourMediaYourPrivacyContent": "Ø§ÛŒÙ† Ø¨Ø±Ù†Ø§Ù…Ù‡ ÙÙ‚Ø· ÙØ§ÛŒÙ„â€ŒÙ‡Ø§ÛŒ Ù…ÙˆØ¬ÙˆØ¯ Ø¯Ø± Ú¯ÙˆØ´ÛŒ Ø´Ù…Ø§ (ÙˆÛŒØ¯ÛŒÙˆ Ùˆ Ù…ÙˆØ³ÛŒÙ‚ÛŒ) Ø±Ø§ Ù¾Ø®Ø´ Ù…ÛŒâ€ŒÚ©Ù†Ø¯. Ù…Ø§ Ø¨Ù‡ Ø¹Ú©Ø³â€ŒÙ‡Ø§ÛŒ Ø´Ø®ØµÛŒ Ø´Ù…Ø§ Ø¯Ø³ØªØ±Ø³ÛŒ Ù†Ø¯Ø§Ø±ÛŒÙ….",
"offlineExperience": "Û². ØªØ¬Ø±Ø¨Ù‡ Ø¢ÙÙ„Ø§ÛŒÙ†",
"offlineExperienceContent": "ØªÙ…Ø§Ù… Ù„ÛŒØ³Øªâ€ŒÙ‡Ø§ÛŒ Ù¾Ø®Ø´ Ø´Ù…Ø§ Ø¯Ø± Ø¯Ø³ØªÚ¯Ø§Ù‡ Ø°Ø®ÛŒØ±Ù‡ Ù…ÛŒâ€ŒØ´ÙˆØ¯. Ù…Ø§ Ù‡ÛŒÚ† Ø¯Ø§Ø¯Ù‡â€ŒØ§ÛŒ Ø±Ø§ Ø¢Ù¾Ù„ÙˆØ¯ Ù†Ù…ÛŒâ€ŒÚ©Ù†ÛŒÙ….",
"noPersonalTracking": "Û³. Ø¨Ø¯ÙˆÙ† Ø±Ø¯ÛŒØ§Ø¨ÛŒ Ø´Ø®ØµÛŒ",
"noPersonalTrackingContent": "Ù…Ø§ Ù†Ø§Ù… ÛŒØ§ Ø§ÛŒÙ…ÛŒÙ„ Ø´Ù…Ø§ Ø±Ø§ Ù†Ù…ÛŒâ€ŒÙ¾Ø±Ø³ÛŒÙ…. Ø¨Ø¯ÙˆÙ† Ø­Ø³Ø§Ø¨ Ú©Ø§Ø±Ø¨Ø±ÛŒ Ù…ÛŒâ€ŒØªÙˆØ§Ù†ÛŒØ¯ Ø§Ø² Ø¨Ø±Ù†Ø§Ù…Ù‡ Ø§Ø³ØªÙØ§Ø¯Ù‡ Ú©Ù†ÛŒØ¯.",
"whyPermissions": "Û´. Ú†Ø±Ø§ Ù…Ø¬ÙˆØ² Ù„Ø§Ø²Ù… Ø§Ø³ØªØŸ",
"whyPermissionsContent": "Ù…Ø§ ÙÙ‚Ø· Ø¨Ø±Ø§ÛŒ Ù¾ÛŒØ¯Ø§ Ú©Ø±Ø¯Ù† Ø¢Ù‡Ù†Ú¯â€ŒÙ‡Ø§ Ùˆ ÙˆÛŒØ¯ÛŒÙˆÙ‡Ø§ÛŒ Ø´Ù…Ø§ Ø¨Ù‡ Ù…Ø¬ÙˆØ² Ø­Ø§ÙØ¸Ù‡ Ù†ÛŒØ§Ø² Ø¯Ø§Ø±ÛŒÙ….",
"securePrivate": "Ûµ. Ø§Ù…Ù† Ùˆ Ø®ØµÙˆØµÛŒ",
"securePrivateContent": "Ø§Ø·Ù„Ø§Ø¹Ø§Øª Ø´Ù…Ø§ Ø®ØµÙˆØµÛŒ Ø§Ø³Øª. Ø¯Ø± ØµÙˆØ±Øª Ø­Ø°Ù Ø¨Ø±Ù†Ø§Ù…Ù‡ØŒ Ù„ÛŒØ³Øªâ€ŒÙ‡Ø§ÛŒ Ù¾Ø®Ø´ Ø´Ù…Ø§ Ù†ÛŒØ² Ø­Ø°Ù Ø®ÙˆØ§Ù‡Ù†Ø¯ Ø´Ø¯.",
"appVersion": "Ù†Ø³Ø®Ù‡",
"allRightsReserved": "ØªÙ…Ø§Ù…ÛŒ Ø­Ù‚ÙˆÙ‚ Ù…Ø­ÙÙˆØ¸ Ø§Ø³Øª"
ðŸ“‚ 16. Polish (pl.json)
JSON
"yourMediaYourPrivacy": "1. Twoje media, Twoja prywatnoÅ›Ä‡",
"yourMediaYourPrivacyContent": "Ta aplikacja odtwarza tylko pliki (wideo i muzykÄ™) znajdujÄ…ce siÄ™ w telefonie. Nie przeglÄ…damy Twoich prywatnych zdjÄ™Ä‡.",
"offlineExperience": "2. DziaÅ‚anie offline",
"offlineExperienceContent": "Playlisty sÄ… zapisywane na urzÄ…dzeniu. Nie wysyÅ‚amy Twoich danych na Å¼aden serwer.",
"noPersonalTracking": "3. Brak Å›ledzenia",
"noPersonalTrackingContent": "Nie pytamy o e-mail ani telefon. MoÅ¼esz korzystaÄ‡ z aplikacji bez konta.",
"whyPermissions": "4. Dlaczego uprawnienia?",
"whyPermissionsContent": "Prosimy o dostÄ™p do pamiÄ™ci tylko po to, aby znaleÅºÄ‡ TwojÄ… muzykÄ™.",
"securePrivate": "5. BezpieczeÅ„stwo",
"securePrivateContent": "Wszystkie dane sÄ… na telefonie. UsuniÄ™cie aplikacji usunie Twoje playlisty.",
"appVersion": "Wersja",
"allRightsReserved": "Wszelkie prawa zastrzeÅ¼one"
ðŸ“‚ 17. Portuguese (pt.json)
JSON
"yourMediaYourPrivacy": "1. Seus MÃ­dias, Sua Privacidade",
"yourMediaYourPrivacyContent": "Este app apenas reproduz arquivos (vÃ­deos e mÃºsicas) que jÃ¡ estÃ£o no seu telefone. NÃ£o acessamos suas fotos privadas.",
"offlineExperience": "2. ExperiÃªncia Offline",
"offlineExperienceContent": "Suas listas sÃ£o salvas no seu dispositivo. NÃ£o fazemos upload de seus dados.",
"noPersonalTracking": "3. Sem Rastreamento",
"noPersonalTrackingContent": "NÃ£o solicitamos seu nome ou e-mail. Use todos os recursos sem conta.",
"whyPermissions": "4. Por que PermissÃµes?",
"whyPermissionsContent": "Pedimos permissÃ£o de armazenamento apenas para localizar suas mÃºsicas.",
"securePrivate": "5. Seguro e Privado",
"securePrivateContent": "Seus dados sÃ£o privados. Se vocÃª excluir o app, suas listas serÃ£o removidas.",
"appVersion": "VersÃ£o",
"allRightsReserved": "Todos os direitos reservados"
ðŸ“‚ 18. Spanish (es.json)
JSON
"yourMediaYourPrivacy": "1. Tus medios, tu privacidad",
"yourMediaYourPrivacyContent": "Esta aplicaciÃ³n solo reproduce archivos (videos y mÃºsica) que ya estÃ¡n en tu telÃ©fono. No miramos tus fotos privadas.",
"offlineExperience": "2. Experiencia sin conexiÃ³n",
"offlineExperienceContent": "Tus listas se guardan en tu dispositivo. No subimos tus archivos a ningÃºn servidor.",
"noPersonalTracking": "3. Sin rastreo personal",
"noPersonalTrackingContent": "No pedimos tu nombre ni correo. Puedes usar el app sin cuenta.",
"whyPermissions": "4. Â¿Por quÃ© permisos?",
"whyPermissionsContent": "Pedimos permiso de almacenamiento solo para encontrar tus videos y mÃºsica.",
"securePrivate": "5. Seguro y privado",
"securePrivateContent": "Tus datos son privados. Si borras la aplicaciÃ³n, se borrarÃ¡n tus listas.",
"appVersion": "VersiÃ³n",
"allRightsReserved": "Todos los derechos reservados"
ðŸ“‚ 19. Swedish (sv.json)
JSON
"yourMediaYourPrivacy": "1. Dina medier, din integritet",
"yourMediaYourPrivacyContent": "Denna app spelar endast filer (videor och musik) pÃ¥ din telefon. Vi tittar inte pÃ¥ dina privata foton.",
"offlineExperience": "2. Offlineupplevelse",
"offlineExperienceContent": "Dina spellistor sparas pÃ¥ din enhet. Vi laddar inte upp din data till nÃ¥gon server.",
"noPersonalTracking": "3. Ingen spÃ¥rning",
"noPersonalTrackingContent": "Vi frÃ¥gar inte efter namn eller e-post. AnvÃ¤nd appen utan att skapa konto.",
"whyPermissions": "4. VarfÃ¶r behÃ¶righeter?",
"whyPermissionsContent": "Vi behÃ¶ver lagringsÃ¥tkomst endast fÃ¶r att hitta din musik.",
"securePrivate": "5. SÃ¤kert och privat",
"securePrivateContent": "All data sparas pÃ¥ din telefon. Om du tar bort appen raderas spellistorna.",
"appVersion": "Version",
"allRightsReserved": "Med ensamrÃ¤tt"
ðŸ“‚ 20. Tamil (ta.json)
JSON
"yourMediaYourPrivacy": "1. à®‰à®™à¯à®•à®³à¯ à®®à¯€à®Ÿà®¿à®¯à®¾, à®‰à®™à¯à®•à®³à¯ à®¤à®©à®¿à®¯à¯à®°à®¿à®®à¯ˆ",
"yourMediaYourPrivacyContent": "à®‡à®¨à¯à®¤ à®†à®ªà¯ à®‰à®™à¯à®•à®³à¯ à®®à¯Šà®ªà¯ˆà®²à®¿à®²à¯ à®‰à®³à¯à®³ à®•à¯‹à®ªà¯à®ªà¯à®•à®³à¯ˆ (à®µà¯€à®Ÿà®¿à®¯à¯‹ à®®à®±à¯à®±à¯à®®à¯ à®‡à®šà¯ˆ) à®®à®Ÿà¯à®Ÿà¯à®®à¯‡ à®‡à®¯à®•à¯à®•à¯à®•à®¿à®±à®¤à¯. à®‰à®™à¯à®•à®³à¯ à®¤à®©à®¿à®ªà¯à®ªà®Ÿà¯à®Ÿ à®ªà¯à®•à¯ˆà®ªà¯à®ªà®Ÿà®™à¯à®•à®³à¯ˆ à®¨à®¾à®™à¯à®•à®³à¯ à®ªà®¾à®°à¯à®ªà¯à®ªà®¤à®¿à®²à¯à®²à¯ˆ.",
"offlineExperience": "2. à®†à®ƒà®ªà¯à®²à¯ˆà®©à¯ à®…à®©à¯à®ªà®µà®®à¯",
"offlineExperienceContent": "à®ªà®¿à®³à¯‡à®²à®¿à®¸à¯à®Ÿà¯à®•à®³à¯ à®‰à®™à¯à®•à®³à¯ à®šà®¾à®¤à®©à®¤à¯à®¤à®¿à®²à¯‡à®¯à¯‡ à®šà¯‡à®®à®¿à®•à¯à®•à®ªà¯à®ªà®Ÿà¯à®®à¯. à®¤à®°à®µà¯ˆ à®¨à®¾à®™à¯à®•à®³à¯ à®ªà®¤à®¿à®µà¯‡à®±à¯à®±à¯à®µà®¤à®¿à®²à¯à®²à¯ˆ.",
"noPersonalTracking": "3. à®•à®£à¯à®•à®¾à®£à®¿à®ªà¯à®ªà¯ à®‡à®²à¯à®²à¯ˆ",
"noPersonalTrackingContent": "à®¨à®¾à®™à¯à®•à®³à¯ à®®à®¿à®©à¯à®©à®žà¯à®šà®²à¯ˆà®•à¯ à®•à¯‡à®Ÿà¯à®ªà®¤à®¿à®²à¯à®²à¯ˆ. à®•à®£à®•à¯à®•à¯ à®‡à®²à¯à®²à®¾à®®à®²à¯‡à®¯à¯‡ à®†à®ªà¯à®ªà¯ˆ à®ªà®¯à®©à¯à®ªà®Ÿà¯à®¤à¯à®¤à®²à®¾à®®à¯.",
"whyPermissions": "4. à®…à®©à¯à®®à®¤à®¿ à®à®©à¯ à®¤à¯‡à®µà¯ˆ?",
"whyPermissionsContent": "à®‰à®™à¯à®•à®³à¯ à®‡à®šà¯ˆ à®®à®±à¯à®±à¯à®®à¯ à®µà¯€à®Ÿà®¿à®¯à¯‹à®•à¯à®•à®³à¯ˆà®•à¯ à®•à®£à¯à®Ÿà®±à®¿à®¯ à®®à®Ÿà¯à®Ÿà¯à®®à¯‡ à®šà¯‡à®®à®¿à®ªà¯à®ªà®• à®…à®©à¯à®®à®¤à®¿ à®¤à¯‡à®µà¯ˆ.",
"securePrivate": "5. à®ªà®¾à®¤à¯à®•à®¾à®ªà¯à®ªà®¾à®©à®¤à¯",
"securePrivateContent": "à®¤à®°à®µà¯ à®‰à®™à¯à®•à®³à¯ à®ªà¯‹à®©à®¿à®²à¯ à®‡à®°à¯à®ªà¯à®ªà®¤à®¾à®²à¯ à®ªà®¾à®¤à¯à®•à®¾à®ªà¯à®ªà®¾à®©à®¤à¯. à®†à®ªà¯à®ªà¯ˆ à®¨à¯€à®•à¯à®•à®¿à®©à®¾à®²à¯ à®ªà®¿à®³à¯‡à®²à®¿à®¸à¯à®Ÿà¯à®•à®³à¯à®®à¯ à®¨à¯€à®•à¯à®•à®ªà¯à®ªà®Ÿà¯à®®à¯.",
"appVersion": "à®ªà®¤à®¿à®ªà¯à®ªà¯",
"allRightsReserved": "à®…à®©à¯ˆà®¤à¯à®¤à¯ à®‰à®°à®¿à®®à¯ˆà®•à®³à¯à®®à¯ à®ªà®¾à®¤à¯à®•à®¾à®•à¯à®•à®ªà¯à®ªà®Ÿà¯à®Ÿà®µà¯ˆ"
ðŸ“‚ 21. Urdu (ur.json)
JSON
"yourMediaYourPrivacy": "Û±. Ø¢Ù¾ Ú©Ø§ Ù…ÛŒÚˆÛŒØ§ØŒ Ø¢Ù¾ Ú©ÛŒ Ø±Ø§Ø²Ø¯Ø§Ø±ÛŒ",
"yourMediaYourPrivacyContent": "ÛŒÛ Ø§ÛŒÙ¾ ØµØ±Ù Ø¢Ù¾ Ú©Û’ ÙÙˆÙ† Ù…ÛŒÚº Ù…ÙˆØ¬ÙˆØ¯ ÙØ§Ø¦Ù„ÙˆÚº (ÙˆÛŒÚˆÛŒÙˆ Ø§ÙˆØ± Ù…ÙˆØ³ÛŒÙ‚ÛŒ) Ú©Ùˆ Ú†Ù„Ø§ØªÛŒ ÛÛ’Û” ÛÙ… Ø¢Ù¾ Ú©ÛŒ Ù†Ø¬ÛŒ ØªØµØ§ÙˆÛŒØ± Ú©Ùˆ Ù†ÛÛŒÚº Ø¯ÛŒÚ©Ú¾ØªÛ’Û”",
"offlineExperience": "Û². Ø¢Ù Ù„Ø§Ø¦Ù† ØªØ¬Ø±Ø¨Û",
"offlineExperienceContent": "Ø¢Ù¾ Ú©ÛŒ Ù¾Ù„Û’ Ù„Ø³Ù¹Ø³ Ø§ÙˆØ± Ù¾Ø³Ù†Ø¯ÛŒØ¯Û Ø¢Ù¾ Ú©Û’ ÙÙˆÙ† à¤ªà¤° ÛÛŒ Ù…Ø­ÙÙˆØ¸ Ø±ÛØªÛ’ ÛÛŒÚºÛ” ÛÙ… Ø¢Ù¾ Ú©Ø§ ÚˆÛŒÙ¹Ø§ Ø§Ù¾ Ù„ÙˆÚˆ Ù†ÛÛŒÚº Ú©Ø±ØªÛ’Û”",
"noPersonalTracking": "Û³. Ú©ÙˆØ¦ÛŒ Ù¹Ø±ÛŒÚ©Ù†Ú¯ Ù†ÛÛŒÚº",
"noPersonalTrackingContent": "ÛÙ… Ø¢Ù¾ Ú©Ø§ Ù†Ø§Ù… ÛŒØ§ Ø§ÛŒ Ù…ÛŒÙ„ Ù†ÛÛŒÚº Ù¾ÙˆÚ†Ú¾ØªÛ’Û” Ø¢Ù¾ Ø§Ú©Ø§Ø¤Ù†Ù¹ Ú©Û’ Ø¨ØºÛŒØ± Ø§ÛŒÙ¾ Ú©ÛŒ ØªÙ…Ø§Ù… Ø®ØµÙˆØµÛŒØ§Øª Ø§Ø³ØªØ¹Ù…Ø§Ù„ Ú©Ø± Ø³Ú©ØªÛ’ ÛÛŒÚºÛ”",
"whyPermissions": "Û´. ÛÙ…ÛŒÚº Ø§Ø¬Ø§Ø²Øª Ú©ÛŒÙˆÚº Ú†Ø§ÛÛŒÛ’ØŸ",
"whyPermissionsContent": "ÛÙ…ÛŒÚº Ù…ÛŒÚˆÛŒØ§ ÙØ§Ø¦Ù„ÙˆÚº Ú©Ùˆ Ú†Ù„Ø§Ù†Û’ Ú©Û’ Ù„ÛŒÛ’ ØµØ±Ù Ø§Ø³Ù¹ÙˆØ±ÛŒØ¬ Ú©ÛŒ Ø§Ø¬Ø§Ø²Øª Ø¯Ø±Ú©Ø§Ø± ÛÙˆØªÛŒ ÛÛ’Û” Ø§Ø³ Ú©Û’ Ø¨ØºÛŒØ± Ø§ÛŒÙ¾ ÙØ§Ø¦Ù„ÛŒÚº Ù†ÛÛŒÚº Ø¯Ú©Ú¾Ø§ Ø³Ú©Û’ Ú¯ÛŒÛ”",
"securePrivate": "Ûµ. Ù…Ø­ÙÙˆØ¸ Ø§ÙˆØ± Ù†Ø¬ÛŒ",
"securePrivateContent": "Ø¢Ù¾ Ú©Ø§ ÚˆÛŒÙ¹Ø§ Ù†Ø¬ÛŒ ÛÛ’Û” Ø§ÛŒÙ¾ ÚˆÛŒÙ„ÛŒÙ¹ Ú©Ø±Ù†Û’ Ø³Û’ Ø¢Ù¾ Ú©ÛŒ Ø¨Ù†Ø§Ø¦ÛŒ Ú¯Ø¦ÛŒ Ù„Ø³Ù¹Ø³ Ø¨Ú¾ÛŒ Ø®ØªÙ… ÛÙˆ Ø¬Ø§Ø¦ÛŒÚº Ú¯ÛŒÛ”",
"appVersion": "ÙˆØ±Ú˜Ù†",
"allRightsReserved": "Ø¬Ù…Ù„Û Ø­Ù‚ÙˆÙ‚ Ù…Ø­ÙÙˆØ¸ ÛÛŒÚº"
 */


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