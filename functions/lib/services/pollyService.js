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
exports.AWS_SECRET_KEY = exports.AWS_ACCESS_KEY = void 0;
exports.synthesizeSpeech = synthesizeSpeech;
const crypto = __importStar(require("crypto"));
const params_1 = require("firebase-functions/params");
// Define secrets
exports.AWS_ACCESS_KEY = (0, params_1.defineSecret)("AWS_ACCESS_KEY");
exports.AWS_SECRET_KEY = (0, params_1.defineSecret)("AWS_SECRET_KEY");
async function synthesizeSpeech(ssmlText, locale, voiceGender, config, voiceMapping, awsAccessKey, awsSecretKey) {
    const engines = getEngineOrder(config.engine);
    const voiceId = getVoiceId(locale, voiceGender, config.engine, voiceMapping);
    for (const engine of engines) {
        try {
            const audioBuffer = await callPollyAPI(ssmlText, voiceId, locale, engine, config, awsAccessKey, awsSecretKey);
            return { audioBuffer, voiceId, engine };
        }
        catch (error) {
            console.warn(`Polly engine ${engine} failed, trying next...`, error);
            if (engines.indexOf(engine) === engines.length - 1) {
                throw error;
            }
        }
    }
    throw new Error("All Polly engines failed");
}
function getEngineOrder(preferredEngine) {
    if (preferredEngine === "generative") {
        return ["generative", "neural", "standard"];
    }
    else if (preferredEngine === "neural") {
        return ["neural", "standard"];
    }
    return ["standard"];
}
function getVoiceId(locale, gender, preferredEngine, voiceMapping) {
    const localeVoices = voiceMapping[locale];
    if (!localeVoices) {
        return gender === "male" ? "Matthew" : "Joanna";
    }
    const engines = getEngineOrder(preferredEngine);
    for (const engine of engines) {
        const engineVoices = localeVoices[engine];
        if (engineVoices && engineVoices[gender]) {
            return engineVoices[gender];
        }
    }
    // Fallback to opposite gender if preferred not available
    for (const engine of engines) {
        const engineVoices = localeVoices[engine];
        const oppositeGender = gender === "male" ? "female" : "male";
        if (engineVoices && engineVoices[oppositeGender]) {
            return engineVoices[oppositeGender];
        }
    }
    return gender === "male" ? "Matthew" : "Joanna";
}
async function callPollyAPI(ssmlText, voiceId, languageCode, engine, config, awsAccessKey, awsSecretKey) {
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
    const headers = generateSigV4Headers("POST", endpoint, requestBody, now, config.region, awsAccessKey, awsSecretKey);
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
    }
    catch (error) {
        clearTimeout(timeoutId);
        throw error;
    }
}
function generateSigV4Headers(method, endpoint, body, timestamp, region, accessKey, secretKey) {
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
function getSignatureKey(key, dateStamp, region, service) {
    const kDate = crypto.createHmac("sha256", `AWS4${key}`).update(dateStamp).digest();
    const kRegion = crypto.createHmac("sha256", kDate).update(region).digest();
    const kService = crypto.createHmac("sha256", kRegion).update(service).digest();
    return crypto.createHmac("sha256", kService).update("aws4_request").digest();
}
function formatAmzDate(dt) {
    return dt.toISOString().replace(/[:-]|\.\d{3}/g, "");
}
function formatDateStamp(dt) {
    return dt.toISOString().slice(0, 10).replace(/-/g, "");
}
//# sourceMappingURL=pollyService.js.map