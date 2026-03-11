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