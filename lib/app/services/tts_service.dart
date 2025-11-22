import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'storage_service.dart';
import 'ai_service.dart';

class TTSService extends GetxService {
  final FlutterTts _tts = FlutterTts();
  final StorageService _storage = Get.find<StorageService>();
  
  final isSpeaking = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    await _tts.setSharedInstance(true);
    
    _tts.setStartHandler(() {
      isSpeaking.value = true;
    });

    _tts.setCompletionHandler(() {
      isSpeaking.value = false;
    });

    _tts.setErrorHandler((msg) {
      print('TTS Error: $msg');
      isSpeaking.value = false;
    });

    // Set default values
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
  }

  Future<void> speak(String text, MoodStyle style) async {
    if (text.isEmpty) return;

    // Stop any ongoing speech
    await stop();

    // Set language
    final languageCode = _storage.getLanguageCode();
    await _setLanguage(languageCode);

    // Apply mood-based voice modulation
    await _applyMoodStyle(style);

    // Speak
    await _tts.speak(text);
  }

  Future<void> speakStronger(String text, MoodStyle style) async {
    if (text.isEmpty) return;

    await stop();

    final languageCode = _storage.getLanguageCode();
    await _setLanguage(languageCode);

    // Make it 2x stronger - increase volume, rate, and pitch
    await _tts.setVolume(1.0);
    
    // Get base values for style
    final baseRate = _getMoodRate(style);
    final basePitch = _getMoodPitch(style);
    
    // Amplify by 1.3x (not too much to avoid distortion)
    await _tts.setSpeechRate((baseRate * 1.3).clamp(0.3, 1.0));
    await _tts.setPitch((basePitch * 1.3).clamp(0.8, 1.5));

    await _tts.speak(text);
  }

  Future<void> _setLanguage(String languageCode) async {
    String language;
    
    switch (languageCode) {
      case 'en':
        language = 'en-US';
        break;
      case 'hi':
        language = 'hi-IN';
        break;
      case 'es':
        language = 'es-ES';
        break;
      case 'zh':
        language = 'zh-CN';
        break;
      case 'fr':
        language = 'fr-FR';
        break;
      case 'de':
        language = 'de-DE';
        break;
      case 'ar':
        language = 'ar-SA';
        break;
      case 'ja':
        language = 'ja-JP';
        break;
      default:
        language = 'en-US';
    }

    await _tts.setLanguage(language);
  }

  Future<void> _applyMoodStyle(MoodStyle style) async {
    final rate = _getMoodRate(style);
    final pitch = _getMoodPitch(style);
    
    // Golden voice - warmer, slower, more pleasant
    if (_storage.hasGoldenVoice()) {
      await _tts.setSpeechRate(rate * 0.9);
      await _tts.setPitch(pitch * 1.1);
    } else {
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
    }
  }

  double _getMoodRate(MoodStyle style) {
    switch (style) {
      case MoodStyle.chaosEnergy:
        return 0.65; // Fast, energetic
      case MoodStyle.gentleGrandma:
        return 0.4; // Slow, calming
      case MoodStyle.permissionSlip:
        return 0.5; // Moderate, formal
      case MoodStyle.realityCheck:
        return 0.55; // Steady, clear
      case MoodStyle.microDare:
        return 0.6; // Quick, actionable
    }
  }

  double _getMoodPitch(MoodStyle style) {
    switch (style) {
      case MoodStyle.chaosEnergy:
        return 1.2; // Higher, excited
      case MoodStyle.gentleGrandma:
        return 0.9; // Lower, soothing
      case MoodStyle.permissionSlip:
        return 1.0; // Normal, official
      case MoodStyle.realityCheck:
        return 1.0; // Normal, honest
      case MoodStyle.microDare:
        return 1.1; // Slightly higher, motivating
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    isSpeaking.value = false;
  }

  @override
  void onClose() {
    _tts.stop();
    super.onClose();
  }
}

