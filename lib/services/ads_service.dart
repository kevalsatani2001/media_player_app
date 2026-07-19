// import 'dart:math' show max, min;
//
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/foundation.dart';
// import '../utils/app_imports.dart';
// import 'connectivity_service.dart';
//
// class AdHelper {
//   /// Provide production IDs with --dart-define for release builds.
//   /// Example:
//   /// --dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-xxx/yyy
//   static const String _androidBannerId = String.fromEnvironment(
//     'ADMOB_ANDROID_BANNER_ID',
//     defaultValue: 'ca-app-pub-5851220383544299/6990350725',
//   );
//   static const String _iosBannerId = String.fromEnvironment(
//     'ADMOB_IOS_BANNER_ID',
//   );
//   static const String _androidInterstitialId = String.fromEnvironment(
//     'ADMOB_ANDROID_INTERSTITIAL_ID',
//     defaultValue: 'ca-app-pub-5851220383544299/9424942373',
//   );
//   static const String _iosInterstitialId = String.fromEnvironment(
//     'ADMOB_IOS_INTERSTITIAL_ID',
//   );
//   static const String _androidRewardedId = String.fromEnvironment(
//     'ADMOB_ANDROID_REWARDED_ID',
//     defaultValue: 'ca-app-pub-5851220383544299/8697124576',
//   );
//   static const String _iosRewardedId = String.fromEnvironment(
//     'ADMOB_IOS_REWARDED_ID',
//   );
//   static const String _androidAppOpenId = String.fromEnvironment(
//     'ADMOB_ANDROID_APP_OPEN_ID',
//     defaultValue: 'ca-app-pub-5851220383544299/2703621355',
//   );
//   static const String _iosAppOpenId = String.fromEnvironment(
//     'ADMOB_IOS_APP_OPEN_ID',
//   );
//   static const String _androidNativePauseId = String.fromEnvironment(
//     'ADMOB_ANDROID_NATIVE_PAUSE_ID',
//     defaultValue: 'ca-app-pub-5851220383544299/8111860707',
//   );
//   static const String _iosNativePauseId = String.fromEnvironment(
//     'ADMOB_IOS_NATIVE_PAUSE_ID',
//   );
//
//   // Official Google test ids (safe in debug/dev).
//   static const String _testAndroidNative = 'ca-app-pub-3940256099942544/2247696110';
//   static const String _testIosNative = 'ca-app-pub-3940256099942544/3986624511';
//   static const String _testAndroidBanner = 'ca-app-pub-3940256099942544/6300978111';
//   static const String _testIosBanner = 'ca-app-pub-3940256099942544/2934735716';
//   static const String _testAndroidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
//   static const String _testIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
//   static const String _testAndroidRewarded = 'ca-app-pub-3940256099942544/5224354917';
//   static const String _testIosRewarded = 'ca-app-pub-3940256099942544/1712485313';
//   static const String _testAndroidAppOpen = 'ca-app-pub-3940256099942544/9257395921';
//   static const String _testIosAppOpen = 'ca-app-pub-3940256099942544/5662855259';
//
//   static String _resolveAdUnit({
//     required String androidLive,
//     required String iosLive,
//     required String androidTest,
//     required String iosTest,
//   }) {
//     if (kReleaseMode) {
//       if (Platform.isAndroid) return androidLive;
//       if (Platform.isIOS) return iosLive;
//       return '';
//     }
//     if (Platform.isAndroid) return androidLive.isNotEmpty ? androidLive : androidTest;
//     if (Platform.isIOS) return iosLive.isNotEmpty ? iosLive : iosTest;
//     return '';
//   }
//
//   static String get nativeVideoPauseOverlayId {
//     return _resolveAdUnit(
//       androidLive: _androidNativePauseId,
//       iosLive: _iosNativePauseId,
//       androidTest: _testAndroidNative,
//       iosTest: _testIosNative,
//     );
//   }
//
//   static String get bannerId {
//     return _resolveAdUnit(
//       androidLive: _androidBannerId,
//       iosLive: _iosBannerId,
//       androidTest: _testAndroidBanner,
//       iosTest: _testIosBanner,
//     );
//   }
//
//   static String get interstitialId {
//     return _resolveAdUnit(
//       androidLive: _androidInterstitialId,
//       iosLive: _iosInterstitialId,
//       androidTest: _testAndroidInterstitial,
//       iosTest: _testIosInterstitial,
//     );
//   }
//
//   static String get rewardedId {
//     return _resolveAdUnit(
//       androidLive: _androidRewardedId,
//       iosLive: _iosRewardedId,
//       androidTest: _testAndroidRewarded,
//       iosTest: _testIosRewarded,
//     );
//   }
//
//   static String get appOpenId {
//     return _resolveAdUnit(
//       androidLive: _androidAppOpenId,
//       iosLive: _iosAppOpenId,
//       androidTest: _testAndroidAppOpen,
//       iosTest: _testIosAppOpen,
//     );
//   }
//
//   static AppOpenAd? _appOpenAd;
//   static bool _isShowingAd = false;
//   static DateTime? _appOpenLoadTime;
//
//  static int _playCount =
//       0;
//
//   static void initAdFlow() {
//     _sessionStartTime = DateTime.now();
//     _preloadInterstitialIfNeeded();
//   }
//   static void playVideoWithAds(
//     BuildContext context,
//     VoidCallback startVideo,
//   ) async {
//     bool isOnline = await NetworkInfo.isConnected();
//     _playCount++;
//
//     if (isOnline) {
//       if (_playCount % 3 == 0) {
//         showInterstitialAd(startVideo);
//       } else {
//         startVideo();
//       }
//     } else {
//       // --- Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ¢â‚¬Å“Ãƒ Ã‚ÂªÃ‚Â«Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¨ Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¯ Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚Â«Ã¢â‚¬Â¹: Ãƒ Ã‚Â«Ã‚Â©Ãƒ Ã‚Â«Ã‚Â¦ Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ¢â‚¬Å¡Ãƒ Ã‚ÂªÃ¢â‚¬â€ Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‹â€ Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â° ---
//       _showOfflineTimerDialog(context, startVideo);
//     }
//   }
//
//   static void _showOfflineTimerDialog(
//     BuildContext context,
//     VoidCallback onFinish,
//   ) {
//     int timeLeft = 30;
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setDialogState) {
//           // Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‹â€ Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â° Ãƒ Ã‚ÂªÃ‚Â¶Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹
//           Timer.periodic(const Duration(seconds: 1), (timer) {
//             if (timeLeft > 0) {
//               if (context.mounted) setDialogState(() => timeLeft--);
//             } else {
//               timer.cancel();
//               if (context.mounted) {
//                 Navigator.pop(
//                   context,
//                 );
//                 onFinish();
//               }
//             }
//           });
//
//           return AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             title: const Text(
//               "Internet Required ÃƒÂ°Ã…Â¸Ã¢â‚¬Å“Ã‚Â¶",
//               style: TextStyle(color: Colors.red),
//             ),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   "To skip waiting and support this app, please turn on internet.",
//                 ),
//                 const SizedBox(height: 20),
//                 const Text("Otherwise, video starts in:"),
//                 Text(
//                   "$timeLeft",
//                   style: const TextStyle(
//                     fontSize: 40,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue,
//                   ),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("Cancel"),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   // --- 1. Standard Banner Ad Widget ---
//   static Widget bannerAdWidget({AdSize size = AdSize.banner}) {
//     return BannerAdWidget(size: size);
//   }
//
//   // --- 2. Adaptive Banner Ad Widget ---
//   static Widget adaptiveBannerWidget(BuildContext context) {
//     return FutureBuilder<AdSize?>(
//       future: AdSize.getAnchoredAdaptiveBannerAdSize(
//         Orientation.portrait,
//         MediaQuery.of(context).size.width.truncate(),
//       ),
//       builder: (context, snapshot) {
//         if (snapshot.hasData && snapshot.data != null) {
//           return BannerAdWidget(size: snapshot.data!);
//         } else {
//           return BannerAdWidget(size: AdSize.banner);
//         }
//       },
//     );
//   }
//
//   // --- 3. Promo Banner (Error Placeholder) ---
//   static Widget _buildPromoBanner(BuildContext context, AdSize size) {
//     return GestureDetector(
//       onTap: () {
//         // launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=your_id"));
//       },
//       child: Container(
//         width: size.width.toDouble(),
//         height: size.height.toDouble(),
//         margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.blue.shade700, Colors.blue.shade400],
//           ),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: const Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.star, color: Colors.white, size: 20),
//             SizedBox(width: 10),
//             Text(
//               "Enjoying the App? Rate us 5 Stars!",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 13,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // --- 4. Shimmer Placeholder ---
//   static Widget _buildShimmerPlaceholder(AdSize size) {
//     return Container(
//       width: size.width.toDouble(),
//       height: size.height.toDouble(),
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
//       decoration: BoxDecoration(
//         color: Colors.grey.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: const Center(
//         child: SizedBox(
//           width: 25,
//           height: 25,
//           child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
//         ),
//       ),
//     );
//   }
//
//   // --- 5. App Open Ad ---
//   static void loadAppOpenAd() async {
//     // Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¾ Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ…Â¸ Ãƒ Ã‚ÂªÃ…Â¡Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹
//     final List<ConnectivityResult> results = await Connectivity()
//         .checkConnectivity();
//     if (results.contains(ConnectivityResult.none)) return;
//
//     AppOpenAd.load(
//       adUnitId: appOpenId,
//       request: const AdRequest(),
//       adLoadCallback: AppOpenAdLoadCallback(
//         onAdLoaded: (ad) {
//           _appOpenAd = ad;
//           _appOpenLoadTime = DateTime.now();
//         },
//         onAdFailedToLoad: (error) => debugPrint('AppOpenAd failed: $error'),
//       ),
//     );
//   }
//
//   static DateTime? _lastAdShowTime;
//   static DateTime _sessionStartTime = DateTime.now();
//   static int _interstitialActionCount = 0;
//   static InterstitialAd? _cachedInterstitialAd;
//   static bool _isInterstitialLoading = false;
//   static bool isFullScreenAdShowing = false;
//   static bool _hasShownAppOpenAdThisSession = false;
//   static const int _interstitialEveryNAction = 4;
//   static const Duration _interstitialMinGap = Duration(seconds: 90);
//   static const Duration _interstitialSessionWarmup = Duration(seconds: 30);
//
//   static bool _isAdAvailable() {
//     if (_appOpenAd == null || _appOpenLoadTime == null) return false;
//     return DateTime.now().difference(_appOpenLoadTime!).inHours < 4;
//   }
//
//   static void showAppOpenAdIfAvailable() {
//     // Only show once per app session
//     if (_hasShownAppOpenAdThisSession) {
//       debugPrint("App Open Ad already shown this session. Skipping.");
//       return;
//     }
//
//     if (isFullScreenAdShowing) {
//       debugPrint(
//         "Ãƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚Â«Ã¢â€šÂ¬Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚ÂÃƒ Ã‚ÂªÃ‚Â¡ Ãƒ Ã‚ÂªÃ…Â¡Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã‚Â Ãƒ Ã‚ÂªÃ¢â‚¬ÂºÃƒ Ã‚Â«Ã¢â‚¬Â¡, App Open Ad Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã¢â€šÂ¬Ãƒ Ã‚ÂªÃ‚Âª Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â€šÂ¬.",
//       );
//       return;
//     }
//
//     if (!_isAdAvailable()) {
//       loadAppOpenAd();
//       return;
//     }
//
//     _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
//       onAdShowedFullScreenContent: (ad) {
//         _isShowingAd = true;
//         isFullScreenAdShowing = true;
//         _hasShownAppOpenAdThisSession = true; // mark as shown
//       },
//       onAdDismissedFullScreenContent: (ad) {
//         _isShowingAd = false;
//         isFullScreenAdShowing = false;
//         ad.dispose();
//         _appOpenAd = null;
//         loadAppOpenAd();
//       },
//       onAdFailedToShowFullScreenContent: (ad, error) {
//         _isShowingAd = false;
//         isFullScreenAdShowing = false;
//         ad.dispose();
//         _appOpenAd = null;
//         loadAppOpenAd();
//       },
//     );
//
//     _appOpenAd!.show();
//   }
//
//   // --- 6. Interstitial Ad ---
//   static bool _canShowInterstitialNow() {
//     if (interstitialId.isEmpty) return false;
//     if (isFullScreenAdShowing || _isShowingAd) return false;
//
//     if (DateTime.now().difference(_sessionStartTime) < _interstitialSessionWarmup) {
//       return false;
//     }
//     if (_lastAdShowTime != null &&
//         DateTime.now().difference(_lastAdShowTime!) < _interstitialMinGap) {
//       return false;
//     }
//     return true;
//   }
//
//   static void _preloadInterstitialIfNeeded() {
//     if (_cachedInterstitialAd != null || _isInterstitialLoading || interstitialId.isEmpty) {
//       return;
//     }
//     _isInterstitialLoading = true;
//     InterstitialAd.load(
//       adUnitId: interstitialId,
//       request: const AdRequest(),
//       adLoadCallback: InterstitialAdLoadCallback(
//         onAdLoaded: (ad) {
//           _cachedInterstitialAd?.dispose();
//           _cachedInterstitialAd = ad;
//           _isInterstitialLoading = false;
//         },
//         onAdFailedToLoad: (error) {
//           _isInterstitialLoading = false;
//           debugPrint("Interstitial preload failed: ${error.message}");
//         },
//       ),
//     );
//   }
//
//   static void showInterstitialAd(VoidCallback onAdDismissed) {
//     _interstitialActionCount++;
//     final bool shouldShowByCount =
//         _interstitialActionCount % _interstitialEveryNAction == 0;
//     if (!shouldShowByCount || !_canShowInterstitialNow()) {
//       _preloadInterstitialIfNeeded();
//       onAdDismissed();
//       return;
//     }
//
//     final ad = _cachedInterstitialAd;
//     _cachedInterstitialAd = null;
//     if (ad == null) {
//       _preloadInterstitialIfNeeded();
//       onAdDismissed();
//       return;
//     }
//
//     ad.fullScreenContentCallback = FullScreenContentCallback(
//       onAdShowedFullScreenContent: (ad) {
//         isFullScreenAdShowing = true;
//         _lastAdShowTime = DateTime.now();
//       },
//       onAdDismissedFullScreenContent: (ad) {
//         isFullScreenAdShowing = false;
//         ad.dispose();
//         _preloadInterstitialIfNeeded();
//         onAdDismissed();
//       },
//       onAdFailedToShowFullScreenContent: (ad, error) {
//         isFullScreenAdShowing = false;
//         ad.dispose();
//         _preloadInterstitialIfNeeded();
//         onAdDismissed();
//       },
//     );
//     ad.show();
//   }
//
//   // --- 7. Rewarded Ad ---
//   static void showRewardedAd(
//     BuildContext context,
//     // Context àª‰àª®à«‡àª°àªµà«‹ àªœàª°à«‚àª°à«€ àª›à«‡ Dialog àª¬àª‚àª§ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡
//     VoidCallback onRewardEarned, {
//     VoidCallback? errorFunction,
//   }) {
//     // à«§. àª²à«‹àª¡àª¿àª‚àª— àª¡àª¾àª¯àª²à«‹àª— àª¬àª¤àª¾àªµà«‹
//     DialogHelper.showAdLoadingDialog(context);
//
//     RewardedAd.load(
//       adUnitId: rewardedId,
//       request: const AdRequest(),
//       rewardedAdLoadCallback: RewardedAdLoadCallback(
//         onAdLoaded: (ad) {
//           // à«¨. àªàª¡ àª²à«‹àª¡ àª¥àªˆ àª—àªˆ, àª¹àªµà«‡ àª²à«‹àª¡àª° àª¬àª‚àª§ àª•àª°à«‹
//           DialogHelper.hideDialog(context);
//
//           ad.fullScreenContentCallback = FullScreenContentCallback(
//             onAdDismissedFullScreenContent: (ad) {
//               ad.dispose();
//             },
//             onAdFailedToShowFullScreenContent: (ad, error) {
//               ad.dispose();
//               if (errorFunction != null) errorFunction();
//             },
//           );
//
//           ad.show(
//             onUserEarnedReward: (ad, reward) {
//               onRewardEarned();
//             },
//           );
//         },
//         onAdFailedToLoad: (error) {
//           // à«©. àªàª¡ àª²à«‹àª¡ àª¨ àª¥àªˆ, àª²à«‹àª¡àª° àª¬àª‚àª§ àª•àª°à«‹ àª…àª¨à«‡ àªàª°àª° àª«àª‚àª•à«àª¶àª¨ àª•à«‹àª² àª•àª°à«‹
//           DialogHelper.hideDialog(context);
//           debugPrint("Rewarded Error: $error");
//
//           if (errorFunction != null) {
//             errorFunction(); // àª…àª¹à«€àª‚ () àª‰àª®à«‡àª°àªµà«àª‚ àªœàª°à«‚àª°à«€ àª›à«‡
//           }
//         },
//       ),
//     );
//   }
// }
//
// class BannerAdWidget extends StatefulWidget {
//   final AdSize size;
//
//   const BannerAdWidget({super.key, required this.size});
//
//   @override
//   State<BannerAdWidget> createState() => _BannerAdWidgetState();
// }
//
// class _BannerAdWidgetState extends State<BannerAdWidget> {
//   BannerAd? _bannerAd;
//   bool _isLoaded = false;
//   bool _isError = false;
//   late StreamSubscription _connectivitySubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadAd();
//
//     // Ãƒ Ã‚Â«Ã‚Â§. Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Â¢ Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚ÂÃƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â° Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ…Â¸ Ãƒ Ã‚ÂªÃ¢â‚¬ Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚ÂªÃ‚Â¤ Ãƒ Ã‚ÂªÃ…â€œ Ãƒ Ã‚ÂªÃ‚ÂÃƒ Ã‚ÂªÃ‚Â¡ Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¡ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚ÂªÃ‚Â¶Ãƒ Ã‚Â«Ã¢â‚¬Â¡
//     _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
//       results,
//     ) {
//       bool isOnline = !results.contains(ConnectivityResult.none);
//       if (isOnline && !_isLoaded) {
//         debugPrint("Network Restored: Loading Banner Ad...");
//         _loadAd();
//       }
//     });
//   }
//
//   // Ãƒ Ã‚Â«Ã‚Â¨. Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â¾ Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚Â«Ã¢â€šÂ¬Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚Â° Ãƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚ÂªÃ‚Â¦Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â¯ Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ‚Â«Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¡ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹
//   @override
//   void didUpdateWidget(covariant BannerAdWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.size != widget.size) {
//       _loadAd();
//     }
//   }
//
//   // Update your _loadAd method to this:
//   void _loadAd() async {
//     final adUnit = AdHelper.bannerId;
//     if (adUnit.isEmpty) {
//       if (mounted) {
//         setState(() {
//           _isLoaded = false;
//           _isError = false;
//         });
//       }
//       return;
//     }
//
//     final results = await Connectivity().checkConnectivity();
//     if (results.contains(ConnectivityResult.none)) {
//       if (mounted) setState(() => _isError = true);
//       return;
//     }
//
//     // 1. Dispose previous ad before creating a new one
//     await _bannerAd?.dispose();
//
//     // 2. Reset states so we don't try to build the AdWidget prematurely
//     if (mounted) {
//       setState(() {
//         _isLoaded = false;
//         _isError = false;
//       });
//     }
//
//     _bannerAd = BannerAd(
//       adUnitId: adUnit,
//       size: widget.size,
//       request: const AdRequest(),
//       listener: BannerAdListener(
//         onAdLoaded: (ad) {
//           debugPrint("Banner Ad Successfully Loaded!");
//           // 3. ONLY set _isLoaded to true here
//           if (mounted) {
//             setState(() {
//               _isLoaded = true;
//             });
//           }
//         },
//         onAdFailedToLoad: (ad, error) {
//           debugPrint("Banner Ad Failed: ${error.message}");
//           ad.dispose();
//           if (mounted) {
//             setState(() {
//               _isLoaded = false;
//               _isError = true;
//             });
//           }
//         },
//       ),
//     );
//
//     // 4. Start loading
//     _bannerAd!.load();
//   }
//
//   @override
//   void dispose() {
//     _connectivitySubscription.cancel();
//     _bannerAd?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // If there's an error, show the promo
//     if (_isError) return AdHelper._buildPromoBanner(context, widget.size);
//
//     // ONLY show AdWidget if _isLoaded is true AND _bannerAd is not null
//     if (_isLoaded && _bannerAd != null) {
//       return Container(
//         alignment: Alignment.center,
//         width: widget.size.width.toDouble(),
//         height: widget.size.height.toDouble(),
//         margin: const EdgeInsets.symmetric(vertical: 10),
//         child: AdWidget(ad: _bannerAd!),
//       );
//     }
//
//     // While loading (or if load hasn't finished), show shimmer
//     return AdHelper._buildShimmerPlaceholder(widget.size);
//   }
// }
//
// /// Centered **native template** ad over a dimmed scrim — for video pause (MX-style).
// /// Uses the same AdMob native pipeline on Android and iOS (no extra native code).
// class PauseVideoNativeAdLayer extends StatefulWidget {
//   final VoidCallback onDismiss;
//
//   const PauseVideoNativeAdLayer({super.key, required this.onDismiss});
//
//   @override
//   State<PauseVideoNativeAdLayer> createState() =>
//       _PauseVideoNativeAdLayerState();
// }
//
// class _PauseVideoNativeAdLayerState extends State<PauseVideoNativeAdLayer> {
//   NativeAd? _nativeAd;
//   bool _loaded = false;
//   bool _failed = false;
//   int _retryCount = 0;
//   static const int _maxRetryCount = 2;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
//   }
//
//   Future<void> _loadAd() async {
//     if (!mounted) return;
//     final id = AdHelper.nativeVideoPauseOverlayId;
//     if (id.isEmpty) {
//       setState(() => _failed = true);
//       return;
//     }
//
//     final results = await Connectivity().checkConnectivity();
//     if (results.contains(ConnectivityResult.none)) {
//       if (_retryCount < _maxRetryCount) {
//         _retryCount++;
//         Future.delayed(const Duration(milliseconds: 700), _loadAd);
//         return;
//       }
//       if (mounted) setState(() => _failed = true);
//       return;
//     }
//
//     await _nativeAd?.dispose();
//     _nativeAd = null;
//     if (!mounted) return;
//
//     final ad = NativeAd(
//       adUnitId: id,
//       listener: NativeAdListener(
//         onAdLoaded: (ad) {
//           if (mounted) {
//             setState(() {
//               _loaded = true;
//               _failed = false;
//               _retryCount = 0;
//             });
//           }
//         },
//         onAdFailedToLoad: (ad, error) {
//           debugPrint('Pause native ad failed: $error');
//           ad.dispose();
//           if (_retryCount < _maxRetryCount) {
//             _retryCount++;
//             Future.delayed(const Duration(milliseconds: 700), _loadAd);
//             return;
//           }
//           if (mounted) {
//             setState(() {
//               _failed = true;
//               _nativeAd = null;
//               _loaded = false;
//             });
//           }
//         },
//       ),
//       request: const AdRequest(),
//       nativeAdOptions: NativeAdOptions(
//         adChoicesPlacement: AdChoicesPlacement.topRightCorner,
//         // Prefer video creatives (or wide media) in pause overlay slot.
//         mediaAspectRatio: MediaAspectRatio.landscape,
//         videoOptions: VideoOptions(startMuted: true),
//       ),
//       nativeTemplateStyle: NativeTemplateStyle(
//         templateType: TemplateType.medium,
//         mainBackgroundColor: const Color(0xFFF8F8F8),
//         cornerRadius: 12,
//         callToActionTextStyle: NativeTemplateTextStyle(
//           textColor: Colors.white,
//           backgroundColor: const Color(0xFFFF6AA6),
//           style: NativeTemplateFontStyle.bold,
//           size: 13.5,
//         ),
//         primaryTextStyle: NativeTemplateTextStyle(
//           textColor: Colors.black87,
//           size: 15,
//           style: NativeTemplateFontStyle.bold,
//         ),
//         secondaryTextStyle: NativeTemplateTextStyle(
//           textColor: Colors.black54,
//           size: 12,
//         ),
//         tertiaryTextStyle: NativeTemplateTextStyle(
//           textColor: Colors.black45,
//           size: 11,
//         ),
//       ),
//     );
//
//     setState(() {
//       _nativeAd = ad;
//       _loaded = false;
//       _failed = false;
//     });
//
//     ad.load();
//   }
//
//   @override
//   void dispose() {
//     _nativeAd?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Positioned.fill(
//       child: Material(
//         type: MaterialType.transparency,
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             final pad = MediaQuery.paddingOf(context);
//             final isLandscape =
//                 constraints.maxWidth > constraints.maxHeight;
//             // Slightly narrower card in landscape reads better on wide screens.
//             final maxW = min(
//               constraints.maxWidth * 0.92,
//               isLandscape ? 360.0 : 400.0,
//             );
//
//             // Portrait: keep previous behaviour. Landscape: short side is tight;
//             // medium native template needs ~280–380 logical px height — old 55%
//             // of height clipped the ad. Prefer a taller slot; scroll if needed.
//             final double adH;
//             if (isLandscape) {
//               final safeH = constraints.maxHeight - pad.vertical;
//               adH = min(
//                 420.0,
//                 max(300.0, safeH * 0.86 - 32.0),
//               );
//             } else {
//               adH = min(constraints.maxHeight * 0.60, 420.0);
//             }
//
//             final cardColumn = Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Stack(
//                   clipBehavior: Clip.none,
//                   children: [
//                     Container(
//                       width: maxW,
//                       constraints: BoxConstraints(maxHeight: adH + 24),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(14),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.35),
//                             blurRadius: 22,
//                             spreadRadius: 1,
//                           ),
//                         ],
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(14),
//                         child: _failed
//                             ? SizedBox(
//                                 width: maxW,
//                                 height: 120,
//                                 child: Center(
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(16),
//                                     child: Text(
//                                       'Ad unavailable',
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         color: Colors.grey.shade700,
//                                         fontSize: 14,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               )
//                             : (!_loaded || _nativeAd == null)
//                                 ? SizedBox(
//                                     width: maxW,
//                                     height: adH.clamp(200.0, 380.0),
//                                     child: const Center(
//                                       child: CircularProgressIndicator(
//                                         color: Color(0xFFFF6AA6),
//                                       ),
//                                     ),
//                                   )
//                                 : SizedBox(
//                                     width: maxW,
//                                     height: adH,
//                                     child: AdWidget(ad: _nativeAd!),
//                                   ),
//                       ),
//                     ),
//                     Positioned(
//                       top: 8,
//                       right: 10,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 6,
//                           vertical: 2,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.shade700,
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: const Text(
//                           'Ad',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 10,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                     Positioned(
//                       top: -6,
//                       right: -6,
//                       child: Material(
//                         color: Colors.black54,
//                         shape: const CircleBorder(),
//                         child: InkWell(
//                           customBorder: const CircleBorder(),
//                           onTap: widget.onDismiss,
//                           child: const Padding(
//                             padding: EdgeInsets.all(6),
//                             child: Icon(
//                               Icons.close,
//                               color: Colors.white,
//                               size: 20,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 TextButton(
//                   onPressed: widget.onDismiss,
//                   child: Text(
//                     'Close',
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.9),
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             );
//
//             // Dimming only — taps pass through to the player GestureDetector except
//             // on the ad card (so empty screen toggles controls; ad stays tappable).
//             return Stack(
//               alignment: Alignment.center,
//               clipBehavior: Clip.none,
//               children: [
//                 Positioned.fill(
//                   child: IgnorePointer(
//                     ignoring: true,
//                     child: ColoredBox(
//                       color: Colors.black.withOpacity(0.48),
//                     ),
//                   ),
//                 ),
//                 Align(
//                   alignment: Alignment.center,
//                   child: Padding(
//                     padding: EdgeInsets.fromLTRB(
//                       8,
//                       max(8.0, pad.top + 4),
//                       8,
//                       max(8.0, pad.bottom + 4),
//                     ),
//                     child: ConstrainedBox(
//                       constraints: BoxConstraints(
//                         maxWidth: maxW + 48,
//                         maxHeight: max(
//                           120.0,
//                           constraints.maxHeight - pad.vertical - 16,
//                         ),
//                       ),
//                       child: ListView(
//                         shrinkWrap: true,
//                         physics: const ClampingScrollPhysics(),
//                         children: [
//                           Align(
//                             alignment: Alignment.center,
//                             child: cardColumn,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'dart:math' show max, min;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_imports.dart';
import 'connectivity_service.dart';
import 'hive_service.dart';

class AdHelper {
  static final Map<String, dynamic> _parsedRemoteConfig = {};

  static String? _getString(String key) {
    if (_parsedRemoteConfig.containsKey(key)) {
      return _parsedRemoteConfig[key]?.toString();
    }
    return _remoteConfig?.getString(key);
  }

  static bool? _getBool(String key) {
    if (_parsedRemoteConfig.containsKey(key)) {
      final val = _parsedRemoteConfig[key]?.toString().toLowerCase().trim();
      return val == 'true' || val == '1';
    }
    return _remoteConfig?.getBool(key);
  }

  static int? _getInt(String key) {
    if (_parsedRemoteConfig.containsKey(key)) {
      return int.tryParse(_parsedRemoteConfig[key]?.toString() ?? '');
    }
    return _remoteConfig?.getInt(key);
  }

  static void _parseJsonRemoteConfig() {
    if (_remoteConfig == null) return;
    // final jsonStr = _remoteConfig!.getString('remote_config_production');
    final jsonStr = _remoteConfig!.getString('remote_config_testing');
    if (jsonStr.isEmpty) return;
    try {
      final Map<String, dynamic> parsed = jsonDecode(jsonStr);
      if (parsed.containsKey('parameters')) {
        final params = parsed['parameters'] as Map<String, dynamic>;
        params.forEach((key, val) {
          if (val is Map && val.containsKey('defaultValue')) {
            final defVal = val['defaultValue'];
            if (defVal is Map && defVal.containsKey('value')) {
              _parsedRemoteConfig[key] = defVal['value'];
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error parsing nested remote_config JSON: $e');
    }
  }

  /// AdMob **native** test unit — replace with your production native ad unit IDs.
  /// See https://developers.google.com/admob/android/test-ads
  static String get nativeVideoPauseOverlayId {
    final val = Platform.isAndroid
        ? _getString('android_native_video_pause_overlay_id')
        : _getString('ios_native_video_pause_overlay_id');
    if (val != null && val.isNotEmpty) return val;
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/2247696110'
        : 'ca-app-pub-3940256099942544/3986624511';
  }

  static String get bannerId {
    final val = Platform.isAndroid
        ? _getString('android_banner_ad_unit_id')
        : _getString('ios_banner_ad_unit_id');
    if (val != null && val.isNotEmpty) return val;
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/6300978111'
        : 'ca-app-pub-3940256099942544/2934735716';
  }

  static String get interstitialId {
    final val = Platform.isAndroid
        ? _getString('android_interstitial_ad_unit_id')
        : _getString('ios_interstitial_ad_unit_id');
    if (val != null && val.isNotEmpty) return val;
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/1033173712'
        : 'ca-app-pub-3940256099942544/4411468910';
  }

  static String get rewardedId {
    final val = Platform.isAndroid
        ? _getString('android_rewarded_ad_unit_id')
        : _getString('ios_rewarded_ad_unit_id');
    if (val != null && val.isNotEmpty) return val;
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/5224354917'
        : 'ca-app-pub-3940256099942544/1712485313';
  }

  static String get appOpenId {
    final val = Platform.isAndroid
        ? _getString('android_app_open_ad_unit_id')
        : _getString('ios_app_open_ad_unit_id');
    if (val != null && val.isNotEmpty) return val;
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/9257395921'
        : 'ca-app-pub-3940256099942544/5662855259';
  }

  static FirebaseRemoteConfig? _remoteConfig;

  static InterstitialAd? _cachedInterstitialAd;
  static bool _isInterstitialLoading = false;
  static DateTime? _lastInterstitialShowTime;
  static int _interstitialClickCount = 0;
  static int _playerPlayCount = 0;

  static Future<void> initRemoteConfig() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(seconds: 10),
        ),
      );
      await _remoteConfig!.setDefaults(const {
        'show_ads_enabled': true,
        'android_native_video_pause_overlay_id': 'ca-app-pub-3940256099942544/2247696110',
        'ios_native_video_pause_overlay_id': 'ca-app-pub-3940256099942544/3986624511',
        'android_banner_ad_unit_id': 'ca-app-pub-3940256099942544/6300978111',
        'ios_banner_ad_unit_id': 'ca-app-pub-3940256099942544/2934735716',
        'android_interstitial_ad_unit_id': 'ca-app-pub-3940256099942544/1033173712',
        'ios_interstitial_ad_unit_id': 'ca-app-pub-3940256099942544/4411468910',
        'android_rewarded_ad_unit_id': 'ca-app-pub-3940256099942544/5224354917',
        'ios_rewarded_ad_unit_id': 'ca-app-pub-3940256099942544/1712485313',
        'android_app_open_ad_unit_id': 'ca-app-pub-3940256099942544/9257395921',
        'ios_app_open_ad_unit_id': 'ca-app-pub-3940256099942544/5662855259',
        'show_interstitial_on_home': true,
        'show_interstitial_on_player': true,
        'show_interstitial_on_language': true,
        'show_interstitial_on_playlist': true,
        'show_interstitial_on_favourite': true,
        'show_interstitial_on_folder': true,
        'show_interstitial_on_audio': true,
        'show_interstitial_on_video': true,
        'show_interstitial_on_settings': true,
        'interstitial_interval': 3,
        'offline_wait_timer_seconds': 30,
        'show_rewarded_on_player_count': 5,
      });
      
      final bool activated = await _remoteConfig!.fetchAndActivate();
      _parseJsonRemoteConfig();
      
      try {
        if (HiveService.settingsBox.isOpen) {
          HiveService.settingsBox.put('last_fetched_show_ads_enabled', showAdsEnabled);
        }
      } catch (_) {}

      debugPrint('======================================');
      debugPrint('Firebase Remote Config fetchAndActivate: $activated');
      debugPrint('Remote Config lastFetchStatus: ${_remoteConfig!.lastFetchStatus}');
      debugPrint('Remote Config show_ads_enabled = ${showAdsEnabled}');
      debugPrint('======================================');
      
      preloadInterstitial();
    } catch (e) {
      debugPrint('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');
      debugPrint('Remote Config init failed: $e');
      debugPrint('Please check your Firebase configuration and internet connection.');
      debugPrint('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');
    }
  }

  static void initAdFlow() {
    preloadInterstitial();
  }

  static bool get showAdsEnabled {
    bool cachedVal = true;
    try {
      if (HiveService.settingsBox.isOpen) {
        cachedVal = HiveService.settingsBox.get('last_fetched_show_ads_enabled', defaultValue: true);
      }
    } catch (_) {}

    final parsed = _getBool('show_ads_enabled');
    if (parsed != null) {
      try {
        if (HiveService.settingsBox.isOpen) {
          HiveService.settingsBox.put('last_fetched_show_ads_enabled', parsed);
        }
      } catch (_) {}
      return parsed;
    }

    if (_remoteConfig == null) return cachedVal;
    try {
      final val = _remoteConfig!.getValue('show_ads_enabled');
      final strVal = val.asString().toLowerCase().trim();
      bool resolvedVal = true;
      if (strVal == 'false' || strVal == '0') {
        resolvedVal = false;
      } else if (strVal == 'true' || strVal == '1') {
        resolvedVal = true;
      } else {
        resolvedVal = val.asBool();
      }
      
      try {
        if (HiveService.settingsBox.isOpen) {
          HiveService.settingsBox.put('last_fetched_show_ads_enabled', resolvedVal);
        }
      } catch (_) {}
      
      return resolvedVal;
    } catch (e) {
      debugPrint('Error getting show_ads_enabled: $e');
      return cachedVal;
    }
  }

  static bool get showInterstitialOnHome =>
      _getBool('show_interstitial_on_home') ?? true;

  static bool get showInterstitialOnPlayer =>
      _getBool('show_interstitial_on_player') ?? true;

  static bool get showInterstitialOnLanguage =>
      _getBool('show_interstitial_on_language') ?? true;

  static bool get showInterstitialOnPlaylist =>
      _getBool('show_interstitial_on_playlist') ?? true;

  static bool get showInterstitialOnFavourite =>
      _getBool('show_interstitial_on_favourite') ?? true;

  static bool get showInterstitialOnFolder =>
      _getBool('show_interstitial_on_folder') ?? true;

  static bool get showInterstitialOnAudio =>
      _getBool('show_interstitial_on_audio') ?? true;

  static bool get showInterstitialOnVideo =>
      _getBool('show_interstitial_on_video') ?? true;

  static bool get showInterstitialOnSettings =>
      _getBool('show_interstitial_on_settings') ?? true;

  static int get interstitialInterval =>
      _getInt('interstitial_interval') ?? 1;

  static int get showRewardedOnPlayerCount =>
      _getInt('show_rewarded_on_player_count') ?? 0;

  static int get offlineWaitTimerSeconds =>
      _getInt('offline_wait_timer_seconds') ?? 30;

  static String str(Object? value) => value?.toString() ?? '';

  static AppOpenAd? _appOpenAd;
  static bool _isShowingAd = false;
  static DateTime? _appOpenLoadTime;

 static int _playCount =
      0;
  static void playVideoWithAds(
    BuildContext context,
    VoidCallback startVideo,
  ) async {
    bool isOnline = await NetworkInfo.isConnected();
    _playCount++;

    if (isOnline) {
      if (_playCount % 3 == 0) {
        showInterstitialAd(context, startVideo, pageName: 'video');
      } else {
        startVideo();
      }
    } else {
      // --- Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ¢â‚¬Å“Ãƒ Ã‚ÂªÃ‚Â«Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¨ Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¯ Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚Â«Ã¢â‚¬Â¹: Ãƒ Ã‚Â«Ã‚Â©Ãƒ Ã‚Â«Ã‚Â¦ Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã‚Â Ãƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã‚Â Ãƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ¢â‚¬Å¡Ãƒ Ã‚ÂªÃ¢â‚¬â€  Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‹â€ Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â° ---
      _showOfflineTimerDialog(context, startVideo);
    }
  }

  static void _showOfflineTimerDialog(
    BuildContext context,
    VoidCallback onFinish,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OfflineTimerDialog(onFinish: onFinish),
    );
  }

  // --- 1. Standard Banner Ad Widget ---
  static Widget bannerAdWidget({AdSize size = AdSize.banner}) {
    return BannerAdWidget(size: size);
  }

  // --- 1.5 Native Ad Widget ---
  static Widget nativeAdWidget({double height = 320}) {
    return InlineNativeAd(height: height);
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
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
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
    if (!showAdsEnabled) return;
    // Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¾ Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ…Â¸ Ãƒ Ã‚ÂªÃ…Â¡Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹
    final List<ConnectivityResult> results = await Connectivity()
        .checkConnectivity();
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

  static bool isFullScreenAdShowing = false;
  static bool _hasShownAppOpenAdThisSession = false;

  static bool _isAdAvailable() {
    if (_appOpenAd == null || _appOpenLoadTime == null) return false;
    return DateTime.now().difference(_appOpenLoadTime!).inHours < 4;
  }

  static void showAppOpenAdIfAvailable() {
    if (!showAdsEnabled) return;
    // Only show once per app session
    if (_hasShownAppOpenAdThisSession) {
      debugPrint("App Open Ad already shown this session. Skipping.");
      return;
    }

    if (isFullScreenAdShowing) {
      debugPrint(
        "Ãƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚Â«Ã¢â€šÂ¬Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚Â Ãƒ Ã‚ÂªÃ‚Â¡ Ãƒ Ã‚ÂªÃ…Â¡Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã‚Â  Ãƒ Ã‚ÂªÃ¢â‚¬ÂºÃƒ Ã‚Â«Ã¢â‚¬Â¡, App Open Ad Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚Â«Ã‚Â Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã¢â€šÂ¬Ãƒ Ã‚ÂªÃ‚Âª Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â€šÂ¬.",
      );
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
  static void preloadInterstitial() {
    if (!showAdsEnabled) return;
    if (_cachedInterstitialAd != null || _isInterstitialLoading) return;
    final unitId = interstitialId;
    if (unitId.isEmpty) return;

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _cachedInterstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('Interstitial ad preloaded successfully.');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _cachedInterstitialAd = null;
          debugPrint('Failed to preload Interstitial ad: $error');
        },
      ),
    );
  }

  // --- 6. Interstitial Ad ---
  static void showInterstitialAd(
    BuildContext context,
    VoidCallback onAdDismissed, {
    String? pageName,
  }) {
    if (!showAdsEnabled) {
      onAdDismissed();
      return;
    }

    if (pageName != null) {
      bool isPageEnabled = true;
      switch (pageName) {
        case 'home':
          isPageEnabled = showInterstitialOnHome;
          break;
        case 'player':
          isPageEnabled = showInterstitialOnPlayer;
          break;
        case 'language':
          isPageEnabled = showInterstitialOnLanguage;
          break;
        case 'playlist':
          isPageEnabled = showInterstitialOnPlaylist;
          break;
        case 'favourite':
          isPageEnabled = showInterstitialOnFavourite;
          break;
        case 'folder':
          isPageEnabled = showInterstitialOnFolder;
          break;
        case 'audio':
          isPageEnabled = showInterstitialOnAudio;
          break;
        case 'video':
          isPageEnabled = showInterstitialOnVideo;
          break;
        case 'settings':
          isPageEnabled = showInterstitialOnSettings;
          break;
      }
      if (!isPageEnabled) {
        debugPrint('Interstitial ad is disabled for page: ' + pageName);
        onAdDismissed();
        return;
      }
    }

    // Special rewarded ad check for player screen
    if (pageName == 'player' || pageName == 'video' || pageName == 'home' || pageName == 'favourite' || pageName == 'playlist') {
      _playerPlayCount++;
      final rewardedCount = showRewardedOnPlayerCount;
      debugPrint('showInterstitialAd (pageName: $pageName): playCount incremented to $_playerPlayCount. Target rewardedCount = $rewardedCount');
      if (rewardedCount > 0 && _playerPlayCount % rewardedCount == 0) {
        debugPrint('Hit rewarded count! Showing rewarded ad instead of interstitial.');
        showRewardedAd(context, onAdDismissed, errorFunction: onAdDismissed);
        return;
      }
    }

    // Cooldown check (minimum 40s)
    final now = DateTime.now();
    if (_lastInterstitialShowTime != null) {
      final diff = now.difference(_lastInterstitialShowTime!);
      if (diff.inSeconds < 40) {
        debugPrint('Interstitial ad skipped due to cooldown: ' + str(diff.inSeconds) + 's < 40s');
        onAdDismissed();
        return;
      }
    }

    // Interval action count check
    _interstitialClickCount++;
    if (_interstitialClickCount % interstitialInterval != 0) {
      debugPrint('Interstitial ad skipped: click count ' + str(_interstitialClickCount) + ' is not a multiple of ' + str(interstitialInterval));
      onAdDismissed();
      return;
    }

    // Show cached ad if available
    final ad = _cachedInterstitialAd;
    _cachedInterstitialAd = null;
    if (ad == null) {
      debugPrint('Preloaded interstitial ad not available. Preloading for next time.');
      preloadInterstitial();
      onAdDismissed();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        isFullScreenAdShowing = true;
        _lastInterstitialShowTime = DateTime.now();
      },
      onAdDismissedFullScreenContent: (shownAd) {
        isFullScreenAdShowing = false;
        shownAd.dispose();
        preloadInterstitial();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        isFullScreenAdShowing = false;
        shownAd.dispose();
        preloadInterstitial();
        onAdDismissed();
      },
    );

    ad.show();
  }

  static void showRewardedAdWithCount(
    BuildContext context,
    VoidCallback onAdDismissed, {
    VoidCallback? errorFunction,
  }) {
    debugPrint('showRewardedAdWithCount: showAdsEnabled = $showAdsEnabled, playCount = $_playerPlayCount');
    if (!showAdsEnabled) {
      onAdDismissed();
      return;
    }
    _playerPlayCount++;
    final rewardedCount = showRewardedOnPlayerCount;
    debugPrint('showRewardedAdWithCount: playCount incremented to $_playerPlayCount. Target rewardedCount = $rewardedCount');
    if (rewardedCount > 0 && _playerPlayCount % rewardedCount == 0) {
      debugPrint('Hit rewarded count! Loading rewarded ad.');
      showRewardedAd(context, onAdDismissed, errorFunction: errorFunction ?? onAdDismissed);
    } else {
      debugPrint('No rewarded ad this time. Skipping.');
      onAdDismissed();
    }
  }

  // --- 7. Rewarded Ad ---
  static void showRewardedAd(
    BuildContext context,
    // Context àª‰àª®à«‡àª°àªµà«‹ àªœàª°à«‚àª°à«€ àª›à«‡ Dialog àª¬àª‚àª§ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡
    VoidCallback onRewardEarned, {
    VoidCallback? errorFunction,
  }) {
    if (!showAdsEnabled) {
      onRewardEarned();
      return;
    }
    // à«§. àª²à«‹àª¡àª¿àª‚àª— àª¡àª¾àª¯àª²à«‹àª— àª¬àª¤àª¾àªµà«‹
    DialogHelper.showAdLoadingDialog(context);

    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          // à«¨. àªàª¡ àª²à«‹àª¡ àª¥àªˆ àª—àªˆ, àª¹àªµà«‡ àª²à«‹àª¡àª° àª¬àª‚àª§ àª•àª°à«‹
          DialogHelper.hideDialog(context);

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (errorFunction != null) errorFunction();
            },
          );

          ad.show(
            onUserEarnedReward: (ad, reward) {
              onRewardEarned();
            },
          );
        },
        onAdFailedToLoad: (error) {
          // à«©. àªàª¡ àª²à«‹àª¡ àª¨ àª¥àªˆ, àª²à«‹àª¡àª° àª¬àª‚àª§ àª•àª°à«‹ àª…àª¨à«‡ àªàª°àª° àª«àª‚àª•à«àª¶àª¨ àª•à«‹àª² àª•àª°à«‹
          DialogHelper.hideDialog(context);
          debugPrint("Rewarded Error: $error");

          if (errorFunction != null) {
            errorFunction(); // àª…àª¹à«€àª‚ () àª‰àª®à«‡àª°àªµà«àª‚ àªœàª°à«‚àª°à«€ àª›à«‡
          }
        },
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

    // Ãƒ Ã‚Â«Ã‚Â§. Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Â¢ Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚ÂÃƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â° Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ…Â¸ Ãƒ Ã‚ÂªÃ¢â‚¬ Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã¢â‚¬Â¡ Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚ÂªÃ‚Â¤ Ãƒ Ã‚ÂªÃ…â€œ Ãƒ Ã‚ÂªÃ‚ÂÃƒ Ã‚ÂªÃ‚Â¡ Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¡ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚ÂªÃ‚Â¶Ãƒ Ã‚Â«Ã¢â‚¬Â¡
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      bool isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline && !_isLoaded) {
        debugPrint("Network Restored: Loading Banner Ad...");
        _loadAd();
      }
    });
  }

  @override
  void didUpdateWidget(covariant BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size != widget.size) {
      _loadAd();
    }
  }

  void _loadAd() async {
    if (!AdHelper.showAdsEnabled) {
      _isLoaded = false;
      _isError = false;
      final oldAd = _bannerAd;
      _bannerAd = null;
      oldAd?.dispose();
      return;
    }
    // Reset loaded state synchronously to prevent build race conditions
    _isLoaded = false;
    _isError = false;
    final oldAd = _bannerAd;
    _bannerAd = null;

    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      if (mounted) {
        setState(() {
          _isError = true;
        });
      }
      oldAd?.dispose();
      return;
    }

    // Dispose old ad asynchronously
    oldAd?.dispose();

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
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("Banner Ad Failed: ${error.message}");
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _isError = true;
            });
          }
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdHelper.showAdsEnabled) return const SizedBox.shrink();

    // If there's an error, show the promo
    if (_isError) return AdHelper._buildPromoBanner(context, widget.size);

    // ONLY show AdWidget if _isLoaded is true AND _bannerAd is not null
    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: widget.size.width.toDouble(),
        height: widget.size.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // While loading (or if load hasn't finished), show shimmer
    return AdHelper._buildShimmerPlaceholder(widget.size);
  }
}

/// Centered **native template** ad over a dimmed scrim — for video pause (MX-style).
/// Uses the same AdMob native pipeline on Android and iOS (no extra native code).
class PauseVideoNativeAdLayer extends StatefulWidget {
  final VoidCallback onDismiss;

  const PauseVideoNativeAdLayer({super.key, required this.onDismiss});

  @override
  State<PauseVideoNativeAdLayer> createState() =>
      _PauseVideoNativeAdLayerState();
}

class _PauseVideoNativeAdLayerState extends State<PauseVideoNativeAdLayer> {
  NativeAd? _nativeAd;
  bool _loaded = false;
  bool _failed = false;
  int _retryCount = 0;
  static const int _maxRetryCount = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
  }

  Future<void> _loadAd() async {
    if (!mounted) return;
    if (!AdHelper.showAdsEnabled) return;

    // Reset loaded state synchronously to prevent build race conditions during await
    _loaded = false;
    _failed = false;
    final oldAd = _nativeAd;
    _nativeAd = null;

    final id = AdHelper.nativeVideoPauseOverlayId;
    if (id.isEmpty) {
      if (mounted) setState(() => _failed = true);
      oldAd?.dispose();
      return;
    }

    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      if (_retryCount < _maxRetryCount) {
        _retryCount++;
        Future.delayed(const Duration(milliseconds: 700), _loadAd);
        oldAd?.dispose();
        return;
      }
      if (mounted) setState(() => _failed = true);
      oldAd?.dispose();
      return;
    }

    oldAd?.dispose();
    if (!mounted) return;

    final ad = NativeAd(
      adUnitId: id,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _loaded = true;
              _failed = false;
              _retryCount = 0;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Pause native ad failed: $error');
          ad.dispose();
          if (_retryCount < _maxRetryCount) {
            _retryCount++;
            Future.delayed(const Duration(milliseconds: 700), _loadAd);
            return;
          }
          if (mounted) {
            setState(() {
              _failed = true;
              _nativeAd = null;
              _loaded = false;
            });
          }
        },
      ),
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(
        adChoicesPlacement: AdChoicesPlacement.topRightCorner,
        mediaAspectRatio: MediaAspectRatio.landscape,
        videoOptions: VideoOptions(startMuted: true),
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: const Color(0xFFF8F8F8),
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFFFF6AA6),
          style: NativeTemplateFontStyle.bold,
          size: 13.5,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black87,
          size: 15,
          style: NativeTemplateFontStyle.bold,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black54,
          size: 12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black45,
          size: 11,
        ),
      ),
    );

    setState(() {
      _nativeAd = ad;
      _loaded = false;
      _failed = false;
    });

    ad.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdHelper.showAdsEnabled) return const SizedBox.shrink();
    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pad = MediaQuery.paddingOf(context);
            final isLandscape =
                constraints.maxWidth > constraints.maxHeight;
            // Slightly narrower card in landscape reads better on wide screens.
            final maxW = min(
              constraints.maxWidth * 0.92,
              isLandscape ? 360.0 : 400.0,
            );

            // Portrait: keep previous behaviour. Landscape: short side is tight;
            // medium native template needs ~280–380 logical px height — old 55%
            // of height clipped the ad. Prefer a taller slot; scroll if needed.
            final double adH;
            if (isLandscape) {
              final safeH = constraints.maxHeight - pad.vertical;
              adH = min(
                420.0,
                max(300.0, safeH * 0.86 - 32.0),
              );
            } else {
              adH = min(constraints.maxHeight * 0.60, 420.0);
            }

            final cardColumn = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: maxW,
                      constraints: BoxConstraints(maxHeight: adH + 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _failed
                            ? SizedBox(
                                width: maxW,
                                height: 120,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'Ad unavailable',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : (!_loaded || _nativeAd == null)
                                ? SizedBox(
                                    width: maxW,
                                    height: adH.clamp(200.0, 380.0),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFFF6AA6),
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    width: maxW,
                                    height: adH,
                                    child: AdWidget(ad: _nativeAd!),
                                  ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Ad',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: widget.onDismiss,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: widget.onDismiss,
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );

            // Dimming only — taps pass through to the player GestureDetector except
            // on the ad card (so empty screen toggles controls; ad stays tappable).
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: ColoredBox(
                      color: Colors.black.withOpacity(0.48),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      8,
                      max(8.0, pad.top + 4),
                      8,
                      max(8.0, pad.bottom + 4),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxW + 48,
                        maxHeight: max(
                          120.0,
                          constraints.maxHeight - pad.vertical - 16,
                        ),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: cardColumn,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class InlineNativeAd extends StatefulWidget {
  final double height;
  const InlineNativeAd({super.key, this.height = 320.0});

  @override
  State<InlineNativeAd> createState() => _InlineNativeAdState();
}

class _InlineNativeAdState extends State<InlineNativeAd> {
  NativeAd? _nativeAd;
  bool _loaded = false;
  bool _failed = false;
  int _retryCount = 0;
  static const int _maxRetryCount = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
  }

  Future<void> _loadAd() async {
    if (!mounted) return;
    if (!AdHelper.showAdsEnabled) return;

    _loaded = false;
    _failed = false;
    final oldAd = _nativeAd;
    _nativeAd = null;

    final id = AdHelper.nativeVideoPauseOverlayId;
    if (id.isEmpty) {
      if (mounted) setState(() => _failed = true);
      oldAd?.dispose();
      return;
    }

    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      if (_retryCount < _maxRetryCount) {
        _retryCount++;
        Future.delayed(const Duration(milliseconds: 700), _loadAd);
        oldAd?.dispose();
        return;
      }
      if (mounted) setState(() => _failed = true);
      oldAd?.dispose();
      return;
    }

    oldAd?.dispose();
    if (!mounted) return;

    final ad = NativeAd(
      adUnitId: id,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _loaded = true;
              _failed = false;
              _retryCount = 0;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Inline native ad failed: $error');
          ad.dispose();
          if (_retryCount < _maxRetryCount) {
            _retryCount++;
            Future.delayed(const Duration(milliseconds: 700), _loadAd);
            return;
          }
          if (mounted) {
            setState(() {
              _failed = true;
              _nativeAd = null;
              _loaded = false;
            });
          }
        },
      ),
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(
        adChoicesPlacement: AdChoicesPlacement.topRightCorner,
        mediaAspectRatio: MediaAspectRatio.landscape,
        videoOptions: VideoOptions(startMuted: true),
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white.withOpacity(0.08),
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFFFF6AA6),
          style: NativeTemplateFontStyle.bold,
          size: 13.5,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          size: 15,
          style: NativeTemplateFontStyle.bold,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          size: 12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white54,
          size: 11,
        ),
      ),
    );

    setState(() {
      _nativeAd = ad;
      _loaded = false;
      _failed = false;
    });

    ad.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdHelper.showAdsEnabled) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: widget.height,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _failed
            ? const Center(
                child: Text(
                  'Ad unavailable',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              )
            : (!_loaded || _nativeAd == null)
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF6AA6),
                    ),
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: AdWidget(ad: _nativeAd!),
                      ),
                      Positioned(
                        top: 8,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Ad',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _OfflineTimerDialog extends StatefulWidget {
  final VoidCallback onFinish;

  const _OfflineTimerDialog({required this.onFinish});

  @override
  State<_OfflineTimerDialog> createState() => _OfflineTimerDialogState();
}

class _OfflineTimerDialogState extends State<_OfflineTimerDialog> {
  late int _timeLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeLeft = AdHelper.offlineWaitTimerSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        if (mounted) {
          setState(() {
            _timeLeft--;
          });
        }
      } else {
        timer.cancel();
        if (mounted) {
          Navigator.pop(context);
          widget.onFinish();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: const Text(
        "Internet Required 📶",
        style: TextStyle(color: Colors.red),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "To skip waiting and support this app, please turn on internet.",
          ),
          const SizedBox(height: 20),
          const Text("Otherwise, video starts in:"),
          Text(
            "$_timeLeft",
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
