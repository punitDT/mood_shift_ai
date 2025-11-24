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
import '../../services/habit_service.dart';
import '../../controllers/ad_free_controller.dart';
import '../../controllers/streak_controller.dart';
import '../../controllers/rewarded_controller.dart';
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
  late final RewardedController _rewardedController;

  final currentState = AppState.idle.obs;
  final statusText = 'hold_to_speak'.obs;
  final streakDay = 1.obs;
  final todayShifts = 0.obs;
  final showRewardButtons = false.obs;

  // Circular progress tracking
  final listeningProgress = 0.0.obs;
  final speakingProgress = 0.0.obs;
  final showLottieAnimation = false.obs;

  late ConfettiController confettiController;
  Timer? _listeningTimeoutTimer;
  Timer? _listeningProgressTimer;
  Timer? _speakingProgressTimer;

  String? lastResponse;
  MoodStyle? lastStyle;

  @override
  void onInit() {
    super.onInit();
    confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _adFreeController = Get.find<AdFreeController>();
    _streakController = Get.find<StreakController>();
    _rewardedController = Get.find<RewardedController>();
    _initializeServices();
    _updateStats();
    _checkForceUpdate();
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
      // Show Lottie animation for 1 second
      showLottieAnimation.value = true;
      await Future.delayed(const Duration(milliseconds: 1000));
      showLottieAnimation.value = false;

      currentState.value = AppState.listening;
      statusText.value = _tr('listening', fallback: 'Listening...');
      showRewardButtons.value = false;

      // Start circular progress for listening (60 seconds max)
      _startListeningProgress();

      // Set a timeout to prevent getting stuck in listening state (60 seconds max)
      _listeningTimeoutTimer?.cancel();
      _listeningTimeoutTimer = Timer(const Duration(seconds: 60), () {
        print('⏱️  [MIC DEBUG] Listening timeout (60s) - stopping recording');
        if (currentState.value == AppState.listening) {
          _speechService.stopListening();
          // The callback will be triggered by stopListening, which will process the text
        }
      });

      await _speechService.startListening((recognizedText) async {
        print('🎤 [MIC DEBUG] Speech callback triggered with: "$recognizedText"');
        _listeningTimeoutTimer?.cancel();
        _stopListeningProgress();

        if (recognizedText.isEmpty || recognizedText.trim().length < 2) {
          print('⚠️  [MIC DEBUG] Empty or too short speech detected, resetting to idle');
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
      _stopListeningProgress();
      Get.snackbar('Error', 'Failed to start listening. Please try again.');
      _resetToIdle();
    }
  }

  Future<void> onMicReleased() async {
    print('🎤 [MIC DEBUG] Mic released - stopping recording');
    _listeningTimeoutTimer?.cancel();
    _stopListeningProgress(); // Stop the circular progress immediately

    if (currentState.value == AppState.listening) {
      // Mark that we're waiting for a result
      bool callbackReceived = false;

      // Store the current state to check later
      final stateBeforeStop = currentState.value;

      // Stop listening immediately when button is released
      await _speechService.stopListening();
      // The callback in startListening will be triggered with the final result

      // Safety timeout: If no result is received within 1.5 seconds, reset to idle
      // This prevents the app from getting stuck when no speech is detected
      Future.delayed(const Duration(milliseconds: 1500), () {
        // If state hasn't changed from listening, it means callback was never called
        if (currentState.value == stateBeforeStop && currentState.value == AppState.listening) {
          print('⚠️  [MIC DEBUG] No speech result received after 1.5s, resetting to idle');
          Get.snackbar('Info', _tr('no_speech_detected', fallback: 'No speech detected'));
          _resetToIdle();
        }
      });
    }
  }

  void _startListeningProgress() {
    listeningProgress.value = 0.0;
    _listeningProgressTimer?.cancel();

    const maxSeconds = 60; // Changed to 60 seconds (1 minute max)
    const updateInterval = 100; // Update every 100ms
    var elapsed = 0;

    _listeningProgressTimer = Timer.periodic(const Duration(milliseconds: updateInterval), (timer) {
      elapsed += updateInterval;
      listeningProgress.value = (elapsed / (maxSeconds * 1000)).clamp(0.0, 1.0);

      if (elapsed >= maxSeconds * 1000) {
        timer.cancel();
      }
    });
  }

  void _stopListeningProgress() {
    _listeningProgressTimer?.cancel();
    listeningProgress.value = 0.0;
  }

  void _startSpeakingProgress(int estimatedDurationMs) {
    speakingProgress.value = 0.0;
    _speakingProgressTimer?.cancel();

    const updateInterval = 100; // Update every 100ms
    var elapsed = 0;

    _speakingProgressTimer = Timer.periodic(const Duration(milliseconds: updateInterval), (timer) {
      elapsed += updateInterval;
      speakingProgress.value = (elapsed / estimatedDurationMs).clamp(0.0, 1.0);

      if (elapsed >= estimatedDurationMs || !_ttsService.isSpeaking.value) {
        timer.cancel();
        speakingProgress.value = 0.0;
      }
    });
  }

  void _stopSpeakingProgress() {
    _speakingProgressTimer?.cancel();
    speakingProgress.value = 0.0;
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

      // Get AI response from Groq (with history tracking built-in)
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
      lastStyle = _llmService.getLastSelectedStyle() ?? MoodStyle.microDare;
      final prosody = _llmService.getLastProsody();
      _storage.setLastResponse(response);

      // Speak response
      currentState.value = AppState.speaking;
      statusText.value = _tr('speaking', fallback: 'Speaking...');

      // Show offline mode indicator if using fallback TTS
      if (_ttsService.isUsingOfflineMode.value) {
        statusText.value = _tr('speaking_offline', fallback: 'Speaking... (offline mode)');
      }

      // Estimate speaking duration (30 seconds max, ~150 words per minute)
      final wordCount = response.split(' ').length;
      final estimatedSeconds = ((wordCount / 150) * 60).clamp(5, 30).toInt();
      final estimatedMs = estimatedSeconds * 1000;

      print('🎙️ [TTS DEBUG] Estimated speaking time: ${estimatedSeconds}s for $wordCount words');

      // Start speaking progress
      _startSpeakingProgress(estimatedMs);

      await _ttsService.speak(response, lastStyle!, prosody: prosody);

      // Wait for TTS to complete
      await Future.delayed(const Duration(milliseconds: 500));
      while (_ttsService.isSpeaking.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Stop speaking progress
      _stopSpeakingProgress();

      // Shift completed!
      _onShiftCompleted();
    } catch (e, stackTrace) {
      slowResponseTimer?.cancel();
      _stopSpeakingProgress();
      print('❌ [MIC DEBUG] Error processing input: $e');
      print('❌ [MIC DEBUG] Stack trace: $stackTrace');
      Get.snackbar('Error', _tr('ai_error', fallback: 'AI service error'));
      _resetToIdle();
    }
  }

  void _onShiftCompleted() {
    // Increment streak FIRST (handles total shifts + daily streak)
    // IMPORTANT: Must be called before HabitService.userDidAShiftToday()
    // because incrementStreak() checks hasShiftedToday() which relies on last_shift_date
    _streakController.incrementStreak();

    // Record shift in HabitService (new smart tracking system)
    HabitService.userDidAShiftToday();

    // Update shift counter for ads
    print('🎯 [SHIFT DEBUG] Counter BEFORE increment: ${_storage.getShiftCounter()}');
    _storage.incrementShiftCounter();
    print('🎯 [SHIFT DEBUG] Counter AFTER increment: ${_storage.getShiftCounter()}');
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

      // Clean up all timers and progress
      _stopListeningProgress();
      _stopSpeakingProgress();
      showLottieAnimation.value = false;
    } catch (e) {
      print('❌ [MIC DEBUG] Error in _resetToIdle: $e');
      currentState.value = AppState.idle;
      statusText.value = 'Hold to Speak';
    }
  }

  // Rewarded Ad Actions
  Future<void> onMakeStronger() async {
    // UNLIMITED! No limit checks - users can spam this as much as they want
    // More rewarded ads = more revenue!

    _adService.showRewardedAdStronger(() async {
      // User watched ad - now generate and play 2× stronger response
      if (lastResponse != null && lastStyle != null) {
        try {
          // Track usage (no decrement, just analytics)
          _rewardedController.useStronger();

          // Play visual effects (electric blue flash + power overlay)
          _rewardedController.playStrongerEffects();

          // Show power activated overlay
          Get.snackbar(
            '⚡ 2× POWER ACTIVATED! ⚡',
            'Amplifying your response...',
            backgroundColor: const Color(0xFF0099FF).withOpacity(0.9), // Electric blue
            colorText: Colors.white,
            icon: const Icon(Icons.bolt, color: Colors.white),
            duration: const Duration(seconds: 2),
          );

          // Generate 2× stronger response from LLM with NEW PROMPT
          final languageCode = _storage.getLanguageCode();
          final strongerResponse = await _llmService.generateStrongerResponse(
            lastResponse!,
            lastStyle!,
            languageCode,
          );

          // Get prosody for stronger response
          final prosody = _llmService.getLastProsody();

          // Play confetti
          confettiController.play();

          // Speak the stronger response with EXTREME SSML
          await _ttsService.speakStronger(strongerResponse, lastStyle!, prosody: prosody);

          print('⚡ [STRONGER] 2× stronger response played successfully');
        } catch (e) {
          print('❌ [STRONGER] Error: $e');
          Get.snackbar(
            'Error',
            'Failed to generate 2× stronger response',
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
          );
        }
      }
    });
  }

  Future<void> onUnlockGolden() async {
    _adService.showRewardedAdGolden(() async {
      // Activate golden voice
      await _rewardedController.activateGoldenVoice();

      // Play confetti
      confettiController.play();
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
    _listeningTimeoutTimer?.cancel();
    _listeningProgressTimer?.cancel();
    _speakingProgressTimer?.cancel();
    confettiController.dispose();
    super.onClose();
  }
}

