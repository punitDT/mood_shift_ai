/**
 * Comprehensive test script for Cloud Function with all scenarios
 * Tests: All styles, features, languages, genders, and engine fallbacks
 * Run with: npx ts-node scripts/testCloudFunction.ts
 */

const FUNCTION_URL = "https://processuserinput-tyzh7rqnka-uc.a.run.app";

interface TestCase {
  name: string;
  category: string;
  payload: {
    deviceId: string;
    text: string;
    language: string;
    locale: string;
    voiceGender: "male" | "female";
    crystalVoice: boolean;
    strongerMode: boolean;
    originalResponse?: string;
    originalStyle?: string;
  };
  expectedEngine?: string; // Expected engine (for validation)
}

const testCases: TestCase[] = [
  // ============================================
  // CATEGORY 1: Normal Mode - All Languages & Genders (uses standard engine)
  // ============================================
  { name: "en-US Female", category: "Normal Mode", expectedEngine: "standard",
    payload: { deviceId: "test-1", text: "I'm stressed", language: "en", locale: "en-US", voiceGender: "female", crystalVoice: false, strongerMode: false } },
  { name: "en-US Male", category: "Normal Mode", expectedEngine: "standard",
    payload: { deviceId: "test-2", text: "I need motivation", language: "en", locale: "en-US", voiceGender: "male", crystalVoice: false, strongerMode: false } },
  { name: "en-GB Female", category: "Normal Mode", expectedEngine: "standard",
    payload: { deviceId: "test-3", text: "Feeling down", language: "en", locale: "en-GB", voiceGender: "female", crystalVoice: false, strongerMode: false } },
  { name: "en-GB Male", category: "Normal Mode", expectedEngine: "standard",
    payload: { deviceId: "test-4", text: "Need help", language: "en", locale: "en-GB", voiceGender: "male", crystalVoice: false, strongerMode: false } },
  { name: "hi-IN Female", category: "Normal Mode", expectedEngine: "standard",
    payload: { deviceId: "test-5", text: "मुझे थकान है", language: "hi", locale: "hi-IN", voiceGender: "female", crystalVoice: false, strongerMode: false } },
  { name: "hi-IN Male (fallback)", category: "Normal Mode", expectedEngine: "standard",
    payload: { deviceId: "test-6", text: "मदद चाहिए", language: "hi", locale: "hi-IN", voiceGender: "male", crystalVoice: false, strongerMode: false } },
  { name: "es-ES Female", category: "Normal Mode", expectedEngine: "standard",
    payload: { deviceId: "test-7", text: "Estoy cansado", language: "es", locale: "es-ES", voiceGender: "female", crystalVoice: false, strongerMode: false } },
  { name: "es-ES Male", category: "Normal Mode", expectedEngine: "standard",
    payload: { deviceId: "test-8", text: "Necesito ayuda", language: "es", locale: "es-ES", voiceGender: "male", crystalVoice: false, strongerMode: false } },
  { name: "fr-FR Female", category: "Normal Mode", expectedEngine: "standard",
    payload: { deviceId: "test-9", text: "Je suis fatigué", language: "fr", locale: "fr-FR", voiceGender: "female", crystalVoice: false, strongerMode: false } },
  { name: "fr-FR Male", category: "Normal Mode", expectedEngine: "standard",
    payload: { deviceId: "test-10", text: "J'ai besoin d'aide", language: "fr", locale: "fr-FR", voiceGender: "male", crystalVoice: false, strongerMode: false } },
  { name: "de-DE Female", category: "Normal Mode", expectedEngine: "standard",
    payload: { deviceId: "test-11", text: "Ich bin müde", language: "de", locale: "de-DE", voiceGender: "female", crystalVoice: false, strongerMode: false } },
  { name: "de-DE Male", category: "Normal Mode", expectedEngine: "standard",
    payload: { deviceId: "test-12", text: "Ich brauche Hilfe", language: "de", locale: "de-DE", voiceGender: "male", crystalVoice: false, strongerMode: false } },

  // ============================================
  // CATEGORY 2: Crystal Voice - All Languages (uses generative engine, fallback to neural)
  // ============================================
  { name: "en-US Female Crystal", category: "Crystal Voice", expectedEngine: "generative",
    payload: { deviceId: "test-20", text: "I need calm", language: "en", locale: "en-US", voiceGender: "female", crystalVoice: true, strongerMode: false } },
  { name: "en-US Male Crystal", category: "Crystal Voice", expectedEngine: "generative",
    payload: { deviceId: "test-21", text: "Help me relax", language: "en", locale: "en-US", voiceGender: "male", crystalVoice: true, strongerMode: false } },
  { name: "en-GB Female Crystal", category: "Crystal Voice",
    payload: { deviceId: "test-22", text: "Calm me down", language: "en", locale: "en-GB", voiceGender: "female", crystalVoice: true, strongerMode: false } },
  { name: "hi-IN Female Crystal", category: "Crystal Voice",
    payload: { deviceId: "test-23", text: "शांत करो", language: "hi", locale: "hi-IN", voiceGender: "female", crystalVoice: true, strongerMode: false } },
  { name: "es-ES Female Crystal", category: "Crystal Voice",
    payload: { deviceId: "test-24", text: "Calma", language: "es", locale: "es-ES", voiceGender: "female", crystalVoice: true, strongerMode: false } },
  { name: "es-ES Male Crystal", category: "Crystal Voice",
    payload: { deviceId: "test-25", text: "Relájame", language: "es", locale: "es-ES", voiceGender: "male", crystalVoice: true, strongerMode: false } },

  // ============================================
  // CATEGORY 3: 2x Stronger - All Styles (uses generative engine)
  // ============================================
  { name: "chaosEnergy Male", category: "2x Stronger", expectedEngine: "generative",
    payload: { deviceId: "test-30", text: "", language: "en", locale: "en-US", voiceGender: "male", crystalVoice: false, strongerMode: true, originalResponse: "You can do this!", originalStyle: "chaosEnergy" } },
  { name: "chaosEnergy Female", category: "2x Stronger", expectedEngine: "generative",
    payload: { deviceId: "test-31", text: "", language: "en", locale: "en-US", voiceGender: "female", crystalVoice: false, strongerMode: true, originalResponse: "Let's go!", originalStyle: "chaosEnergy" } },
  { name: "gentleGrandma Female", category: "2x Stronger", expectedEngine: "generative",
    payload: { deviceId: "test-32", text: "", language: "en", locale: "en-US", voiceGender: "female", crystalVoice: false, strongerMode: true, originalResponse: "It's okay to rest.", originalStyle: "gentleGrandma" } },
  { name: "gentleGrandma Male", category: "2x Stronger", expectedEngine: "generative",
    payload: { deviceId: "test-33", text: "", language: "en", locale: "en-US", voiceGender: "male", crystalVoice: false, strongerMode: true, originalResponse: "Take your time.", originalStyle: "gentleGrandma" } },
  { name: "permissionSlip Female", category: "2x Stronger", expectedEngine: "generative",
    payload: { deviceId: "test-34", text: "", language: "en", locale: "en-US", voiceGender: "female", crystalVoice: false, strongerMode: true, originalResponse: "You're allowed to feel this.", originalStyle: "permissionSlip" } },
  { name: "permissionSlip Male", category: "2x Stronger", expectedEngine: "generative",
    payload: { deviceId: "test-35", text: "", language: "en", locale: "en-US", voiceGender: "male", crystalVoice: false, strongerMode: true, originalResponse: "It's okay.", originalStyle: "permissionSlip" } },
  { name: "realityCheck Male", category: "2x Stronger", expectedEngine: "generative",
    payload: { deviceId: "test-36", text: "", language: "en", locale: "en-US", voiceGender: "male", crystalVoice: false, strongerMode: true, originalResponse: "Let's be honest.", originalStyle: "realityCheck" } },
  { name: "realityCheck Female", category: "2x Stronger", expectedEngine: "generative",
    payload: { deviceId: "test-37", text: "", language: "en", locale: "en-US", voiceGender: "female", crystalVoice: false, strongerMode: true, originalResponse: "Face the truth.", originalStyle: "realityCheck" } },
  { name: "microDare Male", category: "2x Stronger", expectedEngine: "generative",
    payload: { deviceId: "test-38", text: "", language: "en", locale: "en-US", voiceGender: "male", crystalVoice: false, strongerMode: true, originalResponse: "Try this small thing.", originalStyle: "microDare" } },
  { name: "microDare Female", category: "2x Stronger", expectedEngine: "generative",
    payload: { deviceId: "test-39", text: "", language: "en", locale: "en-US", voiceGender: "female", crystalVoice: false, strongerMode: true, originalResponse: "Take one step.", originalStyle: "microDare" } },

  // ============================================
  // CATEGORY 4: 2x Stronger - Different Languages (tests neural fallback)
  // ============================================
  { name: "es-ES Stronger", category: "2x Stronger Languages",
    payload: { deviceId: "test-40", text: "", language: "es", locale: "es-ES", voiceGender: "female", crystalVoice: false, strongerMode: true, originalResponse: "Puedes hacerlo!", originalStyle: "chaosEnergy" } },
  { name: "fr-FR Stronger", category: "2x Stronger Languages",
    payload: { deviceId: "test-41", text: "", language: "fr", locale: "fr-FR", voiceGender: "female", crystalVoice: false, strongerMode: true, originalResponse: "Tu peux le faire!", originalStyle: "chaosEnergy" } },
  { name: "de-DE Stronger", category: "2x Stronger Languages",
    payload: { deviceId: "test-42", text: "", language: "de", locale: "de-DE", voiceGender: "male", crystalVoice: false, strongerMode: true, originalResponse: "Du schaffst das!", originalStyle: "chaosEnergy" } },
  { name: "hi-IN Stronger", category: "2x Stronger Languages",
    payload: { deviceId: "test-43", text: "", language: "hi", locale: "hi-IN", voiceGender: "female", crystalVoice: false, strongerMode: true, originalResponse: "तुम कर सकते हो!", originalStyle: "chaosEnergy" } },
];

interface TestResult {
  name: string;
  category: string;
  success: boolean;
  style?: string;
  voice?: string;
  engine?: string;
  expectedEngine?: string;
  engineMatch?: boolean;
  duration?: number;
  error?: string;
}

async function runTests() {
  console.log("=".repeat(70));
  console.log("  COMPREHENSIVE CLOUD FUNCTION TEST");
  console.log("  Testing: Styles, Features, Languages, Genders, Engine Fallbacks");
  console.log("=".repeat(70));

  const results: TestResult[] = [];
  let currentCategory = "";

  for (const testCase of testCases) {
    // Print category header
    if (testCase.category !== currentCategory) {
      currentCategory = testCase.category;
      console.log(`\n${"━".repeat(70)}`);
      console.log(`📁 ${currentCategory.toUpperCase()}`);
      console.log(`${"━".repeat(70)}`);
    }

    process.stdout.write(`  🧪 ${testCase.name.padEnd(25)} `);

    try {
      const startTime = Date.now();
      const response = await fetch(FUNCTION_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(testCase.payload),
      });

      const duration = Date.now() - startTime;
      const data = await response.json();

      if (data.success) {
        const engineMatch = !testCase.expectedEngine || data.engine === testCase.expectedEngine;
        const engineInfo = testCase.expectedEngine
          ? (engineMatch ? `✓ ${data.engine}` : `✗ ${data.engine} (expected ${testCase.expectedEngine})`)
          : data.engine;

        console.log(`✅ ${duration.toString().padStart(4)}ms | ${data.style.padEnd(14)} | ${data.voiceId.padEnd(10)} | ${engineInfo}`);

        results.push({
          name: testCase.name,
          category: testCase.category,
          success: true,
          style: data.style,
          voice: data.voiceId,
          engine: data.engine,
          expectedEngine: testCase.expectedEngine,
          engineMatch,
          duration,
        });
      } else {
        console.log(`❌ Failed: ${data.error || "Unknown error"}`);
        results.push({
          name: testCase.name,
          category: testCase.category,
          success: false,
          error: data.error || "Unknown error",
        });
      }
    } catch (error) {
      console.log(`❌ Error: ${error}`);
      results.push({
        name: testCase.name,
        category: testCase.category,
        success: false,
        error: String(error),
      });
    }

    // Small delay between tests to avoid rate limiting
    await new Promise((r) => setTimeout(r, 500));
  }

  // Print summary
  console.log(`\n${"=".repeat(70)}`);
  console.log("  TEST SUMMARY");
  console.log(`${"=".repeat(70)}`);

  const passed = results.filter((r) => r.success).length;
  const failed = results.filter((r) => !r.success).length;
  const engineMismatches = results.filter((r) => r.success && r.expectedEngine && !r.engineMatch).length;

  console.log(`\n  Total Tests:      ${results.length}`);
  console.log(`  ✅ Passed:        ${passed}`);
  console.log(`  ❌ Failed:        ${failed}`);
  console.log(`  ⚠️  Engine Mismatch: ${engineMismatches}`);

  // Group by category
  const categories = [...new Set(results.map((r) => r.category))];
  console.log("\n  By Category:");
  for (const cat of categories) {
    const catResults = results.filter((r) => r.category === cat);
    const catPassed = catResults.filter((r) => r.success).length;
    console.log(`    ${cat}: ${catPassed}/${catResults.length} passed`);
  }

  // Show engine usage
  const engines = results.filter((r) => r.engine).reduce((acc, r) => {
    acc[r.engine!] = (acc[r.engine!] || 0) + 1;
    return acc;
  }, {} as { [key: string]: number });
  console.log("\n  Engine Usage:");
  for (const [engine, count] of Object.entries(engines)) {
    console.log(`    ${engine}: ${count} tests`);
  }

  // Show any failures
  if (failed > 0) {
    console.log("\n  ❌ Failed Tests:");
    for (const r of results.filter((r) => !r.success)) {
      console.log(`    - ${r.category} / ${r.name}: ${r.error}`);
    }
  }

  // Show engine mismatches (fallbacks that occurred)
  if (engineMismatches > 0) {
    console.log("\n  ⚠️  Engine Fallbacks (expected vs actual):");
    for (const r of results.filter((r) => r.success && r.expectedEngine && !r.engineMatch)) {
      console.log(`    - ${r.name}: expected ${r.expectedEngine}, got ${r.engine}`);
    }
  }

  console.log(`\n${"=".repeat(70)}`);
  console.log(passed === results.length ? "  🎉 ALL TESTS PASSED!" : "  ⚠️  SOME TESTS FAILED");
  console.log(`${"=".repeat(70)}\n`);
}

runTests();

