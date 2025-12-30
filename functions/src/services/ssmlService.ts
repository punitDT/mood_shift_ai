import { MoodStyle, ProsodyConfig, VoiceEngine } from "../types";
import { logger } from "../utils/logger";

// Escape XML special characters for SSML
// Note: We intentionally do NOT escape apostrophes (') as AWS Polly handles them
// natively and escaping to &apos; can cause pronunciation issues
export function escapeXml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
  // Removed: .replace(/'/g, "&apos;") - causes Polly pronunciation issues
}

// Normalize text to remove invisible/problematic characters that cause Polly to spell out words
function normalizeTextForPolly(text: string): string {
  // Log the raw input with character codes for debugging
  const charCodes = text.split("").slice(0, 50).map((c) => c.charCodeAt(0).toString(16));
  logger.debug("normalizeTextForPolly input", {
    textLength: text.length,
    preview: text.substring(0, 100),
    firstCharCodes: charCodes,
  });

  // Use Unicode normalization to convert composed characters to their canonical form
  // This handles many homoglyphs and combining characters
  text = text.normalize("NFKC");

  // Remove zero-width characters that can cause spelling issues
  text = text.replace(/[\u200B-\u200D\uFEFF]/g, "");

  // Remove other invisible Unicode characters (split to avoid ESLint combined character class warning)
  // eslint-disable-next-line no-misleading-character-class
  text = text.replace(/[\u00AD\u034F\u061C\u115F\u1160\u17B4\u17B5\u180E]/g, "");
  text = text.replace(/[\u2000-\u200A]/g, " "); // Replace various Unicode spaces with regular space
  text = text.replace(/[\u2028\u2029]/g, " "); // Line/paragraph separators to space
  text = text.replace(/[\u202A-\u202E]/g, ""); // Bidirectional text control
  text = text.replace(/[\u2060-\u2064]/g, ""); // Word joiner and invisible operators
  text = text.replace(/[\u206A-\u206F]/g, ""); // Deprecated formatting characters

  // Remove variation selectors that might affect pronunciation
  text = text.replace(/[\uFE00-\uFE0F]/g, "");

  // Replace common Unicode homoglyphs with ASCII equivalents
  // These are characters that look like regular letters but have different code points
  const homoglyphMap: { [key: string]: string } = {
    "\u0131": "i", // Latin small letter dotless i
    "\u0130": "I", // Latin capital letter I with dot above
    "\u0456": "i", // Cyrillic small letter byelorussian-ukrainian i
    "\u0406": "I", // Cyrillic capital letter byelorussian-ukrainian i
    "\u04CF": "i", // Cyrillic small letter palochka (looks like lowercase L or I)
    "\u0435": "e", // Cyrillic small letter ie
    "\u0415": "E", // Cyrillic capital letter ie
    "\u043E": "o", // Cyrillic small letter o
    "\u041E": "O", // Cyrillic capital letter o
    "\u0440": "p", // Cyrillic small letter er
    "\u0420": "P", // Cyrillic capital letter er
    "\u0441": "c", // Cyrillic small letter es
    "\u0421": "C", // Cyrillic capital letter es
    "\u0430": "a", // Cyrillic small letter a
    "\u0410": "A", // Cyrillic capital letter a
    "\u0445": "x", // Cyrillic small letter ha
    "\u0425": "X", // Cyrillic capital letter ha
    "\u0443": "y", // Cyrillic small letter u (looks like y)
    "\u0423": "Y", // Cyrillic capital letter u
    "\u0422": "T", // Cyrillic capital letter te
    "\u0442": "t", // Cyrillic small letter te (some fonts)
    "\u041C": "M", // Cyrillic capital letter em
    "\u041D": "H", // Cyrillic capital letter en
    "\u041A": "K", // Cyrillic capital letter ka
    "\u0412": "B", // Cyrillic capital letter ve
    "\u2018": "'", // Left single quotation mark
    "\u2019": "'", // Right single quotation mark
    "\u201C": "\"", // Left double quotation mark
    "\u201D": "\"", // Right double quotation mark
    "\u2013": "-", // En dash
    "\u2014": "-", // Em dash
    "\u2026": "...", // Horizontal ellipsis
  };

  for (const [homoglyph, ascii] of Object.entries(homoglyphMap)) {
    text = text.split(homoglyph).join(ascii);
  }

  // Normalize multiple spaces to single space
  text = text.replace(/\s+/g, " ");

  const resultCharCodes = text.split("").slice(0, 50).map((c) => c.charCodeAt(0).toString(16));
  logger.debug("normalizeTextForPolly output", {
    textLength: text.length,
    preview: text.substring(0, 100),
    firstCharCodes: resultCharCodes,
  });

  return text.trim();
}

// List of stop words to convert to lowercase
const STOP_WORDS = new Set([
  "a", "about", "above", "after", "again", "against", "all", "am", "an", "and",
  "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being",
  "below", "between", "both", "but", "by", "can", "cannot", "could", "couldn't",
  "did", "didn't", "do", "does", "doesn't", "doing", "don't", "down", "during",
  "each", "few", "for", "from", "further", "had", "hadn't", "has", "hasn't",
  "have", "haven't", "having", "he", "he'd", "he'll", "he's", "her", "here",
  "here's", "hers", "herself", "him", "himself", "his", "how", "how's", "i",
  "i'd", "i'll", "i'm", "i've", "if", "in", "into", "is", "isn't", "it", "it's",
  "its", "itself", "let's", "me", "more", "most", "mustn't", "my", "myself",
  "no", "nor", "not", "of", "off", "on", "once", "only", "or", "other", "ought",
  "our", "ours", "ourselves", "out", "over", "own", "same", "shan't", "she",
  "she'd", "she'll", "she's", "should", "shouldn't", "so", "some", "such", "than",
  "that", "that's", "the", "their", "theirs", "them", "themselves", "then",
  "there", "there's", "these", "they", "they'd", "they'll", "they're", "they've",
  "this", "those", "through", "to", "too", "under", "until", "up", "very", "was",
  "wasn't", "we", "we'd", "we'll", "we're", "we've", "were", "weren't", "what",
  "what's", "when", "when's", "where", "where's", "which", "while", "who", "who's",
  "whom", "why", "why's", "with", "won't", "would", "wouldn't", "you", "you'd",
  "you'll", "you're", "you've", "your", "yours", "yourself", "yourselves",
]);

// Convert stop words to lowercase to prevent Polly spelling them out
function convertStopWordsToLowercase(text: string): string {
  return text.replace(/\b([A-Z]+)\b/g, (match) => {
    const lower = match.toLowerCase();
    if (STOP_WORDS.has(lower)) {
      return lower; // Only lowercase if it's a stop word
    }
    return match; // Otherwise leave unchanged (e.g., AI, NASA, IT stays as is)
  });
}

// Clean text for speech
function cleanTextForSpeech(text: string): string {
  // First normalize to remove problematic Unicode characters
  text = normalizeTextForPolly(text);
  // Convert stop words to lowercase to prevent Polly spelling them out
  text = convertStopWordsToLowercase(text);
  // Clean up extra whitespace
  text = text.trim().replace(/\s+/g, " ");
  // Remove any prosody artifacts
  text = removeProsodyArtifacts(text);

  logger.debug("cleanTextForSpeech result", {
    textLength: text.length,
    preview: text.substring(0, 100),
  });

  return text;
}

function removeProsodyArtifacts(text: string): string {
  // Remove prosody patterns at the beginning
  const patterns = [
    /^[\s,;]*(?:pitch|rate|volume|voice|prosody)\s*[=:]\s*\S+/i,
    /^[\s,;]*(?:pitch|rate|volume|voice|prosody)\s+(?:equal|equals|is|to|at|set to|set at)\s+\S+/i,
    /^[\s,;]*(?:x-)?(?:high|low|medium|soft|loud|slow|fast|normal|default)\s+(?:pitch|rate|volume|voice)/i,
    /^[\s]*(?:(?:pitch|rate|volume)\s*[=:]\s*\S+[\s,;]*)+/i,
  ];

  let foundMatch = true;
  let iterations = 0;
  const maxIterations = 10;

  while (foundMatch && iterations < maxIterations) {
    foundMatch = false;
    iterations++;

    for (const pattern of patterns) {
      const match = text.match(pattern);
      if (match && match.index === 0) {
        text = text.substring(match[0].length).trim();
        foundMatch = true;
        break;
      }
    }
  }

  // Clean up leading punctuation
  text = text.replace(/^[\s,;:.]+/, "");
  return text.trim();
}

// Convert word values to x-values for generative engine
function convertToXValue(value: string, attribute: string): string {
  const rateMap: { [key: string]: string } = {
    "x-slow": "x-slow",
    "slow": "x-slow",
    "medium": "medium",
    "fast": "x-fast",
    "x-fast": "x-fast",
  };

  const volumeMap: { [key: string]: string } = {
    "silent": "silent",
    "x-soft": "x-soft",
    "soft": "x-soft",
    "medium": "medium",
    "loud": "x-loud",
    "x-loud": "x-loud",
  };

  if (attribute === "rate") {
    return rateMap[value] || "medium";
  } else if (attribute === "volume") {
    return volumeMap[value] || "medium";
  }
  return value;
}

// Convert word values to decibels for neural engine
function convertToDecibels(volumeWord: string): string {
  const volumeToDb: { [key: string]: string } = {
    "silent": "-20dB",
    "x-soft": "-10dB",
    "soft": "-6dB",
    "medium": "+0dB",
    "loud": "+6dB",
    "x-loud": "+10dB",
  };
  return volumeToDb[volumeWord] || "+0dB";
}

// Build SSML for normal response
export function buildSSML(
  text: string,
  engine: VoiceEngine,
  style: MoodStyle,
  prosodyConfig: ProsodyConfig
): string {
  logger.debug("buildSSML input", { textLength: text.length, engine, style });

  const cleanedText = cleanTextForSpeech(text);
  const escapedText = escapeXml(cleanedText);
  const settings = prosodyConfig[style] || { rate: "medium", pitch: "medium", volume: "medium" };

  let ssml: string;
  if (engine === "generative") {
    const rate = convertToXValue(settings.rate, "rate");
    const volume = convertToXValue(settings.volume, "volume");
    ssml = `<speak><prosody rate="${rate}" volume="${volume}">${escapedText}</prosody></speak>`;
  } else if (engine === "neural") {
    const volumeDb = convertToDecibels(settings.volume);
    ssml = `<speak><prosody volume="${volumeDb}">${escapedText}</prosody></speak>`;
  } else {
    // Standard engine - full SSML support
    const prosody = `rate="${settings.rate}" volume="${settings.volume}" pitch="${settings.pitch}"`;
    ssml = `<speak><prosody ${prosody}>${escapedText}</prosody></speak>`;
  }

  logger.debug("buildSSML output", { ssmlLength: ssml.length, ssmlPreview: ssml.substring(0, 200) });
  return ssml;
}

// Build SSML for 2× stronger response
export function buildStrongerSSML(text: string, engine: VoiceEngine): string {
  logger.debug("buildStrongerSSML input", { textLength: text.length, engine });

  const cleanedText = cleanTextForSpeech(text);
  const escapedText = escapeXml(cleanedText);

  let ssml: string;
  if (engine === "generative") {
    ssml = `<speak><prosody rate="medium" volume="x-loud">${escapedText}</prosody></speak>`;
  } else if (engine === "neural") {
    ssml = `<speak><prosody volume="+6dB">${escapedText}</prosody></speak>`;
  } else {
    ssml = "<speak><emphasis level=\"strong\">" +
      `<prosody rate="medium" volume="+6dB" pitch="+15%">${escapedText}</prosody></emphasis></speak>`;
  }

  logger.debug("buildStrongerSSML output", { ssmlLength: ssml.length, ssmlPreview: ssml.substring(0, 200) });
  return ssml;
}

// Build SSML for Crystal Voice
export function buildCrystalSSML(text: string, engine: VoiceEngine): string {
  logger.debug("buildCrystalSSML input", { textLength: text.length, engine });

  const cleanedText = cleanTextForSpeech(text);
  const escapedText = escapeXml(cleanedText);

  let ssml: string;
  if (engine === "generative") {
    ssml = `<speak><prosody rate="x-slow" volume="x-soft">${escapedText}</prosody></speak>`;
  } else if (engine === "neural") {
    ssml = `<speak><amazon:effect name="drc"><prosody volume="+0dB">${escapedText}</prosody></amazon:effect></speak>`;
  } else {
    // Standard engine with crystal voice effects
    ssml = "<speak><amazon:effect name=\"drc\"><amazon:effect phonation=\"soft\">" +
      "<amazon:effect vocal-tract-length=\"+12%\">" +
      `<prosody rate="slow" pitch="-10%" volume="soft">${escapedText}</prosody>` +
      "</amazon:effect></amazon:effect></amazon:effect></speak>";
  }

  logger.debug("buildCrystalSSML output", { ssmlLength: ssml.length, ssmlPreview: ssml.substring(0, 200) });
  return ssml;
}

