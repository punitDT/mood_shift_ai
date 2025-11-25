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
      // Check if voice discovery has already been completed
      final storedVoiceMap = _storage.getPollyVoiceMap();

      if (storedVoiceMap != null && storedVoiceMap.isNotEmpty) {
        _voiceMap = storedVoiceMap;
        print('✅ [POLLY] Voice map loaded from storage (${_voiceMap!.length} languages)');

        // Debug: Print en-US voices to verify
        if (_voiceMap!.containsKey('en-US')) {
          final enUS = _voiceMap!['en-US'];
          print('   📋 [DEBUG] en-US voices:');
          print('      Generative: M=${enUS['generative']?['male']}, F=${enUS['generative']?['female']}');
          print('      Neural: M=${enUS['neural']?['male']}, F=${enUS['neural']?['female']}');
          print('      Standard: M=${enUS['standard']?['male']}, F=${enUS['standard']?['female']}');
        }
        return;
      }

      // First launch - discover and test voices
      print('🔍 [POLLY] First launch detected - starting voice discovery...');
      await _discoverAndTestVoices();

    } catch (e) {
      print('❌ [POLLY] Voice discovery error: $e');
      // Use fallback hardcoded voices
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

    // Preferred voices based on AWS documentation
    final preferredVoices = {
      'en-US': {'generative': {'male': 'Matthew', 'female': 'Danielle'}, 'neural': {'male': 'Matthew', 'female': 'Danielle'}, 'standard': {'male': 'Joey', 'female': 'Joanna'}},
      'en-GB': {'generative': {'male': 'Brian', 'female': 'Amy'}, 'neural': {'male': 'Brian', 'female': 'Amy'}, 'standard': {'male': 'Brian', 'female': 'Amy'}},
      'hi-IN': {'generative': {'female': 'Swara'}, 'neural': {'male': 'Arjun', 'female': 'Swara'}, 'standard': {'female': 'Raveena'}},
      'es-ES': {'generative': {'female': 'Conchita'}, 'neural': {'male': 'Enrique', 'female': 'Conchita'}, 'standard': {'male': 'Miguel', 'female': 'Paula'}},
      'cmn-CN': {'generative': {'female': 'Xiaoxiao'}, 'neural': {'male': 'Yunxi', 'female': 'Xiaoxiao'}, 'standard': {'female': 'Nicole'}},
      'fr-FR': {'generative': {'female': 'Celine'}, 'neural': {'male': 'Mathieu', 'female': 'Celine'}, 'standard': {'male': 'Sebastien', 'female': 'Celine'}},
      'de-DE': {'generative': {'female': 'Marlene'}, 'neural': {'male': 'Hans', 'female': 'Marlene'}, 'standard': {'male': 'Hans', 'female': 'Vicki'}},
      'arb': {'generative': {'female': 'Zeinab'}, 'neural': {'male': 'Talal', 'female': 'Zeinab'}, 'standard': {'male': 'Yasser', 'female': 'Zeinab'}},
      'ja-JP': {'generative': {'female': 'Mizuki'}, 'neural': {'male': 'Takumi', 'female': 'Mizuki'}, 'standard': {'male': 'Takumi', 'female': 'Mizuki'}},
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

  /// Speak with Main mode (normal or Golden Voice)
  /// Multi-level fallback: Generative → Neural → Standard → Plain TTS
  Future<void> speak(String text, MoodStyle style, {Map<String, String>? prosody}) async {
    if (text.isEmpty) return;

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
    } catch (e) {
      print('❌ [POLLY] Polly synthesis failed: $e');
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
    } catch (e) {
      print('❌ [POLLY] Polly 2× stronger synthesis failed: $e');
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
      final ssmlText = _buildStrongerSSML(text, style); // Pass style for extreme SSML

      print('⚡ [POLLY] Synthesizing 2× STRONGER with voice: $voiceId, language: $fullLocale, style: $style');

      // Try with configured engine first (generative > neural > standard)
      final engines = _pollyEngine == 'generative'
          ? ['generative', 'neural', 'standard']
          : _pollyEngine == 'neural'
              ? ['neural', 'standard']
              : ['standard'];

      for (final engine in engines) {
        try {
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

      // Use Golden SSML if golden voice is active, otherwise use normal SSML with LLM prosody
      final ssmlText = _storage.hasGoldenVoice()
          ? _buildGoldenSSML(text, style)
          : _buildSSML(text, prosody: prosody);

      final voiceMode = _storage.hasGoldenVoice() ? 'GOLDEN' : 'NORMAL';
      print('🎙️ [POLLY] Synthesizing with voice: $voiceId, language: $fullLocale ($voiceMode mode)');

      // Try with configured engine first (generative > neural > standard)
      final engines = _pollyEngine == 'generative'
          ? ['generative', 'neural', 'standard']
          : _pollyEngine == 'neural'
              ? ['neural', 'standard']
              : ['standard'];

      for (final engine in engines) {
        try {
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
            return null;
          }
        } catch (e) {
          if (engines.indexOf(engine) < engines.length - 1) {
            final nextEngine = engines[engines.indexOf(engine) + 1];
            print('⚠️ [POLLY] $engine engine failed: $e, trying $nextEngine engine...');
            continue;
          }
          rethrow;
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
    final Map<String, Map<String, Map<String, String?>>> voices = {
      "en-US": {
        "Generative": {
          "male": "Matthew",        // ✅ AWS Doc: Matthew is generative male
          "female": "Danielle",     // ✅ AWS Doc: Danielle, Joanna, Ruth, Salli, Stephen (using Danielle)
        },
        "Neural": {
          "male": "Matthew",        // ✅ AWS Doc: Gregory, Joey, Justin, Kevin, Matthew, Stephen, Patrick (using Matthew)
          "female": "Danielle",     // ✅ AWS Doc: Danielle, Ivy, Joanna, Kendra, Kimberly, Salli (using Danielle)
        },
        "Standard": {
          "male": "Joey",           // ✅ AWS Doc: Joey, Kevin (using Joey)
          "female": "Joanna",       // ✅ AWS Doc: Ivy, Joanna, Kendra, Kimberly, Salli (using Joanna)
        },
      },
      "en-GB": {
        "Generative": {
          "male": "Brian",          // ✅ AWS Doc: Brian, Arthur (using Brian)
          "female": "Amy",          // ✅ AWS Doc: Amy, Emma (using Amy)
        },
        "Neural": {
          "male": "Brian",          // ✅ AWS Doc: Brian, Arthur (using Brian)
          "female": "Amy",          // ✅ AWS Doc: Amy, Emma (using Amy)
        },
        "Standard": {
          "male": "Brian",          // ✅ AWS Doc: Brian, Arthur (using Brian)
          "female": "Amy",          // ✅ AWS Doc: Amy, Emma (using Amy)
        },
      },
      "hi-IN": {
        "Generative": {
          "male": null,             // ❌ AWS Doc: No male generative voice
          "female": "Swara",        // ✅ AWS Doc: Swara (female-only generative)
        },
        "Neural": {
          "male": "Arjun",          // ✅ AWS Doc: Arjun (male added 2025)
          "female": "Swara",        // ✅ AWS Doc: Swara
        },
        "Standard": {
          "male": null,             // ❌ AWS Doc: No male standard voice
          "female": "Raveena",      // ✅ AWS Doc: Raveena (female-only)
        },
      },
      "es-ES": {
        "Generative": {
          "male": null,             // ❌ AWS Doc: No male generative voice
          "female": "Conchita",     // ✅ AWS Doc: Conchita (female-only)
        },
        "Neural": {
          "male": "Enrique",        // ✅ AWS Doc: Enrique
          "female": "Conchita",     // ✅ AWS Doc: Conchita
        },
        "Standard": {
          "male": "Miguel",         // ✅ AWS Doc: Miguel
          "female": "Paula",        // ✅ AWS Doc: Paula
        },
      },
      "cmn-CN": {
        "Generative": {
          "male": null,             // ❌ AWS Doc: No male generative voice
          "female": "Xiaoxiao",     // ✅ AWS Doc: Xiaoxiao (female-only generative)
        },
        "Neural": {
          "male": "Yunxi",          // ✅ AWS Doc: Yunxi (male 2025 addition)
          "female": "Xiaoxiao",     // ✅ AWS Doc: Xiaoxiao
        },
        "Standard": {
          "male": null,             // ❌ AWS Doc: No male standard voice
          "female": "Nicole",       // ✅ AWS Doc: Nicole (female-only)
        },
      },
      "fr-FR": {
        "Generative": {
          "male": null,             // ❌ AWS Doc: No male generative voice
          "female": "Celine",       // ✅ AWS Doc: Celine (female-only)
        },
        "Neural": {
          "male": "Mathieu",        // ✅ AWS Doc: Mathieu
          "female": "Celine",       // ✅ AWS Doc: Celine
        },
        "Standard": {
          "male": "Sebastien",      // ✅ AWS Doc: Sebastien
          "female": "Celine",       // ✅ AWS Doc: Celine
        },
      },
      "de-DE": {
        "Generative": {
          "male": null,             // ❌ AWS Doc: No male generative voice
          "female": "Marlene",      // ✅ AWS Doc: Marlene (female-only)
        },
        "Neural": {
          "male": "Hans",           // ✅ AWS Doc: Hans
          "female": "Marlene",      // ✅ AWS Doc: Marlene
        },
        "Standard": {
          "male": "Hans",           // ✅ AWS Doc: Hans
          "female": "Vicki",        // ✅ AWS Doc: Vicki
        },
      },
      "arb": {
        "Generative": {
          "male": null,             // ❌ AWS Doc: No male generative voice
          "female": "Zeinab",       // ✅ AWS Doc: Zeinab (female-only, partial generative)
        },
        "Neural": {
          "male": "Talal",          // ✅ AWS Doc: Talal (male 2025 addition)
          "female": "Zeinab",       // ✅ AWS Doc: Zeinab
        },
        "Standard": {
          "male": "Yasser",         // ✅ AWS Doc: Yasser
          "female": "Zeinab",       // ✅ AWS Doc: Zeinab
        },
      },
      "ja-JP": {
        "Generative": {
          "male": null,             // ❌ AWS Doc: No male generative voice
          "female": "Mizuki",       // ✅ AWS Doc: Mizuki (female-only)
        },
        "Neural": {
          "male": "Takumi",         // ✅ AWS Doc: Takumi
          "female": "Mizuki",       // ✅ AWS Doc: Mizuki
        },
        "Standard": {
          "male": "Takumi",         // ✅ AWS Doc: Takumi
          "female": "Mizuki",       // ✅ AWS Doc: Mizuki
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

  /// Build SSML for Main mode (clean, natural)
  /// Uses LLM-provided prosody for natural speech
  String _buildSSML(String text, {Map<String, String>? prosody}) {
    // Use LLM-provided prosody or defaults
    final rate = prosody?['rate'] ?? 'medium';
    final pitch = prosody?['pitch'] ?? 'medium';
    final volume = prosody?['volume'] ?? 'medium';

    // Escape XML special characters
    final escapedText = _escapeXml(text);

    // Clean SSML - works with all engines (generative, neural, standard)
    final prosodyTag = '<prosody rate="$rate" pitch="$pitch" volume="$volume">$escapedText</prosody>';
    return '<speak>$prosodyTag</speak>';
  }

  /// Build EXTREME SSML for 2× STRONGER mode
  /// Amplified, energetic, powerful speech
  /// Compatible with generative, neural, and standard engines
  String _buildStrongerSSML(String text, MoodStyle style) {
    // Escape XML special characters
    final escapedText = _escapeXml(text);

    // 2× STRONGER: Fast, loud, emphasized
    // Uses emphasis tag for extra punch (works with all engines)
    return '<speak>'
        '<prosody rate="fast" volume="x-loud" pitch="+15%">'
        '<emphasis level="strong">$escapedText</emphasis>'
        '</prosody>'
        '</speak>';
  }

  /// Build SSML for Golden Voice mode
  /// Premium human-like SSML with advanced effects
  /// Uses amazon:effect tags that work best with generative engine
  String _buildGoldenSSML(String text, MoodStyle style) {
    // Escape XML special characters
    final escapedText = _escapeXml(text);

    // Premium Golden Voice SSML - Insanely human-like
    // DRC (Dynamic Range Compression) + soft phonation + vocal tract length
    // These effects work best with generative engine, gracefully degrade on neural/standard
    return '<speak>'
        '<amazon:effect name="drc">'
        '<prosody rate="slow" pitch="-10%" volume="soft">'
        '<amazon:effect phonation="soft">'
        '<amazon:effect vocal-tract-length="+12%">'
        '$escapedText'
        '</amazon:effect>'
        '</amazon:effect>'
        '</prosody>'
        '</amazon:effect>'
        '</speak>';
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

