import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Test SSML for all supported languages with different engines
void main(List<String> args) async {
  print('🧪 Testing SSML for all languages...\n');
  
  if (args.length < 2) {
    print('❌ ERROR: Missing AWS credentials');
    exit(1);
  }
  
  final awsAccessKey = args[0];
  final awsSecretKey = args[1];
  final awsRegion = 'us-east-1';
  
  // Test cases for different languages
  final tests = [
    // English (US)
    {'lang': 'en-US', 'voice': 'Matthew', 'engine': 'generative', 'text': 'Hello, this is a test.'},
    {'lang': 'en-US', 'voice': 'Joanna', 'engine': 'neural', 'text': 'Hello, this is a test.'},
    
    // English (GB)
    {'lang': 'en-GB', 'voice': 'Brian', 'engine': 'generative', 'text': 'Hello, this is a test.'},
    
    // Hindi
    {'lang': 'hi-IN', 'voice': 'Kajal', 'engine': 'generative', 'text': 'नमस्ते, यह एक परीक्षण है।'},
    
    // Spanish
    {'lang': 'es-ES', 'voice': 'Sergio', 'engine': 'generative', 'text': 'Hola, esto es una prueba.'},
    {'lang': 'es-ES', 'voice': 'Lucia', 'engine': 'generative', 'text': 'Hola, esto es una prueba.'},
    
    // Chinese
    {'lang': 'cmn-CN', 'voice': 'Zhiyu', 'engine': 'neural', 'text': '你好，这是一个测试。'},
    
    // French
    {'lang': 'fr-FR', 'voice': 'Mathieu', 'engine': 'generative', 'text': 'Bonjour, ceci est un test.'},
    
    // German
    {'lang': 'de-DE', 'voice': 'Hans', 'engine': 'generative', 'text': 'Hallo, das ist ein Test.'},
    
    // Arabic
    {'lang': 'arb', 'voice': 'Zeina', 'engine': 'neural', 'text': 'مرحبا، هذا اختبار.'},
    
    // Japanese
    {'lang': 'ja-JP', 'voice': 'Takumi', 'engine': 'generative', 'text': 'こんにちは、これはテストです。'},
  ];
  
  print('═══════════════════════════════════════════');
  print('📊 MULTI-LANGUAGE SSML TEST');
  print('═══════════════════════════════════════════\n');
  
  var passed = 0;
  var failed = 0;
  
  for (final test in tests) {
    final lang = test['lang'] as String;
    final voice = test['voice'] as String;
    final engine = test['engine'] as String;
    final text = test['text'] as String;
    
    // Build SSML based on engine type
    String ssml;
    if (engine == 'generative') {
      // Generative: Use x-values
      ssml = '<speak><prosody rate="medium" volume="x-loud">$text</prosody></speak>';
    } else {
      // Neural/Standard: Use word values
      ssml = '<speak><prosody rate="medium" volume="x-loud" pitch="+15%">$text</prosody></speak>';
    }
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎙️  $lang - $voice ($engine)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final success = await testVoice(
      voice: voice,
      engine: engine,
      languageCode: lang,
      ssml: ssml,
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
    await Future.delayed(Duration(milliseconds: 300));
  }
  
  print('\n═══════════════════════════════════════════');
  print('📊 SUMMARY');
  print('═══════════════════════════════════════════');
  print('✅ Passed: $passed');
  print('❌ Failed: $failed');
  print('');
}

Future<bool> testVoice({
  required String voice,
  required String engine,
  required String languageCode,
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
      'LanguageCode': languageCode,
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

