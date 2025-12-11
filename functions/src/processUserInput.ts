import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {
  ProcessUserInputRequest,
  ProcessUserInputResponse,
  MoodStyle,
  VoiceEngine,
  PollyConfig,
  TokenUsage,
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
import { logger } from "./utils/logger";

// Helper to get the appropriate engine for a feature
function getFeatureEngine(
  pollyConfig: PollyConfig,
  strongerMode: boolean,
  crystalVoice: boolean
): VoiceEngine {
  const featureEngines = pollyConfig.featureEngines;

  if (strongerMode) {
    return featureEngines?.stronger || pollyConfig.engine;
  } else if (crystalVoice) {
    return featureEngines?.crystal || pollyConfig.engine;
  } else {
    return featureEngines?.main || pollyConfig.engine;
  }
}

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

// Determine if this is the production project based on project ID
// Production project: mood-shift-ai
// Dev project: mood-shift-ai-dev
const PROJECT_ID = process.env.GCLOUD_PROJECT || "";
const IS_PRODUCTION = PROJECT_ID === "mood-shift-ai";

// Enforce App Check only in production
const ENFORCE_APP_CHECK = IS_PRODUCTION;

logger.info("Cloud Function initialized", {
  project: PROJECT_ID,
  isProduction: IS_PRODUCTION,
  appCheckEnforced: ENFORCE_APP_CHECK,
});

export const processUserInput = onRequest(
  {
    region: "us-central1",
    memory: "512MiB",
    timeoutSeconds: 60,
    secrets: [GROQ_API_KEY, AWS_ACCESS_KEY, AWS_SECRET_KEY],
    cors: true,
  },
  async (req, res) => {
    const startTime = Date.now();
    logger.flow("Request received", { method: req.method, ip: req.ip });

    // Only allow POST
    if (req.method !== "POST") {
      logger.warn("Invalid method", { method: req.method });
      res.status(405).json({ success: false, error: "Method not allowed" });
      return;
    }

    // Verify Firebase App Check token (only if enforcement is enabled)
    if (ENFORCE_APP_CHECK) {
      const appCheckToken = req.header("X-Firebase-AppCheck");
      if (!appCheckToken) {
        logger.warn("Missing App Check token");
        res.status(401).json({ success: false, error: "Unauthorized: Missing App Check token" });
        return;
      }

      try {
        await admin.appCheck().verifyToken(appCheckToken);
        logger.debug("App Check token verified successfully");
      } catch (error) {
        logger.warn("Invalid App Check token", { error });
        res.status(401).json({ success: false, error: "Unauthorized: Invalid App Check token" });
        return;
      }
    } else {
      logger.debug("App Check verification skipped (not enforced)");
    }

    try {
      const request = req.body as ProcessUserInputRequest;

      // Log incoming request (dev only)
      logger.vars("Incoming Request", {
        deviceId: request.deviceId,
        text: request.text ? `${request.text.substring(0, 50)}...` : "(empty)",
        language: request.language,
        locale: request.locale,
        voiceGender: request.voiceGender,
        crystalVoice: request.crystalVoice,
        strongerMode: request.strongerMode,
        hasOriginalResponse: !!request.originalResponse,
      });

      // Validate request
      // For stronger mode, text can be empty but originalResponse is required
      const isStrongerMode = request.strongerMode === true;
      if (!request.deviceId || (!isStrongerMode && !request.text) || (isStrongerMode && !request.originalResponse)) {
        logger.warn("Missing required fields", {
          hasDeviceId: !!request.deviceId,
          hasText: !!request.text,
          isStrongerMode,
          hasOriginalResponse: !!request.originalResponse,
        });
        res.status(400).json({ success: false, error: "Missing required fields" });
        return;
      }

      // Load all configs in parallel
      logger.flow("Loading configs");
      const configStartTime = Date.now();
      const [llmConfig, promptsConfig, pollyConfig, voicesConfig, prosodyConfig, fallbacksConfig] =
        await Promise.all([
          getLLMConfig(),
          getPromptsConfig(),
          getPollyConfig(),
          getVoicesConfig(),
          getProsodyConfig(),
          getFallbacksConfig(),
        ]);
      logger.debug("Configs loaded", {
        duration: `${Date.now() - configStartTime}ms`,
        llmModel: llmConfig.model,
        pollyEngine: pollyConfig.engine,
      });

      const languageName = getLanguageName(request.language);
      let responseText: string;
      let style: MoodStyle = MoodStyle.microDare;
      let tokenUsage: TokenUsage | undefined;

      // Get API keys from secrets
      const groqApiKey = GROQ_API_KEY.value();
      const awsAccessKey = AWS_ACCESS_KEY.value();
      const awsSecretKey = AWS_SECRET_KEY.value();
      logger.debug("Secrets loaded", { hasGroqKey: !!groqApiKey, hasAwsKeys: !!awsAccessKey && !!awsSecretKey });

      if (request.strongerMode && request.originalResponse) {
        // Generate 2× stronger response
        logger.flow("Generating 2x stronger response");
        try {
          const llmStartTime = Date.now();
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
          tokenUsage = result.tokenUsage;
          logger.info("Stronger response generated", {
            duration: `${Date.now() - llmStartTime}ms`,
            style,
            responseLength: responseText.length,
            tokenUsage,
          });
        } catch (error) {
          logger.error("Stronger response generation failed", error);
          responseText = amplifyResponseManually(request.originalResponse);
          logger.warn("Using manual amplification fallback");
        }
      } else {
        // Normal flow: get conversation history and generate response
        logger.flow("Normal response flow");
        const history = await getConversationHistory(request.deviceId);
        logger.debug("Conversation history", { historyLength: history.length });

        const messages = buildMessagesForGroq(
          history,
          request.text,
          promptsConfig.systemPrompt,
          languageName
        );
        logger.debug("Messages built for Groq", { messageCount: messages.length });

        try {
          const llmStartTime = Date.now();
          const result = await generateResponse(messages, llmConfig, groqApiKey);
          responseText = result.response;
          style = result.style;
          tokenUsage = result.tokenUsage;
          logger.info("LLM response generated", {
            duration: `${Date.now() - llmStartTime}ms`,
            style,
            responseLength: responseText.length,
            responsePreview: responseText.substring(0, 80) + "...",
            tokenUsage,
          });

          // Save to conversation history
          await addToConversationHistory(request.deviceId, request.text, responseText);
          logger.debug("Conversation history updated");
        } catch (error) {
          logger.error("LLM generation failed", error);
          // Use fallback response
          responseText = getRandomFallback(request.language, fallbacksConfig);
          logger.warn("Using fallback response", { language: request.language });
        }
      }

      // Determine the engine for this feature
      const featureEngine = getFeatureEngine(pollyConfig, request.strongerMode, request.crystalVoice);
      logger.debug("Feature engine selected", {
        feature: request.strongerMode ? "stronger" : request.crystalVoice ? "crystal" : "main",
        engine: featureEngine,
        configuredEngines: pollyConfig.featureEngines,
      });

      // Build SSML based on mode with feature-specific engine
      let ssmlText: string;
      if (request.strongerMode) {
        ssmlText = buildStrongerSSML(responseText, featureEngine);
        logger.debug("Built stronger SSML", { engine: featureEngine });
      } else if (request.crystalVoice) {
        ssmlText = buildCrystalSSML(responseText, featureEngine);
        logger.debug("Built crystal SSML", { engine: featureEngine });
      } else {
        ssmlText = buildSSML(responseText, featureEngine, style, prosodyConfig);
        logger.debug("Built standard SSML", { style, engine: featureEngine });
      }
      logger.debug("SSML preview", { ssml: ssmlText.substring(0, 150) + "..." });

      // Synthesize speech with feature-specific engine
      logger.flow("Synthesizing speech with Polly");
      let audioBase64: string;
      let voiceId: string;
      let engine: string;
      try {
        const pollyStartTime = Date.now();
        const pollyResult = await synthesizeSpeech(
          ssmlText,
          request.locale,
          request.voiceGender,
          featureEngine,
          pollyConfig,
          voicesConfig,
          awsAccessKey,
          awsSecretKey
        );

        voiceId = pollyResult.voiceId;
        engine = pollyResult.engine;
        // Convert audio buffer to base64 for direct response
        audioBase64 = pollyResult.audioBuffer.toString("base64");
        logger.info("Polly synthesis complete", {
          duration: `${Date.now() - pollyStartTime}ms`,
          voiceId,
          engine,
          audioSize: pollyResult.audioBuffer.length,
          base64Length: audioBase64.length,
        });
      } catch (error) {
        logger.error("Polly synthesis failed", error);
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
        audioBase64,
        voiceId,
        engine,
        tokenUsage,
      };

      logger.flow("Request completed successfully", {
        totalDuration: `${Date.now() - startTime}ms`,
        voiceId,
        engine,
        responseLength: responseText.length,
        tokenUsage,
      });
      res.status(200).json(response);
    } catch (error) {
      logger.error("processUserInput error", error);
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

