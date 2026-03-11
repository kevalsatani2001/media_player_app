/*
  connectivity_plus:
  app_settings:
 */


import 'dart:async';
import 'package:app_settings/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

import '../screens/setting_screen.dart';
import '../utils/app_colors.dart';
import '../widgets/text_widget.dart';
import 'ads_service.dart';

// à«§. àª‡àª¨à«àªŸàª°àª¨à«‡àªŸ àªšà«‡àª• àª•àª°àªµàª¾ àª®àª¾àªŸà«‡
class NetworkInfo {
  static Future<bool> isConnected() async {
    final List<ConnectivityResult> result = await Connectivity()
        .checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isOffline = false;
  bool _isConnecting = false;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      bool currentStatus = results.contains(ConnectivityResult.none);

      // àªœà«‹ àª¯à«àªàª° àª“àª«àª²àª¾àª‡àª¨àª®àª¾àª‚àª¥à«€ àª“àª¨àª²àª¾àª‡àª¨ àª¥àª¾àª¯, àª¤à«‹ àªœ àªàª¨àª¿àª®à«‡àª¶àª¨ àª¬àª¤àª¾àªµà«‹
      if (!currentStatus && _isOffline) {
        _startConnectingAnimation();
      } else {
        setState(() => _isOffline = currentStatus);
      }
    });
  }

  void _startConnectingAnimation() {
    setState(() {
      _isConnecting = true;
      _isOffline = false;
    });

    // à«¨ àª¸à«‡àª•àª¨à«àª¡àª¨à«‹ àª«à«‹àª°à«àª¸à«àª¡ àª¹à«‹àª²à«àª¡ (àªœà«‡àª¥à«€ "Connecting..." àª¦à«‡àª–àª¾àª¯)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Scaffold(
      body: Stack(
        children: [
          // Key àª‰àª®à«‡àª°àªµàª¾àª¥à«€ àª†àª–à«àª‚ àªµàª¿àªœà«‡àªŸ àªŸà«àª°à«€ àª°àª¿àª«à«àª°à«‡àª¶ àª¥àª¶à«‡ àªœà«‡àªµà«àª‚ àª¨à«‡àªŸ àª†àªµàª¶à«‡
          KeyedSubtree(key: ValueKey(_isConnecting), child: widget.child),

          if (_isOffline && !_isConnecting) _buildLockScreen(colors),
          if (_isConnecting) _buildConnectingScreen(colors),
        ],
      ),
    );
  }

  // --- àª²à«‹àª• àª¸à«àª•à«àª°à«€àª¨ UI (àª¤àª®àª¾àª°à«€ àªªà«àª°àª¾àª‡àªµàª¸à«€ àªªà«‹àª²àª¿àª¸à«€ àªœà«‡àªµà«€ àª¡àª¿àªàª¾àªˆàª¨) ---
  Widget _buildLockScreen(AppThemeColors colors) {
    return Container(
      key: const ValueKey('lock'),
      color: colors.background,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 70,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 30),
          AppText(
            context.tr("internetRequired"),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AppText(
              context.tr("mandatoryInternetContent"),
              fontSize: 14,
              color: colors.secondaryText,
              align: TextAlign.center,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _buildButton(colors, context.tr("checkConnection"), () {
            AppSettings.openAppSettings(type: AppSettingsType.wireless);
          }),
        ],
      ),
    );
  }

  // --- àª•àª¨à«‡àª•à«àªŸàª¿àª‚àª— àªàª¨àª¿àª®à«‡àª¶àª¨ UI ---
  Widget _buildConnectingScreen(AppThemeColors colors) {
    return Container(
      key: const ValueKey('connecting'),
      color: colors.background,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colors.primary,
              backgroundColor: colors.primary.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 30),
          AppText(
            context.tr("restoringConnection"), // "Connecting..."
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.primary,
          ),
        ],
      ),
    );
  }

  // àª•àª¸à«àªŸàª® àª¬àªŸàª¨ àªµàª¿àªœà«‡àªŸ
  Widget _buildButton(AppThemeColors colors, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: AppText(
          text,
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/*
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/app_imports.dart';
import 'connectivity_service.dart';

class AdHelper {
  static String get bannerId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    return '';
  }

  static String get interstitialId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return '';
  }

  static String get rewardedId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    return '';
  }

  static String get appOpenId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/9257395921';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/5662855259';
    return '';
  }

  static AppOpenAd? _appOpenAd;
  static bool _isShowingAd = false;
  static DateTime? _appOpenLoadTime;

  // AdHelper àª•à«àª²àª¾àª¸àª¨à«€ àª…àª‚àª¦àª° àª† àª‰àª®à«‡àª°à«‹:

  static int _playCount = 0; // àªµàª¿àª¡àª¿àª¯à«‹ àª—àª£àªµàª¾ àª®àª¾àªŸà«‡

  static void playVideoWithAds(BuildContext context, VoidCallback startVideo) async {
    bool isOnline = await NetworkInfo.isConnected();
    _playCount++;

    if (isOnline) {
      // --- àªœà«‹ àª“àª¨àª²àª¾àª‡àª¨ àª¹à«‹àª¯ àª¤à«‹: àª¦àª° à«© àªµàª¿àª¡àª¿àª¯à«‹àª Interstitial àªàª¡ ---
      if (_playCount % 3 == 0) {
        showInterstitialAd(startVideo);
      } else {
        startVideo();
      }
    } else {
      // --- àªœà«‹ àª“àª«àª²àª¾àª‡àª¨ àª¹à«‹àª¯ àª¤à«‹: à«©à«¦ àª¸à«‡àª•àª¨à«àª¡àª¨à«àª‚ àªµà«‡àªŸàª¿àª‚àª— àªŸàª¾àªˆàª®àª° ---
      _showOfflineTimerDialog(context, startVideo);
    }
  }

  static void _showOfflineTimerDialog(BuildContext context, VoidCallback onFinish) {
    int timeLeft = 30;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // àªŸàª¾àªˆàª®àª° àª¶àª°à«‚ àª•àª°à«‹
          Timer.periodic(const Duration(seconds: 1), (timer) {
            if (timeLeft > 0) {
              if (context.mounted) setDialogState(() => timeLeft--);
            } else {
              timer.cancel();
              if (context.mounted) {
                Navigator.pop(context); // àª¡àª¾àª¯àª²à«‹àª— àª¬àª‚àª§ àª•àª°à«‹
                onFinish(); // àªµàª¿àª¡àª¿àª¯à«‹ àª¶àª°à«‚ àª•àª°à«‹
              }
            }
          });

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text("Internet Required ðŸ“¶", style: TextStyle(color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("To skip waiting and support this app, please turn on internet."),
                const SizedBox(height: 20),
                const Text("Otherwise, video starts in:"),
                Text("$timeLeft", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 1. Standard Banner Ad Widget ---
  static Widget bannerAdWidget({AdSize size = AdSize.banner}) {
    return BannerAdWidget(size: size);
  }

  // --- 2. Adaptive Banner Ad Widget ---
  static Widget adaptiveBannerWidget(BuildContext context) {
    return FutureBuilder<AdSize?>(
      future: AdSize.getAnchoredAdaptiveBannerAdSize(
        Orientation.portrait,
        MediaQuery.of(context).size.width.truncate(),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return BannerAdWidget(size: snapshot.data!);
        } else {
          return BannerAdWidget(size: AdSize.banner);
        }
      },
    );
  }

  // --- 3. Promo Banner (Error Placeholder) ---
  static Widget _buildPromoBanner(BuildContext context, AdSize size) {
    return GestureDetector(
      onTap: () {
        // launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=your_id"));
      },
      child: Container(
        width: size.width.toDouble(),
        height: size.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 8,horizontal: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade400],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              "Enjoying the App? Rate us 5 Stars!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Shimmer Placeholder ---
  static Widget _buildShimmerPlaceholder(AdSize size) {
    return Container(
      width: size.width.toDouble(),
      height: size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 8,horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: SizedBox(
          width: 25,
          height: 25,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      ),
    );
  }

  // --- 5. App Open Ad ---
  static void loadAppOpenAd() async {
    // àªªàª¹à«‡àª²àª¾ àª¨à«‡àªŸ àªšà«‡àª• àª•àª°à«‹
    final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) return;

    AppOpenAd.load(
      adUnitId: appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) => debugPrint('AppOpenAd failed: $error'),
      ),
    );
  }

  static DateTime? _lastAdShowTime;
  static bool isFullScreenAdShowing = false;
  static bool _hasShownAppOpenAdThisSession = false;

  static bool _isAdAvailable() {
    if (_appOpenAd == null || _appOpenLoadTime == null) return false;
    return DateTime.now().difference(_appOpenLoadTime!).inHours < 4;
  }

  static void showAppOpenAdIfAvailable() {
    // Only show once per app session
    if (_hasShownAppOpenAdThisSession) {
      debugPrint("App Open Ad already shown this session. Skipping.");
      return;
    }

    if (isFullScreenAdShowing) {
      debugPrint("àª¬à«€àªœà«€ àªàª¡ àªšàª¾àª²à« àª›à«‡, App Open Ad àª¸à«àª•à«€àªª àª•àª°à«€.");
      return;
    }

    if (!_isAdAvailable()) {
      loadAppOpenAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        isFullScreenAdShowing = true;
        _hasShownAppOpenAdThisSession = true; // mark as shown
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        isFullScreenAdShowing = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        isFullScreenAdShowing = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }

  // --- 6. Interstitial Ad ---
  static void showInterstitialAd(VoidCallback onAdDismissed) {
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              isFullScreenAdShowing = true; // àª…àª—àª¤à«àª¯àª¨à«àª‚: àª…àª¹à«€àª‚ àªŸà«àª°à« àª•àª°àªµà«àª‚
            },
            onAdDismissedFullScreenContent: (ad) {
              isFullScreenAdShowing = false; // àª…àª—àª¤à«àª¯àª¨à«àª‚: àª…àª¹à«€àª‚ àª«à«‹àª²à«àª¸ àª•àª°àªµà«àª‚
              ad.dispose();
              onAdDismissed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              isFullScreenAdShowing = false;
              ad.dispose();
              onAdDismissed();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          isFullScreenAdShowing = false;
          onAdDismissed();
        },
      ),
    );
  }

  // --- 7. Rewarded Ad ---
  static void showRewardedAd(VoidCallback onRewardEarned) {
    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
          );
          ad.show(onUserEarnedReward: (ad, reward) => onRewardEarned());
        },
        onAdFailedToLoad: (error) => debugPrint("Rewarded Error: $error"),
      ),
    );
  }
}

class BannerAdWidget extends StatefulWidget {
  final AdSize size;

  const BannerAdWidget({super.key, required this.size});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isError = false;
  late StreamSubscription _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadAd();

    // à«§. àª¨à«‡àªŸàªµàª°à«àª• àª²àª¿àªàª¨àª° àªœà«‡àªµà«àª‚ àª¨à«‡àªŸ àª†àªµà«‡ àª•à«‡ àª¤àª°àª¤ àªœ àªàª¡ àª²à«‹àª¡ àª•àª°àª¶à«‡
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      bool isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline && !_isLoaded) {
        debugPrint("Network Restored: Loading Banner Ad...");
        _loadAd();
      }
    });
  }

  // à«¨. àªœà«‹ àªµàª¿àªœà«‡àªŸàª¨àª¾ àªªà«‡àª°àª¾àª®à«€àªŸàª° àª¬àª¦àª²àª¾àª¯ àª¤à«‹ àª«àª°à«€ àª²à«‹àª¡ àª•àª°à«‹
  @override
  void didUpdateWidget(covariant BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isLoaded) _loadAd();
  }

  void _loadAd() async {
    // àª‡àª¨à«àªŸàª°àª¨à«‡àªŸ àªšà«‡àª• àª•àª°à«‹
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      if (mounted) setState(() => _isError = true);
      return;
    }

    // àªœà«‚àª¨à«€ àªàª¡ àª•à«àª²à«€àª¨ àª•àª°à«‹
    await _bannerAd?.dispose();
    _bannerAd = null;

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerId,
      size: widget.size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint("Banner Ad Successfully Loaded!");
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isError = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("Banner Ad Failed: ${error.message}");
          ad.dispose();
          if (mounted) setState(() => _isError = true);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) return AdHelper._buildPromoBanner(context, widget.size);

    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: widget.size.width.toDouble(),
        height: widget.size.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    return AdHelper._buildShimmerPlaceholder(widget.size);
  }
}
/*
Standard Project Quotation: Professional Android Media PlayerArchitecture: Flutter (Clean BLoC + Provider) | Version: 1.0 (Production Ready)1. Module-wise Standard Costing (INR)Module 1: UI/UX & Navigation FrameworkScope: 4-Tab Bottom Navigation (Home, Video, Audio, Settings), Material 3 Design, Theme Management (Light/Dark), and Multi-language support.Cost: â‚¹15,000Timeline: 5 DaysModule 2: Media Discovery & Storage LogicScope: Device scanning for local files, folder-wise categorization, high-speed thumbnail caching, and Android 13+ Scoped Storage permission handling.Cost: â‚¹25,000Timeline: 7 DaysModule 3: Global Player & Mini-Player SystemScope: Advanced Video Player (Gestures, Subtitles support), Audio Player with Background Service (continues playing when app is closed), and a Global Mini-Player that stays synced across all tabs.Cost: â‚¹35,000Timeline: 10 DaysModule 4: Data Management (Playlists & Favorites)Scope: SQLite database integration, logic for duplicate playlist names, validation for items already in a playlist, and Favorites management.Cost: â‚¹20,000Timeline: 6 DaysModule 5: Search & File OperationsScope: Unified search (Audio/Video/Playlists), Share functionality, Metadata display, and secure File Deletion (Android OS prompt logic).Cost: â‚¹15,000Timeline: 5 DaysModule 6: AdMob Integration & MonetizationScope: Implementation of 4 Ad types (App Open, Banner, Interstitial, Rewarded), custom AdHelper to prevent overlaps, and ProGuard/R8 rules for Android security.Cost: â‚¹12,000Timeline: 3 Days2. Cost Summary TableComponentProfessional Standard Rate (INR)UI/UX & Navigationâ‚¹15,000Media Fetching Engineâ‚¹25,000Player & Background Serviceâ‚¹35,000Database & Validation Logicâ‚¹20,000Search & File Opsâ‚¹15,000AdMob & Settingsâ‚¹12,000Total Standard Project Costâ‚¹1,22,000
 */


 */
/*
{
"internetRequired": "Internet Required",
"mandatoryInternetContent": "To enjoy free services, an active internet connection is mandatory for loading ads.",
"checkConnection": "Check Connection",
"restoringConnection": "Connecting..."
}
{
  "internetRequired": "Ø§Ù„Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø¥Ù†ØªØ±Ù†Øª Ù…Ø·Ù„ÙˆØ¨",
  "mandatoryInternetContent": "Ù„Ù„Ø§Ø³ØªÙ…ØªØ§Ø¹ Ø¨Ø§Ù„Ø®Ø¯Ù…Ø§Øª Ø§Ù„Ù…Ø¬Ø§Ù†ÙŠØ©ØŒ ÙŠØ¹Ø¯ Ø§Ù„Ø§ØªØµØ§Ù„ Ø§Ù„Ù†Ø´Ø· Ø¨Ø§Ù„Ø¥Ù†ØªØ±Ù†Øª Ø¥Ù„Ø²Ø§Ù…ÙŠØ§Ù‹ Ù„ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø¥Ø¹Ù„Ø§Ù†Ø§Øª.",
  "checkConnection": "ØªØ­Ù‚Ù‚ Ù…Ù† Ø§Ù„Ø§ØªØµØ§Ù„",
  "restoringConnection": "Ø¬Ø§Ø±ÙŠ Ø§Ù„Ø§ØªØµØ§Ù„..."
}{
  "internetRequired": "á€¡á€„á€ºá€á€¬á€”á€€á€º á€œá€­á€¯á€¡á€•á€ºá€žá€Šá€º",
  "mandatoryInternetContent": "á€¡á€á€™á€²á€· á€á€”á€ºá€†á€±á€¬á€„á€ºá€™á€¾á€¯á€™á€»á€¬á€¸ á€›á€›á€¾á€­á€›á€”á€ºá€¡á€á€½á€€á€º á€€á€¼á€±á€¬á€ºá€„á€¼á€¬á€™á€»á€¬á€¸ á€á€„á€ºá€›á€”á€º á€¡á€„á€ºá€á€¬á€”á€€á€º á€á€»á€­á€á€ºá€†á€€á€ºá€™á€¾á€¯ á€›á€¾á€­á€›á€•á€«á€™á€Šá€ºá‹",
  "checkConnection": "á€á€»á€­á€á€ºá€†á€€á€ºá€™á€¾á€¯á€€á€­á€¯ á€…á€…á€ºá€†á€±á€¸á€•á€«",
  "restoringConnection": "á€á€»á€­á€á€ºá€†á€€á€ºá€”á€±á€žá€Šá€º..."
}{
  "internetRequired": "Kailangan ng Internet",
  "mandatoryInternetContent": "Upang tamasahin ang mga libreng serbisyo, kailangan ang internet para sa mga ad.",
  "checkConnection": "Suriin ang Koneksyon",
  "restoringConnection": "Kumokonekta..."
}{
  "internetRequired": "Internet Requis",
  "mandatoryInternetContent": "Pour profiter des services gratuits, une connexion internet est obligatoire pour charger les publicitÃ©s.",
  "checkConnection": "VÃ©rifier la Connexion",
  "restoringConnection": "Connexion en cours..."
}{
  "internetRequired": "Internet Erforderlich",
  "mandatoryInternetContent": "Um kostenlose Dienste zu nutzen, ist eine Internetverbindung zum Laden von Anzeigen erforderlich.",
  "checkConnection": "Verbindung PrÃ¼fen",
  "restoringConnection": "Verbinden..."
}{
  "internetRequired": "àª‡àª¨à«àªŸàª°àª¨à«‡àªŸ àªœàª°à«‚àª°à«€ àª›à«‡",
  "mandatoryInternetContent": "àª®àª«àª¤ àª¸à«‡àªµàª¾àª“àª¨à«‹ àª†àª¨àª‚àª¦ àª®àª¾àª£àªµàª¾ àª®àª¾àªŸà«‡, àªœàª¾àª¹à«‡àª°àª¾àª¤à«‹ àª²à«‹àª¡ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡ àª‡àª¨à«àªŸàª°àª¨à«‡àªŸ àª•àª¨à«‡àª•à«àª¶àª¨ àª«àª°àªœàª¿àª¯àª¾àª¤ àª›à«‡.",
  "checkConnection": "àª•àª¨à«‡àª•à«àª¶àª¨ àª¤àªªàª¾àª¸à«‹",
  "restoringConnection": "àª•àª¨à«‡àª•à«àªŸ àª¥àªˆ àª°àª¹à«àª¯à«àª‚ àª›à«‡..."
}{
  "internetRequired": "à¤‡à¤‚à¤Ÿà¤°à¤¨à¥‡à¤Ÿ à¤†à¤µà¤¶à¥à¤¯à¤• à¤¹à¥ˆ",
  "mandatoryInternetContent": "à¤®à¥à¤«à¤¼à¥à¤¤ à¤¸à¥‡à¤µà¤¾à¤“à¤‚ à¤•à¤¾ à¤†à¤¨à¤‚à¤¦ à¤²à¥‡à¤¨à¥‡ à¤•à¥‡ à¤²à¤¿à¤, à¤µà¤¿à¤œà¥à¤žà¤¾à¤ªà¤¨ à¤²à¥‹à¤¡ à¤•à¤°à¤¨à¥‡ à¤¹à¥‡à¤¤à¥ à¤‡à¤‚à¤Ÿà¤°à¤¨à¥‡à¤Ÿ à¤•à¤¨à¥‡à¤•à¥à¤¶à¤¨ à¤…à¤¨à¤¿à¤µà¤¾à¤°à¥à¤¯ à¤¹à¥ˆà¥¤",
  "checkConnection": "à¤•à¤¨à¥‡à¤•à¥à¤¶à¤¨ à¤œà¤¾à¤‚à¤šà¥‡à¤‚",
  "restoringConnection": "à¤•à¤¨à¥‡à¤•à¥à¤Ÿ à¤¹à¥‹ à¤°à¤¹à¤¾ à¤¹à¥ˆ..."
}{
  "internetRequired": "Internet Diperlukan",
  "mandatoryInternetContent": "Untuk menikmati layanan gratis, koneksi internet aktif wajib untuk memuat iklan.",
  "checkConnection": "Periksa Koneksi",
  "restoringConnection": "Menghubungkan..."
}{
  "internetRequired": "Internet Richiesto",
  "mandatoryInternetContent": "Per usufruire dei servizi gratuiti, la connessione internet Ã¨ obbligatoria per caricare gli annunci.",
  "checkConnection": "Controlla Connessione",
  "restoringConnection": "Connessione in corso..."
}{
  "internetRequired": "ã‚¤ãƒ³ã‚¿ãƒ¼ãƒãƒƒãƒˆãŒå¿…è¦",
  "mandatoryInternetContent": "ç„¡æ–™ã‚µãƒ¼ãƒ“ã‚¹ã‚’åˆ©ç”¨ã™ã‚‹ã«ã¯ã€åºƒå‘Šã‚’èª­ã¿è¾¼ã‚€ãŸã‚ã«ã‚¤ãƒ³ã‚¿ãƒ¼ãƒãƒƒãƒˆæŽ¥ç¶šãŒå¿…é ˆã§ã™ã€‚",
  "checkConnection": "æŽ¥ç¶šã‚’ç¢ºèª",
  "restoringConnection": "æŽ¥ç¶šä¸­..."
}{
  "internetRequired": "ì¸í„°ë„· í•„ìš”",
  "mandatoryInternetContent": "ë¬´ë£Œ ì„œë¹„ìŠ¤ë¥¼ ì¦ê¸°ë ¤ë©´ ê´‘ê³  ë¡œë“œë¥¼ ìœ„í•´ ì¸í„°ë„· ì—°ê²°ì´ í•„ìˆ˜ìž…ë‹ˆë‹¤.",
  "checkConnection": "ì—°ê²° í™•ì¸",
  "restoringConnection": "ì—°ê²° ì¤‘..."
}{
  "internetRequired": "Internet Diperlukan",
  "mandatoryInternetContent": "Untuk menikmati perkhidmatan percuma, sambungan internet wajib untuk memuatkan iklan.",
  "checkConnection": "Semak Sambungan",
  "restoringConnection": "Menyambung..."
}{
  "internetRequired": "à¤‡à¤‚à¤Ÿà¤°à¤¨à¥‡à¤Ÿ à¤†à¤µà¤¶à¥à¤¯à¤• à¤†à¤¹à¥‡",
  "mandatoryInternetContent": "à¤µà¤¿à¤¨à¤¾à¤®à¥‚à¤²à¥à¤¯ à¤¸à¥‡à¤µà¤¾à¤‚à¤šà¤¾ à¤†à¤¨à¤‚à¤¦ à¤˜à¥‡à¤£à¥à¤¯à¤¾à¤¸à¤¾à¤ à¥€, à¤œà¤¾à¤¹à¤¿à¤°à¤¾à¤¤à¥€ à¤²à¥‹à¤¡ à¤•à¤°à¤£à¥à¤¯à¤¾à¤¸à¤¾à¤ à¥€ à¤‡à¤‚à¤Ÿà¤°à¤¨à¥‡à¤Ÿ à¤•à¤¨à¥‡à¤•à¥à¤¶à¤¨ à¤…à¤¨à¤¿à¤µà¤¾à¤°à¥à¤¯ à¤†à¤¹à¥‡.",
  "checkConnection": "à¤•à¤¨à¥‡à¤•à¥à¤¶à¤¨ à¤¤à¤ªà¤¾à¤¸à¤¾",
  "restoringConnection": "à¤•à¤¨à¥‡à¤•à¥à¤Ÿ à¤¹à¥‹à¤¤ à¤†à¤¹à¥‡..."
}{
  "internetRequired": "Ø§ÛŒÙ†ØªØ±Ù†Øª Ù…ÙˆØ±Ø¯ Ù†ÛŒØ§Ø² Ø§Ø³Øª",
  "mandatoryInternetContent": "Ø¨Ø±Ø§ÛŒ Ø¨Ù‡Ø±Ù‡â€ŒÙ…Ù†Ø¯ÛŒ Ø§Ø² Ø®Ø¯Ù…Ø§Øª Ø±Ø§ÛŒÚ¯Ø§Ù†ØŒ Ø§ØªØµØ§Ù„ Ø¨Ù‡ Ø§ÛŒÙ†ØªØ±Ù†Øª Ø¨Ø±Ø§ÛŒ Ø¨Ø§Ø±Ú¯Ø°Ø§Ø±ÛŒ ØªØ¨Ù„ÛŒØºØ§Øª Ø§Ù„Ø²Ø§Ù…ÛŒ Ø§Ø³Øª.",
  "checkConnection": "Ø¨Ø±Ø±Ø³ÛŒ Ø§ØªØµØ§Ù„",
  "restoringConnection": "Ø¯Ø± Ø­Ø§Ù„ Ø§ØªØµØ§Ù„..."
}{
  "internetRequired": "Wymagany Internet",
  "mandatoryInternetContent": "Aby korzystaÄ‡ z bezpÅ‚atnych usÅ‚ug, poÅ‚Ä…czenie internetowe jest obowiÄ…zkowe do Å‚adowania reklam.",
  "checkConnection": "SprawdÅº PoÅ‚Ä…czenie",
  "restoringConnection": "ÅÄ…czenie..."
}{
  "internetRequired": "Internet NecessÃ¡ria",
  "mandatoryInternetContent": "Para desfrutar de serviÃ§os gratuitos, a conexÃ£o Ã  internet Ã© obrigatÃ³ria para carregar anÃºncios.",
  "checkConnection": "Verificar ConexÃ£o",
  "restoringConnection": "Conectando..."
}{
  "internetRequired": "Internet Requerido",
  "mandatoryInternetContent": "Para disfrutar de servicios gratuitos, la conexiÃ³n a internet es obligatoria para cargar anuncios.",
  "checkConnection": "Verificar ConexiÃ³n",
  "restoringConnection": "Conectando..."
}{
  "internetRequired": "Internet KrÃ¤vs",
  "mandatoryInternetContent": "FÃ¶r att anvÃ¤nda gratistjÃ¤nster krÃ¤vs en internetanslutning fÃ¶r att ladda annonser.",
  "checkConnection": "Kontrollera Anslutning",
  "restoringConnection": "Ansluter..."
}{
  "internetRequired": "à®‡à®£à¯ˆà®¯à®®à¯ à®¤à¯‡à®µà¯ˆ",
  "mandatoryInternetContent": "à®‡à®²à®µà®š à®šà¯‡à®µà¯ˆà®•à®³à¯ˆà®ªà¯ à®ªà¯†à®±, à®µà®¿à®³à®®à¯à®ªà®°à®™à¯à®•à®³à¯ˆ à®à®±à¯à®± à®‡à®£à¯ˆà®¯ à®‡à®£à¯ˆà®ªà¯à®ªà¯ à®•à®Ÿà¯à®Ÿà®¾à®¯à®®à®¾à®•à¯à®®à¯.",
  "checkConnection": "à®‡à®£à¯ˆà®ªà¯à®ªà¯ˆà®šà¯ à®šà®°à®¿à®ªà®¾à®°à¯à®•à¯à®•à®µà¯à®®à¯",
  "restoringConnection": "à®‡à®£à¯ˆà®•à¯à®•à®¿à®±à®¤à¯..."
}{
  "internetRequired": "Ø§Ù†Ù¹Ø±Ù†ÛŒÙ¹ Ø¯Ø±Ú©Ø§Ø± ÛÛ’",
  "mandatoryInternetContent": "Ù…ÙØª Ø®Ø¯Ù…Ø§Øª Ø³Û’ Ù„Ø·Ù Ø§Ù†Ø¯ÙˆØ² ÛÙˆÙ†Û’ Ú©Û’ Ù„ÛŒÛ’ØŒ Ø§Ø´ØªÛØ§Ø±Ø§Øª Ù„ÙˆÚˆ Ú©Ø±Ù†Û’ Ú©Û’ Ù„ÛŒÛ’ Ø§Ù†Ù¹Ø±Ù†ÛŒÙ¹ Ú©Ù†Ú©Ø´Ù† Ù„Ø§Ø²Ù…ÛŒ ÛÛ’Û”",
  "checkConnection": "Ú©Ù†Ú©Ø´Ù† Ú†ÛŒÚ© Ú©Ø±ÛŒÚº",
  "restoringConnection": "Ù…Ù†Ø³Ù„Ú© ÛÙˆ Ø±ÛØ§ ÛÛ’..."
}
 */