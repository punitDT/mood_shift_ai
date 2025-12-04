"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.GROQ_API_KEY = void 0;
exports.getLanguageName = getLanguageName;
exports.generateResponse = generateResponse;
exports.generateStrongerResponse = generateStrongerResponse;
const params_1 = require("firebase-functions/params");
const types_1 = require("../types");
// Define the secret
exports.GROQ_API_KEY = (0, params_1.defineSecret)("GROQ_API_KEY");
const LANGUAGE_NAMES = {
    en: "English",
    hi: "Hindi",
    es: "Spanish",
    zh: "Chinese",
    fr: "French",
    de: "German",
    ar: "Arabic",
    ja: "Japanese",
};
function getLanguageName(languageCode) {
    return LANGUAGE_NAMES[languageCode] || "English";
}
async function generateResponse(messages, config, apiKey) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), config.timeoutSeconds * 1000);
    try {
        const response = await fetch(config.apiUrl, {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${apiKey}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                model: config.model,
                messages,
                temperature: config.temperature,
                max_tokens: config.maxTokens,
                top_p: 1,
                frequency_penalty: config.frequencyPenalty,
                presence_penalty: config.presencePenalty,
                response_format: { type: "json_object" },
            }),
            signal: controller.signal,
        });
        clearTimeout(timeoutId);
        if (!response.ok) {
            throw new Error(`Groq API error: ${response.status} ${response.statusText}`);
        }
        const data = await response.json();
        if (data.choices && data.choices.length > 0) {
            const content = data.choices[0].message?.content || "";
            return parseGroqResponse(content, config.maxResponseWords);
        }
        throw new Error("No response from Groq API");
    }
    catch (error) {
        clearTimeout(timeoutId);
        throw error;
    }
}
async function generateStrongerResponse(originalResponse, originalStyle, languageName, config, promptsConfig, apiKey) {
    const styleStr = getStyleString(originalStyle);
    const prompt = promptsConfig.strongerPrompt
        .replace("{style}", styleStr)
        .replace("$languageName", languageName);
    const fullPrompt = `ORIGINAL RESPONSE: "${originalResponse}"
ORIGINAL STYLE: ${styleStr}

${prompt}`;
    const messages = [
        {
            role: "system",
            content: "You are MoodShift AI in MAXIMUM POWER MODE. Amplify responses to 2× intensity. ALWAYS respond with valid JSON only.",
        },
        { role: "user", content: fullPrompt },
    ];
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), config.timeoutSeconds * 1000);
    try {
        const response = await fetch(config.apiUrl, {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${apiKey}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                model: config.model,
                messages,
                temperature: 0.9,
                max_tokens: config.maxTokens,
                top_p: 1,
                frequency_penalty: 0.2,
                presence_penalty: 0.8,
                response_format: { type: "json_object" },
            }),
            signal: controller.signal,
        });
        clearTimeout(timeoutId);
        if (!response.ok) {
            throw new Error(`Groq API error: ${response.status}`);
        }
        const data = await response.json();
        if (data.choices && data.choices.length > 0) {
            const content = data.choices[0].message?.content || "";
            return parseGroqResponse(content, config.maxResponseWords);
        }
        throw new Error("No response from Groq API");
    }
    catch (error) {
        clearTimeout(timeoutId);
        throw error;
    }
}
function parseGroqResponse(content, maxWords) {
    try {
        const json = JSON.parse(content);
        let response = json.response || "";
        response = cleanResponse(response, maxWords);
        response = removeEmojis(response);
        return {
            style: types_1.MoodStyle.microDare, // Default style
            response,
        };
    }
    catch {
        // Try to extract JSON from the content
        const jsonMatch = content.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
            try {
                const json = JSON.parse(jsonMatch[0]);
                let response = json.response || "";
                response = cleanResponse(response, maxWords);
                response = removeEmojis(response);
                return { style: types_1.MoodStyle.microDare, response };
            }
            catch {
                // Fall through to return raw content
            }
        }
        return { style: types_1.MoodStyle.microDare, response: removeEmojis(content) };
    }
}
function cleanResponse(response, maxWords) {
    response = response.trim().replace(/\s+/g, " ");
    const words = response.split(" ");
    if (words.length > maxWords) {
        response = words.slice(0, maxWords).join(" ") + "...";
    }
    return response;
}
function removeEmojis(text) {
    // eslint-disable-next-line max-len
    const emojiRegex = /[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA00}-\u{1FA6F}]|[\u{1FA70}-\u{1FAFF}]/gu;
    return text.replace(emojiRegex, "").trim();
}
function getStyleString(style) {
    const styleMap = {
        [types_1.MoodStyle.chaosEnergy]: "CHAOS_ENERGY",
        [types_1.MoodStyle.gentleGrandma]: "GENTLE_GRANDMA",
        [types_1.MoodStyle.permissionSlip]: "PERMISSION_SLIP",
        [types_1.MoodStyle.realityCheck]: "REALITY_CHECK",
        [types_1.MoodStyle.microDare]: "MICRO_DARE",
    };
    return styleMap[style] || "MICRO_DARE";
}
//# sourceMappingURL=groqService.js.map