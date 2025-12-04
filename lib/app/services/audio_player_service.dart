import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'storage_service.dart';
import 'crashlytics_service.dart';
import '../utils/app_logger.dart';

/// Service to play audio from Cloud Storage URLs
/// Falls back to device TTS if URL playback fails
class AudioPlayerService extends GetxService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _fallbackTts = FlutterTts();
  late final StorageService _storage;
  late final CrashlyticsService _crashlytics;

  final isSpeaking = false.obs;
  final isPreparing = false.obs;
  final isUsingOfflineMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    _crashlytics = Get.find<CrashlyticsService>();
    _setupAudioPlayer();
    _initializeFallbackTTS();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        isSpeaking.value = true;
        isPreparing.value = false;
      } else if (state == PlayerState.completed || state == PlayerState.stopped) {
        isSpeaking.value = false;
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      isSpeaking.value = false;
    });
  }

  Future<void> _initializeFallbackTTS() async {
    await _fallbackTts.setSharedInstance(true);

    _fallbackTts.setStartHandler(() {
      isSpeaking.value = true;
    });

    _fallbackTts.setCompletionHandler(() {
      isSpeaking.value = false;
    });

    _fallbackTts.setErrorHandler((msg) {
      isSpeaking.value = false;
    });

    await _fallbackTts.setVolume(1.0);
    await _fallbackTts.setSpeechRate(0.42);
    await _fallbackTts.setPitch(1.0);
  }

  /// Play audio from a Cloud Storage signed URL
  /// Falls back to device TTS if URL playback fails
  Future<void> playFromUrl(String audioUrl, String fallbackText) async {
    if (audioUrl.isEmpty) {
      AppLogger.info('🔊 No audio URL, using fallback TTS');
      await _speakWithFallback(fallbackText);
      return;
    }

    await stop();
    isPreparing.value = true;
    isUsingOfflineMode.value = false;

    try {
      AppLogger.info('🔊 Playing audio from URL: ${audioUrl.substring(0, 50)}...');
      
      await _audioPlayer.play(UrlSource(audioUrl));
      isPreparing.value = false;
      
      // Wait for playback to complete
      await Future.delayed(const Duration(milliseconds: 500));
      while (isSpeaking.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e, stackTrace) {
      isPreparing.value = false;
      AppLogger.error('Audio URL playback failed', e, stackTrace);
      _crashlytics.reportError(e, stackTrace, reason: 'Audio URL playback failed');
      
      // Fallback to device TTS
      isUsingOfflineMode.value = true;
      await _speakWithFallback(fallbackText);
    }
  }

  Future<void> _speakWithFallback(String text) async {
    if (text.isEmpty) return;

    isUsingOfflineMode.value = true;
    final fullLocale = _storage.getFullLocale();
    
    await _fallbackTts.setLanguage(fullLocale);
    await _fallbackTts.speak(text);
    
    // Wait for TTS to complete
    await Future.delayed(const Duration(milliseconds: 500));
    while (isSpeaking.value) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Stop any currently playing audio
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _fallbackTts.stop();
    isSpeaking.value = false;
    isPreparing.value = false;
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    _fallbackTts.stop();
    super.onClose();
  }
}

