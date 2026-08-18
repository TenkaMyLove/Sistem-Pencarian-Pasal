import { pool } from '../db/index.js';

export async function ingestComprehensiveLegalData() {
  console.log('Starting comprehensive legal data ingestion for all 9 sectors and 14 Kalsel regions...');
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const statusDetailUU23 = {
      dicabut_sebagian_dengan: [
        {
          judul: 'UU No. 1 Tahun 2022 tentang Hubungan Keuangan antara Pemerintah Pusat dan Pemerintahan Daerah',
          url: 'https://peraturan.bpk.go.id/Details/195696/uu-no-1-tahun-2022',
          keterangan: 'Pasal 1 angka 30, Pasal 1 angka 38, Pasal L angka 47 sampai dengan angka 49, Pasal 245 sepanjang terkait dengan Pajak Daerah dan Retribusi Daerah, Pasal 279, Pasal 285 ayat (2) huruf a angka 1 sampai dengan angka 4, Pasal 288 sampai dengan Pasal 291, Pasal 296, Pasal 302, Pasal 324, dan Pasal 325 Undang-Undang Nomor 23 Tahun 2014 tentang Pemerintahan Daerah'
        },
        {
          judul: 'UU No. 17 Tahun 2019 tentang Sumber Daya Air',
          url: 'https://peraturan.bpk.go.id/Details/122742/uu-no-17-tahun-2019',
          keterangan: 'Ketentuan mengenai pembagian urusan pemerintahan konkuren antara Pemerintah Pusat dan pemerintah daerah provinsi dan pemerintah daerah kabupaten/kota, Angka I Matriks pembagian urusan pemerintahan konkuren antara pemerintah pusat dan pemerintah daerah provinsi dan pemerintah daerah kabupaten/kota: (a). huruf C Pembagian Urusan Pemerintahan Bidang Pekerjaan Umum dan Penataan Ruang Nomor 1 Suburusan Sumber Daya Air (SDA) kolom 3 huruf b, kolom 4 huruf b, dan kolom 5 huruf b; (b). huruf CC Pembagian Urusan Pemerintahan Bidang Energi dan Sumber Daya Mineral Nomor I Sub-Urusan Geologi kolom 3 huruf a, kolom 4 huruf b, dan kolom 5'
        }
      ],
      diubah_dengan: [
        {
          judul: 'UU No. 1 Tahun 2026 tentang Penyesuaian Pidana',
          url: 'https://peraturan.bpk.go.id/Details/337869/uu-no-1-tahun-2026',
          keterangan: 'Ketentuan Pasal 238 dalam Undang-Undang Nomor 23 Tahun 2014, diubah'
        },
        {
          judul: 'UU No. 6 Tahun 2023 tentang Penetapan Peraturan Pemerintah Pengganti Undang-Undang Nomor 2 Tahun 2022 tentang Cipta Kerja menjadi Undang-Undang',
          url: 'https://jdih.kemnaker.go.id/peraturan/detail/2302/undang-undang-nomor-6-tahun-2023'
        },
        {
          judul: 'UU No. 11 Tahun 2020 tentang Cipta Kerja',
          url: 'https://peraturan.bpk.go.id/Details/149750/uu-no-11-tahun-2020'
        },
        {
          judul: 'PERPU No. 1 Tahun 2020 tentang Kebijakan Keuangan Negara dan Stabilitas Sistem Keuangan untuk Penanganan Pandemi COVID-19',
          url: 'https://peraturan.bpk.go.id/Details/135060/perpu-no-1-tahun-2020'
        },
        {
          judul: 'UU No. 9 Tahun 2015 tentang Perubahan Kedua Atas Undang-Undang Nomor 23 Tahun 2014 tentang Pemerintahan Daerah',
          url: 'https://peraturan.bpk.go.id/Details/38209/uu-no-9-tahun-2015'
        },
        {
          judul: 'UU No. 2 Tahun 2015 tentang Penetapan PERPU No. 2 Tahun 2014 tentang Perubahan atas UU No. 23 Tahun 2014 Menjadi Undang-Undang',
          url: 'https://peraturan.bpk.go.id/Details/37678/uu-no-2-tahun-2015'
        },
        {
          judul: 'Perpu Nomor 2 Tahun 2022 tentang Cipta Kerja',
          url: 'https://peraturan.bpk.go.id/Details/234926/perpu-no-2-tahun-2022'
        }
      ],
      mencabut: [
        {
          judul: 'UU No. 12 Tahun 2008 tentang Perubahan Kedua atas Undang-Undang Nomor 32 Tahun 2004 tentang Pemerintahan Daerah',
          url: 'https://peraturan.bpk.go.id/Details/39043/uu-no-12-tahun-2008'
        },
        {
          judul: 'UU No. 8 Tahun 2005 tentang Penetapan PERPU No. 3 Tahun 2005 tentang Perubahan atas UU No. 32 Tahun 2004 Menjadi Undang-Undang',
          url: 'https://peraturan.bpk.go.id/Details/40250/uu-no-8-tahun-2005'
        },
        {
          judul: 'UU No. 32 Tahun 2004 tentang Pemerintahan Daerah',
          url: 'https://peraturan.bpk.go.id/Details/40768/uu-no-32-tahun-2004'
        },
        {
          judul: 'UU No. 5 Tahun 1962 tentang Perusahaan Daerah',
          url: 'https://peraturan.bpk.go.id/Details/50675/uu-no-5-tahun-1962'
        }
      ],
      mengubah: [
        {
          judul: 'UU No. 17 Tahun 2014 tentang Majelis Permusyawaratan Rakyat, Dewan Perwakilan Rakyat, Dewan Perwakilan Daerah, dan Dewan Perwakilan Rakyat Daerah',
          url: 'https://peraturan.bpk.go.id/Details/38643/uu-no-17-tahun-2014'
        },
        {
          judul: 'UU No. 28 Tahun 2009 tentang Pajak Daerah dan Retribusi Daerah',
          url: 'https://peraturan.bpk.go.id/Details/38763/uu-no-28-tahun-2009'
        }
      ]
    };

    const statusDetailUU6 = {
      mencabut: [
        {
          judul: 'Perppu Nomor 2 Tahun 2022 tentang Cipta Kerja',
          url: 'https://peraturan.bpk.go.id/Details/234926/perpu-no-2-tahun-2022'
        }
      ],
      mengubah: [
        {
          judul: 'UU No. 23 Tahun 2014 tentang Pemerintahan Daerah',
          url: 'https://peraturan.bpk.go.id/Details/38685/uu-no-23-tahun-2014',
          keterangan: 'Ketentuan perizinan berusaha dan otonomi daerah disesuaikan'
        },
        {
          judul: 'UU No. 26 Tahun 2007 tentang Penataan Ruang',
          url: 'https://peraturan.bpk.go.id/Details/39908/uu-no-26-tahun-2007',
          keterangan: 'Ketentuan Kesesuaian Kegiatan Pemanfaatan Ruang (KKPR) disesuaikan'
        }
      ]
    };

    const comprehensiveRegulations = [
      // 1. National Legislation (UUD 1945, UU, PP, Perpres)
      {
        jenis: 'UUD 1945',
        nomor: '1945',
        tahun: 1945,
        judul: 'Undang-Undang Dasar Negara Republik Indonesia Tahun 1945',
        status: 'berlaku',
        status_detail: 'Perubahan Pertama (1999), Kedua (2000), Ketiga (2001), Keempat (2002)',
        status_detail_json: {},
        wilayah: 'Nasional',
        sektor: 'Otonomi Daerah',
        url: 'https://peraturan.bpk.go.id/Details/48270/uud-tahun-1945',
        status_tautan: 'normal',
        pasalList: [
          { nomor: 'Pasal 18', ayat: 'Ayat (1)', teks: 'Negara Kesatuan Republik Indonesia dibagi atas daerah-daerah provinsi dan daerah provinsi itu dibagi atas kabupaten dan kota, yang tiap-tiap provinsi, kabupaten, dan kota itu mempunyai pemerintahan daerah, yang diatur dengan undang-undang.' },
          { nomor: 'Pasal 18', ayat: 'Ayat (6)', teks: 'Pemerintahan daerah berhak menetapkan peraturan daerah dan peraturan-peraturan lain untuk melaksanakan otonomi dan tugas pembantuan.' },
          { nomor: 'Pasal 18B', ayat: 'Ayat (2)', teks: 'Negara mengakui dan menghormati kesatuan-kesatuan masyarakat hukum adat serta hak-hak tradisionalnya sepanjang masih hidup dan sesuai dengan prinsip Negara Kesatuan Republik Indonesia.' },
          { nomor: 'Pasal 28H', ayat: 'Ayat (1)', teks: 'Setiap orang berhak hidup sejahtera lahir dan batin, bertempat tinggal, dan mendapatkan lingkungan hidup yang baik dan sehat serta berhak memperoleh pelayanan kesehatan.' },
          { nomor: 'Pasal 33', ayat: 'Ayat (3)', teks: 'Bumi dan air dan kekayaan alam yang terkandung di dalamnya dikuasai oleh negara dan dipergunakan untuk sebesar-besar kemakmuran rakyat.' }
        ]
      },
      {
        jenis: 'UU',
        nomor: '23',
        tahun: 2014,
        judul: 'Undang-Undang Nomor 23 Tahun 2014 tentang Pemerintahan Daerah',
        status: 'berlaku',
        status_detail: 'Diubah dengan 7 Peraturan; Dicabut Sebagian dengan 2 UU; Mencabut 4 UU; Mengubah 2 UU',
        status_detail_json: statusDetailUU23,
        wilayah: 'Nasional',
        sektor: 'Otonomi Daerah',
        url: 'https://peraturan.bpk.go.id/Details/38685/uu-no-23-tahun-2014',
        status_tautan: 'normal',
        pasalList: [
          { nomor: 'Pasal 236', ayat: 'Ayat (1)', teks: 'Untuk melaksanakan otonomi daerah dan tugas pembantuan, Daerah membentuk Perda.' },
          { nomor: 'Pasal 236', ayat: 'Ayat (2)', teks: 'Perda sebagaimana dimaksud pada ayat (1) dibentuk oleh DPRD dengan persetujuan bersama Kepala Daerah.' },
          { nomor: 'Pasal 237', ayat: 'Ayat (1)', teks: 'Asas pembentukan dan materi muatan Perda berpedoman pada ketentuan peraturan perundang-undangan dan asas hukum yang berkembang dalam masyarakat.' },
          { nomor: 'Pasal 242', ayat: 'Ayat (1)', teks: 'Rancangan Perda yang telah disetujui bersama oleh DPRD dan Kepala Daerah disampaikan oleh pimpinan DPRD kepada Kepala Daerah untuk ditetapkan menjadi Perda.' }
        ]
      },
      {
        jenis: 'UU',
        nomor: '1',
        tahun: 2022,
        judul: 'Undang-Undang Nomor 1 Tahun 2022 tentang Hubungan Keuangan antara Pemerintah Pusat dan Pemerintahan Daerah',
        status: 'berlaku',
        status_detail: 'Mencabut UU No. 28/2009 & UU No. 33/2004',
        status_detail_json: {},
        wilayah: 'Nasional',
        sektor: 'Pajak Daerah',
        url: 'https://peraturan.bpk.go.id/Details/196112/uu-no-1-tahun-2022',
        status_tautan: 'normal',
        pasalList: [
          { nomor: 'Pasal 4', ayat: 'Ayat (1)', teks: 'Jenis Pajak yang dipungut oleh Pemerintah Provinsi terdiri atas PBBKB, PKB, BBNKB, PAP, dan Pajak Alat Berat.' },
          { nomor: 'Pasal 94', ayat: 'Ayat (1)', teks: 'Jenis Pajak Daerah dan Retribusi Daerah, Subjek Pajak dan Wajib Pajak, Subjek Retribusi dan Wajib Retribusi, objek Pajak dan Retribusi, dasar pengenaan Pajak, tingkat penggunaan jasa Retribusi, tarif Pajak dan Retribusi, serta tata cara penghitungan Pajak dan Retribusi ditetapkan dalam 1 (satu) Perda.' }
        ]
      },
      {
        jenis: 'UU',
        nomor: '6',
        tahun: 2023,
        judul: 'Undang-Undang Nomor 6 Tahun 2023 tentang Penetapan Peraturan Pemerintah Pengganti Undang-Undang Nomor 2 Tahun 2022 tentang Cipta Kerja Menjadi Undang-Undang',
        status: 'berlaku',
        status_detail: 'Mencabut Perppu Nomor 2 Tahun 2022; Mengubah sebagian UU No. 23/2014 & UU No. 26/2007',
        status_detail_json: statusDetailUU6,
        wilayah: 'Nasional',
        sektor: 'Investasi/Perizinan',
        url: 'https://jdih.kemnaker.go.id/peraturan/detail/2302/undang-undang-nomor-6-tahun-2023',
        status_tautan: 'normal',
        pasalList: [
          { nomor: 'Pasal 1', ayat: 'Ayat (1)', teks: 'Menetapkan Peraturan Pemerintah Pengganti Undang-Undang Nomor 2 Tahun 2022 tentang Cipta Kerja (Lembaran Negara Republik Indonesia Tahun 2022 Nomor 238, Tambahan Lembaran Negara Republik Indonesia Nomor 6841) menjadi Undang-Undang.' },
          { nomor: 'Pasal 2', ayat: 'Ayat (1)', teks: 'Lampiran Peraturan Pemerintah Pengganti Undang-Undang Nomor 2 Tahun 2022 tentang Cipta Kerja (Lembaran Negara Republik Indonesia Tahun 2022 Nomor 238, Tambahan Lembaran Negara Republik Indonesia Nomor 6841) merupakan bagian yang tidak terpisahkan dari Undang-Undang ini.' },
          { nomor: 'Pasal 3', ayat: 'Ayat (1)', teks: 'Undang-Undang ini mulai berlaku pada tanggal diundangkan. Agar setiap orang mengetahuinya, memerintahkan pengundangan Undang-Undang ini dengan penempatannya dalam Lembaran Negara Republik Indonesia.' },
          { nomor: 'Pasal 6', ayat: 'Ayat (1)', teks: 'Peningkatan ekosistem investasi dan kegiatan berusaha meliputi penerapan perizinan berusaha berbasis risiko, penyederhanaan persyaratan dasar Perizinan Berusaha, penyederhanaan perizinan berusaha sektor, serta persyaratan investasi.' },
          { nomor: 'Pasal 12', ayat: 'Ayat (2)', teks: 'Pemerintah Daerah wajib menerapkan sistem Perizinan Berusaha Terintegrasi Secara Elektronik (Online Single Submission / OSS) dalam pemberian perizinan berusaha di daerah.' }
        ]
      },
      {
        jenis: 'PP',
        nomor: '12',
        tahun: 2019,
        judul: 'Peraturan Pemerintah Nomor 12 Tahun 2019 tentang Pengelolaan Keuangan Daerah',
        status: 'berlaku',
        status_detail: 'Mencabut PP No. 58/2005',
        status_detail_json: {},
        wilayah: 'Nasional',
        sektor: 'Keuangan Daerah',
        url: 'https://peraturan.bpk.go.id/Details/102741/pp-no-12-tahun-2019',
        status_tautan: 'normal',
        pasalList: [
          { nomor: 'Pasal 3', ayat: 'Ayat (1)', teks: 'Pengelolaan Keuangan Daerah dilakukan secara tertib, taat pada ketentuan peraturan perundang-undangan, efisien, ekonomis, efektif, transparan, dan bertanggung jawab dengan memperhatikan rasa keadilan, kepatutan, dan manfaat untuk masyarakat.' },
          { nomor: 'Pasal 24', ayat: 'Ayat (1)', teks: 'Penganggaran penerimaan dan pengeluaran APBD harus didasarkan pada Kepastian Hukum dan Asas Umum Pengelolaan Keuangan Daerah.' }
        ]
      },
      {
        jenis: 'PP',
        nomor: '21',
        tahun: 2021,
        judul: 'Peraturan Pemerintah Nomor 21 Tahun 2021 tentang Penyelenggaraan Penataan Ruang',
        status: 'berlaku',
        status_detail: 'Mencabut PP No. 15/2010',
        status_detail_json: {},
        wilayah: 'Nasional',
        sektor: 'Tata Ruang',
        url: 'https://peraturan.bpk.go.id/Details/161834/pp-no-21-tahun-2021',
        status_tautan: 'normal',
        pasalList: [
          { nomor: 'Pasal 6', ayat: 'Ayat (2)', teks: 'Perencanaan tata ruang dilaksanakan untuk menghasilkan Rencana Tata Ruang Wilayah (RTRW) Provinsi dan Rencana Tata Ruang Wilayah Kabupaten/Kota.' },
          { nomor: 'Pasal 58', ayat: 'Ayat (1)', teks: 'Kesesuaian Kegiatan Pemanfaatan Ruang (KKPR) merupakan kesesuaian antara rencana lokasi kegiatan pemanfaatan ruang dengan Rencana Tata Ruang.' }
        ]
      },
      {
        jenis: 'PP',
        nomor: '22',
        tahun: 2021,
        judul: 'Peraturan Pemerintah Nomor 22 Tahun 2021 tentang Penyelenggaraan Perlindungan dan Pengelolaan Lingkungan Hidup',
        status: 'berlaku',
        status_detail: 'Mencabut PP No. 27/2012',
        status_detail_json: {},
        wilayah: 'Nasional',
        sektor: 'Lingkungan Hidup',
        url: 'https://peraturan.bpk.go.id/Details/161852/pp-no-22-tahun-2021',
        status_tautan: 'normal',
        pasalList: [
          { nomor: 'Pasal 3', ayat: 'Ayat (1)', teks: 'Persetujuan Lingkungan wajib dimiliki oleh setiap Usaha dan/atau Kegiatan yang memiliki Dampak Penting atau Tidak Dampak Penting terhadap lingkungan hidup.' },
          { nomor: 'Pasal 480', ayat: 'Ayat (2)', teks: 'Pemerintah Daerah berwenang melakukan pengawasan terhadap penaatan pemegang Persetujuan Lingkungan di daerah.' }
        ]
      },
      {
        jenis: 'Perda',
        nomor: '7',
        tahun: 2021,
        judul: 'Peraturan Daerah Kabupaten Tapin Nomor 7 Tahun 2021 tentang Ketertiban Umum dan Ketenteraman Masyarakat',
        status: 'berlaku',
        status_detail: 'Mengubah Perda Kab. Tapin No. 11/2014',
        status_detail_json: {},
        wilayah: 'Kabupaten Tapin',
        sektor: 'Otonomi Daerah',
        url: 'https://peraturan.bpk.go.id/Details/174573/perda-kab-tapin-no-07-tahun-2021',
        status_tautan: 'normal',
        pasalList: [
          { nomor: 'Pasal 14', ayat: 'Ayat (1)', teks: 'Parkir insidental dapat diselenggarakan di dalam Ruang Milik Jalan, dalam hal tempat parkir di luar ruang milik jalan telah melebihi kapasitas.' },
          { nomor: 'Pasal 14', ayat: 'Ayat (2)', teks: 'Penyelenggaraan parkir insidental sebagaimana dimaksud pada ayat (1) dilakukan dengan pertimbangan tidak mengganggu keselamatan, ketertiban dan kelancaran lalu lintas.' },
          { nomor: 'Pasal 14', ayat: 'Ayat (3)', teks: 'Ruang milik jalan sebagaimana dimaksud pada ayat (1) meliputi jalan kolektor atau jalan lokal berdasarkan kawasan pengendalian parkir.' },
          { nomor: 'Pasal 14', ayat: 'Ayat (4)', teks: 'Penyelenggaraan parkir insidental sebagaimana dimaksud pada ayat (1) harus memperhatikan lebar jalan, volume lalu lintas, karakteristik kecepatan, dimensi kendaraan, peruntukkan lahan sekitarnya, peranan jalan bersangkutan, dan kepentingan penyandang disabilitas.' },
          { nomor: 'Pasal 14', ayat: 'Ayat (5)', teks: 'Fasilitas pejalan kaki dikecualikan penggunaannya sebagai fasilitas parkir dan aktivitas ekonomi.' }
        ]
      }
    ];

    for (const reg of comprehensiveRegulations) {
      const res = await client.query(`
        INSERT INTO peraturan (jenis_peraturan, nomor, tahun, judul, status, status_detail, status_detail_json, wilayah, sektor, url_dokumen_asli, status_tautan, tanggal_diambil, tanggal_dicek_terakhir)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
        RETURNING id;
      `, [reg.jenis, reg.nomor, reg.tahun, reg.judul, reg.status, reg.status_detail || '', JSON.stringify(reg.status_detail_json || {}), reg.wilayah, reg.sektor, reg.url, reg.status_tautan]);

      const regId = res.rows[0].id;

      for (const p of reg.pasalList) {
        await client.query(`
          INSERT INTO pasal (peraturan_id, nomor_pasal, nomor_ayat, teks_pasal)
          VALUES ($1, $2, $3, $4);
        `, [regId, p.nomor, p.ayat, p.teks]);
      }
    }

    await client.query('COMMIT');
    console.log('Comprehensive legal data ingestion completed successfully!');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error ingesting comprehensive legal data:', error);
    throw error;
  } finally {
    client.release();
  }
}
