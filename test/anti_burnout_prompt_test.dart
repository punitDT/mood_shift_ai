// Anti-Burnout Prompt Integration Tests
// Tests that the LLM prompt handles anti-burnout protection based on conversation history
// No Flutter code changes - prompt-only solution

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String model = 'llama-3.1-8b-instant';

class TestCase {
  final int id;
  final String scenario;
  final int shiftCount;
  final List<String> previousInputs;
  final String currentInput;
  final bool expectPauseMessage;
  final List<String> expectedPhrases;
  final String description;

  TestCase({
    required this.id,
    required this.scenario,
    required this.shiftCount,
    required this.previousInputs,
    required this.currentInput,
    required this.expectPauseMessage,
    required this.expectedPhrases,
    required this.description,
  });
}

// Generate fake previous inputs for testing
List<String> generatePreviousInputs(int count) {
  final inputs = [
    "I'm feeling stressed",
    "I need motivation",
    "I'm bored today",
    "Help me focus",
    "I'm anxious",
    "I feel overwhelmed",
    "I need energy",
    "I'm tired",
    "Help me relax",
    "I'm feeling down",
    "I need a boost",
    "I'm restless",
    "Help me calm down",
    "I'm feeling stuck",
    "I need encouragement",
    "I'm feeling lost",
    "Help me breathe",
    "I'm feeling scattered",
    "I need grounding",
    "I'm feeling tense",
  ];
  return inputs.take(count).toList();
}

final List<TestCase> testCases = [
  // Test 1: 8th shift - gentle nudge
  TestCase(
    id: 1,
    scenario: '7 shifts already, 8th shift',
    shiftCount: 8,
    previousInputs: generatePreviousInputs(7),
    currentInput: "I'm feeling anxious right now",
    expectPauseMessage: true,
    expectedPhrases: ["You've been showing up so much", "proud", "slow breath"],
    description: 'Gentle nudge at 8th shift',
  ),
  // Test 2: 10th shift - soft cooldown
  TestCase(
    id: 2,
    scenario: '9 shifts already, 10th shift',
    shiftCount: 10,
    previousInputs: generatePreviousInputs(9),
    currentInput: "I need some motivation",
    expectPauseMessage: true,
    expectedPhrases: ["10 shifts", "rest", "45 seconds", "breathe", "safe"],
    description: 'Soft cooldown at 10th shift',
  ),
  // Test 3: 12th shift - 60 sec cooldown
  TestCase(
    id: 3,
    scenario: '11 shifts already, 12th shift',
    shiftCount: 12,
    previousInputs: generatePreviousInputs(11),
    currentInput: "I'm feeling overwhelmed",
    expectPauseMessage: true,
    expectedPhrases: ["12 shifts", "strength", "pause", "minute", "calm"],
    description: 'Cooldown at 12th shift',
  ),
  // Test 4: 15th shift - 90 sec cooldown
  TestCase(
    id: 4,
    scenario: '14 shifts already, 15th shift',
    shiftCount: 15,
    previousInputs: generatePreviousInputs(14),
    currentInput: "Help me focus",
    expectPauseMessage: true,
    expectedPhrases: ["matter more than any shift", "rest", "90 seconds"],
    description: 'Max cooldown at 15th shift',
  ),
  // Test 5: 18th shift - still 90 sec
  TestCase(
    id: 5,
    scenario: '17 shifts already, 18th shift',
    shiftCount: 18,
    previousInputs: generatePreviousInputs(17),
    currentInput: "I'm feeling restless",
    expectPauseMessage: true,
    expectedPhrases: ["matter", "rest", "90"],
    description: '90-sec cooldown continues at 18th shift',
  ),
  // Test 6: After 6-minute break (simulated by empty history)
  TestCase(
    id: 6,
    scenario: 'User waits 6 minutes after shift #10',
    shiftCount: 1,
    previousInputs: [], // Empty = reset
    currentInput: "I'm back and feeling good",
    expectPauseMessage: false,
    expectedPhrases: [],
    description: 'Counter reset after break - no pause message',
  ),
  // Test 7: Skip early simulation (still shows pause at 10)
  TestCase(
    id: 7,
    scenario: '10 shifts → user taps Continue early',
    shiftCount: 10,
    previousInputs: generatePreviousInputs(9),
    currentInput: "I want to continue",
    expectPauseMessage: true,
    expectedPhrases: ["10 shifts", "rest", "breathe"],
    description: 'Pause message still appears at 10th shift',
  ),
  // Test 8: App closed and reopened (simulated by empty history)
  TestCase(
    id: 8,
    scenario: '10 shifts → cooldown → user closes app → reopens',
    shiftCount: 1,
    previousInputs: [], // Empty = app was closed
    currentInput: "I'm starting fresh",
    expectPauseMessage: false,
    expectedPhrases: [],
    description: 'Cooldown cancelled after app restart',
  ),
  // Test 9: 20+ shifts - still 90 sec max
  TestCase(
    id: 9,
    scenario: '20 shifts in one session',
    shiftCount: 20,
    previousInputs: generatePreviousInputs(19),
    currentInput: "I'm still here",
    expectPauseMessage: true,
    expectedPhrases: ["matter", "rest", "90"],
    description: 'Still 90-sec max at 20th shift',
  ),
  // Test 10: First shift - no pause
  TestCase(
    id: 10,
    scenario: 'First shift of the day',
    shiftCount: 1,
    previousInputs: [],
    currentInput: "Good morning, I need help focusing",
    expectPauseMessage: false,
    expectedPhrases: [],
    description: 'No pause message on first shift',
  ),
];

String buildPrompt(String userInput, List<String> previousInputs) {
  final shiftCount = previousInputs.length + 1;

  // Determine the exact pause message based on shift count
  String pauseMessage;
  if (shiftCount >= 15) {
    pauseMessage = "You matter more than any shift. Let's rest together for 90 seconds.";
  } else if (shiftCount >= 12) {
    pauseMessage = "You've done $shiftCount shifts today – that takes real strength. Let's pause for a minute and feel calm.";
  } else if (shiftCount >= 10) {
    pauseMessage = "Wow, $shiftCount shifts already. Let's rest for 45 seconds – just breathe with me. You're safe.";
  } else if (shiftCount >= 8) {
    pauseMessage = "You've been showing up so much – I'm proud of you. Let's take one slow breath together first.";
  } else {
    pauseMessage = "";
  }

  if (shiftCount >= 8) {
    return '''
MoodShift AI - Shift #$shiftCount

User said: "$userInput"

YOU MUST OUTPUT EXACTLY THESE 4 LINES:

PAUSE_MESSAGE: $pauseMessage
STYLE: MICRO_DARE
PROSODY: rate=medium pitch=medium volume=medium
RESPONSE: [Your 50-75 word coaching response to "$userInput"]

STYLE OPTIONS (change STYLE line based on mood):
- CHAOS_ENERGY + rate=medium pitch=high volume=loud → if bored/restless/hyper
- GENTLE_GRANDMA + rate=slow pitch=low volume=soft → if anxious/sad/overwhelmed
- PERMISSION_SLIP + rate=medium pitch=medium volume=medium → if guilt/"should"
- REALITY_CHECK + rate=medium pitch=medium volume=medium → if negative self-talk
- MICRO_DARE + rate=medium pitch=medium volume=medium → if neutral (default)

CRITICAL RULES:
1. Line 1 MUST be exactly: PAUSE_MESSAGE: $pauseMessage
2. Line 2 MUST start with: STYLE:
3. Line 3 MUST start with: PROSODY:
4. Line 4 MUST start with: RESPONSE:
5. RESPONSE is your coaching reply, NOT the pause message
''';
  } else {
    return '''
You are MoodShift AI. Shift #$shiftCount (early shift - no pause needed).

User: "$userInput"

YOUR OUTPUT MUST BE EXACTLY 3 LINES STARTING WITH "STYLE:":
STYLE: [CHAOS_ENERGY|GENTLE_GRANDMA|PERMISSION_SLIP|REALITY_CHECK|MICRO_DARE]
PROSODY: rate=[slow|medium] pitch=[low|medium|high] volume=[soft|medium|loud]
RESPONSE: [Your 50-75 word response to the user]

STYLE RULES:
- CHAOS_ENERGY: bored, restless, hyper → rate=medium pitch=high volume=loud
- GENTLE_GRANDMA: anxious, sad, overwhelmed → rate=slow pitch=low volume=soft
- PERMISSION_SLIP: guilt, "should" → rate=medium pitch=medium volume=medium
- REALITY_CHECK: negative self-talk → rate=medium pitch=medium volume=medium
- MICRO_DARE: neutral/default → rate=medium pitch=medium volume=medium

CRITICAL: Your first line MUST be "STYLE:" followed by one of the 5 styles above.
''';
  }
}

Future<String> callGroqAPI(String prompt, String apiKey) async {
  final response = await http.post(
    Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': 'You are MoodShift AI. You MUST output in the EXACT format specified. Every response MUST start with either PAUSE_MESSAGE: (for shifts 8+) or STYLE: (for shifts 1-7). Never output anything before these lines.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.6,
      'max_tokens': 350,
      'top_p': 0.9,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['choices'] != null && data['choices'].isNotEmpty) {
      return data['choices'][0]['message']['content'] ?? '';
    }
  } else if (response.statusCode == 429) {
    throw Exception('RATE_LIMITED');
  }
  throw Exception('API call failed: ${response.statusCode} - ${response.body}');
}

Map<String, String> parseOutput(String output) {
  final pauseMatch = RegExp(r'PAUSE_MESSAGE:\s*(.+)', caseSensitive: false).firstMatch(output);
  final styleMatch = RegExp(r'STYLE:\s*(CHAOS_ENERGY|GENTLE_GRANDMA|PERMISSION_SLIP|REALITY_CHECK|MICRO_DARE)', caseSensitive: false).firstMatch(output);
  final prosodyMatch = RegExp(r'PROSODY:\s*rate=(\w+)\s+pitch=(\w+)\s+volume=(\w+)', caseSensitive: false).firstMatch(output);
  final responseMatch = RegExp(r'RESPONSE:\s*(.+)', caseSensitive: false, dotAll: true).firstMatch(output);

  return {
    'pause_message': pauseMatch?.group(1)?.trim() ?? '',
    'style': styleMatch?.group(1)?.toUpperCase() ?? 'UNKNOWN',
    'prosody': prosodyMatch != null ? 'rate=${prosodyMatch.group(1)} pitch=${prosodyMatch.group(2)} volume=${prosodyMatch.group(3)}' : 'UNKNOWN',
    'response': responseMatch?.group(1)?.trim() ?? output,
  };
}

class TestResult {
  final bool passed;
  final String message;
  final String pauseMessage;
  final String style;
  final String response;

  TestResult({
    required this.passed,
    required this.message,
    required this.pauseMessage,
    required this.style,
    required this.response,
  });
}

TestResult evaluateTestCase(TestCase testCase, String rawOutput) {
  final parsed = parseOutput(rawOutput);
  final pauseMessage = parsed['pause_message']!;
  final style = parsed['style']!;
  final response = parsed['response']!;

  List<String> failures = [];

  if (testCase.expectPauseMessage) {
    // Should have a pause message
    if (pauseMessage.isEmpty) {
      failures.add('Expected PAUSE_MESSAGE but none found');
    } else {
      // Check for expected phrases (at least one should match)
      final pauseLower = pauseMessage.toLowerCase();
      bool foundPhrase = testCase.expectedPhrases.isEmpty;
      for (final phrase in testCase.expectedPhrases) {
        if (pauseLower.contains(phrase.toLowerCase())) {
          foundPhrase = true;
          break;
        }
      }
      if (!foundPhrase) {
        failures.add('PAUSE_MESSAGE missing expected phrases: ${testCase.expectedPhrases}');
      }
    }

    // Should also have normal response
    if (style == 'UNKNOWN') {
      failures.add('Missing STYLE after PAUSE_MESSAGE');
    }
    if (response.isEmpty || response == rawOutput) {
      failures.add('Missing RESPONSE after PAUSE_MESSAGE');
    }
  } else {
    // Should NOT have a pause message
    if (pauseMessage.isNotEmpty) {
      failures.add('Unexpected PAUSE_MESSAGE found: "$pauseMessage"');
    }

    // Should have normal response
    if (style == 'UNKNOWN') {
      failures.add('Missing STYLE');
    }
  }

  return TestResult(
    passed: failures.isEmpty,
    message: failures.isEmpty ? 'All checks passed' : failures.join('. '),
    pauseMessage: pauseMessage,
    style: style,
    response: response.length > 80 ? '${response.substring(0, 80)}...' : response,
  );
}

Future<void> main() async {
  // Load API key from .env file
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ ERROR: .env file not found. Please create one with GROK_API_KEY=your_key');
    exit(1);
  }

  final envContent = envFile.readAsStringSync();
  final apiKeyMatch = RegExp(r'GROK_API_KEY=(.+)').firstMatch(envContent);

  if (apiKeyMatch == null) {
    print('❌ ERROR: GROK_API_KEY not found in .env file.');
    exit(1);
  }

  final apiKey = apiKeyMatch.group(1)!.trim();

  print('🧪 ANTI-BURNOUT PROMPT INTEGRATION TESTS');
  print('=' * 60);
  print('Model: $model');
  print('Test Cases: ${testCases.length}');
  print('=' * 60);
  print('');

  int passed = 0;
  int failed = 0;

  for (final testCase in testCases) {
    print('📋 Test Case ${testCase.id}: ${testCase.scenario}');
    print('   Shift Count: ${testCase.shiftCount}');
    print('   Input: "${testCase.currentInput}"');
    print('   Expect Pause: ${testCase.expectPauseMessage}');

    String rawOutput = '';
    int retries = 0;
    const maxRetries = 3;

    while (retries < maxRetries) {
      try {
        final prompt = buildPrompt(testCase.currentInput, testCase.previousInputs);
        rawOutput = await callGroqAPI(prompt, apiKey);
        break;
      } catch (e) {
        if (e.toString().contains('RATE_LIMITED')) {
          retries++;
          print('   ⏳ Rate limited, waiting 5 seconds before retry $retries/$maxRetries...');
          await Future.delayed(Duration(seconds: 5));
        } else {
          print('   ❌ API Error: $e');
          failed++;
          break;
        }
      }
    }

    if (rawOutput.isEmpty) {
      print('   ❌ FAILED: Could not get response from API');
      failed++;
      continue;
    }

    final result = evaluateTestCase(testCase, rawOutput);

    if (result.passed) {
      print('   ✅ PASSED');
      passed++;
    } else {
      print('   ❌ FAILED: ${result.message}');
      failed++;
    }

    if (result.pauseMessage.isNotEmpty) {
      print('   Pause: ${result.pauseMessage.length > 60 ? '${result.pauseMessage.substring(0, 60)}...' : result.pauseMessage}');
    }
    print('   Style: ${result.style}');
    print('   Response: ${result.response}');
    print('');

    // Small delay between tests
    await Future.delayed(Duration(seconds: 2));
  }

  print('=' * 60);
  print('📊 RESULTS SUMMARY');
  print('=' * 60);
  print('Total: ${testCases.length} | Passed: $passed | Failed: $failed');
  print('Pass Rate: ${(passed / testCases.length * 100).toStringAsFixed(1)}%');
  print('');

  if (failed == 0) {
    print('✅ ALL TESTS PASSED!');
    exit(0);
  } else {
    print('❌ SOME TESTS FAILED - Prompt needs strengthening!');
    exit(1);
  }
}

