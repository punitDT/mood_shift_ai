import { MoodStyle, ProsodyConfig, VoiceEngine } from "../types";

// Escape XML special characters for SSML
export function escapeXml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

// Clean text for speech
function cleanTextForSpeech(text: string): string {
  // Clean up extra whitespace
  text = text.trim().replace(/\s+/g, " ");
  // Remove any prosody artifacts
  text = removeProsodyArtifacts(text);
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
  const cleanedText = cleanTextForSpeech(text);
  const escapedText = escapeXml(cleanedText);
  const settings = prosodyConfig[style] || { rate: "medium", pitch: "medium", volume: "medium" };

  if (engine === "generative") {
    const rate = convertToXValue(settings.rate, "rate");
    const volume = convertToXValue(settings.volume, "volume");
    return `<speak><prosody rate="${rate}" volume="${volume}">${escapedText}</prosody></speak>`;
  } else if (engine === "neural") {
    const volumeDb = convertToDecibels(settings.volume);
    return `<speak><prosody volume="${volumeDb}">${escapedText}</prosody></speak>`;
  } else {
    // Standard engine - full SSML support
    const prosody = `rate="${settings.rate}" volume="${settings.volume}" pitch="${settings.pitch}"`;
    return `<speak><prosody ${prosody}>${escapedText}</prosody></speak>`;
  }
}

// Build SSML for 2× stronger response
export function buildStrongerSSML(text: string, engine: VoiceEngine): string {
  const cleanedText = cleanTextForSpeech(text);
  const escapedText = escapeXml(cleanedText);

  if (engine === "generative") {
    return `<speak><prosody rate="medium" volume="x-loud">${escapedText}</prosody></speak>`;
  } else if (engine === "neural") {
    return `<speak><prosody volume="+6dB">${escapedText}</prosody></speak>`;
  } else {
    return "<speak><emphasis level=\"strong\">" +
      `<prosody rate="medium" volume="+6dB" pitch="+15%">${escapedText}</prosody></emphasis></speak>`;
  }
}

// Build SSML for Crystal Voice
export function buildCrystalSSML(text: string, engine: VoiceEngine): string {
  const cleanedText = cleanTextForSpeech(text);
  const escapedText = escapeXml(cleanedText);

  if (engine === "generative") {
    return `<speak><prosody rate="x-slow" volume="x-soft">${escapedText}</prosody></speak>`;
  } else if (engine === "neural") {
    return `<speak><amazon:effect name="drc"><prosody volume="+0dB">${escapedText}</prosody></amazon:effect></speak>`;
  } else {
    // Standard engine with crystal voice effects
    return "<speak><amazon:effect name=\"drc\"><amazon:effect phonation=\"soft\">" +
      "<amazon:effect vocal-tract-length=\"+12%\">" +
      `<prosody rate="slow" pitch="-10%" volume="soft">${escapedText}</prosody>` +
      "</amazon:effect></amazon:effect></amazon:effect></speak>";
  }
}

