import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_service.dart';
import 'storage_service.dart';
import 'crashlytics_service.dart';

class GroqLLMService extends GetxService {
  final Random _random = Random();
  late final String _apiKey;
  late final String _model;
  late final String _groqApiUrl;
  late final double _temperature;
  late final int _maxTokens;
  late final int _timeoutSeconds;
  late final double _frequencyPenalty;
  late final double _presencePenalty;
  late final int _maxResponseWords;
  late final StorageService _storage;
  late final CrashlyticsService _crashlytics;

  MoodStyle? _lastSelectedStyle;
  Map<String, String> _lastProsody = {'rate': 'medium', 'pitch': 'medium', 'volume': 'medium'};
  Map<String, dynamic> _lastSSML = _getDefaultSSML();

  @override
  void onInit() {
    super.onInit();
    _apiKey = dotenv.env['GROK_API_KEY'] ?? '';
    _model = dotenv.env['GROK_MODEL_NAME'] ?? 'llama-3.2-3b-preview';
    _groqApiUrl = dotenv.env['GROK_API_URL'] ?? 'https://api.groq.com/openai/v1/chat/completions';
    _temperature = double.tryParse(dotenv.env['GROK_TEMPERATURE'] ?? '0.9') ?? 0.9;
    _maxTokens = int.tryParse(dotenv.env['GROK_MAX_TOKENS'] ?? '800') ?? 800;
    _timeoutSeconds = int.tryParse(dotenv.env['GROK_TIMEOUT_SECONDS'] ?? '10') ?? 10;
    _frequencyPenalty = double.tryParse(dotenv.env['GROK_FREQUENCY_PENALTY'] ?? '0.8') ?? 0.8;
    _presencePenalty = double.tryParse(dotenv.env['GROK_PRESENCE_PENALTY'] ?? '0.8') ?? 0.8;
    _maxResponseWords = int.tryParse(dotenv.env['GROK_MAX_RESPONSE_WORDS'] ?? '300') ?? 300;
    _storage = Get.find<StorageService>();
    _crashlytics = Get.find<CrashlyticsService>();
  }

  Future<String> generateResponse(String userInput, String language) async {
    _storage.addUserInputToHistory(userInput);

    if (userInput.trim().isEmpty || userInput.trim().length < 3) {
      return _getHardcodedFallback(language);
    }

    // Check for unsafe content BEFORE calling LLM
    final safetyResult = _checkContentSafety(userInput);
    if (!safetyResult['isSafe']) {
      final declineResponse = _getDeclineResponse(language, safetyResult['category'] as String);
      _lastSelectedStyle = MoodStyle.gentleGrandma;
      _lastProsody = {'rate': 'slow', 'pitch': 'low', 'volume': 'soft'};
      _storage.addAIResponseToHistory(declineResponse);
      return declineResponse;
    }

    final cached = _storage.findCachedResponse(userInput, language);
    if (cached != null) {
      final response = cached['response'] as String;
      _storage.addAIResponseToHistory(response);
      return response;
    }

    try {
      final prompt = _buildPromptWithStyleSelection(userInput, language);

      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are MoodShift AI, a compassionate mood companion. You analyze user input and select the most appropriate coaching style, then respond in that style. Your response will be spoken aloud immediately. ALWAYS respond with valid JSON only.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': _temperature,
          'max_tokens': _maxTokens,
          'top_p': 1,
          'frequency_penalty': _frequencyPenalty,
          'presence_penalty': _presencePenalty,
          'response_format': {'type': 'json_object'},
        }),
      ).timeout(
        Duration(seconds: _timeoutSeconds),
        onTimeout: () {
          final timeoutError = Exception('Groq API timeout after $_timeoutSeconds seconds');
          _crashlytics.reportLLMError(timeoutError, StackTrace.current, operation: 'generateResponse', model: _model, userInput: userInput);
          throw timeoutError;
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          String generatedText = data['choices'][0]['message']['content'] ?? '';

          final parsed = _parseStyleAndResponse(generatedText);
          final selectedStyle = parsed['style'] as MoodStyle;
          final prosody = parsed['prosody'] as Map<String, String>;
          final ssml = parsed['ssml'] as Map<String, dynamic>;
          String finalResponse = parsed['response'] as String;

          _lastSelectedStyle = selectedStyle;
          _lastProsody = prosody;
          _lastSSML = ssml;

          finalResponse = _cleanResponse(finalResponse);
          _storage.addCachedResponse(userInput, finalResponse, language);
          _storage.addAIResponseToHistory(finalResponse);

          return finalResponse;
        }
      } else {
        _crashlytics.reportLLMError(
          Exception('Groq API returned status ${response.statusCode}'),
          StackTrace.current,
          operation: 'generateResponse',
          model: _model,
          statusCode: response.statusCode,
          userInput: userInput,
        );
      }

      return _getHardcodedFallback(language);
    } catch (e, stackTrace) {
      _crashlytics.reportLLMError(e, stackTrace, operation: 'generateResponse', model: _model, userInput: userInput);
      return _getHardcodedFallback(language);
    }
  }

  /// Generate a 2× STRONGER version of the original response
  Future<String> generateStrongerResponse(String originalResponse, MoodStyle originalStyle, String language) async {
    // Check original response for safety (in case it slipped through)
    final safetyResult = _checkContentSafety(originalResponse);
    if (!safetyResult['isSafe']) {
      return _getDeclineResponse(language, safetyResult['category'] as String);
    }

    try {
      final languageName = _getLanguageName(language);
      final styleStr = _getStyleString(originalStyle);

      final prompt = '''ORIGINAL RESPONSE: "$originalResponse"
ORIGINAL STYLE: $styleStr

TRANSFORM THIS INTO 2× STRONGER VERSION:
- Keep exact same style and core message
- Make it dramatically MORE intense, emotional, urgent
- Use stronger verbs, CAPS, !!, deeper affirmations, bigger dares
- Add one short power phrase (e.g., "You are UNSTOPPABLE", "This is YOUR moment")
- Same length (50–75 words)
- Stay in $languageName
- No emojis

FORBIDDEN WORDS (never use): safety, moderation, inappropriate, sexual, violence, hate, risk, sorry, cannot

Respond with this exact JSON structure:
{
  "style": "$styleStr",
  "prosody": {"rate": "medium", "pitch": "high", "volume": "loud"},
  "ssml": {
    "generative": {"rate": "medium", "volume": "x-loud"},
    "neural": {"volume_db": "+6dB"},
    "standard": {"rate": "medium", "pitch": "+15%", "volume": "+6dB", "emphasis": "strong"}
  },
  "response": "Your 2× STRONGER version here"
}

Make it feel like the AI just LEVELED UP!''';

      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': 'You are MoodShift AI in MAXIMUM POWER MODE. Amplify responses to 2× intensity. ALWAYS respond with valid JSON only.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.9,
          'max_tokens': _maxTokens,
          'top_p': 1,
          'frequency_penalty': 0.2,
          'presence_penalty': 0.8,
          'response_format': {'type': 'json_object'},
        }),
      ).timeout(
        Duration(seconds: _timeoutSeconds),
        onTimeout: () {
          final timeoutError = Exception('Groq API timeout for 2× stronger after $_timeoutSeconds seconds');
          _crashlytics.reportLLMError(timeoutError, StackTrace.current, operation: 'generateStrongerResponse', model: _model);
          throw timeoutError;
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          String generatedText = data['choices'][0]['message']['content'] ?? '';
          final parsed = _parseStyleAndResponse(generatedText);
          final selectedStyle = parsed['style'] as MoodStyle;
          final prosody = parsed['prosody'] as Map<String, String>;
          final ssml = parsed['ssml'] as Map<String, dynamic>? ?? _getDefaultStrongerSSML();
          String finalResponse = parsed['response'] as String;

          _lastSelectedStyle = selectedStyle;
          _lastProsody = prosody;
          _lastSSML = ssml;
          finalResponse = _cleanResponse(finalResponse);
          return finalResponse;
        }
      } else {
        _crashlytics.reportLLMError(
          Exception('Groq API returned status ${response.statusCode} for 2× stronger'),
          StackTrace.current,
          operation: 'generateStrongerResponse',
          model: _model,
          statusCode: response.statusCode,
        );
      }

      // Use default stronger SSML for fallback
      _lastSSML = _getDefaultStrongerSSML();
      return _amplifyResponseManually(originalResponse);
    } catch (e, stackTrace) {
      _crashlytics.reportLLMError(e, stackTrace, operation: 'generateStrongerResponse', model: _model);
      _lastSSML = _getDefaultStrongerSSML();
      return _amplifyResponseManually(originalResponse);
    }
  }

  String _getStyleString(MoodStyle style) {
    switch (style) {
      case MoodStyle.chaosEnergy:
        return 'CHAOS_ENERGY';
      case MoodStyle.gentleGrandma:
        return 'GENTLE_GRANDMA';
      case MoodStyle.permissionSlip:
        return 'PERMISSION_SLIP';
      case MoodStyle.realityCheck:
        return 'REALITY_CHECK';
      case MoodStyle.microDare:
        return 'MICRO_DARE';
    }
  }

  String _amplifyResponseManually(String original) {
    String amplified = original.toUpperCase();
    amplified = amplified.replaceAll('.', '! 🔥');
    amplified = amplified.replaceAll('!', '!! ⚡');
    amplified = '🚀 $amplified 💪';
    return amplified;
  }

  /// Build prompt that asks LLM to determine the style and respond
  String _buildPromptWithStyleSelection(String userInput, String language) {
    final languageName = _getLanguageName(language);
    final streak = _storage.getCurrentStreak();
    final timeContext = _getTimeContext();

    // Get recent history for anti-repetition
    final recentResponses = _storage.getRecentAIResponses();
    final responsesText = recentResponses.isEmpty ? 'None' : recentResponses.map((r) => r.length > 60 ? '${r.substring(0, 60)}...' : r).join(' | ');

    // Use injected storage service for consistency
    final String voiceGender = _storage.getVoiceGender();

    final ssmlGuide = '''
"ssml": {
  "generative": {"rate": "medium", "volume": "medium"},
  "neural": {"volume_db": "+0dB"},
  "standard": {"rate": "medium", "pitch": "medium", "volume": "medium"}
}''';

    return '''
User said: "$userInput"

Respond with this exact JSON structure:
{
  "style": "MICRO_DARE",
  "prosody": {"rate": "medium", "pitch": "medium", "volume": "medium"},
  $ssmlGuide,
  "response": "Your 50-75 word coaching response here"
}

STYLE OPTIONS with matching SSML (choose based on user's mood):

1. "CHAOS_ENERGY" → if bored/restless/hyper
   prosody: {"rate": "medium", "pitch": "high", "volume": "loud"}
   ssml.generative: {"rate": "medium", "volume": "x-loud"}
   ssml.neural: {"volume_db": "+6dB"}
   ssml.standard: {"rate": "medium", "pitch": "+10%", "volume": "loud"}

2. "GENTLE_GRANDMA" → if anxious/sad/overwhelmed
   prosody: {"rate": "slow", "pitch": "low", "volume": "soft"}
   ssml.generative: {"rate": "x-slow", "volume": "x-soft"}
   ssml.neural: {"volume_db": "-6dB"}
   ssml.standard: {"rate": "slow", "pitch": "-10%", "volume": "soft"}

3. "PERMISSION_SLIP" → if guilt/"should"
   prosody: {"rate": "medium", "pitch": "medium", "volume": "medium"}
   ssml.generative: {"rate": "medium", "volume": "medium"}
   ssml.neural: {"volume_db": "+0dB"}
   ssml.standard: {"rate": "medium", "pitch": "medium", "volume": "medium"}

4. "REALITY_CHECK" → if negative self-talk
   prosody: {"rate": "medium", "pitch": "medium", "volume": "medium"}
   ssml.generative: {"rate": "medium", "volume": "medium"}
   ssml.neural: {"volume_db": "+0dB"}
   ssml.standard: {"rate": "medium", "pitch": "medium", "volume": "medium"}

5. "MICRO_DARE" → if neutral (default)
   prosody: {"rate": "medium", "pitch": "medium", "volume": "medium"}
   ssml.generative: {"rate": "medium", "volume": "medium"}
   ssml.neural: {"volume_db": "+0dB"}
   ssml.standard: {"rate": "medium", "pitch": "medium", "volume": "medium"}

SAFETY: If input mentions flirty/desired/sexy/dirty/punch/hurt/harm/kill/cutting/suicide/disappear/hate myself/racism/suffer → use GENTLE_GRANDMA with breathing exercise

RULES:
1. FORBIDDEN words in response: safety, moderation, inappropriate, sexual, violence, hate, risk
2. Response must be in $languageName language
3. No emojis in response

Context: Day $streak, $timeContext, $voiceGender voice
Previous responses to avoid: $responsesText
''';
  }

  /// Parse JSON response from LLM
  Map<String, dynamic> _parseStyleAndResponse(String llmOutput) {
    try {
      // Parse JSON response
      final json = jsonDecode(llmOutput) as Map<String, dynamic>;

      // Extract style
      final styleStr = (json['style'] as String?)?.toUpperCase() ?? 'MICRO_DARE';
      final selectedStyle = _parseStyle(styleStr);

      // Extract prosody
      Map<String, String> prosody = {'rate': 'medium', 'pitch': 'medium', 'volume': 'medium'};
      if (json['prosody'] != null && json['prosody'] is Map) {
        final prosodyJson = json['prosody'] as Map<String, dynamic>;
        prosody = {
          'rate': (prosodyJson['rate'] as String?)?.toLowerCase() ?? 'medium',
          'pitch': (prosodyJson['pitch'] as String?)?.toLowerCase() ?? 'medium',
          'volume': (prosodyJson['volume'] as String?)?.toLowerCase() ?? 'medium',
        };
      } else {
        prosody = _getDefaultProsody(selectedStyle);
      }

      // Extract SSML settings for different engines
      Map<String, dynamic> ssml = _getDefaultSSML();
      if (json['ssml'] != null && json['ssml'] is Map) {
        ssml = _parseSSMLSettings(json['ssml'] as Map<String, dynamic>);
      }

      // Extract response
      String response = (json['response'] as String?) ?? '';
      response = _cleanResponse(response);
      response = _removeEmojis(response);

      return {'style': selectedStyle, 'prosody': prosody, 'ssml': ssml, 'response': response};
    } catch (e) {
      // Fallback: try to extract JSON from the output if it's wrapped in other text
      return _parseStyleAndResponseFallback(llmOutput);
    }
  }

  /// Parse SSML settings from JSON, with defaults for missing values
  Map<String, dynamic> _parseSSMLSettings(Map<String, dynamic> ssmlJson) {
    final defaults = _getDefaultSSML();

    return {
      'generative': _parseEngineSSML(ssmlJson['generative'], defaults['generative'] as Map<String, dynamic>),
      'neural': _parseEngineSSML(ssmlJson['neural'], defaults['neural'] as Map<String, dynamic>),
      'standard': _parseEngineSSML(ssmlJson['standard'], defaults['standard'] as Map<String, dynamic>),
    };
  }

  /// Parse SSML settings for a specific engine
  Map<String, dynamic> _parseEngineSSML(dynamic engineJson, Map<String, dynamic> defaults) {
    if (engineJson == null || engineJson is! Map) {
      return defaults;
    }

    final result = Map<String, dynamic>.from(defaults);
    final engineMap = engineJson as Map<String, dynamic>;

    // Copy all values from the JSON, keeping defaults for missing keys
    for (final key in engineMap.keys) {
      if (engineMap[key] != null) {
        result[key] = engineMap[key];
      }
    }

    return result;
  }

  /// Fallback parser for when JSON parsing fails
  /// Tries to extract JSON from the output or falls back to regex
  Map<String, dynamic> _parseStyleAndResponseFallback(String llmOutput) {
    try {
      // Try to find JSON object in the output
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(llmOutput);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;

        final styleStr = (json['style'] as String?)?.toUpperCase() ?? 'MICRO_DARE';
        final selectedStyle = _parseStyle(styleStr);

        Map<String, String> prosody = {'rate': 'medium', 'pitch': 'medium', 'volume': 'medium'};
        if (json['prosody'] != null && json['prosody'] is Map) {
          final prosodyJson = json['prosody'] as Map<String, dynamic>;
          prosody = {
            'rate': (prosodyJson['rate'] as String?)?.toLowerCase() ?? 'medium',
            'pitch': (prosodyJson['pitch'] as String?)?.toLowerCase() ?? 'medium',
            'volume': (prosodyJson['volume'] as String?)?.toLowerCase() ?? 'medium',
          };
        } else {
          prosody = _getDefaultProsody(selectedStyle);
        }

        // Extract SSML settings for different engines
        Map<String, dynamic> ssml = _getDefaultSSML();
        if (json['ssml'] != null && json['ssml'] is Map) {
          ssml = _parseSSMLSettings(json['ssml'] as Map<String, dynamic>);
        }

        String response = (json['response'] as String?) ?? '';
        response = _cleanResponse(response);
        response = _removeEmojis(response);

        return {'style': selectedStyle, 'prosody': prosody, 'ssml': ssml, 'response': response};
      }
    } catch (_) {
      // JSON extraction failed, continue to default
    }

    // Ultimate fallback: return the raw output as response
    return {
      'style': MoodStyle.microDare,
      'prosody': {'rate': 'medium', 'pitch': 'medium', 'volume': 'medium'},
      'ssml': _getDefaultSSML(),
      'response': _removeEmojis(llmOutput),
    };
  }

  /// Parse style string to MoodStyle enum
  MoodStyle _parseStyle(String styleStr) {
    switch (styleStr) {
      case 'CHAOS_ENERGY':
        return MoodStyle.chaosEnergy;
      case 'GENTLE_GRANDMA':
        return MoodStyle.gentleGrandma;
      case 'PERMISSION_SLIP':
        return MoodStyle.permissionSlip;
      case 'REALITY_CHECK':
        return MoodStyle.realityCheck;
      case 'MICRO_DARE':
      default:
        return MoodStyle.microDare;
    }
  }

  /// Get default prosody settings for a style (fallback if LLM doesn't provide)
  Map<String, String> _getDefaultProsody(MoodStyle style) {
    switch (style) {
      case MoodStyle.chaosEnergy:
        return {'rate': 'medium', 'pitch': 'high', 'volume': 'loud'};
      case MoodStyle.gentleGrandma:
        return {'rate': 'slow', 'pitch': 'low', 'volume': 'soft'};
      case MoodStyle.permissionSlip:
        return {'rate': 'medium', 'pitch': 'medium', 'volume': 'medium'};
      case MoodStyle.realityCheck:
        return {'rate': 'medium', 'pitch': 'medium', 'volume': 'medium'};
      case MoodStyle.microDare:
        return {'rate': 'medium', 'pitch': 'medium', 'volume': 'medium'};
    }
  }



  // Safety: Unsafe content categories and keywords
  static const Map<String, List<String>> _unsafeKeywords = {
    'sexual': [
      'sexy', 'flirty', 'desired', 'dirty', 'horny', 'naked', 'nude',
      'sex', 'porn', 'erotic', 'seduce', 'kiss me', 'touch me',
      'make love', 'hookup', 'hook up', 'hot body', 'turn me on',
      'sexual', 'intercourse', 'orgasm', 'masturbate', 'foreplay',
      'strip', 'stripper', 'prostitute', 'escort', 'onlyfans',
      'boobs', 'breasts', 'penis', 'vagina', 'genital', 'fetish',
      'bdsm', 'kinky', 'threesome', 'orgy', 'affair', 'cheat on',
    ],
    'violence': [
      'kill', 'murder', 'punch', 'hurt', 'harm', 'attack', 'stab',
      'shoot', 'beat up', 'fight', 'destroy', 'revenge', 'weapon',
      'gun', 'knife', 'blood', 'torture', 'abuse',
      'killing', 'killer', 'slaughter', 'massacre', 'assassinate',
      'strangle', 'choke', 'suffocate', 'drown', 'poison',
      'rifle', 'pistol', 'firearm', 'bullet', 'ammo', 'ammunition',
      'shotgun', 'ar-15', 'ak-47', 'machine gun', 'sniper',
      'bomb', 'explosive', 'grenade', 'detonate', 'blow up',
      'assault', 'batter', 'brutalize', 'maim', 'mutilate',
    ],
    'self_harm': [
      'suicide', 'kill myself', 'end my life', 'cutting', 'self harm',
      'self-harm', 'want to die', 'disappear', 'not exist', 'end it all',
      'hurt myself', 'harm myself', 'slit', 'overdose',
      'suicidal', 'jump off', 'hang myself', 'drown myself',
      'take my life', 'no reason to live', 'better off dead',
      'wrist', 'bleed out', 'pills', 'end it',
    ],
    'hate': [
      'racism', 'racist', 'hate', 'slur', 'discriminate', 'bigot',
      'nazi', 'supremacy', 'inferior', 'ethnic cleansing',
      'homophobic', 'transphobic', 'xenophobic', 'sexist',
      'antisemitic', 'islamophobic', 'white power', 'kkk',
    ],
    'drugs': [
      'drugs', 'cocaine', 'heroin', 'meth', 'methamphetamine',
      'marijuana', 'weed', 'cannabis', 'joint', 'blunt', 'edibles',
      'smoke weed', 'get high', 'getting high', 'stoned', 'baked',
      'lsd', 'acid', 'shrooms', 'mushrooms', 'ecstasy', 'mdma',
      'molly', 'fentanyl', 'opioid', 'opiate', 'crack', 'ketamine',
      'xanax', 'adderall', 'percocet', 'oxy', 'oxycontin',
      'smoke', 'smoking', 'vape', 'vaping', 'cigarette', 'nicotine',
      'tobacco', 'juul', 'dab', 'dabbing', 'dealer', 'plug',
      'snort', 'inject', 'needle', 'syringe', 'trip', 'tripping',
    ],
    'illegal': [
      'steal', 'rob', 'robbery', 'theft', 'burglary', 'break in',
      'hack', 'hacking', 'phishing', 'malware', 'ransomware',
      'illegal', 'crime', 'criminal', 'fraud', 'scam', 'counterfeit',
      'launder', 'money laundering', 'bribe', 'blackmail', 'extort',
      'smuggle', 'trafficking', 'cartel', 'gang', 'mafia',
    ],
  };

  /// Check if user input contains unsafe content
  Map<String, dynamic> _checkContentSafety(String input) {
    final lowerInput = input.toLowerCase();

    for (final entry in _unsafeKeywords.entries) {
      final category = entry.key;
      final keywords = entry.value;

      for (final keyword in keywords) {
        if (lowerInput.contains(keyword)) {
          return {'isSafe': false, 'category': category, 'keyword': keyword};
        }
      }
    }

    return {'isSafe': true, 'category': '', 'keyword': ''};
  }

  /// Get a declining response for unsafe content
  String _getDeclineResponse(String languageCode, String category) {
    final responses = _declineResponsesByLanguage[languageCode] ??
        _declineResponsesByLanguage['en']!;
    return responses[category] ?? responses['default']!;
  }

  static const Map<String, Map<String, String>> _declineResponsesByLanguage = {
    'en': {
      'sexual': "I'm here to help with your mood and focus, not for that kind of conversation. Let's talk about how you're really feeling today.",
      'violence': "I can't help with anything that could hurt you or others. If you're feeling angry, let's find a healthier way to process that together.",
      'self_harm': "I'm really concerned about what you shared. Please reach out to a crisis helpline or someone you trust. You matter, and help is available.",
      'hate': "I'm not able to engage with that. Everyone deserves respect. Let's focus on something that helps you feel better.",
      'drugs': "I can't discuss substances or smoking. Your health matters to me. Let's talk about what's really going on and find healthier ways to cope.",
      'illegal': "I can't help with that. Let's redirect to something positive that supports your wellbeing.",
      'default': "I'm not able to help with that request. Let's focus on your mood and what's really going on for you today.",
    },
    'hi': {
      'sexual': "मैं आपके मूड और फोकस में मदद करने के लिए हूं, इस तरह की बातचीत के लिए नहीं। आइए बात करें कि आज आप वास्तव में कैसा महसूस कर रहे हैं।",
      'violence': "मैं किसी ऐसी चीज़ में मदद नहीं कर सकता जो आपको या दूसरों को नुकसान पहुंचा सकती है। अगर आप गुस्सा महसूस कर रहे हैं, तो आइए मिलकर एक स्वस्थ तरीका खोजें।",
      'self_harm': "आपने जो साझा किया उससे मुझे वास्तव में चिंता है। कृपया किसी क्राइसिस हेल्पलाइन या किसी विश्वसनीय व्यक्ति से संपर्क करें। आप मायने रखते हैं।",
      'hate': "मैं इसमें शामिल नहीं हो सकता। हर कोई सम्मान का हकदार है। आइए किसी ऐसी चीज़ पर ध्यान दें जो आपको बेहतर महसूस कराए।",
      'drugs': "मैं नशीले पदार्थों या धूम्रपान पर चर्चा नहीं कर सकता। आपका स्वास्थ्य मेरे लिए महत्वपूर्ण है। आइए बात करें कि वास्तव में क्या हो रहा है।",
      'illegal': "मैं इसमें मदद नहीं कर सकता। आइए कुछ सकारात्मक पर ध्यान दें।",
      'default': "मैं उस अनुरोध में मदद नहीं कर सकता। आइए आपके मूड पर ध्यान दें।",
    },
    'es': {
      'sexual': "Estoy aquí para ayudarte con tu estado de ánimo y enfoque, no para ese tipo de conversación. Hablemos de cómo te sientes realmente hoy.",
      'violence': "No puedo ayudar con nada que pueda lastimarte a ti o a otros. Si te sientes enojado, encontremos una forma más saludable de procesarlo juntos.",
      'self_harm': "Me preocupa mucho lo que compartiste. Por favor contacta una línea de crisis o alguien de confianza. Importas, y hay ayuda disponible.",
      'hate': "No puedo participar en eso. Todos merecen respeto. Enfoquémonos en algo que te ayude a sentirte mejor.",
      'drugs': "No puedo discutir sustancias o fumar. Tu salud me importa. Hablemos de lo que realmente está pasando y encontremos formas más saludables de afrontarlo.",
      'illegal': "No puedo ayudar con eso. Redirijamos hacia algo positivo.",
      'default': "No puedo ayudar con esa solicitud. Enfoquémonos en tu estado de ánimo.",
    },
    'zh': {
      'sexual': "我是来帮助你调整情绪和专注力的，不是进行那种对话。让我们谈谈你今天真正的感受。",
      'violence': "我无法帮助任何可能伤害你或他人的事情。如果你感到愤怒，让我们一起找到更健康的方式来处理。",
      'self_harm': "我真的很担心你分享的内容。请联系危机热线或你信任的人。你很重要，帮助是可用的。",
      'hate': "我无法参与那个。每个人都值得尊重。让我们专注于能让你感觉更好的事情。",
      'drugs': "我无法讨论物质或吸烟。你的健康对我很重要。让我们谈谈真正发生了什么，找到更健康的应对方式。",
      'illegal': "我无法帮助那个。让我们转向积极的事情。",
      'default': "我无法帮助那个请求。让我们专注于你的情绪。",
    },
    'fr': {
      'sexual': "Je suis là pour t'aider avec ton humeur et ta concentration, pas pour ce genre de conversation. Parlons de comment tu te sens vraiment aujourd'hui.",
      'violence': "Je ne peux pas aider avec quoi que ce soit qui pourrait te blesser ou blesser les autres. Si tu te sens en colère, trouvons ensemble une façon plus saine de gérer ça.",
      'self_harm': "Je suis vraiment inquiet par ce que tu as partagé. S'il te plaît, contacte une ligne de crise ou quelqu'un en qui tu as confiance. Tu comptes, et l'aide est disponible.",
      'hate': "Je ne peux pas m'engager dans ça. Tout le monde mérite le respect. Concentrons-nous sur quelque chose qui t'aide à te sentir mieux.",
      'drugs': "Je ne peux pas discuter de substances ou de tabac. Ta santé compte pour moi. Parlons de ce qui se passe vraiment et trouvons des moyens plus sains de faire face.",
      'illegal': "Je ne peux pas aider avec ça. Redirigeons vers quelque chose de positif.",
      'default': "Je ne peux pas aider avec cette demande. Concentrons-nous sur ton humeur.",
    },
    'de': {
      'sexual': "Ich bin hier, um dir bei deiner Stimmung und Konzentration zu helfen, nicht für diese Art von Gespräch. Lass uns darüber reden, wie du dich heute wirklich fühlst.",
      'violence': "Ich kann bei nichts helfen, das dir oder anderen schaden könnte. Wenn du wütend bist, lass uns gemeinsam einen gesünderen Weg finden, damit umzugehen.",
      'self_harm': "Ich mache mir wirklich Sorgen über das, was du geteilt hast. Bitte wende dich an eine Krisenhotline oder jemanden, dem du vertraust. Du bist wichtig, und Hilfe ist verfügbar.",
      'hate': "Ich kann mich darauf nicht einlassen. Jeder verdient Respekt. Lass uns auf etwas konzentrieren, das dir hilft, dich besser zu fühlen.",
      'drugs': "Ich kann nicht über Substanzen oder Rauchen sprechen. Deine Gesundheit ist mir wichtig. Lass uns darüber reden, was wirklich los ist, und gesündere Wege finden.",
      'illegal': "Ich kann dabei nicht helfen. Lass uns auf etwas Positives umlenken.",
      'default': "Ich kann bei dieser Anfrage nicht helfen. Lass uns auf deine Stimmung konzentrieren.",
    },
    'ar': {
      'sexual': "أنا هنا لمساعدتك في مزاجك وتركيزك، وليس لهذا النوع من المحادثات. دعنا نتحدث عن شعورك الحقيقي اليوم.",
      'violence': "لا أستطيع المساعدة في أي شيء قد يؤذيك أو يؤذي الآخرين. إذا كنت تشعر بالغضب، دعنا نجد طريقة أكثر صحة للتعامل مع ذلك معًا.",
      'self_harm': "أنا قلق حقًا مما شاركته. يرجى التواصل مع خط أزمات أو شخص تثق به. أنت مهم، والمساعدة متاحة.",
      'hate': "لا أستطيع المشاركة في ذلك. الجميع يستحق الاحترام. دعنا نركز على شيء يساعدك على الشعور بشكل أفضل.",
      'drugs': "لا أستطيع مناقشة المواد أو التدخين. صحتك تهمني. دعنا نتحدث عما يحدث حقًا ونجد طرقًا أكثر صحة للتعامل.",
      'illegal': "لا أستطيع المساعدة في ذلك. دعنا نتجه نحو شيء إيجابي.",
      'default': "لا أستطيع المساعدة في هذا الطلب. دعنا نركز على مزاجك.",
    },
    'ja': {
      'sexual': "私はあなたの気分と集中力を助けるためにここにいます。そのような会話のためではありません。今日本当にどう感じているか話しましょう。",
      'violence': "あなたや他の人を傷つける可能性のあることは手伝えません。怒りを感じているなら、一緒にもっと健康的な方法を見つけましょう。",
      'self_harm': "あなたが共有したことを本当に心配しています。危機対応の相談窓口や信頼できる人に連絡してください。あなたは大切です。助けは利用可能です。",
      'hate': "それには関われません。誰もが尊重に値します。気分が良くなることに集中しましょう。",
      'drugs': "物質や喫煙については話せません。あなたの健康は私にとって大切です。本当に何が起きているか話して、より健康的な対処法を見つけましょう。",
      'illegal': "それは手伝えません。ポジティブなことに向かいましょう。",
      'default': "そのリクエストは手伝えません。あなたの気分に集中しましょう。",
    },
  };

  /// Remove all emojis from text
  String _removeEmojis(String text) {
    // Remove emojis using Unicode ranges
    return text.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA00}-\u{1FA6F}]|[\u{1FA70}-\u{1FAFF}]|[\u{FE00}-\u{FE0F}]|[\u{1F004}]|[\u{1F0CF}]|[\u{1F18E}]|[\u{3030}]|[\u{2B50}]|[\u{2B55}]|[\u{231A}-\u{231B}]|[\u{23E9}-\u{23F3}]|[\u{25AA}-\u{25AB}]|[\u{25B6}]|[\u{25C0}]|[\u{25FB}-\u{25FE}]|[\u{2934}-\u{2935}]|[\u{2B05}-\u{2B07}]|[\u{2B1B}-\u{2B1C}]|[\u{3297}]|[\u{3299}]|[\u{00A9}]|[\u{00AE}]|[\u{203C}]|[\u{2049}]|[\u{2122}]|[\u{2139}]|[\u{2194}-\u{2199}]|[\u{21A9}-\u{21AA}]|[\u{231A}-\u{231B}]|[\u{2328}]|[\u{23CF}]|[\u{23ED}-\u{23EF}]|[\u{23F8}-\u{23FA}]|[\u{24C2}]|[\u{25AA}-\u{25AB}]|[\u{25B6}]|[\u{25C0}]|[\u{25FB}-\u{25FE}]|[\u{2600}-\u{2604}]|[\u{260E}]|[\u{2611}]|[\u{2614}-\u{2615}]|[\u{2618}]|[\u{2620}]|[\u{2622}-\u{2623}]|[\u{2626}]|[\u{262A}]|[\u{262E}-\u{262F}]|[\u{2638}-\u{263A}]|[\u{2640}]|[\u{2642}]|[\u{2648}-\u{2653}]|[\u{2660}]|[\u{2663}]|[\u{2665}-\u{2666}]|[\u{2668}]|[\u{267B}]|[\u{267F}]|[\u{2692}-\u{2697}]|[\u{2699}]|[\u{269B}-\u{269C}]|[\u{26A0}-\u{26A1}]|[\u{26AA}-\u{26AB}]|[\u{26B0}-\u{26B1}]|[\u{26BD}-\u{26BE}]|[\u{26C4}-\u{26C5}]|[\u{26C8}]|[\u{26CE}-\u{26CF}]|[\u{26D1}]|[\u{26D3}-\u{26D4}]|[\u{26E9}-\u{26EA}]|[\u{26F0}-\u{26F5}]|[\u{26F7}-\u{26FA}]|[\u{26FD}]',
        unicode: true,
      ),
      '',
    ).trim();
  }



  String _getTimeContext() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'late night';
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    if (hour < 21) return 'evening';
    return 'night';
  }



  String _cleanResponse(String response) {
    // Basic cleanup only - let the prompt engineering handle quality
    response = response.trim();

    // Clean up extra whitespace (multiple spaces, tabs, newlines -> single space)
    response = response.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Limit to reasonable length (configurable max words for ~2 minutes)
    final words = response.split(' ');
    if (words.length > _maxResponseWords) {
      response = words.take(_maxResponseWords).join(' ') + '...';
    }

    return response;
  }

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en': return 'English';
      case 'hi': return 'Hindi';
      case 'es': return 'Spanish';
      case 'zh': return 'Chinese';
      case 'fr': return 'French';
      case 'de': return 'German';
      case 'ar': return 'Arabic';
      case 'ja': return 'Japanese';
      default: return 'English';
    }
  }

  MoodStyle getRandomStyle() {
    return MoodStyle.values[_random.nextInt(MoodStyle.values.length)];
  }

  /// Get the last selected style (used for 2x stronger feature)
  MoodStyle? getLastSelectedStyle() {
    return _lastSelectedStyle;
  }

  /// Get the last prosody settings from LLM
  Map<String, String> getLastProsody() {
    return _lastProsody;
  }

  /// Get the last SSML settings from LLM for different Polly engines
  Map<String, dynamic> getLastSSML() {
    return _lastSSML;
  }

  /// Get SSML settings for 2× STRONGER mode
  Map<String, dynamic> getStrongerSSML() {
    return _getDefaultStrongerSSML();
  }

  /// Get SSML settings for Crystal Voice mode
  Map<String, dynamic> getCrystalSSML() {
    return _getDefaultCrystalSSML();
  }

  /// Default SSML settings for all engines
  static Map<String, dynamic> _getDefaultSSML() {
    return {
      'generative': {'rate': 'medium', 'volume': 'medium'},
      'neural': {'volume_db': '+0dB'},
      'standard': {'rate': 'medium', 'pitch': 'medium', 'volume': 'medium'},
    };
  }

  /// Default SSML settings for 2× STRONGER mode
  static Map<String, dynamic> _getDefaultStrongerSSML() {
    return {
      'generative': {'rate': 'medium', 'volume': 'x-loud'},
      'neural': {'volume_db': '+6dB'},
      'standard': {'rate': 'medium', 'pitch': '+15%', 'volume': '+6dB', 'emphasis': 'strong'},
    };
  }

  /// Default SSML settings for Crystal Voice mode
  static Map<String, dynamic> _getDefaultCrystalSSML() {
    return {
      'generative': {'rate': 'x-slow', 'volume': 'x-soft'},
      'neural': {'volume_db': '+0dB', 'drc': true},
      'standard': {'rate': 'slow', 'pitch': '-10%', 'volume': 'soft', 'phonation': 'soft', 'vocal_tract_length': '+12%'},
    };
  }

  String _getHardcodedFallback(String languageCode) {
    final fallbacks = _getFallbacksByLanguage(languageCode);
    final selected = fallbacks[_random.nextInt(fallbacks.length)];
    _storage.addAIResponseToHistory(selected);
    return selected;
  }

  List<String> _getFallbacksByLanguage(String languageCode) {
    final fallbacksMap = {
      'en': [
        "Breathe with me: in for 4… hold for 7… out for 8. You're safe here.",
        "You're doing better than you think. Name one tiny win from today.",
        "Permission granted to rest. You've earned it, no questions asked.",
        "Your brain is a Ferrari — sometimes it just needs a pit stop. Take 5 minutes.",
        "Real talk: You're not broken. You're just running on a different operating system.",
        "Micro dare: Drink a full glass of water right now. Your brain will thank you.",
        "You know what? It's okay to not be okay. Just be here with me for a moment.",
        "Plot twist: The fact that you're trying is already a win. Keep going.",
        "Here's your permission slip to do absolutely nothing for the next 10 minutes.",
        "Gentle reminder: You're loved, you're enough, and you're going to be okay.",
      ],
      'hi': [
        "मेरे साथ सांस लें: 4 के लिए अंदर… 7 के लिए रोकें… 8 के लिए बाहर। आप यहां सुरक्षित हैं।",
        "आप जितना सोचते हैं उससे बेहतर कर रहे हैं। आज की एक छोटी जीत बताएं।",
        "आराम करने की अनुमति दी गई। आपने इसे अर्जित किया है, कोई सवाल नहीं।",
        "आपका दिमाग एक फेरारी है — कभी-कभी इसे बस एक पिट स्टॉप की जरूरत होती है। 5 मिनट लें।",
        "सच्ची बात: आप टूटे नहीं हैं। आप बस एक अलग ऑपरेटिंग सिस्टम पर चल रहे हैं।",
        "माइक्रो डेयर: अभी एक पूरा गिलास पानी पिएं। आपका दिमाग आपको धन्यवाद देगा।",
        "आप जानते हैं क्या? ठीक न होना ठीक है। बस एक पल के लिए मेरे साथ रहें।",
        "प्लॉट ट्विस्ट: यह तथ्य कि आप कोशिश कर रहे हैं पहले से ही एक जीत है। जारी रखें।",
        "यहां अगले 10 मिनट के लिए बिल्कुल कुछ न करने की आपकी अनुमति पर्ची है।",
        "कोमल अनुस्मारक: आप प्यार किए जाते हैं, आप पर्याप्त हैं, और आप ठीक हो जाएंगे।",
      ],
      'es': [
        "Respira conmigo: inhala por 4… mantén por 7… exhala por 8. Estás seguro aquí.",
        "Lo estás haciendo mejor de lo que piensas. Nombra una pequeña victoria de hoy.",
        "Permiso concedido para descansar. Te lo has ganado, sin preguntas.",
        "Tu cerebro es un Ferrari — a veces solo necesita una parada en boxes. Toma 5 minutos.",
        "Hablemos claro: No estás roto. Solo estás ejecutando un sistema operativo diferente.",
        "Micro desafío: Bebe un vaso lleno de agua ahora mismo. Tu cerebro te lo agradecerá.",
        "¿Sabes qué? Está bien no estar bien. Solo quédate aquí conmigo un momento.",
        "Giro de trama: El hecho de que lo estés intentando ya es una victoria. Sigue adelante.",
        "Aquí está tu permiso para no hacer absolutamente nada durante los próximos 10 minutos.",
        "Recordatorio gentil: Eres amado, eres suficiente y vas a estar bien.",
      ],
      'zh': [
        "和我一起呼吸：吸气4秒…保持7秒…呼气8秒。你在这里很安全。",
        "你做得比你想象的要好。说出今天的一个小胜利。",
        "允许休息。你已经赢得了它，不用问。",
        "你的大脑是一辆法拉利——有时它只需要一个维修站。休息5分钟。",
        "实话实说：你没有坏掉。你只是在运行不同的操作系统。",
        "微挑战：现在喝一整杯水。你的大脑会感谢你。",
        "你知道吗？不好也没关系。和我在这里待一会儿。",
        "情节转折：你正在尝试这一事实已经是一场胜利。继续前进。",
        "这是你在接下来的10分钟内什么都不做的许可单。",
        "温柔提醒：你被爱着，你足够了，你会好起来的。",
      ],
      'fr': [
        "Respirez avec moi : inspirez pendant 4… retenez pendant 7… expirez pendant 8. Vous êtes en sécurité ici.",
        "Vous faites mieux que vous ne le pensez. Nommez une petite victoire d'aujourd'hui.",
        "Permission accordée de vous reposer. Vous l'avez mérité, sans questions.",
        "Votre cerveau est une Ferrari — parfois il a juste besoin d'un arrêt au stand. Prenez 5 minutes.",
        "Parlons franchement : Vous n'êtes pas cassé. Vous fonctionnez juste sur un système d'exploitation différent.",
        "Micro défi : Buvez un verre d'eau complet maintenant. Votre cerveau vous remerciera.",
        "Vous savez quoi ? C'est normal de ne pas aller bien. Restez juste ici avec moi un moment.",
        "Rebondissement : Le fait que vous essayiez est déjà une victoire. Continuez.",
        "Voici votre permission de ne rien faire du tout pendant les 10 prochaines minutes.",
        "Rappel doux : Vous êtes aimé, vous êtes suffisant et vous allez bien aller.",
      ],
      'de': [
        "Atme mit mir: einatmen für 4… halten für 7… ausatmen für 8. Du bist hier sicher.",
        "Du machst es besser als du denkst. Nenne einen kleinen Sieg von heute.",
        "Erlaubnis erteilt, sich auszuruhen. Du hast es verdient, keine Fragen.",
        "Dein Gehirn ist ein Ferrari — manchmal braucht es nur einen Boxenstopp. Nimm dir 5 Minuten.",
        "Klartext: Du bist nicht kaputt. Du läufst nur auf einem anderen Betriebssystem.",
        "Mikro-Herausforderung: Trink jetzt ein volles Glas Wasser. Dein Gehirn wird es dir danken.",
        "Weißt du was? Es ist okay, nicht okay zu sein. Bleib einfach einen Moment bei mir.",
        "Wendung: Die Tatsache, dass du es versuchst, ist bereits ein Sieg. Mach weiter.",
        "Hier ist deine Erlaubnis, die nächsten 10 Minuten absolut nichts zu tun.",
        "Sanfte Erinnerung: Du bist geliebt, du bist genug und es wird dir gut gehen.",
      ],
      'ar': [
        "تنفس معي: استنشق لمدة 4... احبس لمدة 7... ازفر لمدة 8. أنت آمن هنا.",
        "أنت تفعل أفضل مما تعتقد. اذكر انتصارًا صغيرًا من اليوم.",
        "تم منح الإذن بالراحة. لقد كسبته، بدون أسئلة.",
        "عقلك فيراري — أحيانًا يحتاج فقط إلى توقف في الحفرة. خذ 5 دقائق.",
        "حديث حقيقي: أنت لست مكسورًا. أنت فقط تعمل على نظام تشغيل مختلف.",
        "تحدي صغير: اشرب كوبًا كاملاً من الماء الآن. سيشكرك عقلك.",
        "أتعلم ماذا؟ لا بأس ألا تكون بخير. فقط ابق هنا معي للحظة.",
        "تطور في الحبكة: حقيقة أنك تحاول هي بالفعل انتصار. استمر.",
        "هذا إذنك لعدم فعل أي شيء على الإطلاق خلال الـ 10 دقائق القادمة.",
        "تذكير لطيف: أنت محبوب، أنت كافٍ، وستكون بخير.",
      ],
      'ja': [
        "一緒に呼吸しましょう：4秒吸って…7秒止めて…8秒吐いて。ここは安全です。",
        "あなたは思っているよりうまくやっています。今日の小さな勝利を一つ挙げてください。",
        "休む許可が与えられました。あなたはそれを獲得しました、質問なし。",
        "あなたの脳はフェラーリです — 時々ピットストップが必要なだけです。5分取ってください。",
        "本当の話：あなたは壊れていません。ただ別のオペレーティングシステムで動いているだけです。",
        "マイクロチャレンジ：今すぐコップ一杯の水を飲んでください。あなたの脳が感謝します。",
        "知ってる？大丈夫じゃなくても大丈夫です。ちょっとここで私と一緒にいてください。",
        "プロットツイスト：あなたが試みているという事実がすでに勝利です。続けてください。",
        "これは次の10分間何もしないあなたの許可証です。",
        "優しいリマインダー：あなたは愛されています、あなたは十分です、そしてあなたは大丈夫になります。",
      ],
    };

    return fallbacksMap[languageCode] ?? fallbacksMap['en']!;
  }
}

