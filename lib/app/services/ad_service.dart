import 'dart:io';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'storage_service.dart';

class AdService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

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

  // Ad Unit IDs loaded from environment variables
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_ANDROID_BANNER_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return dotenv.env['ADMOB_IOS_BANNER_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_ANDROID_INTERSTITIAL_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return dotenv.env['ADMOB_IOS_INTERSTITIAL_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_ANDROID_REWARDED_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return dotenv.env['ADMOB_IOS_REWARDED_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }

  @override
  void onInit() {
    super.onInit();
    print('📱 [AD] Banner ID: $bannerAdUnitId');
    print('📱 [AD] Interstitial ID: $interstitialAdUnitId');
    print('📱 [AD] Rewarded ID: $rewardedAdUnitId');
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
    print('🔄 [AD DEBUG] Loading all rewarded ads...');

    // 1. Make 2x Stronger
    print('   Loading 2x Stronger ad...');
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ [AD DEBUG] 2x Stronger ad loaded successfully');
          rewardedAdStronger = ad;
          isRewardedStrongerLoaded.value = true;
        },
        onAdFailedToLoad: (error) {
          print('❌ [AD DEBUG] 2x Stronger ad failed to load: $error');
          isRewardedStrongerLoaded.value = false;
        },
      ),
    );

    // 2. Golden Voice
    print('   Loading Golden Voice ad...');
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ [AD DEBUG] Golden Voice ad loaded successfully');
          rewardedAdGolden = ad;
          isRewardedGoldenLoaded.value = true;
        },
        onAdFailedToLoad: (error) {
          print('❌ [AD DEBUG] Golden Voice ad failed to load: $error');
          isRewardedGoldenLoaded.value = false;
        },
      ),
    );

    // 3. Remove Ads 24h
    print('   Loading Remove Ads ad...');
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ [AD DEBUG] Remove Ads ad loaded successfully');
          rewardedAdRemoveAds = ad;
          isRewardedRemoveAdsLoaded.value = true;
        },
        onAdFailedToLoad: (error) {
          print('❌ [AD DEBUG] Remove Ads ad failed to load: $error');
          isRewardedRemoveAdsLoaded.value = false;
        },
      ),
    );
  }

  void showRewardedAdStronger(Function onRewarded) {
    print('🎬 [AD DEBUG] Attempting to show 2x Stronger ad');
    print('   Ad loaded: ${isRewardedStrongerLoaded.value}');
    print('   Ad object: ${rewardedAdStronger != null}');

    if (rewardedAdStronger == null || !isRewardedStrongerLoaded.value) {
      print('❌ [AD DEBUG] Ad not ready, attempting to reload...');
      Get.snackbar('Loading...', 'Please wait a moment and try again');

      // Try to reload the ad immediately
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            print('✅ [AD DEBUG] 2x Stronger ad reloaded successfully');
            rewardedAdStronger = ad;
            isRewardedStrongerLoaded.value = true;
          },
          onAdFailedToLoad: (error) {
            print('❌ [AD DEBUG] Failed to reload 2x Stronger ad: $error');
            isRewardedStrongerLoaded.value = false;
          },
        ),
      );
      return;
    }

    bool rewarded = false;

    rewardedAdStronger?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        print('🎬 [AD DEBUG] 2x Stronger ad dismissed');
        ad.dispose();
        // Play audio after ad is closed
        if (rewarded) {
          print('✅ [AD DEBUG] User earned reward, executing callback');

          // Track analytics
          _analytics.logEvent(
            name: 'rewarded_ad_watched',
            parameters: {
              'ad_type': 'stronger',
              'reward_earned': true,
            },
          );

          onRewarded();
        }
        // Reload
        print('🔄 [AD DEBUG] Reloading 2x Stronger ad...');
        RewardedAd.load(
          adUnitId: rewardedAdUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              print('✅ [AD DEBUG] 2x Stronger ad reloaded after show');
              rewardedAdStronger = ad;
              isRewardedStrongerLoaded.value = true;
            },
            onAdFailedToLoad: (error) {
              print('❌ [AD DEBUG] Failed to reload 2x Stronger ad: $error');
              isRewardedStrongerLoaded.value = false;
            },
          ),
        );
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ [AD DEBUG] Failed to show 2x Stronger ad: $error');
        ad.dispose();
        Get.snackbar('Error', 'Failed to show ad. Please try again.');
        // Reload on failure
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

    print('🎬 [AD DEBUG] Showing 2x Stronger ad now...');
    rewardedAdStronger?.show(
      onUserEarnedReward: (ad, reward) {
        print('🎁 [AD DEBUG] User earned reward!');
        rewarded = true;
      },
    );
  }

  void showRewardedAdGolden(Function onRewarded) {
    print('🎬 [AD DEBUG] Attempting to show Golden Voice ad');
    print('   Ad loaded: ${isRewardedGoldenLoaded.value}');
    print('   Ad object: ${rewardedAdGolden != null}');

    if (rewardedAdGolden == null || !isRewardedGoldenLoaded.value) {
      print('❌ [AD DEBUG] Golden Voice ad not ready, attempting to reload...');
      Get.snackbar('Loading...', 'Please wait a moment and try again');

      // Try to reload the ad immediately
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            print('✅ [AD DEBUG] Golden Voice ad reloaded successfully');
            rewardedAdGolden = ad;
            isRewardedGoldenLoaded.value = true;
          },
          onAdFailedToLoad: (error) {
            print('❌ [AD DEBUG] Failed to reload Golden Voice ad: $error');
            isRewardedGoldenLoaded.value = false;
          },
        ),
      );
      return;
    }

    bool rewarded = false;

    rewardedAdGolden?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        print('🎬 [AD DEBUG] Golden Voice ad dismissed');
        ad.dispose();
        // Execute reward after ad is closed
        if (rewarded) {
          print('✅ [AD DEBUG] User earned Golden Voice reward');

          // Track analytics
          _analytics.logEvent(
            name: 'rewarded_ad_watched',
            parameters: {
              'ad_type': 'golden_voice',
              'reward_earned': true,
            },
          );

          onRewarded();
        }
        print('🔄 [AD DEBUG] Reloading Golden Voice ad...');
        RewardedAd.load(
          adUnitId: rewardedAdUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              print('✅ [AD DEBUG] Golden Voice ad reloaded after show');
              rewardedAdGolden = ad;
              isRewardedGoldenLoaded.value = true;
            },
            onAdFailedToLoad: (error) {
              print('❌ [AD DEBUG] Failed to reload Golden Voice ad: $error');
              isRewardedGoldenLoaded.value = false;
            },
          ),
        );
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ [AD DEBUG] Failed to show Golden Voice ad: $error');
        ad.dispose();
        Get.snackbar('Error', 'Failed to show ad. Please try again.');
        // Reload on failure
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

    print('🎬 [AD DEBUG] Showing Golden Voice ad now...');
    rewardedAdGolden?.show(
      onUserEarnedReward: (ad, reward) {
        print('🎁 [AD DEBUG] User earned Golden Voice reward!');
        rewarded = true;
      },
    );
  }

  void showRewardedAdRemoveAds(Function onRewarded) {
    print('🎬 [AD DEBUG] Attempting to show Remove Ads ad');
    print('   Ad loaded: ${isRewardedRemoveAdsLoaded.value}');
    print('   Ad object: ${rewardedAdRemoveAds != null}');

    if (rewardedAdRemoveAds == null || !isRewardedRemoveAdsLoaded.value) {
      print('❌ [AD DEBUG] Remove Ads ad not ready, attempting to reload...');
      Get.snackbar('Loading...', 'Please wait a moment and try again');

      // Try to reload the ad immediately
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            print('✅ [AD DEBUG] Remove Ads ad reloaded successfully');
            rewardedAdRemoveAds = ad;
            isRewardedRemoveAdsLoaded.value = true;
          },
          onAdFailedToLoad: (error) {
            print('❌ [AD DEBUG] Failed to reload Remove Ads ad: $error');
            isRewardedRemoveAdsLoaded.value = false;
          },
        ),
      );
      return;
    }

    bool rewarded = false;

    rewardedAdRemoveAds?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        print('🎬 [AD DEBUG] Remove Ads ad dismissed');
        ad.dispose();
        // Execute reward after ad is closed
        if (rewarded) {
          print('✅ [AD DEBUG] User earned Remove Ads reward');
          onRewarded();
        }
        print('🔄 [AD DEBUG] Reloading Remove Ads ad...');
        RewardedAd.load(
          adUnitId: rewardedAdUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              print('✅ [AD DEBUG] Remove Ads ad reloaded after show');
              rewardedAdRemoveAds = ad;
              isRewardedRemoveAdsLoaded.value = true;
            },
            onAdFailedToLoad: (error) {
              print('❌ [AD DEBUG] Failed to reload Remove Ads ad: $error');
              isRewardedRemoveAdsLoaded.value = false;
            },
          ),
        );
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ [AD DEBUG] Failed to show Remove Ads ad: $error');
        ad.dispose();
        Get.snackbar('Error', 'Failed to show ad. Please try again.');
        // Reload on failure
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

    print('🎬 [AD DEBUG] Showing Remove Ads ad now...');
    rewardedAdRemoveAds?.show(
      onUserEarnedReward: (ad, reward) {
        print('🎁 [AD DEBUG] User earned Remove Ads reward!');
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

