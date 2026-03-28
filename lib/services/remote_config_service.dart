import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();

  factory RemoteConfigService() => _instance;

  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Map<String, dynamic> _adsConfig = {};

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await _remoteConfig.fetchAndActivate();

      String jsonString = _remoteConfig.getString('ads_config');
      if (jsonString.isNotEmpty) {
        _adsConfig = jsonDecode(jsonString);
      }
    } catch (e) {
      print('Error initializing Remote Config: $e');
    }
  }

  Map<String, dynamic> get adsConfig => _adsConfig;

  bool get showAds => _adsConfig['show_ads'] ?? false;

  String getAdUnitId(String type) {
    if (_adsConfig['ads_units'] != null &&
        _adsConfig['ads_units'][type] != null) {
      return _adsConfig['ads_units'][type]['id_android'] ?? '';
    }
    return '';
  }

  bool isAdEnabled(String type) {
    if (_adsConfig['ads_units'] != null &&
        _adsConfig['ads_units'][type] != null) {
      return _adsConfig['ads_units'][type]['enable'] ?? false;
    }
    return false;
  }

  bool isTriggerEnabled(String adType, String trigger) {
    final triggers = _adsConfig['${adType}_triggers'] as List?;
    return triggers?.contains(trigger) ?? false;
  }

  int getFrequency(String type) {
    // Standardize key to lowercase
    final key = type.toLowerCase().replaceAll('ad', ''); // 'InterstitialAd' -> 'interstitial'

    if (_adsConfig['ads_units'] != null &&
        _adsConfig['ads_units'][key] != null &&
        _adsConfig['ads_units'][key]['frequency'] != null) {
      return _adsConfig['ads_units'][key]['frequency'];
    }

    // Fallback to top-level keys like 'interstitial_frequency'
    return _adsConfig['${key}_frequency'] ?? 1;
  }

  // Deprecated: used getFrequency instead
  int get adFrequencySessions => getFrequency('interstitial');
}
