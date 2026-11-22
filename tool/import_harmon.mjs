// Run as a Firestore administrator. Writes are atomic and seed records are
// create-only, so rerunning the import cannot overwrite edited records.
import { execFileSync } from 'node:child_process';
import { readFile } from 'node:fs/promises';

const [project, team, file] = process.argv.slice(2);
if (!project || !/^[a-z0-9-]+$/.test(project) ||
    !team || !/^[A-Za-z0-9_-]{1,128}$/.test(team) || !file) {
  throw new Error('Usage: node tool/import_harmon.mjs PROJECT TEAM_ID EXPORT_JSON');
}

const seed = JSON.parse(await readFile(file, 'utf8'));
function value(input) {
  if (typeof input === 'string') return { stringValue: input };
  if (typeof input === 'boolean') return { booleanValue: input };
  if (Number.isInteger(input)) return { integerValue: String(input) };
  if (Array.isArray(input)) return { arrayValue: { values: input.map(value) } };
  if (input && typeof input === 'object') return { mapValue: { fields: fields(input) } };
  throw new Error('Unexpected value in Harmon seed.');
}
function fields(record) {
  return Object.fromEntries(Object.entries(record).map(([key, input]) => [key, value(input)]));
}

const database = `projects/${project}/databases/(default)`;
const teamPath = `${database}/documents/teams/${team}`;
const writes = [
  {
    update: { name: teamPath, fields: fields({ activeCaseId: seed.activeCaseId }) },
    updateMask: { fieldPaths: ['activeCaseId'] },
  },
  ...Object.entries(seed.documents).map(([path, record]) => {
    if (!/^(?:[A-Za-z0-9_-]+\/)+[A-Za-z0-9_-]+$/.test(path) ||
        path.split('/').length % 2 !== 0) {
      throw new Error('Invalid seed document path.');
    }
    return {
      update: { name: `${teamPath}/${path}`, fields: fields(record) },
      currentDocument: { exists: false },
    };
  }),
];

const emulator = process.env.FIRESTORE_EMULATOR_HOST;
if (emulator && !project.startsWith('demo-')) {
  throw new Error('Use a demo-* project with the emulator.');
}
const host = emulator ? `http://${emulator}` : 'https://firestore.googleapis.com';
const token = emulator ? 'owner' : execFileSync(
  'gcloud', ['auth', 'application-default', 'print-access-token'],
  { encoding: 'utf8' },
).trim();
const response = await fetch(`${host}/v1/${database}/documents:commit`, {
  method: 'POST',
  headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({ writes }),
});
if (!response.ok) throw new Error(await response.text());
console.log(`Seeded ${writes.length - 1} records for ${project}/${team}.`);
