import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_service.dart'; // For MoodStyle enum
import 'storage_service.dart';

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

  @override
  void onInit() {
    super.onInit();
    _apiKey = dotenv.env['GROK_API_KEY'] ?? '';
    _model = dotenv.env['GROK_MODEL_NAME'] ?? 'llama-3.2-3b-preview';
    _groqApiUrl = dotenv.env['GROK_API_URL'] ?? 'https://api.groq.com/openai/v1/chat/completions';
    _temperature = double.tryParse(dotenv.env['GROK_TEMPERATURE'] ?? '0.9') ?? 0.9;
    _maxTokens = int.tryParse(dotenv.env['GROK_MAX_TOKENS'] ?? '300') ?? 300;
    _timeoutSeconds = int.tryParse(dotenv.env['GROK_TIMEOUT_SECONDS'] ?? '10') ?? 10;
    _frequencyPenalty = double.tryParse(dotenv.env['GROK_FREQUENCY_PENALTY'] ?? '0.5') ?? 0.5;
    _presencePenalty = double.tryParse(dotenv.env['GROK_PRESENCE_PENALTY'] ?? '0.5') ?? 0.5;
    _maxResponseWords = int.tryParse(dotenv.env['GROK_MAX_RESPONSE_WORDS'] ?? '100') ?? 100;
    _storage = Get.find<StorageService>();

    if (_apiKey.isEmpty) {
      print('⚠️ [GROQ] Warning: GROK_API_KEY not found in .env');
    }

    print('🤖 [GROQ] Using model: $_model');
    print('🔧 [GROQ] API URL: $_groqApiUrl');
    print('🔧 [GROQ] Temperature: $_temperature, Max Tokens: $_maxTokens, Timeout: ${_timeoutSeconds}s');
  }

  Future<String> generateResponse(String userInput, String language) async {
    // Check cache first for offline support
    final cached = _storage.findCachedResponse(userInput, language);
    if (cached != null) {
      print('💾 [GROQ] Using cached response');
      return cached['response'] as String;
    }

    try {
      // Randomly select a mood style
      final style = MoodStyle.values[_random.nextInt(MoodStyle.values.length)];

      // Build the prompt with safety and style
      final prompt = _buildPrompt(userInput, style, language);

      print('🤖 [GROQ] Calling Groq API with model: $_model');

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
              'content': 'You are MoodShift AI, a compassionate ADHD companion. Keep responses 15-20 seconds when spoken (50-80 words max). Be warm, supportive, and actionable.',
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
        }),
      ).timeout(
        Duration(seconds: _timeoutSeconds),
        onTimeout: () {
          print('⏱️ [GROQ] API timeout after $_timeoutSeconds seconds');
          throw Exception('Groq API timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          String generatedText = data['choices'][0]['message']['content'] ?? '';

          // Clean up and limit length
          generatedText = _cleanResponse(generatedText);

          // Cache the response
          _storage.addCachedResponse(userInput, generatedText, language);

          print('✅ [GROQ] Response generated successfully (${generatedText.length} chars)');
          return generatedText;
        }
      } else {
        print('❌ [GROQ] API error: ${response.statusCode} - ${response.body}');
      }

      // Fallback response
      print('🔄 [GROQ] Using fallback response');
      final fallback = _getUniversalFallback();
      _storage.addCachedResponse(userInput, fallback, language);
      return fallback;
    } catch (e) {
      print('❌ [GROQ] Error: $e');
      final fallback = _getUniversalFallback();
      _storage.addCachedResponse(userInput, fallback, language);
      return fallback;
    }
  }

  String _buildPrompt(String userInput, MoodStyle style, String language) {
    final stylePrompt = _getStylePrompt(style);
    
    return '''You are MoodShift AI, a compassionate ADHD companion. Your role is to respond to users with empathy, humor, and actionable micro-shifts.

SAFETY RULES (CRITICAL):
- NEVER judge or shame the user
- If user mentions self-harm, substance abuse, or harmful intent → gently redirect with breathing exercises, drinking water, holding ice, and remind them they're loved ❤️
- Always be kind, supportive, and non-judgmental
- Keep responses 15-20 seconds when spoken (50-80 words max)

STYLE FOR THIS RESPONSE: $stylePrompt

USER INPUT: "$userInput"

LANGUAGE: Respond in $language

Respond directly without any preamble or meta-commentary:''';
  }

  String _getStylePrompt(MoodStyle style) {
    switch (style) {
      case MoodStyle.chaosEnergy:
        return 'CHAOS ENERGY - Give a hyper, energetic dare or challenge. Be wild, fun, and push them to do something unexpected RIGHT NOW. Use excitement and urgency!';
      
      case MoodStyle.gentleGrandma:
        return 'GENTLE GRANDMA - Speak softly and lovingly. Guide them through a calming breathing exercise or gentle movement. Be warm, nurturing, and soothing.';
      
      case MoodStyle.permissionSlip:
        return 'PERMISSION SLIP - Give them official permission to do (or not do) something. Be formal yet playful. "You are hereby granted permission to..."';
      
      case MoodStyle.realityCheck:
        return 'REALITY CHECK - Give them a kind, honest truth. Be direct but loving. Help them see things clearly without judgment.';
      
      case MoodStyle.microDare:
        return 'MICRO DARE - Give them one tiny, specific action to do in the next 60 seconds. Make it simple, achievable, and slightly fun.';
    }
  }

  String _cleanResponse(String response) {
    // Remove any remaining prompt artifacts
    response = response.trim();
    
    // Remove common AI preambles
    final preambles = [
      'Here\'s a response:',
      'Here is a response:',
      'Response:',
      'RESPONSE:',
      'As MoodShift AI,',
      'As an AI,',
    ];
    
    for (final preamble in preambles) {
      if (response.toLowerCase().startsWith(preamble.toLowerCase())) {
        response = response.substring(preamble.length).trim();
      }
    }
    
    // Limit to reasonable length (configurable max words)
    final words = response.split(' ');
    if (words.length > _maxResponseWords) {
      response = words.take(_maxResponseWords).join(' ') + '...';
    }
    
    return response;
  }

  String _getUniversalFallback() {
    // 10 universal fallback responses (warm, varied, 15-20 sec spoken)
    final fallbacks = [
      "Breathe with me: in for 4… hold for 7… out for 8. You're safe here ❤️",
      "You're doing better than you think. Name one tiny win from today ❤️",
      "Permission granted to rest. You've earned it, no questions asked ❤️",
      "Your brain is a Ferrari — sometimes it just needs a pit stop. Take 5 minutes ❤️",
      "Real talk: You're not broken. You're just running on a different operating system ❤️",
      "Micro dare: Drink a full glass of water right now. Your brain will thank you ❤️",
      "You know what? It's okay to not be okay. Just be here with me for a moment ❤️",
      "Plot twist: The fact that you're trying is already a win. Keep going ❤️",
      "Here's your permission slip to do absolutely nothing for the next 10 minutes ❤️",
      "Gentle reminder: You're loved, you're enough, and you're going to be okay ❤️",
    ];
    
    final selected = fallbacks[_random.nextInt(fallbacks.length)];
    print('💝 [GROQ] Using universal fallback: ${selected.substring(0, 30)}...');
    return selected;
  }

  MoodStyle getRandomStyle() {
    return MoodStyle.values[_random.nextInt(MoodStyle.values.length)];
  }
}

