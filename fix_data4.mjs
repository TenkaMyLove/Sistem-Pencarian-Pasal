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

const fixes = [
  {
    label: 'Perda Tapin 7/2021 (Ketertiban Umum)',
    jenis: 'Perda', nomor: '7', tahun: 2021,
    wilayahLike: '%Tapin%',
    url: 'https://peraturan.bpk.go.id/Details/174575/perda-kab-tapin-no-09-tahun-2021',
  },
  {
    label: 'PP 18/2016 (Perangkat Daerah)',
    jenis: 'PP', nomor: '18', tahun: 2016,
    url: 'https://peraturan.bpk.go.id/Details/5739/pp-no-18-tahun-2016',
  },
  {
    label: 'PP 17/2018 (Kecamatan)',
    jenis: 'PP', nomor: '17', tahun: 2018,
    url: 'https://peraturan.bpk.go.id/Details/77921/pp-no-17-tahun-2018',
  },
  {
    label: 'PP 16/2018 (Satpol PP)',
    jenis: 'PP', nomor: '16', tahun: 2018,
    url: 'https://peraturan.bpk.go.id/Details/77284/pp-no-16-tahun-2018',
  },
  {
    label: 'PP 12/2017 (Pembinaan Pengawasan Pemda)',
    jenis: 'PP', nomor: '12', tahun: 2017,
    url: 'https://peraturan.bpk.go.id/Details/5832/pp-no-12-tahun-2017',
  },
];

async function main() {
  const client = await pool.connect();
  try {
    for (const f of fixes) {
      let q, params;
      if (f.wilayahLike) {
        q = `UPDATE peraturan SET url_dokumen_asli = $1, status_tautan = 'normal', tanggal_dicek_terakhir = NOW()
             WHERE jenis_peraturan = $2 AND nomor = $3 AND tahun = $4 AND wilayah LIKE $5
             RETURNING id, judul`;
        params = [f.url, f.jenis, f.nomor, f.tahun, f.wilayahLike];
      } else {
        q = `UPDATE peraturan SET url_dokumen_asli = $1, status_tautan = 'normal', tanggal_dicek_terakhir = NOW()
             WHERE jenis_peraturan = $2 AND nomor = $3 AND tahun = $4
             RETURNING id, judul`;
        params = [f.url, f.jenis, f.nomor, f.tahun];
      }
      const r = await client.query(q, params);
      if (r.rows.length > 0) {
        console.log(`UPDATED [${f.label}]`);
        console.log(`  -> ${f.url}`);
      } else {
        console.log(`NOT FOUND: ${f.label}`);
      }
    }
    console.log('\nAll done.');
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    client.release();
    await pool.end();
  }
}

main();
