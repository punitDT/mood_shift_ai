import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Test which en-US female voices actually work with generative engine
void main(List<String> args) async {
  print('🧪 Testing en-US female voices with GENERATIVE engine...\n');
  
  if (args.length < 2) {
    print('❌ ERROR: Missing AWS credentials');
    print('USAGE: dart test/test_generative_voices.dart <AWS_ACCESS_KEY> <AWS_SECRET_KEY>');
    exit(1);
  }
  
  final awsAccessKey = args[0];
  final awsSecretKey = args[1];
  final awsRegion = 'us-east-1';
  
  // Test these female voices with generative engine
  final voicesToTest = [
    'Joanna',
    'Danielle',
    'Ruth',
    'Salli',
    'Kendra',
    'Ivy',
    'Kimberly',
  ];
  
  final successfulVoices = <String>[];
  final failedVoices = <String>[];
  
  for (final voice in voicesToTest) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎙️  Testing: $voice (female) - generative engine');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final result = await testVoice(
      voice: voice,
      engine: 'generative',
      languageCode: 'en-US',
      awsAccessKey: awsAccessKey,
      awsSecretKey: awsSecretKey,
      awsRegion: awsRegion,
    );
    
    if (result) {
      successfulVoices.add(voice);
    } else {
      failedVoices.add(voice);
    }
    
    // Small delay between requests
    await Future.delayed(Duration(milliseconds: 500));
  }
  
  print('\n\n═══════════════════════════════════════════');
  print('📊 GENERATIVE ENGINE TEST RESULTS');
  print('═══════════════════════════════════════════\n');
  
  print('✅ SUCCESSFUL VOICES (${successfulVoices.length}):');
  for (final voice in successfulVoices) {
    print('   • $voice');
  }
  
  print('\n❌ FAILED VOICES (${failedVoices.length}):');
  for (final voice in failedVoices) {
    print('   • $voice');
  }
  
  if (successfulVoices.isNotEmpty) {
    print('\n💡 RECOMMENDED: Use ${successfulVoices.first} for en-US female generative voice');
  }
}

Future<bool> testVoice({
  required String voice,
  required String engine,
  required String languageCode,
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
      'Text': '<speak>Hello, this is a test.</speak>',
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
      print('   ✅ SUCCESS - Audio size: ${response.bodyBytes.length} bytes');
      return true;
    } else {
      print('   ❌ FAILED - ${response.statusCode}: ${response.body}');
      return false;
    }
  } catch (e) {
    print('   ❌ ERROR: $e');
    return false;
  }
}

