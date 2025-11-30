import 'package:get/get.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'storage_service.dart';
import 'crashlytics_service.dart';
import '../utils/app_logger.dart';

class SpeechService extends GetxService {
  // Services - nullable to avoid late initialization issues
  SpeechToText? _speech;
  StorageService? _storage;
  CrashlyticsService? _crashlytics;

  // For testing - allow dependency injection
  final SpeechToText? _injectedSpeech;
  final StorageService? _injectedStorage;
  final CrashlyticsService? _injectedCrashlytics;

  SpeechService({
    SpeechToText? speech,
    StorageService? storage,
    CrashlyticsService? crashlytics,
  })  : _injectedSpeech = speech,
        _injectedStorage = storage,
        _injectedCrashlytics = crashlytics;

  final isListening = false.obs;
  final recognizedText = ''.obs;

  // Track if service is properly initialized
  bool _isInitialized = false;

  // Available locales on the device
  List<LocaleName> _availableLocales = [];
  LocaleName? _systemLocale;

  // Maximum recording time: 60 seconds
  static const int maxRecordingSeconds = 60;

  // Continuous listening state
  bool _isActiveSession = false;
  DateTime? _sessionStartTime;
  String _accumulatedText = '';
  String? _currentLocaleId;
  bool _isRestarting = false; // Prevent overlapping restart attempts
  String _lastPartialResult = ''; // Track last partial to capture on timeout

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
  }

  void _initializeServices() {
    try {
      _speech = _injectedSpeech ?? SpeechToText();
      _storage = _injectedStorage ?? Get.find<StorageService>();
      _crashlytics = _injectedCrashlytics ?? Get.find<CrashlyticsService>();
      _isInitialized = true;
    } catch (e) {
      AppLogger.warning('🎤 Failed to initialize SpeechService dependencies: $e');
      _isInitialized = false;
    }
  }

  /// Check if service is ready to use
  bool get isReady => _isInitialized && _speech != null;

  Future<bool> initialize() async {
    final speech = _speech;
    if (speech == null) {
      AppLogger.warning('🎤 Speech service not initialized');
      return false;
    }

    try {
      final available = await speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );

      if (available) {
        _availableLocales = await speech.locales();
        _systemLocale = await speech.systemLocale();
      } else {
        _crashlytics?.reportSpeechError(
          Exception('Speech recognition not available on this device'),
          StackTrace.current,
          operation: 'initialize',
          isAvailable: false,
        );
      }

      return available;
    } catch (e, stackTrace) {
      AppLogger.warning('🎤 Failed to initialize speech: $e');
      _crashlytics?.reportSpeechError(
        e,
        stackTrace,
        operation: 'initialize',
        isAvailable: false,
      );
      return false;
    }
  }

  // Track when we last scheduled a restart to avoid duplicate restarts
  DateTime? _lastRestartScheduledAt;

  // Track the last captured partial to avoid duplicates when final result arrives after status change
  String _lastCapturedPartial = '';

  void _onStatus(String status) {
    AppLogger.info('🎤 Speech status: $status');

    if (status == 'notListening' || status == 'done') {
      // If session is still active, restart listening to handle pauses
      // But avoid duplicate restarts if we just scheduled one (within 500ms)
      if (_isActiveSession && !_isRestarting) {
        final now = DateTime.now();
        if (_lastRestartScheduledAt != null &&
            now.difference(_lastRestartScheduledAt!).inMilliseconds < 500) {
          // Skip this restart, we just scheduled one
          return;
        }
        _scheduleRestart();
      } else if (!_isActiveSession) {
        isListening.value = false;
      }
    }
  }

  void _onError(dynamic error) {
    AppLogger.warning('🎤 Speech error: $error');

    // Ignore error_client and error_speech_timeout if we're already restarting
    // These often come after notListening/done status
    final errorStr = error.toString();
    if (_isRestarting &&
        (errorStr.contains('error_client') || errorStr.contains('error_speech_timeout'))) {
      return;
    }

    // If session is still active, try to restart on error
    if (_isActiveSession && !_isRestarting) {
      // Check if we just scheduled a restart
      final now = DateTime.now();
      if (_lastRestartScheduledAt != null &&
          now.difference(_lastRestartScheduledAt!).inMilliseconds < 500) {
        // Skip this restart, we just scheduled one
        return;
      }
      _scheduleRestart(delayMs: 500); // Longer delay after error
    } else if (!_isActiveSession) {
      final speech = _speech;
      _crashlytics?.reportSpeechError(
        Exception('Speech recognition error: $error'),
        StackTrace.current,
        operation: 'onError',
        locale: _storage?.getFullLocale() ?? 'unknown',
        isAvailable: speech?.isAvailable ?? false,
      );
      isListening.value = false;
    }
  }

  Future<void> _scheduleRestart({int delayMs = 500}) async {
    if (_isRestarting || !_isActiveSession) return;

    final speech = _speech;
    if (speech == null) return;

    _isRestarting = true;
    _lastRestartScheduledAt = DateTime.now();

    // Capture any partial result that wasn't finalized before timeout
    if (_lastPartialResult.isNotEmpty) {
      AppLogger.info('🎤 Capturing partial result before restart: $_lastPartialResult');
      _lastCapturedPartial = _lastPartialResult; // Track what we captured for duplicate detection
      if (_accumulatedText.isNotEmpty) {
        _accumulatedText += ' $_lastPartialResult';
      } else {
        _accumulatedText = _lastPartialResult;
      }
      recognizedText.value = _accumulatedText;
      _lastPartialResult = '';
    }

    // Stop the current recognizer first to avoid error_busy
    try {
      if (speech.isListening) {
        await speech.stop();
      }
    } catch (e) {
      AppLogger.warning('🎤 Error stopping speech before restart: $e');
    }

    // Wait for the recognizer to fully stop - use longer delay to avoid error_client
    await Future.delayed(Duration(milliseconds: delayMs));

    _isRestarting = false;
    if (_isActiveSession) {
      _startListeningSession();
    }
  }

  Future<void> startListening(Function(String) onResult) async {
    final speech = _speech;
    final storage = _storage;

    if (speech == null) {
      throw Exception('Speech service not initialized');
    }

    try {
      if (!speech.isAvailable) {
        final initialized = await initialize();
        if (!initialized) {
          throw Exception('Speech recognition not available');
        }
      }

      if (speech.isAvailable && !_isActiveSession) {
        // Reset state for new session
        _accumulatedText = '';
        _lastPartialResult = '';
        _lastCapturedPartial = '';
        recognizedText.value = '';
        _sessionStartTime = DateTime.now();
        _isActiveSession = true;
        isListening.value = true;

        // Get locale for this session
        final fullLocale = storage?.getFullLocale() ?? 'en-US';
        final localeId = _convertLocaleToId(fullLocale);
        _currentLocaleId = _getBestMatchingLocale(localeId);

        AppLogger.info('🎤 Starting speech session | Locale: $_currentLocaleId');

        _startListeningSession();
      } else {
        if (_isActiveSession) {
          final error = Exception('Already listening');
          _crashlytics?.reportSpeechError(
            error,
            StackTrace.current,
            operation: 'startListening',
            locale: storage?.getFullLocale() ?? 'unknown',
            isAvailable: speech.isAvailable,
          );
          throw error;
        }
      }
    } catch (e, stackTrace) {
      _crashlytics?.reportSpeechError(
        e,
        stackTrace,
        operation: 'startListening',
        locale: storage?.getFullLocale() ?? 'unknown',
        isAvailable: speech.isAvailable,
      );
      _isActiveSession = false;
      isListening.value = false;
      rethrow;
    }
  }

  void _startListeningSession() {
    if (!_isActiveSession) return;

    final speech = _speech;
    if (speech == null) {
      AppLogger.warning('🎤 Cannot start listening session - speech not initialized');
      _isActiveSession = false;
      isListening.value = false;
      return;
    }

    // Check if we've exceeded the maximum recording time
    if (_sessionStartTime != null &&
        DateTime.now().difference(_sessionStartTime!).inSeconds >= maxRecordingSeconds) {
      AppLogger.info('🎤 Max recording time reached, stopping session');
      stopListening();
      return;
    }

    AppLogger.info('🎤 Starting/restarting listen session');

    try {
      speech.listen(
        onResult: _onResult,
        localeId: _currentLocaleId,
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5), // Increased to 5 seconds to capture more context and improve accuracy
      );
    } catch (e) {
      AppLogger.warning('🎤 Error starting listen session: $e');
      _isActiveSession = false;
      isListening.value = false;
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      // Append final result to accumulated text
      final newText = result.recognizedWords.trim();
      if (newText.isNotEmpty) {
        // Check if this final result was already captured as a partial
        // This can happen when status changes to notListening before final result arrives
        if (_accumulatedText.endsWith(newText)) {
          AppLogger.info('🎤 Final result already captured as partial (endsWith), skipping: $newText');
          _lastPartialResult = '';
          _lastCapturedPartial = '';
          return;
        }

        // Check if the final result starts with what we just captured as partial
        // This happens when: partial "after" captured, then final "after after Falls" arrives
        // We should only add the NEW part: "after Falls" (skip the first "after")
        if (_lastCapturedPartial.isNotEmpty && newText.startsWith(_lastCapturedPartial)) {
          final newPart = newText.substring(_lastCapturedPartial.length).trim();
          if (newPart.isEmpty) {
            AppLogger.info('🎤 Final result already captured as partial (startsWith, no new content), skipping: $newText');
            _lastPartialResult = '';
            _lastCapturedPartial = '';
            return;
          }
          // Only add the new part that wasn't captured
          AppLogger.info('🎤 Final result starts with captured partial, adding only new part: $newPart');
          _accumulatedText += ' $newPart';
          recognizedText.value = _accumulatedText;
          _lastPartialResult = '';
          _lastCapturedPartial = '';
          AppLogger.info('🎤 Final result accumulated: $_accumulatedText');
          return;
        }

        // Clear the captured partial tracker since we're processing a new final result
        _lastCapturedPartial = '';

        if (_accumulatedText.isNotEmpty) {
          _accumulatedText += ' $newText';
        } else {
          _accumulatedText = newText;
        }
        recognizedText.value = _accumulatedText;
        _lastPartialResult = ''; // Clear partial since we got final
        AppLogger.info('🎤 Final result accumulated: $_accumulatedText');
      }
    } else {
      // Track partial results
      final partialText = result.recognizedWords.trim();
      if (partialText.isNotEmpty) {
        _lastPartialResult = partialText;
        // Show partial results (accumulated + current partial)
        if (_accumulatedText.isNotEmpty) {
          recognizedText.value = '$_accumulatedText $partialText';
        } else {
          recognizedText.value = partialText;
        }
      }
    }
  }

  String _getBestMatchingLocale(String requestedLocale) {
    if (_availableLocales.isEmpty) {
      return requestedLocale;
    }

    final exactMatch = _availableLocales.firstWhere(
      (locale) => locale.localeId == requestedLocale,
      orElse: () => LocaleName('', ''),
    );

    if (exactMatch.localeId.isNotEmpty) {
      return exactMatch.localeId;
    }

    final languageCode = requestedLocale.split('_')[0];
    final languageMatch = _availableLocales.firstWhere(
      (locale) => locale.localeId.startsWith(languageCode),
      orElse: () => LocaleName('', ''),
    );

    if (languageMatch.localeId.isNotEmpty) {
      return languageMatch.localeId;
    }

    if (_systemLocale != null && _systemLocale!.localeId.isNotEmpty) {
      return _systemLocale!.localeId;
    }

    return _availableLocales.first.localeId;
  }

  Future<void> stopListening() async {
    // Capture any remaining partial result before stopping
    if (_lastPartialResult.isNotEmpty) {
      AppLogger.info('🎤 Capturing final partial before stop: $_lastPartialResult');
      if (_accumulatedText.isNotEmpty) {
        _accumulatedText += ' $_lastPartialResult';
      } else {
        _accumulatedText = _lastPartialResult;
      }
      recognizedText.value = _accumulatedText;
      _lastPartialResult = '';
    }

    AppLogger.info('🎤 Stopping speech session | Accumulated: ${recognizedText.value}');
    _isActiveSession = false;
    _isRestarting = false;
    _sessionStartTime = null;
    _currentLocaleId = null;

    final speech = _speech;
    if (speech != null && speech.isListening) {
      try {
        await speech.stop();
      } catch (e) {
        AppLogger.warning('🎤 Error stopping speech: $e');
      }
    }
    isListening.value = false;
  }

  String _convertLocaleToId(String fullLocale) {
    // Convert from 'en-US' format to 'en_US' format
    return fullLocale.replaceAll('-', '_');
  }

  @override
  void onClose() {
    _isActiveSession = false;
    _isRestarting = false;
    try {
      _speech?.stop();
    } catch (e) {
      // Ignore errors during cleanup
    }
    super.onClose();
  }
}

