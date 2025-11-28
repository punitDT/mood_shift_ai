import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'storage_service.dart';

/// Centralized service for reporting errors to Firebase Crashlytics
/// Only reports errors in release mode to avoid noise during development
class CrashlyticsService extends GetxService {
  late final StorageService _storage;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    _setUserContext();
  }

  void _setUserContext() {
    if (kReleaseMode) {
      try {
        FirebaseCrashlytics.instance.setCustomKey('voice_gender', _storage.getVoiceGender());
        FirebaseCrashlytics.instance.setCustomKey('selected_lang', _storage.getLanguageCode());
        FirebaseCrashlytics.instance.setCustomKey('current_streak', _storage.getCurrentStreak());
        FirebaseCrashlytics.instance.setCustomKey('has_crystal_voice', _storage.hasCrystalVoice());
      } catch (e) {
        // Silently fail - not critical
      }
    }
  }

  void updateUserContext() {
    _setUserContext();
  }

  void reportError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? customKeys,
    bool fatal = false,
  }) {
    if (!kReleaseMode) {
      return;
    }

    try {
      if (customKeys != null) {
        for (final entry in customKeys.entries) {
          FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value);
        }
      }

      if (reason != null) {
        FirebaseCrashlytics.instance.setCustomKey('error_reason', reason);
      }

      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: fatal,
        reason: reason,
      );
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Report LLM API errors
  void reportLLMError(
    dynamic error,
    StackTrace? stackTrace, {
    required String operation,
    String? model,
    int? statusCode,
    String? userInput,
  }) {
    reportError(
      error,
      stackTrace,
      reason: 'LLM API Error: $operation',
      customKeys: {
        'error_type': 'llm_api',
        'llm_operation': operation,
        if (model != null) 'llm_model': model,
        if (statusCode != null) 'llm_status_code': statusCode,
        if (userInput != null) 'llm_user_input_length': userInput.length,
      },
    );
  }

  /// Report TTS errors
  void reportTTSError(
    dynamic error,
    StackTrace? stackTrace, {
    required String operation,
    String? engine,
    String? voiceId,
    String? locale,
    int? textLength,
  }) {
    reportError(
      error,
      stackTrace,
      reason: 'TTS Error: $operation',
      customKeys: {
        'error_type': 'tts',
        'tts_operation': operation,
        if (engine != null) 'tts_engine': engine,
        if (voiceId != null) 'tts_voice_id': voiceId,
        if (locale != null) 'tts_locale': locale,
        if (textLength != null) 'tts_text_length': textLength,
      },
    );
  }

  /// Report Speech Recognition errors
  void reportSpeechError(
    dynamic error,
    StackTrace? stackTrace, {
    required String operation,
    String? locale,
    bool? isAvailable,
  }) {
    reportError(
      error,
      stackTrace,
      reason: 'Speech Recognition Error: $operation',
      customKeys: {
        'error_type': 'speech_recognition',
        'speech_operation': operation,
        if (locale != null) 'speech_locale': locale,
        if (isAvailable != null) 'speech_available': isAvailable,
      },
    );
  }

  /// Report network errors
  void reportNetworkError(
    dynamic error,
    StackTrace? stackTrace, {
    required String service,
    String? endpoint,
    int? statusCode,
    String? method,
  }) {
    reportError(
      error,
      stackTrace,
      reason: 'Network Error: $service',
      customKeys: {
        'error_type': 'network',
        'network_service': service,
        if (endpoint != null) 'network_endpoint': endpoint,
        if (statusCode != null) 'network_status_code': statusCode,
        if (method != null) 'network_method': method,
      },
    );
  }

  /// Report user flow errors (critical user interactions that failed)
  void reportUserFlowError(
    dynamic error,
    StackTrace? stackTrace, {
    required String flow,
    String? step,
    Map<String, dynamic>? context,
  }) {
    reportError(
      error,
      stackTrace,
      reason: 'User Flow Error: $flow',
      customKeys: {
        'error_type': 'user_flow',
        'flow_name': flow,
        if (step != null) 'flow_step': step,
        if (context != null) ...context,
      },
    );
  }

  /// Report storage/persistence errors
  void reportStorageError(
    dynamic error,
    StackTrace? stackTrace, {
    required String operation,
    String? key,
  }) {
    reportError(
      error,
      stackTrace,
      reason: 'Storage Error: $operation',
      customKeys: {
        'error_type': 'storage',
        'storage_operation': operation,
        if (key != null) 'storage_key': key,
      },
    );
  }

  void log(String message) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.log(message);
    }
  }

  Future<void> testCrashlytics() async {
    if (!kReleaseMode) {
      return;
    }

    try {
      reportError(
        Exception('Test error from CrashlyticsService'),
        StackTrace.current,
        reason: 'Crashlytics Integration Test',
        customKeys: {
          'test_type': 'integration_test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  void setCrashReportsEnabled(bool enabled) {
    try {
      FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
      _storage.setCrashReportsEnabled(enabled);
    } catch (e) {
      // Silently fail
    }
  }

  bool getCrashReportsEnabled() {
    return _storage.getCrashReportsEnabled();
  }
}
