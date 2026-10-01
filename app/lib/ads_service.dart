import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob is deliberately opt-in. The first release must remain ad-free.
/// Enable only with --dart-define=NALVIUM_ADS_ENABLED=true and a reviewed
/// environment configuration.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  static const _enabled = bool.fromEnvironment(
    'NALVIUM_ADS_ENABLED',
    defaultValue: false,
  );
  static const _environment = String.fromEnvironment(
    'NALVIUM_ENV',
    defaultValue: 'development',
  );
  static const _appOpenId = String.fromEnvironment('NALVIUM_AD_APP_OPEN_ID');
  static const _interstitialId = String.fromEnvironment(
    'NALVIUM_AD_INTERSTITIAL_ID',
  );
  static const _rewardedId = String.fromEnvironment('NALVIUM_AD_REWARDED_ID');

  bool get enabled => _enabled && !kIsWeb;
  bool get isDevelopment => _environment != 'production';

  // Official Google test units. They are used for every non-production build.
  static const _testAppOpenId = 'ca-app-pub-3940256099942544/9257395921';
  static const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  String get appOpenId => isDevelopment ? _testAppOpenId : _appOpenId;
  String get interstitialId =>
      isDevelopment ? _testInterstitialId : _interstitialId;
  String get rewardedId => isDevelopment ? _testRewardedId : _rewardedId;

  bool _initialized = false;
  AppOpenAd? _appOpen;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  Future<void> initialize() async {
    if (!enabled || _initialized) return;
    if (!isDevelopment &&
        (appOpenId.isEmpty || interstitialId.isEmpty || rewardedId.isEmpty)) {
      throw StateError(
        'AdMob production IDs are required when advertising is enabled.',
      );
    }
    await _requestConsent();
    if (!await ConsentInformation.instance.canRequestAds()) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  Future<void> showPrivacyOptions() async {
    if (!enabled) return;
    await ConsentForm.showPrivacyOptionsForm((_) {});
  }

  Future<void> _requestConsent() {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            // The UMP SDK owns the approved consent UI and privacy choices.
            await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
          }
        } finally {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (_) {
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  Future<void> preloadAppOpen() async {
    if (!enabled || !_initialized || appOpenId.isEmpty) return;
    await AppOpenAd.load(
      adUnitId: appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpen = ad,
        onAdFailedToLoad: (error) => _appOpen = null,
      ),
    );
  }

  Future<void> showAppOpenIfAllowed() async {
    if (!enabled || _appOpen == null) return;
    final ad = _appOpen!;
    _appOpen = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
    );
    await ad.show();
  }

  Future<void> preloadInterstitial() async {
    if (!enabled || !_initialized || interstitialId.isEmpty) return;
    await InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) => _interstitial = null,
      ),
    );
  }

  Future<void> showInterstitialIfAllowed() async {
    if (!enabled || _interstitial == null) return;
    final ad = _interstitial!;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
    );
    await ad.show();
  }

  Future<void> preloadRewarded() async {
    if (!enabled || !_initialized || rewardedId.isEmpty) return;
    await RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (error) => _rewarded = null,
      ),
    );
  }

  Future<bool> showRewardedIfAllowed() async {
    if (!enabled || _rewarded == null) return false;
    final ad = _rewarded!;
    _rewarded = null;
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
    );
    await ad.show(onUserEarnedReward: (_, reward) => earned = true);
    return earned;
  }
}
