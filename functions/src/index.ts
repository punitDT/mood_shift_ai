/**
 * MoodShift AI Cloud Functions
 *
 * Main entry point for all Cloud Functions.
 * - processUserInput: Main AI processing function (Groq LLM + AWS Polly TTS)
 *
 * Note: Audio file cleanup is handled by Firebase Storage lifecycle rules
 * configured in the Google Cloud Console (auto-delete files in audio/ after 1 day)
 */

export { processUserInput } from "./processUserInput";

