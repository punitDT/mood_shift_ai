import 'dart:io';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'storage_service.dart';

class AdService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();
  
  BannerAd? bannerAd;
  InterstitialAd? interstitialAd;
  RewardedAd? rewardedAdStronger;
  RewardedAd? rewardedAdGolden;
  RewardedAd? rewardedAdRemoveAds;
  
  final isBannerLoaded = false.obs;
  final isInterstitialLoaded = false.obs;
  final isRewardedStrongerLoaded = false.obs;
  final isRewardedGoldenLoaded = false.obs;
  final isRewardedRemoveAdsLoaded = false.obs;

  // Test Ad Unit IDs (replace with real ones for production)
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test banner
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test banner
    }
    return '';
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test interstitial
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test interstitial
    }
    return '';
  }

  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test rewarded
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test rewarded
    }
    return '';
  }

  @override
  void onInit() {
    super.onInit();
    loadBannerAd();
    loadInterstitialAd();
    loadRewardedAds();
  }

  // Banner Ad (always visible at bottom)
  void loadBannerAd() {
    if (_storage.isAdFree()) {
      isBannerLoaded.value = false;
      return;
    }

    bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          isBannerLoaded.value = true;
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
          isBannerLoaded.value = false;
        },
      ),
    );

    bannerAd?.load();
  }

  // Interstitial Ad (every 4th shift)
  void loadInterstitialAd() {
    if (_storage.isAdFree()) {
      isInterstitialLoaded.value = false;
      return;
    }

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
          isInterstitialLoaded.value = true;
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadInterstitialAd(); // Load next one
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Interstitial ad failed to show: $error');
              ad.dispose();
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          isInterstitialLoaded.value = false;
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_storage.isAdFree()) return;

    final counter = _storage.getShiftCounter();
    print('🎯 [AD DEBUG] Shift counter: $counter');

    // Show interstitial ONLY on exactly 4th, 8th, 12th shift (counter == 4)
    if (counter == 4 && isInterstitialLoaded.value && interstitialAd != null) {
      print('✅ [AD DEBUG] Showing interstitial ad on shift #$counter');
      interstitialAd?.show();
      _storage.resetShiftCounter();
    } else {
      print('⏭️  [AD DEBUG] Skipping interstitial (counter: $counter, loaded: ${isInterstitialLoaded.value})');
    }
  }

  // Rewarded Ads (3 types)
  // NOTE: Rewarded ads are ALWAYS loaded, even during ad-free period
  // They are superpowers, not ads!
  void loadRewardedAds() {
    // 1. Make 2x Stronger
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAdStronger = ad;
          isRewardedStrongerLoaded.value = true;
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad (stronger) failed to load: $error');
          isRewardedStrongerLoaded.value = false;
        },
      ),
    );

    // 2. Golden Voice
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAdGolden = ad;
          isRewardedGoldenLoaded.value = true;
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad (golden) failed to load: $error');
          isRewardedGoldenLoaded.value = false;
        },
      ),
    );

    // 3. Remove Ads 24h
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAdRemoveAds = ad;
          isRewardedRemoveAdsLoaded.value = true;
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad (remove ads) failed to load: $error');
          isRewardedRemoveAdsLoaded.value = false;
        },
      ),
    );
  }

  void showRewardedAdStronger(Function onRewarded) {
    if (rewardedAdStronger == null || !isRewardedStrongerLoaded.value) {
      Get.snackbar('Error', 'ad_not_ready'.tr);
      return;
    }

    bool rewarded = false;

    rewardedAdStronger?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        // Play audio after ad is closed
        if (rewarded) {
          onRewarded();
        }
        // Reload
        RewardedAd.load(
          adUnitId: rewardedAdUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              rewardedAdStronger = ad;
              isRewardedStrongerLoaded.value = true;
            },
            onAdFailedToLoad: (error) {
              isRewardedStrongerLoaded.value = false;
            },
          ),
        );
      },
    );

    rewardedAdStronger?.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
      },
    );
  }

  void showRewardedAdGolden(Function onRewarded) {
    if (rewardedAdGolden == null || !isRewardedGoldenLoaded.value) {
      Get.snackbar('Error', 'ad_not_ready'.tr);
      return;
    }

    bool rewarded = false;

    rewardedAdGolden?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        // Execute reward after ad is closed
        if (rewarded) {
          onRewarded();
        }
        RewardedAd.load(
          adUnitId: rewardedAdUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              rewardedAdGolden = ad;
              isRewardedGoldenLoaded.value = true;
            },
            onAdFailedToLoad: (error) {
              isRewardedGoldenLoaded.value = false;
            },
          ),
        );
      },
    );

    rewardedAdGolden?.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
      },
    );
  }

  void showRewardedAdRemoveAds(Function onRewarded) {
    if (rewardedAdRemoveAds == null || !isRewardedRemoveAdsLoaded.value) {
      Get.snackbar('Error', 'ad_not_ready'.tr);
      return;
    }

    bool rewarded = false;

    rewardedAdRemoveAds?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        // Execute reward after ad is closed
        if (rewarded) {
          onRewarded();
        }
        RewardedAd.load(
          adUnitId: rewardedAdUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              rewardedAdRemoveAds = ad;
              isRewardedRemoveAdsLoaded.value = true;
            },
            onAdFailedToLoad: (error) {
              isRewardedRemoveAdsLoaded.value = false;
            },
          ),
        );
      },
    );

    rewardedAdRemoveAds?.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
      },
    );
  }

  @override
  void onClose() {
    bannerAd?.dispose();
    interstitialAd?.dispose();
    rewardedAdStronger?.dispose();
    rewardedAdGolden?.dispose();
    rewardedAdRemoveAds?.dispose();
    super.onClose();
  }
}

