/**
 * expandRegulations2.ts
 *
 * Second batch expansion — adds 20 new regulations across all sectors
 * including Cipta Kerja cluster, KUHP baru, Desa, Jasa Konstruksi,
 * Sampah, Bangunan Gedung, Ketenagakerjaan, PDRD, Administrasi Pemerintahan.
 *
 * Also updates Perda Kalsel 7/2019 URL from JDIH to BPK.
 *
 * Run once: npx tsx src/scraper/expandRegulations2.ts
 */

import { pool } from '../db/index.js';

interface PasalEntry {
  nomor: string;
  ayat: string;
  teks: string;
}

interface RegEntry {
  jenis: string;
  nomor: string;
  tahun: number;
  judul: string;
  status: string;
  status_detail: string;
  wilayah: string;
  sektor: string;
  url: string;
  pasalList: PasalEntry[];
}

const NEW_REGULATIONS: RegEntry[] = [

  // ─── CIPTA KERJA (UU Induk & Produk) ────────────────────────────────────
  {
    jenis: 'UU', nomor: '11', tahun: 2020,
    judul: 'Undang-Undang Nomor 11 Tahun 2020 tentang Cipta Kerja',
    status: 'berlaku', status_detail: 'Diubah dengan UU No. 6/2023 (penetapan Perppu 2/2022)',
    wilayah: 'Nasional', sektor: 'Investasi dan Perizinan',
    url: 'https://peraturan.bpk.go.id/Details/149750/uu-no-11-tahun-2020',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Cipta Kerja adalah upaya penciptaan kerja melalui usaha kemudahan, perlindungan, dan pemberdayaan koperasi dan usaha mikro, kecil, dan menengah, peningkatan ekosistem investasi dan kemudahan berusaha, dan investasi Pemerintah Pusat dan percepatan proyek strategis nasional.' },
      { nomor: 'Pasal 4', ayat: 'Ayat (1)', teks: 'Penyederhanaan persyaratan dasar Perizinan Berusaha meliputi: a. kesesuaian kegiatan pemanfaatan ruang; b. Persetujuan Bangunan Gedung dan Sertifikat Laik Fungsi; c. persetujuan lingkungan.' },
      { nomor: 'Pasal 6', ayat: '', teks: 'Peningkatan ekosistem investasi dan kegiatan berusaha sebagaimana dimaksud dalam Pasal 5 huruf a meliputi: a. penerapan Perizinan Berusaha berbasis risiko; b. penyederhanaan persyaratan investasi; c. penyederhanaan persyaratan Perizinan Berusaha.' },
      { nomor: 'Pasal 185', ayat: 'Huruf b', teks: 'Pemerintah Daerah wajib menyesuaikan Peraturan Daerah yang berkaitan dengan kemudahan berusaha dan investasi paling lambat 3 (tiga) bulan sejak Undang-Undang ini berlaku.' },
    ]
  },

  // ─── HUKUM PIDANA (KUHP Baru) ────────────────────────────────────────────
  {
    jenis: 'UU', nomor: '1', tahun: 2023,
    judul: 'Undang-Undang Nomor 1 Tahun 2023 tentang Kitab Undang-Undang Hukum Pidana',
    status: 'berlaku', status_detail: 'Diubah dengan UU No. 1/2026 (Penyesuaian Pidana); Mencabut KUHP warisan kolonial dan beberapa UU pidana terkait; Mulai berlaku 2 Januari 2026',
    wilayah: 'Nasional', sektor: 'Hukum Pidana',
    url: 'https://peraturan.bpk.go.id/Details/234935/uu-no-1-tahun-2023',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Ayat (1)', teks: 'Tidak ada seorang pun yang dapat dipidana atau dikenai tindakan, kecuali perbuatan yang dilakukan patut dipersalahkan sesuai dengan ketentuan undang-undang yang berlaku pada saat perbuatan itu dilakukan.' },
      { nomor: 'Pasal 2', ayat: 'Ayat (1)', teks: 'Ketentuan dalam Buku Kesatu berlaku bagi perbuatan yang dapat dipidana berdasarkan ketentuan peraturan perundang-undangan lain, termasuk Peraturan Daerah Provinsi dan Peraturan Daerah Kabupaten/Kota, kecuali ditentukan lain menurut undang-undang.' },
      { nomor: 'Pasal 599', ayat: 'Ayat (1)', teks: 'Dipidana dengan pidana denda paling banyak kategori II, setiap orang yang melanggar Peraturan Daerah Provinsi atau Peraturan Daerah Kabupaten/Kota.' },
      { nomor: 'Pasal 622', ayat: 'Ayat (1)', teks: 'Pada saat Undang-Undang ini mulai berlaku, beberapa undang-undang yang mengatur ketentuan pidana dinyatakan masih tetap berlaku sepanjang tidak bertentangan dengan Undang-Undang ini.' },
    ]
  },
  {
    jenis: 'UU', nomor: '1', tahun: 2026,
    judul: 'Undang-Undang Nomor 1 Tahun 2026 tentang Penyesuaian Pidana',
    status: 'berlaku', status_detail: 'Mengubah ketentuan pidana dalam UU No. 6/2023, UU No. 13/2022, UU No. 15/2019, UU No. 23/2014, UU No. 12/2011; Mulai berlaku 2 Januari 2026',
    wilayah: 'Nasional', sektor: 'Hukum Pidana',
    url: 'https://peraturan.bpk.go.id/Details/337869/uu-no-1-tahun-2026',
    pasalList: [
      { nomor: 'Pasal 1', ayat: '', teks: 'Undang-Undang ini mengatur mengenai penyesuaian terhadap ketentuan pidana dalam setiap Undang-Undang di luar Undang-Undang Nomor 1 Tahun 2023 tentang Kitab Undang-Undang Hukum Pidana dan Peraturan Daerah dengan Buku Kesatu Undang-Undang Nomor 1 Tahun 2023.' },
      { nomor: 'Pasal 238', ayat: '', teks: 'Ketentuan Pasal 238 Undang-Undang Nomor 23 Tahun 2014 tentang Pemerintahan Daerah diubah sehingga berbunyi: sanksi administratif yang dikenakan kepada Kepala Daerah dan DPRD disesuaikan dengan ketentuan dalam Undang-Undang Nomor 1 Tahun 2023.' },
    ]
  },

  // ─── PEMBENTUKAN PERATURAN PERUNDANG-UNDANGAN ────────────────────────────
  {
    jenis: 'UU', nomor: '15', tahun: 2019,
    judul: 'Undang-Undang Nomor 15 Tahun 2019 tentang Perubahan atas Undang-Undang Nomor 12 Tahun 2011 tentang Pembentukan Peraturan Perundang-Undangan',
    status: 'berlaku', status_detail: 'Mengubah UU No. 12/2011; Diubah dengan UU No. 13/2022 dan UU No. 1/2026',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/121716/',
    pasalList: [
      { nomor: 'Pasal I', ayat: '', teks: 'Beberapa ketentuan dalam Undang-Undang Nomor 12 Tahun 2011 tentang Pembentukan Peraturan Perundang-undangan diubah, termasuk penambahan mekanisme pembahasan RUU yang sudah dibahas pada periode sebelumnya dan pengaturan mengenai Pemantauan dan Peninjauan Peraturan Perundang-undangan.' },
      { nomor: 'Pasal 95A', ayat: 'Ayat (1)', teks: 'DPR, DPD, dan Presiden melakukan Pemantauan dan Peninjauan terhadap Undang-Undang.' },
      { nomor: 'Pasal 95B', ayat: 'Ayat (1)', teks: 'Menteri, kepala lembaga, atau kepala daerah melakukan pemantauan dan peninjauan terhadap Peraturan Perundang-undangan di bawah Undang-Undang.' },
    ]
  },
  {
    jenis: 'UU', nomor: '13', tahun: 2022,
    judul: 'Undang-Undang Nomor 13 Tahun 2022 tentang Perubahan Kedua atas Undang-Undang Nomor 12 Tahun 2011 tentang Pembentukan Peraturan Perundang-Undangan',
    status: 'berlaku', status_detail: 'Mengubah UU No. 12/2011 dan UU No. 15/2019; Diubah dengan UU No. 1/2026 (Pasal 15 diubah)',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/212810/uu-no-13-tahun-2022',
    pasalList: [
      { nomor: 'Pasal I', ayat: '', teks: 'Beberapa ketentuan dalam Undang-Undang Nomor 12 Tahun 2011 tentang Pembentukan Peraturan Perundang-undangan diubah, termasuk penambahan metode omnibus, penguatan meaningful participation, dan pembentukan peraturan perundang-undangan secara elektronik.' },
      { nomor: 'Pasal 9A', ayat: 'Ayat (1)', teks: 'Pembentukan Peraturan Perundang-undangan dapat menggunakan metode omnibus.' },
      { nomor: 'Pasal 96', ayat: 'Ayat (1)', teks: 'Masyarakat berhak memberikan masukan secara lisan dan/atau tertulis dalam setiap tahapan Pembentukan Peraturan Perundang-undangan.' },
      { nomor: 'Pasal 96', ayat: 'Ayat (4)', teks: 'Masyarakat yang terdampak langsung atau memiliki kepentingan atas materi muatan Rancangan Peraturan Perundang-undangan berhak: a. memberikan masukan secara lisan dan/atau tertulis; b. mendapatkan penjelasan; dan c. mendapatkan laporan atas masukannya.' },
    ]
  },

  // ─── ADMINISTRASI & TATA KELOLA PEMERINTAHAN ────────────────────────────
  {
    jenis: 'UU', nomor: '30', tahun: 2014,
    judul: 'Undang-Undang Nomor 30 Tahun 2014 tentang Administrasi Pemerintahan',
    status: 'berlaku', status_detail: 'Diubah dengan UU No. 11/2020 (Cipta Kerja), Perppu No. 2/2022, UU No. 6/2023',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/38695/uu-no-30-tahun-2014',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Administrasi Pemerintahan adalah tata laksana dalam pengambilan keputusan dan/atau tindakan oleh badan dan/atau pejabat pemerintahan.' },
      { nomor: 'Pasal 5', ayat: '', teks: 'Penyelenggaraan Administrasi Pemerintahan berdasarkan pada asas: a. legalitas; b. perlindungan hukum; c. kepastian hukum; d. ketidakberpihakan; e. kecermatan; f. tidak menyalahgunakan kewenangan; g. keterbukaan; h. kepentingan umum; dan i. pelayanan yang baik.' },
      { nomor: 'Pasal 9', ayat: 'Ayat (1)', teks: 'Setiap Keputusan dan/atau Tindakan wajib berdasarkan ketentuan peraturan perundang-undangan dan AUPB.' },
      { nomor: 'Pasal 14', ayat: 'Ayat (1)', teks: 'Badan dan/atau Pejabat Pemerintahan yang menggunakan Diskresi harus memenuhi syarat: a. sesuai dengan tujuan Diskresi; b. tidak bertentangan dengan ketentuan peraturan perundang-undangan; c. sesuai dengan AUPB; d. berdasarkan alasan-alasan yang objektif; e. tidak menimbulkan konflik kepentingan; dan f. dilakukan dengan iktikad baik.' },
    ]
  },
  {
    jenis: 'UU', nomor: '25', tahun: 2009,
    judul: 'Undang-Undang Nomor 25 Tahun 2009 tentang Pelayanan Publik',
    status: 'berlaku', status_detail: 'Berlaku penuh; belum ada perubahan formal',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/38748/uu-no-25-tahun-2009',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Pelayanan publik adalah kegiatan atau rangkaian kegiatan dalam rangka pemenuhan kebutuhan pelayanan sesuai dengan peraturan perundang-undangan bagi setiap warga negara dan penduduk atas barang, jasa, dan/atau pelayanan administratif yang disediakan oleh penyelenggara pelayanan publik.' },
      { nomor: 'Pasal 4', ayat: '', teks: 'Penyelenggaraan pelayanan publik berasaskan: a. kepentingan umum; b. kepastian hukum; c. kesamaan hak; d. keseimbangan hak dan kewajiban; e. keprofesionalan; f. partisipatif; g. persamaan perlakuan/tidak diskriminatif; h. keterbukaan; i. akuntabilitas; j. fasilitas dan perlakuan khusus bagi kelompok rentan; k. ketepatan waktu; dan l. kecepatan, kemudahan, dan keterjangkauan.' },
      { nomor: 'Pasal 20', ayat: 'Ayat (1)', teks: 'Penyelenggara berkewajiban menyusun dan menetapkan standar pelayanan dengan memperhatikan kemampuan penyelenggara, kebutuhan masyarakat, dan kondisi lingkungan.' },
    ]
  },
  {
    jenis: 'UU', nomor: '14', tahun: 2008,
    judul: 'Undang-Undang Nomor 14 Tahun 2008 tentang Keterbukaan Informasi Publik',
    status: 'berlaku', status_detail: 'Berlaku penuh; belum ada perubahan formal',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/39047/uu-no-14-tahun-2008',
    pasalList: [
      { nomor: 'Pasal 2', ayat: 'Ayat (1)', teks: 'Setiap Informasi Publik bersifat terbuka dan dapat diakses oleh setiap Pengguna Informasi Publik.' },
      { nomor: 'Pasal 7', ayat: 'Ayat (1)', teks: 'Badan Publik wajib menyediakan, memberikan dan/atau menerbitkan Informasi Publik yang berada di bawah kewenangannya kepada Pemohon Informasi Publik, selain informasi yang dikecualikan sesuai dengan ketentuan.' },
      { nomor: 'Pasal 9', ayat: 'Ayat (1)', teks: 'Setiap Badan Publik wajib mengumumkan Informasi Publik secara berkala.' },
    ]
  },

  // ─── DESA ────────────────────────────────────────────────────────────────
  {
    jenis: 'UU', nomor: '6', tahun: 2014,
    judul: 'Undang-Undang Nomor 6 Tahun 2014 tentang Desa',
    status: 'berlaku', status_detail: 'Diubah dengan UU No. 11/2020, Perppu 2/2022, UU No. 6/2023, UU No. 3/2024; Mencabut Pasal 200-216 UU 32/2004',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/38582/uu-no-6-tahun-2014',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Desa adalah desa dan desa adat atau yang disebut dengan nama lain, selanjutnya disebut Desa, adalah kesatuan masyarakat hukum yang memiliki batas wilayah yang berwenang untuk mengatur dan mengurus urusan pemerintahan, kepentingan masyarakat setempat berdasarkan prakarsa masyarakat, hak asal usul, dan/atau hak tradisional yang diakui dan dihormati dalam sistem pemerintahan Negara Kesatuan Republik Indonesia.' },
      { nomor: 'Pasal 26', ayat: 'Ayat (1)', teks: 'Kepala Desa bertugas menyelenggarakan Pemerintahan Desa, melaksanakan Pembangunan Desa, pembinaan kemasyarakatan Desa, dan pemberdayaan masyarakat Desa.' },
      { nomor: 'Pasal 69', ayat: 'Ayat (1)', teks: 'Jenis peraturan di Desa terdiri atas Peraturan Desa, peraturan bersama Kepala Desa, dan peraturan Kepala Desa.' },
      { nomor: 'Pasal 72', ayat: 'Ayat (1)', teks: 'Pendapatan Desa bersumber dari: a. pendapatan asli Desa; b. alokasi Anggaran Pendapatan dan Belanja Negara; c. bagian dari hasil pajak daerah dan retribusi daerah; d. alokasi dana desa; e. bantuan keuangan dari APBD Provinsi dan APBD Kabupaten/Kota; f. hibah dan sumbangan yang tidak mengikat dari pihak ketiga; g. lain-lain pendapatan Desa yang sah.' },
    ]
  },
  {
    jenis: 'UU', nomor: '3', tahun: 2024,
    judul: 'Undang-Undang Nomor 3 Tahun 2024 tentang Perubahan Kedua atas Undang-Undang Nomor 6 Tahun 2014 tentang Desa',
    status: 'berlaku', status_detail: 'Mengubah UU No. 6/2014 dan UU No. 6/2023; Mengubah Pasal 39 (masa jabatan Kepala Desa menjadi 8 tahun)',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/283617/uu-no-3-tahun-2024',
    pasalList: [
      { nomor: 'Pasal I', ayat: '', teks: 'Beberapa ketentuan dalam Undang-Undang Nomor 6 Tahun 2014 tentang Desa sebagaimana telah diubah dengan Undang-Undang Nomor 6 Tahun 2023 diubah, termasuk ketentuan mengenai masa jabatan Kepala Desa.' },
      { nomor: 'Pasal 39', ayat: 'Ayat (1)', teks: 'Kepala Desa memegang jabatan selama 8 (delapan) tahun terhitung sejak tanggal pelantikan.' },
      { nomor: 'Pasal 39', ayat: 'Ayat (2)', teks: 'Kepala Desa sebagaimana dimaksud pada ayat (1) dapat menjabat paling banyak 2 (dua) kali masa jabatan secara berturut-turut atau tidak secara berturut-turut.' },
    ]
  },
  {
    jenis: 'PP', nomor: '11', tahun: 2019,
    judul: 'Peraturan Pemerintah Nomor 11 Tahun 2019 tentang Perubahan Kedua atas Peraturan Pemerintah Nomor 43 Tahun 2014 tentang Peraturan Pelaksanaan Undang-Undang Nomor 6 Tahun 2014 tentang Desa',
    status: 'berlaku', status_detail: 'Mengubah PP No. 43/2014 dan PP No. 47/2015; Sebagian digantikan oleh PP No. 16/2026',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/102675/pp-no-11-tahun-2019',
    pasalList: [
      { nomor: 'Pasal 81', ayat: 'Ayat (1)', teks: 'Penghasilan tetap diberikan kepada kepala desa, sekretaris desa, dan perangkat desa lainnya dianggarkan dalam APBDesa yang bersumber dari ADD atau sumber lain dalam APBDesa selain dana desa.' },
      { nomor: 'Pasal 81A', ayat: 'Ayat (1)', teks: 'Besaran penghasilan tetap kepala desa paling sedikit Rp2.426.640 (dua juta empat ratus dua puluh enam ribu enam ratus empat puluh rupiah) setara 120% gaji pokok PNS golongan ruang II/a.' },
    ]
  },

  // ─── PERANGKAT DAERAH ────────────────────────────────────────────────────
  {
    jenis: 'PP', nomor: '72', tahun: 2019,
    judul: 'Peraturan Pemerintah Nomor 72 Tahun 2019 tentang Perubahan atas Peraturan Pemerintah Nomor 18 Tahun 2016 tentang Perangkat Daerah',
    status: 'berlaku', status_detail: 'Mengubah PP No. 18/2016; Memperkuat kedudukan Inspektorat Daerah dan mengatur Rumah Sakit Daerah',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/122033/pp-no-72-tahun-2019',
    pasalList: [
      { nomor: 'Pasal I', ayat: '', teks: 'Beberapa ketentuan dalam Peraturan Pemerintah Nomor 18 Tahun 2016 tentang Perangkat Daerah diubah untuk memperkuat peran dan independensi Inspektorat Daerah serta mengatur tata kelola Rumah Sakit Daerah.' },
      { nomor: 'Pasal 11A', ayat: 'Ayat (1)', teks: 'Inspektur Daerah provinsi diangkat dan diberhentikan oleh gubernur setelah berkonsultasi dengan Menteri Dalam Negeri.' },
      { nomor: 'Pasal 11B', ayat: 'Ayat (1)', teks: 'Untuk mendukung pelaksanaan tugas Inspektorat Daerah, dapat dibentuk Unit Pelaksana Teknis Daerah pada Inspektorat Daerah.' },
    ]
  },

  // ─── JASA KONSTRUKSI ─────────────────────────────────────────────────────
  {
    jenis: 'UU', nomor: '2', tahun: 2017,
    judul: 'Undang-Undang Nomor 2 Tahun 2017 tentang Jasa Konstruksi',
    status: 'berlaku', status_detail: 'Diubah dengan UU No. 11/2020, Perppu 2/2022, UU No. 6/2023; Mencabut UU No. 18/1999',
    wilayah: 'Nasional', sektor: 'Jasa Konstruksi',
    url: 'https://peraturan.bpk.go.id/Details/37637/uu-no-2-tahun-2017',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Jasa Konstruksi adalah layanan jasa konsultansi konstruksi dan/atau pekerjaan konstruksi.' },
      { nomor: 'Pasal 7', ayat: 'Ayat (1)', teks: 'Kewenangan Pemerintah Pusat meliputi: a. penetapan kebijakan pengembangan Jasa Konstruksi nasional; b. penyelenggaraan registrasi badan usaha Jasa Konstruksi; c. penyelenggaraan registrasi pengalaman badan usaha Jasa Konstruksi; d. penyelenggaraan akreditasi asosiasi badan usaha Jasa Konstruksi; e. pembentukan lembaga.' },
      { nomor: 'Pasal 8', ayat: 'Ayat (1)', teks: 'Kewenangan Pemerintah Daerah Provinsi dalam penyelenggaraan Jasa Konstruksi meliputi: a. penyelenggaraan pelatihan tenaga ahli konstruksi; b. penyelenggaraan sistem informasi Jasa Konstruksi.' },
      { nomor: 'Pasal 14', ayat: 'Ayat (1)', teks: 'Usaha Jasa Konstruksi mencakup jenis usaha, sifat usaha, dan klasifikasi usaha Jasa Konstruksi.' },
    ]
  },
  {
    jenis: 'PP', nomor: '14', tahun: 2021,
    judul: 'Peraturan Pemerintah Nomor 14 Tahun 2021 tentang Perubahan atas Peraturan Pemerintah Nomor 22 Tahun 2020 tentang Peraturan Pelaksanaan Undang-Undang Nomor 2 Tahun 2017 tentang Jasa Konstruksi',
    status: 'berlaku', status_detail: 'Mengubah PP No. 22/2020; Bagian dari kluster Cipta Kerja',
    wilayah: 'Nasional', sektor: 'Jasa Konstruksi',
    url: 'https://peraturan.bpk.go.id/Details/161844/pp-no-14-tahun-2021',
    pasalList: [
      { nomor: 'Pasal I', ayat: '', teks: 'Beberapa ketentuan dalam Peraturan Pemerintah Nomor 22 Tahun 2020 tentang Peraturan Pelaksanaan Undang-Undang Nomor 2 Tahun 2017 tentang Jasa Konstruksi diubah dalam rangka pelaksanaan Undang-Undang Nomor 11 Tahun 2020 tentang Cipta Kerja.' },
      { nomor: 'Pasal 1', ayat: 'Angka 10', teks: 'Perizinan Berusaha adalah legalitas yang diberikan kepada Pelaku Usaha untuk memulai dan menjalankan usaha dan/atau kegiatan Jasa Konstruksi.' },
    ]
  },

  // ─── LINGKUNGAN HIDUP / SAMPAH ────────────────────────────────────────────
  {
    jenis: 'UU', nomor: '18', tahun: 2008,
    judul: 'Undang-Undang Nomor 18 Tahun 2008 tentang Pengelolaan Sampah',
    status: 'berlaku', status_detail: 'Berlaku penuh; belum ada perubahan formal',
    wilayah: 'Nasional', sektor: 'Lingkungan Hidup',
    url: 'https://peraturan.bpk.go.id/Details/39067/uu-no-18-tahun-2008',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Sampah adalah sisa kegiatan sehari-hari manusia dan/atau proses alam yang berbentuk padat.' },
      { nomor: 'Pasal 5', ayat: '', teks: 'Pemerintah dan pemerintahan daerah bertugas menjamin terselenggaranya pengelolaan sampah yang baik dan berwawasan lingkungan sesuai dengan tujuan Undang-Undang ini.' },
      { nomor: 'Pasal 9', ayat: 'Ayat (1)', teks: 'Pemerintahan kabupaten/kota mempunyai kewenangan: a. menetapkan kebijakan dan strategi pengelolaan sampah berdasarkan kebijakan nasional dan provinsi; b. menyelenggarakan pengelolaan sampah skala kabupaten/kota sesuai dengan norma, standar, prosedur, dan kriteria yang ditetapkan oleh Pemerintah; c. melakukan pembinaan dan pengawasan kinerja pengelolaan sampah yang dilaksanakan oleh pihak lain.' },
      { nomor: 'Pasal 29', ayat: 'Ayat (1)', teks: 'Setiap orang dilarang: a. membuang sampah tidak pada tempat yang telah ditentukan dan disediakan; b. melakukan penanganan sampah dengan pembuangan terbuka di lahan terbuka; c. membakar sampah yang tidak sesuai dengan persyaratan teknis pengelolaan sampah.' },
    ]
  },

  // ─── TATA RUANG / BANGUNAN GEDUNG ────────────────────────────────────────
  {
    jenis: 'UU', nomor: '28', tahun: 2002,
    judul: 'Undang-Undang Nomor 28 Tahun 2002 tentang Bangunan Gedung',
    status: 'berlaku', status_detail: 'Diubah dengan UU No. 11/2020 (Cipta Kerja) dan UU No. 6/2023; Mengatur transisi dari IMB ke PBG',
    wilayah: 'Nasional', sektor: 'Tata Ruang',
    url: 'https://peraturan.bpk.go.id/Details/44487/uu-no-28-tahun-2002',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Bangunan gedung adalah wujud fisik hasil pekerjaan konstruksi yang menyatu dengan tempat kedudukannya, sebagian atau seluruhnya berada di atas dan/atau di dalam tanah dan/atau air, yang berfungsi sebagai tempat manusia melakukan kegiatannya, baik untuk hunian atau tempat tinggal, kegiatan keagamaan, kegiatan usaha, kegiatan sosial, budaya, maupun kegiatan khusus.' },
      { nomor: 'Pasal 7', ayat: 'Ayat (1)', teks: 'Setiap bangunan gedung harus memenuhi persyaratan administratif dan persyaratan teknis sesuai dengan fungsi bangunan gedung.' },
      { nomor: 'Pasal 35', ayat: 'Ayat (1)', teks: 'Pemerintah daerah wajib menerbitkan Persetujuan Bangunan Gedung sesuai dengan ketentuan peraturan perundang-undangan.' },
    ]
  },
  {
    jenis: 'PP', nomor: '16', tahun: 2021,
    judul: 'Peraturan Pemerintah Nomor 16 Tahun 2021 tentang Peraturan Pelaksanaan Undang-Undang Nomor 28 Tahun 2002 tentang Bangunan Gedung',
    status: 'berlaku', status_detail: 'Mencabut PP No. 36/2005; Bagian dari kluster Cipta Kerja; Mengatur transisi IMB ke PBG',
    wilayah: 'Nasional', sektor: 'Tata Ruang',
    url: 'https://peraturan.bpk.go.id/Details/161846/pp-no-16-tahun-2021',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 6', teks: 'Persetujuan Bangunan Gedung yang selanjutnya disingkat PBG adalah perizinan yang diberikan kepada pemilik Bangunan Gedung untuk membangun baru, mengubah, memperluas, mengurangi, dan/atau merawat Bangunan Gedung sesuai dengan standar teknis Bangunan Gedung.' },
      { nomor: 'Pasal 347', ayat: 'Ayat (1)', teks: 'Izin Mendirikan Bangunan yang telah diterbitkan sebelum berlakunya Peraturan Pemerintah ini dinyatakan tetap berlaku.' },
      { nomor: 'Pasal 350', ayat: '', teks: 'Pemerintah Daerah wajib melakukan penyesuaian Peraturan Daerah tentang bangunan gedung dengan ketentuan Peraturan Pemerintah ini paling lambat 1 (satu) tahun sejak berlakunya Peraturan Pemerintah ini.' },
    ]
  },

  // ─── PAJAK DAERAH & RETRIBUSI DAERAH (CIPTA KERJA) ───────────────────────
  {
    jenis: 'PP', nomor: '10', tahun: 2021,
    judul: 'Peraturan Pemerintah Nomor 10 Tahun 2021 tentang Pajak Daerah dan Retribusi Daerah dalam Rangka Mendukung Kemudahan Berusaha dan Layanan Daerah',
    status: 'berlaku', status_detail: 'Bagian dari kluster Cipta Kerja; Mengatur PDRD dalam rangka kemudahan berusaha',
    wilayah: 'Nasional', sektor: 'Keuangan Daerah',
    url: 'https://peraturan.bpk.go.id/Details/161840/pp-no-10-tahun-2021',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Pajak Daerah, yang selanjutnya disebut Pajak, adalah kontribusi wajib kepada Daerah yang terutang oleh orang pribadi atau badan yang bersifat memaksa berdasarkan Undang-Undang, dengan tidak mendapatkan imbalan secara langsung dan digunakan untuk keperluan Daerah bagi sebesar-besarnya kemakmuran rakyat.' },
      { nomor: 'Pasal 4', ayat: 'Ayat (1)', teks: 'Peraturan Daerah tentang PDRD yang tidak sesuai dengan ketentuan peraturan perundang-undangan yang lebih tinggi dinyatakan tidak berlaku dan harus disesuaikan.' },
      { nomor: 'Pasal 8', ayat: 'Ayat (1)', teks: 'Kepala Daerah melalui Menteri melaporkan Peraturan Daerah yang mengatur PDRD kepada Pemerintah Pusat.' },
    ]
  },

  // ─── KETENAGAKERJAAN (CIPTA KERJA) ───────────────────────────────────────
  {
    jenis: 'PP', nomor: '35', tahun: 2021,
    judul: 'Peraturan Pemerintah Nomor 35 Tahun 2021 tentang Perjanjian Kerja Waktu Tertentu, Alih Daya, Waktu Kerja dan Waktu Istirahat, dan Pemutusan Hubungan Kerja',
    status: 'berlaku', status_detail: 'Bagian dari kluster Cipta Kerja; Melaksanakan UU No. 13/2003 sebagaimana diubah UU 11/2020',
    wilayah: 'Nasional', sektor: 'Ketenagakerjaan',
    url: 'https://peraturan.bpk.go.id/Details/161904/pp-no-35-tahun-2021',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Perjanjian Kerja Waktu Tertentu yang selanjutnya disingkat PKWT adalah perjanjian kerja antara pekerja/buruh dengan pengusaha untuk mengadakan hubungan kerja dalam waktu tertentu atau untuk pekerjaan tertentu.' },
      { nomor: 'Pasal 5', ayat: 'Ayat (1)', teks: 'PKWT berdasarkan jangka waktu dibuat untuk paling lama 5 (lima) tahun.' },
      { nomor: 'Pasal 37', ayat: 'Ayat (1)', teks: 'Waktu kerja paling lama 8 (delapan) jam 1 (satu) hari dan 40 (empat puluh) jam 1 (satu) minggu, untuk 5 (lima) hari kerja dalam 1 (satu) minggu.' },
      { nomor: 'Pasal 40', ayat: 'Ayat (1)', teks: 'Pemutusan Hubungan Kerja mengakibatkan pengusaha wajib membayar uang pesangon, uang penghargaan masa kerja, dan/atau uang penggantian hak sesuai ketentuan.' },
    ]
  },
  {
    jenis: 'PP', nomor: '36', tahun: 2021,
    judul: 'Peraturan Pemerintah Nomor 36 Tahun 2021 tentang Pengupahan',
    status: 'berlaku', status_detail: 'Bagian dari kluster Cipta Kerja; Mencabut PP No. 78/2015 tentang Pengupahan',
    wilayah: 'Nasional', sektor: 'Ketenagakerjaan',
    url: 'https://peraturan.bpk.go.id/Details/161909/pp-no-36-tahun-2021',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Upah adalah hak pekerja/buruh yang diterima dan dinyatakan dalam bentuk uang sebagai imbalan dari pengusaha atau pemberi kerja kepada pekerja/buruh yang ditetapkan dan dibayarkan menurut suatu perjanjian kerja, kesepakatan, atau peraturan perundang-undangan.' },
      { nomor: 'Pasal 26', ayat: 'Ayat (1)', teks: 'Gubernur menetapkan Upah Minimum Provinsi setiap tahun berdasarkan kondisi ekonomi dan ketenagakerjaan.' },
      { nomor: 'Pasal 33', ayat: 'Ayat (1)', teks: 'Bupati/Wali Kota dapat menetapkan UMK dengan syarat lebih besar dari UMP.' },
    ]
  },
];

// ─── URL UPDATES ──────────────────────────────────────────────────────────────
// Fix Perda Kalsel 7/2019 URL from JDIH to BPK, and fix source code bugs

const URL_UPDATES = [
  {
    jenis: 'PERDA', nomor: '7', tahun: 2019,
    newUrl: 'https://peraturan.bpk.go.id/Details/122053/perda-prov-kalimantan-selatan-no-7-tahun-2019',
    note: 'Perda Prov. Kalimantan Selatan No. 7 Tahun 2019 tentang Penyelenggaraan Jasa Konstruksi',
  },
  {
    jenis: 'UU', nomor: '12', tahun: 2011,
    newUrl: 'https://peraturan.bpk.go.id/Details/39188/uu-no-12-tahun-2011',
    note: 'UU 12/2011 — fix URL from wrong Details/39045 to correct Details/39188',
  },
  {
    jenis: 'PP', nomor: '43', tahun: 2014,
    newUrl: 'https://peraturan.bpk.go.id/Details/5482/pp-no-43-tahun-2014',
    note: 'PP 43/2014 — fix URL from wrong Details/5301 to correct Details/5482',
  },
];

export async function expandRegulations2() {
  console.log(`\n=== EXPANDING REGULATION DATABASE (Batch 2) ===`);
  console.log(`Adding ${NEW_REGULATIONS.length} new regulations...`);
  console.log(`Updating ${URL_UPDATES.length} existing URLs...\n`);

  const client = await pool.connect();
  let added = 0;
  let skipped = 0;
  let urlsFixed = 0;

  try {
    await client.query('BEGIN');

    // ── Fix existing URLs ─────────────────────────────────────────────────
    for (const upd of URL_UPDATES) {
      const res = await client.query(
        `UPDATE peraturan SET url_dokumen_asli = $1, tanggal_dicek_terakhir = NOW()
         WHERE jenis_peraturan = $2 AND nomor = $3 AND tahun = $4`,
        [upd.newUrl, upd.jenis, upd.nomor, upd.tahun]
      );
      if (res.rowCount && res.rowCount > 0) {
        console.log(`  URL FIXED: ${upd.note}`);
        urlsFixed++;
      } else {
        console.log(`  URL SKIP (not found): ${upd.note}`);
      }
    }

    // ── Add new regulations ───────────────────────────────────────────────
    for (const reg of NEW_REGULATIONS) {
      const exists = await client.query(
        `SELECT id FROM peraturan WHERE jenis_peraturan=$1 AND nomor=$2 AND tahun=$3`,
        [reg.jenis, reg.nomor, reg.tahun]
      );

      if (exists.rows.length > 0) {
        console.log(`  SKIP (exists): ${reg.jenis} No.${reg.nomor}/${reg.tahun}`);
        skipped++;
        continue;
      }

      const res = await client.query(`
        INSERT INTO peraturan (jenis_peraturan, nomor, tahun, judul, status, status_detail, status_detail_json, wilayah, sektor, url_dokumen_asli, status_tautan, tanggal_diambil, tanggal_dicek_terakhir)
        VALUES ($1, $2, $3, $4, $5, $6, '{}', $7, $8, $9, 'normal', NOW(), NOW())
        RETURNING id;
      `, [reg.jenis, reg.nomor, reg.tahun, reg.judul, reg.status, reg.status_detail || '', reg.wilayah, reg.sektor, reg.url]);

      const regId = res.rows[0].id;

      for (const p of reg.pasalList) {
        await client.query(`
          INSERT INTO pasal (peraturan_id, nomor_pasal, nomor_ayat, teks_pasal)
          VALUES ($1, $2, $3, $4);
        `, [regId, p.nomor, p.ayat, p.teks]);
      }

      console.log(`  ADDED: ${reg.jenis} No.${reg.nomor}/${reg.tahun} — ${reg.pasalList.length} pasal`);
      added++;
    }

    await client.query('COMMIT');
    console.log(`\nDone. Added: ${added} | Skipped: ${skipped} | URLs Fixed: ${urlsFixed}`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Fatal:', err);
    throw err;
  } finally {
    client.release();
  }
}

expandRegulations2().then(() => process.exit(0)).catch(() => process.exit(1));
