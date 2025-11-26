import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/ai_service.dart';
import '../../services/groq_llm_service.dart';
import '../../services/speech_service.dart';
import '../../services/polly_tts_service.dart';
import '../../services/storage_service.dart';
import '../../services/ad_service.dart';
import '../../services/remote_config_service.dart';
import '../../services/habit_service.dart';
import '../../services/crashlytics_service.dart';
import '../../controllers/ad_free_controller.dart';
import '../../controllers/streak_controller.dart';
import '../../controllers/rewarded_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/snackbar_utils.dart';

enum AppState {
  idle,
  listening,
  processing,
  speaking,
}

class HomeController extends GetxController {
  late final GroqLLMService _llmService;
  late final SpeechService _speechService;
  late final PollyTTSService _ttsService;
  late final StorageService _storage;
  late final AdService _adService;
  late final RemoteConfigService _remoteConfig;
  late final CrashlyticsService _crashlytics;
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

    // Initialize all services with error handling
    try {
      _llmService = Get.find<GroqLLMService>();
      _speechService = Get.find<SpeechService>();
      _ttsService = Get.find<PollyTTSService>();
      _storage = Get.find<StorageService>();
      _adService = Get.find<AdService>();
      _remoteConfig = Get.find<RemoteConfigService>();
      _crashlytics = Get.find<CrashlyticsService>();
      _adFreeController = Get.find<AdFreeController>();
      _streakController = Get.find<StreakController>();
      _rewardedController = Get.find<RewardedController>();

      print('✅ [HOME] All services initialized successfully');
    } catch (e, stackTrace) {
      print('❌ [HOME] Error initializing services: $e');
      print('❌ [HOME] Stack trace: $stackTrace');

      // Try to report to Crashlytics if available
      try {
        final crashlytics = Get.find<CrashlyticsService>();
        crashlytics.reportError(
          e,
          stackTrace,
          reason: 'HomeController service initialization failed',
          customKeys: {
            'error_type': 'service_initialization',
            'controller': 'HomeController',
          },
        );
      } catch (_) {
        // Crashlytics not available, continue
      }

      // Show error to user
      SnackbarUtils.showError(
        title: 'Initialization Error',
        message: 'Failed to initialize app services. Please restart the app.',
      );
      return;
    }

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
    try {
      await _speechService.initialize();
      print('✅ [HOME] Speech service initialized');
    } catch (e, stackTrace) {
      print('❌ [HOME] Error initializing speech service: $e');
      print('❌ [HOME] Stack trace: $stackTrace');

      // Report to Crashlytics
      _crashlytics.reportError(
        e,
        stackTrace,
        reason: 'Speech service initialization failed in HomeController',
        customKeys: {
          'error_type': 'speech_initialization',
          'controller': 'HomeController',
        },
      );

      // Show error to user
      SnackbarUtils.showError(
        title: 'Speech Error',
        message: 'Failed to initialize speech recognition. Voice input may not work.',
      );
    }
  }

  void _updateStats() {
    streakDay.value = _storage.getStreakDay();
    todayShifts.value = _storage.getTodayShifts();
  }

  void _checkForceUpdate() {
    // Listen to updateAvailable changes to show dialog when update is detected
    ever(_remoteConfig.updateAvailable, (isUpdateAvailable) {
      if (isUpdateAvailable) {
        print('🔧 [UPDATE] Update detected! Showing dialog...');
        _showForceUpdateDialog();
      }
    });

    // Check immediately if update is already available
    if (_remoteConfig.updateAvailable.value) {
      print('🔧 [UPDATE] Update already available on init! Showing dialog...');
      _showForceUpdateDialog();
    }
  }

  void _showForceUpdateDialog() {
    // Check if this is a force update or optional update
    final isForceUpdate = _remoteConfig.forceUpdate.value;

    Get.dialog(
      PopScope(
        canPop: !isForceUpdate, // Can't dismiss if force update
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                isForceUpdate ? Icons.warning_amber_rounded : Icons.info_outline,
                color: isForceUpdate ? Colors.orange : Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isForceUpdate ? 'update_required'.tr : 'update_available'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _remoteConfig.getUpdateMessage(),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'Latest Version: ${_remoteConfig.latestVersion.value}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            // Show "Later" button only if not force update
            if (!isForceUpdate)
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'later'.tr,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ElevatedButton(
              onPressed: _openAppStore,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'update_now'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: !isForceUpdate, // Can't dismiss by tapping outside if force update
    );
  }

  Future<void> _openAppStore() async {
    try {
      final androidUrl = dotenv.env['ANDROID_PLAY_STORE_URL'] ?? 'https://play.google.com/store/apps/details?id=com.moodshift.ai';
      final iosUrl = dotenv.env['IOS_APP_STORE_URL'] ?? 'https://apps.apple.com/app/idYOUR_APP_ID';

      final url = Platform.isAndroid ? androidUrl : iosUrl;
      final uri = Uri.parse(url);

      print('🔧 [UPDATE] Opening app store: $url');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('❌ [UPDATE] Could not launch URL: $url');
        SnackbarUtils.showError(
          title: 'Error',
          message: 'Could not open app store',
        );
      }
    } catch (e) {
      print('❌ [UPDATE] Error opening app store: $e');
      SnackbarUtils.showError(
        title: 'Error',
        message: 'Could not open app store',
      );
    }
  }

  Future<void> onMicPressed() async {
    if (currentState.value != AppState.idle) return;

    print('🎤 [MIC DEBUG] Mic pressed - starting listening immediately');

    try {
      // Start listening immediately - no delay to capture first words
      currentState.value = AppState.listening;
      statusText.value = _tr('listening', fallback: 'Listening...');
      showRewardButtons.value = false;
      showLottieAnimation.value = true;

      // Start progress tracking for listening (90 seconds max)
      _startListeningProgress();

      // Set a timeout to prevent getting stuck in listening state (90 seconds max)
      _listeningTimeoutTimer?.cancel();
      _listeningTimeoutTimer = Timer(const Duration(seconds: 90), () async {
        print('⏱️  [MIC DEBUG] Listening timeout (90s) - processing accumulated speech');
        if (currentState.value == AppState.listening) {
          // Get any accumulated text before stopping
          final accumulatedText = _speechService.recognizedText.value;
          await _speechService.stopListening();
          _stopListeningProgress();

          // Process accumulated text if available
          if (accumulatedText.isNotEmpty && accumulatedText.trim().isNotEmpty) {
            print('✅ [MIC DEBUG] Processing accumulated text from timeout: "$accumulatedText"');
            await _processUserInput(accumulatedText);
          } else {
            print('⚠️  [MIC DEBUG] No speech accumulated after 90s timeout');
            SnackbarUtils.showWarning(
              title: 'No Speech',
              message: _tr('no_speech_detected', fallback: 'No speech detected. Please try again.'),
            );
            _resetToIdle();
          }
        }
      });

      // Start listening - callback is NOT used anymore, we process manually
      await _speechService.startListening((recognizedText) async {
        // This callback is intentionally empty - we process manually on button release
        print('🎤 [MIC DEBUG] Speech callback triggered (ignored) - processing happens on button release');
      });
    } catch (e, stackTrace) {
      print('❌ [MIC DEBUG] Error starting listening: $e');
      print('❌ [MIC DEBUG] Stack trace: $stackTrace');
      _listeningTimeoutTimer?.cancel();
      _stopListeningProgress();
      SnackbarUtils.showError(
        title: 'Error',
        message: 'Failed to start listening. Please try again.',
      );
      _resetToIdle();
    }
  }

  Future<void> onMicReleased() async {
    print('🎤 [MIC DEBUG] Mic released - stopping recording and processing');
    _listeningTimeoutTimer?.cancel();
    _stopListeningProgress(); // Stop the circular progress immediately

    if (currentState.value == AppState.listening) {
      // Stop listening immediately when button is released
      await _speechService.stopListening();

      // Wait briefly for speech service to finalize (300ms)
      await Future.delayed(const Duration(milliseconds: 300));

      // Process accumulated text
      final accumulatedText = _speechService.recognizedText.value;
      if (accumulatedText.isNotEmpty && accumulatedText.trim().isNotEmpty) {
        print('✅ [MIC DEBUG] Button released - processing accumulated text: "$accumulatedText"');
        await _processUserInput(accumulatedText);
      } else {
        print('⚠️  [MIC DEBUG] No speech accumulated');
        SnackbarUtils.showWarning(
          title: 'No Speech',
          message: _tr('no_speech_detected', fallback: 'No speech detected. Please try again.'),
        );
        _resetToIdle();
      }
    }
  }

  void _startListeningProgress() {
    listeningProgress.value = 0.0;
    _listeningProgressTimer?.cancel();

    const maxSeconds = 90; // Changed to 90 seconds (1.5 minutes max)
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
        SnackbarUtils.showError(
          title: 'Error',
          message: _tr('ai_error', fallback: 'AI service error'),
        );
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
      // Report user flow error to Crashlytics
      _crashlytics.reportUserFlowError(
        e,
        stackTrace,
        flow: 'mood_shift',
        step: 'process_input',
        context: {
          'current_state': currentState.value.toString(),
          'language': _storage.getLanguageCode(),
        },
      );
      SnackbarUtils.showError(
        title: 'Error',
        message: _tr('ai_error', fallback: 'AI service error'),
      );
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
          SnackbarUtils.showCustom(
            title: '⚡ 2× POWER ACTIVATED! ⚡',
            message: 'Amplifying your response...',
            backgroundColor: const Color(0xFF7C4DFF),
            textColor: Colors.white,
            icon: Icons.bolt,
            duration: const Duration(seconds: 2),
          );

          // Set state to processing while generating
          currentState.value = AppState.processing;
          statusText.value = _tr('processing', fallback: 'Amplifying...');

          // Generate 2× stronger response from LLM with NEW PROMPT
          final languageCode = _storage.getLanguageCode();
          final strongerResponse = await _llmService.generateStrongerResponse(
            lastResponse!,
            lastStyle!,
            languageCode,
          );

          // Get prosody for stronger response
          final prosody = _llmService.getLastProsody();

          // Set state to speaking and show animation
          currentState.value = AppState.speaking;
          statusText.value = _tr('speaking', fallback: 'Speaking...');
          showLottieAnimation.value = true;

          // Estimate speaking duration for progress bar
          final wordCount = strongerResponse.split(' ').length;
          final estimatedSeconds = ((wordCount / 150) * 60).clamp(5, 30).toInt();
          final estimatedMs = estimatedSeconds * 1000;

          print('🎙️ [STRONGER] Estimated speaking time: ${estimatedSeconds}s for $wordCount words');

          // Start speaking progress
          _startSpeakingProgress(estimatedMs);

          // Play confetti
          confettiController.play();

          // Speak the stronger response with EXTREME SSML
          await _ttsService.speakStronger(strongerResponse, lastStyle!, prosody: prosody);

          // Wait for TTS to complete
          await Future.delayed(const Duration(milliseconds: 500));
          while (_ttsService.isSpeaking.value) {
            await Future.delayed(const Duration(milliseconds: 100));
          }

          // Stop speaking progress
          _stopSpeakingProgress();

          // Reset to idle
          _resetToIdle();

          print('⚡ [STRONGER] 2× stronger response played successfully');
        } catch (e) {
          print('❌ [STRONGER] Error: $e');
          _stopSpeakingProgress();
          _resetToIdle();
          SnackbarUtils.showError(
            title: 'Error',
            message: 'Failed to generate 2× stronger response',
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
      SnackbarUtils.showCustom(
        title: '🕊️ Peace Mode Activated!',
        message: 'peace_mode_activated'.tr,
        backgroundColor: const Color(0xFF4CAF50),
        textColor: Colors.white,
        icon: Icons.spa_rounded,
        duration: const Duration(seconds: 4),
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

