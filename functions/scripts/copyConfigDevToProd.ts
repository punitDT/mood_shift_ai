/**
 * Script to copy Firestore config from dev to prod project
 * 
 * This script reads all documents from the 'config' collection in the dev project
 * and writes them to the prod project.
 * 
 * Usage:
 *   cd functions
 *   npx ts-node scripts/copyConfigDevToProd.ts
 * 
 * Prerequisites:
 *   - You must be logged in with Firebase CLI: firebase login
 *   - Your account must have access to both projects
 */

import * as admin from "firebase-admin";

const DEV_PROJECT_ID = "mood-shift-ai-dev";
const PROD_PROJECT_ID = "mood-shift-ai";
const CONFIG_COLLECTION = "config";

// Known config documents to copy
const CONFIG_DOCS = ["llm", "prompts", "polly", "prosody", "voices"];

// Initialize Firebase Admin apps for both projects
const devApp = admin.initializeApp(
  { projectId: DEV_PROJECT_ID },
  "dev"
);

const prodApp = admin.initializeApp(
  { projectId: PROD_PROJECT_ID },
  "prod"
);

const devDb = admin.firestore(devApp);
const prodDb = admin.firestore(prodApp);

interface CopyResult {
  docId: string;
  success: boolean;
  error?: string;
}

async function copyDocument(docId: string): Promise<CopyResult> {
  try {
    // Read from dev
    const devDoc = await devDb.collection(CONFIG_COLLECTION).doc(docId).get();
    
    if (!devDoc.exists) {
      return { docId, success: false, error: "Document not found in dev" };
    }
    
    const data = devDoc.data();
    
    // Write to prod
    await prodDb.collection(CONFIG_COLLECTION).doc(docId).set(data!);
    
    return { docId, success: true };
  } catch (error) {
    return { docId, success: false, error: String(error) };
  }
}

async function main() {
  console.log("=".repeat(60));
  console.log("  COPY FIRESTORE CONFIG: DEV → PROD");
  console.log("=".repeat(60));
  console.log("");
  console.log(`  Source:      ${DEV_PROJECT_ID}`);
  console.log(`  Destination: ${PROD_PROJECT_ID}`);
  console.log(`  Collection:  ${CONFIG_COLLECTION}`);
  console.log("");
  console.log("-".repeat(60));
  
  const results: CopyResult[] = [];
  
  for (const docId of CONFIG_DOCS) {
    process.stdout.write(`  📄 Copying '${docId}'... `);
    const result = await copyDocument(docId);
    results.push(result);
    
    if (result.success) {
      console.log("✅ Done");
    } else {
      console.log(`❌ Failed: ${result.error}`);
    }
  }
  
  // Also check for any additional documents in the config collection
  console.log("");
  console.log("-".repeat(60));
  console.log("  Checking for additional config documents...");
  
  const allDevDocs = await devDb.collection(CONFIG_COLLECTION).listDocuments();
  const additionalDocs = allDevDocs
    .map(doc => doc.id)
    .filter(id => !CONFIG_DOCS.includes(id));
  
  if (additionalDocs.length > 0) {
    console.log(`  Found ${additionalDocs.length} additional document(s):`);
    for (const docId of additionalDocs) {
      process.stdout.write(`  📄 Copying '${docId}'... `);
      const result = await copyDocument(docId);
      results.push(result);
      
      if (result.success) {
        console.log("✅ Done");
      } else {
        console.log(`❌ Failed: ${result.error}`);
      }
    }
  } else {
    console.log("  No additional documents found.");
  }
  
  // Summary
  console.log("");
  console.log("=".repeat(60));
  console.log("  SUMMARY");
  console.log("=".repeat(60));
  
  const successful = results.filter(r => r.success).length;
  const failed = results.filter(r => !r.success).length;
  
  console.log(`  ✅ Successful: ${successful}`);
  console.log(`  ❌ Failed:     ${failed}`);
  
  if (failed > 0) {
    console.log("");
    console.log("  Failed documents:");
    results.filter(r => !r.success).forEach(r => {
      console.log(`    - ${r.docId}: ${r.error}`);
    });
  }
  
  console.log("");
  console.log("=".repeat(60));
  
  // Cleanup
  await devApp.delete();
  await prodApp.delete();
  
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});

