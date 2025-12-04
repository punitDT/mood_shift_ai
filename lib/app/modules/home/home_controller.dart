import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/speech_service.dart';
import '../../services/storage_service.dart';
import '../../services/ad_service.dart';
import '../../services/remote_config_service.dart';
import '../../services/habit_service.dart';
import '../../services/crashlytics_service.dart';
import '../../services/permission_service.dart';
import '../../services/cloud_ai_service.dart';
import '../../services/audio_player_service.dart';
import '../../controllers/ad_free_controller.dart';
import '../../controllers/streak_controller.dart';
import '../../controllers/rewarded_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/app_logger.dart';

enum AppState {
  idle,
  listening,
  processing,
  speaking,
}

class HomeController extends GetxController {
  // Services - nullable to avoid late initialization issues
  SpeechService? _speechService;
  StorageService? _storage;
  AdService? _adService;
  RemoteConfigService? _remoteConfig;
  CrashlyticsService? _crashlytics;
  PermissionService? _permissionService;
  AdFreeController? _adFreeController;
  StreakController? _streakController;
  RewardedController? _rewardedController;

  // Cloud Functions services
  CloudAIService? _cloudAIService;
  AudioPlayerService? _audioPlayerService;

  // Track if services are properly initialized
  final _servicesInitialized = false.obs;

  final currentState = AppState.idle.obs;
  final statusText = 'hold_to_speak'.obs;
  final streakDay = 1.obs;
  final todayShifts = 0.obs;
  final showRewardButtons = false.obs;

  // Circular progress tracking
  final listeningProgress = 0.0.obs;
  final speakingProgress = 0.0.obs;
  final showLottieAnimation = false.obs;

  // Confetti controller - initialized in onInit
  ConfettiController? _confettiController;
  ConfettiController get confettiController {
    _confettiController ??= ConfettiController(duration: const Duration(seconds: 3));
    return _confettiController!;
  }

  Timer? _listeningTimeoutTimer;
  Timer? _listeningProgressTimer;
  Timer? _speakingProgressTimer;

  // Guard against concurrent mic operations
  bool _isMicOperationInProgress = false;

  String? lastResponse;

  @override
  void onInit() {
    super.onInit();
    _initializeAllServices();
  }

  void _initializeAllServices() {
    try {
      _speechService = Get.find<SpeechService>();
      _storage = Get.find<StorageService>();
      _adService = Get.find<AdService>();
      _remoteConfig = Get.find<RemoteConfigService>();
      _crashlytics = Get.find<CrashlyticsService>();
      _permissionService = Get.find<PermissionService>();
      _adFreeController = Get.find<AdFreeController>();
      _streakController = Get.find<StreakController>();
      _rewardedController = Get.find<RewardedController>();

      // Cloud Functions services
      _cloudAIService = Get.find<CloudAIService>();
      _audioPlayerService = Get.find<AudioPlayerService>();

      _servicesInitialized.value = true;
    } catch (e, stackTrace) {
      _servicesInitialized.value = false;
      try {
        final crashlytics = Get.find<CrashlyticsService>();
        crashlytics.reportError(e, stackTrace,
            reason: 'HomeController service initialization failed',
            customKeys: {
              'error_type': 'service_initialization',
              'controller': 'HomeController'
            });
      } catch (_) {
        // Crashlytics not available
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
    _setupAudioPlayerListeners();
  }

  /// Check if all required services are available
  bool get _areServicesReady {
    return _servicesInitialized.value &&
        _speechService != null &&
        _storage != null &&
        _permissionService != null &&
        _cloudAIService != null &&
        _audioPlayerService != null;
  }

  void _setupAudioPlayerListeners() {
    final audioPlayer = _audioPlayerService;
    if (audioPlayer == null) return;

    // Listen for isPreparing state to update status text
    ever(audioPlayer.isPreparing, (isPreparing) {
      if (currentState.value == AppState.speaking) {
        if (isPreparing) {
          statusText.value = _tr('preparing', fallback: 'Preparing...');
        } else if (audioPlayer.isSpeaking.value) {
          if (audioPlayer.isUsingOfflineMode.value) {
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
    final storage = _storage;
    if (storage == null) return;

    streakDay.value = storage.getStreakDay();
    todayShifts.value = storage.getTodayShifts();
  }

  void _checkForceUpdate() {
    final remoteConfig = _remoteConfig;
    if (remoteConfig == null) return;

    ever(remoteConfig.updateAvailable, (isUpdateAvailable) {
      if (isUpdateAvailable) {
        _showForceUpdateDialog();
      }
    });

    if (remoteConfig.updateAvailable.value) {
      _showForceUpdateDialog();
    }
  }

  void _showForceUpdateDialog() {
    final remoteConfig = _remoteConfig;
    if (remoteConfig == null) return;

    // Check if this is a force update or optional update
    final isForceUpdate = remoteConfig.forceUpdate.value;

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
                remoteConfig.getUpdateMessage(),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'Latest Version: ${remoteConfig.latestVersion.value}',
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
    // Guard: Check if already in non-idle state
    if (currentState.value != AppState.idle) return;

    // Guard: Prevent concurrent mic operations
    if (_isMicOperationInProgress) return;
    _isMicOperationInProgress = true;

    // Guard: Check if services are ready
    if (!_areServicesReady) {
      _isMicOperationInProgress = false;
      SnackbarUtils.showError(
        title: 'Not Ready',
        message: 'App is still initializing. Please try again.',
      );
      return;
    }

    final permissionService = _permissionService;
    final speechService = _speechService;

    // Extra null check (should not happen if _areServicesReady is true)
    if (permissionService == null || speechService == null) {
      _isMicOperationInProgress = false;
      SnackbarUtils.showError(
        title: 'Error',
        message: 'Services not available. Please restart the app.',
      );
      return;
    }

    try {
      final permissionResult = await permissionService.requestPermissionsFlow();
      final hasPermission = permissionResult['granted'] ?? false;
      final justGranted = permissionResult['justGranted'] ?? false;

      if (!hasPermission) {
        _isMicOperationInProgress = false;
        return;
      }

      if (justGranted) {
        _isMicOperationInProgress = false;
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
      _listeningTimeoutTimer = Timer(const Duration(seconds: 60), () async {
        if (currentState.value == AppState.listening) {
          final accumulatedText = speechService.recognizedText.value;
          await speechService.stopListening();
          _stopListeningProgress();

          if (accumulatedText.isNotEmpty && accumulatedText.trim().isNotEmpty) {
            await _processUserInput(accumulatedText);
          } else {
            SnackbarUtils.showCustom(
              title: 'No Speech Detected',
              message: _tr('no_speech_detected', fallback: 'No speech detected. Please try again.'),
              backgroundColor: const Color(0xFF7B1FA2),
              textColor: Colors.white,
              icon: Icons.mic_off_rounded,
            );
            _resetToIdle();
          }
        }
      });

      await speechService.startListening((recognizedText) async {
        // Callback intentionally empty - processing happens on button release
      });
    } catch (e, stackTrace) {
      _listeningTimeoutTimer?.cancel();
      _stopListeningProgress();
      _crashlytics?.reportError(e, stackTrace,
          reason: 'Failed to start listening',
          customKeys: {'state': currentState.value.toString()});
      SnackbarUtils.showError(title: 'Error', message: 'Failed to start listening. Please try again.');
      _resetToIdle();
    } finally {
      // Note: We don't reset _isMicOperationInProgress here because
      // the operation continues until onMicReleased is called
    }
  }

  Future<void> onMicReleased() async {
    // Always reset the mic operation flag
    _isMicOperationInProgress = false;

    _listeningTimeoutTimer?.cancel();
    _stopListeningProgress();

    // Guard: Only process if we were actually listening
    if (currentState.value != AppState.listening) {
      return;
    }

    final speechService = _speechService;
    if (speechService == null) {
      _resetToIdle();
      return;
    }

    try {
      // Wait a bit for speech recognition to finish processing the last words
      await Future.delayed(const Duration(milliseconds: 500));
      await speechService.stopListening();
      // Additional delay to ensure final result is captured
      await Future.delayed(const Duration(milliseconds: 300));

      final accumulatedText = speechService.recognizedText.value;
      if (accumulatedText.isNotEmpty && accumulatedText.trim().isNotEmpty) {
        await _processUserInput(accumulatedText);
      } else {
        SnackbarUtils.showCustom(
          title: 'No Speech Detected',
          message: _tr('no_speech_detected', fallback: 'No speech detected. Please try again.'),
          backgroundColor: const Color(0xFF7B1FA2),
          textColor: Colors.white,
          icon: Icons.mic_off_rounded,
        );
        _resetToIdle();
      }
    } catch (e, stackTrace) {
      _crashlytics?.reportError(e, stackTrace,
          reason: 'Error in onMicReleased',
          customKeys: {'state': currentState.value.toString()});
      _resetToIdle();
    }
  }

  void _startListeningProgress() {
    listeningProgress.value = 0.0;
    _listeningProgressTimer?.cancel();

    const maxSeconds = 60; // 60 seconds max recording time
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

      final audioPlayer = _audioPlayerService;
      if (elapsed >= estimatedDurationMs || !(audioPlayer?.isSpeaking.value ?? false)) {
        timer.cancel();
        speakingProgress.value = 0.0;
      }
    });
  }

  void _stopSpeakingProgress() {
    _speakingProgressTimer?.cancel();
    speakingProgress.value = 0.0;
  }

  /// Process user input using Cloud Functions
  Future<void> _processUserInput(String userInput) async {
    Timer? slowResponseTimer;
    final cloudAI = _cloudAIService;
    final audioPlayer = _audioPlayerService;
    final storage = _storage;

    if (cloudAI == null || audioPlayer == null || storage == null) {
      SnackbarUtils.showError(
        title: 'Error',
        message: 'Services not available. Please restart the app.',
      );
      _resetToIdle();
      return;
    }

    AppLogger.userSaid(userInput);

    try {
      currentState.value = AppState.processing;
      statusText.value = _tr('processing', fallback: 'Thinking...');

      slowResponseTimer = Timer(const Duration(seconds: 3), () {
        if (currentState.value == AppState.processing) {
          statusText.value = _tr('taking_moment', fallback: 'Taking a moment...');
        }
      });

      final result = await cloudAI.processUserInput(userInput);
      slowResponseTimer.cancel();

      if (!result.success || result.response.isEmpty) {
        AppLogger.error('Cloud Function failed', result.error);
        SnackbarUtils.showError(title: 'Error', message: _tr('ai_error', fallback: 'AI service error'));
        _resetToIdle();
        return;
      }

      AppLogger.pollySaid(result.response);

      lastResponse = result.response;
      storage.setLastResponse(result.response);

      currentState.value = AppState.speaking;
      statusText.value = _tr('preparing', fallback: 'Preparing...');

      final wordCount = result.response.split(' ').length;
      final estimatedSeconds = ((wordCount / 150) * 60).clamp(5, 30).toInt();
      final estimatedMs = estimatedSeconds * 1000;

      _startSpeakingProgress(estimatedMs);

      // Play audio from Cloud Storage URL
      await audioPlayer.playFromUrl(result.audioUrl, result.response);

      _stopSpeakingProgress();
      _onShiftCompleted();
    } catch (e, stackTrace) {
      slowResponseTimer?.cancel();
      _stopSpeakingProgress();
      _crashlytics?.reportUserFlowError(e, stackTrace,
          flow: 'mood_shift_cloud',
          step: 'process_input',
          context: {'current_state': currentState.value.toString()});

      SnackbarUtils.showError(title: 'Error', message: _tr('ai_error', fallback: 'AI service error'));
      _resetToIdle();
    }
  }

  void _onShiftCompleted() {
    _streakController?.incrementStreak();
    HabitService.userDidAShiftToday();
    _storage?.incrementShiftCounter();
    _updateStats();
    confettiController.play();
    _adService?.showInterstitialAd();
    showRewardButtons.value = true;
    _resetToIdle();
    _remoteConfig?.fetchConfig();
  }

  void _resetToIdle() {
    // Reset mic operation flag
    _isMicOperationInProgress = false;

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
    final adService = _adService;
    final rewardedController = _rewardedController;
    final cloudAI = _cloudAIService;
    final audioPlayer = _audioPlayerService;

    if (adService == null) return;

    adService.showRewardedAdStronger(() async {
      // User watched ad - now generate and play 2× stronger response
      if (lastResponse != null && cloudAI != null && audioPlayer != null) {
        try {
          // Track usage (no decrement, just analytics)
          rewardedController?.useStronger();

          // Play visual effects (electric blue flash + power overlay)
          rewardedController?.playStrongerEffects();

          // Show power activated overlay
          SnackbarUtils.showCustom(
            title: '⚡ 2x Power Activated',
            message: 'Amplifying your response...',
            backgroundColor: const Color(0xFF7C4DFF),
            textColor: Colors.white,
            icon: Icons.bolt,
            duration: const Duration(seconds: 2),
          );

          // Set state to processing while generating
          currentState.value = AppState.processing;
          statusText.value = _tr('processing', fallback: 'Amplifying...');

          // Use Cloud Functions
          final result = await cloudAI.processStronger(lastResponse!);

          if (!result.success || result.response.isEmpty) {
            throw Exception('Failed to generate stronger response');
          }

          currentState.value = AppState.speaking;
          statusText.value = _tr('preparing', fallback: 'Preparing...');
          showLottieAnimation.value = true;

          final wordCount = result.response.split(' ').length;
          final estimatedSeconds = ((wordCount / 150) * 60).clamp(5, 30).toInt();
          final estimatedMs = estimatedSeconds * 1000;

          _startSpeakingProgress(estimatedMs);
          confettiController.play();

          await audioPlayer.playFromUrl(result.audioUrl, result.response);

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
    final adService = _adService;
    final rewardedController = _rewardedController;

    if (adService == null) return;

    adService.showRewardedAdCrystal(() async {
      // Activate crystal voice
      await rewardedController?.activateCrystalVoice();

      // Play confetti
      confettiController.play();
    });
  }

  void onRemoveAds() {
    final adFreeController = _adFreeController;
    if (adFreeController == null) return;

    adFreeController.activateAdFree24h(() {
      // Play confetti animation
      confettiController.play();

      // Show beautiful snackbar
      SnackbarUtils.showCustom(
        title: '🕊️ Peace Mode Activated',
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
    _confettiController?.dispose();
    super.onClose();
  }
}

