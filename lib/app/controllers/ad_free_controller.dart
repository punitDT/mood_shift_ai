import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/scheduler.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';

/// Controller for Peace Mode feature - hides all ads for a configurable period
class AdFreeController extends GetxController {
  static AdFreeController get to => Get.find();

  final StorageService _storage = Get.find<StorageService>();
  AdService? _adService;

  final isPeaceModeActive = false.obs;
  final peaceModeTimeRemaining = ''.obs;

  Timer? _peaceModeTimer;

  @override
  void onInit() {
    super.onInit();
    // Use post-frame callback to access AdService after initialization completes
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _adService = Get.find<AdService>();
      _updatePeaceModeStatus();
      _startPeaceModeTimer();
    });
  }

  void _startPeaceModeTimer() {
    // Update peace mode status every second
    _peaceModeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updatePeaceModeStatus();
    });
  }

  void _updatePeaceModeStatus() {
    final wasPeaceMode = isPeaceModeActive.value;
    isPeaceModeActive.value = _storage.isPeaceModeActive();

    if (isPeaceModeActive.value) {
      final remaining = _storage.getRemainingPeaceModeTime();
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds.remainder(60);

      peaceModeTimeRemaining.value =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      peaceModeTimeRemaining.value = '';

      // Peace mode just ended - reload all ads
      if (wasPeaceMode && !isPeaceModeActive.value) {
        _adService?.loadBannerAd();
        _adService?.loadInterstitialAd();
      }
    }
  }

  /// Get formatted timer display for UI
  String getPeaceModeTimerDisplay() {
    if (!isPeaceModeActive.value) return '';
    return peaceModeTimeRemaining.value;
  }

  void activatePeaceMode(Function onSuccess) {
    final adService = _adService;
    if (adService == null) return;

    adService.showRewardedAdRemoveAds(() {
      _storage.setPeaceMode();
      _updatePeaceModeStatus();

      // Hide banner ad immediately
      adService.isBannerLoaded.value = false;
      adService.bannerAd?.dispose();
      adService.bannerAd = null;

      onSuccess();
    });
  }

  @override
  void onClose() {
    _peaceModeTimer?.cancel();
    super.onClose();
  }
}

