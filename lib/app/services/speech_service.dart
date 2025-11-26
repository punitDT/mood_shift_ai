import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';
import 'crashlytics_service.dart';
import '../utils/snackbar_utils.dart';

class SpeechService extends GetxService {
  final SpeechToText _speech = SpeechToText();
  final StorageService _storage = Get.find<StorageService>();
  late final CrashlyticsService _crashlytics;

  final isListening = false.obs;
  final recognizedText = ''.obs;

  // Available locales on the device
  List<LocaleName> _availableLocales = [];
  LocaleName? _systemLocale;

  // Maximum recording time: 90 seconds (1.5 minutes to allow for pauses)
  static const int maxRecordingSeconds = 90;

  @override
  void onInit() {
    super.onInit();
    _crashlytics = Get.find<CrashlyticsService>();
    print('🎤 [SPEECH] Max recording time: ${maxRecordingSeconds}s');
  }

  Future<bool> initialize() async {
    // NOTE: Permission is now handled by PermissionService (2025 compliance)
    // This method only initializes the speech recognition engine

    // Initialize speech recognition
    final available = await _speech.initialize(
      onError: (error) {
        print('❌ [SPEECH ERROR] Speech recognition error: $error');
        // Report speech recognition error to Crashlytics
        _crashlytics.reportSpeechError(
          Exception('Speech recognition error: $error'),
          StackTrace.current,
          operation: 'onError',
          locale: _storage.getFullLocale(),
          isAvailable: _speech.isAvailable,
        );
        isListening.value = false;
      },
      onStatus: (status) {
        print('📊 [SPEECH STATUS] Speech recognition status: $status');
        if (status == 'done' || status == 'notListening') {
          isListening.value = false;
        }
      },
    );

    if (available) {
      // Get available locales
      _availableLocales = await _speech.locales();
      _systemLocale = await _speech.systemLocale();

      print('🌍 [SPEECH] Available locales: ${_availableLocales.length}');
      print('🌍 [SPEECH] System locale: ${_systemLocale?.localeId}');

      // Print first few locales for debugging
      if (_availableLocales.isNotEmpty) {
        final firstFew = _availableLocales.take(5).map((l) => l.localeId).join(', ');
        print('🌍 [SPEECH] Sample locales: $firstFew');
      }
    } else {
      print('❌ [SPEECH] Speech recognition not available on this device');
      // Report that speech recognition is not available
      _crashlytics.reportSpeechError(
        Exception('Speech recognition not available on this device'),
        StackTrace.current,
        operation: 'initialize',
        isAvailable: false,
      );
    }

    return available;
  }

  Future<void> startListening(Function(String) onResult) async {
    try {
      if (!_speech.isAvailable) {
        print('🎤 [SPEECH DEBUG] Speech not available, initializing...');
        final initialized = await initialize();
        if (!initialized) {
          print('❌ [SPEECH DEBUG] Failed to initialize speech recognition');
          throw Exception('Speech recognition not available');
        }
      }

      if (_speech.isAvailable && !isListening.value) {
        recognizedText.value = '';
        isListening.value = true;

        // Get user's language with null safety
        final fullLocale = _storage.getFullLocale();
        if (fullLocale.isEmpty) {
          print('⚠️  [SPEECH DEBUG] Empty locale, using default');
        }
        final localeId = _convertLocaleToId(fullLocale);

        // Validate and get best matching locale
        final bestLocale = _getBestMatchingLocale(localeId);

        print('🎤 [SPEECH DEBUG] Requested locale: $localeId');
        print('🎤 [SPEECH DEBUG] Using locale: $bestLocale (max ${maxRecordingSeconds}s)');
        print('🎤 [SPEECH DEBUG] System locale: ${_systemLocale?.localeId}');

        await _speech.listen(
          onResult: (result) {
            try {
              // ALWAYS update recognized text continuously (for display and manual processing)
              recognizedText.value = result.recognizedWords;

              if (result.recognizedWords.isNotEmpty) {
                print('🎤 [SPEECH DEBUG] Partial result: "${result.recognizedWords}" (final: ${result.finalResult})');
              }

              // COMPLETELY IGNORE finalResult - we process manually in controller
              // This prevents premature processing during pauses
              if (result.finalResult) {
                print('🔄 [SPEECH DEBUG] Ignoring finalResult - waiting for user to release button');
              }
            } catch (e, stackTrace) {
              print('❌ [SPEECH DEBUG] Error in onResult callback: $e');
              print('❌ [SPEECH DEBUG] Stack trace: $stackTrace');
            }
          },
          localeId: bestLocale,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
          // Maximum recording time: 90 seconds (1.5 minutes)
          listenFor: Duration(seconds: maxRecordingSeconds),
          // Allow up to 90 seconds of pause - user controls when to stop by releasing button
          // This ensures user can pause as long as they want between sentences
          pauseFor: Duration(seconds: maxRecordingSeconds),
        );

        print('✅ [SPEECH DEBUG] Listen command sent successfully');
      } else {
        print('⚠️  [SPEECH DEBUG] Cannot start listening (available: ${_speech.isAvailable}, isListening: ${isListening.value})');
        if (isListening.value) {
          final error = Exception('Already listening');
          _crashlytics.reportSpeechError(
            error,
            StackTrace.current,
            operation: 'startListening',
            locale: _storage.getFullLocale(),
            isAvailable: _speech.isAvailable,
          );
          throw error;
        }
      }
    } catch (e, stackTrace) {
      print('❌ [SPEECH DEBUG] Error in startListening: $e');
      print('❌ [SPEECH DEBUG] Stack trace: $stackTrace');
      // Report speech error to Crashlytics
      _crashlytics.reportSpeechError(
        e,
        stackTrace,
        operation: 'startListening',
        locale: _storage.getFullLocale(),
        isAvailable: _speech.isAvailable,
      );
      isListening.value = false;
      rethrow;
    }
  }

  /// Get the best matching locale from available locales
  /// Falls back to system locale or first available locale if requested locale not found
  String _getBestMatchingLocale(String requestedLocale) {
    // If no locales available, return requested locale (will use system default)
    if (_availableLocales.isEmpty) {
      print('⚠️  [SPEECH] No available locales, using requested: $requestedLocale');
      return requestedLocale;
    }

    // Try exact match first
    final exactMatch = _availableLocales.firstWhere(
      (locale) => locale.localeId == requestedLocale,
      orElse: () => LocaleName('', ''),
    );

    if (exactMatch.localeId.isNotEmpty) {
      print('✅ [SPEECH] Found exact match: ${exactMatch.localeId}');
      return exactMatch.localeId;
    }

    // Try language-only match (e.g., 'en' for 'en_US')
    final languageCode = requestedLocale.split('_')[0];
    final languageMatch = _availableLocales.firstWhere(
      (locale) => locale.localeId.startsWith(languageCode),
      orElse: () => LocaleName('', ''),
    );

    if (languageMatch.localeId.isNotEmpty) {
      print('✅ [SPEECH] Found language match: ${languageMatch.localeId} for $requestedLocale');
      return languageMatch.localeId;
    }

    // Fall back to system locale
    if (_systemLocale != null && _systemLocale!.localeId.isNotEmpty) {
      print('⚠️  [SPEECH] No match found, using system locale: ${_systemLocale!.localeId}');
      return _systemLocale!.localeId;
    }

    // Last resort: use first available locale
    final fallback = _availableLocales.first.localeId;
    print('⚠️  [SPEECH] No match found, using first available: $fallback');
    return fallback;
  }

  Future<void> stopListening() async {
    if (isListening.value) {
      print('🛑 [SPEECH DEBUG] Stopping listening');
      await _speech.stop();
      isListening.value = false;
    }
  }

  String _convertLocaleToId(String fullLocale) {
    // Convert from 'en-US' format to 'en_US' format
    return fullLocale.replaceAll('-', '_');
  }

  @override
  void onClose() {
    _speech.stop();
    super.onClose();
  }
}

