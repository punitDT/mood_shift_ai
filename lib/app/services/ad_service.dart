import 'dart:io';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'storage_service.dart';
import '../utils/snackbar_utils.dart';

class AdService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();

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
    loadBannerAd();
    loadInterstitialAd();
    loadRewardedAds();
  }

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
          ad.dispose();
          isBannerLoaded.value = false;
        },
      ),
    );

    bannerAd?.load();
  }

  void loadTopBannerAd() {
    if (_storage.isAdFree()) {
      isTopBannerLoaded.value = false;
      return;
    }

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
              interstitialAd = null;
              isInterstitialLoaded.value = false;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              interstitialAd = null;
              isInterstitialLoaded.value = false;
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
    if (_storage.isAdFree()) {
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

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
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
  }

  void showRewardedAdStronger(Function onRewarded) {
    if (rewardedAdStronger == null || !isRewardedStrongerLoaded.value) {
      SnackbarUtils.showInfo(title: 'Loading...', message: 'Please wait a moment and try again');

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
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        SnackbarUtils.showError(title: 'Error', message: 'Failed to show ad. Please try again.');
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

  void showRewardedAdCrystal(Function onRewarded) {
    if (rewardedAdCrystal == null || !isRewardedCrystalLoaded.value) {
      SnackbarUtils.showInfo(title: 'Loading...', message: 'Please wait a moment and try again');

      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
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
          adUnitId: rewardedAdUnitId,
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
        RewardedAd.load(
          adUnitId: rewardedAdUnitId,
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

  void showRewardedAdRemoveAds(Function onRewarded) {
    if (rewardedAdRemoveAds == null || !isRewardedRemoveAdsLoaded.value) {
      SnackbarUtils.showInfo(title: 'Loading...', message: 'Please wait a moment and try again');

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
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        SnackbarUtils.showError(title: 'Error', message: 'Failed to show ad. Please try again.');
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
    topBannerAd?.dispose();
    interstitialAd?.dispose();
    rewardedAdStronger?.dispose();
    rewardedAdCrystal?.dispose();
    rewardedAdRemoveAds?.dispose();
    super.onClose();
  }
}
