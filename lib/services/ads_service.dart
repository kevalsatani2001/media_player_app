import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdHelper {
  // Test IDs (લાઈવ કરતી વખતે તમારા રિયલ આઈડી અહીં નાખવા)
  static String get bannerId => 'ca-app-pub-3940256099942544/6300978111';
  static String get interstitialId => 'ca-app-pub-3940256099942544/1033173712';
  static String get rewardedId => 'ca-app-pub-3940256099942544/5224354917';
  static String get appOpenId => 'ca-app-pub-3940256099942544/9257395923';

  // --- ૧. Banner Ad (વિજેટ તરીકે વાપરવા) ---
  static Widget bannerAdWidget() {
    return StatefulBuilder(builder: (context, setState) {
      BannerAd banner = BannerAd(
        adUnitId: bannerId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => setState(() {}),
          onAdFailedToLoad: (ad, error) => ad.dispose(),
        ),
      )..load();
      return SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      );
    });
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
/*
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/> ```

૨. **iOS (Info.plist):**
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
 */

/*
૨. કેવી રીતે વાપરવું? (સૌથી સરળ રીત)
તમારે હવે માત્ર નીચેની લાઇનો જ તમારા પેજમાં લખવાની છે:

A. પેજમાં ક્યાંય પણ બેનર બતાવવા:
Dart
Column(
  children: [
    Expanded(child: YourUIContent()),
    AdHelper.bannerAdWidget(), // બસ આટલું જ!
  ],
)
B. બટન ક્લિક પર આખા પેજની એડ બતાવવા:
Dart
onTap: () {
  AdHelper.showInterstitialAd();
  // પછી નેક્સ્ટ પેજ પર જવાનું લોજિક
}
C. રિવોર્ડ એડ (દા.ત. કોઈ પ્રીમિયમ ફીચર ખોલવા):
Dart
onTap: () {
  AdHelper.showRewardedAd(() {
    print("User earned 10 coins!"); // યુઝરને અહીં પોઈન્ટ્સ આપો
  });
}
D. એપ ઓપન થાય ત્યારે (Splash Screen પર):
તમારા Splash Screen ના initState માં:

Dart
@override
void initState() {
  super.initState();
  AdHelper.showAppOpenAd();
}
 */