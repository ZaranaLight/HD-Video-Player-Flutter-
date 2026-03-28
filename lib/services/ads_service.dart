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
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd();
    loadAppOpenAd();
  }

  bool isAdEnabled(String type) {
    if (!_remoteConfigService.showAds) return false;
    return _remoteConfigService.isAdEnabled(type);
  }

  Future<bool> shouldShowAdByFrequency(String adType) async {
    final sessionCount = await _sessionService.getSessionCount();
    final frequency = _remoteConfigService.getFrequency(adType);
    
    // Always show on first session OR if session matches frequency
    bool shouldShow = (sessionCount == 1) || (sessionCount % frequency) == 0 || frequency == 1;

    _logger.i('--- AD FREQUENCY CHECK ($adType) ---');
    _logger.i('Session: $sessionCount, Frequency: $frequency, Should Show: $shouldShow');

    return shouldShow;
  }

  // Interstitial Ad
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  int _interstitialLoadAttempts = 0;

  void loadInterstitialAd() {
    if (!isAdEnabled('interstitial') || _isInterstitialLoading || _interstitialAd != null) return;

    _isInterstitialLoading = true;
    String adUnitId = AdHelper.interstitialAdUnitId;
    _logger.i('Loading Interstitial Ad with ID: $adUnitId');

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _logger.i('Interstitial Ad Loaded Successfully');
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          _logger.e('Interstitial Ad Failed to Load: ${error.message}');
          _isInterstitialLoading = false;
          _interstitialAd = null;
          _interstitialLoadAttempts++;
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
    final isTriggerOk = _remoteConfigService.isTriggerEnabled('interstitial', trigger);
    final shouldShow = await shouldShowAdByFrequency('InterstitialAd');

    _logger.i('--- INTERSTITIAL TRIGGER CHECK ---');
    _logger.i('Trigger: $trigger, Enabled: $isTriggerOk, Ad Ready: ${_interstitialAd != null}');

    if (!isTriggerOk || !shouldShow || _interstitialAd == null) {
      if (!isTriggerOk) _logger.w('Skipping: Trigger "$trigger" not enabled in Remote Config');
      if (!shouldShow) _logger.w('Skipping: Frequency cap not met');
      if (_interstitialAd == null) {
        _logger.w('Skipping: Interstitial Ad is NULL');
        loadInterstitialAd(); 
      }
      onAdClosed();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _logger.i('Interstitial Ad Dismissed');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _logger.e('Interstitial Ad Failed to Show: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onAdClosed();
      },
    );

    _logger.i('Showing Interstitial Ad...');
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // App Open Ad
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isAppOpenLoading = false;

  void loadAppOpenAd() {
    if (!isAdEnabled('app_open') || _isAppOpenLoading || _appOpenAd != null) return;

    _isAppOpenLoading = true;
    String adUnitId = AdHelper.appOpenAdUnitId;
    _logger.i('Loading App Open Ad with ID: $adUnitId');

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      orientation: AppOpenAd.orientationPortrait,
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenLoading = false;
        },
        onAdFailedToLoad: (error) {
          _logger.e('App Open Ad Failed to Load: ${error.message}');
          _appOpenAd = null;
          _isAppOpenLoading = false;
        },
      ),
    );
  }

  void showAppOpenAdIfAvailable() async {
    final shouldShow = await shouldShowAdByFrequency('AppOpenAd');
    if (!shouldShow || _isShowingAd || _appOpenAd == null) {
      if (_appOpenAd == null) loadAppOpenAd();
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
