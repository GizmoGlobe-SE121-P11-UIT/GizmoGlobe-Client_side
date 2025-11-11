/**
 * One-off importer: reads Excel survey responses and writes to Firestore.
 *
 * Usage:
 *   cd functions
 *   npm i
 *   npm run import:survey
 *
 * Notes:
 * - Adjust SOURCE_PATH if your Excel file moves.
 * - Writes to 'surveyResponses_raw' with a normalized structure:
 *     { submittedAt, channel: 'form', version: 'v1', raw: { column: value } }
 */
const path = require('path');
const fs = require('fs');
const admin = require('firebase-admin');
const XLSX = require('xlsx');

// Initialize Admin SDK if not already initialized (when running outside CF env)
try {
  admin.app();
} catch (e) {
  const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const usingEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;
  if (credPath && fs.existsSync(credPath)) {
    const svc = JSON.parse(fs.readFileSync(credPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(svc),
      projectId: svc.project_id,
    });
    console.log('Initialized Firebase Admin with service account from GOOGLE_APPLICATION_CREDENTIALS');
  } else if (usingEmulator) {
    // Emulator does not require credentials
    admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'demo-project' });
    console.log('Initialized Firebase Admin for Firestore Emulator');
  } else {
    // Fallback to ADC (gcloud auth application-default login)
    admin.initializeApp();
    console.log('Initialized Firebase Admin with Application Default Credentials');
  }
}

const db = admin.firestore();

// Excel file inside the Flutter repo
const SOURCE_PATH = path.resolve(__dirname, '../../lib/data/Survey.xlsx');
const TARGET_COL = db.collection('surveyResponses_raw');

function readWorksheet(filePath) {
  const workbook = XLSX.readFile(filePath);
  const sheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[sheetName];
  // Convert to JSON, preserving headers
  const json = XLSX.utils.sheet_to_json(sheet, { defval: null });
  return json;
}

async function main() {
  console.log('Importing survey from:', SOURCE_PATH);
  const rows = readWorksheet(SOURCE_PATH);
  console.log(`Found ${rows.length} rows`);

  const batchSize = 400;
  let index = 0;
  let imported = 0;

  while (index < rows.length) {
    const slice = rows.slice(index, index + batchSize);
    const batch = db.batch();

    slice.forEach((row) => {
      // Attempt to parse a timestamp column if it exists (common in Google Forms)
      // Fallback to now
      let submittedAt = new Date();
      const tsCandidate =
        row['Timestamp'] ||
        row['Thời gian'] ||
        row['Submission Time'] ||
        row['submittedAt'];
      if (tsCandidate) {
        const parsed = new Date(tsCandidate);
        if (!isNaN(parsed.getTime())) {
          submittedAt = parsed;
        }
      }

      const docRef = TARGET_COL.doc();
      batch.set(docRef, {
        submittedAt: admin.firestore.Timestamp.fromDate(submittedAt),
        channel: 'form',
        version: 'v1',
        raw: row,
      });
    });

    await batch.commit();
    imported += slice.length;
    index += batchSize;
    console.log(`Imported ${imported}/${rows.length}`);
  }

  console.log('Import complete.');
}

main().catch((err) => {
  console.error('Importer failed:', err);
  process.exit(1);
});


