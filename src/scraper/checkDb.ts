import { pool } from '../db/index.js';

const client = await pool.connect();
try {
  const r1 = await client.query(
    `SELECT id, jenis_peraturan, nomor, tahun, judul, url_dokumen_asli
     FROM peraturan WHERE tahun=2019 AND nomor='7' AND wilayah ILIKE '%Kalsel%' OR
     (tahun=2019 AND nomor='7' AND judul ILIKE '%Jasa Konstruksi%') LIMIT 5`
  );
  console.log('Perda Kalsel 7/2019 candidates:', r1.rows);

  // Also check count of new regulations
  const r2 = await client.query(
    `SELECT COUNT(*) as total FROM peraturan`
  );
  console.log('Total peraturan in DB:', r2.rows[0].total);

  // Sample of new ones added
  const r3 = await client.query(
    `SELECT jenis_peraturan, nomor, tahun, judul, url_dokumen_asli FROM peraturan
     WHERE tahun IN (2020, 2021, 2022, 2023, 2024, 2026) ORDER BY tahun DESC, nomor LIMIT 25`
  );
  console.log('\nNewly added regulations:');
  r3.rows.forEach(r => console.log(`  ${r.jenis_peraturan} ${r.nomor}/${r.tahun} — ${r.url_dokumen_asli}`));
} finally {
  client.release();
  process.exit(0);
}
