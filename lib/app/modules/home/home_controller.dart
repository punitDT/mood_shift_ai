import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../services/ai_service.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';
import '../../services/storage_service.dart';
import '../../services/ad_service.dart';
import '../../services/remote_config_service.dart';
import '../../routes/app_routes.dart';

enum AppState {
  idle,
  listening,
  processing,
  speaking,
}

class HomeController extends GetxController {
  final AIService _aiService = Get.find<AIService>();
  final SpeechService _speechService = Get.find<SpeechService>();
  final TTSService _ttsService = Get.find<TTSService>();
  final StorageService _storage = Get.find<StorageService>();
  final AdService _adService = Get.find<AdService>();
  final RemoteConfigService _remoteConfig = Get.find<RemoteConfigService>();

  final currentState = AppState.idle.obs;
  final statusText = 'hold_to_speak'.obs;
  final streakDay = 1.obs;
  final todayShifts = 0.obs;
  final showRewardButtons = false.obs;
  
  late ConfettiController confettiController;
  
  String? lastResponse;
  MoodStyle? lastStyle;

  @override
  void onInit() {
    super.onInit();
    confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initializeServices();
    _updateStats();
    _checkForceUpdate();
  }

  Future<void> _initializeServices() async {
    await _speechService.initialize();
  }

  void _updateStats() {
    streakDay.value = _storage.getStreakDay();
    todayShifts.value = _storage.getTodayShifts();
  }

  void _checkForceUpdate() {
    if (_remoteConfig.shouldForceUpdate()) {
      _showForceUpdateDialog();
    }
  }

  void _showForceUpdateDialog() {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text('update_required'.tr),
          content: Text(_remoteConfig.getUpdateMessage()),
          actions: [
            ElevatedButton(
              onPressed: () {
                // TODO: Open app store/play store
                // Use url_launcher to open store link
              },
              child: Text('update_now'.tr),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> onMicPressed() async {
    if (currentState.value != AppState.idle) return;

    currentState.value = AppState.listening;
    statusText.value = 'listening'.tr;
    showRewardButtons.value = false;

    await _speechService.startListening((recognizedText) async {
      if (recognizedText.isEmpty) {
        Get.snackbar('Error', 'no_speech_detected'.tr);
        _resetToIdle();
        return;
      }

      await _processUserInput(recognizedText);
    });
  }

  Future<void> onMicReleased() async {
    if (currentState.value == AppState.listening) {
      await _speechService.stopListening();
    }
  }

  Future<void> _processUserInput(String userInput) async {
    currentState.value = AppState.processing;
    statusText.value = 'processing'.tr;

    try {
      // Get AI response
      final languageCode = _storage.getLanguageCode();
      final response = await _aiService.generateResponse(userInput, languageCode);
      
      if (response.isEmpty) {
        Get.snackbar('Error', 'ai_error'.tr);
        _resetToIdle();
        return;
      }

      // Save response for 2x stronger feature
      lastResponse = response;
      lastStyle = _aiService.getRandomStyle();
      _storage.setLastResponse(response);

      // Speak response
      currentState.value = AppState.speaking;
      statusText.value = 'speaking'.tr;

      await _ttsService.speak(response, lastStyle!);

      // Wait for TTS to complete
      await Future.delayed(const Duration(milliseconds: 500));
      while (_ttsService.isSpeaking.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Shift completed!
      _onShiftCompleted();
    } catch (e) {
      print('Error processing input: $e');
      Get.snackbar('Error', 'ai_error'.tr);
      _resetToIdle();
    }
  }

  void _onShiftCompleted() {
    // Update stats
    _storage.incrementShift();
    _storage.incrementShiftCounter();
    _updateStats();

    // Show confetti
    confettiController.play();

    // Show interstitial ad (every 4th shift)
    _adService.showInterstitialAd();

    // Show rewarded ad buttons
    showRewardButtons.value = true;

    // Reset to idle
    _resetToIdle();

    // Fetch remote config after shift
    _remoteConfig.fetchConfig();
  }

  void _resetToIdle() {
    currentState.value = AppState.idle;
    statusText.value = 'hold_to_speak'.tr;
  }

  // Rewarded Ad Actions
  void onMakeStronger() {
    _adService.showRewardedAdStronger(() {
      // Replay 2x stronger
      if (lastResponse != null && lastStyle != null) {
        _ttsService.speakStronger(lastResponse!, lastStyle!);
        confettiController.play();
      }
    });
  }

  void onUnlockGolden() {
    _adService.showRewardedAdGolden(() {
      _storage.setGoldenVoice1Hour();
      Get.snackbar(
        'Success',
        'Golden Voice unlocked for 1 hour! ✨',
        backgroundColor: Colors.amber.withOpacity(0.8),
      );
    });
  }

  void onRemoveAds() {
    _adService.showRewardedAdRemoveAds(() {
      _storage.setAdFree24Hours();
      Get.snackbar(
        'Success',
        'Ads removed for 24 hours! 🚀',
        backgroundColor: Colors.green.withOpacity(0.8),
      );
      // Reload banner ad (will check ad-free status)
      _adService.loadBannerAd();
    });
  }

  void goToSettings() {
    Get.toNamed(AppRoutes.SETTINGS);
  }

  @override
  void onClose() {
    confettiController.dispose();
    super.onClose();
  }
}

