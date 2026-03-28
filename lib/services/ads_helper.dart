import 'dart:io';
import 'remote_config_service.dart';

class AdHelper {
  /// Toggle: true = always use test ad IDs (ignore live ids from remote config)
  static const bool useTestAds = true;

  // Android Test Ad IDs
  static String get androidBannerAdUnitId =>
      'ca-app-pub-3940256099942544/6300978111';

  static String get androidInterstitialAdUnitId =>
      'ca-app-pub-3940256099942544/1033173712';

  static String get androidRewardedAdUnitId =>
      'ca-app-pub-3940256099942544/5224354917';

  static String get androidNativeAdUnitId =>
      'ca-app-pub-3940256099942544/2247696110';

  static String get androidAppOpenAdUnitId =>
      'ca-app-pub-3940256099942544/9257395921';

  // iOS Test Ad IDs
  static String get iosBannerAdUnitId =>
      'ca-app-pub-3940256099942544/2934735716';

  static String get iosInterstitialAdUnitId =>
      'ca-app-pub-3940256099942544/4411468910';

  static String get iosRewardedAdUnitId =>
      'ca-app-pub-3940256099942544/1712485313';

  static String get iosNativeAdUnitId =>
      'ca-app-pub-3940256099942544/3986624511';

  static String get iosAppOpenAdUnitId =>
      'ca-app-pub-3940256099942544/5575463023';

  static String get bannerAdUnitId {
    if (useTestAds) {
      return Platform.isAndroid ? androidBannerAdUnitId : iosBannerAdUnitId;
    }
    String remoteId = RemoteConfigService().getAdUnitId('banner');
    return remoteId.isNotEmpty
        ? remoteId
        : (Platform.isAndroid ? androidBannerAdUnitId : iosBannerAdUnitId);
  }

  static String get interstitialAdUnitId {
    if (useTestAds) {
      return Platform.isAndroid
          ? androidInterstitialAdUnitId
          : iosInterstitialAdUnitId;
    }
    String remoteId = RemoteConfigService().getAdUnitId('interstitial');
    return remoteId.isNotEmpty
        ? remoteId
        : (Platform.isAndroid
            ? androidInterstitialAdUnitId
            : iosInterstitialAdUnitId);
  }

  static String get nativeAdUnitId {
    if (useTestAds) {
      return Platform.isAndroid ? androidNativeAdUnitId : iosNativeAdUnitId;
    }
    String remoteId = RemoteConfigService().getAdUnitId('native_advanced');
    return remoteId.isNotEmpty
        ? remoteId
        : (Platform.isAndroid ? androidNativeAdUnitId : iosNativeAdUnitId);
  }

  static String get rewardedAdUnitId {
    if (useTestAds) {
      return Platform.isAndroid ? androidRewardedAdUnitId : iosRewardedAdUnitId;
    }
    String remoteId = RemoteConfigService().getAdUnitId('rewarded');
    return remoteId.isNotEmpty
        ? remoteId
        : (Platform.isAndroid ? androidRewardedAdUnitId : iosRewardedAdUnitId);
  }

  static String get appOpenAdUnitId {
    if (useTestAds) {
      return Platform.isAndroid ? androidAppOpenAdUnitId : iosAppOpenAdUnitId;
    }
    String remoteId = RemoteConfigService().getAdUnitId('app_open');
    return remoteId.isNotEmpty
        ? remoteId
        : (Platform.isAndroid ? androidAppOpenAdUnitId : iosAppOpenAdUnitId);
  }
}
