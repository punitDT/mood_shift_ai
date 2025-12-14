/**
 * Script to test prosody config for all styles, features, languages, and voices
 * Run with: npx ts-node scripts/testProsodyConfig.ts
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin with the dev project
admin.initializeApp({
  projectId: "mood-shift-ai-dev",
});

const db = admin.firestore();

interface ProsodySettings {
  rate: string;
  pitch: string;
  volume: string;
}

interface VoiceEngineMapping {
  male?: string;
  female?: string;
}

async function testConfig() {
  console.log("=".repeat(60));
  console.log("Testing Firebase Config for MoodShift AI");
  console.log("=".repeat(60));

  // Test 1: Prosody Config
  console.log("\n📊 PROSODY CONFIG:");
  console.log("-".repeat(40));
  const prosodyDoc = await db.collection("config").doc("prosody").get();
  if (!prosodyDoc.exists) {
    console.error("❌ Prosody config NOT FOUND!");
  } else {
    const prosody = prosodyDoc.data() as { [style: string]: ProsodySettings };
    const styles = ["chaosEnergy", "gentleGrandma", "permissionSlip", "realityCheck", "microDare"];
    
    for (const style of styles) {
      if (prosody[style]) {
        const s = prosody[style];
        console.log(`  ✅ ${style}: rate=${s.rate}, pitch=${s.pitch}, volume=${s.volume}`);
      } else {
        console.log(`  ❌ ${style}: MISSING!`);
      }
    }
  }

  // Test 2: Polly Config (feature engines)
  console.log("\n🔊 POLLY CONFIG (Feature Engines):");
  console.log("-".repeat(40));
  const pollyDoc = await db.collection("config").doc("polly").get();
  if (!pollyDoc.exists) {
    console.error("❌ Polly config NOT FOUND!");
  } else {
    const polly = pollyDoc.data();
    console.log(`  Default engine: ${polly?.engine}`);
    if (polly?.featureEngines) {
      console.log(`  ✅ main: ${polly.featureEngines.main}`);
      console.log(`  ✅ stronger: ${polly.featureEngines.stronger}`);
      console.log(`  ✅ crystal: ${polly.featureEngines.crystal}`);
    } else {
      console.log("  ❌ featureEngines MISSING!");
    }
  }

  // Test 3: Voices Config
  console.log("\n🎤 VOICES CONFIG:");
  console.log("-".repeat(40));
  const voicesDoc = await db.collection("config").doc("voices").get();
  if (!voicesDoc.exists) {
    console.error("❌ Voices config NOT FOUND!");
  } else {
    const voices = voicesDoc.data() as { [locale: string]: { [engine: string]: VoiceEngineMapping } };
    const testLocales = ["en-US", "en-GB", "hi-IN", "es-ES", "fr-FR", "de-DE"];
    const engines = ["generative", "neural", "standard"];
    
    for (const locale of testLocales) {
      if (voices[locale]) {
        console.log(`  ${locale}:`);
        for (const engine of engines) {
          const voiceMap = voices[locale][engine];
          if (voiceMap) {
            const male = voiceMap.male || "N/A";
            const female = voiceMap.female || "N/A";
            console.log(`    ${engine}: M=${male}, F=${female}`);
          }
        }
      } else {
        console.log(`  ❌ ${locale}: MISSING!`);
      }
    }
  }

  // Test 4: Prompts Config
  console.log("\n📝 PROMPTS CONFIG:");
  console.log("-".repeat(40));
  const promptsDoc = await db.collection("config").doc("prompts").get();
  if (!promptsDoc.exists) {
    console.error("❌ Prompts config NOT FOUND!");
  } else {
    const prompts = promptsDoc.data();
    console.log(`  ✅ systemPrompt: ${prompts?.systemPrompt?.length || 0} chars`);
    console.log(`  ✅ strongerPrompt: ${prompts?.strongerPrompt?.length || 0} chars`);
    console.log(`  ✅ emergencyResponse: ${prompts?.emergencyResponse?.length || 0} chars`);
    
    // Check if systemPrompt includes style instructions
    if (prompts?.systemPrompt?.includes("chaosEnergy")) {
      console.log("  ✅ systemPrompt includes style selection instructions");
    } else {
      console.log("  ⚠️  systemPrompt may be missing style selection instructions");
    }
  }

  // Test 5: LLM Config
  console.log("\n🤖 LLM CONFIG:");
  console.log("-".repeat(40));
  const llmDoc = await db.collection("config").doc("llm").get();
  if (!llmDoc.exists) {
    console.error("❌ LLM config NOT FOUND!");
  } else {
    const llm = llmDoc.data();
    console.log(`  ✅ model: ${llm?.model}`);
    console.log(`  ✅ temperature: ${llm?.temperature}`);
    console.log(`  ✅ maxTokens: ${llm?.maxTokens}`);
    console.log(`  ✅ maxResponseWords: ${llm?.maxResponseWords}`);
  }

  console.log("\n" + "=".repeat(60));
  console.log("Test Complete!");
  console.log("=".repeat(60));

  process.exit(0);
}

testConfig().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});

