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

  // Accumulated text across multiple recognition sessions (for auto-restart on pause)
  String _accumulatedText = '';

  // Available locales on the device
  List<LocaleName> _availableLocales = [];
  LocaleName? _systemLocale;

  // Maximum recording time: 90 seconds (1.5 minutes to allow for pauses)
  static const int maxRecordingSeconds = 90;

  @override
  void onInit() {
    super.onInit();
    _crashlytics = Get.find<CrashlyticsService>();
  }

  Future<bool> initialize() async {
    final available = await _speech.initialize(
      onError: (error) {
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
        if (status == 'done' || status == 'notListening') {
          isListening.value = false;
        }
      },
    );

    if (available) {
      _availableLocales = await _speech.locales();
      _systemLocale = await _speech.systemLocale();
    } else {
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
        final initialized = await initialize();
        if (!initialized) {
          throw Exception('Speech recognition not available');
        }
      }

      if (_speech.isAvailable && !isListening.value) {
        recognizedText.value = '';
        _accumulatedText = '';
        isListening.value = true;

        final fullLocale = _storage.getFullLocale();
        final localeId = _convertLocaleToId(fullLocale);
        final bestLocale = _getBestMatchingLocale(localeId);

        await _speech.listen(
          onResult: (result) {
            try {
              if (result.finalResult) {
                // When result is final, accumulate it
                if (result.recognizedWords.isNotEmpty) {
                  if (_accumulatedText.isNotEmpty) {
                    _accumulatedText += ' ${result.recognizedWords}';
                  } else {
                    _accumulatedText = result.recognizedWords;
                  }
                  recognizedText.value = _accumulatedText;
                }
              } else {
                // For partial results, show accumulated + current
                if (_accumulatedText.isNotEmpty) {
                  recognizedText.value = '$_accumulatedText ${result.recognizedWords}';
                } else {
                  recognizedText.value = result.recognizedWords;
                }
              }
            } catch (e, stackTrace) {
              _crashlytics.reportSpeechError(
                e,
                stackTrace,
                operation: 'onResult',
                locale: _storage.getFullLocale(),
                isAvailable: _speech.isAvailable,
              );
            }
          },
          localeId: bestLocale,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
          listenFor: Duration(seconds: maxRecordingSeconds),
          pauseFor: Duration(seconds: maxRecordingSeconds),
        );
      } else {
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
    if (isListening.value) {
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

