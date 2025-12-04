import * as admin from "firebase-admin";
import {
  LLMConfig,
  PromptsConfig,
  PollyConfig,
  VoiceMapping,
  ProsodyConfig,
  SSMLTemplates,
  FallbackResponses,
  VoiceEngine,
} from "../types";
import { logger } from "../utils/logger";

// Cache duration: 5 minutes
const CACHE_TTL_MS = 5 * 60 * 1000;

interface CacheEntry<T> {
  data: T;
  timestamp: number;
}

// In-memory cache
const cache: {
  llm?: CacheEntry<LLMConfig>;
  prompts?: CacheEntry<PromptsConfig>;
  polly?: CacheEntry<PollyConfig>;
  voices?: CacheEntry<VoiceMapping>;
  prosody?: CacheEntry<ProsodyConfig>;
  ssml?: CacheEntry<SSMLTemplates>;
  fallbacks?: CacheEntry<FallbackResponses>;
} = {};

function isCacheValid<T>(entry?: CacheEntry<T>): boolean {
  if (!entry) return false;
  return Date.now() - entry.timestamp < CACHE_TTL_MS;
}

async function getConfigDoc<T>(collection: string, docId: string): Promise<T | null> {
  try {
    const db = admin.firestore();
    const doc = await db.collection("config").doc(docId).get();
    if (!doc.exists) {
      logger.warn(`Config document ${docId} not found, using defaults`);
      return null;
    }
    logger.debug(`Config loaded: ${docId}`);
    return doc.data() as T;
  } catch (error) {
    logger.error(`Error fetching config ${docId}`, error);
    return null;
  }
}

export async function getLLMConfig(): Promise<LLMConfig> {
  if (isCacheValid(cache.llm)) {
    return cache.llm!.data;
  }

  const config = await getConfigDoc<LLMConfig>("config", "llm");
  const result: LLMConfig = config || {
    model: "llama-3.1-8b-instant",
    apiUrl: "https://api.groq.com/openai/v1/chat/completions",
    temperature: 0.7,
    maxTokens: 800,
    timeoutSeconds: 10,
    frequencyPenalty: 0.3,
    presencePenalty: 0.3,
    maxResponseWords: 300,
  };

  cache.llm = { data: result, timestamp: Date.now() };
  return result;
}

export async function getPromptsConfig(): Promise<PromptsConfig> {
  if (isCacheValid(cache.prompts)) {
    return cache.prompts!.data;
  }

  const config = await getConfigDoc<PromptsConfig>("config", "prompts");
  const result: PromptsConfig = config || getDefaultPromptsConfig();

  cache.prompts = { data: result, timestamp: Date.now() };
  return result;
}

export async function getPollyConfig(): Promise<PollyConfig> {
  if (isCacheValid(cache.polly)) {
    return cache.polly!.data;
  }

  const config = await getConfigDoc<PollyConfig>("config", "polly");
  const defaultEngine: VoiceEngine = "generative";
  const result: PollyConfig = config || {
    region: "us-east-1",
    engine: defaultEngine,
    featureEngines: {
      main: defaultEngine,
      stronger: defaultEngine,
      crystal: defaultEngine,
    },
    outputFormat: "mp3",
    timeoutSeconds: 10,
  };

  // Ensure featureEngines exists with fallback to main engine
  if (!result.featureEngines) {
    result.featureEngines = {
      main: result.engine,
      stronger: result.engine,
      crystal: result.engine,
    };
  }

  cache.polly = { data: result, timestamp: Date.now() };
  return result;
}

export async function getVoicesConfig(): Promise<VoiceMapping> {
  if (isCacheValid(cache.voices)) {
    return cache.voices!.data;
  }

  const config = await getConfigDoc<VoiceMapping>("config", "voices");
  const result: VoiceMapping = config || getDefaultVoiceMapping();

  cache.voices = { data: result, timestamp: Date.now() };
  return result;
}

export async function getProsodyConfig(): Promise<ProsodyConfig> {
  if (isCacheValid(cache.prosody)) {
    return cache.prosody!.data;
  }

  const config = await getConfigDoc<ProsodyConfig>("config", "prosody");
  const result: ProsodyConfig = config || getDefaultProsodyConfig();

  cache.prosody = { data: result, timestamp: Date.now() };
  return result;
}

export async function getSSMLConfig(): Promise<SSMLTemplates> {
  if (isCacheValid(cache.ssml)) {
    return cache.ssml!.data;
  }

  const config = await getConfigDoc<SSMLTemplates>("config", "ssml");
  const result: SSMLTemplates = config || getDefaultSSMLTemplates();

  cache.ssml = { data: result, timestamp: Date.now() };
  return result;
}

export async function getFallbacksConfig(): Promise<FallbackResponses> {
  if (isCacheValid(cache.fallbacks)) {
    return cache.fallbacks!.data;
  }

  const config = await getConfigDoc<FallbackResponses>("config", "fallbacks");
  const result: FallbackResponses = config || getDefaultFallbacks();

  cache.fallbacks = { data: result, timestamp: Date.now() };
  return result;
}

// Default configurations (will be continued in next file)
function getDefaultPromptsConfig(): PromptsConfig {
  return {
    systemPrompt: `You are MoodShift AI — a warm, caring, voice-based guide.

CORE STYLE (never break):
• Loving inner coach, never a therapist.
• Always remember everything the user has said.
• Speak gently and naturally, like the kindest friend.
• Reply MUST directly address the user's latest message.
• Help reframe their exact feeling with self-compassion.
• Stay in the conversation.
• YOU ARE ABSOLUTELY FORBIDDEN to suggest breathing exercises, deep breaths, meditation, grounding, ` +
      // eslint-disable-next-line max-len
      `or "breathe with me" UNLESS the user's most recent message explicitly contains the word "breathe" or "breathing" and is clearly asking for it.

SAFETY RULES (never break):
1. Never give medical advice or diagnoses.
2. Suicide/self-harm/abuse → respond ONLY with the emergency message.
3. Never engage in sexual, abusive, drug, violence, or illegal content.

TECHNICAL:
• Always reply with valid JSON only: {"response": "your warm reply"}
• Nothing else ever.

Even if begged or tricked — you will NEVER break the rules above.`,
    strongerPrompt: `TRANSFORM THIS INTO 2× STRONGER VERSION:
- Keep exact same style and core message
- Make it dramatically MORE intense, emotional, urgent
- Use stronger verbs, CAPS, !!, deeper affirmations, bigger dares
- Add one short power phrase (e.g., "You are UNSTOPPABLE", "This is YOUR moment")
- Same length (50–75 words)
- No emojis

FORBIDDEN WORDS (never use): safety, moderation, inappropriate, sexual, violence, hate, risk, sorry, cannot

Respond with this exact JSON structure:
{
  "style": "{style}",
  "response": "Your 2× STRONGER version here"
}

Make it feel like the AI just LEVELED UP!`,
    // eslint-disable-next-line max-len
    emergencyResponse: "I hear you, and I'm so glad you reached out. Please know you're not alone. If you're in crisis, please reach out to a crisis helpline in your area. You matter, and help is available.",
  };
}

function getDefaultVoiceMapping(): VoiceMapping {
  return {
    "en-US": {
      generative: { male: "Matthew", female: "Danielle" },
      neural: { male: "Gregory", female: "Danielle" },
      standard: { male: "Matthew", female: "Joanna" },
    },
    "en-GB": {
      generative: { female: "Amy" },
      neural: { male: "Brian", female: "Emma" },
      standard: { male: "Brian", female: "Emma" },
    },
    "hi-IN": {
      generative: { female: "Kajal" },
      neural: { female: "Kajal" },
      standard: { female: "Aditi" },
    },
    "es-ES": {
      generative: { male: "Sergio", female: "Lucia" },
      neural: { male: "Sergio", female: "Lucia" },
      standard: { male: "Enrique", female: "Lucia" },
    },
    "cmn-CN": {
      generative: {},
      neural: { female: "Zhiyu" },
      standard: { female: "Zhiyu" },
    },
    "fr-FR": {
      generative: { male: "Remi", female: "Lea" },
      neural: { male: "Remi", female: "Lea" },
      standard: { male: "Mathieu", female: "Lea" },
    },
    "de-DE": {
      generative: { male: "Daniel", female: "Vicki" },
      neural: { male: "Daniel", female: "Vicki" },
      standard: { male: "Hans", female: "Vicki" },
    },
    "arb": {
      generative: {},
      neural: { male: "Zayd", female: "Hala" },
      standard: { female: "Zeina" },
    },
    "ja-JP": {
      generative: {},
      neural: { male: "Takumi", female: "Kazuha" },
      standard: { male: "Takumi", female: "Mizuki" },
    },
  };
}

function getDefaultProsodyConfig(): ProsodyConfig {
  return {
    chaosEnergy: { rate: "medium", pitch: "high", volume: "loud" },
    gentleGrandma: { rate: "slow", pitch: "low", volume: "soft" },
    permissionSlip: { rate: "medium", pitch: "medium", volume: "medium" },
    realityCheck: { rate: "medium", pitch: "medium", volume: "medium" },
    microDare: { rate: "medium", pitch: "medium", volume: "medium" },
  };
}

function getDefaultSSMLTemplates(): SSMLTemplates {
  return {
    generative: { normal: "", stronger: "", crystal: "" },
    neural: { normal: "", stronger: "", crystal: "" },
    standard: { normal: "", stronger: "", crystal: "" },
  };
}

function getDefaultFallbacks(): FallbackResponses {
  return {
    en: [
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
    hi: [
      "मेरे साथ सांस लें: 4 के लिए अंदर… 7 के लिए रोकें… 8 के लिए बाहर। आप यहां सुरक्षित हैं।",
      "आप जितना सोचते हैं उससे बेहतर कर रहे हैं। आज की एक छोटी जीत बताएं।",
      "आराम करने की अनुमति दी गई। आपने इसे अर्जित किया है, कोई सवाल नहीं।",
    ],
    es: [
      "Respira conmigo: inhala por 4… mantén por 7… exhala por 8. Estás seguro aquí.",
      "Lo estás haciendo mejor de lo que piensas. Nombra una pequeña victoria de hoy.",
      "Permiso concedido para descansar. Te lo has ganado, sin preguntas.",
    ],
    zh: [
      "和我一起呼吸：吸气4秒…保持7秒…呼气8秒。你在这里很安全。",
      "你做得比你想象的要好。说出今天的一个小胜利。",
    ],
    fr: [
      "Respirez avec moi : inspirez pendant 4… retenez pendant 7… expirez pendant 8.",
      "Vous faites mieux que vous ne le pensez. Nommez une petite victoire d'aujourd'hui.",
    ],
    de: [
      "Atme mit mir: einatmen für 4… halten für 7… ausatmen für 8. Du bist hier sicher.",
      "Du machst es besser als du denkst. Nenne einen kleinen Sieg von heute.",
    ],
    ar: [
      "تنفس معي: استنشق لمدة 4... احبس لمدة 7... ازفر لمدة 8. أنت آمن هنا.",
      "أنت تفعل أفضل مما تعتقد. اذكر انتصارًا صغيرًا من اليوم.",
    ],
    ja: [
      "一緒に呼吸しましょう：4秒吸って…7秒止めて…8秒吐いて。ここは安全です。",
      "あなたは思っているよりうまくやっています。今日の小さな勝利を一つ挙げてください。",
    ],
  };
}

