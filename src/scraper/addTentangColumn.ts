import { query } from '../db/index.js';

async function run() {
  await query(`ALTER TABLE jadwal_rapat_harmonisasi ADD COLUMN IF NOT EXISTS tentang TEXT NOT NULL DEFAULT ''`);
  console.log('Column tentang added (or already exists).');
  process.exit(0);
}

run().catch(e => { console.error(e.message); process.exit(1); });
