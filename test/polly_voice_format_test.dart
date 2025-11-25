import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AWS Polly Voice Format Test
/// Tests different VoiceId formats to determine the correct one
///
/// This test will try:
/// 1. Standard format: VoiceId="Matthew", Engine="generative"
/// 2. Locale format: VoiceId="en-US-Matthew", Engine="generative"
/// 3. Engine suffix format: VoiceId="MatthewGenerative"
/// 4. Locale + Engine format: VoiceId="en-US-MatthewGenerative"
///
/// Run: flutter test test/polly_voice_format_test.dart

void main() {
  late String accessKey;
  late String secretKey;
  late String region;

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    accessKey = dotenv.env['AWS_ACCESS_KEY'] ?? '';
    secretKey = dotenv.env['AWS_SECRET_KEY'] ?? '';
    region = dotenv.env['AWS_REGION'] ?? 'us-east-1';
  });

  group('AWS Polly VoiceId Format Tests', () {
    test('Format 1: Standard (VoiceId="Matthew", Engine="standard")', () async {
      print('\n${'=' * 80}');
      print('TEST 1: Standard Format - VoiceId="Matthew", Engine="standard"');
      print('=' * 80);
      
      final result = await _testVoiceFormat(
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
        voiceId: 'Matthew',
        engine: 'standard',
        languageCode: 'en-US',
      );

      print('Result: ${result['success'] ? '✅ SUCCESS' : '❌ FAILED'}');
      if (!result['success']) {
        print('Error: ${result['error']}');
      }
      print('');
    });

    test('Format 2: Standard (VoiceId="Matthew", Engine="neural")', () async {
      print('\n${'=' * 80}');
      print('TEST 2: Standard Format - VoiceId="Matthew", Engine="neural"');
      print('=' * 80);
      
      final result = await _testVoiceFormat(
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
        voiceId: 'Matthew',
        engine: 'neural',
        languageCode: 'en-US',
      );

      print('Result: ${result['success'] ? '✅ SUCCESS' : '❌ FAILED'}');
      if (!result['success']) {
        print('Error: ${result['error']}');
      }
      print('');
    });

    test('Format 3: Standard (VoiceId="Matthew", Engine="generative")', () async {
      print('\n${'=' * 80}');
      print('TEST 3: Standard Format - VoiceId="Matthew", Engine="generative"');
      print('=' * 80);
      
      final result = await _testVoiceFormat(
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
        voiceId: 'Matthew',
        engine: 'generative',
        languageCode: 'en-US',
      );

      print('Result: ${result['success'] ? '✅ SUCCESS' : '❌ FAILED'}');
      if (!result['success']) {
        print('Error: ${result['error']}');
      }
      print('');
    });

    test('Format 4: Locale Prefix (VoiceId="en-US-Matthew", Engine="standard")', () async {
      print('\n${'=' * 80}');
      print('TEST 4: Locale Prefix - VoiceId="en-US-Matthew", Engine="standard"');
      print('=' * 80);
      
      final result = await _testVoiceFormat(
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
        voiceId: 'en-US-Matthew',
        engine: 'standard',
        languageCode: 'en-US',
      );

      print('Result: ${result['success'] ? '✅ SUCCESS' : '❌ FAILED'}');
      if (!result['success']) {
        print('Error: ${result['error']}');
      }
      print('');
    });

    test('Format 5: Engine Suffix (VoiceId="MatthewNeural", Engine="neural")', () async {
      print('\n${'=' * 80}');
      print('TEST 5: Engine Suffix - VoiceId="MatthewNeural", Engine="neural"');
      print('=' * 80);
      
      final result = await _testVoiceFormat(
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
        voiceId: 'MatthewNeural',
        engine: 'neural',
        languageCode: 'en-US',
      );

      print('Result: ${result['success'] ? '✅ SUCCESS' : '❌ FAILED'}');
      if (!result['success']) {
        print('Error: ${result['error']}');
      }
      print('');
    });

    test('Format 6: Locale + Engine (VoiceId="en-US-MatthewNeural", Engine="neural")', () async {
      print('\n${'=' * 80}');
      print('TEST 6: Locale + Engine - VoiceId="en-US-MatthewNeural", Engine="neural"');
      print('=' * 80);
      
      final result = await _testVoiceFormat(
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
        voiceId: 'en-US-MatthewNeural',
        engine: 'neural',
        languageCode: 'en-US',
      );

      print('Result: ${result['success'] ? '✅ SUCCESS' : '❌ FAILED'}');
      if (!result['success']) {
        print('Error: ${result['error']}');
      }
      print('');
    });

    test('Format 7: Engine Suffix Only (VoiceId="MatthewGenerative")', () async {
      print('\n${'=' * 80}');
      print('TEST 7: Engine Suffix - VoiceId="MatthewGenerative", Engine="generative"');
      print('=' * 80);

      final result = await _testVoiceFormat(
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
        voiceId: 'MatthewGenerative',
        engine: 'generative',
        languageCode: 'en-US',
      );

      print('Result: ${result['success'] ? '✅ SUCCESS' : '❌ FAILED'}');
      if (!result['success']) {
        print('Error: ${result['error']}');
      }
      print('');
    });

    test('Format 8: Locale + Engine Generative (VoiceId="en-US-MatthewGenerative")', () async {
      print('\n${'=' * 80}');
      print('TEST 8: Locale + Engine - VoiceId="en-US-MatthewGenerative", Engine="generative"');
      print('=' * 80);
      
      final result = await _testVoiceFormat(
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
        voiceId: 'en-US-MatthewGenerative',
        engine: 'generative',
        languageCode: 'en-US',
      );

      print('Result: ${result['success'] ? '✅ SUCCESS' : '❌ FAILED'}');
      if (!result['success']) {
        print('Error: ${result['error']}');
      }
      print('');
    });
  });
}

Future<Map<String, dynamic>> _testVoiceFormat({
  required String accessKey,
  required String secretKey,
  required String region,
  required String voiceId,
  required String engine,
  required String languageCode,
}) async {
  try {
    final endpoint = 'https://polly.$region.amazonaws.com/v1/speech';
    final now = DateTime.now().toUtc();

    final requestBody = jsonEncode({
      'Text': 'Test',
      'TextType': 'text',
      'VoiceId': voiceId,
      'LanguageCode': languageCode,
      'Engine': engine,
      'OutputFormat': 'mp3',
    });

    print('Request Body:');
    print(const JsonEncoder.withIndent('  ').convert(jsonDecode(requestBody)));

    final headers = await _generateSigV4Headers(
      method: 'POST',
      endpoint: endpoint,
      body: requestBody,
      timestamp: now,
      accessKey: accessKey,
      secretKey: secretKey,
      region: region,
    );

    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: requestBody,
    );

    print('Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('Response Size: ${response.bodyBytes.length} bytes');
      return {'success': true};
    } else {
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'error': '$e',
    };
  }
}

Future<Map<String, String>> _generateSigV4Headers({
  required String method,
  required String endpoint,
  required String body,
  required DateTime timestamp,
  required String accessKey,
  required String secretKey,
  required String region,
}) async {
  final uri = Uri.parse(endpoint);
  final host = uri.host;
  final canonicalUri = uri.path;
  final canonicalQueryString = uri.query;

  final amzDate = _formatDateTime(timestamp);
  final dateStamp = _formatDate(timestamp);

  final payloadHash = sha256.convert(utf8.encode(body)).toString();

  final canonicalHeaders = 'host:$host\nx-amz-date:$amzDate\n';
  final signedHeaders = 'host;x-amz-date';

  final canonicalRequest = '$method\n$canonicalUri\n$canonicalQueryString\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

  final algorithm = 'AWS4-HMAC-SHA256';
  final credentialScope = '$dateStamp/$region/polly/aws4_request';
  final stringToSign = '$algorithm\n$amzDate\n$credentialScope\n${sha256.convert(utf8.encode(canonicalRequest))}';

  final signingKey = _getSignatureKey(secretKey, dateStamp, region, 'polly');
  final signature = hex.encode(Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).bytes);

  final authorizationHeader = '$algorithm Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

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

String _formatDateTime(DateTime dt) {
  return '${dt.year}${_pad(dt.month)}${_pad(dt.day)}T${_pad(dt.hour)}${_pad(dt.minute)}${_pad(dt.second)}Z';
}

String _formatDate(DateTime dt) {
  return '${dt.year}${_pad(dt.month)}${_pad(dt.day)}';
}

String _pad(int n) => n.toString().padLeft(2, '0');

