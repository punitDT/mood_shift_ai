import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { logger } from "../utils/logger";

const AUDIO_BUCKET_PATH = "audio";
const CACHE_STATS_COLLECTION = "cache_stats";
const CACHE_STATS_DOC = "audio_cache";

export interface CachedResponse {
  response: string;
  audioUrl: string;
  voiceId: string;
  engine: string;
}

// Generate hash based on user input for caching
export function generateInputHash(
  userText: string,
  language: string,
  locale: string,
  voiceGender: string,
  crystalVoice: boolean,
  strongerMode: boolean,
  originalResponse?: string
): string {
  const input = strongerMode && originalResponse ?
    `stronger|${originalResponse}|${locale}|${voiceGender}|${crystalVoice}` :
    `${userText}|${language}|${locale}|${voiceGender}|${crystalVoice}`;
  return crypto.createHash("sha256").update(input).digest("hex").substring(0, 32);
}

// Generate a download token for Firebase Storage public URL
function generateDownloadToken(): string {
  return crypto.randomUUID();
}

// Build Firebase Storage public URL with download token
function buildPublicUrl(bucketName: string, filePath: string, token: string): string {
  const encodedPath = encodeURIComponent(filePath);
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodedPath}?alt=media&token=${token}`;
}

// Check cache - returns cached response data from audio file metadata
export async function checkCache(inputHash: string): Promise<CachedResponse | null> {
  try {
    const bucket = admin.storage().bucket();
    const filePath = `${AUDIO_BUCKET_PATH}/${inputHash}.mp3`;
    const file = bucket.file(filePath);

    const [exists] = await file.exists();
    if (!exists) {
      return null;
    }

    const [metadata] = await file.getMetadata();
    const customMetadata = metadata.metadata as { [key: string]: string } | undefined;

    if (!customMetadata?.firebaseStorageDownloadTokens || !customMetadata?.response) {
      return null;
    }

    // Cache hit - increment counter
    const db = admin.firestore();
    db.collection(CACHE_STATS_COLLECTION).doc(CACHE_STATS_DOC).set(
      {
        hits: admin.firestore.FieldValue.increment(1),
        lastHitAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    ).catch(() => {}); // Fire and forget

    const audioUrl = buildPublicUrl(bucket.name, filePath, customMetadata.firebaseStorageDownloadTokens);

    return {
      response: customMetadata.response,
      audioUrl,
      voiceId: customMetadata.voiceId || "",
      engine: customMetadata.engine || "",
    };
  } catch (error) {
    logger.error("Error checking cache", error);
    return null;
  }
}

// Save to cache - stores audio with response in metadata
export async function saveToCache(
  inputHash: string,
  response: string,
  audioBuffer: Buffer,
  voiceId: string,
  engine: string
): Promise<string> {
  try {
    const bucket = admin.storage().bucket();
    const filePath = `${AUDIO_BUCKET_PATH}/${inputHash}.mp3`;
    const file = bucket.file(filePath);
    const downloadToken = generateDownloadToken();

    await file.save(audioBuffer, {
      metadata: {
        contentType: "audio/mpeg",
        cacheControl: "public, max-age=86400",
        metadata: {
          firebaseStorageDownloadTokens: downloadToken,
          response: response,
          voiceId: voiceId,
          engine: engine,
        },
      },
    });

    return buildPublicUrl(bucket.name, filePath, downloadToken);
  } catch (error) {
    logger.error("Error saving to cache", error);
    throw error;
  }
}
