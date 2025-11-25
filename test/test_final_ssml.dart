import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Test the final SSML formats that should work
void main(List<String> args) async {
  print('🧪 Testing FINAL SSML formats...\n');
  
  if (args.length < 2) {
    print('❌ ERROR: Missing AWS credentials');
    exit(1);
  }
  
  final awsAccessKey = args[0];
  final awsSecretKey = args[1];
  final awsRegion = 'us-east-1';
  
  // Test cases that should ALL work
  final tests = [
    {
      'name': 'Generative - Golden Voice (x-slow, x-soft)',
      'voice': 'Matthew',
      'engine': 'generative',
      'text': '<speak><prosody rate="x-slow" volume="x-soft">Hello, this is a test.</prosody></speak>',
    },
    {
      'name': 'Generative - Stronger (x-fast, x-loud)',
      'voice': 'Matthew',
      'engine': 'generative',
      'text': '<speak><prosody rate="x-fast" volume="x-loud">Hello, this is a test.</prosody></speak>',
    },
    {
      'name': 'Generative - Normal (medium)',
      'voice': 'Matthew',
      'engine': 'generative',
      'text': '<speak><prosody rate="medium" volume="medium">Hello, this is a test.</prosody></speak>',
    },
    {
      'name': 'Neural - Golden Voice (with amazon:effect)',
      'voice': 'Matthew',
      'engine': 'neural',
      'text': '<speak><amazon:effect name="drc"><prosody rate="slow" pitch="-10%" volume="soft">Hello, this is a test.</prosody></amazon:effect></speak>',
    },
    {
      'name': 'Neural - Stronger (with emphasis)',
      'voice': 'Matthew',
      'engine': 'neural',
      'text': '<speak><prosody rate="fast" volume="x-loud" pitch="+15%"><emphasis level="strong">Hello, this is a test.</emphasis></prosody></speak>',
    },
    {
      'name': 'Standard - Normal (word values)',
      'voice': 'Matthew',
      'engine': 'standard',
      'text': '<speak><prosody rate="medium" pitch="medium" volume="medium">Hello, this is a test.</prosody></speak>',
    },
  ];
  
  print('═══════════════════════════════════════════');
  print('📊 FINAL SSML TEST RESULTS');
  print('═══════════════════════════════════════════\n');
  
  var passed = 0;
  var failed = 0;
  
  for (final test in tests) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎙️  ${test['name']}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final success = await testText(
      voice: test['voice'] as String,
      engine: test['engine'] as String,
      text: test['text'] as String,
      awsAccessKey: awsAccessKey,
      awsSecretKey: awsSecretKey,
      awsRegion: awsRegion,
    );
    
    if (success) {
      passed++;
    } else {
      failed++;
    }
    
    print('');
    await Future.delayed(Duration(milliseconds: 500));
  }
  
  print('\n═══════════════════════════════════════════');
  print('📊 SUMMARY');
  print('═══════════════════════════════════════════');
  print('✅ Passed: $passed');
  print('❌ Failed: $failed');
  print('');
}

Future<bool> testText({
  required String voice,
  required String engine,
  required String text,
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
      'Text': text,
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

