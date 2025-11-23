import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../services/ai_service.dart';
import '../../services/groq_llm_service.dart';
import '../../services/speech_service.dart';
import '../../services/polly_tts_service.dart';
import '../../services/storage_service.dart';
import '../../services/ad_service.dart';
import '../../services/remote_config_service.dart';
import '../../controllers/ad_free_controller.dart';
import '../../controllers/streak_controller.dart';
import '../../routes/app_routes.dart';

enum AppState {
  idle,
  listening,
  processing,
  speaking,
}

class HomeController extends GetxController {
  final GroqLLMService _llmService = Get.find<GroqLLMService>();
  final SpeechService _speechService = Get.find<SpeechService>();
  final PollyTTSService _ttsService = Get.find<PollyTTSService>();
  final StorageService _storage = Get.find<StorageService>();
  final AdService _adService = Get.find<AdService>();
  final RemoteConfigService _remoteConfig = Get.find<RemoteConfigService>();
  late final AdFreeController _adFreeController;
  late final StreakController _streakController;

  final currentState = AppState.idle.obs;
  final statusText = 'hold_to_speak'.obs;
  final streakDay = 1.obs;
  final todayShifts = 0.obs;
  final showRewardButtons = false.obs;

  // Golden Voice tracking
  final hasGoldenVoice = false.obs;
  final goldenTimeRemaining = ''.obs;

  late ConfettiController confettiController;
  Timer? _goldenVoiceTimer;
  Timer? _listeningTimeoutTimer;

  String? lastResponse;
  MoodStyle? lastStyle;

  @override
  void onInit() {
    super.onInit();
    confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _adFreeController = Get.find<AdFreeController>();
    _streakController = Get.find<StreakController>();
    _initializeServices();
    _updateStats();
    _checkForceUpdate();
    _startGoldenVoiceTimer();
  }

  // Safe translation helper to prevent range errors
  String _tr(String key, {String fallback = ''}) {
    try {
      final translated = key.tr;
      return translated.isNotEmpty ? translated : (fallback.isNotEmpty ? fallback : key);
    } catch (e) {
      print('⚠️  [TRANSLATION DEBUG] Error translating "$key": $e');
      return fallback.isNotEmpty ? fallback : key;
    }
  }

  Future<void> _initializeServices() async {
    await _speechService.initialize();
  }

  void _updateStats() {
    streakDay.value = _storage.getStreakDay();
    todayShifts.value = _storage.getTodayShifts();
    _updateGoldenVoiceStatus();
  }

  void _startGoldenVoiceTimer() {
    // Update golden voice status every second
    _goldenVoiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateGoldenVoiceStatus();
    });
  }

  void _updateGoldenVoiceStatus() {
    hasGoldenVoice.value = _storage.hasGoldenVoice();

    if (hasGoldenVoice.value) {
      final remaining = _storage.getRemainingGoldenTime();
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      goldenTimeRemaining.value = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      print('⏱️  [GOLDEN DEBUG] Time remaining: ${goldenTimeRemaining.value}');
    } else {
      goldenTimeRemaining.value = '';
    }
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

    print('🎤 [MIC DEBUG] Mic pressed - starting listening');

    try {
      currentState.value = AppState.listening;
      statusText.value = _tr('listening', fallback: 'Listening...');
      showRewardButtons.value = false;

      // Set a timeout to prevent getting stuck in listening state
      _listeningTimeoutTimer?.cancel();
      _listeningTimeoutTimer = Timer(const Duration(seconds: 10), () {
        print('⏱️  [MIC DEBUG] Listening timeout - resetting to idle');
        if (currentState.value == AppState.listening) {
          _speechService.stopListening();
          Get.snackbar('Timeout', 'No speech detected. Please try again.');
          _resetToIdle();
        }
      });

      await _speechService.startListening((recognizedText) async {
        print('🎤 [MIC DEBUG] Speech recognized: $recognizedText');
        _listeningTimeoutTimer?.cancel();

        if (recognizedText.isEmpty) {
          Get.snackbar('Error', _tr('no_speech_detected', fallback: 'No speech detected'));
          _resetToIdle();
          return;
        }

        await _processUserInput(recognizedText);
      });
    } catch (e, stackTrace) {
      print('❌ [MIC DEBUG] Error starting listening: $e');
      print('❌ [MIC DEBUG] Stack trace: $stackTrace');
      _listeningTimeoutTimer?.cancel();
      Get.snackbar('Error', 'Failed to start listening. Please try again.');
      _resetToIdle();
    }
  }

  Future<void> onMicReleased() async {
    print('🎤 [MIC DEBUG] Mic released');
    if (currentState.value == AppState.listening) {
      await _speechService.stopListening();
      // Don't reset to idle here - wait for the callback or timeout
    }
  }

  Future<void> _processUserInput(String userInput) async {
    Timer? slowResponseTimer;

    try {
      currentState.value = AppState.processing;
      statusText.value = _tr('processing', fallback: 'Thinking...');

      // Show "Taking a moment..." if API is slow (>3 seconds)
      slowResponseTimer = Timer(const Duration(seconds: 3), () {
        if (currentState.value == AppState.processing) {
          statusText.value = _tr('taking_moment', fallback: 'Taking a moment...');
        }
      });

      // Get AI response from Groq
      final languageCode = _storage.getLanguageCode();
      print('🎤 [MIC DEBUG] Processing input with language: $languageCode');

      final response = await _llmService.generateResponse(userInput, languageCode);
      slowResponseTimer.cancel();

      if (response.isEmpty) {
        Get.snackbar('Error', _tr('ai_error', fallback: 'AI service error'));
        _resetToIdle();
        return;
      }

      // Save response for 2x stronger feature
      lastResponse = response;
      lastStyle = _llmService.getRandomStyle();
      _storage.setLastResponse(response);

      // Speak response
      currentState.value = AppState.speaking;
      statusText.value = _tr('speaking', fallback: 'Speaking...');

      // Show offline mode indicator if using fallback TTS
      if (_ttsService.isUsingOfflineMode.value) {
        statusText.value = _tr('speaking_offline', fallback: 'Speaking... (offline mode)');
      }

      await _ttsService.speak(response, lastStyle!);

      // Wait for TTS to complete
      await Future.delayed(const Duration(milliseconds: 500));
      while (_ttsService.isSpeaking.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Shift completed!
      _onShiftCompleted();
    } catch (e, stackTrace) {
      slowResponseTimer?.cancel();
      print('❌ [MIC DEBUG] Error processing input: $e');
      print('❌ [MIC DEBUG] Stack trace: $stackTrace');
      Get.snackbar('Error', _tr('ai_error', fallback: 'AI service error'));
      _resetToIdle();
    }
  }

  void _onShiftCompleted() {
    // Increment streak (handles total shifts + daily streak)
    _streakController.incrementStreak();

    // Update shift counter for ads
    _storage.incrementShiftCounter();
    _updateStats();

    // Show confetti (StreakController also shows confetti, but this is for the main shift completion)
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
    try {
      currentState.value = AppState.idle;
      statusText.value = _tr('hold_to_speak', fallback: 'Hold to Speak');
    } catch (e) {
      print('❌ [MIC DEBUG] Error in _resetToIdle: $e');
      currentState.value = AppState.idle;
      statusText.value = 'Hold to Speak';
    }
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
      _updateGoldenVoiceStatus();
      confettiController.play();
      Get.snackbar(
        '✨ Golden Voice Unlocked!',
        '1 hour of premium warm voice activated',
        backgroundColor: Colors.amber.withOpacity(0.9),
        colorText: Colors.black,
        icon: const Icon(Icons.star, color: Colors.amber),
        duration: const Duration(seconds: 3),
      );
    });
  }

  void onRemoveAds() {
    _adFreeController.activateAdFree24h(() {
      // Play confetti animation
      confettiController.play();

      // Show beautiful snackbar
      Get.snackbar(
        '🕊️ Peace Mode Activated!',
        'peace_mode_activated'.tr,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        icon: const Icon(Icons.spa_rounded, color: Colors.white),
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    });
  }

  void goToSettings() {
    Get.toNamed(AppRoutes.SETTINGS);
  }

  @override
  void onClose() {
    _goldenVoiceTimer?.cancel();
    _listeningTimeoutTimer?.cancel();
    confettiController.dispose();
    super.onClose();
  }
}

