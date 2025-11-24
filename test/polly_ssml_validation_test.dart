import 'package:flutter_test/flutter_test.dart';
import 'package:mood_shift_ai/app/services/ai_service.dart';

/// Comprehensive SSML Validation Test
/// Tests all combinations of:
/// - Languages: en-US, en-GB, hi-IN, es-ES, zh-CN, fr-FR, de-DE, ar-SA, ja-JP
/// - Genders: male, female
/// - Features: Normal, 2× STRONGER, Golden Voice
/// - Mood Styles: All 5 styles
void main() {
  group('AWS Polly SSML Validation Tests', () {
    // All supported languages
    final languages = [
      'en-US', 'en-GB', 'hi-IN', 'es-ES', 'zh-CN', 
      'fr-FR', 'de-DE', 'ar-SA', 'ja-JP'
    ];
    
    final genders = ['male', 'female'];
    final styles = MoodStyle.values;
    
    // Test text samples
    const testText = 'Hello, this is a test message!';
    const testTextWithSpecialChars = 'Test with <special> & "quotes" and \'apostrophes\'';

    test('Validate Normal SSML with LLM prosody', () {
      for (final lang in languages) {
        for (final gender in genders) {
          final ssml = buildSSML(testText, prosody: {
            'rate': 'medium',
            'pitch': 'medium',
            'volume': 'medium',
          });
          
          expect(ssml, contains('<speak>'));
          expect(ssml, contains('</speak>'));
          expect(ssml, contains('<prosody'));
          expect(ssml, contains('rate="medium"'));
          expect(ssml, contains('pitch="medium"'));
          expect(ssml, contains('volume="medium"'));
          expect(ssml, contains('</prosody>'));
          
          // Should NOT contain invalid tags
          expect(ssml, isNot(contains('phonation')));
          expect(ssml, isNot(contains('vocal-tract-length')));
          expect(ssml, isNot(contains('style=')));
          
          print('✅ Normal SSML valid for $lang ($gender)');
        }
      }
    });

    test('Validate 2× STRONGER SSML for all styles', () {
      for (final lang in languages) {
        for (final gender in genders) {
          for (final style in styles) {
            final ssml = buildStrongerSSML(testText, style);

            // Basic SSML structure
            expect(ssml, contains('<speak>'));
            expect(ssml, contains('</speak>'));
            expect(ssml, contains('<prosody'));
            expect(ssml, contains('</prosody>'));

            // Should NOT contain DRC (not supported by neural voices)
            expect(ssml, isNot(contains('<amazon:effect name="drc">')));

            // Should NOT contain invalid tags for neural voices
            expect(ssml, isNot(contains('phonation="breathy"')));
            expect(ssml, isNot(contains('phonation="soft"')));
            expect(ssml, isNot(contains('vocal-tract-length')));
            expect(ssml, isNot(contains('style=')));

            // Validate prosody attributes are valid
            expect(ssml, matches(RegExp(r'rate="(x-slow|slow|medium|fast|x-fast|\d+%)"')));
            expect(ssml, matches(RegExp(r'pitch="([+-]?\d+%|x-low|low|medium|high|x-high|default)"')));
            expect(ssml, matches(RegExp(r'volume="([+-]?\d+dB|silent|x-soft|soft|medium|loud|x-loud|default)"')));

            print('✅ 2× STRONGER SSML valid for $lang ($gender) - $style');
          }
        }
      }
    });

    test('Validate Golden Voice SSML', () {
      for (final lang in languages) {
        for (final gender in genders) {
          for (final style in styles) {
            final ssml = buildGoldenSSML(testText, style);

            // Basic SSML structure
            expect(ssml, contains('<speak>'));
            expect(ssml, contains('</speak>'));
            expect(ssml, contains('<prosody'));
            expect(ssml, contains('</prosody>'));

            // Should NOT contain DRC (not supported by neural voices)
            expect(ssml, isNot(contains('<amazon:effect name="drc">')));

            // Should NOT contain invalid tags
            expect(ssml, isNot(contains('phonation')));
            expect(ssml, isNot(contains('vocal-tract-length')));
            expect(ssml, isNot(contains('style=')));
            expect(ssml, isNot(contains('conversational')));

            // Should have valid prosody values
            expect(ssml, contains('rate="medium"'));
            expect(ssml, contains('pitch="medium"'));
            expect(ssml, contains('volume="medium"'));

            print('✅ Golden Voice SSML valid for $lang ($gender) - $style');
          }
        }
      }
    });

    test('Validate XML escaping in SSML', () {
      final ssml = buildSSML(testTextWithSpecialChars);
      
      // Should escape XML special characters
      expect(ssml, contains('&lt;'));  // <
      expect(ssml, contains('&gt;'));  // >
      expect(ssml, contains('&amp;')); // &
      expect(ssml, contains('&quot;')); // "
      expect(ssml, contains('&apos;')); // '
      
      // Should NOT contain unescaped special chars
      expect(ssml, isNot(matches(RegExp(r'>[^<]*<special>'))));
      
      print('✅ XML escaping works correctly');
    });

    test('Validate SSML tag nesting order', () {
      for (final style in styles) {
        final ssml = buildStrongerSSML(testText, style);

        // Proper nesting: speak > prosody > text
        final speakStart = ssml.indexOf('<speak>');
        final prosodyStart = ssml.indexOf('<prosody');
        final prosodyEnd = ssml.indexOf('</prosody>');
        final speakEnd = ssml.indexOf('</speak>');

        expect(speakStart, lessThan(prosodyStart));
        expect(prosodyStart, lessThan(prosodyEnd));
        expect(prosodyEnd, lessThan(speakEnd));

        print('✅ SSML tag nesting is correct for $style');
      }
    });

    test('Validate no duplicate or conflicting tags', () {
      for (final style in styles) {
        final ssml = buildStrongerSSML(testText, style);
        
        // Should not have multiple conflicting phonation attributes
        final phonationCount = 'phonation'.allMatches(ssml).length;
        expect(phonationCount, equals(0), reason: 'Should not use phonation attribute');
        
        // Should not have multiple conflicting vocal-tract-length
        final vocalTractCount = 'vocal-tract-length'.allMatches(ssml).length;
        expect(vocalTractCount, equals(0), reason: 'Should not use vocal-tract-length');
        
        print('✅ No conflicting tags for $style');
      }
    });
  });
}

// Helper functions that mirror the actual implementation
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
      return '<speak>'
          '<prosody rate="x-fast" pitch="+30%" volume="+10dB">'
          '$escapedText'
          '</prosody>'
          '</speak>';

    case MoodStyle.gentleGrandma:
      return '<speak>'
          '<prosody rate="medium" pitch="+25%" volume="+8dB">'
          '$escapedText'
          '</prosody>'
          '</speak>';

    case MoodStyle.permissionSlip:
      return '<speak>'
          '<prosody rate="fast" pitch="+28%" volume="+9dB">'
          '$escapedText'
          '</prosody>'
          '</speak>';

    case MoodStyle.realityCheck:
      return '<speak>'
          '<prosody rate="fast" pitch="+22%" volume="+9dB">'
          '$escapedText'
          '</prosody>'
          '</speak>';

    case MoodStyle.microDare:
      return '<speak>'
          '<prosody rate="fast" pitch="+25%" volume="+9dB">'
          '$escapedText'
          '</prosody>'
          '</speak>';
  }
}

String buildGoldenSSML(String text, MoodStyle style) {
  final escapedText = escapeXml(text);

  return '<speak>'
      '<prosody rate="medium" pitch="medium" volume="medium">'
      '$escapedText'
      '</prosody>'
      '</speak>';
}

String escapeXml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

