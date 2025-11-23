import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'storage_service.dart';

class SpeechService extends GetxService {
  final SpeechToText _speech = SpeechToText();
  final StorageService _storage = Get.find<StorageService>();

  final isListening = false.obs;
  final recognizedText = ''.obs;

  late final int _listenForSeconds;
  late final int _pauseForSeconds;

  @override
  void onInit() {
    super.onInit();
    _listenForSeconds = int.tryParse(dotenv.env['SPEECH_LISTEN_FOR_SECONDS'] ?? '30') ?? 30;
    _pauseForSeconds = int.tryParse(dotenv.env['SPEECH_PAUSE_FOR_SECONDS'] ?? '3') ?? 3;
    print('🎤 [SPEECH] Listen for: ${_listenForSeconds}s, Pause for: ${_pauseForSeconds}s');
  }

  Future<bool> initialize() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    
    if (!status.isGranted) {
      Get.snackbar('Error', 'mic_permission_denied'.tr);
      return false;
    }

    // Initialize speech recognition
    final available = await _speech.initialize(
      onError: (error) {
        print('Speech recognition error: $error');
        isListening.value = false;
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
        if (status == 'done' || status == 'notListening') {
          isListening.value = false;
        }
      },
    );

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
        final languageCode = _storage.getLanguageCode();
        if (languageCode.isEmpty) {
          print('⚠️  [SPEECH DEBUG] Empty language code, using default');
        }
        final localeId = _getLocaleId(languageCode);

        print('🎤 [SPEECH DEBUG] Starting to listen with locale: $localeId (from languageCode: $languageCode)');

        await _speech.listen(
          onResult: (result) {
            try {
              recognizedText.value = result.recognizedWords;
              print('🎤 [SPEECH DEBUG] Partial result: ${result.recognizedWords} (final: ${result.finalResult})');

              if (result.finalResult) {
                isListening.value = false;
                print('✅ [SPEECH DEBUG] Final result: ${recognizedText.value}');
                if (recognizedText.value.isNotEmpty) {
                  onResult(recognizedText.value);
                } else {
                  print('⚠️  [SPEECH DEBUG] Empty final result');
                  onResult(''); // Call with empty string to trigger error handling
                }
              }
            } catch (e, stackTrace) {
              print('❌ [SPEECH DEBUG] Error in onResult callback: $e');
              print('❌ [SPEECH DEBUG] Stack trace: $stackTrace');
              isListening.value = false;
              onResult(''); // Trigger error handling
            }
          },
          localeId: localeId,
          listenMode: ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
          listenFor: Duration(seconds: _listenForSeconds),
          pauseFor: Duration(seconds: _pauseForSeconds),
        );
      } else {
        print('⚠️  [SPEECH DEBUG] Cannot start listening (available: ${_speech.isAvailable}, isListening: ${isListening.value})');
        if (isListening.value) {
          throw Exception('Already listening');
        }
      }
    } catch (e, stackTrace) {
      print('❌ [SPEECH DEBUG] Error in startListening: $e');
      print('❌ [SPEECH DEBUG] Stack trace: $stackTrace');
      isListening.value = false;
      rethrow;
    }
  }

  Future<void> stopListening() async {
    if (isListening.value) {
      print('🛑 [SPEECH DEBUG] Stopping listening');
      await _speech.stop();
      isListening.value = false;
    }
  }

  String _getLocaleId(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'en_US';
      case 'hi':
        return 'hi_IN';
      case 'es':
        return 'es_ES';
      case 'zh':
        return 'zh_CN';
      case 'fr':
        return 'fr_FR';
      case 'de':
        return 'de_DE';
      case 'ar':
        return 'ar_SA';
      case 'ja':
        return 'ja_JP';
      default:
        return 'en_US';
    }
  }

  @override
  void onClose() {
    _speech.stop();
    super.onClose();
  }
}

