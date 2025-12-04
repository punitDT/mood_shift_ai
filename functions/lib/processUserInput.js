"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.processUserInput = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("./types");
const configService_1 = require("./services/configService");
const conversationService_1 = require("./services/conversationService");
const groqService_1 = require("./services/groqService");
const ssmlService_1 = require("./services/ssmlService");
const pollyService_1 = require("./services/pollyService");
const audioService_1 = require("./services/audioService");
// Initialize Firebase Admin
if (!admin.apps.length) {
    admin.initializeApp();
}
exports.processUserInput = (0, https_1.onRequest)({
    region: "us-central1",
    memory: "512MiB",
    timeoutSeconds: 60,
    secrets: [groqService_1.GROQ_API_KEY, pollyService_1.AWS_ACCESS_KEY, pollyService_1.AWS_SECRET_KEY],
    cors: true,
}, async (req, res) => {
    // Only allow POST
    if (req.method !== "POST") {
        res.status(405).json({ success: false, error: "Method not allowed" });
        return;
    }
    try {
        const request = req.body;
        // Validate request
        // For stronger mode, text can be empty but originalResponse is required
        const isStrongerMode = request.strongerMode === true;
        if (!request.deviceId || (!isStrongerMode && !request.text) || (isStrongerMode && !request.originalResponse)) {
            res.status(400).json({ success: false, error: "Missing required fields" });
            return;
        }
        // Generate cache key based on user input
        const inputHash = (0, audioService_1.generateInputHash)(request.text || "", request.language, request.locale, request.voiceGender, request.crystalVoice, request.strongerMode, request.originalResponse);
        // Check cache first
        const cachedResponse = await (0, audioService_1.checkCache)(inputHash);
        if (cachedResponse) {
            // Cache hit - return cached response
            console.log("Cache hit for input hash:", inputHash);
            const response = {
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
        const [llmConfig, promptsConfig, pollyConfig, voicesConfig, prosodyConfig, fallbacksConfig] = await Promise.all([
            (0, configService_1.getLLMConfig)(),
            (0, configService_1.getPromptsConfig)(),
            (0, configService_1.getPollyConfig)(),
            (0, configService_1.getVoicesConfig)(),
            (0, configService_1.getProsodyConfig)(),
            (0, configService_1.getFallbacksConfig)(),
        ]);
        const languageName = (0, groqService_1.getLanguageName)(request.language);
        let responseText;
        let style = types_1.MoodStyle.microDare;
        // Get API keys from secrets
        const groqApiKey = groqService_1.GROQ_API_KEY.value();
        const awsAccessKey = pollyService_1.AWS_ACCESS_KEY.value();
        const awsSecretKey = pollyService_1.AWS_SECRET_KEY.value();
        if (request.strongerMode && request.originalResponse) {
            // Generate 2× stronger response
            try {
                const result = await (0, groqService_1.generateStrongerResponse)(request.originalResponse, style, languageName, llmConfig, promptsConfig, groqApiKey);
                responseText = result.response;
                style = result.style;
            }
            catch (error) {
                console.error("Stronger response generation failed:", error);
                responseText = amplifyResponseManually(request.originalResponse);
            }
        }
        else {
            // Normal flow: get conversation history and generate response
            const history = await (0, conversationService_1.getConversationHistory)(request.deviceId);
            const messages = (0, conversationService_1.buildMessagesForGroq)(history, request.text, promptsConfig.systemPrompt, languageName);
            try {
                const result = await (0, groqService_1.generateResponse)(messages, llmConfig, groqApiKey);
                responseText = result.response;
                style = result.style;
                // Save to conversation history
                await (0, conversationService_1.addToConversationHistory)(request.deviceId, request.text, responseText);
            }
            catch (error) {
                console.error("LLM generation failed:", error);
                // Use fallback response
                responseText = getRandomFallback(request.language, fallbacksConfig);
            }
        }
        // Build SSML based on mode
        let ssmlText;
        if (request.strongerMode) {
            ssmlText = (0, ssmlService_1.buildStrongerSSML)(responseText, pollyConfig.engine);
        }
        else if (request.crystalVoice) {
            ssmlText = (0, ssmlService_1.buildCrystalSSML)(responseText, pollyConfig.engine);
        }
        else {
            ssmlText = (0, ssmlService_1.buildSSML)(responseText, pollyConfig.engine, style, prosodyConfig);
        }
        // Synthesize speech
        let audioUrl;
        let voiceId;
        let engine;
        try {
            const pollyResult = await (0, pollyService_1.synthesizeSpeech)(ssmlText, request.locale, request.voiceGender, pollyConfig, voicesConfig, awsAccessKey, awsSecretKey);
            voiceId = pollyResult.voiceId;
            engine = pollyResult.engine;
            // Save to cache (audio with response in metadata)
            audioUrl = await (0, audioService_1.saveToCache)(inputHash, responseText, pollyResult.audioBuffer, voiceId, engine);
        }
        catch (error) {
            console.error("Polly synthesis failed:", error);
            res.status(500).json({
                success: false,
                error: "Audio synthesis failed",
                response: responseText,
            });
            return;
        }
        const response = {
            success: true,
            response: responseText,
            audioUrl,
            voiceId,
            engine,
        };
        res.status(200).json(response);
    }
    catch (error) {
        console.error("processUserInput error:", error);
        res.status(500).json({
            success: false,
            error: error instanceof Error ? error.message : "Unknown error",
        });
    }
});
function amplifyResponseManually(original) {
    let amplified = original.toUpperCase();
    amplified = amplified.replace(/\./g, "! ");
    amplified = amplified.replace(/!/g, "!! ");
    return amplified;
}
function getRandomFallback(language, fallbacks) {
    const langFallbacks = fallbacks[language] || fallbacks["en"] || [];
    if (langFallbacks.length === 0) {
        return "You're doing better than you think. Take a moment to breathe.";
    }
    return langFallbacks[Math.floor(Math.random() * langFallbacks.length)];
}
//# sourceMappingURL=processUserInput.js.map