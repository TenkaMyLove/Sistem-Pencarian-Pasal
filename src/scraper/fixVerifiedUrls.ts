import { pool } from '../db/index.js';

async function fixVerifiedUrls() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Fix Perppu No. 2 Tahun 2022 URL in mencabut array of UU 6/2023
    // Real URL provided by user: https://jdih.kemnaker.go.id/peraturan/detail/2286/perppu-nomor-2-tahun-2022
    await client.query(`
      UPDATE peraturan
      SET status_detail_json = jsonb_set(
        status_detail_json,
        '{mencabut,0,url}',
        '"https://jdih.kemnaker.go.id/peraturan/detail/2286/perppu-nomor-2-tahun-2022"'
      )
      WHERE jenis_peraturan = 'UU' AND nomor = '6' AND tahun = 2023;
    `);

    // Verify
    const res = await client.query(`
      SELECT status_detail_json->'mencabut' AS mencabut
      FROM peraturan
      WHERE jenis_peraturan = 'UU' AND nomor = '6' AND tahun = 2023;
    `);
    console.log('Updated mencabut:', JSON.stringify(res.rows[0].mencabut, null, 2));

    await client.query('COMMIT');
    console.log('URL fix applied successfully.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error:', err);
  } finally {
    client.release();
    process.exit(0);
  }
}

fixVerifiedUrls();
