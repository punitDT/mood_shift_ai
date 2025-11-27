import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

enum MoodStyle {
  chaosEnergy,
  gentleGrandma,
  permissionSlip,
  realityCheck,
  microDare,
}

class AIService extends GetxService {
  // TODO: Replace with your Hugging Face API token
  static const String _apiToken = 'YOUR_HUGGING_FACE_API_TOKEN';
  static const String _apiUrl = 'https://api-inference.huggingface.co/models/meta-llama/Meta-Llama-3-8B-Instruct';

  final Random _random = Random();

  Future<String> generateResponse(String userInput, String language) async {
    try {
      // Randomly select a mood style
      final style = MoodStyle.values[_random.nextInt(MoodStyle.values.length)];
      
      // Build the prompt with safety and style
      final prompt = _buildPrompt(userInput, style, language);
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {
            'max_new_tokens': 150,
            'temperature': 0.9,
            'top_p': 0.95,
            'do_sample': true,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          String generatedText = data[0]['generated_text'] ?? '';

          // Extract only the response part (after the prompt)
          if (generatedText.contains('RESPONSE:')) {
            generatedText = generatedText.split('RESPONSE:').last.trim();
          }

          return generatedText.trim();
        }
      }
      
      return _getFallbackResponse(style, language);
    } catch (e) {
      return _getFallbackResponse(MoodStyle.gentleGrandma, language);
    }
  }

  String _buildPrompt(String userInput, MoodStyle style, String language) {
    final stylePrompt = _getStylePrompt(style);
    
    return '''You are MoodShift AI, a compassionate ADHD companion. Your role is to respond to users with empathy, humor, and actionable micro-shifts.

SAFETY RULES (CRITICAL):
- NEVER judge or shame the user
- If user mentions self-harm, substance abuse, or harmful intent → gently redirect with breathing exercises, drinking water, holding ice, and remind them they're loved ❤️
- Always be kind, supportive, and non-judgmental
- Keep responses 10-30 seconds when spoken (50-100 words max)

STYLE FOR THIS RESPONSE: $stylePrompt

USER INPUT: "$userInput"

LANGUAGE: Respond in $language

RESPONSE:''';
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

  String _getFallbackResponse(MoodStyle style, String language) {
    // Fallback responses in case API fails
    final fallbacks = {
      MoodStyle.chaosEnergy: {
        'en': 'Hey! Drop everything and do 10 jumping jacks RIGHT NOW! Let\'s shake that energy loose! GO GO GO! 🔥',
        'hi': 'अरे! सब कुछ छोड़ो और अभी 10 जंपिंग जैक करो! उस ऊर्जा को हिलाओ! चलो चलो चलो! 🔥',
        'es': '¡Oye! ¡Deja todo y haz 10 saltos de tijera AHORA MISMO! ¡Vamos a sacudir esa energía! ¡VAMOS VAMOS VAMOS! 🔥',
      },
      MoodStyle.gentleGrandma: {
        'en': 'Sweet one, let\'s breathe together. In for 4... hold for 4... out for 4. You\'re doing beautifully. Everything will be okay. ❤️',
        'hi': 'प्यारे, चलो साथ में सांस लेते हैं। 4 के लिए अंदर... 4 के लिए रोकें... 4 के लिए बाहर। आप बहुत अच्छा कर रहे हैं। सब ठीक हो जाएगा। ❤️',
        'es': 'Querido, respiremos juntos. Inhala por 4... mantén por 4... exhala por 4. Lo estás haciendo hermoso. Todo estará bien. ❤️',
      },
      MoodStyle.permissionSlip: {
        'en': 'You are hereby officially granted permission to take a 5-minute break and do absolutely nothing. Signed, The Universe. ✨',
        'hi': 'आपको आधिकारिक रूप से 5 मिनट का ब्रेक लेने और बिल्कुल कुछ न करने की अनुमति दी जाती है। हस्ताक्षरित, ब्रह्मांड। ✨',
        'es': 'Por la presente se te concede oficialmente permiso para tomar un descanso de 5 minutos y no hacer absolutamente nada. Firmado, El Universo. ✨',
      },
      MoodStyle.realityCheck: {
        'en': 'Real talk: You\'re feeling stuck, but you\'re not actually stuck. Pick ONE tiny thing and do it. That\'s all. You got this. 💪',
        'hi': 'सच्ची बात: आप फंसा हुआ महसूस कर रहे हैं, लेकिन आप वास्तव में फंसे नहीं हैं। एक छोटी सी चीज़ चुनें और करें। बस इतना ही। आप कर सकते हैं। 💪',
        'es': 'Hablemos claro: Te sientes atascado, pero no estás realmente atascado. Elige UNA cosa pequeña y hazla. Eso es todo. Tú puedes. 💪',
      },
      MoodStyle.microDare: {
        'en': 'Micro dare: In the next 60 seconds, drink a full glass of water. That\'s it. Timer starts NOW! ⏱️',
        'hi': 'माइक्रो डेयर: अगले 60 सेकंड में, एक पूरा गिलास पानी पिएं। बस इतना ही। टाइमर अभी शुरू होता है! ⏱️',
        'es': 'Micro desafío: En los próximos 60 segundos, bebe un vaso lleno de agua. Eso es todo. ¡El temporizador comienza AHORA! ⏱️',
      },
    };

    final langCode = language.toLowerCase().split('_')[0];
    final styleResponses = fallbacks[style] ?? fallbacks[MoodStyle.gentleGrandma]!;
    
    return styleResponses[langCode] ?? styleResponses['en']!;
  }

  MoodStyle getRandomStyle() {
    return MoodStyle.values[_random.nextInt(MoodStyle.values.length)];
  }
}

