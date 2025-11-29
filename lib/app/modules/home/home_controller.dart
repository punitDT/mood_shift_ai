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
import '../../services/permission_service.dart';
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
  late final PermissionService _permissionService;
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

    try {
      _llmService = Get.find<GroqLLMService>();
      _speechService = Get.find<SpeechService>();
      _ttsService = Get.find<PollyTTSService>();
      _storage = Get.find<StorageService>();
      _adService = Get.find<AdService>();
      _remoteConfig = Get.find<RemoteConfigService>();
      _crashlytics = Get.find<CrashlyticsService>();
      _permissionService = Get.find<PermissionService>();
      _adFreeController = Get.find<AdFreeController>();
      _streakController = Get.find<StreakController>();
      _rewardedController = Get.find<RewardedController>();
    } catch (e, stackTrace) {
      try {
        final crashlytics = Get.find<CrashlyticsService>();
        crashlytics.reportError(e, stackTrace, reason: 'HomeController service initialization failed', customKeys: {'error_type': 'service_initialization', 'controller': 'HomeController'});
      } catch (_) {
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
    _setupTTSListeners();
  }

  void _setupTTSListeners() {
    // Listen for isPreparing state to update status text
    ever(_ttsService.isPreparing, (isPreparing) {
      if (currentState.value == AppState.speaking) {
        if (isPreparing) {
          statusText.value = _tr('preparing', fallback: 'Preparing...');
        } else if (_ttsService.isSpeaking.value) {
          if (_ttsService.isUsingOfflineMode.value) {
            statusText.value = _tr('speaking_offline', fallback: 'Speaking... (offline mode)');
          } else {
            statusText.value = _tr('speaking', fallback: 'Speaking...');
          }
        }
      }
    });
  }

  String _tr(String key, {String fallback = ''}) {
    try {
      final translated = key.tr;
      return translated.isNotEmpty ? translated : (fallback.isNotEmpty ? fallback : key);
    } catch (e) {
      return fallback.isNotEmpty ? fallback : key;
    }
  }

  Future<void> _initializeServices() async {
    // Speech service initialization is now handled on-demand when mic is pressed
  }

  void _updateStats() {
    streakDay.value = _storage.getStreakDay();
    todayShifts.value = _storage.getTodayShifts();
  }

  void _checkForceUpdate() {
    ever(_remoteConfig.updateAvailable, (isUpdateAvailable) {
      if (isUpdateAvailable) {
        _showForceUpdateDialog();
      }
    });

    if (_remoteConfig.updateAvailable.value) {
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

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        SnackbarUtils.showError(title: 'Error', message: 'Could not open app store');
      }
    } catch (e) {
      SnackbarUtils.showError(title: 'Error', message: 'Could not open app store');
    }
  }

  Future<void> onMicPressed() async {
    if (currentState.value != AppState.idle) return;

    try {
      final permissionResult = await _permissionService.requestPermissionsFlow();
      final hasPermission = permissionResult['granted'] ?? false;
      final justGranted = permissionResult['justGranted'] ?? false;

      if (!hasPermission) {
        return;
      }

      if (justGranted) {
        SnackbarUtils.showSuccess(
          title: _tr('ready_to_use', fallback: 'Ready to Use'),
          message: _tr('tap_mic_again', fallback: 'Tap the mic button again to start recording'),
        );
        return;
      }

      currentState.value = AppState.listening;
      statusText.value = _tr('listening', fallback: 'Listening...');
      showRewardButtons.value = false;
      showLottieAnimation.value = true;

      _startListeningProgress();

      _listeningTimeoutTimer?.cancel();
      _listeningTimeoutTimer = Timer(const Duration(seconds: 90), () async {
        if (currentState.value == AppState.listening) {
          final accumulatedText = _speechService.recognizedText.value;
          await _speechService.stopListening();
          _stopListeningProgress();

          if (accumulatedText.isNotEmpty && accumulatedText.trim().isNotEmpty) {
            await _processUserInput(accumulatedText);
          } else {
            SnackbarUtils.showWarning(
              title: 'No Speech',
              message: _tr('no_speech_detected', fallback: 'No speech detected. Please try again.'),
            );
            _resetToIdle();
          }
        }
      });

      await _speechService.startListening((recognizedText) async {
        // Callback intentionally empty - processing happens on button release
      });
    } catch (e, stackTrace) {
      _listeningTimeoutTimer?.cancel();
      _stopListeningProgress();
      SnackbarUtils.showError(title: 'Error', message: 'Failed to start listening. Please try again.');
      _resetToIdle();
    }
  }

  Future<void> onMicReleased() async {
    _listeningTimeoutTimer?.cancel();
    _stopListeningProgress();

    if (currentState.value == AppState.listening) {
      await _speechService.stopListening();
      await Future.delayed(const Duration(milliseconds: 300));

      final accumulatedText = _speechService.recognizedText.value;
      if (accumulatedText.isNotEmpty && accumulatedText.trim().isNotEmpty) {
        await _processUserInput(accumulatedText);
      } else {
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

      final languageCode = _storage.getLanguageCode();
      final response = await _llmService.generateResponse(userInput, languageCode);
      slowResponseTimer.cancel();

      if (response.isEmpty) {
        SnackbarUtils.showError(title: 'Error', message: _tr('ai_error', fallback: 'AI service error'));
        _resetToIdle();
        return;
      }

      lastResponse = response;
      lastStyle = _llmService.getLastSelectedStyle() ?? MoodStyle.microDare;
      final prosody = _llmService.getLastProsody();
      _storage.setLastResponse(response);

      currentState.value = AppState.speaking;
      // Start with "Preparing..." - will update to "Speaking..." when audio starts
      statusText.value = _tr('preparing', fallback: 'Preparing...');

      final wordCount = response.split(' ').length;
      final estimatedSeconds = ((wordCount / 150) * 60).clamp(5, 30).toInt();
      final estimatedMs = estimatedSeconds * 1000;

      _startSpeakingProgress(estimatedMs);

      await _ttsService.speak(response, lastStyle!, prosody: prosody);

      await Future.delayed(const Duration(milliseconds: 500));
      while (_ttsService.isSpeaking.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _stopSpeakingProgress();
      _onShiftCompleted();
    } catch (e, stackTrace) {
      slowResponseTimer?.cancel();
      _stopSpeakingProgress();
      _crashlytics.reportUserFlowError(e, stackTrace, flow: 'mood_shift', step: 'process_input', context: {'current_state': currentState.value.toString(), 'language': _storage.getLanguageCode()});
      SnackbarUtils.showError(title: 'Error', message: _tr('ai_error', fallback: 'AI service error'));
      _resetToIdle();
    }
  }

  void _onShiftCompleted() {
    _streakController.incrementStreak();
    HabitService.userDidAShiftToday();
    _storage.incrementShiftCounter();
    _updateStats();
    confettiController.play();
    _adService.showInterstitialAd();
    showRewardButtons.value = true;
    _resetToIdle();
    _remoteConfig.fetchConfig();

    // Clean up audio files after shift completes
    _ttsService.cleanupAudioFiles();
  }

  void _resetToIdle() {
    try {
      currentState.value = AppState.idle;
      statusText.value = _tr('hold_to_speak', fallback: 'Hold to Speak');
      _stopListeningProgress();
      _stopSpeakingProgress();
      showLottieAnimation.value = false;
    } catch (e) {
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

          // Get prosody for stronger response (SSML is now hardcoded in TTS service)
          final prosody = _llmService.getLastProsody();

          // Set state to speaking and show animation
          currentState.value = AppState.speaking;
          // Start with "Preparing..." - will update to "Speaking..." when audio starts
          statusText.value = _tr('preparing', fallback: 'Preparing...');
          showLottieAnimation.value = true;

          final wordCount = strongerResponse.split(' ').length;
          final estimatedSeconds = ((wordCount / 150) * 60).clamp(5, 30).toInt();
          final estimatedMs = estimatedSeconds * 1000;

          _startSpeakingProgress(estimatedMs);
          confettiController.play();

          await _ttsService.speakStronger(strongerResponse, lastStyle!, prosody: prosody);

          await Future.delayed(const Duration(milliseconds: 500));
          while (_ttsService.isSpeaking.value) {
            await Future.delayed(const Duration(milliseconds: 100));
          }

          _stopSpeakingProgress();
          _resetToIdle();
        } catch (e) {
          _stopSpeakingProgress();
          _resetToIdle();
          SnackbarUtils.showError(title: 'Error', message: 'Failed to generate 2× stronger response');
        }
      }
    });
  }

  Future<void> onUnlockCrystal() async {
    _adService.showRewardedAdCrystal(() async {
      // Activate crystal voice
      await _rewardedController.activateCrystalVoice();

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

    // Clean up audio files when controller closes
    _ttsService.cleanupAudioFiles();

    super.onClose();
  }
}

