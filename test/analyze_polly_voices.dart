import 'dart:convert';
import 'dart:io';

/// Analyzes AWS Polly voice data and generates optimal voice mappings
/// for the MoodShift AI app
void main() async {
  print('🔍 Analyzing AWS Polly voices...\n');

  // Languages supported by MoodShift AI
  final supportedLanguages = {
    'en-US': 'US English',
    'en-GB': 'British English',
    'hi-IN': 'Indian English/Hindi',
    'es-ES': 'Castilian Spanish',
    'cmn-CN': 'Chinese Mandarin',
    'fr-FR': 'French',
    'de-DE': 'German',
    'arb': 'Arabic',
    'ja-JP': 'Japanese',
  };

  // Read AWS CLI outputs
  final neuralData = jsonDecode(await File('test/neural_voices.json').readAsString());
  final generativeData = jsonDecode(await File('test/generative_voices.json').readAsString());
  final standardData = jsonDecode(await File('test/standard_voices.json').readAsString());

  final Map<String, Map<String, Map<String, String>>> voiceMap = {};

  for (final langCode in supportedLanguages.keys) {
    voiceMap[langCode] = {
      'generative': {'male': '', 'female': ''},
      'neural': {'male': '', 'female': ''},
      'standard': {'male': '', 'female': ''},
    };

    // Find voices for each engine
    for (final engine in ['generative', 'neural', 'standard']) {
      final data = engine == 'generative' ? generativeData : 
                   engine == 'neural' ? neuralData : standardData;
      
      final voices = (data['Voices'] as List).where((v) {
        final code = v['LanguageCode'] as String;
        final additionalCodes = v['AdditionalLanguageCodes'] as List?;
        return code == langCode || 
               (additionalCodes?.contains(langCode) ?? false);
      }).toList();

      // Find male voice
      final maleVoice = voices.firstWhere(
        (v) => v['Gender'] == 'Male',
        orElse: () => null,
      );
      if (maleVoice != null) {
        voiceMap[langCode]![engine]!['male'] = maleVoice['Id'];
      }

      // Find female voice
      final femaleVoice = voices.firstWhere(
        (v) => v['Gender'] == 'Female',
        orElse: () => null,
      );
      if (femaleVoice != null) {
        voiceMap[langCode]![engine]!['female'] = femaleVoice['Id'];
      }
    }
  }

  // Print results
  print('═══════════════════════════════════════════');
  print('📊 VOICE MAPPING ANALYSIS');
  print('═══════════════════════════════════════════\n');

  for (final langCode in supportedLanguages.keys) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🌍 $langCode (${supportedLanguages[langCode]})');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    for (final engine in ['generative', 'neural', 'standard']) {
      final male = voiceMap[langCode]![engine]!['male'] ?? '';
      final female = voiceMap[langCode]![engine]!['female'] ?? '';

      print('  $engine:');
      print('    Male:   ${male.isEmpty ? "❌ NOT AVAILABLE" : "✅ $male"}');
      print('    Female: ${female.isEmpty ? "❌ NOT AVAILABLE" : "✅ $female"}');
    }
    print('');
  }

  // Generate Dart code
  print('\n═══════════════════════════════════════════');
  print('💡 RECOMMENDED DART CONFIGURATION');
  print('═══════════════════════════════════════════\n');
  
  print('final preferredVoices = {');
  for (final langCode in supportedLanguages.keys) {
    print("  '$langCode': {");
    for (final engine in ['generative', 'neural', 'standard']) {
      final male = voiceMap[langCode]![engine]!['male'] ?? '';
      final female = voiceMap[langCode]![engine]!['female'] ?? '';

      print("    '$engine': {");
      if (male.isNotEmpty) {
        print("      'male': '$male',");
      }
      if (female.isNotEmpty) {
        print("      'female': '$female',");
      }
      print("    },");
    }
    print("  },");
  }
  print('};');

  print('\n✅ Analysis complete!\n');
}

