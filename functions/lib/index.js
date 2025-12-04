"use strict";
/**
 * MoodShift AI Cloud Functions
 *
 * Main entry point for all Cloud Functions.
 * - processUserInput: Main AI processing function (Groq LLM + AWS Polly TTS)
 *
 * Note: Audio file cleanup is handled by Firebase Storage lifecycle rules
 * configured in the Google Cloud Console (auto-delete files in audio/ after 1 day)
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.processUserInput = void 0;
var processUserInput_1 = require("./processUserInput");
Object.defineProperty(exports, "processUserInput", { enumerable: true, get: function () { return processUserInput_1.processUserInput; } });
//# sourceMappingURL=index.js.map