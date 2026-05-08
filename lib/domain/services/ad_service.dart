import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import 'monetization_service.dart';

class AdService {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  int _interstitialCounter = 0;
  bool _isBannerLoaded = false;
  final MonetizationService _monetization = MonetizationService();

  /// Загрузить баннер
  Future<void> loadBannerAd() async {
    final showAds = await _monetization.shouldShowAds();
    if (!showAds) return;

    _bannerAd?.dispose();

    _bannerAd = BannerAd(
      adUnitId: AppConstants.adUnitIdBanner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isBannerLoaded = true;
          logger.i('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerLoaded = false;
          ad.dispose();
          logger.w('Banner ad failed to load: ${error.message}');
        },
        onAdOpened: (_) => logger.i('Banner ad opened'),
        onAdClosed: (_) => logger.i('Banner ad closed'),
      ),
    )..load();
  }

  /// Показать межстраничную рекламу
  Future<void> showInterstitial() async {
    final showAds = await _monetization.shouldShowAds();
    if (!showAds) return;

    _interstitialCounter++;
    if (_interstitialCounter < 3) return;
    _interstitialCounter = 0;

    await InterstitialAd.load(
      adUnitId: AppConstants.adUnitIdInterstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd?.show();
          _interstitialAd?.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );
        },
        onAdFailedToLoad: (error) {
          logger.w('Interstitial ad failed to load: ${error.message}');
        },
      ),
    );
  }

  /// Показать rewarded video для получения доп. запросов
  Future<bool> showRewardedForRequests() async {
    final showAds = await _monetization.shouldShowAds();
    if (!showAds) return false;

    final completer = Completer<bool>();

    await RewardedAd.load(
      adUnitId: AppConstants.adUnitIdRewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(
            onUserEarnedReward: (ad, reward) {
              completer.complete(true);
            },
          );
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              completer.complete(false);
            },
          );
        },
        onAdFailedToLoad: (error) {
          logger.w('Rewarded ad failed to load: ${error.message}');
          completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  /// Виджет баннера
  Widget bannerWidget() {
    return FutureBuilder<bool>(
      future: _monetization.shouldShowAds(),
      builder: (context, snapshot) {
        if (snapshot.data == false) {
          return const SizedBox.shrink();
        }
        if (!_isBannerLoaded || _bannerAd == null) {
          return const SizedBox(height: 50);
        }
        return Container(
          height: 50,
          color: Colors.black12,
          child: AdWidget(ad: _bannerAd!),
        );
      },
    );
  }

  /// Загрузить всё
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    await loadBannerAd();
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}
