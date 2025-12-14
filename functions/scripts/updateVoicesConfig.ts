/**
 * Script to update voices config in Firebase with complete AWS Polly voice mapping
 * Run with: npx ts-node scripts/updateVoicesConfig.ts [dev|prod]
 * 
 * Based on AWS Polly available voices as of Dec 2024:
 * https://docs.aws.amazon.com/polly/latest/dg/available-voices.html
 */

import * as admin from "firebase-admin";

const args = process.argv.slice(2);
const environment = args[0] || "dev";

const projectId = environment === "prod" ? "mood-shift-ai" : "mood-shift-ai-dev";

admin.initializeApp({ projectId });
const db = admin.firestore();

// Complete voice mapping based on AWS Polly available voices
// Note: Some languages don't have male voices (hi-IN, cmn-CN, ko-KR, etc.)
const voicesConfig = {
  // English (US) - Full support
  "en-US": {
    generative: { male: "Matthew", female: "Danielle" },
    neural: { male: "Gregory", female: "Danielle" },
    standard: { male: "Matthew", female: "Joanna" },
  },
  // English (British) - Added Arthur for neural male
  "en-GB": {
    generative: { female: "Amy" }, // No male generative for en-GB
    neural: { male: "Arthur", female: "Amy" },
    standard: { male: "Brian", female: "Emma" },
  },
  // English (Australian)
  "en-AU": {
    generative: { female: "Olivia" },
    neural: { female: "Olivia" },
    standard: { male: "Russell", female: "Nicole" },
  },
  // English (Indian) - Kajal is bilingual (en-IN and hi-IN)
  "en-IN": {
    generative: { female: "Kajal" },
    neural: { female: "Kajal" },
    standard: { female: "Aditi" }, // No male voice
  },
  // Hindi - NO MALE VOICE AVAILABLE in AWS Polly
  "hi-IN": {
    generative: { female: "Kajal" }, // Kajal is bilingual
    neural: { female: "Kajal" },
    standard: { female: "Aditi" },
    // male: NOT AVAILABLE - will fallback to female
  },
  // Spanish (Spain) - Full support
  "es-ES": {
    generative: { male: "Sergio", female: "Lucia" },
    neural: { male: "Sergio", female: "Lucia" },
    standard: { male: "Enrique", female: "Lucia" },
  },
  // Spanish (Mexican)
  "es-MX": {
    generative: { male: "Andres", female: "Mia" },
    neural: { male: "Andres", female: "Mia" },
    standard: { female: "Mia" },
  },
  // Spanish (US)
  "es-US": {
    generative: { male: "Pedro", female: "Lupe" },
    neural: { male: "Pedro", female: "Lupe" },
    standard: { male: "Miguel", female: "Lupe" },
  },
  // French (France) - Full support
  "fr-FR": {
    generative: { male: "Remi", female: "Lea" },
    neural: { male: "Remi", female: "Lea" },
    standard: { male: "Mathieu", female: "Celine" },
  },
  // French (Canadian)
  "fr-CA": {
    generative: { male: "Liam", female: "Gabrielle" },
    neural: { male: "Liam", female: "Gabrielle" },
    standard: { female: "Chantal" },
  },
  // German - Full support
  "de-DE": {
    generative: { male: "Daniel", female: "Vicki" },
    neural: { male: "Daniel", female: "Vicki" },
    standard: { male: "Hans", female: "Vicki" },
  },
  // Italian
  "it-IT": {
    generative: { female: "Bianca" },
    neural: { male: "Adriano", female: "Bianca" },
    standard: { male: "Giorgio", female: "Carla" },
  },
  // Portuguese (Brazilian)
  "pt-BR": {
    generative: { female: "Camila" },
    neural: { male: "Thiago", female: "Camila" },
    standard: { male: "Ricardo", female: "Vitoria" },
  },
  // Japanese
  "ja-JP": {
    generative: {}, // No generative
    neural: { male: "Takumi", female: "Kazuha" },
    standard: { male: "Takumi", female: "Mizuki" },
  },
  // Korean - NO MALE VOICE
  "ko-KR": {
    generative: { female: "Seoyeon" },
    neural: { female: "Seoyeon" },
    standard: { female: "Seoyeon" },
  },
  // Chinese (Mandarin) - NO MALE VOICE
  "cmn-CN": {
    generative: {},
    neural: { female: "Zhiyu" },
    standard: { female: "Zhiyu" },
  },
  // Arabic (Gulf)
  "ar-AE": {
    generative: {},
    neural: { male: "Zayd", female: "Hala" },
    standard: {},
  },
  // Arabic (Standard)
  "arb": {
    generative: {},
    neural: {},
    standard: { female: "Zeina" },
  },
};

async function updateVoicesConfig() {
  console.log(`Updating voices config in ${projectId}...`);
  
  await db.collection("config").doc("voices").set(voicesConfig);
  
  console.log("✅ Voices config updated successfully!");
  console.log("\nLanguages with NO male voice (will fallback to female):");
  console.log("  - hi-IN (Hindi)");
  console.log("  - ko-KR (Korean)");
  console.log("  - cmn-CN (Chinese Mandarin)");
  console.log("  - en-IN (English Indian)");
  
  process.exit(0);
}

updateVoicesConfig().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});

