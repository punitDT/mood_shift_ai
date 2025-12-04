import * as crypto from "crypto";
import { defineSecret } from "firebase-functions/params";
import { PollyConfig, VoiceMapping } from "../types";

// Define secrets
export const AWS_ACCESS_KEY = defineSecret("AWS_ACCESS_KEY");
export const AWS_SECRET_KEY = defineSecret("AWS_SECRET_KEY");

interface PollyResult {
  audioBuffer: Buffer;
  voiceId: string;
  engine: string;
}

export async function synthesizeSpeech(
  ssmlText: string,
  locale: string,
  voiceGender: "male" | "female",
  config: PollyConfig,
  voiceMapping: VoiceMapping,
  awsAccessKey: string,
  awsSecretKey: string
): Promise<PollyResult> {
  const engines = getEngineOrder(config.engine);
  const voiceId = getVoiceId(locale, voiceGender, config.engine, voiceMapping);

  for (const engine of engines) {
    try {
      const audioBuffer = await callPollyAPI(
        ssmlText,
        voiceId,
        locale,
        engine,
        config,
        awsAccessKey,
        awsSecretKey
      );

      return { audioBuffer, voiceId, engine };
    } catch (error) {
      console.warn(`Polly engine ${engine} failed, trying next...`, error);
      if (engines.indexOf(engine) === engines.length - 1) {
        throw error;
      }
    }
  }

  throw new Error("All Polly engines failed");
}

function getEngineOrder(preferredEngine: string): string[] {
  if (preferredEngine === "generative") {
    return ["generative", "neural", "standard"];
  } else if (preferredEngine === "neural") {
    return ["neural", "standard"];
  }
  return ["standard"];
}

function getVoiceId(
  locale: string,
  gender: "male" | "female",
  preferredEngine: string,
  voiceMapping: VoiceMapping
): string {
  const localeVoices = voiceMapping[locale];
  if (!localeVoices) {
    return gender === "male" ? "Matthew" : "Joanna";
  }

  const engines = getEngineOrder(preferredEngine);
  for (const engine of engines) {
    const engineVoices = localeVoices[engine as keyof typeof localeVoices];
    if (engineVoices && engineVoices[gender]) {
      return engineVoices[gender]!;
    }
  }

  // Fallback to opposite gender if preferred not available
  for (const engine of engines) {
    const engineVoices = localeVoices[engine as keyof typeof localeVoices];
    const oppositeGender = gender === "male" ? "female" : "male";
    if (engineVoices && engineVoices[oppositeGender]) {
      return engineVoices[oppositeGender]!;
    }
  }

  return gender === "male" ? "Matthew" : "Joanna";
}

async function callPollyAPI(
  ssmlText: string,
  voiceId: string,
  languageCode: string,
  engine: string,
  config: PollyConfig,
  awsAccessKey: string,
  awsSecretKey: string
): Promise<Buffer> {
  const endpoint = `https://polly.${config.region}.amazonaws.com/v1/speech`;
  const now = new Date();

  const requestBody = JSON.stringify({
    Text: ssmlText,
    TextType: "ssml",
    VoiceId: voiceId,
    LanguageCode: languageCode,
    Engine: engine,
    OutputFormat: config.outputFormat,
  });

  const headers = generateSigV4Headers(
    "POST",
    endpoint,
    requestBody,
    now,
    config.region,
    awsAccessKey,
    awsSecretKey
  );

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), config.timeoutSeconds * 1000);

  try {
    const response = await fetch(endpoint, {
      method: "POST",
      headers,
      body: requestBody,
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Polly API error: ${response.status} - ${errorText}`);
    }

    const arrayBuffer = await response.arrayBuffer();
    return Buffer.from(arrayBuffer);
  } catch (error) {
    clearTimeout(timeoutId);
    throw error;
  }
}

function generateSigV4Headers(
  method: string,
  endpoint: string,
  body: string,
  timestamp: Date,
  region: string,
  accessKey: string,
  secretKey: string
): { [key: string]: string } {
  const uri = new URL(endpoint);
  const host = uri.host;
  const canonicalUri = uri.pathname;

  const amzDate = formatAmzDate(timestamp);
  const dateStamp = formatDateStamp(timestamp);

  const payloadHash = crypto.createHash("sha256").update(body).digest("hex");

  const canonicalHeaders = `content-type:application/json\nhost:${host}\nx-amz-date:${amzDate}\n`;
  const signedHeaders = "content-type;host;x-amz-date";

  const canonicalRequest = `${method}\n${canonicalUri}\n\n${canonicalHeaders}\n${signedHeaders}\n${payloadHash}`;

  const credentialScope = `${dateStamp}/${region}/polly/aws4_request`;
  const canonicalHash = crypto.createHash("sha256").update(canonicalRequest).digest("hex");
  const stringToSign = `AWS4-HMAC-SHA256\n${amzDate}\n${credentialScope}\n${canonicalHash}`;

  const signingKey = getSignatureKey(secretKey, dateStamp, region, "polly");
  const signature = crypto.createHmac("sha256", signingKey).update(stringToSign).digest("hex");

  // Build authorization header as a single line (no newlines allowed in HTTP headers)
  const authorizationHeader = `AWS4-HMAC-SHA256 Credential=${accessKey}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;

  return {
    "Content-Type": "application/json",
    "Host": host,
    "X-Amz-Date": amzDate,
    "Authorization": authorizationHeader,
  };
}

function getSignatureKey(key: string, dateStamp: string, region: string, service: string): Buffer {
  const kDate = crypto.createHmac("sha256", `AWS4${key}`).update(dateStamp).digest();
  const kRegion = crypto.createHmac("sha256", kDate).update(region).digest();
  const kService = crypto.createHmac("sha256", kRegion).update(service).digest();
  return crypto.createHmac("sha256", kService).update("aws4_request").digest();
}

function formatAmzDate(dt: Date): string {
  return dt.toISOString().replace(/[:-]|\.\d{3}/g, "");
}

function formatDateStamp(dt: Date): string {
  return dt.toISOString().slice(0, 10).replace(/-/g, "");
}

