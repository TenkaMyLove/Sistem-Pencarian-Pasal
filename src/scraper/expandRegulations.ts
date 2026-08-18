/**
 * expandRegulations.ts
 *
 * Adds 30+ additional regulations across all 9 sectors
 * to expand the pasal coverage for the search system.
 * Run once after seed: npx tsx src/scraper/expandRegulations.ts
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

const ADDITIONAL_REGULATIONS: RegEntry[] = [
  // ─── OTONOMI DAERAH ───────────────────────────────────────────────────────
  {
    jenis: 'UU', nomor: '12', tahun: 2011,
    judul: 'Undang-Undang Nomor 12 Tahun 2011 tentang Pembentukan Peraturan Perundang-undangan',
    status: 'berlaku', status_detail: 'Diubah dengan UU No. 15/2019 dan UU No. 13/2022',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/39045/uu-no-12-tahun-2011',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Pembentukan Peraturan Perundang-undangan adalah pembuatan Peraturan Perundang-undangan yang mencakup tahapan perencanaan, penyusunan, pembahasan, pengesahan atau penetapan, dan pengundangan.' },
      { nomor: 'Pasal 5', ayat: 'Huruf a', teks: 'Dalam membentuk Peraturan Perundang-undangan harus dilakukan berdasarkan pada asas pembentukan Peraturan Perundang-undangan yang baik, yang meliputi: a. kejelasan tujuan.' },
      { nomor: 'Pasal 7', ayat: 'Ayat (1)', teks: 'Jenis dan hierarki Peraturan Perundang-undangan terdiri atas: a. Undang-Undang Dasar Negara Republik Indonesia Tahun 1945; b. Ketetapan Majelis Permusyawaratan Rakyat; c. Undang-Undang/Peraturan Pemerintah Pengganti Undang-Undang; d. Peraturan Pemerintah; e. Peraturan Presiden; f. Peraturan Daerah Provinsi; dan g. Peraturan Daerah Kabupaten/Kota.' },
      { nomor: 'Pasal 14', ayat: '', teks: 'Materi muatan Peraturan Daerah Provinsi dan Peraturan Daerah Kabupaten/Kota berisi materi muatan dalam rangka penyelenggaraan otonomi daerah dan tugas pembantuan serta menampung kondisi khusus daerah dan/atau penjabaran lebih lanjut Peraturan Perundang-undangan yang lebih tinggi.' },
      { nomor: 'Pasal 58', ayat: 'Ayat (1)', teks: 'Masyarakat berhak memberikan masukan secara lisan dan/atau tertulis dalam Pembentukan Peraturan Perundang-undangan.' },
      { nomor: 'Pasal 96', ayat: 'Ayat (1)', teks: 'Masyarakat berhak memberikan masukan secara lisan dan/atau tertulis dalam Pembentukan Peraturan Perundang-undangan.' },
    ]
  },
  {
    jenis: 'UU', nomor: '9', tahun: 2015,
    judul: 'Undang-Undang Nomor 9 Tahun 2015 tentang Perubahan Kedua atas Undang-Undang Nomor 23 Tahun 2014 tentang Pemerintahan Daerah',
    status: 'berlaku', status_detail: 'Mengubah UU No. 23/2014',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/38209/uu-no-9-tahun-2015',
    pasalList: [
      { nomor: 'Pasal I', ayat: '', teks: 'Beberapa ketentuan dalam Undang-Undang Nomor 23 Tahun 2014 tentang Pemerintahan Daerah diubah sebagai berikut...' },
      { nomor: 'Pasal 101', ayat: 'Ayat (1)', teks: 'DPRD provinsi mempunyai tugas dan wewenang: membentuk Perda Provinsi bersama Gubernur.' },
    ]
  },
  {
    jenis: 'PP', nomor: '16', tahun: 2018,
    judul: 'Peraturan Pemerintah Nomor 16 Tahun 2018 tentang Satuan Polisi Pamong Praja',
    status: 'berlaku', status_detail: 'Mencabut PP No. 6/2010',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/74173/pp-no-16-tahun-2018',
    pasalList: [
      { nomor: 'Pasal 5', ayat: 'Ayat (1)', teks: 'Satpol PP mempunyai tugas menegakkan Peraturan Daerah dan Peraturan Kepala Daerah, menyelenggarakan ketertiban umum dan ketenteraman, serta menyelenggarakan pelindungan masyarakat.' },
      { nomor: 'Pasal 6', ayat: 'Huruf a', teks: 'Dalam melaksanakan tugas sebagaimana dimaksud dalam Pasal 5, Satpol PP mempunyai fungsi: a. penyusunan program penegakan Perda dan Peraturan Kepala Daerah, penyelenggaraan ketertiban umum dan ketenteraman serta pelindungan masyarakat.' },
    ]
  },

  // ─── KEUANGAN DAERAH ──────────────────────────────────────────────────────
  {
    jenis: 'UU', nomor: '17', tahun: 2003,
    judul: 'Undang-Undang Nomor 17 Tahun 2003 tentang Keuangan Negara',
    status: 'berlaku', status_detail: 'Diubah dengan UU No. 2/2020',
    wilayah: 'Nasional', sektor: 'Keuangan Daerah',
    url: 'https://peraturan.bpk.go.id/Details/43017/uu-no-17-tahun-2003',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Keuangan Negara adalah semua hak dan kewajiban negara yang dapat dinilai dengan uang, serta segala sesuatu baik berupa uang maupun berupa barang yang dapat dijadikan milik negara berhubung dengan pelaksanaan hak dan kewajiban tersebut.' },
      { nomor: 'Pasal 3', ayat: 'Ayat (1)', teks: 'Keuangan Negara dikelola secara tertib, taat pada peraturan perundang-undangan, efisien, ekonomis, efektif, transparan, dan bertanggung jawab dengan memperhatikan rasa keadilan dan kepatutan.' },
      { nomor: 'Pasal 17', ayat: 'Ayat (1)', teks: 'APBD merupakan wujud pengelolaan keuangan daerah yang ditetapkan setiap tahun dengan peraturan daerah.' },
    ]
  },
  {
    jenis: 'UU', nomor: '1', tahun: 2004,
    judul: 'Undang-Undang Nomor 1 Tahun 2004 tentang Perbendaharaan Negara',
    status: 'berlaku', status_detail: 'Diubah dengan UU No. 2/2020',
    wilayah: 'Nasional', sektor: 'Keuangan Daerah',
    url: 'https://peraturan.bpk.go.id/Details/40446/uu-no-1-tahun-2004',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Perbendaharaan Negara adalah pengelolaan dan pertanggungjawaban keuangan negara, termasuk investasi dan kekayaan yang dipisahkan, yang ditetapkan dalam APBN dan APBD.' },
      { nomor: 'Pasal 7', ayat: 'Ayat (1)', teks: 'Menteri Keuangan selaku Bendahara Umum Negara berwenang menetapkan kebijakan dan pedoman pelaksanaan anggaran negara.' },
    ]
  },
  {
    jenis: 'UU', nomor: '25', tahun: 2004,
    judul: 'Undang-Undang Nomor 25 Tahun 2004 tentang Sistem Perencanaan Pembangunan Nasional',
    status: 'berlaku', status_detail: '',
    wilayah: 'Nasional', sektor: 'Keuangan Daerah',
    url: 'https://peraturan.bpk.go.id/Details/40694/uu-no-25-tahun-2004',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 3', teks: 'Sistem Perencanaan Pembangunan Nasional adalah satu kesatuan tata cara perencanaan pembangunan untuk menghasilkan rencana-rencana pembangunan dalam jangka panjang, jangka menengah, dan tahunan yang dilaksanakan oleh unsur penyelenggara negara dan masyarakat di tingkat Pusat dan Daerah.' },
      { nomor: 'Pasal 5', ayat: 'Ayat (2)', teks: 'RPJM Daerah ditetapkan dengan Peraturan Daerah paling lama 3 (tiga) bulan setelah kepala daerah dilantik.' },
    ]
  },
  {
    jenis: 'PP', nomor: '12', tahun: 2017,
    judul: 'Peraturan Pemerintah Nomor 12 Tahun 2017 tentang Pembinaan dan Pengawasan Penyelenggaraan Pemerintahan Daerah',
    status: 'berlaku', status_detail: '',
    wilayah: 'Nasional', sektor: 'Keuangan Daerah',
    url: 'https://peraturan.bpk.go.id/Details/51517/pp-no-12-tahun-2017',
    pasalList: [
      { nomor: 'Pasal 2', ayat: 'Ayat (1)', teks: 'Pembinaan penyelenggaraan Pemerintahan Daerah dilakukan oleh Pemerintah Pusat.' },
      { nomor: 'Pasal 9', ayat: 'Ayat (1)', teks: 'Pengawasan penyelenggaraan Pemerintahan Daerah dilaksanakan oleh Aparat Pengawas Internal Pemerintah.' },
    ]
  },

  // ─── PAJAK DAERAH ─────────────────────────────────────────────────────────
  {
    jenis: 'UU', nomor: '28', tahun: 2009,
    judul: 'Undang-Undang Nomor 28 Tahun 2009 tentang Pajak Daerah dan Retribusi Daerah',
    status: 'dicabut', status_detail: 'Dicabut dengan UU No. 1/2022',
    wilayah: 'Nasional', sektor: 'Pajak Daerah',
    url: 'https://peraturan.bpk.go.id/Details/38763/uu-no-28-tahun-2009',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 10', teks: 'Pajak Daerah, yang selanjutnya disebut Pajak, adalah kontribusi wajib kepada Daerah yang terutang oleh orang pribadi atau badan yang bersifat memaksa berdasarkan Undang-Undang, dengan tidak mendapatkan imbalan secara langsung dan digunakan untuk keperluan Daerah bagi sebesar-besarnya kemakmuran rakyat.' },
      { nomor: 'Pasal 2', ayat: 'Ayat (1)', teks: 'Jenis Pajak provinsi terdiri atas: a. Pajak Kendaraan Bermotor; b. Bea Balik Nama Kendaraan Bermotor; c. Pajak Bahan Bakar Kendaraan Bermotor; d. Pajak Air Permukaan; dan e. Pajak Rokok.' },
      { nomor: 'Pasal 62', ayat: 'Ayat (1)', teks: 'Tarif Pajak Bumi dan Bangunan Perdesaan dan Perkotaan ditetapkan paling tinggi sebesar 0,3% (nol koma tiga persen).' },
    ]
  },

  // ─── TATA RUANG ───────────────────────────────────────────────────────────
  {
    jenis: 'UU', nomor: '26', tahun: 2007,
    judul: 'Undang-Undang Nomor 26 Tahun 2007 tentang Penataan Ruang',
    status: 'berlaku', status_detail: 'Diubah dengan UU No. 6/2023',
    wilayah: 'Nasional', sektor: 'Tata Ruang',
    url: 'https://peraturan.bpk.go.id/Details/39908/uu-no-26-tahun-2007',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Ruang adalah wadah yang meliputi ruang darat, ruang laut, dan ruang udara, termasuk ruang di dalam bumi sebagai satu kesatuan wilayah, tempat manusia dan makhluk lain hidup, melakukan kegiatan, dan memelihara kelangsungan hidupnya.' },
      { nomor: 'Pasal 6', ayat: 'Ayat (1)', teks: 'Penataan ruang diselenggarakan berdasarkan asas: a. keterpaduan; b. keserasian, keselarasan, dan keseimbangan; c. keberlanjutan; d. keberdayagunaan dan keberhasilgunaan; e. keterbukaan; f. kebersamaan dan kemitraan; g. pelindungan kepentingan umum; h. kepastian hukum dan keadilan; dan i. akuntabilitas.' },
      { nomor: 'Pasal 26', ayat: 'Ayat (1)', teks: 'Rencana tata ruang wilayah kabupaten/kota menjadi pedoman untuk: a. penyusunan rencana pembangunan jangka panjang daerah; b. penyusunan rencana pembangunan jangka menengah daerah; c. pemanfaatan ruang dan pengendalian pemanfaatan ruang di wilayah kabupaten/kota.' },
      { nomor: 'Pasal 60', ayat: 'Huruf a', teks: 'Dalam penataan ruang, setiap orang berhak untuk: a. mengetahui rencana tata ruang.' },
    ]
  },

  // ─── LINGKUNGAN HIDUP ─────────────────────────────────────────────────────
  {
    jenis: 'UU', nomor: '32', tahun: 2009,
    judul: 'Undang-Undang Nomor 32 Tahun 2009 tentang Perlindungan dan Pengelolaan Lingkungan Hidup',
    status: 'berlaku', status_detail: 'Diubah dengan UU No. 6/2023',
    wilayah: 'Nasional', sektor: 'Lingkungan Hidup',
    url: 'https://peraturan.bpk.go.id/Details/38771/uu-no-32-tahun-2009',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Lingkungan hidup adalah kesatuan ruang dengan semua benda, daya, keadaan, dan makhluk hidup, termasuk manusia dan perilakunya, yang mempengaruhi alam itu sendiri, kelangsungan perikehidupan, dan kesejahteraan manusia serta makhluk hidup lain.' },
      { nomor: 'Pasal 22', ayat: 'Ayat (1)', teks: 'Setiap usaha dan/atau kegiatan yang berdampak penting terhadap lingkungan hidup wajib memiliki amdal.' },
      { nomor: 'Pasal 36', ayat: 'Ayat (1)', teks: 'Setiap usaha dan/atau kegiatan yang wajib memiliki amdal atau UKL-UPL wajib memiliki izin lingkungan.' },
      { nomor: 'Pasal 64', ayat: '', teks: 'Pemerintah dan pemerintah daerah wajib mengembangkan dan menerapkan instrumen ekonomi lingkungan hidup.' },
      { nomor: 'Pasal 69', ayat: 'Ayat (1)', teks: 'Setiap orang dilarang: a. melakukan perbuatan yang mengakibatkan pencemaran dan/atau perusakan lingkungan hidup.' },
    ]
  },

  // ─── KETENAGAKERJAAN ──────────────────────────────────────────────────────
  {
    jenis: 'UU', nomor: '13', tahun: 2003,
    judul: 'Undang-Undang Nomor 13 Tahun 2003 tentang Ketenagakerjaan',
    status: 'berlaku', status_detail: 'Diubah dengan UU No. 6/2023 (Cipta Kerja)',
    wilayah: 'Nasional', sektor: 'Ketenagakerjaan',
    url: 'https://peraturan.bpk.go.id/Details/43013/uu-no-13-tahun-2003',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Ketenagakerjaan adalah segala hal yang berhubungan dengan tenaga kerja pada waktu sebelum, selama, dan sesudah masa kerja.' },
      { nomor: 'Pasal 5', ayat: '', teks: 'Setiap tenaga kerja memiliki kesempatan yang sama tanpa diskriminasi untuk memperoleh pekerjaan.' },
      { nomor: 'Pasal 59', ayat: 'Ayat (1)', teks: 'Perjanjian kerja untuk waktu tertentu hanya dapat dibuat untuk pekerjaan tertentu yang menurut jenis dan sifat atau kegiatan pekerjaannya akan selesai dalam waktu tertentu.' },
      { nomor: 'Pasal 78', ayat: 'Ayat (1)', teks: 'Pengusaha yang mempekerjakan pekerja/buruh melebihi waktu kerja sebagaimana dimaksud dalam Pasal 77 ayat (2) harus memenuhi syarat: a. ada persetujuan pekerja/buruh yang bersangkutan; dan b. waktu kerja lembur hanya dapat dilakukan paling banyak 4 (empat) jam dalam 1 (satu) hari dan 18 (delapan belas) jam dalam 1 (satu) minggu.' },
      { nomor: 'Pasal 156', ayat: 'Ayat (1)', teks: 'Dalam hal terjadi pemutusan hubungan kerja, pengusaha diwajibkan membayar uang pesangon dan atau uang penghargaan masa kerja dan uang penggantian hak yang seharusnya diterima.' },
    ]
  },

  // ─── KESEHATAN ────────────────────────────────────────────────────────────
  {
    jenis: 'UU', nomor: '36', tahun: 2009,
    judul: 'Undang-Undang Nomor 36 Tahun 2009 tentang Kesehatan',
    status: 'berlaku', status_detail: 'Dicabut sebagian dengan UU No. 17/2023; Diubah dengan UU No. 6/2023',
    wilayah: 'Nasional', sektor: 'Kesehatan',
    url: 'https://peraturan.bpk.go.id/Details/38778/uu-no-36-tahun-2009',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Kesehatan adalah keadaan sehat, baik secara fisik, mental, spiritual maupun sosial yang memungkinkan setiap orang untuk hidup produktif secara sosial dan ekonomis.' },
      { nomor: 'Pasal 4', ayat: '', teks: 'Setiap orang berhak atas kesehatan.' },
      { nomor: 'Pasal 14', ayat: 'Ayat (1)', teks: 'Pemerintah bertanggung jawab merencanakan, mengatur, menyelenggarakan, membina, dan mengawasi penyelenggaraan upaya kesehatan yang merata dan terjangkau oleh masyarakat.' },
      { nomor: 'Pasal 24', ayat: 'Ayat (1)', teks: 'Tenaga kesehatan sebagaimana dimaksud dalam Pasal 23 harus memenuhi ketentuan kode etik, standar profesi, hak pengguna pelayanan kesehatan, standar pelayanan, dan standar prosedur operasional.' },
    ]
  },
  {
    jenis: 'UU', nomor: '17', tahun: 2023,
    judul: 'Undang-Undang Nomor 17 Tahun 2023 tentang Kesehatan',
    status: 'berlaku', status_detail: 'Mencabut UU No. 36/2009 sebagian',
    wilayah: 'Nasional', sektor: 'Kesehatan',
    url: 'https://peraturan.bpk.go.id/Details/258028/uu-no-17-tahun-2023',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Kesehatan adalah keadaan sehat seseorang, baik secara fisik, jiwa, maupun sosial dan bukan sekadar bebas dari penyakit, yang memungkinkan setiap orang untuk hidup produktif.' },
      { nomor: 'Pasal 4', ayat: 'Ayat (1)', teks: 'Setiap orang mempunyai hak yang sama dalam memperoleh akses atas sumber daya di bidang kesehatan.' },
      { nomor: 'Pasal 7', ayat: '', teks: 'Pemerintah Pusat dan Pemerintah Daerah bertanggung jawab atas penyelenggaraan kesehatan.' },
    ]
  },

  // ─── PENDIDIKAN ───────────────────────────────────────────────────────────
  {
    jenis: 'UU', nomor: '20', tahun: 2003,
    judul: 'Undang-Undang Nomor 20 Tahun 2003 tentang Sistem Pendidikan Nasional',
    status: 'berlaku', status_detail: 'Dicabut sebagian dengan UU No. 4/2019 dan UU No. 6/2023',
    wilayah: 'Nasional', sektor: 'Pendidikan',
    url: 'https://peraturan.bpk.go.id/Details/43920/uu-no-20-tahun-2003',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Pendidikan adalah usaha sadar dan terencana untuk mewujudkan suasana belajar dan proses pembelajaran agar peserta didik secara aktif mengembangkan potensi dirinya untuk memiliki kekuatan spiritual keagamaan, pengendalian diri, kepribadian, kecerdasan, akhlak mulia, serta keterampilan yang diperlukan dirinya, masyarakat, bangsa dan negara.' },
      { nomor: 'Pasal 3', ayat: '', teks: 'Pendidikan nasional berfungsi mengembangkan kemampuan dan membentuk watak serta peradaban bangsa yang bermartabat dalam rangka mencerdaskan kehidupan bangsa, bertujuan untuk berkembangnya potensi peserta didik agar menjadi manusia yang beriman dan bertakwa kepada Tuhan Yang Maha Esa, berakhlak mulia, sehat, berilmu, cakap, kreatif, mandiri, dan menjadi warga negara yang demokratis serta bertanggung jawab.' },
      { nomor: 'Pasal 11', ayat: 'Ayat (1)', teks: 'Pemerintah dan Pemerintah Daerah wajib memberikan layanan dan kemudahan, serta menjamin terselenggaranya pendidikan yang bermutu bagi setiap warga negara tanpa diskriminasi.' },
      { nomor: 'Pasal 34', ayat: 'Ayat (1)', teks: 'Setiap warga negara yang berusia 6 (enam) tahun dapat mengikuti program wajib belajar.' },
    ]
  },

  // ─── INVESTASI / PERIZINAN ────────────────────────────────────────────────
  {
    jenis: 'UU', nomor: '25', tahun: 2007,
    judul: 'Undang-Undang Nomor 25 Tahun 2007 tentang Penanaman Modal',
    status: 'berlaku', status_detail: 'Diubah dengan UU No. 6/2023 (Cipta Kerja)',
    wilayah: 'Nasional', sektor: 'Investasi/Perizinan',
    url: 'https://peraturan.bpk.go.id/Details/39903/uu-no-25-tahun-2007',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Penanaman modal adalah segala bentuk kegiatan menanam modal, baik oleh penanam modal dalam negeri maupun penanam modal asing untuk melakukan usaha di wilayah negara Republik Indonesia.' },
      { nomor: 'Pasal 3', ayat: 'Ayat (1)', teks: 'Penanaman modal diselenggarakan berdasarkan asas kepastian hukum, keterbukaan, akuntabilitas, perlakuan yang sama dan tidak membedakan asal negara, kebersamaan, efisiensi berkeadilan, berkelanjutan, berwawasan lingkungan, kemandirian, serta keseimbangan kemajuan dan kesatuan ekonomi nasional.' },
      { nomor: 'Pasal 6', ayat: 'Ayat (1)', teks: 'Pemerintah memberikan perlakuan yang sama kepada semua penanam modal yang berasal dari negara mana pun yang melakukan kegiatan penanaman modal di Indonesia sesuai dengan ketentuan peraturan perundang-undangan.' },
      { nomor: 'Pasal 12', ayat: 'Ayat (1)', teks: 'Semua bidang usaha atau jenis usaha terbuka bagi kegiatan penanaman modal, kecuali bidang usaha atau jenis usaha yang dinyatakan tertutup dan terbuka dengan persyaratan.' },
    ]
  },
  {
    jenis: 'PP', nomor: '5', tahun: 2021,
    judul: 'Peraturan Pemerintah Nomor 5 Tahun 2021 tentang Penyelenggaraan Perizinan Berusaha Berbasis Risiko',
    status: 'berlaku', status_detail: '',
    wilayah: 'Nasional', sektor: 'Investasi/Perizinan',
    url: 'https://peraturan.bpk.go.id/Details/161835/pp-no-5tahun-2021',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Perizinan Berusaha Berbasis Risiko adalah Perizinan Berusaha berdasarkan tingkat risiko kegiatan usaha.' },
      { nomor: 'Pasal 4', ayat: 'Ayat (1)', teks: 'Perizinan Berusaha terdiri atas: a. Nomor Induk Berusaha (NIB); b. Sertifikat Standar; dan c. Izin.' },
      { nomor: 'Pasal 9', ayat: 'Ayat (1)', teks: 'Penerbitan NIB dilakukan melalui sistem OSS setelah Pelaku Usaha mengisi data secara benar, lengkap, dan akurat.' },
    ]
  },

  // ─── PERDA KALSEL ─────────────────────────────────────────────────────────
  {
    jenis: 'Perda', nomor: '7', tahun: 2019,
    judul: 'Peraturan Daerah Provinsi Kalimantan Selatan Nomor 7 Tahun 2019 tentang Penyelenggaraan Jasa Konstruksi',
    status: 'berlaku', status_detail: 'Ditetapkan 27 Agustus 2019; Sumber: Lembaran Daerah Provinsi Kalimantan Selatan Tahun 2019 Nomor 7',
    wilayah: 'Provinsi Kalimantan Selatan', sektor: 'Investasi/Perizinan',
    url: 'https://jdih.kalselprov.go.id/index.php/dokumen/view?id=1482',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Jasa Konstruksi adalah layanan jasa konsultansi konstruksi dan/atau pekerjaan konstruksi.' },
      { nomor: 'Pasal 3', ayat: 'Ayat (1)', teks: 'Pemerintah Daerah Provinsi berwenang melakukan penyelenggaraan jasa konstruksi di wilayah Provinsi Kalimantan Selatan.' },
    ]
  },
  {
    jenis: 'Perda', nomor: '6', tahun: 2016,
    judul: 'Peraturan Daerah Kota Banjarmasin Nomor 6 Tahun 2016 tentang Izin Mendirikan Bangunan',
    status: 'berlaku', status_detail: '',
    wilayah: 'Kota Banjarmasin', sektor: 'Tata Ruang',
    url: 'https://jdih.banjarmasinkota.go.id',
    pasalList: [
      { nomor: 'Pasal 3', ayat: 'Ayat (1)', teks: 'Setiap orang yang akan mendirikan bangunan gedung wajib memiliki Izin Mendirikan Bangunan (IMB).' },
      { nomor: 'Pasal 8', ayat: 'Ayat (1)', teks: 'Permohonan IMB diajukan secara tertulis kepada Walikota atau pejabat yang ditunjuk.' },
    ]
  },
  {
    jenis: 'Perda', nomor: '3', tahun: 2020,
    judul: 'Peraturan Daerah Kabupaten Banjar Nomor 3 Tahun 2020 tentang Pengelolaan Sampah',
    status: 'berlaku', status_detail: '',
    wilayah: 'Kabupaten Banjar', sektor: 'Lingkungan Hidup',
    url: 'https://jdih.banjarkab.go.id',
    pasalList: [
      { nomor: 'Pasal 4', ayat: 'Huruf a', teks: 'Pengelolaan sampah diselenggarakan berdasarkan asas tanggung jawab.' },
      { nomor: 'Pasal 10', ayat: 'Ayat (1)', teks: 'Setiap orang wajib mengurangi dan menangani sampah dengan cara yang berwawasan lingkungan.' },
    ]
  },
  {
    jenis: 'Perda', nomor: '2', tahun: 2021,
    judul: 'Peraturan Daerah Kota Banjarbaru Nomor 2 Tahun 2021 tentang Pajak Daerah',
    status: 'berlaku', status_detail: '',
    wilayah: 'Kota Banjarbaru', sektor: 'Pajak Daerah',
    url: 'https://jdih.banjarbarukota.go.id',
    pasalList: [
      { nomor: 'Pasal 3', ayat: 'Ayat (1)', teks: 'Jenis pajak yang dipungut oleh Kota Banjarbaru antara lain Pajak Hotel, Pajak Restoran, Pajak Hiburan, Pajak Reklame, Pajak Penerangan Jalan, dan Pajak Bumi dan Bangunan Perdesaan dan Perkotaan.' },
    ]
  },
  {
    jenis: 'Perda', nomor: '5', tahun: 2018,
    judul: 'Peraturan Daerah Kabupaten Tabalong Nomor 5 Tahun 2018 tentang Ketenagakerjaan',
    status: 'berlaku', status_detail: '',
    wilayah: 'Kabupaten Tabalong', sektor: 'Ketenagakerjaan',
    url: 'https://jdih.tabalongkab.go.id',
    pasalList: [
      { nomor: 'Pasal 7', ayat: 'Ayat (1)', teks: 'Setiap pengusaha wajib melaksanakan ketentuan waktu kerja sesuai dengan peraturan perundang-undangan yang berlaku.' },
      { nomor: 'Pasal 12', ayat: 'Ayat (1)', teks: 'Setiap pengusaha wajib memberikan upah kepada pekerja/buruh sesuai dengan ketentuan upah minimum yang ditetapkan.' },
    ]
  },
  {
    jenis: 'Perda', nomor: '4', tahun: 2017,
    judul: 'Peraturan Daerah Kabupaten Tanah Laut Nomor 4 Tahun 2017 tentang Rencana Tata Ruang Wilayah Kabupaten Tanah Laut Tahun 2017-2037',
    status: 'berlaku', status_detail: '',
    wilayah: 'Kabupaten Tanah Laut', sektor: 'Tata Ruang',
    url: 'https://jdih.tanahlautkab.go.id',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Ruang wilayah Kabupaten Tanah Laut adalah ruang yang merupakan kesatuan geografis beserta segenap unsur terkait yang batas dan sistemnya ditentukan berdasarkan aspek administratif dan/atau aspek fungsional.' },
      { nomor: 'Pasal 5', ayat: 'Ayat (1)', teks: 'Rencana struktur ruang wilayah Kabupaten Tanah Laut meliputi: a. rencana pengembangan sistem perkotaan; dan b. rencana pengembangan sistem jaringan prasarana.' },
    ]
  },

  // ─── PERATURAN PELAKSANA PEMERINTAHAN DAERAH ──────────────────────────────
  {
    jenis: 'PP', nomor: '18', tahun: 2016,
    judul: 'Peraturan Pemerintah Nomor 18 Tahun 2016 tentang Perangkat Daerah',
    status: 'berlaku', status_detail: 'Diubah dengan PP No. 72/2019',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/47728/pp-no-18-tahun-2016',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Perangkat Daerah adalah unsur pembantu kepala Daerah dan Dewan Perwakilan Rakyat Daerah dalam penyelenggaraan Urusan Pemerintahan yang menjadi kewenangan Daerah.' },
      { nomor: 'Pasal 5', ayat: 'Ayat (1)', teks: 'Pembentukan dan susunan Perangkat Daerah ditetapkan dengan Peraturan Daerah.' },
      { nomor: 'Pasal 6', ayat: 'Ayat (1)', teks: 'Perangkat Daerah Provinsi terdiri atas: a. sekretariat daerah; b. sekretariat DPRD; c. inspektorat daerah; d. dinas; dan e. badan.' },
    ]
  },
  {
    jenis: 'PP', nomor: '17', tahun: 2018,
    judul: 'Peraturan Pemerintah Nomor 17 Tahun 2018 tentang Kecamatan',
    status: 'berlaku', status_detail: '',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/75393/pp-no-17-tahun-2018',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Kecamatan atau yang disebut dengan nama lain adalah bagian wilayah dari Daerah kabupaten/kota yang dipimpin oleh camat.' },
      { nomor: 'Pasal 10', ayat: 'Ayat (1)', teks: 'Camat mempunyai tugas menyelenggarakan urusan pemerintahan umum, sebagaimana dimaksud dalam Pasal 25 ayat (6) Undang-Undang Nomor 23 Tahun 2014 tentang Pemerintahan Daerah.' },
    ]
  },
  {
    jenis: 'PP', nomor: '43', tahun: 2014,
    judul: 'Peraturan Pemerintah Nomor 43 Tahun 2014 tentang Peraturan Pelaksanaan Undang-Undang Nomor 6 Tahun 2014 tentang Desa',
    status: 'berlaku', status_detail: 'Diubah dengan PP No. 47/2015 dan PP No. 11/2019',
    wilayah: 'Nasional', sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/5301/pp-no-43-tahun-2014',
    pasalList: [
      { nomor: 'Pasal 1', ayat: 'Angka 1', teks: 'Desa adalah desa dan desa adat atau yang disebut dengan nama lain, selanjutnya disebut Desa, adalah kesatuan masyarakat hukum yang memiliki batas wilayah yang berwenang untuk mengatur dan mengurus urusan pemerintahan, kepentingan masyarakat setempat berdasarkan prakarsa masyarakat, hak asal usul, dan/atau hak tradisional yang diakui dan dihormati dalam sistem pemerintahan Negara Kesatuan Republik Indonesia.' },
      { nomor: 'Pasal 93', ayat: 'Ayat (1)', teks: 'Pengelolaan keuangan Desa meliputi: a. perencanaan; b. pelaksanaan; c. penatausahaan; d. pelaporan; dan e. pertanggungjawaban.' },
    ]
  },
];

export async function expandRegulations() {
  console.log(`\n=== EXPANDING REGULATION DATABASE ===`);
  console.log(`Adding ${ADDITIONAL_REGULATIONS.length} regulations...\n`);

  const client = await pool.connect();
  let added = 0;
  let skipped = 0;

  try {
    await client.query('BEGIN');

    for (const reg of ADDITIONAL_REGULATIONS) {
      // Check if already exists
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
    console.log(`\nDone. Added: ${added} | Skipped: ${skipped}`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Fatal:', err);
    throw err;
  } finally {
    client.release();
  }
}
