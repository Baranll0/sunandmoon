import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  static AdService get instance => _instance;

  AdService._internal();

  InterstitialAd? _interstitialAd;
  int _levelsCompleted = 0;
  bool _isAdLoading = false;

  // Test Ad Unit IDs
  final String _androidAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  final String _iosAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    if (_isAdLoading) return;
    _isAdLoading = true;

    InterstitialAd.load(
      adUnitId: Platform.isAndroid ? _androidAdUnitId : _iosAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          _interstitialAd = ad;
          _isAdLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd(); // Preload the next one
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isAdLoading = false;
        },
      ),
    );
  }

  /// Show ad if available
  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null; // Clear reference, wait for preload on dismiss
    } else {
      debugPrint('Warning: Interstitial ad not ready yet.');
      _loadInterstitialAd(); // Try loading again if missed
    }
  }

  /// Called when a level is completed.
  /// Shows ad if logic conditions are met (every 3 levels).
  void onLevelComplete() {
    _levelsCompleted++;
    debugPrint('Levels completed: $_levelsCompleted');
    
    if (_levelsCompleted % 3 == 0) {
      debugPrint('Triggering Ad (Level $_levelsCompleted)');
      showInterstitialAd();
    }
  }
}
