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
  const client = await pool.connect();
  try {
    // 1. Delete Perda Kalsel 7/2019 (data tidak valid - halaman resmi berbeda)
    const del = await client.query(`
      DELETE FROM peraturan
      WHERE jenis_peraturan = 'Perda' AND nomor = '7' AND tahun = 2019
        AND wilayah = 'Provinsi Kalimantan Selatan'
      RETURNING id, judul;
    `);
    if (del.rows.length > 0) {
      console.log(`DELETED: ID ${del.rows[0].id} - ${del.rows[0].judul}`);
    } else {
      console.log('Perda Kalsel 7/2019 not found (already removed or different key)');
    }

    // 2. Fix Perppu 2/2022 dead link in status_detail_json across all peraturan
    const fixPerppu = await client.query(`
      UPDATE peraturan
      SET status_detail_json = REPLACE(
        status_detail_json::text,
        'https://peraturan.bpk.go.id/Details/238128/perpu-no-2-tahun-2022',
        'https://peraturan.bpk.go.id/Details/234926/perpu-no-2-tahun-2022'
      )::jsonb,
      url_dokumen_asli = 'https://peraturan.bpk.go.id/Details/234926/perpu-no-2-tahun-2022'
      WHERE jenis_peraturan = 'Perpu' AND nomor = '2' AND tahun = 2022
      RETURNING id, judul;
    `);
    if (fixPerppu.rows.length > 0) {
      console.log(`FIXED Perppu 2/2022 URL: ${fixPerppu.rows[0].judul}`);
    }

    // Also fix any references to the dead link in OTHER peraturan status_detail_json
    const fixRefs = await client.query(`
      UPDATE peraturan
      SET status_detail_json = REPLACE(
        status_detail_json::text,
        'https://peraturan.bpk.go.id/Details/238128/perpu-no-2-tahun-2022',
        'https://peraturan.bpk.go.id/Details/234926/perpu-no-2-tahun-2022'
      )::jsonb
      WHERE status_detail_json::text LIKE '%238128%'
      RETURNING id, judul;
    `);
    fixRefs.rows.forEach(r => console.log(`  Fixed ref in: ${r.judul}`));

    // 3. Fix UU 17/2023 Kesehatan wrong URL
    const fixUU17 = await client.query(`
      UPDATE peraturan
      SET url_dokumen_asli = 'https://peraturan.bpk.go.id/Details/258028/uu-no-17-tahun-2023'
      WHERE jenis_peraturan = 'UU' AND nomor = '17' AND tahun = 2023
      RETURNING id, judul, url_dokumen_asli;
    `);
    if (fixUU17.rows.length > 0) {
      console.log(`FIXED UU 17/2023 URL to: ${fixUU17.rows[0].url_dokumen_asli}`);
    } else {
      console.log('UU 17/2023 not found');
    }

    // Count remaining
    const cnt = await client.query('SELECT COUNT(*) FROM peraturan');
    console.log(`\nTotal peraturan remaining: ${cnt.rows[0].count}`);

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    client.release();
    await pool.end();
  }
}

main();
