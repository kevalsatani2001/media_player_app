import 'package:connectivity_plus/connectivity_plus.dart';
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

  // AdHelper Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ¢â‚¬Â¦Ãƒ Ã‚ÂªÃ¢â‚¬Å¡Ãƒ Ã‚ÂªÃ‚Â¦Ãƒ Ã‚ÂªÃ‚Â° Ãƒ Ã‚ÂªÃ¢â‚¬  Ãƒ Ã‚ÂªÃ¢â‚¬Â°Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹:

  static int _playCount =
      0; // Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ¢â‚¬â€Ãƒ Ã‚ÂªÃ‚Â£Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚ÂªÃ‚Â¾ Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚Â«Ã¢â‚¬Â¡

  static void playVideoWithAds(
    BuildContext context,
    VoidCallback startVideo,
  ) async {
    bool isOnline = await NetworkInfo.isConnected();
    _playCount++;

    if (isOnline) {
      // --- Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ¢â‚¬Å“Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¨ Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¯ Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚Â«Ã¢â‚¬Â¹: Ãƒ Ã‚ÂªÃ‚Â¦Ãƒ Ã‚ÂªÃ‚Â° Ãƒ Ã‚Â«Ã‚Â© Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â Interstitial Ãƒ Ã‚ÂªÃ‚ÂÃƒ Ã‚ÂªÃ‚Â¡ ---
      if (_playCount % 3 == 0) {
        showInterstitialAd(startVideo);
      } else {
        startVideo();
      }
    } else {
      // --- Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ¢â‚¬Å“Ãƒ Ã‚ÂªÃ‚Â«Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â¨ Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¯ Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚Â«Ã¢â‚¬Â¹: Ãƒ Ã‚Â«Ã‚Â©Ãƒ Ã‚Â«Ã‚Â¦ Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ¢â‚¬Å¡Ãƒ Ã‚ÂªÃ¢â‚¬â€ Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‹â€ Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â° ---
      _showOfflineTimerDialog(context, startVideo);
    }
  }

  static void _showOfflineTimerDialog(
    BuildContext context,
    VoidCallback onFinish,
  ) {
    int timeLeft = 30;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‹â€ Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚ÂªÃ‚Â° Ãƒ Ã‚ÂªÃ‚Â¶Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹
          Timer.periodic(const Duration(seconds: 1), (timer) {
            if (timeLeft > 0) {
              if (context.mounted) setDialogState(() => timeLeft--);
            } else {
              timer.cancel();
              if (context.mounted) {
                Navigator.pop(
                  context,
                ); // Ãƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ¢â‚¬â€ Ãƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚ÂªÃ¢â‚¬Å¡Ãƒ Ã‚ÂªÃ‚Â§ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹
                onFinish(); // Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â¡Ãƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ‚Â¶Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹
              }
            }
          });

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              "Internet Required ÃƒÂ°Ã…Â¸Ã¢â‚¬Å“Ã‚Â¶",
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
                  "$timeLeft",
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
      // Ã Âªâ€¦Ã ÂªÂ¹Ã Â«â‚¬Ã Âªâ€š Ã ÂªÂµÃ ÂªÂ¿Ã ÂªÂ¡Ã Â«ÂÃ ÂªÂ¥Ã ÂªÂ®Ã ÂªÂ¾Ã Âªâ€šÃ ÂªÂ¥Ã Â«â‚¬ Ã ÂªÂ®Ã ÂªÂ¾Ã ÂªÂ°Ã Â«ÂÃ ÂªÅ“Ã ÂªÂ¿Ã ÂªÂ¨ Ã ÂªÂ¬Ã ÂªÂ¾Ã ÂªÂ¦ Ã Âªâ€¢Ã ÂªÂ°Ã ÂªÂµÃ ÂªÂ¾Ã ÂªÂ¨Ã Â«â‚¬ Ã ÂªÅ“Ã ÂªÂ°Ã Â«â€šÃ ÂªÂ° Ã ÂªÂ¨Ã ÂªÂ¥Ã Â«â‚¬, AdSize Ã ÂªÂªÃ Â«â€¹Ã ÂªÂ¤Ã Â«â€¡ Ã ÂªÂÃ ÂªÂ¡Ã ÂªÅ“Ã ÂªÂ¸Ã Â«ÂÃ ÂªÅ¸ Ã Âªâ€¢Ã ÂªÂ°Ã ÂªÂ¶Ã Â«â€¡
      future: AdSize.getAnchoredAdaptiveBannerAdSize(
        Orientation.portrait,
        MediaQuery.of(context).size.width.truncate(),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return BannerAdWidget(size: snapshot.data!);
        } else {
          // Ã ÂªÅ“Ã Â«ÂÃ ÂªÂ¯Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â€¡ Ã ÂªÂ¡Ã Â«â€¡Ã ÂªÅ¸Ã ÂªÂ¾ Ã ÂªÂ²Ã Â«â€¹Ã ÂªÂ¡ Ã ÂªÂ¥Ã ÂªÂ¤Ã Â«â€¹ Ã ÂªÂ¹Ã Â«â€¹Ã ÂªÂ¯ Ã ÂªÂ¤Ã Â«ÂÃ ÂªÂ¯Ã ÂªÂ¾Ã ÂªÂ°Ã Â«â€¡ Ã ÂªÂ¸Ã Â«â€¡Ã ÂªÂ« Ã ÂªÂ¸Ã ÂªÂ¾Ã ÂªË†Ã ÂªÂ Ã Âªâ€ Ã ÂªÂªÃ Â«â€¹
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
      debugPrint(
        "Ãƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚Â«Ã¢â€šÂ¬Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚ÂÃƒ Ã‚ÂªÃ‚Â¡ Ãƒ Ã‚ÂªÃ…Â¡Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã‚Â Ãƒ Ã‚ÂªÃ¢â‚¬ÂºÃƒ Ã‚Â«Ã¢â‚¬Â¡, App Open Ad Ãƒ Ã‚ÂªÃ‚Â¸Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚Â«Ã¢â€šÂ¬Ãƒ Ã‚ÂªÃ‚Âª Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â€šÂ¬.",
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
  static void showInterstitialAd(VoidCallback onAdDismissed) {
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              isFullScreenAdShowing =
                  true; // Ãƒ Ã‚ÂªÃ¢â‚¬Â¦Ãƒ Ã‚ÂªÃ¢â‚¬â€Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡: Ãƒ Ã‚ÂªÃ¢â‚¬Â¦Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â€šÂ¬Ãƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã‚Â Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡
            },
            onAdDismissedFullScreenContent: (ad) {
              isFullScreenAdShowing =
                  false; // Ãƒ Ã‚ÂªÃ¢â‚¬Â¦Ãƒ Ã‚ÂªÃ¢â‚¬â€Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¯Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡: Ãƒ Ã‚ÂªÃ¢â‚¬Â¦Ãƒ Ã‚ÂªÃ‚Â¹Ãƒ Ã‚Â«Ã¢â€šÂ¬Ãƒ Ã‚ÂªÃ¢â‚¬Å¡ Ãƒ Ã‚ÂªÃ‚Â«Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ‚Â¸ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚Â«Ã‚ÂÃƒ Ã‚ÂªÃ¢â‚¬Å¡
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
  static void showRewardedAd(
    BuildContext context,
    // Context àª‰àª®à«‡àª°àªµà«‹ àªœàª°à«‚àª°à«€ àª›à«‡ Dialog àª¬àª‚àª§ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡
    VoidCallback onRewardEarned, {
    VoidCallback? errorFunction,
  }) {
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

  // Ãƒ Ã‚Â«Ã‚Â¨. Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ‚ÂµÃƒ Ã‚ÂªÃ‚Â¿Ãƒ Ã‚ÂªÃ…â€œÃƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚Â¨Ãƒ Ã‚ÂªÃ‚Â¾ Ãƒ Ã‚ÂªÃ‚ÂªÃƒ Ã‚Â«Ã¢â‚¬Â¡Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â®Ãƒ Ã‚Â«Ã¢â€šÂ¬Ãƒ Ã‚ÂªÃ…Â¸Ãƒ Ã‚ÂªÃ‚Â° Ãƒ Ã‚ÂªÃ‚Â¬Ãƒ Ã‚ÂªÃ‚Â¦Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚ÂªÃ‚Â¾Ãƒ Ã‚ÂªÃ‚Â¯ Ãƒ Ã‚ÂªÃ‚Â¤Ãƒ Ã‚Â«Ã¢â‚¬Â¹ Ãƒ Ã‚ÂªÃ‚Â«Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â€šÂ¬ Ãƒ Ã‚ÂªÃ‚Â²Ãƒ Ã‚Â«Ã¢â‚¬Â¹Ãƒ Ã‚ÂªÃ‚Â¡ Ãƒ Ã‚ÂªÃ¢â‚¬Â¢Ãƒ Ã‚ÂªÃ‚Â°Ãƒ Ã‚Â«Ã¢â‚¬Â¹
  @override
  void didUpdateWidget(covariant BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size != widget.size) {
      _loadAd();
    }
  }

  // Update your _loadAd method to this:
  void _loadAd() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      if (mounted) setState(() => _isError = true);
      return;
    }

    // 1. Dispose previous ad before creating a new one
    await _bannerAd?.dispose();

    // 2. Reset states so we don't try to build the AdWidget prematurely
    if (mounted) {
      setState(() {
        _isLoaded = false;
        _isError = false;
      });
    }

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerId,
      size: widget.size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint("Banner Ad Successfully Loaded!");
          // 3. ONLY set _isLoaded to true here
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

    // 4. Start loading
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
