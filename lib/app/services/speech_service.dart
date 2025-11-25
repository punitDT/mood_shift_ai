import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'storage_service.dart';
import '../utils/snackbar_utils.dart';

class SpeechService extends GetxService {
  final SpeechToText _speech = SpeechToText();
  final StorageService _storage = Get.find<StorageService>();

  final isListening = false.obs;
  final recognizedText = ''.obs;

  // Maximum recording time: 90 seconds (1.5 minutes to allow for pauses)
  static const int maxRecordingSeconds = 90;

  @override
  void onInit() {
    super.onInit();
    print('🎤 [SPEECH] Max recording time: ${maxRecordingSeconds}s');
  }

  Future<bool> initialize() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    
    if (!status.isGranted) {
      SnackbarUtils.showError(
        title: 'Permission Denied',
        message: 'mic_permission_denied'.tr,
      );
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
        final fullLocale = _storage.getFullLocale();
        if (fullLocale.isEmpty) {
          print('⚠️  [SPEECH DEBUG] Empty locale, using default');
        }
        final localeId = _convertLocaleToId(fullLocale);

        print('🎤 [SPEECH DEBUG] Starting to listen with locale: $localeId (max ${maxRecordingSeconds}s)');

        await _speech.listen(
          onResult: (result) {
            try {
              // ALWAYS update recognized text continuously (for display and manual processing)
              recognizedText.value = result.recognizedWords;
              print('🎤 [SPEECH DEBUG] Partial result: ${result.recognizedWords} (final: ${result.finalResult})');

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
          localeId: localeId,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
          // Maximum recording time: 90 seconds (1.5 minutes)
          listenFor: Duration(seconds: maxRecordingSeconds),
          // Allow up to 90 seconds of pause - user controls when to stop by releasing button
          // This ensures user can pause as long as they want between sentences
          pauseFor: Duration(seconds: maxRecordingSeconds),
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

