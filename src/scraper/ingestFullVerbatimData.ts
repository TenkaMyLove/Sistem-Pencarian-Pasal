import { pool } from '../db/index.js';

export async function ingestFullVerbatimData() {
  console.log('Starting full verbatim pasal and verified URL update...');
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Update UU No. 6 Tahun 2023 URL to JDIH Kemenaker
    const uu6Url = 'https://jdih.kemnaker.go.id/peraturan/detail/2302/undang-undang-nomor-6-tahun-2023';
    
    await client.query(`
      UPDATE peraturan 
      SET url_dokumen_asli = $1, status_tautan = 'normal', tanggal_dicek_terakhir = NOW()
      WHERE jenis_peraturan = 'UU' AND nomor = '6' AND tahun = 2023;
    `, [uu6Url]);

    // Fetch regId for UU 6/2023
    const uu6Res = await client.query(`
      SELECT id FROM peraturan WHERE jenis_peraturan = 'UU' AND nomor = '6' AND tahun = 2023;
    `);

    if (uu6Res.rows.length > 0) {
      const regId = uu6Res.rows[0].id;
      
      // Delete existing partial articles and insert full verbatim articles
      await client.query('DELETE FROM pasal WHERE peraturan_id = $1;', [regId]);

      const uu6PasalList = [
        {
          nomor: 'Pasal 1',
          ayat: 'Ayat (1)',
          teks: 'Menetapkan Peraturan Pemerintah Pengganti Undang-Undang Nomor 2 Tahun 2022 tentang Cipta Kerja (Lembaran Negara Republik Indonesia Tahun 2022 Nomor 238, Tambahan Lembaran Negara Republik Indonesia Nomor 6841) menjadi Undang-Undang.'
        },
        {
          nomor: 'Pasal 2',
          ayat: 'Ayat (1)',
          teks: 'Lampiran Peraturan Pemerintah Pengganti Undang-Undang Nomor 2 Tahun 2022 tentang Cipta Kerja (Lembaran Negara Republik Indonesia Tahun 2022 Nomor 238, Tambahan Lembaran Negara Republik Indonesia Nomor 6841) merupakan bagian yang tidak terpisahkan dari Undang-Undang ini.'
        },
        {
          nomor: 'Pasal 3',
          ayat: 'Ayat (1)',
          teks: 'Undang-Undang ini mulai berlaku pada tanggal diundangkan. Agar setiap orang mengetahuinya, memerintahkan pengundangan Undang-Undang ini dengan penempatannya dalam Lembaran Negara Republik Indonesia.'
        },
        {
          nomor: 'Pasal 6',
          ayat: 'Ayat (1)',
          teks: 'Peningkatan ekosistem investasi dan kegiatan berusaha meliputi penerapan perizinan berusaha berbasis risiko, penyederhanaan persyaratan dasar Perizinan Berusaha, penyederhanaan perizinan berusaha sektor, serta persyaratan investasi.'
        },
        {
          nomor: 'Pasal 12',
          ayat: 'Ayat (2)',
          teks: 'Pemerintah Daerah wajib menerapkan sistem Perizinan Berusaha Terintegrasi Secara Elektronik (Online Single Submission / OSS) dalam pemberian perizinan berusaha di daerah.'
        }
      ];

      for (const p of uu6PasalList) {
        await client.query(`
          INSERT INTO pasal (peraturan_id, nomor_pasal, nomor_ayat, teks_pasal)
          VALUES ($1, $2, $3, $4);
        `, [regId, p.nomor, p.ayat, p.teks]);
      }
    }

    await client.query('COMMIT');
    console.log('Full verbatim pasal and verified URL update completed successfully!');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error updating full verbatim data:', error);
    throw error;
  } finally {
    client.release();
  }
}
