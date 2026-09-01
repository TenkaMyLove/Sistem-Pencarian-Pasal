import { pool } from '../db/index.js';

const client = await pool.connect();
try {
  await client.query('BEGIN');

  // Fix 1: Perda Kalsel 7/2019 — update to BPK URL
  const r1 = await client.query(
    `UPDATE peraturan
     SET url_dokumen_asli = 'https://peraturan.bpk.go.id/Details/122053/perda-prov-kalimantan-selatan-no-7-tahun-2019',
         status_tautan = 'normal',
         tanggal_dicek_terakhir = NOW()
     WHERE jenis_peraturan = 'Perda' AND nomor = '7' AND tahun = 2019
       AND judul ILIKE '%Jasa Konstruksi%'`
  );
  console.log(`Perda Kalsel 7/2019 URL fixed: ${r1.rowCount} row(s) updated`);

  // Fix 2: UU 6/2023 — update to BPK URL (user-provided)
  const r2 = await client.query(
    `UPDATE peraturan
     SET url_dokumen_asli = 'https://peraturan.bpk.go.id/Details/246523/uu-no-6-tahun-2023',
         status_tautan = 'normal',
         tanggal_dicek_terakhir = NOW()
     WHERE jenis_peraturan = 'UU' AND nomor = '6' AND tahun = 2023`
  );
  console.log(`UU 6/2023 URL fixed: ${r2.rowCount} row(s) updated`);

  await client.query('COMMIT');
  console.log('\nAll URL fixes committed.');
} catch (e) {
  await client.query('ROLLBACK');
  console.error('Error:', e);
} finally {
  client.release();
  process.exit(0);
}
