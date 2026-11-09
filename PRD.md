# Product Requirement Document (PRD)
## Sistem Pencarian Pasal — P3H Kemenkum Kalsel

**Versi**: 3.0  
**Tanggal Pembaruan**: 9 November 2026  
**Status**: Approved & Production Ready  
**Target Pengguna**: Divisi Peraturan Perundang-undangan dan Pembinaan Hukum (P3H), Kantor Wilayah Kementerian Hukum Kalimantan Selatan  

---

## 1. Latar Belakang & Tujuan Produk

Dalam proses harmonisasi Rancangan Peraturan Daerah (Ranperda) dan Rancangan Peraturan Kepala Daerah (Ranperkada) di lingkungan Kantor Wilayah Kementerian Hukum Kalimantan Selatan, tim Perancang Peraturan Perundang-undangan dan Pengelola Harmonisasi membutuhkan akses cepat, akurat, dan terintegrasi untuk mencari pasal-pasal rujukan dari berbagai tingkatan peraturan (UUD 1945, Undang-Undang, Peraturan Pemerintah, Peraturan Presiden, hingga Peraturan Daerah Provinsi dan Kabupaten/Kota se-Kalimantan Selatan).

### Tujuan Utama Produk:
1. **Mesin Pencari Pasal Real-Time & Cerdas**: Menyediakan pencarian pasal hukum yang instan, responsif, dan presisi (baik berbasis web HTMX tanpa *page reload* maupun aplikasi mobile Flutter).
2. **Keterhubungan Relasi Hukum Komprehensif**: Menyajikan relasi status hukum antar peraturan secara lengkap (*Mencabut*, *Dicabut Dengan*, *Diubah Dengan*, *Mengubah*, *Mencabut Sebagian*, dan *Dicabut Sebagian Dengan*).
3. **Manajemen Agenda Rapat Harmonisasi**: Menyediakan agenda penjadwalan rapat harmonisasi Ranperda/Ranperkada yang terstruktur dengan dukungan multi-kompilator dan pengaturan hak akses peran.
4. **Ekspansi Data Otomatis (Web Crawler)**: Menyediakan alat pengindeksan peraturan dan pasal baru secara langsung melalui URL resmi portal hukum (JDIH BPK / Pemda).
5. **Aksesibilitas Multi-Platform**: Mendukung peramban web desktop dan aplikasi mobile Flutter multi-platform (Android, Web Browser, iOS) dengan tampilan modern dan efek skeletonizer.
6. **Verifikasi Keabsahan Dokumen**: Memastikan tautan dokumen sumber mengarah langsung ke dokumen resmi terverifikasi dengan pemantauan status keaktifan tautan (*normal* vs *tautan bermasalah*).

---

## 2. Pengguna & Peran (Role-Based Access Control / RBAC)

Sistem membagi akses pengguna ke dalam 4 tingkatan peran:

| Peran Pengguna | Label Tampilan Antarmuka | Deskripsi & Hak Akses |
|---|---|---|
| **Admin** | Administrator | • Manajemen akun pengguna & reset kata sandi staf (`/kelola-akun` & `/api/admin/*`)<br>• Pencarian Pasal & Monitoring Sistem |
| **Pengelola** | Pengelola & Kompilator | • Pencarian Pasal & Filter Peraturan<br>• Manajemen Jadwal Rapat Harmonisasi (**Full CRUD**: Tambah, Edit, Hapus)<br>• Tambah Peraturan & Pasal via Tautan URL Crawler |
| **Perancang** | Perancang Perundangan | • Pencarian Pasal & Filter Peraturan<br>• Jadwal Rapat Harmonisasi (**Read-Only** untuk koordinasi agenda) |
| **Tamu** | Mode Tamu / Publik | • Akses langsung Pencarian Pasal tanpa perlu login/autentikasi<br>• Dibatasi dari agenda rapat internal dan administrasi sistem |

---

## 3. Spesifikasi Fitur Utama

### 3.1. Mesin Pencarian Pasal & Filter Peraturan (Web & Mobile)
- **Pencarian Real-Time**: Pencarian berbasis HTMX (Web) dan debounce async reactive (Mobile) yang memperbarui hasil pencarian secara instan.
- **Word-Boundary Keyword Highlighting**: Penyorotan kata kunci pencarian pada teks pasal secara presisi menggunakan regex tanpa merusak struktur elemen antarmuka.
- **Dukungan Pencarian Peraturan Kosong (UNION Query)**: Peraturan yang baru diindeks tetapi belum memiliki pasal tetap muncul dalam hasil pencarian dengan keterangan informatif dan tautan dokumen asli.
- **Filter Sektor & Wilayah**:
  - **Sektor Hukum (9+ Sektor)**: Otonomi & Pemerintahan Daerah, Investasi & Perizinan, Keuangan Daerah, Tata Ruang & Bangunan, Lingkungan Hidup, Pajak & Retribusi Daerah, Ketenagakerjaan, Kesehatan, Pendidikan, Hukum Pidana & Jasa Konstruksi, dll.
  - **Wilayah**: Nasional, Provinsi Kalimantan Selatan, serta 13 Kabupaten/Kota se-Kalimantan Selatan.
- **Modal Interaktif Detil Status Peraturan (`StatusDetailModal`)**:
  - Menampilkan relasi status hukum lengkap yang dikelompokkan rapi (*Mencabut*, *Dicabut Dengan*, *Diubah Dengan*, *Mengubah*, dll).
  - Tautan dokumen relasi mengarah langsung ke portal resmi eksternal (BPK/JDIH) dengan indikator panah link keluar.
  - Linkify otomatis untuk sebutan pasal di dalam teks keterangan status (misal: "Pasal 238", "Pasal 15").
  - Dilengkapi tombol tutup bulat (✕) di pojok kanan atas serta penutupan otomatis saat klik area backdrop/luar modal.
- **Tautan Dokumen PDF Asli**:
  - Tombol tautan langsung ke portal JDIH BPK / Pemda.
  - Indikator badge otomatis `Tautan Bermasalah` jika terjadi kegagalan respon HTTP pada situs sumber.

### 3.2. Manajemen Jadwal Rapat Harmonisasi
- **Agenda Rapat Terstruktur**: Menampilkan No, Jenis Rancangan (Ranperda / Ranperkada), Pokok Materi (Tentang), Hari/Tanggal, Jam (WITA), Nama Kompilator, Tim Pokja (Pokja 1 / Pokja 2), dan Pembuat Agenda.
- **Dukungan Multi-Kompilator**: Checkbox pilihan perancang tim harmonisasi Kanwil serta entri manual nama kompilator tambahan.
- **Kontrol Hak Akses**: Pengelola memiliki kontrol CRUD penuh (Tambah, Ubah, Hapus), sedangkan akun Perancang dalam mode baca (*Read-Only*).

### 3.3. Tambah Peraturan via Tautan (Web Crawler & Ingestion)
- Fitur khusus peran Pengelola untuk mengindeks peraturan baru dengan memasukkan URL portal hukum.
- Crawler otomatis mengekstrak metadata (Jenis, Nomor, Tahun, Judul, Wilayah, Sektor), teks pasal, dan relasi hukum peraturan.
- Opsi fallback: kolom teks manual untuk menyalin isi peraturan PDF jika halaman sumber tidak menyediakan format HTML terstruktur.

### 3.4. Aplikasi Mobile Terintegrasi (Flutter)
- Dikembangkan menggunakan **Flutter** multi-platform (Android, Web Browser, iOS).
- **Skeletonizer Shimmer Effect**: Seluruh proses pemuatan data (pencarian pasal, jadwal rapat, detail status) menggunakan efek animasi *shimmer skeleton* yang modern.
- **Host Switcher Terintegrasi**: Dialog pengaturan IP/host backend yang memudahkan pengalihan antara Web Browser (`localhost:3000`), Emulator Android (`10.0.2.2:3000`), dan Device Fisik / LAN (`192.168.x.x:3000`).
- **Fitur Mobile Lengkap**: Salin teks pasal ke clipboard, pembaca detail pasal internal peraturan, dan CRUD jadwal rapat.

### 3.5. Kelola Akun & Reset Kata Sandi (Khusus Admin)
- Antarmuka khusus Administrator untuk memperbarui kata sandi akun operasional staf (*Pengelola* dan *Perancang*).
- Validasi keamanan: minimal 6 karakter, konfirmasi kecocokan kata sandi, dan penyimpanan terenkripsi menggunakan algoritma `bcrypt`.

---

## 4. Cakupan Data Peraturan (56 Peraturan Terindeks)

Basis data mencakup **56 Peraturan Perundang-Undangan** terverifikasi yang mencakup regulasi nasional dan daerah:

| Sektor Hukum | Peraturan Terindeks |
|---|---|
| **Otonomi & Pemda** | UUD 1945, UU 23/2014, UU 9/2015, UU 12/2011, UU 15/2019, UU 13/2022, UU 25/2004, UU 30/2014, UU 25/2009, UU 14/2008, UU 6/2014, UU 3/2024, PP 43/2014, PP 18/2016, PP 16/2018, PP 17/2018, PP 11/2019, PP 72/2019, Perda Kab. Tapin No. 7 Tahun 2021 |
| **Investasi & Perizinan** | UU 25/2007, UU 11/2020, UU 6/2023 (Cipta Kerja), PP 5/2021 (OSS RBA), Perda Prov. Kalsel No. 7 Tahun 2019 (Jasa Konstruksi) |
| **Keuangan Daerah** | UU 17/2003, UU 1/2004, PP 12/2017, PP 12/2019, PP 10/2021 |
| **Tata Ruang & Bangunan** | UU 26/2007, UU 28/2002, PP 21/2021, PP 16/2021, Perda Kota Banjarmasin No. 6 Tahun 2016 (IMB), Perda Kab. Tanah Laut No. 4 Tahun 2017 (RTRW) |
| **Lingkungan Hidup** | UU 32/2009, UU 18/2008, PP 22/2021, Perda Kab. Banjar No. 3 Tahun 2020 (Pengelolaan Sampah) |
| **Pajak & Retribusi Daerah** | UU 28/2009, UU 1/2022 (HKPD), Perda Kota Banjarbaru No. 2 Tahun 2021 |
| **Ketenagakerjaan** | UU 13/2003, PP 35/2021, PP 36/2021, Perda Kab. Tabalong No. 5 Tahun 2018 |
| **Kesehatan** | UU 36/2009, UU 17/2023 |
| **Pendidikan** | UU 20/2003 (Sisdiknas) |
| **Hukum Pidana & Jasa Konstruksi** | UU 1/2023 (KUHP Nasional), UU 1/2026, UU 2/2017, PP 14/2021 |
| **Perda Kalsel Lainnya** | Perda Prov. Kalsel No. 6 Tahun 2023, Perda Prov. Kalsel No. 11 Tahun 2016, Perda Prov. Kalsel No. 11 Tahun 2021 |

---

## 5. Arsitektur Teknis & Perangkat Lunak

```
   +------------------------------------+      +------------------------------------+
   |         Client Web Browser         |      |       Client Mobile App (Flutter)  |
   |      HTMX + Custom CSS P3H         |      |  Android / Chrome Web / iOS / Shimmer|
   +-----------------+------------------+      +-----------------+------------------+
                     |                                           |
                     | (HTML / HTMX SSR)                         | (JSON / REST API)
                     +--------------------+ ---------------------+
                                          |
                                          v
                     +-------------------------------------------+
                     |         Hono Web & API Server (Node 22)   |
                     |  - Middleware: Auth & RBAC Cookie/CORS    |
                     |  - SSR Engine: Hono JSX Components        |
                     |  - API Controller: /api/* Endpoints       |
                     |  - Scraper Engine: Cheerio & URL Crawler  |
                     +--------------------+----------------------+
                                          |
                                          v (Connection Pool mysql2)
                     +-------------------------------------------+
                     |         MySQL 8.x Database Engine         |
                     |  - Database: p3h_kemenkum_kalsel          |
                     |  - Full-Text Indexes: judul & teks_pasal  |
                     |  - JSON Columns: status_detail_json       |
                     +-------------------------------------------+
```

### Stack Teknologi:
- **Backend Runtime**: Node.js v20+ / v22+ (ESM)
- **Web Framework**: [Hono](https://hono.dev/) (SSR JSX & REST API)
- **Database Engine**: MySQL 8.x (`mysql2/promise` dengan Full-Text Indexing)
- **Frontend Web**: HTMX 1.9 + Custom Vanilla CSS
- **Mobile Framework**: Flutter 3.x & Dart 3.x (Multi-platform)
- **Mobile UI Libraries**: `skeletonizer`, `google_fonts`, `http`, `shared_preferences`, `url_launcher`
- **Web Scraper & Crawler**: `cheerio` + Native HTTP Client
- **Security & Hashing**: `bcryptjs` (Cost factor 10) + Cookie Session & CORS Management

---

## 6. Spesifikasi REST API Endpoints

Sistem menyediakan endpoint REST API untuk melayani aplikasi mobile dan integrasi pihak ketiga:

| Method | Endpoint | Deskripsi | Hak Akses |
|---|---|---|---|
| `GET` | `/api/health` | Pemeriksaan status server dan konektivitas | Publik |
| `POST` | `/api/auth/login` | Otentikasi pengguna dan penerbitan sesi peran | Publik |
| `GET` | `/api/search` | Pencarian peraturan/pasal dengan parameter `q`, `sektor`, `wilayah`, `page` | Publik / Tamu |
| `GET` | `/api/peraturan/:id` | Mengambil detail peraturan dan daftar seluruh pasalnya | Publik / Tamu |
| `GET` | `/api/jadwal` | Mengambil seluruh daftar agenda rapat harmonisasi | Staf Terdaftar |
| `POST` | `/api/jadwal` | Menambahkan agenda jadwal rapat baru | Pengelola / Admin |
| `PUT` | `/api/jadwal/:id` | Memperbarui data jadwal rapat harmonisasi | Pengelola / Admin |
| `DELETE` | `/api/jadwal/:id` | Menghapus agenda rapat harmonisasi | Pengelola / Admin |
| `GET` | `/api/admin/users` | Mengambil daftar akun pengguna sistem | Khusus Admin |
| `POST` | `/api/admin/reset-password` | Mereset kata sandi akun staf | Khusus Admin |
| `POST` | `/api/tambah-peraturan` | Menjalankan crawler untuk menambah peraturan dari link URL | Pengelola / Admin |

---

## 7. Skema Database MySQL 8.x (DDL Resmi)

Database `p3h_kemenkum_kalsel` menggunakan 7 tabel terstruktur:

```sql
-- 1. Tabel Peraturan
CREATE TABLE peraturan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    jenis_peraturan VARCHAR(100) NOT NULL,
    nomor VARCHAR(50) NOT NULL,
    tahun INT NOT NULL,
    judul TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'berlaku',
    status_detail TEXT,
    status_detail_json JSON,
    wilayah VARCHAR(150) NOT NULL DEFAULT 'Nasional',
    sektor VARCHAR(100),
    url_dokumen_asli TEXT NOT NULL,
    status_tautan VARCHAR(50) NOT NULL DEFAULT 'normal',
    tanggal_diambil DATETIME DEFAULT CURRENT_TIMESTAMP,
    tanggal_dicek_terakhir DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_peraturan_jenis (jenis_peraturan),
    INDEX idx_peraturan_tahun (tahun),
    INDEX idx_peraturan_wilayah (wilayah),
    INDEX idx_peraturan_sektor (sektor),
    FULLTEXT INDEX idx_peraturan_judul_ft (judul)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 2. Tabel Pasal
CREATE TABLE pasal (
    id INT AUTO_INCREMENT PRIMARY KEY,
    peraturan_id INT NOT NULL,
    nomor_pasal VARCHAR(50) NOT NULL,
    nomor_ayat VARCHAR(50),
    teks_pasal TEXT NOT NULL,
    CONSTRAINT fk_pasal_peraturan FOREIGN KEY (peraturan_id) REFERENCES peraturan(id) ON DELETE CASCADE,
    INDEX idx_pasal_peraturan_id (peraturan_id),
    INDEX idx_pasal_nomor_pasal (nomor_pasal),
    FULLTEXT INDEX idx_pasal_teks_ft (teks_pasal)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 3. Tabel Jadwal Rapat Harmonisasi
CREATE TABLE jadwal_rapat_harmonisasi (
    id INT AUTO_INCREMENT PRIMARY KEY,
    jenis_rancangan VARCHAR(50) NOT NULL,
    tentang TEXT NOT NULL,
    tanggal DATE NOT NULL,
    jam TIME NOT NULL,
    nama_kompilator VARCHAR(150) NOT NULL,
    tim_pokja VARCHAR(50) NOT NULL,
    dibuat_oleh VARCHAR(50) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_jadwal_tanggal (tanggal)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 4. Tabel Pengguna (Users & RBAC)
CREATE TABLE pengguna (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    kata_sandi_terenkripsi VARCHAR(255) NOT NULL,
    peran VARCHAR(50) NOT NULL,
    diubah_terakhir_oleh VARCHAR(50),
    tanggal_kata_sandi_diubah DATETIME DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 5. Tabel Sumber Scraping
CREATE TABLE sumber_scraping (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama_sumber VARCHAR(150) NOT NULL,
    url_dasar TEXT NOT NULL,
    jadwal_crawl_terakhir DATETIME,
    jadwal_crawl_status_terakhir VARCHAR(50) DEFAULT 'belum_pernah'
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 6. Tabel Antrian Scraping
CREATE TABLE antrian_scraping (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sumber_scraping_id INT NOT NULL,
    status_batch VARCHAR(50) NOT NULL DEFAULT 'menunggu',
    halaman_terakhir_diproses INT DEFAULT 0,
    CONSTRAINT fk_antrian_sumber FOREIGN KEY (sumber_scraping_id) REFERENCES sumber_scraping(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 7. Tabel Log Kegagalan Crawl
CREATE TABLE log_kegagalan_crawl (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sumber_scraping_id INT NOT NULL,
    waktu_kegagalan DATETIME DEFAULT CURRENT_TIMESTAMP,
    pesan_error TEXT NOT NULL,
    CONSTRAINT fk_log_sumber FOREIGN KEY (sumber_scraping_id) REFERENCES sumber_scraping(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

---

## 8. Persyaratan Non-Fungsional (Non-Functional Requirements)

1. **Performa & Responsivitas**:
   - Waktu respon pencarian pasal rata-rata `< 150 ms` dengan dukungan indeks Full-Text MySQL dan query UNION berpaginasi.
   - Pemuatan antarmuka mobile responsif dengan transisi skeleton shimmer tanpa *screen flickering*.
2. **Keamanan (Security)**:
   - Penggunaan HTTP-Only Cookie untuk sesi web dan penyimpanan aman token/kredensial pada client mobile.
   - Hashing kata sandi menggunakan `bcrypt` dengan salt rounds 10.
   - Pencegahan injeksi SQL melalui parameterized queries (`mysql2/promise`).
   - Kebijakan CORS terkelola untuk pertukaran data API yang aman.
3. **Ketersediaan & Aksesibilitas**:
   - Desain tata letak responsif untuk resolusi desktop, laptop, tablet, dan smartphone Android.
   - Skema warna elegan dan berwibawa mengacu pada identitas resmi Kementerian Hukum Republik Indonesia (Navy `#0b192c` dan Gold Accent `#d97706`).
   - Penataan antarmuka bersih tanpa emoji dekoratif sesuai standar resmi tata kelola dokumen pemerintahan.
