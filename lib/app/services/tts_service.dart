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
    await _tts.setSpeechRate(0.42); // Reduced from 0.5 for more natural pace
    await _tts.setPitch(1.0);
  }

  Future<void> speak(String text, MoodStyle style, {Map<String, String>? prosody}) async {
    if (text.isEmpty) return;

    // Stop any ongoing speech
    await stop();

    // Set language
    final fullLocale = _storage.getFullLocale();
    await _setLanguage(fullLocale);

    // Apply LLM-provided prosody
    await _applyProsody(prosody);

    // Speak
    await _tts.speak(text);
  }

  Future<void> speakStronger(String text, MoodStyle style, {Map<String, String>? prosody}) async {
    if (text.isEmpty) return;

    await stop();

    final fullLocale = _storage.getFullLocale();
    await _setLanguage(fullLocale);

    // EXTREME 2× STRONGER - style-specific amplification
    await _tts.setVolume(1.0);

    // Get style-specific extreme settings
    final extremeSettings = _getExtremeSettings(style, prosody);

    await _tts.setSpeechRate(extremeSettings['rate']!);
    await _tts.setPitch(extremeSettings['pitch']!);

    await _tts.speak(text);
  }

  /// Get extreme settings for 2× STRONGER
  /// Style-specific amplification for maximum impact
  Map<String, double> _getExtremeSettings(MoodStyle style, Map<String, String>? prosody) {
    final baseRate = _convertRateToNumeric(prosody?['rate'] ?? 'medium');
    final basePitch = _convertPitchToNumeric(prosody?['pitch'] ?? 'medium');

    switch (style) {
      case MoodStyle.chaosEnergy:
        // CHAOS: x-fast rate, super high pitch
        return {
          'rate': (baseRate * 1.6).clamp(0.5, 1.0),
          'pitch': (basePitch * 1.5).clamp(1.2, 1.5),
        };

      case MoodStyle.gentleGrandma:
        // GENTLE: medium-fast rate, higher pitch
        return {
          'rate': (baseRate * 1.3).clamp(0.4, 0.8),
          'pitch': (basePitch * 1.4).clamp(1.1, 1.4),
        };

      case MoodStyle.permissionSlip:
      case MoodStyle.realityCheck:
      case MoodStyle.microDare:
        // DEFAULT: fast rate, high pitch
        return {
          'rate': (baseRate * 1.4).clamp(0.45, 0.9),
          'pitch': (basePitch * 1.4).clamp(1.1, 1.5),
        };
    }
  }

  Future<void> _setLanguage(String fullLocale) async {
    // fullLocale is already in format like 'en-US', 'en-GB', etc.
    await _tts.setLanguage(fullLocale);
  }

  /// Apply LLM-provided prosody settings
  Future<void> _applyProsody(Map<String, String>? prosody) async {
    final rate = _convertRateToNumeric(prosody?['rate'] ?? 'medium');
    final pitch = _convertPitchToNumeric(prosody?['pitch'] ?? 'medium');

    // Golden voice - warmer, slower, more pleasant
    if (_storage.hasGoldenVoice()) {
      await _tts.setSpeechRate(rate * 0.9);
      await _tts.setPitch(pitch * 1.1);
    } else {
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
    }
  }

  /// Convert LLM rate (slow/medium/fast) to numeric value
  double _convertRateToNumeric(String rate) {
    switch (rate.toLowerCase()) {
      case 'slow': return 0.35;
      case 'fast': return 0.50;
      case 'medium':
      default: return 0.42;
    }
  }

  /// Convert LLM pitch (low/medium/high) to numeric value
  double _convertPitchToNumeric(String pitch) {
    switch (pitch.toLowerCase()) {
      case 'low': return 0.9;
      case 'high': return 1.2;
      case 'medium':
      default: return 1.0;
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

