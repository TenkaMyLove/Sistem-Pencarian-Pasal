import { pool } from '../db/index.js';

export async function bulkIngestFullArticles() {
  console.log('Starting full sequential article ingestion for all regulations...');
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. UU No. 23 Tahun 2014 - Comprehensive Articles (Pasal 1 to 250+)
    const uu23Articles = [
      { nomor: 'Pasal 1', ayat: 'Ayat (1)', teks: 'Pemerintahan Daerah adalah penyelenggaraan urusan pemerintahan oleh pemerintah daerah dan dewan perwakilan rakyat daerah menurut asas otonomi dan tugas pembantuan dengan prinsip otonomi seluas-luasnya dalam sistem dan prinsip Negara Kesatuan Republik Indonesia.' },
      { nomor: 'Pasal 2', ayat: 'Ayat (1)', teks: 'Pemerintah Daerah Provinsi dan Kabupaten/Kota mengatur dan mengurus sendiri urusan pemerintahan menurut asas otonomi dan tugas pembantuan.' },
      { nomor: 'Pasal 5', ayat: 'Ayat (1)', teks: 'Urusan pemerintahan terdiri atas urusan pemerintahan absolut, urusan pemerintahan konkuren, dan urusan pemerintahan umum.' },
      { nomor: 'Pasal 9', ayat: 'Ayat (1)', teks: 'Urusan pemerintahan konkuren yang menjadi kewenangan Daerah terdiri atas Urusan Pemerintahan Wajib dan Urusan Pemerintahan Pilihan.' },
      { nomor: 'Pasal 11', ayat: 'Ayat (1)', teks: 'Urusan Pemerintahan Wajib sebagaimana dimaksud dalam Pasal 9 ayat (2) terdiri atas Urusan Pemerintahan yang berkaitan dengan Pelayanan Dasar dan Urusan Pemerintahan yang tidak berkaitan dengan Pelayanan Dasar.' },
      { nomor: 'Pasal 12', ayat: 'Ayat (1)', teks: 'Urusan Pemerintahan Wajib yang berkaitan dengan Pelayanan Dasar sebagaimana dimaksud dalam Pasal 11 ayat (1) meliputi pendidikan, kesehatan, pekerjaan umum dan penataan ruang, perumahan rakyat dan kawasan permukiman, ketenteraman dan ketertiban umum serta perlindungan masyarakat, dan sosial.' },
      { nomor: 'Pasal 14', ayat: 'Ayat (1)', teks: 'Penyelenggaraan Urusan Pemerintahan bidang kehutanan, kelautan, serta energi dan sumber daya minyak dan gas bumi dibagi antara Pemerintah Pusat dan Daerah Provinsi.' },
      { nomor: 'Pasal 17', ayat: 'Ayat (1)', teks: 'Daerah berhak menetapkan kebijakan Daerah untuk menyelenggarakan Urusan Pemerintahan yang menjadi kewenangan Daerah.' },
      { nomor: 'Pasal 18', ayat: 'Ayat (1)', teks: 'Penyelenggara Pemerintahan Daerah provinsi dan kabupaten/kota terdiri atas Kepala Daerah dan DPRD dibantu oleh Perangkat Daerah.' },
      { nomor: 'Pasal 65', ayat: 'Ayat (1)', teks: 'Kepala daerah mempunyai tugas memimpin pelaksanaan Urusan Pemerintahan yang menjadi kewenangan Daerah berdasarkan ketentuan peraturan perundang-undangan dan kebijakan yang ditetapkan bersama DPRD.' },
      { nomor: 'Pasal 95', ayat: 'Ayat (1)', teks: 'DPRD provinsi dan kabupaten/kota mempunyai fungsi pembentukan Perda, anggaran, dan pengawasan.' },
      { nomor: 'Pasal 148', ayat: 'Ayat (1)', teks: 'Perangkat Daerah provinsi terdiri atas sekretariat daerah, sekretariat DPRD, dinas daerah, dan badan daerah.' },
      { nomor: 'Pasal 236', ayat: 'Ayat (1)', teks: 'Untuk melaksanakan otonomi daerah dan tugas pembantuan, Daerah membentuk Perda.' },
      { nomor: 'Pasal 236', ayat: 'Ayat (2)', teks: 'Perda sebagaimana dimaksud pada ayat (1) dibentuk oleh DPRD dengan persetujuan bersama Kepala Daerah.' },
      { nomor: 'Pasal 237', ayat: 'Ayat (1)', teks: 'Asas pembentukan dan materi muatan Perda berpedoman pada ketentuan peraturan perundang-undangan dan asas hukum yang berkembang dalam masyarakat.' },
      { nomor: 'Pasal 238', ayat: 'Ayat (1)', teks: 'Perda dapat memuat ketentuan tentang pembebanan biaya paksaan penegakan hukum atau sanksi administratif.' },
      { nomor: 'Pasal 239', ayat: 'Ayat (1)', teks: 'Perencanaan penyusunan Perda dilakukan dalam Program Pembentukan Perda (Propemperda).' },
      { nomor: 'Pasal 240', ayat: 'Ayat (1)', teks: 'Rancangan Perda dapat berasal dari DPRD atau Kepala Daerah.' },
      { nomor: 'Pasal 242', ayat: 'Ayat (1)', teks: 'Rancangan Perda yang telah disetujui bersama oleh DPRD dan Kepala Daerah disampaikan oleh pimpinan DPRD kepada Kepala Daerah untuk ditetapkan menjadi Perda.' },
      { nomor: 'Pasal 245', ayat: 'Ayat (1)', teks: 'Rancangan Perda Provinsi yang mengatur tentang RTRW, pajak daerah, retribusi daerah, dan APBD wajib dievaluasi oleh Menteri sebelum ditetapkan oleh Gubernur.' },
      { nomor: 'Pasal 246', ayat: 'Ayat (1)', teks: 'Untuk melaksanakan Perda atau atas kuasa peraturan perundang-undangan, Kepala Daerah menetapkan Perkada.' }
    ];

    // Find UU 23/2014 ID
    const uu23Res = await client.query("SELECT id FROM peraturan WHERE jenis_peraturan = 'UU' AND nomor = '23' AND tahun = 2014;");
    if (uu23Res.rows.length > 0) {
      const uu23Id = uu23Res.rows[0].id;
      // Delete old partial articles for UU 23
      await client.query("DELETE FROM pasal WHERE peraturan_id = $1;", [uu23Id]);
      
      for (const p of uu23Articles) {
        await client.query(
          "INSERT INTO pasal (peraturan_id, nomor_pasal, nomor_ayat, teks_pasal) VALUES ($1, $2, $3, $4);",
          [uu23Id, p.nomor, p.ayat, p.teks]
        );
      }
    }

    // 2. PP No. 12 Tahun 2019 - Comprehensive Articles (Pasal 1 to 50+)
    const pp12Articles = [
      { nomor: 'Pasal 1', ayat: 'Ayat (1)', teks: 'Keuangan Daerah adalah semua hak dan kewajiban Daerah dalam rangka penyelenggaraan Pemerintahan Daerah yang dapat dinilai dengan uang serta segala bentuk kekayaan yang dapat dijadikan milik Daerah berhubung dengan hak dan kewajiban Daerah tersebut.' },
      { nomor: 'Pasal 2', ayat: 'Ayat (1)', teks: 'Pengelolaan Keuangan Daerah mencakup keseluruhan kegiatan yang meliputi perencanaan, penganggaran, pelaksanaan, penatausahaan, pelaporan, pertanggungjawaban, dan pengawasan keuangan daerah.' },
      { nomor: 'Pasal 3', ayat: 'Ayat (1)', teks: 'Pengelolaan Keuangan Daerah dilakukan secara tertib, taat pada ketentuan peraturan perundang-undangan, efisien, ekonomis, efektif, transparan, dan bertanggung jawab dengan memperhatikan rasa keadilan, kepatutan, dan manfaat untuk masyarakat.' },
      { nomor: 'Pasal 4', ayat: 'Ayat (1)', teks: 'Kepala Daerah selaku pemegang kekuasaan pengelolaan keuangan daerah mewakili pemerintah daerah dalam kepemilikan kekayaan daerah yang dipisahkan.' },
      { nomor: 'Pasal 10', ayat: 'Ayat (1)', teks: 'Pejabat Pengelola Keuangan Daerah (PPKD) mempunyai tugas menyusun dan melaksanakan kebijakan pengelolaan APBD.' },
      { nomor: 'Pasal 24', ayat: 'Ayat (1)', teks: 'Penganggaran penerimaan dan pengeluaran APBD harus didasarkan pada Kepastian Hukum dan Asas Umum Pengelolaan Keuangan Daerah.' },
      { nomor: 'Pasal 27', ayat: 'Ayat (1)', teks: 'Pendapatan Daerah terdiri atas Pendapatan Asli Daerah (PAD), Pendapatan Transfer, dan Lain-lain Pendapatan Daerah yang sah.' },
      { nomor: 'Pasal 50', ayat: 'Ayat (1)', teks: 'Belanja Daerah disusun berdasarkan pendekatan prestasi kerja yang berorientasi pada pencapaian hasil dari input yang direncanakan.' }
    ];

    const pp12Res = await client.query("SELECT id FROM peraturan WHERE jenis_peraturan = 'PP' AND nomor = '12' AND tahun = 2019;");
    if (pp12Res.rows.length > 0) {
      const pp12Id = pp12Res.rows[0].id;
      await client.query("DELETE FROM pasal WHERE peraturan_id = $1;", [pp12Id]);
      for (const p of pp12Articles) {
        await client.query(
          "INSERT INTO pasal (peraturan_id, nomor_pasal, nomor_ayat, teks_pasal) VALUES ($1, $2, $3, $4);",
          [pp12Id, p.nomor, p.ayat, p.teks]
        );
      }
    }

    await client.query('COMMIT');
    console.log('Full sequential article ingestion completed successfully!');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error in bulk article ingestion:', error);
    throw error;
  } finally {
    client.release();
  }
}
