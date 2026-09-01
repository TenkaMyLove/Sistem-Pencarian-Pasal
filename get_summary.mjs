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
    const res = await client.query(`
      SELECT p.id, p.jenis_peraturan, p.nomor, p.tahun, p.judul, p.wilayah, p.sektor, p.url_dokumen_asli, COUNT(ps.id) as jumlah_pasal
      FROM peraturan p
      LEFT JOIN pasal ps ON ps.peraturan_id = p.id
      GROUP BY p.id
      ORDER BY p.sektor, p.jenis_peraturan, p.tahun, CAST(p.nomor AS INTEGER) NULLS LAST;
    `);
    
    console.log(JSON.stringify(res.rows, null, 2));
  } catch (e) {
    console.error(e);
  } finally {
    client.release();
    await pool.end();
  }
}

main();
