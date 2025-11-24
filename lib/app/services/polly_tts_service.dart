import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'storage_service.dart';
import 'ai_service.dart';

class PollyTTSService extends GetxService {
  final FlutterTts _fallbackTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StorageService _storage = Get.find<StorageService>();

  final isSpeaking = false.obs;
  final isUsingOfflineMode = false.obs;

  late final String _awsAccessKey;
  late final String _awsSecretKey;
  late final String _awsRegion;
  late final String _pollyEngine;
  late final String _pollyOutputFormat;
  late final int _pollyTimeoutSeconds;
  late final int _pollyCacheMaxFiles;

  String? _cacheDir;

  @override
  void onInit() {
    super.onInit();
    _awsAccessKey = dotenv.env['AWS_ACCESS_KEY'] ?? '';
    _awsSecretKey = dotenv.env['AWS_SECRET_KEY'] ?? '';
    _awsRegion = dotenv.env['AWS_REGION'] ?? 'ap-south-1';
    _pollyEngine = dotenv.env['AWS_POLLY_ENGINE'] ?? 'neural';
    _pollyOutputFormat = dotenv.env['AWS_POLLY_OUTPUT_FORMAT'] ?? 'mp3';
    _pollyTimeoutSeconds = int.tryParse(dotenv.env['AWS_POLLY_TIMEOUT_SECONDS'] ?? '10') ?? 10;
    _pollyCacheMaxFiles = int.tryParse(dotenv.env['AWS_POLLY_CACHE_MAX_FILES'] ?? '20') ?? 20;

    if (_awsAccessKey.isEmpty || _awsSecretKey.isEmpty) {
      print('⚠️ [POLLY] Warning: AWS credentials not found in .env');
    }

    print('🎙️ [POLLY] Engine: $_pollyEngine, Format: $_pollyOutputFormat, Timeout: ${_pollyTimeoutSeconds}s');
    print('💾 [POLLY] Cache max files: $_pollyCacheMaxFiles');

    _initializeFallbackTTS();
    _initializeCacheDir();
    _setupAudioPlayer();
  }

  Future<void> _initializeCacheDir() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _cacheDir = '${dir.path}/polly_cache';
      await Directory(_cacheDir!).create(recursive: true);
      print('📁 [POLLY] Cache directory: $_cacheDir');
    } catch (e) {
      print('❌ [POLLY] Error creating cache dir: $e');
    }
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
      print('❌ [POLLY] Fallback TTS Error: $msg');
      isSpeaking.value = false;
    });

    await _fallbackTts.setVolume(1.0);
    await _fallbackTts.setSpeechRate(0.42); // Reduced from 0.5 for more natural pace
    await _fallbackTts.setPitch(1.0);
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        isSpeaking.value = true;
      } else if (state == PlayerState.completed || state == PlayerState.stopped) {
        isSpeaking.value = false;
      }
    });
  }

  Future<void> speak(String text, MoodStyle style, {Map<String, String>? prosody}) async {
    if (text.isEmpty) return;

    await stop();

    final languageCode = _storage.getLanguageCode();
    final gender = _storage.getVoiceGender();
    final isGolden = _storage.hasGoldenVoice();
    final cacheKey = _getCacheKey(text, languageCode, style, gender: gender, isGolden: isGolden);
    final cachedFile = await _getCachedAudio(cacheKey);

    // Try to use cached audio first
    if (cachedFile != null) {
      print('🎵 [POLLY] Using cached audio');
      await _playAudioFile(cachedFile);
      return;
    }

    // Try Amazon Polly
    try {
      final audioFile = await _synthesizeWithPolly(text, languageCode, style, prosody: prosody);
      if (audioFile != null) {
        await _cacheAudio(cacheKey, audioFile);
        await _playAudioFile(audioFile);
        isUsingOfflineMode.value = false;
        return;
      }
    } catch (e) {
      print('❌ [POLLY] Polly synthesis failed: $e');
    }

    // Fallback to flutter_tts
    print('🔄 [POLLY] Using flutter_tts fallback');
    isUsingOfflineMode.value = true;
    await _speakWithFallback(text, languageCode, style, prosody: prosody);
  }

  /// Speak with 2× STRONGER amplification
  /// Uses SSML for Polly or amplified settings for fallback TTS
  Future<void> speakStronger(String text, MoodStyle style, {Map<String, String>? prosody}) async {
    if (text.isEmpty) return;

    await stop();

    final languageCode = _storage.getLanguageCode();
    final gender = _storage.getVoiceGender();
    final cacheKey = _getCacheKey(text, languageCode, style, gender: gender, isStronger: true);
    final cachedFile = await _getCachedAudio(cacheKey);

    // Try to use cached audio first
    if (cachedFile != null) {
      print('🎵 [POLLY] Using cached 2× STRONGER audio');
      await _playAudioFile(cachedFile);
      return;
    }

    // Try Amazon Polly with 2× STRONGER SSML
    try {
      final audioFile = await _synthesizeStrongerWithPolly(text, languageCode, style);
      if (audioFile != null) {
        await _cacheAudio(cacheKey, audioFile);
        await _playAudioFile(audioFile);
        isUsingOfflineMode.value = false;
        return;
      }
    } catch (e) {
      print('❌ [POLLY] Polly 2× stronger synthesis failed: $e');
    }

    // Fallback to flutter_tts with amplified settings
    print('🔄 [POLLY] Using flutter_tts fallback for 2× STRONGER');
    isUsingOfflineMode.value = true;

    await _fallbackTts.setVolume(1.0);

    // Get base values from LLM prosody
    final baseRate = _convertRateToNumeric(prosody?['rate'] ?? 'medium');
    final basePitch = _convertPitchToNumeric(prosody?['pitch'] ?? 'medium');

    // Amplify by 1.3x for 2× STRONGER effect
    await _fallbackTts.setSpeechRate((baseRate * 1.3).clamp(0.3, 1.0));
    await _fallbackTts.setPitch((basePitch * 1.3).clamp(0.8, 1.5));
    await _setLanguage(languageCode);

    await _fallbackTts.speak(text);
  }

  /// Synthesize 2× STRONGER audio with Polly using amplified SSML
  Future<File?> _synthesizeStrongerWithPolly(String text, String languageCode, MoodStyle style) async {
    try {
      final voiceId = _getPollyVoice(languageCode);
      final ssmlText = _buildStrongerSSML(text);

      print('⚡ [POLLY] Synthesizing 2× STRONGER with voice: $voiceId');

      final engines = _pollyEngine == 'neural' ? ['neural', 'standard'] : ['standard'];

      for (final engine in engines) {
        try {
          final endpoint = 'https://polly.$_awsRegion.amazonaws.com/v1/speech';
          final now = DateTime.now().toUtc();

          final requestBody = jsonEncode({
            'Text': ssmlText,
            'TextType': 'ssml',
            'VoiceId': voiceId,
            'Engine': engine,
            'OutputFormat': _pollyOutputFormat,
          });

          final headers = await _generateSigV4Headers(
            method: 'POST',
            endpoint: endpoint,
            body: requestBody,
            timestamp: now,
          );

          final response = await http.post(
            Uri.parse(endpoint),
            headers: headers,
            body: requestBody,
          ).timeout(
            Duration(seconds: _pollyTimeoutSeconds),
            onTimeout: () {
              print('⏱️ [POLLY] 2× STRONGER API timeout after ${_pollyTimeoutSeconds}s');
              throw Exception('Polly API timeout');
            },
          );

          if (response.statusCode == 200) {
            final tempFile = File('${_cacheDir}/temp_stronger_${DateTime.now().millisecondsSinceEpoch}.$_pollyOutputFormat');
            await tempFile.writeAsBytes(response.bodyBytes);
            print('✅ [POLLY] 2× STRONGER audio synthesized successfully with $engine engine');
            return tempFile;
          } else if (response.statusCode == 400 && engine == 'neural' && engines.length > 1) {
            print('⚠️ [POLLY] Neural engine not supported for 2× STRONGER, trying standard...');
            continue;
          } else {
            print('❌ [POLLY] 2× STRONGER API error: ${response.statusCode} - ${response.body}');
            return null;
          }
        } catch (e) {
          if (engine == 'neural' && engines.length > 1) {
            print('⚠️ [POLLY] Neural engine failed for 2× STRONGER: $e, trying standard...');
            continue;
          }
          throw e;
        }
      }

      return null;
    } catch (e) {
      print('❌ [POLLY] 2× STRONGER synthesis error: $e');
      return null;
    }
  }

  Future<File?> _synthesizeWithPolly(String text, String languageCode, MoodStyle style, {Map<String, String>? prosody}) async {
    try {
      final voiceId = _getPollyVoice(languageCode);

      // Use Golden SSML if golden voice is active, otherwise use normal SSML with LLM prosody
      final ssmlText = _storage.hasGoldenVoice()
          ? _buildGoldenSSML(text, style)
          : _buildSSML(text, prosody: prosody);

      final voiceMode = _storage.hasGoldenVoice() ? 'GOLDEN' : 'NORMAL';
      print('🎙️ [POLLY] Synthesizing with voice: $voiceId ($voiceMode mode)');

      // Try with configured engine first (neural), then fallback to standard
      final engines = _pollyEngine == 'neural' ? ['neural', 'standard'] : ['standard'];

      for (final engine in engines) {
        try {
          final endpoint = 'https://polly.$_awsRegion.amazonaws.com/v1/speech';
          final now = DateTime.now().toUtc();

          final requestBody = jsonEncode({
            'Text': ssmlText,
            'TextType': 'ssml',
            'VoiceId': voiceId,
            'Engine': engine,
            'OutputFormat': _pollyOutputFormat,
          });

          final headers = await _generateSigV4Headers(
            method: 'POST',
            endpoint: endpoint,
            body: requestBody,
            timestamp: now,
          );

          final response = await http.post(
            Uri.parse(endpoint),
            headers: headers,
            body: requestBody,
          ).timeout(
            Duration(seconds: _pollyTimeoutSeconds),
            onTimeout: () {
              print('⏱️ [POLLY] API timeout after ${_pollyTimeoutSeconds}s');
              throw Exception('Polly API timeout');
            },
          );

          if (response.statusCode == 200) {
            final tempFile = File('${_cacheDir}/temp_${DateTime.now().millisecondsSinceEpoch}.$_pollyOutputFormat');
            await tempFile.writeAsBytes(response.bodyBytes);
            print('✅ [POLLY] Audio synthesized successfully with $engine engine');
            return tempFile;
          } else if (response.statusCode == 400 && engine == 'neural' && engines.length > 1) {
            // Neural not supported, try standard engine
            print('⚠️ [POLLY] Neural engine not supported, trying standard engine...');
            continue;
          } else {
            print('❌ [POLLY] API error: ${response.statusCode} - ${response.body}');
            return null;
          }
        } catch (e) {
          if (engine == 'neural' && engines.length > 1) {
            print('⚠️ [POLLY] Neural engine failed: $e, trying standard engine...');
            continue;
          }
          throw e;
        }
      }

      return null;
    } catch (e) {
      print('❌ [POLLY] Synthesis error: $e');
      return null;
    }
  }

  Future<Map<String, String>> _generateSigV4Headers({
    required String method,
    required String endpoint,
    required String body,
    required DateTime timestamp,
  }) async {
    final uri = Uri.parse(endpoint);
    final host = uri.host;
    final canonicalUri = uri.path;
    
    final amzDate = _formatAmzDate(timestamp);
    final dateStamp = _formatDateStamp(timestamp);
    
    final payloadHash = sha256.convert(utf8.encode(body)).toString();
    
    final canonicalHeaders = 'content-type:application/json\n'
        'host:$host\n'
        'x-amz-date:$amzDate\n';
    
    final signedHeaders = 'content-type;host;x-amz-date';
    
    final canonicalRequest = '$method\n'
        '$canonicalUri\n'
        '\n'
        '$canonicalHeaders\n'
        '$signedHeaders\n'
        '$payloadHash';
    
    final credentialScope = '$dateStamp/$_awsRegion/polly/aws4_request';
    final stringToSign = 'AWS4-HMAC-SHA256\n'
        '$amzDate\n'
        '$credentialScope\n'
        '${sha256.convert(utf8.encode(canonicalRequest))}';
    
    final signingKey = _getSignatureKey(_awsSecretKey, dateStamp, _awsRegion, 'polly');
    final signature = hex.encode(Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).bytes);
    
    final authorizationHeader = 'AWS4-HMAC-SHA256 '
        'Credential=$_awsAccessKey/$credentialScope, '
        'SignedHeaders=$signedHeaders, '
        'Signature=$signature';
    
    return {
      'Content-Type': 'application/json',
      'Host': host,
      'X-Amz-Date': amzDate,
      'Authorization': authorizationHeader,
    };
  }

  List<int> _getSignatureKey(String key, String dateStamp, String regionName, String serviceName) {
    final kDate = Hmac(sha256, utf8.encode('AWS4$key')).convert(utf8.encode(dateStamp)).bytes;
    final kRegion = Hmac(sha256, kDate).convert(utf8.encode(regionName)).bytes;
    final kService = Hmac(sha256, kRegion).convert(utf8.encode(serviceName)).bytes;
    final kSigning = Hmac(sha256, kService).convert(utf8.encode('aws4_request')).bytes;
    return kSigning;
  }

  String _formatAmzDate(DateTime dt) {
    return '${dt.year}${_pad(dt.month)}${_pad(dt.day)}T'
        '${_pad(dt.hour)}${_pad(dt.minute)}${_pad(dt.second)}Z';
  }

  String _formatDateStamp(DateTime dt) {
    return '${dt.year}${_pad(dt.month)}${_pad(dt.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _getPollyVoice(String lang) {
    final String gender = GetStorage().read('voice_gender') ?? 'female';

    // Updated Amazon Polly Neural voice IDs (locale-prefixed, Neural only)
    final Map<String, Map<String, String>> voices = {
      "en-US": {
        "male": "en-US-MatthewNeural",    // Warm, energetic male
        "female": "en-US-JoannaNeural",   // Soothing, empathetic female
      },
      "hi-IN": {
        "male": "hi-IN-KajalNeural",      // Only female available – use as male fallback
        "female": "hi-IN-KajalNeural",    // Natural Hindi female
      },
      "es-ES": {
        "male": "es-ES-SergioNeural",     // Dynamic male
        "female": "es-ES-LuciaNeural",    // Warm female
      },
      "zh-CN": {
        "male": "zh-CN-ZhiyuNeural",      // Only female available – use as male fallback
        "female": "zh-CN-ZhiyuNeural",    // Clear Mandarin female
      },
      "fr-FR": {
        "male": "fr-FR-RemiNeural",       // Friendly male
        "female": "fr-FR-LeaNeural",      // Soft female
      },
      "de-DE": {
        "male": "de-DE-DanielNeural",     // Clear male
        "female": "de-DE-VickiNeural",    // Natural female
      },
      "ar-SA": {
        "male": "en-US-MatthewNeural",    // No Neural for ar-SA – fallback to English male
        "female": "en-US-JoannaNeural",   // Fallback to English female
      },
      "ja-JP": {
        "male": "ja-JP-TakumiNeural",     // Energetic male
        "female": "ja-JP-KazuhaNeural",   // Gentle female (preferred over Tomoko for warmth)
      },
    };

    return voices[lang]?[gender] ?? (gender == "male" ? "Matthew" : "Joanna");
  }

  String _buildSSML(String text, {Map<String, String>? prosody}) {
    // Use LLM-provided prosody or defaults
    final rate = prosody?['rate'] ?? 'medium';
    final pitch = prosody?['pitch'] ?? 'medium';
    final volume = prosody?['volume'] ?? 'medium';

    // Escape XML special characters
    final escapedText = _escapeXml(text);

    final prosodyTag = '<prosody rate="$rate" pitch="$pitch" volume="$volume">$escapedText</prosody>';
    return '<speak>$prosodyTag</speak>';
  }

  /// Build SSML for 2× STRONGER effect
  /// Faster rate (1.3x), higher pitch (1.2x), louder volume (1.2x)
  String _buildStrongerSSML(String text) {
    // Escape XML special characters
    final escapedText = _escapeXml(text);

    // 2× STRONGER: rate="130%" pitch="+20%" volume="loud"
    // Using percentage and semitone notation for better control
    return '<speak><prosody rate="130%" pitch="+20%" volume="loud">$escapedText</prosody></speak>';
  }

  /// Build SSML for Golden Voice effect
  /// Warmer, more empathetic tone with conversational style
  String _buildGoldenSSML(String text, MoodStyle style) {
    // Escape XML special characters
    final escapedText = _escapeXml(text);

    // Golden Voice: slightly slower (90%), slightly higher pitch (+10%), warm volume
    // Add emphasis on key emotional words
    String prosody = '<prosody rate="90%" pitch="+10%" volume="medium">$escapedText</prosody>';

    // Wrap in conversational speaking style if supported
    return '<speak><amazon:domain name="conversational">$prosody</amazon:domain></speak>';
  }

  /// Escape XML special characters for SSML
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _getCacheKey(String text, String languageCode, MoodStyle style, {String gender = 'female', bool isStronger = false, bool isGolden = false}) {
    final modifier = isStronger ? '-stronger' : (isGolden ? '-golden' : '');
    final combined = '$text-$languageCode-${style.toString()}-$gender$modifier';
    return sha256.convert(utf8.encode(combined)).toString();
  }

  Future<File?> _getCachedAudio(String cacheKey) async {
    try {
      final file = File('$_cacheDir/$cacheKey.$_pollyOutputFormat');
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      print('❌ [POLLY] Error checking cache: $e');
    }
    return null;
  }

  Future<void> _cacheAudio(String cacheKey, File audioFile) async {
    try {
      final cachedFile = File('$_cacheDir/$cacheKey.$_pollyOutputFormat');
      await audioFile.copy(cachedFile.path);

      // Clean up old cache files (configurable max)
      await _cleanupOldCache();
    } catch (e) {
      print('❌ [POLLY] Error caching audio: $e');
    }
  }

  Future<void> _cleanupOldCache() async {
    try {
      final dir = Directory(_cacheDir!);
      final files = await dir.list().toList();

      if (files.length > _pollyCacheMaxFiles) {
        // Sort by modification time
        files.sort((a, b) {
          final aStat = (a as File).statSync();
          final bStat = (b as File).statSync();
          return aStat.modified.compareTo(bStat.modified);
        });

        // Delete oldest files
        for (var i = 0; i < files.length - _pollyCacheMaxFiles; i++) {
          await (files[i] as File).delete();
        }
        print('🧹 [POLLY] Cleaned up ${files.length - _pollyCacheMaxFiles} old cache files');
      }
    } catch (e) {
      print('❌ [POLLY] Error cleaning cache: $e');
    }
  }

  Future<void> _playAudioFile(File file) async {
    try {
      isSpeaking.value = true;
      await _audioPlayer.play(DeviceFileSource(file.path));
    } catch (e) {
      print('❌ [POLLY] Error playing audio: $e');
      isSpeaking.value = false;
    }
  }

  Future<void> _speakWithFallback(String text, String languageCode, MoodStyle style, {Map<String, String>? prosody}) async {
    await _setLanguage(languageCode);
    await _applyProsody(prosody);
    await _fallbackTts.speak(text);
  }

  Future<void> _setLanguage(String languageCode) async {
    String language;

    switch (languageCode) {
      case 'en': language = 'en-US'; break;
      case 'hi': language = 'hi-IN'; break;
      case 'es': language = 'es-ES'; break;
      case 'zh': language = 'zh-CN'; break;
      case 'fr': language = 'fr-FR'; break;
      case 'de': language = 'de-DE'; break;
      case 'ar': language = 'ar-SA'; break;
      case 'ja': language = 'ja-JP'; break;
      default: language = 'en-US';
    }

    await _fallbackTts.setLanguage(language);
  }

  /// Apply LLM-provided prosody settings to fallback TTS
  Future<void> _applyProsody(Map<String, String>? prosody) async {
    // Convert LLM prosody to numeric values for flutter_tts
    final rate = _convertRateToNumeric(prosody?['rate'] ?? 'medium');
    final pitch = _convertPitchToNumeric(prosody?['pitch'] ?? 'medium');

    if (_storage.hasGoldenVoice()) {
      await _fallbackTts.setSpeechRate(rate * 0.9);
      await _fallbackTts.setPitch(pitch * 1.1);
    } else {
      await _fallbackTts.setSpeechRate(rate);
      await _fallbackTts.setPitch(pitch);
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
    await _audioPlayer.stop();
    await _fallbackTts.stop();
    isSpeaking.value = false;
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    _fallbackTts.stop();
    super.onClose();
  }
}

