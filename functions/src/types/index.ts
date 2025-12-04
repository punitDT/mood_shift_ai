// MoodStyle enum matching Flutter's ai_service.dart
export enum MoodStyle {
  chaosEnergy = "chaosEnergy",
  gentleGrandma = "gentleGrandma",
  permissionSlip = "permissionSlip",
  realityCheck = "realityCheck",
  microDare = "microDare",
}

// Request payload from Flutter client
export interface ProcessUserInputRequest {
  deviceId: string;
  text: string;
  language: string; // e.g., "en", "hi", "es"
  locale: string; // e.g., "en-US", "hi-IN"
  voiceGender: "male" | "female";
  crystalVoice: boolean;
  strongerMode: boolean;
  originalResponse?: string; // Only for strongerMode
}

// Response to Flutter client
export interface ProcessUserInputResponse {
  success: boolean;
  response: string;
  audioUrl: string;
  voiceId: string;
  engine: string;
  error?: string;
}

// Conversation message stored in Firestore
export interface ConversationMessage {
  role: "user" | "assistant";
  content: string;
  timestamp: FirebaseFirestore.Timestamp;
}

// Conversation document in Firestore
export interface ConversationDocument {
  deviceId: string;
  messages: ConversationMessage[];
  lastActivity: FirebaseFirestore.Timestamp;
}

// LLM Config from Firestore
export interface LLMConfig {
  model: string;
  apiUrl: string;
  temperature: number;
  maxTokens: number;
  timeoutSeconds: number;
  frequencyPenalty: number;
  presencePenalty: number;
  maxResponseWords: number;
}

// Prompts Config from Firestore
export interface PromptsConfig {
  systemPrompt: string;
  strongerPrompt: string;
  emergencyResponse: string;
}

// Polly Config from Firestore
export interface PollyConfig {
  region: string;
  engine: string;
  outputFormat: string;
  timeoutSeconds: number;
}

// Voice mapping structure
export interface VoiceMapping {
  [locale: string]: {
    generative: { male?: string; female?: string };
    neural: { male?: string; female?: string };
    standard: { male?: string; female?: string };
  };
}

// Prosody settings for each MoodStyle
export interface ProsodySettings {
  rate: string;
  pitch: string;
  volume: string;
}

export interface ProsodyConfig {
  [style: string]: ProsodySettings;
}

// SSML templates for each engine
export interface SSMLTemplates {
  generative: {
    normal: string;
    stronger: string;
    crystal: string;
  };
  neural: {
    normal: string;
    stronger: string;
    crystal: string;
  };
  standard: {
    normal: string;
    stronger: string;
    crystal: string;
  };
}

// Fallback responses by language
export interface FallbackResponses {
  [language: string]: string[];
}

// Groq API response structure
export interface GroqAPIResponse {
  choices: Array<{
    message: {
      content: string;
    };
  }>;
}

// Groq parsed response
export interface GroqParsedResponse {
  style: MoodStyle;
  response: string;
}

// Audio cache entry
export interface AudioCacheEntry {
  hash: string;
  url: string;
  createdAt: FirebaseFirestore.Timestamp;
  expiresAt: FirebaseFirestore.Timestamp;
}

