import * as admin from "firebase-admin";
import { ConversationMessage, ConversationDocument } from "../types";
import { logger } from "../utils/logger";

const MAX_MESSAGES = 8; // Keep last 4 user + 4 assistant messages

export async function getConversationHistory(deviceId: string): Promise<ConversationMessage[]> {
  try {
    const db = admin.firestore();
    const docRef = db.collection("conversations").doc(deviceId);
    const doc = await docRef.get();

    if (!doc.exists) {
      return [];
    }

    const data = doc.data() as ConversationDocument;
    return data.messages || [];
  } catch (error) {
    logger.error("Error getting conversation history", error);
    return [];
  }
}

export async function addToConversationHistory(
  deviceId: string,
  userMessage: string,
  assistantMessage: string
): Promise<void> {
  try {
    const db = admin.firestore();
    const docRef = db.collection("conversations").doc(deviceId);
    const now = admin.firestore.Timestamp.now();

    const newMessages: ConversationMessage[] = [
      { role: "user", content: userMessage, timestamp: now },
      { role: "assistant", content: assistantMessage, timestamp: now },
    ];

    const doc = await docRef.get();

    if (!doc.exists) {
      // Create new conversation document
      const newDoc: ConversationDocument = {
        deviceId,
        messages: newMessages,
        lastActivity: now,
      };
      await docRef.set(newDoc);
    } else {
      // Update existing conversation
      const data = doc.data() as ConversationDocument;
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
  } catch (error) {
    logger.error("Error adding to conversation history", error);
    // Don't throw - conversation history is not critical
  }
}

export async function clearConversationHistory(deviceId: string): Promise<void> {
  try {
    const db = admin.firestore();
    await db.collection("conversations").doc(deviceId).delete();
    logger.debug("Conversation history cleared", { deviceId });
  } catch (error) {
    logger.error("Error clearing conversation history", error);
  }
}

// Build messages array for Groq API from conversation history
export function buildMessagesForGroq(
  history: ConversationMessage[],
  currentUserInput: string,
  systemPrompt: string,
  languageName: string
): Array<{ role: string; content: string }> {
  const messages: Array<{ role: string; content: string }> = [];

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

