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
exports.getConversationHistory = getConversationHistory;
exports.addToConversationHistory = addToConversationHistory;
exports.clearConversationHistory = clearConversationHistory;
exports.buildMessagesForGroq = buildMessagesForGroq;
const admin = __importStar(require("firebase-admin"));
const MAX_MESSAGES = 8; // Keep last 4 user + 4 assistant messages
async function getConversationHistory(deviceId) {
    try {
        const db = admin.firestore();
        const docRef = db.collection("conversations").doc(deviceId);
        const doc = await docRef.get();
        if (!doc.exists) {
            return [];
        }
        const data = doc.data();
        return data.messages || [];
    }
    catch (error) {
        console.error("Error getting conversation history:", error);
        return [];
    }
}
async function addToConversationHistory(deviceId, userMessage, assistantMessage) {
    try {
        const db = admin.firestore();
        const docRef = db.collection("conversations").doc(deviceId);
        const now = admin.firestore.Timestamp.now();
        const newMessages = [
            { role: "user", content: userMessage, timestamp: now },
            { role: "assistant", content: assistantMessage, timestamp: now },
        ];
        const doc = await docRef.get();
        if (!doc.exists) {
            // Create new conversation document
            const newDoc = {
                deviceId,
                messages: newMessages,
                lastActivity: now,
            };
            await docRef.set(newDoc);
        }
        else {
            // Update existing conversation
            const data = doc.data();
            let messages = [...(data.messages || []), ...newMessages];
            // Keep only the last MAX_MESSAGES
            if (messages.length > MAX_MESSAGES) {
                messages = messages.slice(-MAX_MESSAGES);
            }
            await docRef.update({
                messages,
                lastActivity: now,
            });
        }
    }
    catch (error) {
        console.error("Error adding to conversation history:", error);
        // Don't throw - conversation history is not critical
    }
}
async function clearConversationHistory(deviceId) {
    try {
        const db = admin.firestore();
        await db.collection("conversations").doc(deviceId).delete();
    }
    catch (error) {
        console.error("Error clearing conversation history:", error);
    }
}
// Build messages array for Groq API from conversation history
function buildMessagesForGroq(history, currentUserInput, systemPrompt, languageName) {
    const messages = [];
    // System message first (with language substitution)
    const systemContent = systemPrompt.replace(/\$languageName/g, languageName);
    messages.push({ role: "system", content: systemContent });
    // Add historical messages (already in chronological order)
    // Skip the most recent pair as we'll add the current input separately
    const historyToUse = history.slice(0, -2); // Remove last pair if exists
    for (const msg of historyToUse) {
        messages.push({
            role: msg.role,
            content: msg.content,
        });
    }
    // Add current user message
    messages.push({ role: "user", content: currentUserInput });
    return messages;
}
//# sourceMappingURL=conversationService.js.map