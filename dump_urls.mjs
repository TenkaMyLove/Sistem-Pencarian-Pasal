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
  const rows = await client.query(`
    SELECT id, jenis_peraturan, nomor, tahun, judul, url_dokumen_asli, wilayah, sektor
    FROM peraturan ORDER BY jenis_peraturan, tahun, CAST(nomor AS INTEGER) NULLS LAST;
  `);
  client.release();
  await pool.end();

  // Print as JSON for easy reading
  const data = rows.rows.map(r => ({
    id: r.id,
    key: `${r.jenis_peraturan} No.${r.nomor}/${r.tahun}`,
    judul_db: r.judul,
    wilayah: r.wilayah,
    url: r.url_dokumen_asli,
  }));

  console.log(JSON.stringify(data, null, 2));
}

main().catch(console.error);
