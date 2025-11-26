import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'storage_service.dart';
import 'ai_service.dart';
import 'crashlytics_service.dart';

class PollyTTSService extends GetxService {
  final FlutterTts _fallbackTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StorageService _storage = Get.find<StorageService>();
  late final CrashlyticsService _crashlytics;

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

  // Voice discovery state
  Map<String, dynamic>? _voiceMap;

  @override
  void onInit() {
    super.onInit();
    _awsAccessKey = dotenv.env['AWS_ACCESS_KEY'] ?? '';
    _awsSecretKey = dotenv.env['AWS_SECRET_KEY'] ?? '';
    // Changed region to us-east-1 for generative voice support
    _awsRegion = dotenv.env['AWS_REGION'] ?? 'us-east-1';
    // Changed engine to generative (will fallback to neural then standard)
    _pollyEngine = dotenv.env['AWS_POLLY_ENGINE'] ?? 'generative';
    _pollyOutputFormat = dotenv.env['AWS_POLLY_OUTPUT_FORMAT'] ?? 'mp3';
    _pollyTimeoutSeconds = int.tryParse(dotenv.env['AWS_POLLY_TIMEOUT_SECONDS'] ?? '10') ?? 10;
    _pollyCacheMaxFiles = int.tryParse(dotenv.env['AWS_POLLY_CACHE_MAX_FILES'] ?? '20') ?? 20;
    _crashlytics = Get.find<CrashlyticsService>();

    if (_awsAccessKey.isEmpty || _awsSecretKey.isEmpty) {
      print('⚠️ [POLLY] Warning: AWS credentials not found in .env');
    }

    print('🎙️ [POLLY] Region: $_awsRegion, Engine: $_pollyEngine, Format: $_pollyOutputFormat, Timeout: ${_pollyTimeoutSeconds}s');
    print('💾 [POLLY] Cache max files: $_pollyCacheMaxFiles');

    _initializeFallbackTTS();
    _initializeCacheDir();
    _setupAudioPlayer();
    _initializeVoiceDiscovery();
  }

  /// Initialize voice discovery on first launch
  Future<void> _initializeVoiceDiscovery() async {
    try {
      // Voice map version - increment this when voice mappings change
      const voiceMapVersion = 4; // Updated: Verified voices from AWS CLI describe-voices
      final storedVersion = _storage.getPollyVoiceMapVersion();

      // Check if voice discovery has already been completed
      final storedVoiceMap = _storage.getPollyVoiceMap();

      // Rediscover if version mismatch or no stored map
      if (storedVersion != voiceMapVersion || storedVoiceMap == null || storedVoiceMap.isEmpty) {
        if (storedVersion != voiceMapVersion) {
          print('🔄 [POLLY] Voice map version mismatch (stored: $storedVersion, current: $voiceMapVersion) - rediscovering...');
        } else {
          print('🔍 [POLLY] First launch detected - starting voice discovery...');
        }
        await _discoverAndTestVoices();
        _storage.setPollyVoiceMapVersion(voiceMapVersion);
        return;
      }

      _voiceMap = storedVoiceMap;
      print('✅ [POLLY] Voice map loaded from storage (${_voiceMap!.length} languages, version: $voiceMapVersion)');

      // Debug: Print en-US voices to verify
      if (_voiceMap!.containsKey('en-US')) {
        final enUS = _voiceMap!['en-US'];
        print('   📋 [DEBUG] en-US voices:');
        print('      Generative: M=${enUS['generative']?['male']}, F=${enUS['generative']?['female']}');
        print('      Neural: M=${enUS['neural']?['male']}, F=${enUS['neural']?['female']}');
        print('      Standard: M=${enUS['standard']?['male']}, F=${enUS['standard']?['female']}');
      }

    } catch (e) {
      print('❌ [POLLY] Voice discovery error: $e');
      // Use fallback hardcoded voices
    }
  }

  /// Force re-discovery of voices (useful for debugging or after AWS updates)
  Future<void> forceRediscoverVoices() async {
    try {
      print('🔄 [POLLY] Forcing voice re-discovery...');
      _storage.clearPollyVoiceMap();
      _voiceMap = null;
      await _discoverAndTestVoices();
      print('✅ [POLLY] Voice re-discovery complete!');
    } catch (e) {
      print('❌ [POLLY] Voice re-discovery error: $e');
    }
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

  /// Discover and test all available voices from AWS Polly
  Future<void> _discoverAndTestVoices() async {
    try {
      print('🔍 [POLLY] Calling DescribeVoices API...');

      final endpoint = 'https://polly.$_awsRegion.amazonaws.com/v1/voices';
      final now = DateTime.now().toUtc();

      final headers = await _generateSigV4Headers(
        method: 'GET',
        endpoint: endpoint,
        body: '',
        timestamp: now,
      );

      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      ).timeout(
        Duration(seconds: _pollyTimeoutSeconds),
        onTimeout: () {
          throw Exception('DescribeVoices API timeout');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('DescribeVoices failed: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      final voices = data['Voices'] as List<dynamic>;

      print('✅ [POLLY] Found ${voices.length} total voices');

      // Build voice map for our 8 supported languages
      final voiceMap = await _buildVoiceMap(voices);

      // Test each voice
      await _testVoices(voiceMap);

      // Save to storage
      _storage.setPollyVoiceMap(voiceMap);
      _voiceMap = voiceMap;

      print('✅ [POLLY] Voice discovery complete!');

    } catch (e) {
      print('❌ [POLLY] Voice discovery failed: $e');
      rethrow;
    }
  }

  /// Build voice map from DescribeVoices response
  Future<Map<String, dynamic>> _buildVoiceMap(List<dynamic> voices) async {
    final supportedLanguages = [
      'en-US', 'en-GB', 'hi-IN', 'es-ES',
      'cmn-CN', 'fr-FR', 'de-DE', 'arb', 'ja-JP'
    ];

    // Preferred voices verified from AWS Polly DescribeVoices API (us-east-1)
    // Note: All engines (generative, neural, standard) use simple voice names
    // The engine is specified as a parameter in the API request, not in the voice ID
    final preferredVoices = {
      'en-US': {
        'generative': {'male': 'Matthew', 'female': 'Danielle'},
        'neural': {'male': 'Gregory', 'female': 'Danielle'},
        'standard': {'male': 'Matthew', 'female': 'Joanna'}
      },
      'en-GB': {
        'generative': {'female': 'Amy'},  // No male generative voice
        'neural': {'male': 'Brian', 'female': 'Emma'},
        'standard': {'male': 'Brian', 'female': 'Emma'}
      },
      'hi-IN': {
        'generative': {'female': 'Kajal'},  // No male voices available
        'neural': {'female': 'Kajal'},
        'standard': {'female': 'Aditi'}
      },
      'es-ES': {
        'generative': {'male': 'Sergio', 'female': 'Lucia'},
        'neural': {'male': 'Sergio', 'female': 'Lucia'},
        'standard': {'male': 'Enrique', 'female': 'Lucia'}
      },
      'cmn-CN': {
        'generative': {},  // No voices available
        'neural': {'female': 'Zhiyu'},  // No male voice
        'standard': {'female': 'Zhiyu'}
      },
      'fr-FR': {
        'generative': {'male': 'Remi', 'female': 'Lea'},
        'neural': {'male': 'Remi', 'female': 'Lea'},
        'standard': {'male': 'Mathieu', 'female': 'Lea'}
      },
      'de-DE': {
        'generative': {'male': 'Daniel', 'female': 'Vicki'},
        'neural': {'male': 'Daniel', 'female': 'Vicki'},
        'standard': {'male': 'Hans', 'female': 'Vicki'}
      },
      'arb': {
        'generative': {},  // No voices available
        'neural': {'male': 'Zayd', 'female': 'Hala'},
        'standard': {'female': 'Zeina'}  // No male standard voice
      },
      'ja-JP': {
        'generative': {},  // No voices available
        'neural': {'male': 'Takumi', 'female': 'Kazuha'},
        'standard': {'male': 'Takumi', 'female': 'Mizuki'}
      },
    };

    final voiceMap = <String, dynamic>{};

    for (final lang in supportedLanguages) {
      voiceMap[lang] = <String, dynamic>{
        'generative': <String, String?>{
          'male': null,
          'female': null,
        },
        'neural': <String, String?>{
          'male': null,
          'female': null,
        },
        'standard': <String, String?>{
          'male': null,
          'female': null,
        },
      };

      // Filter voices for this language
      final langVoices = voices.where((v) =>
        v['LanguageCode'] == lang
      ).toList();

      // Categorize by engine and gender, prioritizing preferred voices
      for (final voice in langVoices) {
        final voiceId = voice['Id'] as String;
        final gender = (voice['Gender'] as String).toLowerCase();
        final supportedEngines = voice['SupportedEngines'] as List<dynamic>;

        // Check engine support in priority order
        for (final engine in ['generative', 'neural', 'standard']) {
          if (supportedEngines.contains(engine)) {
            final engineMap = voiceMap[lang][engine] as Map<String, String?>;

            // Prefer the voice from our preferred list, otherwise use first available
            final preferredVoice = preferredVoices[lang]?[engine]?[gender];
            if (preferredVoice == voiceId) {
              engineMap[gender] = voiceId;
            } else if (engineMap[gender] == null) {
              engineMap[gender] = voiceId;
            }
          }
        }
      }

      // Apply preferred voices even if not found in DescribeVoices
      // This ensures we use the correct voice IDs from our verified list
      for (final engine in ['generative', 'neural', 'standard']) {
        for (final gender in ['male', 'female']) {
          final preferredVoice = preferredVoices[lang]?[engine]?[gender];
          if (preferredVoice != null) {
            final engineMap = voiceMap[lang][engine] as Map<String, String?>;
            // Only set if not already set by DescribeVoices
            if (engineMap[gender] == null) {
              engineMap[gender] = preferredVoice;
            }
          }
        }
      }

      // Apply engine-level fallbacks (but not cross-gender fallbacks)
      _applyVoiceFallbacks(voiceMap[lang] as Map<String, dynamic>);

      final genMap = voiceMap[lang]['generative'] as Map<String, String?>;
      final neuMap = voiceMap[lang]['neural'] as Map<String, String?>;
      final stdMap = voiceMap[lang]['standard'] as Map<String, String?>;

      print('🎙️ [POLLY] $lang voices:');
      print('   Generative: M=${genMap['male']}, F=${genMap['female']}');
      print('   Neural: M=${neuMap['male']}, F=${neuMap['female']}');
      print('   Standard: M=${stdMap['male']}, F=${stdMap['female']}');
    }

    return voiceMap;
  }

  /// Apply fallbacks when specific gender/engine combinations are missing
  /// NOTE: We no longer apply cross-gender fallbacks here - the selection logic handles it
  /// This method is kept for backward compatibility but only applies engine-level fallbacks
  void _applyVoiceFallbacks(Map<String, dynamic> langVoices) {
    // If generative is missing, fallback to neural
    final generativeMap = langVoices['generative'] as Map<String, String?>;
    final neuralMap = langVoices['neural'] as Map<String, String?>;
    final standardMap = langVoices['standard'] as Map<String, String?>;

    // Only fallback to next engine if the voice doesn't exist at all
    // Don't cross genders - let the selection logic handle that
    if (generativeMap['male'] == null && neuralMap['male'] != null) {
      generativeMap['male'] = neuralMap['male'];
    }
    if (generativeMap['female'] == null && neuralMap['female'] != null) {
      generativeMap['female'] = neuralMap['female'];
    }

    // If neural is missing, fallback to standard
    if (neuralMap['male'] == null && standardMap['male'] != null) {
      neuralMap['male'] = standardMap['male'];
    }
    if (neuralMap['female'] == null && standardMap['female'] != null) {
      neuralMap['female'] = standardMap['female'];
    }
  }

  /// Test all voices with a 3-second test phrase
  Future<void> _testVoices(Map<String, dynamic> voiceMap) async {
    print('🧪 [POLLY] Starting voice test suite...');

    int totalVoices = 0;
    int generativeSuccess = 0;
    int neuralFallback = 0;
    int standardFallback = 0;

    for (final lang in voiceMap.keys) {
      for (final gender in ['male', 'female']) {
        totalVoices++;

        final generativeVoice = voiceMap[lang]['generative'][gender];
        final neuralVoice = voiceMap[lang]['neural'][gender];
        final standardVoice = voiceMap[lang]['standard'][gender];

        if (generativeVoice == null) continue;

        // Test phrase
        final testPhrase = 'Test voice ok';

        // Try generative first
        final generativeResult = await _testVoice(
          voiceId: generativeVoice,
          languageCode: lang,
          engine: 'generative',
          text: testPhrase,
        );

        if (generativeResult) {
          generativeSuccess++;
          print('✅ [POLLY] $lang $gender → Generative OK ($generativeVoice)');
        } else {
          // Try neural
          final neuralResult = await _testVoice(
            voiceId: neuralVoice ?? generativeVoice,
            languageCode: lang,
            engine: 'neural',
            text: testPhrase,
          );

          if (neuralResult) {
            neuralFallback++;
            print('⚠️ [POLLY] $lang $gender → Fallback to Neural (${neuralVoice ?? generativeVoice})');
          } else {
            // Try standard
            final standardResult = await _testVoice(
              voiceId: standardVoice ?? neuralVoice ?? generativeVoice,
              languageCode: lang,
              engine: 'standard',
              text: testPhrase,
            );

            if (standardResult) {
              standardFallback++;
              print('⚠️ [POLLY] $lang $gender → Fallback to Standard (${standardVoice ?? neuralVoice ?? generativeVoice})');
            } else {
              print('❌ [POLLY] $lang $gender → All engines failed');
            }
          }
        }
      }
    }

    print('');
    print('🎉 [POLLY] Voice Test Complete:');
    print('   Generative ready: $generativeSuccess/${totalVoices} voices');
    print('   Neural fallback: $neuralFallback voices');
    print('   Standard fallback: $standardFallback voices');
    print('');
  }

  /// Test a single voice with a specific engine
  Future<bool> _testVoice({
    required String voiceId,
    required String languageCode,
    required String engine,
    required String text,
  }) async {
    try {
      final endpoint = 'https://polly.$_awsRegion.amazonaws.com/v1/speech';
      final now = DateTime.now().toUtc();

      final ssmlText = '<speak>$text</speak>';

      final requestBody = jsonEncode({
        'Text': ssmlText,
        'TextType': 'ssml',
        'VoiceId': voiceId,
        'LanguageCode': languageCode,
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
        Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Test timeout');
        },
      );

      return response.statusCode == 200;

    } catch (e) {
      return false;
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

  /// Speak with Main mode (normal or Crystal Voice)
  /// Multi-level fallback: Generative → Neural → Standard → Plain TTS
  Future<void> speak(String text, MoodStyle style, {Map<String, String>? prosody}) async {
    if (text.isEmpty) return;

    // DEBUG: Log the text received for speaking
    print('🔍 [POLLY DEBUG] Text received for speaking: "$text"');

    await stop();

    final fullLocale = _storage.getFullLocale();
    final gender = _storage.getVoiceGender();
    final isGolden = _storage.hasGoldenVoice();
    final cacheKey = _getCacheKey(text, fullLocale, style, gender: gender, isGolden: isGolden);
    final cachedFile = await _getCachedAudio(cacheKey);

    // Try to use cached audio first
    if (cachedFile != null) {
      print('🎵 [POLLY] Using cached audio');
      await _playAudioFile(cachedFile);
      return;
    }

    // Try Amazon Polly with multi-level engine fallback
    // Priority: generative → neural → standard
    try {
      final audioFile = await _synthesizeWithPolly(text, fullLocale, style, prosody: prosody);
      if (audioFile != null) {
        await _cacheAudio(cacheKey, audioFile);
        await _playAudioFile(audioFile);
        isUsingOfflineMode.value = false;
        return;
      }
    } catch (e, stackTrace) {
      print('❌ [POLLY] Polly synthesis failed: $e');
      // Report TTS synthesis error to Crashlytics
      _crashlytics.reportTTSError(
        e,
        stackTrace,
        operation: 'speak',
        locale: fullLocale,
        textLength: text.length,
      );
    }

    // Final fallback to flutter_tts (never fail)
    print('🔄 [POLLY] Using flutter_tts fallback');
    isUsingOfflineMode.value = true;
    await _speakWithFallback(text, fullLocale, style, prosody: prosody);
  }

  /// Speak with 2× STRONGER amplification
  /// Multi-level fallback: Generative → Neural → Standard → Plain TTS
  /// Uses extreme SSML for powerful, energetic speech
  Future<void> speakStronger(String text, MoodStyle style, {Map<String, String>? prosody}) async {
    if (text.isEmpty) return;

    await stop();

    final fullLocale = _storage.getFullLocale();
    final gender = _storage.getVoiceGender();
    final cacheKey = _getCacheKey(text, fullLocale, style, gender: gender, isStronger: true);
    final cachedFile = await _getCachedAudio(cacheKey);

    // Try to use cached audio first
    if (cachedFile != null) {
      print('🎵 [POLLY] Using cached 2× STRONGER audio');
      await _playAudioFile(cachedFile);
      return;
    }

    // Try Amazon Polly with 2× STRONGER SSML
    try {
      final audioFile = await _synthesizeStrongerWithPolly(text, fullLocale, style);
      if (audioFile != null) {
        await _cacheAudio(cacheKey, audioFile);
        await _playAudioFile(audioFile);
        isUsingOfflineMode.value = false;
        return;
      }
    } catch (e, stackTrace) {
      print('❌ [POLLY] Polly 2× stronger synthesis failed: $e');
      // Report TTS synthesis error to Crashlytics
      _crashlytics.reportTTSError(
        e,
        stackTrace,
        operation: 'speakStronger',
        locale: fullLocale,
        textLength: text.length,
      );
    }

    // Fallback to flutter_tts with EXTREME amplified settings
    print('🔄 [POLLY] Using flutter_tts fallback for 2× STRONGER with style: $style');
    isUsingOfflineMode.value = true;

    await _fallbackTts.setVolume(1.0);

    // Get style-specific extreme settings
    final extremeSettings = _getExtremeSettings(style, prosody);

    await _fallbackTts.setSpeechRate(extremeSettings['rate']!);
    await _fallbackTts.setPitch(extremeSettings['pitch']!);
    await _setLanguage(fullLocale);

    await _fallbackTts.speak(text);
  }

  /// Synthesize 2× STRONGER audio with Polly using EXTREME style-specific SSML
  Future<File?> _synthesizeStrongerWithPolly(String text, String fullLocale, MoodStyle style) async {
    try {
      final voiceId = _getPollyVoice(fullLocale);
      print('⚡ [POLLY] Synthesizing 2× STRONGER with voice: $voiceId, language: $fullLocale, style: $style');

      // Try with configured engine first (generative > neural > standard)
      final engines = _pollyEngine == 'generative'
          ? ['generative', 'neural', 'standard']
          : _pollyEngine == 'neural'
              ? ['neural', 'standard']
              : ['standard'];

      for (final engine in engines) {
        try {
          // Build SSML for current engine (important for fallback compatibility)
          final ssmlText = _buildStrongerSSMLForEngine(text, style, engine);

          final endpoint = 'https://polly.$_awsRegion.amazonaws.com/v1/speech';
          final now = DateTime.now().toUtc();

          final requestBody = jsonEncode({
            'Text': ssmlText,
            'TextType': 'ssml',
            'VoiceId': voiceId,
            'LanguageCode': fullLocale,
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
          } else if (response.statusCode == 400 && engines.indexOf(engine) < engines.length - 1) {
            // Current engine not supported, try next engine in priority list
            final nextEngine = engines[engines.indexOf(engine) + 1];
            print('⚠️ [POLLY] $engine engine not supported for 2× STRONGER, trying $nextEngine...');
            continue;
          } else {
            print('❌ [POLLY] 2× STRONGER API error: ${response.statusCode} - ${response.body}');
            return null;
          }
        } catch (e) {
          if (engines.indexOf(engine) < engines.length - 1) {
            final nextEngine = engines[engines.indexOf(engine) + 1];
            print('⚠️ [POLLY] $engine engine failed for 2× STRONGER: $e, trying $nextEngine...');
            continue;
          }
          rethrow;
        }
      }

      return null;
    } catch (e) {
      print('❌ [POLLY] 2× STRONGER synthesis error: $e');
      return null;
    }
  }

  Future<File?> _synthesizeWithPolly(String text, String fullLocale, MoodStyle style, {Map<String, String>? prosody}) async {
    try {
      final voiceId = _getPollyVoice(fullLocale);
      final voiceMode = _storage.hasGoldenVoice() ? 'CRYSTAL' : 'NORMAL';
      print('🎙️ [POLLY] Synthesizing with voice: $voiceId, language: $fullLocale ($voiceMode mode)');

      // Try with configured engine first (generative > neural > standard)
      final engines = _pollyEngine == 'generative'
          ? ['generative', 'neural', 'standard']
          : _pollyEngine == 'neural'
              ? ['neural', 'standard']
              : ['standard'];

      for (final engine in engines) {
        try {
          // Build SSML for current engine (important for fallback compatibility)
          final ssmlText = _storage.hasGoldenVoice()
              ? _buildGoldenSSMLForEngine(text, style, engine)
              : _buildSSMLForEngine(text, engine, prosody: prosody);

          final endpoint = 'https://polly.$_awsRegion.amazonaws.com/v1/speech';
          final now = DateTime.now().toUtc();

          final requestBody = jsonEncode({
            'Text': ssmlText,
            'TextType': 'ssml',
            'VoiceId': voiceId,
            'LanguageCode': fullLocale,
            'Engine': engine,
            'OutputFormat': _pollyOutputFormat,
          });

          // Debug: Log the request details
          print('🔍 [POLLY DEBUG] Request:');
          print('   Region: $_awsRegion');
          print('   Endpoint: $endpoint');
          print('   Voice: $voiceId');
          print('   Language: $fullLocale');
          print('   Engine: $engine');
          print('   SSML length: ${ssmlText.length} chars');

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
          } else if (response.statusCode == 400 && engines.indexOf(engine) < engines.length - 1) {
            // Current engine not supported, try next engine in priority list
            final nextEngine = engines[engines.indexOf(engine) + 1];
            print('⚠️ [POLLY] $engine engine not supported for voice $voiceId, trying $nextEngine engine...');
            print('   AWS Error: ${response.body}');
            continue;
          } else {
            print('❌ [POLLY] API error: ${response.statusCode} - ${response.body}');
            // Report API error to Crashlytics
            _crashlytics.reportTTSError(
              Exception('Polly API returned status ${response.statusCode}'),
              StackTrace.current,
              operation: '_synthesizeWithPolly',
              engine: engine,
              voiceId: voiceId,
              locale: fullLocale,
            );
            return null;
          }
        } catch (e, stackTrace) {
          if (engines.indexOf(engine) < engines.length - 1) {
            final nextEngine = engines[engines.indexOf(engine) + 1];
            print('⚠️ [POLLY] $engine engine failed: $e, trying $nextEngine engine...');
            continue;
          }
          // Report error to Crashlytics before rethrowing
          _crashlytics.reportTTSError(
            e,
            stackTrace,
            operation: '_synthesizeWithPolly',
            engine: engine,
            voiceId: voiceId,
            locale: fullLocale,
          );
          rethrow;
        }
      }

      return null;
    } catch (e, stackTrace) {
      print('❌ [POLLY] Synthesis error: $e');
      // Report synthesis error to Crashlytics
      _crashlytics.reportTTSError(
        e,
        stackTrace,
        operation: '_synthesizeWithPolly',
        locale: fullLocale,
      );
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

  String _getPollyVoice(String fullLocale) {
    // Use injected storage service for consistency
    final String gender = _storage.getVoiceGender();

    // Try to use discovered voice map first
    if (_voiceMap != null && _voiceMap!.containsKey(fullLocale)) {
      final enginePriority = _pollyEngine == 'generative'
          ? ['generative', 'neural', 'standard']
          : _pollyEngine == 'neural'
              ? ['neural', 'standard']
              : ['standard'];

      // STRICT GENDER PREFERENCE: Only try selected gender across all engines
      // Priority: generative → neural → standard
      for (final engine in enginePriority) {
        final voiceId = _voiceMap![fullLocale][engine]?[gender];
        if (voiceId != null) {
          print('🎙️ [POLLY] Selected voice from map: $voiceId ($engine) for $fullLocale ($gender)');
          return voiceId;
        }
      }

      // If no voice found for selected gender, log warning but don't fallback to opposite gender
      print('⚠️ [POLLY] No $gender voice available in voice map for $fullLocale, trying hardcoded voices');
    }

    // Fallback to hardcoded voices if discovery not complete
    print('⚠️ [POLLY] Using fallback hardcoded voices');

    // ✅ AWS POLLY VOICE MAPPINGS (Based on AWS Documentation - November 2025)
    // Priority: Generative → Neural → Standard
    // Gender preference: Try selected gender across all engines before falling back to opposite gender
    // Note: All engines use simple voice names - the engine is specified as a parameter
    final Map<String, Map<String, Map<String, String?>>> voices = {
      "en-US": {
        "Generative": {
          "male": "Matthew",                // ✅ Generative voice
          "female": "Danielle",             // ✅ Generative voice
        },
        "Neural": {
          "male": "Gregory",                // ✅ Neural voice
          "female": "Danielle",             // ✅ Neural voice
        },
        "Standard": {
          "male": "Matthew",                // ✅ Standard voice
          "female": "Joanna",               // ✅ Standard voice
        },
      },
      "en-GB": {
        "Generative": {
          "male": null,                     // ❌ No male generative voice
          "female": "Amy",                  // ✅ Generative voice
        },
        "Neural": {
          "male": "Brian",                  // ✅ Neural voice
          "female": "Emma",                 // ✅ Neural voice
        },
        "Standard": {
          "male": "Brian",                  // ✅ Standard voice
          "female": "Emma",                 // ✅ Standard voice
        },
      },
      "hi-IN": {
        "Generative": {
          "male": null,                     // ❌ No male generative voice
          "female": "Kajal",                // ✅ Generative voice
        },
        "Neural": {
          "male": null,                     // ❌ No male neural voice
          "female": "Kajal",                // ✅ Neural voice
        },
        "Standard": {
          "male": null,                     // ❌ No male standard voice
          "female": "Aditi",                // ✅ Standard voice
        },
      },
      "es-ES": {
        "Generative": {
          "male": "Sergio",                 // ✅ Generative voice
          "female": "Lucia",                // ✅ Generative voice
        },
        "Neural": {
          "male": "Sergio",                 // ✅ Neural voice
          "female": "Lucia",                // ✅ Neural voice
        },
        "Standard": {
          "male": "Enrique",                // ✅ Standard voice
          "female": "Lucia",                // ✅ Standard voice
        },
      },
      "cmn-CN": {
        "Generative": {
          "male": null,                     // ❌ No male generative voice
          "female": null,                   // ❌ No female generative voice
        },
        "Neural": {
          "male": null,                     // ❌ No male neural voice
          "female": "Zhiyu",                // ✅ Neural voice
        },
        "Standard": {
          "male": null,                     // ❌ No male standard voice
          "female": "Zhiyu",                // ✅ Standard voice
        },
      },
      "fr-FR": {
        "Generative": {
          "male": "Remi",                   // ✅ Generative voice
          "female": "Lea",                  // ✅ Generative voice
        },
        "Neural": {
          "male": "Remi",                   // ✅ Neural voice
          "female": "Lea",                  // ✅ Neural voice
        },
        "Standard": {
          "male": "Mathieu",                // ✅ Standard voice
          "female": "Lea",                  // ✅ Standard voice
        },
      },
      "de-DE": {
        "Generative": {
          "male": "Daniel",                 // ✅ Generative voice
          "female": "Vicki",                // ✅ Generative voice
        },
        "Neural": {
          "male": "Daniel",                 // ✅ Neural voice
          "female": "Vicki",                // ✅ Neural voice
        },
        "Standard": {
          "male": "Hans",                   // ✅ Standard voice
          "female": "Vicki",                // ✅ Standard voice
        },
      },
      "arb": {
        "Generative": {
          "male": null,                     // ❌ No male generative voice
          "female": null,                   // ❌ No female generative voice
        },
        "Neural": {
          "male": "Zayd",                   // ✅ Neural voice
          "female": "Hala",                 // ✅ Neural voice
        },
        "Standard": {
          "male": null,                     // ❌ No male standard voice
          "female": "Zeina",                // ✅ Standard voice
        },
      },
      "ja-JP": {
        "Generative": {
          "male": null,                     // ❌ No male generative voice
          "female": null,                   // ❌ No female generative voice
        },
        "Neural": {
          "male": "Takumi",                 // ✅ Neural voice
          "female": "Kazuha",               // ✅ Neural voice
        },
        "Standard": {
          "male": "Takumi",                 // ✅ Standard voice
          "female": "Mizuki",               // ✅ Standard voice
        },
      },
    };

    // Engine priority based on configuration
    final enginePriority = _pollyEngine == 'generative'
        ? ['Generative', 'Neural', 'Standard']
        : _pollyEngine == 'neural'
            ? ['Neural', 'Standard']
            : ['Standard'];

    // STRICT GENDER PREFERENCE: Only try selected gender across all engines
    // Priority: generative → neural → standard
    for (final engine in enginePriority) {
      final voiceId = voices[fullLocale]?[engine]?[gender];
      if (voiceId != null) {
        print('🎙️ [POLLY] Selected voice: $voiceId ($engine engine) for $fullLocale ($gender)');
        return voiceId;
      }
    }

    // Ultimate fallback to en-US with selected gender
    print('⚠️ [POLLY] No $gender voice found for $fullLocale, falling back to en-US $gender voice');
    return gender == "male" ? "Matthew" : "Joanna";
  }

  /// Build SSML for a specific engine
  String _buildSSMLForEngine(String text, String engine, {Map<String, String>? prosody}) {
    // Clean the text first to fix spacing issues
    final cleanedText = _cleanTextForSpeech(text);

    // DEBUG: Log before and after cleaning
    print('🔍 [POLLY DEBUG] Before cleaning: "$text"');
    print('🔍 [POLLY DEBUG] After cleaning: "$cleanedText"');

    // Escape XML special characters
    final escapedText = _escapeXml(cleanedText);

    print('🔍 [POLLY DEBUG] After XML escape: "$escapedText"');

    // Generative engine has limited SSML support - only x-values work
    if (engine == 'generative') {
      // For generative engine, convert word values to x-values
      // Generative engine does NOT support word values (slow, medium, fast) or percentages
      final rate = _convertToXValue(prosody?['rate'] ?? 'medium', 'rate');
      final volume = _convertToXValue(prosody?['volume'] ?? 'medium', 'volume');

      // Note: Generative engine doesn't reliably support pitch adjustments
      return '<speak><prosody rate="$rate" volume="$volume">$escapedText</prosody></speak>';
    } else if (engine == 'neural') {
      // Neural engine: ONLY supports volume in decibels
      // Neural does NOT support: rate/pitch (word values or percentages)
      // TESTED: Only volume works reliably on neural
      final volumeWord = prosody?['volume'] ?? 'medium';
      final volumeDb = _convertToDecibels(volumeWord);

      return '<speak><prosody volume="$volumeDb">$escapedText</prosody></speak>';
    } else {
      // Standard engine supports word values for all attributes
      final rate = prosody?['rate'] ?? 'medium';
      final volume = prosody?['volume'] ?? 'medium';
      final pitch = prosody?['pitch'] ?? 'medium';

      return '<speak><prosody rate="$rate" volume="$volume" pitch="$pitch">$escapedText</prosody></speak>';
    }
  }

  /// Convert word values to x-values for generative engine
  String _convertToXValue(String value, String attribute) {
    // Map word values to x-values
    final Map<String, String> rateMap = {
      'x-slow': 'x-slow',
      'slow': 'x-slow',
      'medium': 'medium',  // medium is supported
      'fast': 'x-fast',
      'x-fast': 'x-fast',
    };

    final Map<String, String> volumeMap = {
      'silent': 'silent',
      'x-soft': 'x-soft',
      'soft': 'x-soft',
      'medium': 'medium',  // medium is supported
      'loud': 'x-loud',
      'x-loud': 'x-loud',
    };

    if (attribute == 'rate') {
      return rateMap[value] ?? 'medium';
    } else if (attribute == 'volume') {
      return volumeMap[value] ?? 'medium';
    }

    return value;
  }

  /// Convert word values to decibels for neural engine
  /// Neural engine ONLY supports volume in decibel format
  String _convertToDecibels(String volumeWord) {
    final Map<String, String> volumeToDb = {
      'silent': '-20dB',
      'x-soft': '-10dB',
      'soft': '-6dB',
      'medium': '+0dB',
      'loud': '+6dB',
      'x-loud': '+10dB',
    };

    return volumeToDb[volumeWord] ?? '+0dB';
  }

  /// Build EXTREME SSML for a specific engine
  /// 2× STRONGER: Energized but smooth
  /// - rate="medium" (max - never faster per app policy)
  /// - volume="+6dB" (amplified)
  /// - pitch="+15%" (elevated)
  /// - <emphasis level="strong"> (Standard only)
  /// - Optional: <amazon:effect phonation="breathy"> for hype (Standard only)
  String _buildStrongerSSMLForEngine(String text, MoodStyle style, String engine) {
    // Clean the text first to fix spacing issues
    final cleanedText = _cleanTextForSpeech(text);

    // Escape XML special characters
    final escapedText = _escapeXml(cleanedText);

    // Check engine type for SSML compatibility
    if (engine == 'generative') {
      // Generative engine: Use x-values only, medium rate for clarity
      // Generative does NOT support: percentages, decibels, emphasis, amazon:effect
      return '<speak>'
          '<prosody rate="medium" volume="x-loud">'
          '$escapedText'
          '</prosody>'
          '</speak>';
    } else if (engine == 'neural') {
      // Neural engine: ONLY supports volume in decibels
      // Neural does NOT support: rate/pitch percentages, word values, emphasis, phonation, vocal-tract-length
      // TESTED: Only volume="+XdB" works reliably on neural
      return '<speak>'
          '<prosody volume="+6dB">'
          '$escapedText'
          '</prosody>'
          '</speak>';
    } else {
      // Standard engine: Full SSML support
      // Use emphasis for stronger impact
      return '<speak>'
          '<emphasis level="strong">'
          '<prosody rate="medium" volume="+6dB" pitch="+15%">'
          '$escapedText'
          '</prosody>'
          '</emphasis>'
          '</speak>';
    }
  }

  /// Build Crystal SSML for a specific engine
  /// CRYSTAL VOICE: Premium clarity
  /// - rate="slow" (deliberate, measured)
  /// - pitch="-10%" (warmer, deeper)
  /// - volume="soft" (gentle, intimate)
  /// - <amazon:effect name="drc"> (Neural/Standard only)
  /// - <amazon:effect phonation="soft"> (Standard only)
  /// - <amazon:effect vocal-tract-length="+12%"> (Standard only)
  String _buildGoldenSSMLForEngine(String text, MoodStyle style, String engine) {
    // Clean the text first to fix spacing issues
    final cleanedText = _cleanTextForSpeech(text);

    // Escape XML special characters
    final escapedText = _escapeXml(cleanedText);

    // Check current engine - generative has limited SSML support
    if (engine == 'generative') {
      // Premium Crystal Voice SSML for GENERATIVE engine
      // Generative engine only supports x-values (x-slow, x-soft, etc)
      // It does NOT support: percentages, DRC, phonation, vocal-tract-length
      return '<speak>'
          '<prosody rate="x-slow" volume="x-soft">'
          '$escapedText'
          '</prosody>'
          '</speak>';
    } else if (engine == 'neural') {
      // Premium Crystal Voice SSML for NEURAL engine
      // Neural supports: DRC, volume in decibels
      // Neural does NOT support: rate/pitch percentages, word values, phonation, vocal-tract-length
      // TESTED: Only DRC + volume works reliably on neural
      return '<speak>'
          '<amazon:effect name="drc">'
          '<prosody volume="+0dB">'
          '$escapedText'
          '</prosody>'
          '</amazon:effect>'
          '</speak>';
    } else {
      // Premium Crystal Voice SSML for STANDARD engine
      // Standard supports: ALL SSML features
      return '<speak>'
          '<amazon:effect name="drc">'
          '<amazon:effect phonation="soft">'
          '<amazon:effect vocal-tract-length="+12%">'
          '<prosody rate="slow" pitch="-10%" volume="soft">'
          '$escapedText'
          '</prosody>'
          '</amazon:effect>'
          '</amazon:effect>'
          '</amazon:effect>'
          '</speak>';
    }
  }

  /// Clean text for speech to fix spacing and formatting issues
  String _cleanTextForSpeech(String text) {
    // Just basic whitespace cleanup - let's see what the actual issue is first
    text = text.trim();

    // Clean up extra whitespace (multiple spaces, tabs, newlines -> single space)
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text;
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
    } catch (e, stackTrace) {
      print('❌ [POLLY] Error playing audio: $e');
      // Report audio playback error to Crashlytics
      _crashlytics.reportTTSError(
        e,
        stackTrace,
        operation: '_playAudioFile',
      );
      isSpeaking.value = false;
    }
  }

  Future<void> _speakWithFallback(String text, String fullLocale, MoodStyle style, {Map<String, String>? prosody}) async {
    await _setLanguage(fullLocale);
    await _applyProsody(prosody);
    await _fallbackTts.speak(text);
  }

  Future<void> _setLanguage(String fullLocale) async {
    // fullLocale is already in format like 'en-US', 'en-GB', etc.
    await _fallbackTts.setLanguage(fullLocale);
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

  /// Get extreme settings for 2× STRONGER fallback TTS
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

