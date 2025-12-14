import { defineSecret } from "firebase-functions/params";
import { MoodStyle, GroqParsedResponse, LLMConfig, PromptsConfig, TokenUsage } from "../types";
import { logger } from "../utils/logger";

// Define the secret
export const GROQ_API_KEY = defineSecret("GROQ_API_KEY");

const LANGUAGE_NAMES: { [key: string]: string } = {
  en: "English",
  hi: "Hindi",
  es: "Spanish",
  zh: "Chinese",
  fr: "French",
  de: "German",
  ar: "Arabic",
  ja: "Japanese",
};

export function getLanguageName(languageCode: string): string {
  return LANGUAGE_NAMES[languageCode] || "English";
}

// Normalize text to remove problematic Unicode characters that can cause TTS issues
// This function is used both for LLM responses and for input text
function normalizeTextForTTS(text: string): string {
  // Use Unicode normalization to convert composed characters to their canonical form
  text = text.normalize("NFKC");

  // Remove zero-width characters
  text = text.replace(/[\u200B-\u200D\uFEFF]/g, "");

  // Remove other invisible Unicode characters
  // eslint-disable-next-line no-misleading-character-class
  text = text.replace(/[\u00AD\u034F\u061C\u115F\u1160\u17B4\u17B5\u180E]/g, "");
  text = text.replace(/[\u2000-\u200A]/g, " ");
  text = text.replace(/[\u2028\u2029]/g, " ");
  text = text.replace(/[\u202A-\u202E]/g, "");
  text = text.replace(/[\u2060-\u2064]/g, "");
  text = text.replace(/[\u206A-\u206F]/g, "");
  text = text.replace(/[\uFE00-\uFE0F]/g, "");

  // Replace common Unicode homoglyphs with ASCII equivalents
  const homoglyphMap: { [key: string]: string } = {
    "\u0131": "i", "\u0130": "I", "\u0456": "i", "\u0406": "I", "\u04CF": "i",
    "\u0435": "e", "\u0415": "E", "\u043E": "o", "\u041E": "O",
    "\u0440": "p", "\u0420": "P", "\u0441": "c", "\u0421": "C",
    "\u0430": "a", "\u0410": "A", "\u0445": "x", "\u0425": "X",
    "\u0443": "y", "\u0423": "Y", "\u0422": "T", "\u0442": "t",
    "\u041C": "M", "\u041D": "H", "\u041A": "K", "\u0412": "B",
    "\u2018": "'", "\u2019": "'", "\u201C": "\"", "\u201D": "\"",
    "\u2013": "-", "\u2014": "-", "\u2026": "...",
  };

  for (const [homoglyph, ascii] of Object.entries(homoglyphMap)) {
    text = text.split(homoglyph).join(ascii);
  }

  // Normalize multiple spaces to single space
  text = text.replace(/\s+/g, " ");

  return text.trim();
}

export async function generateResponse(
  messages: Array<{ role: string; content: string }>,
  config: LLMConfig,
  apiKey: string
): Promise<GroqParsedResponse> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), config.timeoutSeconds * 1000);

  logger.debug("Calling Groq API", { model: config.model, messageCount: messages.length });

  try {
    const response = await fetch(config.apiUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: config.model,
        messages,
        temperature: config.temperature,
        max_tokens: config.maxTokens,
        top_p: 1,
        frequency_penalty: config.frequencyPenalty,
        presence_penalty: config.presencePenalty,
        response_format: { type: "json_object" },
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      logger.error("Groq API error", { status: response.status, statusText: response.statusText });
      throw new Error(`Groq API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    logger.debug("Groq API response received", { hasChoices: !!data.choices, choiceCount: data.choices?.length });

    // Extract token usage from Groq API response
    const tokenUsage: TokenUsage = {
      inputTokens: data.usage?.prompt_tokens || 0,
      outputTokens: data.usage?.completion_tokens || 0,
      totalTokens: data.usage?.total_tokens || 0,
    };
    logger.debug("Token usage", tokenUsage);

    if (data.choices && data.choices.length > 0) {
      const content = data.choices[0].message?.content || "";
      logger.debug("Groq raw content", { contentLength: content.length, preview: content.substring(0, 100) });
      return parseGroqResponse(content, config.maxResponseWords, tokenUsage);
    }

    throw new Error("No response from Groq API");
  } catch (error) {
    clearTimeout(timeoutId);
    throw error;
  }
}

export async function generateStrongerResponse(
  originalResponse: string,
  originalStyle: MoodStyle,
  languageName: string,
  config: LLMConfig,
  promptsConfig: PromptsConfig,
  apiKey: string
): Promise<GroqParsedResponse> {
  // Normalize the original response to remove problematic characters before sending to LLM
  const normalizedOriginal = normalizeTextForTTS(originalResponse);
  logger.debug("generateStrongerResponse input normalization", {
    originalLength: originalResponse.length,
    normalizedLength: normalizedOriginal.length,
    changed: originalResponse !== normalizedOriginal,
  });

  const styleStr = getStyleString(originalStyle);

  // System prompt: strongerPrompt from config contains all transformation instructions
  const systemPrompt = promptsConfig.strongerPrompt
    .replace("{style}", styleStr)
    .replace("$languageName", languageName);

  // User message: just the data to transform
  const userMessage = `ORIGINAL RESPONSE: "${normalizedOriginal}"
ORIGINAL STYLE: ${styleStr}`;

  const messages = [
    { role: "system", content: systemPrompt },
    { role: "user", content: userMessage },
  ];

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), config.timeoutSeconds * 1000);

  try {
    const response = await fetch(config.apiUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: config.model,
        messages,
        temperature: 0.9,
        max_tokens: config.maxTokens,
        top_p: 1,
        frequency_penalty: 0.2,
        presence_penalty: 0.8,
        response_format: { type: "json_object" },
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`Groq API error: ${response.status}`);
    }

    const data = await response.json();

    // Extract token usage from Groq API response
    const tokenUsage: TokenUsage = {
      inputTokens: data.usage?.prompt_tokens || 0,
      outputTokens: data.usage?.completion_tokens || 0,
      totalTokens: data.usage?.total_tokens || 0,
    };
    logger.debug("Stronger token usage", tokenUsage);

    if (data.choices && data.choices.length > 0) {
      const content = data.choices[0].message?.content || "";
      return parseGroqResponse(content, config.maxResponseWords, tokenUsage);
    }

    throw new Error("No response from Groq API");
  } catch (error) {
    clearTimeout(timeoutId);
    throw error;
  }
}

function parseStyleFromResponse(styleStr: string | undefined): MoodStyle {
  if (!styleStr) return MoodStyle.microDare;

  // Check if the style is a valid MoodStyle enum value (exact match)
  if (Object.values(MoodStyle).includes(styleStr as MoodStyle)) {
    return styleStr as MoodStyle;
  }

  // Normalize the style string: remove underscores/hyphens/spaces and convert to lowercase
  // This handles: REALITY_CHECK, reality-check, Reality Check, reality_check, etc.
  const normalizedInput = styleStr.toLowerCase().replace(/[_\-\s]/g, "");

  // Map of normalized style names to MoodStyle enum values
  const styleMap: { [key: string]: MoodStyle } = {
    // chaosEnergy variations
    "chaosenergy": MoodStyle.chaosEnergy,
    "chaos": MoodStyle.chaosEnergy,

    // gentleGrandma variations
    "gentlegrandma": MoodStyle.gentleGrandma,
    "grandma": MoodStyle.gentleGrandma,
    "gentle": MoodStyle.gentleGrandma,

    // permissionSlip variations
    "permissionslip": MoodStyle.permissionSlip,
    "permission": MoodStyle.permissionSlip,

    // realityCheck variations
    "realitycheck": MoodStyle.realityCheck,
    "reality": MoodStyle.realityCheck,

    // microDare variations
    "microdare": MoodStyle.microDare,
    "dare": MoodStyle.microDare,
    "micro": MoodStyle.microDare,
  };

  if (styleMap[normalizedInput]) {
    return styleMap[normalizedInput];
  }

  // Try partial match as last resort
  for (const [key, value] of Object.entries(styleMap)) {
    if (normalizedInput.includes(key) || key.includes(normalizedInput)) {
      return value;
    }
  }

  logger.debug("Unknown style from LLM, defaulting to microDare", { receivedStyle: styleStr });
  return MoodStyle.microDare;
}

function parseGroqResponse(content: string, maxWords: number, tokenUsage: TokenUsage): GroqParsedResponse {
  try {
    const json = JSON.parse(content);
    let response = json.response || "";
    response = cleanResponse(response, maxWords);
    response = removeEmojis(response);
    response = normalizeTextForTTS(response);

    const style = parseStyleFromResponse(json.style);
    logger.debug("Parsed style from LLM response", { rawStyle: json.style, parsedStyle: style });

    return {
      style,
      response,
      tokenUsage,
    };
  } catch {
    // Try to extract JSON from the content
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      try {
        const json = JSON.parse(jsonMatch[0]);
        let response = json.response || "";
        response = cleanResponse(response, maxWords);
        response = removeEmojis(response);
        response = normalizeTextForTTS(response);
        const style = parseStyleFromResponse(json.style);
        return { style, response, tokenUsage };
      } catch {
        // Fall through to return raw content
      }
    }
    return { style: MoodStyle.microDare, response: normalizeTextForTTS(removeEmojis(content)), tokenUsage };
  }
}

function cleanResponse(response: string, maxWords: number): string {
  response = response.trim().replace(/\s+/g, " ");
  const words = response.split(" ");
  if (words.length > maxWords) {
    response = words.slice(0, maxWords).join(" ") + "...";
  }
  return response;
}

function removeEmojis(text: string): string {
  // eslint-disable-next-line max-len
  const emojiRegex = /[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA00}-\u{1FA6F}]|[\u{1FA70}-\u{1FAFF}]/gu;
  return text.replace(emojiRegex, "").trim();
}

function getStyleString(style: MoodStyle): string {
  const styleMap: { [key in MoodStyle]: string } = {
    [MoodStyle.chaosEnergy]: "CHAOS_ENERGY",
    [MoodStyle.gentleGrandma]: "GENTLE_GRANDMA",
    [MoodStyle.permissionSlip]: "PERMISSION_SLIP",
    [MoodStyle.realityCheck]: "REALITY_CHECK",
    [MoodStyle.microDare]: "MICRO_DARE",
  };
  return styleMap[style] || "MICRO_DARE";
}

