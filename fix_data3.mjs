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

async function fix(client, label, jenis, nomor, tahun, newUrl) {
  const r = await client.query(
    `UPDATE peraturan SET url_dokumen_asli = $1, tanggal_dicek_terakhir = NOW()
     WHERE jenis_peraturan = $2 AND nomor = $3 AND tahun = $4
     RETURNING id, judul`,
    [newUrl, jenis, nomor, tahun]
  );
  if (r.rows.length > 0) {
    console.log(`FIXED ${label}: ${r.rows[0].judul.substring(0, 70)}`);
    console.log(`  -> ${newUrl}`);
  } else {
    console.log(`NOT FOUND: ${label}`);
  }
}

async function main() {
  const client = await pool.connect();
  try {
    // Fix URLs that were verified wrong and correct ID was found
    await fix(client, 'PP 43/2014', 'PP', '43', 2014,
      'https://peraturan.bpk.go.id/Details/5482/pp-no-43-tahun-2014');

    await fix(client, 'UU 12/2011', 'UU', '12', 2011,
      'https://peraturan.bpk.go.id/Details/39188/uu-no-12-tahun-2011');

    // Mark the 4 PPs with wrong IDs as UNVERIFIED
    const wrongPPs = [
      { jenis: 'PP', nomor: '16', tahun: 2018 },
      { jenis: 'PP', nomor: '12', tahun: 2017 },
      { jenis: 'PP', nomor: '18', tahun: 2016 },
      { jenis: 'PP', nomor: '17', tahun: 2018 },
    ];
    for (const pp of wrongPPs) {
      const r = await client.query(
        `UPDATE peraturan SET status_tautan = 'perlu_verifikasi', tanggal_dicek_terakhir = NOW()
         WHERE jenis_peraturan = $1 AND nomor = $2 AND tahun = $3
         RETURNING id, judul, url_dokumen_asli`,
        [pp.jenis, pp.nomor, pp.tahun]
      );
      if (r.rows.length > 0) {
        console.log(`FLAGGED (URL salah): ${pp.jenis} ${pp.nomor}/${pp.tahun}`);
        console.log(`  Salah: ${r.rows[0].url_dokumen_asli}`);
      }
    }

    // Also flag Perda Tapin 7/2021 - BPK ID shows wrong subject (Perparkiran not Ketertiban Umum)
    const r = await client.query(
      `UPDATE peraturan SET status_tautan = 'perlu_verifikasi', tanggal_dicek_terakhir = NOW()
       WHERE jenis_peraturan = 'Perda' AND nomor = '7' AND tahun = 2021 AND wilayah LIKE '%Tapin%'
       RETURNING id, judul`,
    );
    if (r.rows.length > 0) {
      console.log(`CLEARED (ID menunjuk Perda Perparkiran): ${r.rows[0].judul.substring(0, 70)}`);
    }

    console.log('\nDone.');
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    client.release();
    await pool.end();
  }
}

main();
