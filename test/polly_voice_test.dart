import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Test script to find exact working parameters for AWS Polly voices
/// Focus: en-US male and female voices across generative, neural, and standard engines
///
/// USAGE: dart test/polly_voice_test.dart <AWS_ACCESS_KEY> <AWS_SECRET_KEY>
void main(List<String> args) async {
  print('🧪 [POLLY TEST] Starting AWS Polly voice parameter test...\n');

  // Get credentials from command line arguments
  if (args.length < 2) {
    print('❌ ERROR: Missing AWS credentials');
    print('USAGE: dart test/polly_voice_test.dart <AWS_ACCESS_KEY> <AWS_SECRET_KEY>');
    exit(1);
  }

  final awsAccessKey = args[0];
  final awsSecretKey = args[1];
  final awsRegion = 'us-east-1';
  
  print('✅ AWS credentials loaded');
  print('📍 Region: $awsRegion\n');
  
  // Test configurations for en-US
  final testCases = [
    // MALE VOICES
    {'voice': 'Matthew', 'engine': 'generative', 'gender': 'male', 'lang': 'en-US'},
    {'voice': 'Matthew', 'engine': 'neural', 'gender': 'male', 'lang': 'en-US'},
    {'voice': 'Matthew', 'engine': 'standard', 'gender': 'male', 'lang': 'en-US'},
    {'voice': 'Joey', 'engine': 'neural', 'gender': 'male', 'lang': 'en-US'},
    {'voice': 'Joey', 'engine': 'standard', 'gender': 'male', 'lang': 'en-US'},
    {'voice': 'Justin', 'engine': 'neural', 'gender': 'male', 'lang': 'en-US'},
    {'voice': 'Kevin', 'engine': 'neural', 'gender': 'male', 'lang': 'en-US'},
    
    // FEMALE VOICES
    {'voice': 'Joanna', 'engine': 'generative', 'gender': 'female', 'lang': 'en-US'},
    {'voice': 'Joanna', 'engine': 'neural', 'gender': 'female', 'lang': 'en-US'},
    {'voice': 'Joanna', 'engine': 'standard', 'gender': 'female', 'lang': 'en-US'},
    {'voice': 'Kendra', 'engine': 'neural', 'gender': 'female', 'lang': 'en-US'},
    {'voice': 'Kendra', 'engine': 'standard', 'gender': 'female', 'lang': 'en-US'},
    {'voice': 'Ivy', 'engine': 'neural', 'gender': 'female', 'lang': 'en-US'},
    {'voice': 'Salli', 'engine': 'neural', 'gender': 'female', 'lang': 'en-US'},
  ];
  
  final results = <Map<String, dynamic>>[];
  
  for (final testCase in testCases) {
    final voice = testCase['voice'] as String;
    final engine = testCase['engine'] as String;
    final gender = testCase['gender'] as String;
    final lang = testCase['lang'] as String;
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎙️  Testing: $voice ($gender) - $engine engine');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final result = await testPollyVoice(
      awsAccessKey: awsAccessKey,
      awsSecretKey: awsSecretKey,
      awsRegion: awsRegion,
      voiceId: voice,
      engine: engine,
      languageCode: lang,
    );
    
    results.add({
      'voice': voice,
      'engine': engine,
      'gender': gender,
      'lang': lang,
      'success': result['success'],
      'error': result['error'],
      'audioSize': result['audioSize'],
    });
    
    // Small delay to avoid rate limiting
    await Future.delayed(Duration(milliseconds: 500));
  }
  
  // Print summary
  print('\n\n');
  print('═══════════════════════════════════════════');
  print('📊 TEST RESULTS SUMMARY');
  print('═══════════════════════════════════════════\n');
  
  final successfulMale = results.where((r) => r['success'] == true && r['gender'] == 'male').toList();
  final successfulFemale = results.where((r) => r['success'] == true && r['gender'] == 'female').toList();
  final failed = results.where((r) => r['success'] == false).toList();
  
  print('✅ SUCCESSFUL MALE VOICES (${successfulMale.length}):');
  for (final r in successfulMale) {
    print('   • ${r['voice']} - ${r['engine']} (${r['audioSize']} bytes)');
  }
  
  print('\n✅ SUCCESSFUL FEMALE VOICES (${successfulFemale.length}):');
  for (final r in successfulFemale) {
    print('   • ${r['voice']} - ${r['engine']} (${r['audioSize']} bytes)');
  }
  
  print('\n❌ FAILED (${failed.length}):');
  for (final r in failed) {
    print('   • ${r['voice']} - ${r['engine']}: ${r['error']}');
  }
  
  // Recommended configuration
  print('\n\n');
  print('═══════════════════════════════════════════');
  print('💡 RECOMMENDED CONFIGURATION');
  print('═══════════════════════════════════════════\n');
  
  final generativeMale = successfulMale.firstWhere(
    (r) => r['engine'] == 'generative',
    orElse: () => {},
  );
  final neuralMale = successfulMale.firstWhere(
    (r) => r['engine'] == 'neural',
    orElse: () => {},
  );
  final standardMale = successfulMale.firstWhere(
    (r) => r['engine'] == 'standard',
    orElse: () => {},
  );
  
  final generativeFemale = successfulFemale.firstWhere(
    (r) => r['engine'] == 'generative',
    orElse: () => {},
  );
  final neuralFemale = successfulFemale.firstWhere(
    (r) => r['engine'] == 'neural',
    orElse: () => {},
  );
  final standardFemale = successfulFemale.firstWhere(
    (r) => r['engine'] == 'standard',
    orElse: () => {},
  );
  
  print("'en-US': {");
  print("  'generative': {");
  print("    'male': '${generativeMale['voice'] ?? 'null'}',");
  print("    'female': '${generativeFemale['voice'] ?? 'null'}',");
  print("  },");
  print("  'neural': {");
  print("    'male': '${neuralMale['voice'] ?? 'null'}',");
  print("    'female': '${neuralFemale['voice'] ?? 'null'}',");
  print("  },");
  print("  'standard': {");
  print("    'male': '${standardMale['voice'] ?? 'null'}',");
  print("    'female': '${standardFemale['voice'] ?? 'null'}',");
  print("  },");
  print("},");
  
  print('\n✅ Test complete!\n');
}

Future<Map<String, dynamic>> testPollyVoice({
  required String awsAccessKey,
  required String awsSecretKey,
  required String awsRegion,
  required String voiceId,
  required String engine,
  required String languageCode,
}) async {
  try {
    final endpoint = 'https://polly.$awsRegion.amazonaws.com/v1/speech';
    final now = DateTime.now().toUtc();
    
    final testText = '<speak>Hello, this is a test.</speak>';
    
    final requestBody = jsonEncode({
      'Text': testText,
      'TextType': 'ssml',
      'VoiceId': voiceId,
      'LanguageCode': languageCode,
      'Engine': engine,
      'OutputFormat': 'mp3',
    });
    
    // AWS Signature V4
    final signature = _generateAwsSignature(
      method: 'POST',
      endpoint: endpoint,
      region: awsRegion,
      service: 'polly',
      accessKey: awsAccessKey,
      secretKey: awsSecretKey,
      requestBody: requestBody,
      timestamp: now,
    );
    
    final response = await http.post(
      Uri.parse(endpoint),
      headers: signature['headers'] as Map<String, String>,
      body: requestBody,
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final audioSize = response.bodyBytes.length;
      print('   ✅ SUCCESS - Audio size: $audioSize bytes');
      return {
        'success': true,
        'audioSize': audioSize,
        'error': null,
      };
    } else {
      final errorBody = response.body;
      print('   ❌ FAILED - ${response.statusCode}');
      print('   Error: $errorBody');
      return {
        'success': false,
        'audioSize': 0,
        'error': '$errorBody',
      };
    }
  } catch (e) {
    print('   ❌ EXCEPTION: $e');
    return {
      'success': false,
      'audioSize': 0,
      'error': e.toString(),
    };
  }
}

Map<String, dynamic> _generateAwsSignature({
  required String method,
  required String endpoint,
  required String region,
  required String service,
  required String accessKey,
  required String secretKey,
  required String requestBody,
  required DateTime timestamp,
}) {
  final uri = Uri.parse(endpoint);
  final host = uri.host;
  final path = uri.path;
  
  final amzDate = timestamp.toIso8601String().replaceAll(RegExp(r'[:\-]'), '').split('.')[0] + 'Z';
  final dateStamp = amzDate.substring(0, 8);
  
  final payloadHash = sha256.convert(utf8.encode(requestBody)).toString();
  
  final canonicalHeaders = 'content-type:application/json\nhost:$host\nx-amz-date:$amzDate\n';
  final signedHeaders = 'content-type;host;x-amz-date';
  
  final canonicalRequest = '$method\n$path\n\n$canonicalHeaders\n$signedHeaders\n$payloadHash';
  
  final credentialScope = '$dateStamp/$region/$service/aws4_request';
  final stringToSign = 'AWS4-HMAC-SHA256\n$amzDate\n$credentialScope\n${sha256.convert(utf8.encode(canonicalRequest))}';
  
  final kDate = _hmacSha256(utf8.encode('AWS4$secretKey'), utf8.encode(dateStamp));
  final kRegion = _hmacSha256(kDate, utf8.encode(region));
  final kService = _hmacSha256(kRegion, utf8.encode(service));
  final kSigning = _hmacSha256(kService, utf8.encode('aws4_request'));
  final signature = _hmacSha256(kSigning, utf8.encode(stringToSign));
  
  final authorizationHeader = 'AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=${_bytesToHex(signature)}';
  
  return {
    'headers': {
      'Content-Type': 'application/json',
      'Host': host,
      'X-Amz-Date': amzDate,
      'Authorization': authorizationHeader,
    },
  };
}

List<int> _hmacSha256(List<int> key, List<int> data) {
  final hmac = Hmac(sha256, key);
  return hmac.convert(data).bytes;
}

String _bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

