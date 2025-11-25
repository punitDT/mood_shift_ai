import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:convert/convert.dart';

/// AWS Polly Voice Testing Utility
/// Tests all voices for each language and gender combination in us-east-1
///
/// Run this test to discover which voices actually support generative engine
///
/// Usage:
/// ```bash
/// flutter test test/polly_voice_test.dart
/// ```

void main() async {
  print('🧪 AWS Polly Voice Testing Utility');
  print('=' * 80);

  // Load environment variables
  await dotenv.load(fileName: ".env");

  final tester = PollyVoiceTester(
    accessKey: dotenv.env['AWS_ACCESS_KEY'] ?? '',
    secretKey: dotenv.env['AWS_SECRET_KEY'] ?? '',
    region: dotenv.env['AWS_REGION'] ?? 'us-east-1',
  );

  await tester.runAllTests();
}

class PollyVoiceTester {
  final String accessKey;
  final String secretKey;
  final String region;

  PollyVoiceTester({
    required this.accessKey,
    required this.secretKey,
    required this.region,
  });

  /// Test configurations for each language
  /// Format: languageCode -> {gender -> [voiceIds to test]}
  final Map<String, Map<String, List<String>>> testVoices = {
    'en-US': {
      'male': ['Matthew', 'Joey', 'Justin', 'Kevin', 'Stephen'],
      'female': ['Danielle', 'Joanna', 'Kendra', 'Kimberly', 'Salli', 'Ivy', 'Ruth'],
    },
    'en-GB': {
      'male': ['Brian', 'Arthur'],
      'female': ['Amy', 'Emma'],
    },
    'hi-IN': {
      'male': ['Kajal'], // No male voice available
      'female': ['Kajal', 'Aditi'],
    },
    'es-ES': {
      'male': ['Sergio', 'Enrique'],
      'female': ['Lucia', 'Conchita'],
    },
    'es-MX': {
      'male': ['Andres'],
      'female': ['Mia'],
    },
    'fr-FR': {
      'male': ['Remi', 'Mathieu'],
      'female': ['Lea', 'Celine'],
    },
    'fr-CA': {
      'male': ['Liam'],
      'female': ['Gabrielle', 'Chantal'],
    },
    'de-DE': {
      'male': ['Daniel', 'Hans'],
      'female': ['Vicki', 'Marlene'],
    },
    'it-IT': {
      'male': ['Adriano', 'Giorgio'],
      'female': ['Bianca', 'Carla'],
    },
    'pt-BR': {
      'male': ['Thiago'],
      'female': ['Camila', 'Vitoria', 'Vitória'],
    },
    'ja-JP': {
      'male': ['Takumi'],
      'female': ['Kazuha', 'Mizuki'],
    },
    'ko-KR': {
      'male': ['Seoyeon'], // No male voice
      'female': ['Seoyeon'],
    },
    'cmn-CN': {
      'male': ['Zhiyu'], // Only female available
      'female': ['Zhiyu'],
    },
    'arb': {
      'male': ['Zeina'], // Only female available
      'female': ['Zeina'],
    },
    'ar-AE': {
      'male': ['Hala'], // Only female available
      'female': ['Hala'],
    },
  };

  /// Test text for each language
  final Map<String, String> testTexts = {
    'en-US': 'Hello, this is a test.',
    'en-GB': 'Hello, this is a test.',
    'hi-IN': 'नमस्ते, यह एक परीक्षण है।',
    'es-ES': 'Hola, esto es una prueba.',
    'es-MX': 'Hola, esto es una prueba.',
    'fr-FR': 'Bonjour, ceci est un test.',
    'fr-CA': 'Bonjour, ceci est un test.',
    'de-DE': 'Hallo, das ist ein Test.',
    'it-IT': 'Ciao, questo è un test.',
    'pt-BR': 'Olá, este é um teste.',
    'ja-JP': 'こんにちは、これはテストです。',
    'ko-KR': '안녕하세요, 이것은 테스트입니다.',
    'cmn-CN': '你好，这是一个测试。',
    'arb': 'مرحبا، هذا اختبار.',
    'ar-AE': 'مرحبا، هذا اختبار.',
  };

  Future<void> runAllTests() async {
    print('\n📋 Testing Configuration:');
    print('   Region: $region');
    print('   Access Key: ${accessKey.substring(0, 8)}...');
    print('   Languages: ${testVoices.keys.length}');
    print('\n');

    final results = <String, Map<String, Map<String, List<String>>>>{};

    for (final languageCode in testVoices.keys) {
      print('\n${'=' * 80}');
      print('🌍 Testing Language: $languageCode');
      print('=' * 80);

      results[languageCode] = {
        'generative': {'male': [], 'female': []},
        'neural': {'male': [], 'female': []},
        'standard': {'male': [], 'female': []},
      };

      for (final gender in testVoices[languageCode]!.keys) {
        print('\n👤 Gender: $gender');
        print('-' * 80);

        for (final voiceId in testVoices[languageCode]![gender]!) {
          print('\n   🎙️  Testing voice: $voiceId');

          // Test generative engine
          final generativeResult = await _testVoice(
            voiceId: voiceId,
            languageCode: languageCode,
            engine: 'generative',
            text: testTexts[languageCode] ?? 'Test',
          );

          if (generativeResult) {
            print('      ✅ GENERATIVE: Supported');
            results[languageCode]!['generative']![gender]!.add(voiceId);
          } else {
            print('      ❌ GENERATIVE: Not supported');
          }

          // Test neural engine
          final neuralResult = await _testVoice(
            voiceId: voiceId,
            languageCode: languageCode,
            engine: 'neural',
            text: testTexts[languageCode] ?? 'Test',
          );

          if (neuralResult) {
            print('      ✅ NEURAL: Supported');
            results[languageCode]!['neural']![gender]!.add(voiceId);
          } else {
            print('      ❌ NEURAL: Not supported');
          }

          // Test standard engine
          final standardResult = await _testVoice(
            voiceId: voiceId,
            languageCode: languageCode,
            engine: 'standard',
            text: testTexts[languageCode] ?? 'Test',
          );

          if (standardResult) {
            print('      ✅ STANDARD: Supported');
            results[languageCode]!['standard']![gender]!.add(voiceId);
          } else {
            print('      ❌ STANDARD: Not supported');
          }

          // Small delay to avoid rate limiting
          await Future.delayed(Duration(milliseconds: 200));
        }
      }
    }

    // Print summary
    _printSummary(results);

    // Generate Dart code for voice mapping
    _generateDartCode(results);
  }

  Future<bool> _testVoice({
    required String voiceId,
    required String languageCode,
    required String engine,
    required String text,
  }) async {
    try {
      final endpoint = 'https://polly.$region.amazonaws.com/v1/speech';
      final now = DateTime.now().toUtc();

      final ssmlText = '<speak>$text</speak>';

      final requestBody = jsonEncode({
        'Text': ssmlText,
        'TextType': 'ssml',
        'VoiceId': voiceId,
        'LanguageCode': languageCode,
        'Engine': engine,
        'OutputFormat': 'mp3',
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
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout');
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
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

    final credentialScope = '$dateStamp/$region/polly/aws4_request';
    final stringToSign = 'AWS4-HMAC-SHA256\n'
        '$amzDate\n'
        '$credentialScope\n'
        '${sha256.convert(utf8.encode(canonicalRequest))}';

    final signingKey = _getSignatureKey(secretKey, dateStamp, region, 'polly');
    final signature = hex.encode(Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).bytes);

    final authorizationHeader = 'AWS4-HMAC-SHA256 '
        'Credential=$accessKey/$credentialScope, '
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
    return '${dt.year}${_pad(dt.month)}${_pad(dt.day)}T${_pad(dt.hour)}${_pad(dt.minute)}${_pad(dt.second)}Z';
  }

  String _formatDateStamp(DateTime dt) {
    return '${dt.year}${_pad(dt.month)}${_pad(dt.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  void _printSummary(Map<String, Map<String, Map<String, List<String>>>> results) {
    print('\n\n');
    print('=' * 80);
    print('📊 TEST SUMMARY');
    print('=' * 80);

    for (final languageCode in results.keys) {
      print('\n🌍 $languageCode:');

      for (final engine in ['generative', 'neural', 'standard']) {
        final maleVoices = results[languageCode]![engine]!['male']!;
        final femaleVoices = results[languageCode]![engine]!['female']!;

        if (maleVoices.isNotEmpty || femaleVoices.isNotEmpty) {
          print('   ${engine.toUpperCase()}:');
          if (maleVoices.isNotEmpty) {
            print('      Male: ${maleVoices.join(', ')}');
          }
          if (femaleVoices.isNotEmpty) {
            print('      Female: ${femaleVoices.join(', ')}');
          }
        }
      }
    }
  }

  void _generateDartCode(Map<String, Map<String, Map<String, List<String>>>> results) {
    print('\n\n');
    print('=' * 80);
    print('💻 GENERATED DART CODE FOR VOICE MAPPING');
    print('=' * 80);
    print('\n// Copy this code to replace the hardcoded voices in polly_tts_service.dart\n');
    print('final Map<String, Map<String, Map<String, String>>> voices = {');

    for (final languageCode in results.keys) {
      print('  "$languageCode": {');

      // Generative
      final genMale = results[languageCode]!['generative']!['male']!;
      final genFemale = results[languageCode]!['generative']!['female']!;

      if (genMale.isNotEmpty || genFemale.isNotEmpty) {
        print('    "Generative": {');
        print('      "male": "${genMale.isNotEmpty ? genMale.first : (genFemale.isNotEmpty ? genFemale.first : 'N/A')}",');
        print('      "female": "${genFemale.isNotEmpty ? genFemale.first : (genMale.isNotEmpty ? genMale.first : 'N/A')}",');
        print('    },');
      }

      // Neural
      final neuralMale = results[languageCode]!['neural']!['male']!;
      final neuralFemale = results[languageCode]!['neural']!['female']!;

      if (neuralMale.isNotEmpty || neuralFemale.isNotEmpty) {
        print('    "Neural": {');
        print('      "male": "${neuralMale.isNotEmpty ? neuralMale.first : (neuralFemale.isNotEmpty ? neuralFemale.first : 'N/A')}",');
        print('      "female": "${neuralFemale.isNotEmpty ? neuralFemale.first : (neuralMale.isNotEmpty ? neuralMale.first : 'N/A')}",');
        print('    },');
      }

      // Standard
      final stdMale = results[languageCode]!['standard']!['male']!;
      final stdFemale = results[languageCode]!['standard']!['female']!;

      if (stdMale.isNotEmpty || stdFemale.isNotEmpty) {
        print('    "Standard": {');
        print('      "male": "${stdMale.isNotEmpty ? stdMale.first : (stdFemale.isNotEmpty ? stdFemale.first : 'N/A')}",');
        print('      "female": "${stdFemale.isNotEmpty ? stdFemale.first : (stdMale.isNotEmpty ? stdMale.first : 'N/A')}",');
        print('    },');
      }

      print('  },');
    }

    print('};');

    print('\n\n');
    print('=' * 80);
    print('✅ RECOMMENDATIONS:');
    print('=' * 80);
    print('\n1. Copy the generated voice mapping above');
    print('2. Replace the hardcoded voices in lib/app/services/polly_tts_service.dart');
    print('3. Update the _getPollyVoice() method to use correct engine names');
    print('4. Test the app with different languages and genders');
    print('\n');
  }
}
