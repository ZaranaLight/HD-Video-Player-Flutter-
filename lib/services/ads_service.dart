import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'remote_config_service.dart';
import 'ads_helper.dart';
import 'session_service.dart';
import 'package:logger/logger.dart';

class AdsService {
  static final AdsService _instance = AdsService._internal();

  factory AdsService() => _instance;

  AdsService._internal();

  final RemoteConfigService _remoteConfigService = RemoteConfigService();
  final SessionService _sessionService = SessionService();
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd();
    loadAppOpenAd();
  }

  String getAdUnitId(String type, String fallback) {
    String remoteId = _remoteConfigService.getAdUnitId(type);
    return remoteId.isNotEmpty ? remoteId : fallback;
  }

  bool isAdEnabled(String type) {
    if (!_remoteConfigService.showAds) return false;
    return _remoteConfigService.isAdEnabled(type);
  }

  Future<bool> shouldShowAdByFrequency(String adType) async {
    final sessionCount = await _sessionService.getSessionCount();
    final frequency = _remoteConfigService.getFrequency(adType);
    
    // Override: Always show on the very first launch (Session 1)
    bool shouldShow = (sessionCount == 1) || (sessionCount % frequency) == 0 || frequency == 1;

    _logger.i('--- AD FREQUENCY CHECK ($adType) ---');
    _logger.i('Type: $adType');
    _logger.i('Session: $sessionCount');
    _logger.i('Frequency: $frequency sessions');
    _logger.i('Remaining: ${shouldShow ? 0 : (frequency - (sessionCount % frequency))} sessions');
    _logger.i('Should Show: $shouldShow');
    _logger.i('--------------------------------------');

    return shouldShow;
  }

  // Interstitial Ad
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  void loadInterstitialAd() {
    if (!isAdEnabled('interstitial')) return;

    InterstitialAd.load(
      adUnitId: getAdUnitId('interstitial', AdHelper.interstitialAdUnitId),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          _interstitialLoadAttempts++;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= 3) {
            loadInterstitialAd();
          }
        },
      ),
    );
  }

  void showInterstitialAd({
    required String trigger,
    required Function onAdClosed,
  }) async {
    final isTriggerOk =
        _remoteConfigService.isTriggerEnabled('interstitial', trigger);
    final shouldShow = await shouldShowAdByFrequency('InterstitialAd');

    _logger.i('--- INTERSTITIAL TRIGGER CHECK ---');
    _logger.i('Trigger: $trigger');
    _logger.i('Trigger Enabled: $isTriggerOk');
    _logger.i('-----------------------------------');

    if (!isTriggerOk || !shouldShow || _interstitialAd == null) {
      if (!isTriggerOk)
        _logger.w('Skipping Interstitial: Trigger "$trigger" not in list');
      if (!shouldShow) _logger.w('Skipping Interstitial: Frequency cap');
      onAdClosed();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitialAd();
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadInterstitialAd();
        onAdClosed();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // App Open Ad
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  void loadAppOpenAd() {
    if (!isAdEnabled('app_open')) return;

    AppOpenAd.load(
      adUnitId: getAdUnitId('app_open', AdHelper.appOpenAdUnitId),
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
        },
      ),
    );
  }

  void showAppOpenAdIfAvailable() async {
    final shouldShow = await shouldShowAdByFrequency('AppOpenAd');
    if (!shouldShow || _isShowingAd || _appOpenAd == null) {
      if (!shouldShow) _logger.w('Skipping App Open: Frequency cap');
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
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
}
