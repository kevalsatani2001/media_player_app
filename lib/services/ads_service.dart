import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // --- Ad Unit IDs (Replace with real IDs for production) ---
  static String get bannerId => 'ca-app-pub-3940256099942544/6300978111';
  static String get interstitialId => 'ca-app-pub-3940256099942544/1033173712';
  static String get rewardedId => 'ca-app-pub-3940256099942544/5224354917';
  static String get appOpenId => 'ca-app-pub-3940256099942544/9257395923';

  // --- 1. Banner Ad Widget ---
  static Widget bannerAdWidget({AdSize size = AdSize.banner}) {
    return StatefulBuilder(
      builder: (context, setState) {
        final BannerAd banner = BannerAd(
          adUnitId: bannerId,
          size: size,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdLoaded: (_) => setState(() {}),
            onAdFailedToLoad: (ad, error) {
              debugPrint("Banner Ad failed to load: $error");
              ad.dispose();
            },
          ),
        )..load();

        return Container(
          alignment: Alignment.center,
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(ad: banner),
        );
      },
    );
  }

  // --- 2. Adaptive Banner Ad ---
  static Widget adaptiveBannerWidget(BuildContext context) {
    return FutureBuilder<AdSize?>(
      future: AdSize.getAnchoredAdaptiveBannerAdSize(
        Orientation.portrait,
        MediaQuery.of(context).size.width.truncate(),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return bannerAdWidget(size: snapshot.data!);
        } else {
          // Fallback to standard banner while loading
          return bannerAdWidget(size: AdSize.banner);
        }
      },
    );
  }

  // --- 3. Interstitial Ad (Full Screen) ---
  static void showInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
          );
          ad.show();
        },
        onAdFailedToLoad: (error) => debugPrint("Interstitial Error: $error"),
      ),
    );
  }

  // --- 4. Rewarded Ad ---
  static void showRewardedAd(VoidCallback onRewardEarned) {
    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
          );
          ad.show(
            onUserEarnedReward: (ad, reward) {
              onRewardEarned();
            },
          );
        },
        onAdFailedToLoad: (error) => debugPrint("Rewarded Ad Error: $error"),
      ),
    );
  }

  // --- 5. App Open Ad ---
  static void showAppOpenAd() {
    AppOpenAd.load(
      adUnitId: appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
          );
          ad.show();
        },
        onAdFailedToLoad: (error) => debugPrint("App Open Ad Error: $error"),
      ),
    );
  }
}