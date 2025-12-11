import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/scheduler.dart';
import 'storage_service.dart';
import 'crashlytics_service.dart';
import '../utils/snackbar_utils.dart';

class AdService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();
  CrashlyticsService? _crashlytics;

  BannerAd? bannerAd; // Bottom banner
  BannerAd? topBannerAd; // Top banner
  InterstitialAd? interstitialAd;
  RewardedAd? rewardedAdStronger;
  RewardedAd? rewardedAdCrystal;
  RewardedAd? rewardedAdRemoveAds;

  final isBannerLoaded = false.obs;
  final isTopBannerLoaded = false.obs; // Top banner state
  final isInterstitialLoaded = false.obs;
  final isRewardedStrongerLoaded = false.obs;
  final isRewardedCrystalLoaded = false.obs;
  final isRewardedRemoveAdsLoaded = false.obs;

  // Store the banner ad size for proper display
  AdSize? bannerAdSize;
  AdSize? topBannerAdSize;

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

  // Rewarded interstitial ad unit ID for 2x Stronger and Crystal Voice
  String get rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_ANDROID_REWARDED_INTERSTITIAL_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return dotenv.env['ADMOB_IOS_REWARDED_INTERSTITIAL_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }

  // Rewarded video ad unit ID for peace mode
  String get rewardedVideoAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_ANDROID_REWARDED_VIDEO_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return dotenv.env['ADMOB_IOS_REWARDED_VIDEO_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }

  @override
  void onInit() {
    super.onInit();
    // Use post-frame callback to access CrashlyticsService after initialization completes
    SchedulerBinding.instance.addPostFrameCallback((_) {
      try {
        _crashlytics = Get.find<CrashlyticsService>();
      } catch (_) {
        // CrashlyticsService not available yet
      }
    });
    loadBannerAd();
    loadInterstitialAd();
    loadRewardedAds();
  }

  /// Load adaptive banner ad that fits the screen width
  /// Call this with a BuildContext to get the proper screen width
  Future<void> loadAdaptiveBannerAd(BuildContext context) async {
    if (_storage.isPeaceModeActive()) {
      isBannerLoaded.value = false;
      return;
    }

    // Dispose existing ad if any
    bannerAd?.dispose();
    bannerAd = null;
    isBannerLoaded.value = false;

    // Get adaptive banner size based on screen width
    final width = MediaQuery.of(context).size.width.truncate();
    bannerAdSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (bannerAdSize == null) {
      // Fallback to standard banner if adaptive fails
      bannerAdSize = AdSize.banner;
    }

    bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: bannerAdSize!,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          isBannerLoaded.value = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          isBannerLoaded.value = false;
        },
      ),
    );

    bannerAd?.load();
  }

  /// Legacy method - loads standard banner (for backward compatibility)
  void loadBannerAd() {
    if (_storage.isPeaceModeActive()) {
      isBannerLoaded.value = false;
      return;
    }

    bannerAdSize = AdSize.banner;
    bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          isBannerLoaded.value = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          isBannerLoaded.value = false;
        },
      ),
    );

    bannerAd?.load();
  }

  /// Load adaptive top banner ad
  Future<void> loadAdaptiveTopBannerAd(BuildContext context) async {
    if (_storage.isPeaceModeActive()) {
      isTopBannerLoaded.value = false;
      return;
    }

    // Dispose existing ad if any
    topBannerAd?.dispose();
    topBannerAd = null;
    isTopBannerLoaded.value = false;

    // Get adaptive banner size based on screen width
    final width = MediaQuery.of(context).size.width.truncate();
    topBannerAdSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (topBannerAdSize == null) {
      topBannerAdSize = AdSize.banner;
    }

    topBannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: topBannerAdSize!,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          isTopBannerLoaded.value = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          isTopBannerLoaded.value = false;
        },
      ),
    );

    topBannerAd?.load();
  }

  /// Legacy method - loads standard top banner
  void loadTopBannerAd() {
    if (_storage.isPeaceModeActive()) {
      isTopBannerLoaded.value = false;
      return;
    }

    topBannerAdSize = AdSize.banner;
    topBannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          isTopBannerLoaded.value = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          isTopBannerLoaded.value = false;
        },
      ),
    );

    topBannerAd?.load();
  }

  void loadInterstitialAd() {
    if (_storage.isPeaceModeActive()) {
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
              interstitialAd = null;
              isInterstitialLoaded.value = false;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              interstitialAd = null;
              isInterstitialLoaded.value = false;
              _crashlytics?.reportAdError(
                Exception('Interstitial ad failed to show: ${error.message}'),
                StackTrace.current,
                operation: 'show_interstitial',
                adType: 'interstitial',
                errorCode: error.code,
                errorMessage: error.message,
              );
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          isInterstitialLoaded.value = false;
          interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_storage.isPeaceModeActive()) {
      return;
    }

    final counter = _storage.getShiftCounter();

    if (counter == 4) {
      if (isInterstitialLoaded.value && interstitialAd != null) {
        interstitialAd?.show();
        _storage.resetShiftCounter();
      } else {
        _storage.resetShiftCounter();
        loadInterstitialAd();
      }
    }
  }

  void loadRewardedAds() {
    // 2x Stronger uses rewarded interstitial ad
    RewardedAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
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

    // Crystal Voice uses rewarded interstitial ad
    RewardedAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAdCrystal = ad;
          isRewardedCrystalLoaded.value = true;
        },
        onAdFailedToLoad: (error) {
          isRewardedCrystalLoaded.value = false;
        },
      ),
    );

    // Peace mode uses rewarded video ad unit ID
    RewardedAd.load(
      adUnitId: rewardedVideoAdUnitId,
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
  }

  void showRewardedAdStronger(Function onRewarded) {
    // Skip ad if peace mode is active - give reward for free
    if (_storage.isPeaceModeActive()) {
      onRewarded();
      return;
    }

    if (rewardedAdStronger == null || !isRewardedStrongerLoaded.value) {
      SnackbarUtils.showInfo(title: 'Loading...', message: 'Please wait a moment and try again');

      RewardedAd.load(
        adUnitId: rewardedInterstitialAdUnitId,
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
      return;
    }

    bool rewarded = false;

    rewardedAdStronger?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (rewarded) {
          onRewarded();
        }
        RewardedAd.load(
          adUnitId: rewardedInterstitialAdUnitId,
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
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        SnackbarUtils.showError(title: 'Error', message: 'Failed to show ad. Please try again.');
        _crashlytics?.reportAdError(
          Exception('Rewarded ad (Stronger) failed to show: ${error.message}'),
          StackTrace.current,
          operation: 'show_rewarded_stronger',
          adType: 'rewarded_interstitial',
          errorCode: error.code,
          errorMessage: error.message,
        );
        RewardedAd.load(
          adUnitId: rewardedInterstitialAdUnitId,
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

  void showRewardedAdCrystal(Function onRewarded) {
    // Skip ad if peace mode is active - give reward for free
    if (_storage.isPeaceModeActive()) {
      onRewarded();
      return;
    }

    if (rewardedAdCrystal == null || !isRewardedCrystalLoaded.value) {
      SnackbarUtils.showInfo(title: 'Loading...', message: 'Please wait a moment and try again');

      RewardedAd.load(
        adUnitId: rewardedInterstitialAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            rewardedAdCrystal = ad;
            isRewardedCrystalLoaded.value = true;
          },
          onAdFailedToLoad: (error) {
            isRewardedCrystalLoaded.value = false;
          },
        ),
      );
      return;
    }

    bool rewarded = false;

    rewardedAdCrystal?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (rewarded) {
          onRewarded();
        }
        RewardedAd.load(
          adUnitId: rewardedInterstitialAdUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              rewardedAdCrystal = ad;
              isRewardedCrystalLoaded.value = true;
            },
            onAdFailedToLoad: (error) {
              isRewardedCrystalLoaded.value = false;
            },
          ),
        );
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        SnackbarUtils.showError(title: 'Error', message: 'Failed to show ad. Please try again.');
        _crashlytics?.reportAdError(
          Exception('Rewarded ad (Crystal) failed to show: ${error.message}'),
          StackTrace.current,
          operation: 'show_rewarded_crystal',
          adType: 'rewarded_interstitial',
          errorCode: error.code,
          errorMessage: error.message,
        );
        RewardedAd.load(
          adUnitId: rewardedInterstitialAdUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              rewardedAdCrystal = ad;
              isRewardedCrystalLoaded.value = true;
            },
            onAdFailedToLoad: (error) {
              isRewardedCrystalLoaded.value = false;
            },
          ),
        );
      },
    );

    rewardedAdCrystal?.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
      },
    );
  }

  // Peace mode uses rewarded video ad unit ID
  void showRewardedAdRemoveAds(Function onRewarded) {
    if (rewardedAdRemoveAds == null || !isRewardedRemoveAdsLoaded.value) {
      SnackbarUtils.showInfo(title: 'Loading...', message: 'Please wait a moment and try again');

      RewardedAd.load(
        adUnitId: rewardedVideoAdUnitId,
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
      return;
    }

    bool rewarded = false;

    rewardedAdRemoveAds?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (rewarded) {
          onRewarded();
        }
        RewardedAd.load(
          adUnitId: rewardedVideoAdUnitId,
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
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        SnackbarUtils.showError(title: 'Error', message: 'Failed to show ad. Please try again.');
        _crashlytics?.reportAdError(
          Exception('Rewarded ad (PeaceMode) failed to show: ${error.message}'),
          StackTrace.current,
          operation: 'show_rewarded_peace_mode',
          adType: 'rewarded_video',
          errorCode: error.code,
          errorMessage: error.message,
        );
        RewardedAd.load(
          adUnitId: rewardedVideoAdUnitId,
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
    topBannerAd?.dispose();
    interstitialAd?.dispose();
    rewardedAdStronger?.dispose();
    rewardedAdCrystal?.dispose();
    rewardedAdRemoveAds?.dispose();
    super.onClose();
  }
}
