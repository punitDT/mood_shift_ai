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
exports.generateInputHash = generateInputHash;
exports.checkCache = checkCache;
exports.saveToCache = saveToCache;
const admin = __importStar(require("firebase-admin"));
const crypto = __importStar(require("crypto"));
const AUDIO_BUCKET_PATH = "audio";
const CACHE_STATS_COLLECTION = "cache_stats";
const CACHE_STATS_DOC = "audio_cache";
// Generate hash based on user input for caching
function generateInputHash(userText, language, locale, voiceGender, crystalVoice, strongerMode, originalResponse) {
    const input = strongerMode && originalResponse ?
        `stronger|${originalResponse}|${locale}|${voiceGender}|${crystalVoice}` :
        `${userText}|${language}|${locale}|${voiceGender}|${crystalVoice}`;
    return crypto.createHash("sha256").update(input).digest("hex").substring(0, 32);
}
// Generate a download token for Firebase Storage public URL
function generateDownloadToken() {
    return crypto.randomUUID();
}
// Build Firebase Storage public URL with download token
function buildPublicUrl(bucketName, filePath, token) {
    const encodedPath = encodeURIComponent(filePath);
    return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodedPath}?alt=media&token=${token}`;
}
// Check cache - returns cached response data from audio file metadata
async function checkCache(inputHash) {
    try {
        const bucket = admin.storage().bucket();
        const filePath = `${AUDIO_BUCKET_PATH}/${inputHash}.mp3`;
        const file = bucket.file(filePath);
        const [exists] = await file.exists();
        if (!exists) {
            return null;
        }
        const [metadata] = await file.getMetadata();
        const customMetadata = metadata.metadata;
        if (!customMetadata?.firebaseStorageDownloadTokens || !customMetadata?.response) {
            return null;
        }
        // Cache hit - increment counter
        const db = admin.firestore();
        db.collection(CACHE_STATS_COLLECTION).doc(CACHE_STATS_DOC).set({
            hits: admin.firestore.FieldValue.increment(1),
            lastHitAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true }).catch(() => { }); // Fire and forget
        const audioUrl = buildPublicUrl(bucket.name, filePath, customMetadata.firebaseStorageDownloadTokens);
        return {
            response: customMetadata.response,
            audioUrl,
            voiceId: customMetadata.voiceId || "",
            engine: customMetadata.engine || "",
        };
    }
    catch (error) {
        console.error("Error checking cache:", error);
        return null;
    }
}
// Save to cache - stores audio with response in metadata
async function saveToCache(inputHash, response, audioBuffer, voiceId, engine) {
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
    }
    catch (error) {
        console.error("Error saving to cache:", error);
        throw error;
    }
}
//# sourceMappingURL=audioService.js.map