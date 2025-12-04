import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {
  ProcessUserInputRequest,
  ProcessUserInputResponse,
  MoodStyle,
} from "./types";
import {
  getLLMConfig,
  getPromptsConfig,
  getPollyConfig,
  getVoicesConfig,
  getProsodyConfig,
  getFallbacksConfig,
} from "./services/configService";
import {
  getConversationHistory,
  addToConversationHistory,
  buildMessagesForGroq,
} from "./services/conversationService";
import {
  generateResponse,
  generateStrongerResponse,
  getLanguageName,
  GROQ_API_KEY,
} from "./services/groqService";
import { buildSSML, buildStrongerSSML, buildCrystalSSML } from "./services/ssmlService";
import { synthesizeSpeech, AWS_ACCESS_KEY, AWS_SECRET_KEY } from "./services/pollyService";
import {
  generateInputHash,
  checkCache,
  saveToCache,
} from "./services/audioService";

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

export const processUserInput = onRequest(
  {
    region: "us-central1",
    memory: "512MiB",
    timeoutSeconds: 60,
    secrets: [GROQ_API_KEY, AWS_ACCESS_KEY, AWS_SECRET_KEY],
    cors: true,
  },
  async (req, res) => {
    // Only allow POST
    if (req.method !== "POST") {
      res.status(405).json({ success: false, error: "Method not allowed" });
      return;
    }

    try {
      const request = req.body as ProcessUserInputRequest;

      // Validate request
      // For stronger mode, text can be empty but originalResponse is required
      const isStrongerMode = request.strongerMode === true;
      if (!request.deviceId || (!isStrongerMode && !request.text) || (isStrongerMode && !request.originalResponse)) {
        res.status(400).json({ success: false, error: "Missing required fields" });
        return;
      }

      // Generate cache key based on user input
      const inputHash = generateInputHash(
        request.text || "",
        request.language,
        request.locale,
        request.voiceGender,
        request.crystalVoice,
        request.strongerMode,
        request.originalResponse
      );

      // Check cache first
      const cachedResponse = await checkCache(inputHash);
      if (cachedResponse) {
        // Cache hit - return cached response
        console.log("Cache hit for input hash:", inputHash);
        const response: ProcessUserInputResponse = {
          success: true,
          response: cachedResponse.response,
          audioUrl: cachedResponse.audioUrl,
          voiceId: cachedResponse.voiceId,
          engine: cachedResponse.engine,
        };
        res.status(200).json(response);
        return;
      }

      // Cache miss - generate new response
      console.log("Cache miss for input hash:", inputHash);

      // Load all configs in parallel
      const [llmConfig, promptsConfig, pollyConfig, voicesConfig, prosodyConfig, fallbacksConfig] =
        await Promise.all([
          getLLMConfig(),
          getPromptsConfig(),
          getPollyConfig(),
          getVoicesConfig(),
          getProsodyConfig(),
          getFallbacksConfig(),
        ]);

      const languageName = getLanguageName(request.language);
      let responseText: string;
      let style: MoodStyle = MoodStyle.microDare;

      // Get API keys from secrets
      const groqApiKey = GROQ_API_KEY.value();
      const awsAccessKey = AWS_ACCESS_KEY.value();
      const awsSecretKey = AWS_SECRET_KEY.value();

      if (request.strongerMode && request.originalResponse) {
        // Generate 2× stronger response
        try {
          const result = await generateStrongerResponse(
            request.originalResponse,
            style,
            languageName,
            llmConfig,
            promptsConfig,
            groqApiKey
          );
          responseText = result.response;
          style = result.style;
        } catch (error) {
          console.error("Stronger response generation failed:", error);
          responseText = amplifyResponseManually(request.originalResponse);
        }
      } else {
        // Normal flow: get conversation history and generate response
        const history = await getConversationHistory(request.deviceId);
        const messages = buildMessagesForGroq(
          history,
          request.text,
          promptsConfig.systemPrompt,
          languageName
        );

        try {
          const result = await generateResponse(messages, llmConfig, groqApiKey);
          responseText = result.response;
          style = result.style;

          // Save to conversation history
          await addToConversationHistory(request.deviceId, request.text, responseText);
        } catch (error) {
          console.error("LLM generation failed:", error);
          // Use fallback response
          responseText = getRandomFallback(request.language, fallbacksConfig);
        }
      }

      // Build SSML based on mode
      let ssmlText: string;
      if (request.strongerMode) {
        ssmlText = buildStrongerSSML(responseText, pollyConfig.engine);
      } else if (request.crystalVoice) {
        ssmlText = buildCrystalSSML(responseText, pollyConfig.engine);
      } else {
        ssmlText = buildSSML(responseText, pollyConfig.engine, style, prosodyConfig);
      }

      // Synthesize speech
      let audioUrl: string;
      let voiceId: string;
      let engine: string;
      try {
        const pollyResult = await synthesizeSpeech(
          ssmlText,
          request.locale,
          request.voiceGender,
          pollyConfig,
          voicesConfig,
          awsAccessKey,
          awsSecretKey
        );

        voiceId = pollyResult.voiceId;
        engine = pollyResult.engine;

        // Save to cache (audio with response in metadata)
        audioUrl = await saveToCache(
          inputHash,
          responseText,
          pollyResult.audioBuffer,
          voiceId,
          engine
        );
      } catch (error) {
        console.error("Polly synthesis failed:", error);
        res.status(500).json({
          success: false,
          error: "Audio synthesis failed",
          response: responseText,
        });
        return;
      }

      const response: ProcessUserInputResponse = {
        success: true,
        response: responseText,
        audioUrl,
        voiceId,
        engine,
      };

      res.status(200).json(response);
    } catch (error) {
      console.error("processUserInput error:", error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }
);

function amplifyResponseManually(original: string): string {
  let amplified = original.toUpperCase();
  amplified = amplified.replace(/\./g, "! ");
  amplified = amplified.replace(/!/g, "!! ");
  return amplified;
}

function getRandomFallback(language: string, fallbacks: { [key: string]: string[] }): string {
  const langFallbacks = fallbacks[language] || fallbacks["en"] || [];
  if (langFallbacks.length === 0) {
    return "You're doing better than you think. Take a moment to breathe.";
  }
  return langFallbacks[Math.floor(Math.random() * langFallbacks.length)];
}

