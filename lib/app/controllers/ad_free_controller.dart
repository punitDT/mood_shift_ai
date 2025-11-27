import 'dart:async';
import 'package:get/get.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';

class AdFreeController extends GetxController {
  static AdFreeController get to => Get.find();
  
  final StorageService _storage = Get.find<StorageService>();
  late final AdService _adService;
  
  final isAdFree = false.obs;
  final adFreeTimeRemaining = ''.obs;
  
  Timer? _adFreeTimer;

  @override
  void onInit() {
    super.onInit();
    // Delay AdService access to avoid circular dependency
    Future.delayed(Duration.zero, () {
      _adService = Get.find<AdService>();
      _updateAdFreeStatus();
      _startAdFreeTimer();
    });
  }

  void _startAdFreeTimer() {
    // Update ad-free status every second
    _adFreeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateAdFreeStatus();
    });
  }

  void _updateAdFreeStatus() {
    final wasAdFree = isAdFree.value;
    isAdFree.value = _storage.isAdFree();
    
    if (isAdFree.value) {
      final remaining = _storage.getRemainingAdFreeTime();
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes.remainder(60);
      final seconds = remaining.inSeconds.remainder(60);
      
      if (hours > 0) {
        adFreeTimeRemaining.value = '${hours}h ${minutes}m';
      } else if (minutes > 0) {
        adFreeTimeRemaining.value = '${minutes}m ${seconds}s';
      } else {
        adFreeTimeRemaining.value = '${seconds}s';
      }
    } else {
      adFreeTimeRemaining.value = '';
      
      if (wasAdFree && !isAdFree.value) {
        _adService.loadBannerAd();
      }
    }
  }

  void activateAdFree24h(Function onSuccess) {
    _adService.showRewardedAdRemoveAds(() {
      _storage.setAdFree24Hours();
      _updateAdFreeStatus();
      
      // Hide banner ad immediately
      _adService.isBannerLoaded.value = false;
      _adService.bannerAd?.dispose();
      _adService.bannerAd = null;
      
      onSuccess();
    });
  }

  @override
  void onClose() {
    _adFreeTimer?.cancel();
    super.onClose();
  }
}

