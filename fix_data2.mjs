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
    // 1. Re-insert Perda Kalsel 7/2019 with CORRECT data from JDIH Kalsel
    const exists = await client.query(
      `SELECT id FROM peraturan WHERE jenis_peraturan='Perda' AND nomor='7' AND tahun=2019 AND wilayah='Provinsi Kalimantan Selatan'`
    );
    if (exists.rows.length > 0) {
      // Update existing if somehow there
      await client.query(`
        UPDATE peraturan SET
          judul = 'Peraturan Daerah Provinsi Kalimantan Selatan Nomor 7 Tahun 2019 tentang Penyelenggaraan Jasa Konstruksi',
          status_detail = 'Ditetapkan 27 Agustus 2019; Sumber: Lembaran Daerah Provinsi Kalimantan Selatan Tahun 2019 Nomor 7',
          sektor = 'Investasi/Perizinan',
          url_dokumen_asli = 'https://jdih.kalselprov.go.id/index.php/dokumen/view?id=1482',
          tanggal_dicek_terakhir = NOW()
        WHERE jenis_peraturan='Perda' AND nomor='7' AND tahun=2019 AND wilayah='Provinsi Kalimantan Selatan'
      `);
      console.log('UPDATED: Perda Kalsel 7/2019');
    } else {
      const res = await client.query(`
        INSERT INTO peraturan (jenis_peraturan, nomor, tahun, judul, status, status_detail, status_detail_json, wilayah, sektor, url_dokumen_asli, status_tautan, tanggal_diambil, tanggal_dicek_terakhir)
        VALUES ('Perda', '7', 2019,
          'Peraturan Daerah Provinsi Kalimantan Selatan Nomor 7 Tahun 2019 tentang Penyelenggaraan Jasa Konstruksi',
          'berlaku',
          'Ditetapkan 27 Agustus 2019; Sumber: Lembaran Daerah Provinsi Kalimantan Selatan Tahun 2019 Nomor 7',
          '{}',
          'Provinsi Kalimantan Selatan',
          'Investasi/Perizinan',
          'https://jdih.kalselprov.go.id/index.php/dokumen/view?id=1482',
          'normal', NOW(), NOW())
        RETURNING id;
      `);
      const regId = res.rows[0].id;
      await client.query(`INSERT INTO pasal (peraturan_id, nomor_pasal, nomor_ayat, teks_pasal) VALUES ($1, 'Pasal 1', 'Angka 1', 'Jasa Konstruksi adalah layanan jasa konsultansi konstruksi dan/atau pekerjaan konstruksi.')`, [regId]);
      await client.query(`INSERT INTO pasal (peraturan_id, nomor_pasal, nomor_ayat, teks_pasal) VALUES ($1, 'Pasal 3', 'Ayat (1)', 'Pemerintah Daerah Provinsi berwenang melakukan penyelenggaraan jasa konstruksi di wilayah Provinsi Kalimantan Selatan.')`, [regId]);
      console.log(`INSERTED: Perda Kalsel 7/2019 (ID ${regId})`);
    }

    // 2. Fix PP 5/2021 URL
    const fixPP5 = await client.query(`
      UPDATE peraturan
      SET url_dokumen_asli = 'https://peraturan.bpk.go.id/Details/161835/pp-no-5tahun-2021',
          tanggal_dicek_terakhir = NOW()
      WHERE jenis_peraturan = 'PP' AND nomor = '5' AND tahun = 2021
      RETURNING id, judul;
    `);
    if (fixPP5.rows.length > 0) {
      console.log(`FIXED PP 5/2021 URL: ${fixPP5.rows[0].judul}`);
    } else {
      console.log('PP 5/2021 not found in DB');
    }

    const cnt = await client.query('SELECT COUNT(*) FROM peraturan');
    console.log(`\nTotal peraturan: ${cnt.rows[0].count}`);
    const psl = await client.query('SELECT COUNT(*) FROM pasal');
    console.log(`Total pasal: ${psl.rows[0].count}`);

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    client.release();
    await pool.end();
  }
}

main();
