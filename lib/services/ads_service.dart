import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // --- Ad Unit IDs (Android & iOS àª®àª¾àªŸà«‡ àª…àª²àª—) ---
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

  // àª…àª¹àª¿àª¯àª¾àª‚ àª¸àª¾àªšà«€ App Open Test ID àª¨àª¾àª–à«€ àª›à«‡ (Android & iOS)
  static String get appOpenId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/9257395921';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/5662855259';
    return '';
  }

  static AppOpenAd? _appOpenAd;
  static bool _isShowingAd = false;
  static DateTime? _appOpenLoadTime;

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
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade400]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              "Enjoying the App? Rate us 5 Stars!",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: SizedBox(
          width: 25, height: 25,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      ),
    );
  }

  // --- 5. App Open Ad ---
  static void loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AppOpenAd Loaded');
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) => debugPrint('AppOpenAd failed: $error'),
      ),
    );
  }

  static DateTime? _lastAdShowTime;

// àªàª¡ 4 àª•àª²àª¾àª•àª¥à«€ àªµàª§à« àªœà«‚àª¨à«€ àª¨ àª¹à«‹àªµà«€ àªœà«‹àªˆàª
  static bool _isAdAvailable() {
    if (_appOpenAd == null || _appOpenLoadTime == null) return false;
    return DateTime.now().difference(_appOpenLoadTime!).inHours < 4;
  }

  static void showAppOpenAdIfAvailable() {
    // à«§. àªœà«‹ àªàª¡ àª²à«‹àª¡ àª¨ àª¹à«‹àª¯, àª¤à«‹ àª²à«‹àª¡ àª•àª°à«‹ àª…àª¨à«‡ àªªàª¾àª›àª¾ àªœàª¾àª“
    if (!_isAdAvailable()) {
      debugPrint("Ad not available or expired, loading new one...");
      loadAppOpenAd();
      return;
    }

    // à«¨. àªœà«‹ àªàª¡ àª…àª¤à«àª¯àª¾àª°à«‡ àª¦à«‡àª–àª¾àªˆ àª°àª¹à«€ àª¹à«‹àª¯, àª¤à«‹ àª¬à«€àªœà«€ àª¨ àª¬àª¤àª¾àªµàªµà«€
    if (_isShowingAd) {
      debugPrint("Ad is already showing");
      return;
    }

    // à«©. àª²àª¿àª®àª¿àªŸ: àª›à«‡àª²à«àª²à«€ àªàª¡ àª¬àª¤àª¾àªµà«àª¯àª¾àª¨à«‡ àªœà«‹ à«§ àª®àª¿àª¨àª¿àªŸ (àª•à«‡ àª¤àª®à«‡ àª§àª¾àª°à«‹ àª¤à«‡àªŸàª²à«€) àª¥à«€ àª“àª›à«‹ àª¸àª®àª¯ àª¥àª¯à«‹ àª¹à«‹àª¯ àª¤à«‹ àª¸à«àª•à«€àªª àª•àª°à«‹
    // àª†àª¨àª¾àª¥à«€ àª¯à«àªàª° àªµàª¾àª°àª‚àªµàª¾àª° àªàªª àª®à«€àª¨à«€àª®àª¾àªˆàª àª•àª°à«‡ àª¤à«‹ àªàª¡àª¨à«‹ àª®àª¾àª°à«‹ àª¨àª¹à«€àª‚ àª¥àª¾àª¯
    if (_lastAdShowTime != null &&
        DateTime.now().difference(_lastAdShowTime!).inSeconds < 60) {
      debugPrint("Skip Ad: Too soon to show again");
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        _lastAdShowTime = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd(); // àª¬à«€àªœà«€ àªàª¡ àª¤à«ˆàª¯àª¾àª° àª°àª¾àª–à«‹
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
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
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onAdDismissed(); // àªàª¡ àª¬àª‚àª§ àª¥àª¾àª¯ àª¤à«àª¯àª¾àª°à«‡ àª¨à«‡àªµàª¿àª—à«‡àª¶àª¨ àª«àª‚àª•à«àª¶àª¨ àª•à«‹àª² àª¥àª¶à«‡
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onAdDismissed(); // àªœà«‹ àªàª¡ àª¨ àª¬àª¤àª¾àªµà«€ àª¶àª•à«‡ àª¤à«‹ àªªàª£ àªàªª àª…àªŸàª•à«‡ àª¨àª¹à«€àª‚
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint("Interstitial Error: $error");
          onAdDismissed(); // àª²à«‹àª¡ àª¨ àª¥àª¾àª¯ àª¤à«‹ àª¸à«€àª§à«àª‚ àª¨à«‡àªµàª¿àª—à«‡àª¶àª¨ àª•àª°à«€ àª¦à«‡àªµà«àª‚
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

// --- àª¬à«‡àª¨àª° àªàª¡ àªµàª¿àªœà«‡àªŸ ---
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

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerId,
      size: widget.size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _isError = true);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
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
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return AdHelper._buildShimmerPlaceholder(widget.size);
  }
}