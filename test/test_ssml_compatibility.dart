import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Test SSML compatibility with different engines
/// Tests both simple prosody and amazon:effect tags
void main(List<String> args) async {
  print('🧪 Testing SSML compatibility with different engines...\n');
  
  if (args.length < 2) {
    print('❌ ERROR: Missing AWS credentials');
    print('USAGE: dart test/test_ssml_compatibility.dart <AWS_ACCESS_KEY> <AWS_SECRET_KEY>');
    exit(1);
  }
  
  final awsAccessKey = args[0];
  final awsSecretKey = args[1];
  final awsRegion = 'us-east-1';
  
  // Test cases
  final tests = [
    {
      'name': 'Simple prosody (generative engine)',
      'voice': 'Joanna',
      'engine': 'generative',
      'ssml': '<speak><prosody rate="95%" pitch="-5%" volume="soft">Hello, this is a test.</prosody></speak>',
    },
    {
      'name': 'Amazon effects (generative engine) - SHOULD FAIL',
      'voice': 'Joanna',
      'engine': 'generative',
      'ssml': '<speak><amazon:effect name="drc"><prosody rate="slow" pitch="-10%" volume="soft">Hello, this is a test.</prosody></amazon:effect></speak>',
    },
    {
      'name': 'Amazon effects (neural engine) - SHOULD WORK',
      'voice': 'Joanna',
      'engine': 'neural',
      'ssml': '<speak><amazon:effect name="drc"><prosody rate="slow" pitch="-10%" volume="soft">Hello, this is a test.</prosody></amazon:effect></speak>',
    },
    {
      'name': 'Danielle with simple prosody (generative)',
      'voice': 'Danielle',
      'engine': 'generative',
      'ssml': '<speak><prosody rate="95%" pitch="-5%" volume="soft">Hello, this is a test.</prosody></speak>',
    },
    {
      'name': 'Matthew with simple prosody (generative)',
      'voice': 'Matthew',
      'engine': 'generative',
      'ssml': '<speak><prosody rate="95%" pitch="-5%" volume="soft">Hello, this is a test.</prosody></speak>',
    },
  ];
  
  print('═══════════════════════════════════════════');
  print('📊 SSML COMPATIBILITY TEST RESULTS');
  print('═══════════════════════════════════════════\n');
  
  for (final test in tests) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎙️  ${test['name']}');
    print('    Voice: ${test['voice']}, Engine: ${test['engine']}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final result = await testSSML(
      voice: test['voice'] as String,
      engine: test['engine'] as String,
      ssml: test['ssml'] as String,
      awsAccessKey: awsAccessKey,
      awsSecretKey: awsSecretKey,
      awsRegion: awsRegion,
    );
    
    print('');
    await Future.delayed(Duration(milliseconds: 500));
  }
  
  print('\n✅ Test complete!\n');
}

Future<bool> testSSML({
  required String voice,
  required String engine,
  required String ssml,
  required String awsAccessKey,
  required String awsSecretKey,
  required String awsRegion,
}) async {
  try {
    final endpoint = 'https://polly.$awsRegion.amazonaws.com/v1/speech';
    final host = 'polly.$awsRegion.amazonaws.com';
    final service = 'polly';
    
    final requestBody = jsonEncode({
      'Engine': engine,
      'LanguageCode': 'en-US',
      'OutputFormat': 'mp3',
      'Text': ssml,
      'TextType': 'ssml',
      'VoiceId': voice,
    });
    
    final now = DateTime.now().toUtc();
    final amzDate = now.toIso8601String().replaceAll(RegExp(r'[:\-]|\.\d{3}'), '').substring(0, 15) + 'Z';
    final dateStamp = amzDate.substring(0, 8);
    
    final payloadHash = sha256.convert(utf8.encode(requestBody)).toString();
    
    final canonicalHeaders = 'content-type:application/json\n'
        'host:$host\n'
        'x-amz-date:$amzDate\n';
    
    final signedHeaders = 'content-type;host;x-amz-date';
    
    final canonicalRequest = 'POST\n'
        '/v1/speech\n'
        '\n'
        '$canonicalHeaders\n'
        '$signedHeaders\n'
        '$payloadHash';
    
    final credentialScope = '$dateStamp/$awsRegion/$service/aws4_request';
    final stringToSign = 'AWS4-HMAC-SHA256\n'
        '$amzDate\n'
        '$credentialScope\n'
        '${sha256.convert(utf8.encode(canonicalRequest))}';
    
    var kDate = Hmac(sha256, utf8.encode('AWS4$awsSecretKey')).convert(utf8.encode(dateStamp)).bytes;
    var kRegion = Hmac(sha256, kDate).convert(utf8.encode(awsRegion)).bytes;
    var kService = Hmac(sha256, kRegion).convert(utf8.encode(service)).bytes;
    var kSigning = Hmac(sha256, kService).convert(utf8.encode('aws4_request')).bytes;
    var signature = Hmac(sha256, kSigning).convert(utf8.encode(stringToSign)).toString();
    
    final authorizationHeader = 'AWS4-HMAC-SHA256 Credential=$awsAccessKey/$credentialScope, '
        'SignedHeaders=$signedHeaders, Signature=$signature';
    
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'X-Amz-Date': amzDate,
        'Authorization': authorizationHeader,
      },
      body: requestBody,
    );
    
    if (response.statusCode == 200) {
      print('    ✅ SUCCESS - Audio size: ${response.bodyBytes.length} bytes');
      return true;
    } else {
      print('    ❌ FAILED - ${response.statusCode}');
      print('    Error: ${response.body}');
      return false;
    }
  } catch (e) {
    print('    ❌ ERROR: $e');
    return false;
  }
}

