import pg from 'pg';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: resolve(__dirname, '.env') });

const { Pool } = pg;

const pool = new Pool({
  host: process.env.PGHOST || 'localhost',
  port: parseInt(process.env.PGPORT || '5432', 10),
  database: process.env.PGDATABASE || 'p3h_kemenkum_kalsel',
  user: process.env.PGUSER || 'postgres',
  password: process.env.PGPASSWORD || '',
});

async function main() {
  try {
    // Check columns of jadwal table
    const cols = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'jadwal_rapat_harmonisasi'
      ORDER BY ordinal_position;
    `);
    console.log('jadwal_rapat_harmonisasi columns:');
    cols.rows.forEach(r => console.log(' -', r.column_name, ':', r.data_type));

    // Check if tentang exists, if not add it
    const hasTentang = cols.rows.some(r => r.column_name === 'tentang');
    if (!hasTentang) {
      console.log('\ntentang column missing — adding now...');
      await pool.query(`ALTER TABLE jadwal_rapat_harmonisasi ADD COLUMN tentang TEXT NOT NULL DEFAULT ''`);
      console.log('OK: tentang added.');
    } else {
      console.log('\ntentang already exists.');
    }

    // Count regulations
    const cnt = await pool.query('SELECT COUNT(*) FROM peraturan');
    console.log(`\nTotal peraturan: ${cnt.rows[0].count}`);
    const psl = await pool.query('SELECT COUNT(*) FROM pasal');
    console.log(`Total pasal: ${psl.rows[0].count}`);
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    await pool.end();
  }
}

main();
