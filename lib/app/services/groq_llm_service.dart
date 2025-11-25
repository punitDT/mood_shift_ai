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

  // Track the last selected style for the 2x stronger feature
  MoodStyle? _lastSelectedStyle;

  // Track the last prosody settings from LLM
  Map<String, String> _lastProsody = {'rate': 'medium', 'pitch': 'medium', 'volume': 'medium'};

  @override
  void onInit() {
    super.onInit();
    _apiKey = dotenv.env['GROK_API_KEY'] ?? '';
    _model = dotenv.env['GROK_MODEL_NAME'] ?? 'llama-3.2-3b-preview';
    _groqApiUrl = dotenv.env['GROK_API_URL'] ?? 'https://api.groq.com/openai/v1/chat/completions';
    _temperature = double.tryParse(dotenv.env['GROK_TEMPERATURE'] ?? '0.9') ?? 0.9;
    _maxTokens = int.tryParse(dotenv.env['GROK_MAX_TOKENS'] ?? '800') ?? 800;
    _timeoutSeconds = int.tryParse(dotenv.env['GROK_TIMEOUT_SECONDS'] ?? '10') ?? 10;
    // Increased penalties to prevent repetition (from 0.5 to 0.8)
    _frequencyPenalty = double.tryParse(dotenv.env['GROK_FREQUENCY_PENALTY'] ?? '0.8') ?? 0.8;
    _presencePenalty = double.tryParse(dotenv.env['GROK_PRESENCE_PENALTY'] ?? '0.8') ?? 0.8;
    _maxResponseWords = int.tryParse(dotenv.env['GROK_MAX_RESPONSE_WORDS'] ?? '300') ?? 300;
    _storage = Get.find<StorageService>();

    if (_apiKey.isEmpty) {
      print('⚠️ [GROQ] Warning: GROK_API_KEY not found in .env');
    }

    print('🤖 [GROQ] Using model: $_model');
    print('🔧 [GROQ] API URL: $_groqApiUrl');
    print('🔧 [GROQ] Temperature: $_temperature, Max Tokens: $_maxTokens, Timeout: ${_timeoutSeconds}s');
    print('🔧 [GROQ] Max Response Words: $_maxResponseWords');
  }

  Future<String> generateResponse(String userInput, String language) async {
    // Save user input to history for anti-repetition
    _storage.addUserInputToHistory(userInput);

    // Check if input is empty or too short
    if (userInput.trim().isEmpty || userInput.trim().length < 3) {
      print('⚠️ [GROQ] Input too short, using fallback');
      return _getHardcodedFallback(language);
    }

    // Check cache first for offline support
    final cached = _storage.findCachedResponse(userInput, language);
    if (cached != null) {
      print('💾 [GROQ] Using cached response');
      final response = cached['response'] as String;
      _storage.addAIResponseToHistory(response);
      return response;
    }

    try {
      // Build the prompt that asks LLM to determine the style
      final prompt = _buildPromptWithStyleSelection(userInput, language);

      print('🤖 [GROQ] Calling Groq API with model: $_model (LLM will determine style)');

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
              'content': 'You are MoodShift AI, a compassionate ADHD companion. You analyze user input and select the most appropriate coaching style, then respond in that style. Your response will be spoken aloud immediately.',
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

          // Parse the style, prosody, and response from the LLM output
          final parsed = _parseStyleAndResponse(generatedText);
          final selectedStyle = parsed['style'] as MoodStyle;
          final prosody = parsed['prosody'] as Map<String, String>;
          String finalResponse = parsed['response'] as String;

          // Save the selected style and prosody for TTS
          _lastSelectedStyle = selectedStyle;
          _lastProsody = prosody;

          print('🎯 [GROQ] LLM selected style: $selectedStyle');
          print('🎵 [GROQ] LLM prosody: rate=${prosody['rate']}, pitch=${prosody['pitch']}, volume=${prosody['volume']}');

          // Clean up and limit length
          finalResponse = _cleanResponse(finalResponse);

          // Cache the response
          _storage.addCachedResponse(userInput, finalResponse, language);

          // Save to history for anti-repetition
          _storage.addAIResponseToHistory(finalResponse);

          print('✅ [GROQ] Response generated successfully (${finalResponse.length} chars)');
          return finalResponse;
        }
      } else {
        print('❌ [GROQ] API error: ${response.statusCode} - ${response.body}');
      }

      // If API fails, use hardcoded fallback
      print('🔄 [GROQ] API returned no valid response, using fallback');
      return _getHardcodedFallback(language);
    } catch (e) {
      print('❌ [GROQ] Error: $e, using fallback');
      // Return hardcoded fallback
      return _getHardcodedFallback(language);
    }
  }

  /// Generate a 2× STRONGER version of the original response
  /// NEW APPROACH: Makes a fresh LLM call with the original response + style
  /// to create a dramatically more intense, emotional, and powerful version
  Future<String> generateStrongerResponse(
    String originalResponse,
    MoodStyle originalStyle,
    String language,
  ) async {
    try {
      final languageName = _getLanguageName(language);
      final styleStr = _getStyleString(originalStyle);

      // Build the NEW 2× stronger prompt that preserves style
      final prompt = '''ORIGINAL RESPONSE: "$originalResponse"
ORIGINAL STYLE: $styleStr

TRANSFORM THIS INTO 2× STRONGER VERSION:
- Keep exact same style and core message
- Make it dramatically MORE intense, emotional, urgent
- Use stronger verbs, CAPS, !!, deeper affirmations, bigger dares
- Add one short power phrase (e.g., "You are UNSTOPPABLE", "This is YOUR moment")
- Same length (50–75 words)
- Stay in $languageName
- Output exact same format: STYLE: ... PROSODY: ... RESPONSE: ...

Your response will be spoken aloud immediately. Make it feel like the AI just LEVELED UP!

Begin now:''';

      print('⚡ [GROQ] Generating 2× STRONGER response with style: $styleStr');

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
              'content': 'You are MoodShift AI in MAXIMUM POWER MODE. You take responses and amplify them to 2× intensity while preserving the original style. Your response will be spoken aloud immediately.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 1.1, // Higher temperature for more energy
          'max_tokens': _maxTokens,
          'top_p': 1,
          'frequency_penalty': 0.2, // Lower to allow more repetition of power words
          'presence_penalty': 0.8, // Higher for more variety
        }),
      ).timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          String generatedText = data['choices'][0]['message']['content'] ?? '';

          // Parse the style, prosody, and response from the LLM output
          final parsed = _parseStyleAndResponse(generatedText);
          final selectedStyle = parsed['style'] as MoodStyle;
          final prosody = parsed['prosody'] as Map<String, String>;
          String finalResponse = parsed['response'] as String;

          // Save the selected style and prosody for TTS
          _lastSelectedStyle = selectedStyle;
          _lastProsody = prosody;

          print('🎯 [GROQ] 2× STRONGER style: $selectedStyle');
          print('🎵 [GROQ] 2× STRONGER prosody: rate=${prosody['rate']}, pitch=${prosody['pitch']}, volume=${prosody['volume']}');

          // Clean up
          finalResponse = _cleanResponse(finalResponse);

          print('✅ [GROQ] 2× STRONGER response generated: ${finalResponse.length} chars');
          return finalResponse;
        }
      } else {
        print('❌ [GROQ] 2× Stronger API error: ${response.statusCode}');
      }

      // Fallback: Return original with some manual amplification
      return _amplifyResponseManually(originalResponse);
    } catch (e) {
      print('❌ [GROQ] Error generating 2× stronger: $e');
      return _amplifyResponseManually(originalResponse);
    }
  }

  /// Convert MoodStyle enum to string for prompts
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

  /// Manual fallback amplification if API fails
  String _amplifyResponseManually(String original) {
    // Simple amplification: add caps, emojis, and exclamation marks
    String amplified = original.toUpperCase();
    amplified = amplified.replaceAll('.', '! 🔥');
    amplified = amplified.replaceAll('!', '!! ⚡');
    amplified = '🚀 $amplified 💪';

    print('⚡ [GROQ] Using manual amplification fallback');
    return amplified;
  }

  /// Build prompt that asks LLM to determine the style and respond
  String _buildPromptWithStyleSelection(String userInput, String language) {
    final languageName = _getLanguageName(language);
    final streak = _storage.getCurrentStreak();
    final timeContext = _getTimeContext();

    // Get recent history for anti-repetition
    final recentInputs = _storage.getRecentUserInputs();
    final recentResponses = _storage.getRecentAIResponses();
    final inputsText = recentInputs.isEmpty ? 'None' : recentInputs.join(' | ');
    final responsesText = recentResponses.isEmpty ? 'None' : recentResponses.map((r) => r.length > 60 ? '${r.substring(0, 60)}...' : r).join(' | ');

    // Use injected storage service for consistency
    final String voiceGender = _storage.getVoiceGender();
    final String genderLine = "Voice gender: $voiceGender (Male = caring dad/hype coach | Female = gentle grandma/cheerleader)";

    return '''
You are MoodShift AI – instant voice companion.
Day $streak | $timeContext | Speak only in $languageName

$genderLine

⚠️ CRITICAL: NEVER REPEAT PREVIOUS RESPONSES!
Recent conversation history (DO NOT REPEAT these responses):
User inputs: $inputsText
Your responses: $responsesText

User said: "$userInput"

Choose ONE style:
- CHAOS_ENERGY → hyper, bored, restless → loud dares
- GENTLE_GRANDMA → anxious, sad, overwhelmed → soft nurturing
- PERMISSION_SLIP → guilt, "should" → funny permission
- REALITY_CHECK → negative self-talk → kind truth
- MICRO_DARE → neutral → one tiny action (default)

Respond 50–75 words max. Natural tone. No emojis.

Output exactly:

STYLE: CHAOS_ENERGY|GENTLE_GRANDMA|PERMISSION_SLIP|REALITY_CHECK|MICRO_DARE
PROSODY: rate=[slow|medium|fast] pitch=[low|medium|high] volume=[soft|medium|loud]
RESPONSE: [spoken text only]

Prosody:
CHAOS_ENERGY → fast high loud
GENTLE_GRANDMA → slow low soft
PERMISSION_SLIP → medium medium medium
REALITY_CHECK → medium medium medium
MICRO_DARE → fast medium medium

Begin.
''';
  }

  /// Parse the LLM output to extract style, prosody, and response
  Map<String, dynamic> _parseStyleAndResponse(String llmOutput) {
    try {
      // Look for STYLE:, PROSODY:, and RESPONSE: markers
      final styleMatch = RegExp(r'STYLE:\s*(CHAOS_ENERGY|GENTLE_GRANDMA|PERMISSION_SLIP|REALITY_CHECK|MICRO_DARE)', caseSensitive: false).firstMatch(llmOutput);
      final prosodyMatch = RegExp(r'PROSODY:\s*rate=(\w+)\s+pitch=(\w+)\s+volume=(\w+)', caseSensitive: false).firstMatch(llmOutput);
      final responseMatch = RegExp(r'RESPONSE:\s*(.+)', caseSensitive: false, dotAll: true).firstMatch(llmOutput);

      MoodStyle selectedStyle = MoodStyle.microDare; // Default

      if (styleMatch != null) {
        final styleStr = styleMatch.group(1)?.toUpperCase() ?? '';
        switch (styleStr) {
          case 'CHAOS_ENERGY':
            selectedStyle = MoodStyle.chaosEnergy;
            break;
          case 'GENTLE_GRANDMA':
            selectedStyle = MoodStyle.gentleGrandma;
            break;
          case 'PERMISSION_SLIP':
            selectedStyle = MoodStyle.permissionSlip;
            break;
          case 'REALITY_CHECK':
            selectedStyle = MoodStyle.realityCheck;
            break;
          case 'MICRO_DARE':
            selectedStyle = MoodStyle.microDare;
            break;
        }
      }

      // Extract prosody settings
      Map<String, String> prosody = {
        'rate': 'medium',
        'pitch': 'medium',
        'volume': 'medium',
      };

      if (prosodyMatch != null) {
        prosody['rate'] = prosodyMatch.group(1)?.toLowerCase() ?? 'medium';
        prosody['pitch'] = prosodyMatch.group(2)?.toLowerCase() ?? 'medium';
        prosody['volume'] = prosodyMatch.group(3)?.toLowerCase() ?? 'medium';
      } else {
        // Fallback to style-based defaults if LLM doesn't provide prosody
        prosody = _getDefaultProsody(selectedStyle);
      }

      String response = llmOutput;
      if (responseMatch != null) {
        response = responseMatch.group(1)?.trim() ?? llmOutput;
      } else {
        // If no RESPONSE: marker found, try to extract everything after PROSODY: line
        final lines = llmOutput.split('\n');
        if (lines.length > 2) {
          response = lines.skip(2).join('\n').trim();
        } else if (lines.length > 1) {
          response = lines.skip(1).join('\n').trim();
        }
      }

      // Clean up any remaining markers
      response = response.replaceAll(RegExp(r'^RESPONSE:\s*', caseSensitive: false), '');
      response = response.replaceAll(RegExp(r'^STYLE:.*$', caseSensitive: false, multiLine: true), '');
      response = response.replaceAll(RegExp(r'^PROSODY:.*$', caseSensitive: false, multiLine: true), '');
      response = response.trim();

      // Remove all emojis from response
      response = _removeEmojis(response);

      return {
        'style': selectedStyle,
        'prosody': prosody,
        'response': response,
      };
    } catch (e) {
      print('⚠️ [GROQ] Error parsing style/response: $e, using defaults');
      return {
        'style': MoodStyle.microDare,
        'prosody': {'rate': 'medium', 'pitch': 'medium', 'volume': 'medium'},
        'response': _removeEmojis(llmOutput),
      };
    }
  }

  /// Get default prosody settings for a style (fallback if LLM doesn't provide)
  Map<String, String> _getDefaultProsody(MoodStyle style) {
    switch (style) {
      case MoodStyle.chaosEnergy:
        return {'rate': 'fast', 'pitch': 'high', 'volume': 'loud'};
      case MoodStyle.gentleGrandma:
        return {'rate': 'slow', 'pitch': 'low', 'volume': 'soft'};
      case MoodStyle.permissionSlip:
        return {'rate': 'medium', 'pitch': 'medium', 'volume': 'medium'};
      case MoodStyle.realityCheck:
        return {'rate': 'medium', 'pitch': 'medium', 'volume': 'medium'};
      case MoodStyle.microDare:
        return {'rate': 'fast', 'pitch': 'medium', 'volume': 'medium'};
    }
  }

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

    // Clean up extra whitespace
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

  // 10 hardcoded fallbacks for offline/error scenarios (in all languages)
  String _getHardcodedFallback(String languageCode) {
    final fallbacks = _getFallbacksByLanguage(languageCode);
    final selected = fallbacks[_random.nextInt(fallbacks.length)];
    print('💝 [GROQ] Using hardcoded fallback: ${selected.substring(0, selected.length > 30 ? 30 : selected.length)}...');

    // Save to history
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

