class RemoteConfigModel {
  final bool showAdsEnabled;
  final bool offDevMode;
  final String latestAppVersion;
  final String minRequiredAppVersion;
  final bool forceUpdateEnabled;
  final String appUpdateUrl;
  final String shareAppUrl;
  final String androidNativeVideoPauseOverlayId;
  final String iosNativeVideoPauseOverlayId;
  final String androidBannerAdUnitId;
  final String iosBannerAdUnitId;
  final String androidInterstitialAdUnitId;
  final String iosInterstitialAdUnitId;
  final String androidRewardedAdUnitId;
  final String iosRewardedAdUnitId;
  final String androidAppOpenAdUnitId;
  final String iosAppOpenAdUnitId;
  final int interstitialInterval;
  final int offlineWaitTimerSeconds;
  final int showRewardedOnPlayerCount;
  final bool showInterstitialOnHome;
  final bool showInterstitialOnPlayer;
  final bool showInterstitialOnLanguage;
  final bool showInterstitialOnPlaylist;
  final bool showInterstitialOnFavourite;
  final bool showInterstitialOnFolder;
  final bool showInterstitialOnAudio;
  final bool showInterstitialOnVideo;
  final bool showInterstitialOnSettings;

  RemoteConfigModel({
    required this.showAdsEnabled,
    required this.offDevMode,
    required this.latestAppVersion,
    required this.minRequiredAppVersion,
    required this.forceUpdateEnabled,
    required this.appUpdateUrl,
    required this.shareAppUrl,
    required this.androidNativeVideoPauseOverlayId,
    required this.iosNativeVideoPauseOverlayId,
    required this.androidBannerAdUnitId,
    required this.iosBannerAdUnitId,
    required this.androidInterstitialAdUnitId,
    required this.iosInterstitialAdUnitId,
    required this.androidRewardedAdUnitId,
    required this.iosRewardedAdUnitId,
    required this.androidAppOpenAdUnitId,
    required this.iosAppOpenAdUnitId,
    required this.interstitialInterval,
    required this.offlineWaitTimerSeconds,
    required this.showRewardedOnPlayerCount,
    required this.showInterstitialOnHome,
    required this.showInterstitialOnPlayer,
    required this.showInterstitialOnLanguage,
    required this.showInterstitialOnPlaylist,
    required this.showInterstitialOnFavourite,
    required this.showInterstitialOnFolder,
    required this.showInterstitialOnAudio,
    required this.showInterstitialOnVideo,
    required this.showInterstitialOnSettings,
  });

  factory RemoteConfigModel.fromDefaults() {
    return RemoteConfigModel(
      showAdsEnabled: false,
      offDevMode: false,
      latestAppVersion: '1.1.0',
      minRequiredAppVersion: '1.0.0',
      forceUpdateEnabled: false,
      appUpdateUrl: 'https://play.google.com/store/apps/details?id=com.nova.media.vision',
      shareAppUrl: 'https://play.google.com/store/apps/details?id=com.nova.media.vision',
      androidNativeVideoPauseOverlayId: 'ca-app-pub-3940256099942544/2247696110',
      iosNativeVideoPauseOverlayId: 'ca-app-pub-3940256099942544/3986624511',
      androidBannerAdUnitId: 'ca-app-pub-3940256099942544/6300978111',
      iosBannerAdUnitId: 'ca-app-pub-3940256099942544/2934735716',
      androidInterstitialAdUnitId: 'ca-app-pub-3940256099942544/1033173712',
      iosInterstitialAdUnitId: 'ca-app-pub-3940256099942544/4411468910',
      androidRewardedAdUnitId: 'ca-app-pub-3940256099942544/5224354917',
      iosRewardedAdUnitId: 'ca-app-pub-3940256099942544/1712485313',
      androidAppOpenAdUnitId: 'ca-app-pub-3940256099942544/9257395921',
      iosAppOpenAdUnitId: 'ca-app-pub-3940256099942544/5662855259',
      interstitialInterval: 3,
      offlineWaitTimerSeconds: 30,
      showRewardedOnPlayerCount: 5,
      showInterstitialOnHome: true,
      showInterstitialOnPlayer: true,
      showInterstitialOnLanguage: true,
      showInterstitialOnPlaylist: true,
      showInterstitialOnFavourite: true,
      showInterstitialOnFolder: true,
      showInterstitialOnAudio: true,
      showInterstitialOnVideo: true,
      showInterstitialOnSettings: true,
    );
  }

  factory RemoteConfigModel.fromJson(Map<String, dynamic> json) {
    // Determine parameters map. It could be under "parameters" or direct.
    final Map<String, dynamic> params = (json.containsKey('parameters') && json['parameters'] is Map<String, dynamic>)
        ? json['parameters'] as Map<String, dynamic>
        : json;

    // Helper function to extract value from defaultValue or direct value
    dynamic getVal(String key, dynamic fallback) {
      if (params.containsKey(key)) {
        final item = params[key];
        if (item is Map && item.containsKey('defaultValue')) {
          final defVal = item['defaultValue'];
          if (defVal is Map && defVal.containsKey('value')) {
            return defVal['value'];
          }
        } else if (item is Map && item.containsKey('value')) {
          return item['value'];
        } else {
          return item;
        }
      }
      return fallback;
    }

    bool toBool(dynamic val, bool fallback) {
      if (val == null) return fallback;
      if (val is bool) return val;
      final s = val.toString().toLowerCase().trim();
      return s == 'true' || s == '1';
    }

    int toInt(dynamic val, int fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    String toStringVal(dynamic val, String fallback) {
      if (val == null) return fallback;
      return val.toString();
    }

    return RemoteConfigModel(
      showAdsEnabled: toBool(getVal('show_ads_enabled', null), false),
      offDevMode: toBool(getVal('off_dev_mode', null), false),
      latestAppVersion: toStringVal(getVal('latest_app_version', null), '1.1.0'),
      minRequiredAppVersion: toStringVal(getVal('min_required_app_version', null), '1.0.0'),
      forceUpdateEnabled: toBool(getVal('force_update_enabled', null), false),
      appUpdateUrl: toStringVal(getVal('app_update_url', null), 'https://play.google.com/store/apps/details?id=com.nova.media.vision'),
      shareAppUrl: toStringVal(getVal('share_app_url', null), 'https://play.google.com/store/apps/details?id=com.nova.media.vision'),
      androidNativeVideoPauseOverlayId: toStringVal(getVal('android_native_video_pause_overlay_id', null), 'ca-app-pub-3940256099942544/2247696110'),
      iosNativeVideoPauseOverlayId: toStringVal(getVal('ios_native_video_pause_overlay_id', null), 'ca-app-pub-3940256099942544/3986624511'),
      androidBannerAdUnitId: toStringVal(getVal('android_banner_ad_unit_id', null), 'ca-app-pub-3940256099942544/6300978111'),
      iosBannerAdUnitId: toStringVal(getVal('ios_banner_ad_unit_id', null), 'ca-app-pub-3940256099942544/2934735716'),
      androidInterstitialAdUnitId: toStringVal(getVal('android_interstitial_ad_unit_id', null), 'ca-app-pub-3940256099942544/1033173712'),
      iosInterstitialAdUnitId: toStringVal(getVal('ios_interstitial_ad_unit_id', null), 'ca-app-pub-3940256099942544/4411468910'),
      androidRewardedAdUnitId: toStringVal(getVal('android_rewarded_ad_unit_id', null), 'ca-app-pub-3940256099942544/5224354917'),
      iosRewardedAdUnitId: toStringVal(getVal('ios_rewarded_ad_unit_id', null), 'ca-app-pub-3940256099942544/1712485313'),
      androidAppOpenAdUnitId: toStringVal(getVal('android_app_open_ad_unit_id', null), 'ca-app-pub-3940256099942544/9257395921'),
      iosAppOpenAdUnitId: toStringVal(getVal('ios_app_open_ad_unit_id', null), 'ca-app-pub-3940256099942544/5662855259'),
      interstitialInterval: toInt(getVal('interstitial_interval', null), 3),
      offlineWaitTimerSeconds: toInt(getVal('offline_wait_timer_seconds', null), 30),
      showRewardedOnPlayerCount: toInt(getVal('show_rewarded_on_player_count', null), 5),
      showInterstitialOnHome: toBool(getVal('show_interstitial_on_home', null), true),
      showInterstitialOnPlayer: toBool(getVal('show_interstitial_on_player', null), true),
      showInterstitialOnLanguage: toBool(getVal('show_interstitial_on_language', null), true),
      showInterstitialOnPlaylist: toBool(getVal('show_interstitial_on_playlist', null), true),
      showInterstitialOnFavourite: toBool(getVal('show_interstitial_on_favourite', null), true),
      showInterstitialOnFolder: toBool(getVal('show_interstitial_on_folder', null), true),
      showInterstitialOnAudio: toBool(getVal('show_interstitial_on_audio', null), true),
      showInterstitialOnVideo: toBool(getVal('show_interstitial_on_video', null), true),
      showInterstitialOnSettings: toBool(getVal('show_interstitial_on_settings', null), true),
    );
  }
}
