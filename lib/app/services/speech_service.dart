import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';

class SpeechService extends GetxService {
  final SpeechToText _speech = SpeechToText();
  final StorageService _storage = Get.find<StorageService>();
  
  final isListening = false.obs;
  final recognizedText = ''.obs;

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
    if (!_speech.isAvailable) {
      await initialize();
    }

    if (_speech.isAvailable && !isListening.value) {
      recognizedText.value = '';
      isListening.value = true;

      // Get user's language
      final languageCode = _storage.getLanguageCode();
      final localeId = _getLocaleId(languageCode);

      await _speech.listen(
        onResult: (result) {
          recognizedText.value = result.recognizedWords;
          
          if (result.finalResult) {
            isListening.value = false;
            if (recognizedText.value.isNotEmpty) {
              onResult(recognizedText.value);
            }
          }
        },
        localeId: localeId,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      );
    }
  }

  Future<void> stopListening() async {
    if (isListening.value) {
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

