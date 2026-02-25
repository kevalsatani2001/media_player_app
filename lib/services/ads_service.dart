import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdHelper {
  // Test IDs (લાઈવ કરતી વખતે તમારા રિયલ આઈડી અહીં નાખવા)
  static String get bannerId => 'ca-app-pub-3940256099942544/6300978111';
  static String get interstitialId => 'ca-app-pub-3940256099942544/1033173712';
  static String get rewardedId => 'ca-app-pub-3940256099942544/5224354917';
  static String get appOpenId => 'ca-app-pub-3940256099942544/9257395923';

  // --- ૧. Banner Ad (વિજેટ તરીકે વાપરવા) ---
  static Widget bannerAdWidget({AdSize size = AdSize.banner}) {
    return StatefulBuilder(builder: (context, setState) {
      BannerAd banner = BannerAd(
        adUnitId: bannerId,
        size: size, // પાસ કરેલી સાઈઝ અહીં વપરાશે
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => setState(() {}),
          onAdFailedToLoad: (ad, error) {
            debugPrint("Ad Load Error: $error");
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
    });
  }


  static Widget adaptiveBannerWidget(BuildContext context) {
    return FutureBuilder<AdSize?>(
      // આ મેથડ Future રિટર્ન કરે છે એટલે આપણે તેને 'future' માં નાખીશું
      future: AdSize.getAnchoredAdaptiveBannerAdSize(
        Orientation.portrait,
        MediaQuery.of(context).size.width.truncate(),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // જો સાઈઝ મળી જાય, તો તે સાઈઝ સાથે બેનર બતાવો
          return bannerAdWidget(size: snapshot.data!);
        } else {
          // જ્યાં સુધી સાઈઝ લોડ થાય, ત્યાં સુધી સ્ટાન્ડર્ડ બેનર બતાવો અથવા ખાલી જગ્યા
          return bannerAdWidget(size: AdSize.banner);
        }
      },
    );
  }

  // --- ૨. Interstitial Ad (આખા પેજની એડ) ---
  static void showInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => ad.show(),
        onAdFailedToLoad: (error) => debugPrint("Interstitial Error: $error"),
      ),
    );
  }

  // --- ૩. Rewarded Ad (વિડિયો એડ - જેમાં કંઈક રિવોર્ડ આપવાનો હોય) ---
  static void showRewardedAd(Function onRewardEarned) {
    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(onUserEarnedReward: (ad, reward) {
            onRewardEarned(); // યુઝરને રિવોર્ડ આપવા માટે આ ફંક્શન કોલ થશે
          });
        },
        onAdFailedToLoad: (error) => debugPrint("Rewarded Error: $error"),
      ),
    );
  }

  // --- ૪. App Open Ad (એપ ઓપન થાય ત્યારે) ---
  static void showAppOpenAd() {
    AppOpenAd.load(
      adUnitId: appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("AppOpenAd loaded successfully");
          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint("AppOpenAd failed to load: $error");
        },
      ),
      // અહીંથી orientation પેરામીટર કાઢી નાખ્યો છે
    );
  }
}