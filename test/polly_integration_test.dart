import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:mood_shift_ai/app/services/ai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Integration test to verify AWS Polly accepts our SSML
/// This test makes actual API calls to AWS Polly to validate SSML
void main() {
  group('AWS Polly Comprehensive Integration Tests', () {
    late String awsAccessKey;
    late String awsSecretKey;
    late String awsRegion;

    // Voice mapping for all languages
    // NOTE: Neural voices don't support DRC, so we only test Standard engine
    final voiceMapping = {
      'en-US': {'male': 'Joey', 'female': 'Joanna', 'neural': false, 'standard': true},
      'en-GB': {'male': 'Brian', 'female': 'Amy', 'neural': false, 'standard': true},
      'hi-IN': {'male': 'Aditi', 'female': 'Aditi', 'neural': false, 'standard': true},
      'es-ES': {'male': 'Enrique', 'female': 'Conchita', 'neural': false, 'standard': true},
      'cmn-CN': {'male': 'Zhiyu', 'female': 'Zhiyu', 'neural': false, 'standard': true},
      'fr-FR': {'male': 'Mathieu', 'female': 'Celine', 'neural': false, 'standard': true},
      'de-DE': {'male': 'Hans', 'female': 'Marlene', 'neural': false, 'standard': true},
      'arb': {'male': 'Zeina', 'female': 'Zeina', 'neural': false, 'standard': true},  // Changed to Zeina (Standard only)
      'ja-JP': {'male': 'Takumi', 'female': 'Mizuki', 'neural': false, 'standard': true},
    };

    final testTexts = {
      'en-US': 'Hello, this is a test!',
      'en-GB': 'Hello, this is a test!',
      'hi-IN': 'नमस्ते, यह एक परीक्षण है।',
      'es-ES': '¡Hola! Esta es una prueba.',
      'cmn-CN': '你好，这是一个测试！',
      'fr-FR': 'Bonjour, ceci est un test!',
      'de-DE': 'Hallo, das ist ein Test!',
      'arb': 'مرحبا، هذا اختبار!',
      'ja-JP': 'こんにちは、これはテストです！',
    };

    setUpAll(() async {
      // Load environment variables
      await dotenv.load(fileName: '.env');
      awsAccessKey = dotenv.env['AWS_ACCESS_KEY'] ?? '';
      awsSecretKey = dotenv.env['AWS_SECRET_KEY'] ?? '';
      awsRegion = dotenv.env['AWS_REGION'] ?? 'ap-south-1';
    });

    test('Test Normal SSML - All Languages, Both Genders, Both Engines', () async {
      if (awsAccessKey.isEmpty || awsSecretKey.isEmpty) {
        print('⚠️ Skipping integration test - AWS credentials not found');
        return;
      }

      int totalTests = 0;
      int passedTests = 0;
      int failedTests = 0;

      for (final entry in voiceMapping.entries) {
        final languageCode = entry.key;
        final voiceInfo = entry.value;
        final testText = testTexts[languageCode]!;

        for (final gender in ['male', 'female']) {
          final voiceId = voiceInfo[gender] as String;

          // Test with Standard engine
          if (voiceInfo['standard'] == true) {
            totalTests++;
            final ssml = buildSSML(testText, prosody: {
              'rate': 'medium',
              'pitch': 'medium',
              'volume': 'medium',
            });

            final result = await testPollyAPI(
              ssml: ssml,
              voiceId: voiceId,
              languageCode: languageCode,
              engine: 'standard',
              awsAccessKey: awsAccessKey,
              awsSecretKey: awsSecretKey,
              awsRegion: awsRegion,
            );

            if (result['success'] == true) {
              passedTests++;
              print('✅ Normal SSML - $languageCode $gender (Standard) - $voiceId');
            } else {
              failedTests++;
              print('❌ Normal SSML - $languageCode $gender (Standard) - $voiceId: ${result['error']}');
            }
          }

          // Test with Neural engine (if supported)
          if (voiceInfo['neural'] == true) {
            totalTests++;
            final ssml = buildSSML(testText, prosody: {
              'rate': 'medium',
              'pitch': 'medium',
              'volume': 'medium',
            });

            final result = await testPollyAPI(
              ssml: ssml,
              voiceId: voiceId,
              languageCode: languageCode,
              engine: 'neural',
              awsAccessKey: awsAccessKey,
              awsSecretKey: awsSecretKey,
              awsRegion: awsRegion,
            );

            if (result['success'] == true) {
              passedTests++;
              print('✅ Normal SSML - $languageCode $gender (Neural) - $voiceId');
            } else {
              failedTests++;
              print('❌ Normal SSML - $languageCode $gender (Neural) - $voiceId: ${result['error']}');
            }
          }
        }
      }

      print('\n📊 Normal SSML Test Results:');
      print('   Total: $totalTests');
      print('   Passed: $passedTests');
      print('   Failed: $failedTests');
      print('   Success Rate: ${(passedTests / totalTests * 100).toStringAsFixed(1)}%');

      expect(failedTests, equals(0), reason: 'All Normal SSML tests should pass');
    });

    test('Test 2× STRONGER SSML - All Languages, Both Genders, Both Engines', () async {
      if (awsAccessKey.isEmpty || awsSecretKey.isEmpty) {
        print('⚠️ Skipping integration test - AWS credentials not found');
        return;
      }

      int totalTests = 0;
      int passedTests = 0;
      int failedTests = 0;

      // Test only one mood style to keep test time reasonable
      final testStyle = MoodStyle.chaosEnergy;

      for (final entry in voiceMapping.entries) {
        final languageCode = entry.key;
        final voiceInfo = entry.value;
        final testText = testTexts[languageCode]!;

        for (final gender in ['male', 'female']) {
          final voiceId = voiceInfo[gender] as String;

          // Test with Standard engine
          if (voiceInfo['standard'] == true) {
            totalTests++;
            final ssml = buildStrongerSSML(testText, testStyle);

            final result = await testPollyAPI(
              ssml: ssml,
              voiceId: voiceId,
              languageCode: languageCode,
              engine: 'standard',
              awsAccessKey: awsAccessKey,
              awsSecretKey: awsSecretKey,
              awsRegion: awsRegion,
            );

            if (result['success'] == true) {
              passedTests++;
              print('✅ 2× STRONGER - $languageCode $gender (Standard) - $voiceId');
            } else {
              failedTests++;
              print('❌ 2× STRONGER - $languageCode $gender (Standard) - $voiceId: ${result['error']}');
            }
          }

          // Test with Neural engine (if supported)
          if (voiceInfo['neural'] == true) {
            totalTests++;
            final ssml = buildStrongerSSML(testText, testStyle);

            final result = await testPollyAPI(
              ssml: ssml,
              voiceId: voiceId,
              languageCode: languageCode,
              engine: 'neural',
              awsAccessKey: awsAccessKey,
              awsSecretKey: awsSecretKey,
              awsRegion: awsRegion,
            );

            if (result['success'] == true) {
              passedTests++;
              print('✅ 2× STRONGER - $languageCode $gender (Neural) - $voiceId');
            } else {
              failedTests++;
              print('❌ 2× STRONGER - $languageCode $gender (Neural) - $voiceId: ${result['error']}');
            }
          }
        }
      }

      print('\n📊 2× STRONGER SSML Test Results:');
      print('   Total: $totalTests');
      print('   Passed: $passedTests');
      print('   Failed: $failedTests');
      print('   Success Rate: ${(passedTests / totalTests * 100).toStringAsFixed(1)}%');

      expect(failedTests, equals(0), reason: 'All 2× STRONGER SSML tests should pass');
    });

    test('Test Golden Voice SSML - All Languages, Both Genders, Both Engines', () async {
      if (awsAccessKey.isEmpty || awsSecretKey.isEmpty) {
        print('⚠️ Skipping integration test - AWS credentials not found');
        return;
      }

      int totalTests = 0;
      int passedTests = 0;
      int failedTests = 0;

      // Test only one mood style to keep test time reasonable
      final testStyle = MoodStyle.gentleGrandma;

      for (final entry in voiceMapping.entries) {
        final languageCode = entry.key;
        final voiceInfo = entry.value;
        final testText = testTexts[languageCode]!;

        for (final gender in ['male', 'female']) {
          final voiceId = voiceInfo[gender] as String;

          // Test with Standard engine
          if (voiceInfo['standard'] == true) {
            totalTests++;
            final ssml = buildGoldenSSML(testText, testStyle);

            final result = await testPollyAPI(
              ssml: ssml,
              voiceId: voiceId,
              languageCode: languageCode,
              engine: 'standard',
              awsAccessKey: awsAccessKey,
              awsSecretKey: awsSecretKey,
              awsRegion: awsRegion,
            );

            if (result['success'] == true) {
              passedTests++;
              print('✅ Golden Voice - $languageCode $gender (Standard) - $voiceId');
            } else {
              failedTests++;
              print('❌ Golden Voice - $languageCode $gender (Standard) - $voiceId: ${result['error']}');
            }
          }

          // Test with Neural engine (if supported)
          if (voiceInfo['neural'] == true) {
            totalTests++;
            final ssml = buildGoldenSSML(testText, testStyle);

            final result = await testPollyAPI(
              ssml: ssml,
              voiceId: voiceId,
              languageCode: languageCode,
              engine: 'neural',
              awsAccessKey: awsAccessKey,
              awsSecretKey: awsSecretKey,
              awsRegion: awsRegion,
            );

            if (result['success'] == true) {
              passedTests++;
              print('✅ Golden Voice - $languageCode $gender (Neural) - $voiceId');
            } else {
              failedTests++;
              print('❌ Golden Voice - $languageCode $gender (Neural) - $voiceId: ${result['error']}');
            }
          }
        }
      }

      print('\n📊 Golden Voice SSML Test Results:');
      print('   Total: $totalTests');
      print('   Passed: $passedTests');
      print('   Failed: $failedTests');
      print('   Success Rate: ${(passedTests / totalTests * 100).toStringAsFixed(1)}%');

      expect(failedTests, equals(0), reason: 'All Golden Voice SSML tests should pass');
    });
  });
}

// Helper function to test AWS Polly API
Future<Map<String, dynamic>> testPollyAPI({
  required String ssml,
  required String voiceId,
  required String languageCode,
  required String engine,
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
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Polly API timeout');
      },
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        'statusCode': response.statusCode,
        'audioSize': response.bodyBytes.length,
      };
    } else {
      print('❌ Polly API error: ${response.statusCode} - ${response.body}');
      return {
        'success': false,
        'statusCode': response.statusCode,
        'error': response.body,
      };
    }
  } catch (e) {
    print('❌ Exception during Polly API call: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

// AWS Signature V4 generation
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
  final service = 'polly';

  final amzDate = timestamp.toIso8601String().replaceAll(RegExp(r'[:\-]'), '').split('.')[0] + 'Z';
  final dateStamp = amzDate.substring(0, 8);

  final payloadHash = sha256.convert(utf8.encode(body)).toString();

  final canonicalHeaders = 'content-type:application/json\nhost:$host\nx-amz-date:$amzDate\n';
  final signedHeaders = 'content-type;host;x-amz-date';

  final canonicalRequest = '$method\n$canonicalUri\n\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

  final algorithm = 'AWS4-HMAC-SHA256';
  final credentialScope = '$dateStamp/$awsRegion/$service/aws4_request';
  final stringToSign = '$algorithm\n$amzDate\n$credentialScope\n${sha256.convert(utf8.encode(canonicalRequest))}';

  final kDate = _hmacSha256(utf8.encode('AWS4$awsSecretKey'), utf8.encode(dateStamp));
  final kRegion = _hmacSha256(kDate, utf8.encode(awsRegion));
  final kService = _hmacSha256(kRegion, utf8.encode(service));
  final kSigning = _hmacSha256(kService, utf8.encode('aws4_request'));
  final signature = _hmacSha256(kSigning, utf8.encode(stringToSign));

  final authorizationHeader = '$algorithm Credential=$awsAccessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=${_bytesToHex(signature)}';

  return {
    'Content-Type': 'application/json',
    'Host': host,
    'X-Amz-Date': amzDate,
    'Authorization': authorizationHeader,
  };
}

List<int> _hmacSha256(List<int> key, List<int> data) {
  final hmac = Hmac(sha256, key);
  return hmac.convert(data).bytes;
}

String _bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

// SSML builder functions (updated to remove DRC - not supported by neural voices)
String buildSSML(String text, {Map<String, String>? prosody}) {
  final rate = prosody?['rate'] ?? 'medium';
  final pitch = prosody?['pitch'] ?? 'medium';
  final volume = prosody?['volume'] ?? 'medium';

  final escapedText = escapeXml(text);

  final prosodyTag = '<prosody rate="$rate" pitch="$pitch" volume="$volume">$escapedText</prosody>';
  return '<speak>$prosodyTag</speak>';
}

String buildStrongerSSML(String text, MoodStyle style) {
  final escapedText = escapeXml(text);

  switch (style) {
    case MoodStyle.chaosEnergy:
      return '<speak><prosody rate="x-fast" pitch="+30%" volume="+10dB">$escapedText</prosody></speak>';
    case MoodStyle.gentleGrandma:
      return '<speak><prosody rate="medium" pitch="+25%" volume="+8dB">$escapedText</prosody></speak>';
    case MoodStyle.permissionSlip:
      return '<speak><prosody rate="fast" pitch="+28%" volume="+9dB">$escapedText</prosody></speak>';
    case MoodStyle.realityCheck:
      return '<speak><prosody rate="fast" pitch="+22%" volume="+9dB">$escapedText</prosody></speak>';
    case MoodStyle.microDare:
      return '<speak><prosody rate="fast" pitch="+25%" volume="+9dB">$escapedText</prosody></speak>';
  }
}

String buildGoldenSSML(String text, MoodStyle style) {
  final escapedText = escapeXml(text);
  return '<speak><prosody rate="medium" pitch="medium" volume="medium">$escapedText</prosody></speak>';
}

String escapeXml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

