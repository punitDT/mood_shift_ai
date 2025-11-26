import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Comprehensive AWS Polly SSML Feature Test
/// 
/// This test validates:
/// 1. Latest SSML tag support for us-east-1 region
/// 2. Engine-specific SSML compatibility (generative > neural > standard)
/// 3. Gender-wise voice availability
/// 4. SSML Effects (Voice Modulation) features:
///    - Main: Basic prosody (rate/volume/pitch per style)
///    - 2× Stronger: Energized with rate="medium", volume="+6dB", pitch="+15%"
///    - Golden Voice: Premium intimacy with rate="slow", pitch="-10%", volume="soft"
///
/// Based on AWS Polly Documentation (2025):
/// https://docs.aws.amazon.com/polly/latest/dg/supportedtags.html
///
/// SSML Support Matrix:
/// ┌─────────────────────────────┬────────────┬─────────┬──────────┐
/// │ SSML Tag                    │ Generative │ Neural  │ Standard │
/// ├─────────────────────────────┼────────────┼─────────┼──────────┤
/// │ <prosody>                   │ Partial    │ Partial │ Full     │
/// │ <emphasis>                  │ ✗          │ ✗       │ ✓        │
/// │ <amazon:effect name="drc">  │ ✗          │ ✓       │ ✓        │
/// │ <amazon:effect phonation>   │ ✗          │ ✗       │ ✓        │
/// │ <amazon:effect vocal-tract> │ ✗          │ ✗       │ ✓        │
/// │ <break>                     │ ✓          │ ✓       │ ✓        │
/// │ <lang>                      │ ✓          │ ✓       │ ✓        │
/// └─────────────────────────────┴────────────┴─────────┴──────────┘

void main(List<String> args) async {
  print('═══════════════════════════════════════════════════════════════');
  print('🧪 AWS Polly SSML Features Test (us-east-1)');
  print('═══════════════════════════════════════════════════════════════\n');

  if (args.length < 2) {
    print('❌ ERROR: Missing AWS credentials');
    print('USAGE: dart test/test_polly_ssml_features.dart <AWS_ACCESS_KEY> <AWS_SECRET_KEY>');
    exit(1);
  }

  final awsAccessKey = args[0];
  final awsSecretKey = args[1];
  final awsRegion = 'us-east-1';

  // Step 1: Fetch available voices
  print('📋 Step 1: Fetching available voices from AWS Polly...\n');
  final voices = await fetchPollyVoices(awsAccessKey, awsSecretKey, awsRegion);
  
  if (voices.isEmpty) {
    print('❌ Failed to fetch voices. Exiting.');
    exit(1);
  }

  // Step 2: Organize voices by engine and gender
  print('\n📊 Step 2: Organizing voices by engine and gender...\n');
  final voiceMap = organizeVoices(voices);
  printVoiceMap(voiceMap);

  // Step 3: Test SSML features
  print('\n🎯 Step 3: Testing SSML Effects Features...\n');
  await testSSMLFeatures(voiceMap, awsAccessKey, awsSecretKey, awsRegion);

  print('\n═══════════════════════════════════════════════════════════════');
  print('✅ Test Complete!');
  print('═══════════════════════════════════════════════════════════════\n');
}

/// Fetch all available voices from AWS Polly
Future<List<Map<String, dynamic>>> fetchPollyVoices(
  String awsAccessKey,
  String awsSecretKey,
  String awsRegion,
) async {
  try {
    final endpoint = 'https://polly.$awsRegion.amazonaws.com/v1/voices';
    final now = DateTime.now().toUtc();

    final headers = await generateSigV4Headers(
      method: 'GET',
      endpoint: endpoint,
      body: '',
      timestamp: now,
      awsAccessKey: awsAccessKey,
      awsSecretKey: awsSecretKey,
      awsRegion: awsRegion,
    );

    final response = await http.get(
      Uri.parse(endpoint),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final voices = (data['Voices'] as List<dynamic>)
          .map((v) => v as Map<String, dynamic>)
          .toList();
      
      print('✅ Found ${voices.length} total voices');
      return voices;
    } else {
      print('❌ Failed to fetch voices: ${response.statusCode}');
      print('   Error: ${response.body}');
      return [];
    }
  } catch (e) {
    print('❌ Error fetching voices: $e');
    return [];
  }
}

/// Organize voices by language, engine, and gender
Map<String, Map<String, Map<String, String>>> organizeVoices(
  List<Map<String, dynamic>> voices,
) {
  final voiceMap = <String, Map<String, Map<String, String>>>{};

  // All supported languages in MoodShift AI
  final supportedLanguages = [
    'en-US', 'en-GB', 'hi-IN', 'es-ES',
    'cmn-CN', 'fr-FR', 'de-DE', 'arb', 'ja-JP'
  ];

  for (final lang in supportedLanguages) {
    final langVoices = voices.where((v) => v['LanguageCode'] == lang).toList();

    if (langVoices.isEmpty) continue;

    voiceMap[lang] = {
      'generative': {'male': '', 'female': ''},
      'neural': {'male': '', 'female': ''},
      'standard': {'male': '', 'female': ''},
    };

    for (final voice in langVoices) {
      final voiceId = voice['Id'] as String;
      final gender = (voice['Gender'] as String).toLowerCase();
      final supportedEngines = (voice['SupportedEngines'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();

      // Assign voices to engines (priority: generative > neural > standard)
      for (final engine in ['generative', 'neural', 'standard']) {
        if (supportedEngines.contains(engine)) {
          if (voiceMap[lang]![engine]![gender]!.isEmpty) {
            voiceMap[lang]![engine]![gender] = voiceId;
          }
        }
      }
    }
  }

  return voiceMap;
}

/// Print voice map in a readable format
void printVoiceMap(Map<String, Map<String, Map<String, String>>> voiceMap) {
  for (final lang in voiceMap.keys) {
    print('🌍 Language: $lang');
    for (final engine in ['generative', 'neural', 'standard']) {
      final male = voiceMap[lang]![engine]!['male'];
      final female = voiceMap[lang]![engine]!['female'];
      print('   $engine: Male=$male, Female=$female');
    }
    print('');
  }
}

/// Get test phrase for each language
String getTestPhrase(String languageCode) {
  final phrases = {
    'en-US': 'Hello, this is a test of the SSML features.',
    'en-GB': 'Hello, this is a test of the SSML features.',
    'hi-IN': 'नमस्ते, यह SSML सुविधाओं का परीक्षण है।',
    'es-ES': 'Hola, esta es una prueba de las funciones SSML.',
    'cmn-CN': '你好，这是SSML功能的测试。',
    'fr-FR': 'Bonjour, ceci est un test des fonctionnalités SSML.',
    'de-DE': 'Hallo, dies ist ein Test der SSML-Funktionen.',
    'arb': 'مرحبا، هذا اختبار لميزات SSML.',
    'ja-JP': 'こんにちは、これはSSML機能のテストです。',
  };
  return phrases[languageCode] ?? 'Test';
}

/// Test SSML features for all three modes
Future<void> testSSMLFeatures(
  Map<String, Map<String, Map<String, String>>> voiceMap,
  String awsAccessKey,
  String awsSecretKey,
  String awsRegion,
) async {

  // Test cases for each feature - ENGINE-SPECIFIC SSML
  // Using {{TEXT}} as placeholder to be replaced with language-specific text
  final testCases = [
    // GENERATIVE ENGINE TESTS
    {
      'name': 'Main - Basic Prosody (Gentle) - GENERATIVE',
      'ssml': '<speak><prosody rate="x-slow" volume="x-soft">{{TEXT}}</prosody></speak>',
      'engines': ['generative'],
    },
    {
      'name': 'Main - Basic Prosody (Chaos) - GENERATIVE',
      'ssml': '<speak><prosody rate="medium" volume="x-loud">{{TEXT}}</prosody></speak>',
      'engines': ['generative'],
    },
    {
      'name': '2× Stronger - Energized - GENERATIVE',
      'ssml': '<speak><prosody rate="medium" volume="x-loud">{{TEXT}}</prosody></speak>',
      'engines': ['generative'],
    },
    {
      'name': 'Golden Voice - Premium Intimacy - GENERATIVE',
      'ssml': '<speak><prosody rate="x-slow" volume="x-soft">{{TEXT}}</prosody></speak>',
      'engines': ['generative'],
    },

    // NEURAL ENGINE TESTS
    {
      'name': 'Main - Basic Prosody (Gentle) - NEURAL',
      'ssml': '<speak><prosody volume="+0dB">{{TEXT}}</prosody></speak>',
      'engines': ['neural'],
    },
    {
      'name': 'Main - Basic Prosody (Chaos) - NEURAL',
      'ssml': '<speak><prosody volume="+6dB">{{TEXT}}</prosody></speak>',
      'engines': ['neural'],
    },
    {
      'name': '2× Stronger - Energized - NEURAL',
      'ssml': '<speak><prosody volume="+6dB">{{TEXT}}</prosody></speak>',
      'engines': ['neural'],
    },
    {
      'name': 'Golden Voice - Premium Intimacy - NEURAL',
      'ssml': '<speak><amazon:effect name="drc"><prosody volume="+0dB">{{TEXT}}</prosody></amazon:effect></speak>',
      'engines': ['neural'],
    },

    // STANDARD ENGINE TESTS
    {
      'name': 'Main - Basic Prosody (Gentle) - STANDARD',
      'ssml': '<speak><prosody rate="slow" volume="soft" pitch="low">{{TEXT}}</prosody></speak>',
      'engines': ['standard'],
    },
    {
      'name': 'Main - Basic Prosody (Chaos) - STANDARD',
      'ssml': '<speak><prosody rate="medium" volume="loud" pitch="high">{{TEXT}}</prosody></speak>',
      'engines': ['standard'],
    },
    {
      'name': '2× Stronger - Energized - STANDARD',
      'ssml': '<speak><emphasis level="strong"><prosody rate="medium" volume="+6dB" pitch="+15%">{{TEXT}}</prosody></emphasis></speak>',
      'engines': ['standard'],
    },
    {
      'name': 'Golden Voice - Premium Intimacy - STANDARD',
      'ssml': '<speak><amazon:effect name="drc"><amazon:effect phonation="soft"><amazon:effect vocal-tract-length="+12%"><prosody rate="slow" pitch="-10%" volume="soft">{{TEXT}}</prosody></amazon:effect></amazon:effect></amazon:effect></speak>',
      'engines': ['standard'],
    },

    // CROSS-ENGINE TESTS
    {
      'name': 'DRC Effect (Neural/Standard only)',
      'ssml': '<speak><amazon:effect name="drc">{{TEXT}}</amazon:effect></speak>',
      'engines': ['neural', 'standard'],
    },
    {
      'name': 'Emphasis (Standard only)',
      'ssml': '<speak><emphasis level="strong">{{TEXT}}</emphasis></speak>',
      'engines': ['standard'],
    },
  ];

  // Test each language
  for (final lang in voiceMap.keys) {
    print('\n╔═══════════════════════════════════════════════════════════════╗');
    print('║ 🌍 Testing Language: $lang');
    print('╚═══════════════════════════════════════════════════════════════╝\n');

    final testText = getTestPhrase(lang);

    // Update test cases with language-specific text
    final langTestCases = testCases.map((tc) {
      final ssml = (tc['ssml'] as String).replaceAll('{{TEXT}}', testText);
      return {
        'name': tc['name'],
        'ssml': ssml,
        'engines': tc['engines'],
      };
    }).toList();

    for (final testCase in langTestCases) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🎯 ${testCase['name']}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final ssml = testCase['ssml'] as String;
      final supportedEngines = testCase['engines'] as List<String>;

      for (final engine in supportedEngines) {
        for (final gender in ['male', 'female']) {
          final voiceId = voiceMap[lang]![engine]![gender];

          if (voiceId == null || voiceId.isEmpty) {
            print('   ⚠️  $engine ($gender): No voice available');
            continue;
          }

          final result = await testSSML(
            voiceId: voiceId,
            languageCode: lang,
            engine: engine,
            ssml: ssml,
            awsAccessKey: awsAccessKey,
            awsSecretKey: awsSecretKey,
            awsRegion: awsRegion,
          );

          final status = result['success'] ? '✅' : '❌';
          final errorMsg = result['error'] ?? '';
          print('   $status $engine ($gender): $voiceId${errorMsg.isNotEmpty ? ' - $errorMsg' : ''}');
        }
      }
      print('');
    }
  }
}

/// Test a single SSML request
Future<Map<String, dynamic>> testSSML({
  required String voiceId,
  required String languageCode,
  required String engine,
  required String ssml,
  required String awsAccessKey,
  required String awsSecretKey,
  required String awsRegion,
}) async {
  try {
    final endpoint = 'https://polly.$awsRegion.amazonaws.com/v1/speech';
    final now = DateTime.now().toUtc();

    final requestBody = jsonEncode({
      'Text': ssml,
      'TextType': 'ssml',
      'VoiceId': voiceId,
      'LanguageCode': languageCode,
      'Engine': engine,
      'OutputFormat': 'mp3',
    });

    final headers = await generateSigV4Headers(
      method: 'POST',
      endpoint: endpoint,
      body: requestBody,
      timestamp: now,
      awsAccessKey: awsAccessKey,
      awsSecretKey: awsSecretKey,
      awsRegion: awsRegion,
    );

    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: requestBody,
    );

    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      final errorBody = response.body;
      String errorMsg = 'HTTP ${response.statusCode}';
      try {
        final errorJson = jsonDecode(errorBody);
        errorMsg = errorJson['message'] ?? errorMsg;
      } catch (_) {
        // If can't parse JSON, use the raw body
        if (errorBody.isNotEmpty && errorBody.length < 100) {
          errorMsg = errorBody;
        }
      }
      return {'success': false, 'error': errorMsg};
    }
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

/// Generate AWS Signature V4 headers
Future<Map<String, String>> generateSigV4Headers({
  required String method,
  required String endpoint,
  required String body,
  required DateTime timestamp,
  required String awsAccessKey,
  required String awsSecretKey,
  required String awsRegion,
}) async {
  final uri = Uri.parse(endpoint);
  final host = uri.host;
  final canonicalUri = uri.path;

  final amzDate = timestamp.toIso8601String().replaceAll(RegExp(r'[:\-]|\.\d{3}'), '').substring(0, 15) + 'Z';
  final dateStamp = amzDate.substring(0, 8);

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

  final credentialScope = '$dateStamp/$awsRegion/polly/aws4_request';
  final stringToSign = 'AWS4-HMAC-SHA256\n'
      '$amzDate\n'
      '$credentialScope\n'
      '${sha256.convert(utf8.encode(canonicalRequest))}';

  var kDate = Hmac(sha256, utf8.encode('AWS4$awsSecretKey')).convert(utf8.encode(dateStamp)).bytes;
  var kRegion = Hmac(sha256, kDate).convert(utf8.encode(awsRegion)).bytes;
  var kService = Hmac(sha256, kRegion).convert(utf8.encode('polly')).bytes;
  var kSigning = Hmac(sha256, kService).convert(utf8.encode('aws4_request')).bytes;
  var signature = Hmac(sha256, kSigning).convert(utf8.encode(stringToSign)).toString();

  final authorizationHeader = 'AWS4-HMAC-SHA256 Credential=$awsAccessKey/$credentialScope, '
      'SignedHeaders=$signedHeaders, Signature=$signature';

  return {
    'Content-Type': 'application/json',
    'X-Amz-Date': amzDate,
    'Authorization': authorizationHeader,
  };
}

