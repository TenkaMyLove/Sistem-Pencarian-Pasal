# Product Requirement Document (PRD)
## Sistem Pencarian Pasal — P3H Kemenkum Kalsel

**Versi**: 3.1  
**Tanggal Pembaruan**: 11 November 2026  
**Status**: Approved & Production Ready  
**Target Pengguna**: Divisi Peraturan Perundang-undangan dan Pembinaan Hukum (P3H), Kantor Wilayah Kementerian Hukum Kalimantan Selatan  

---

## 1. Latar Belakang & Tujuan Produk

Dalam proses harmonisasi Rancangan Peraturan Daerah (Ranperda) dan Rancangan Peraturan Kepala Daerah (Ranperkada / Ranpergub) di lingkungan Kantor Wilayah Kementerian Hukum Kalimantan Selatan, tim Perancang Peraturan Perundang-undangan dan Pengelola Harmonisasi membutuhkan akses cepat, akurat, dan terintegrasi untuk mencari serta mengelola pasal-pasal rujukan dari berbagai tingkatan peraturan (UUD 1945, Undang-Undang, Peraturan Pemerintah Pengganti Undang-Undang, Peraturan Pemerintah, Peraturan Presiden, hingga Peraturan Daerah Provinsi dan Kabupaten/Kota se-Kalimantan Selatan).

### Tujuan Utama Produk:
1. **Mesin Pencari & Kurasi Pasal Real-Time**: Menyediakan pencarian pasal hukum yang instan, responsif, dan presisi (berbasis web HTMX tanpa *page reload* maupun aplikasi mobile Flutter), disertai kemampuan kurasi (Edit & Hapus pasal) bagi Pengelola/Admin.
2. **Keterhubungan Relasi Hukum Komprehensif**: Menyajikan relasi status hukum antar peraturan secara lengkap (*Mencabut*, *Dicabut Dengan*, *Diubah Dengan*, *Mengubah*, *Mencabut Sebagian*, dan *Dicabut Sebagian Dengan*) dengan penyorotan (*highlight*) referensi pasal pada keterangan.
3. **Manajemen Agenda Rapat Harmonisasi**: Menyediakan agenda penjadwalan rapat harmonisasi Ranperda/Ranpergub yang terstruktur dengan dukungan multi-kompilator dan kontrol hak akses berbasis peran.
4. **Ekspansi Data Otomatis (Web Crawler)**: Menyediakan alat pengindeksan peraturan dan pasal baru secara langsung melalui URL resmi portal hukum (JDIH BPK / Pemda) maupun entri teks manual.
5. **Aksesibilitas Multi-Platform**: Mendukung peramban web desktop dan aplikasi mobile Flutter multi-platform (Web Browser Chrome/Edge & Android Emulator/Device) dengan tampilan modern dan efek *skeletonizer*.
6. **Verifikasi Keabsahan Dokumen**: Memastikan tautan dokumen sumber mengarah langsung ke dokumen resmi terverifikasi dengan pemantauan status keaktifan tautan (*normal* vs *tautan_bermasalah*).

---

## 2. Pengguna & Peran (Role-Based Access Control / RBAC)

Sistem membagi akses pengguna ke dalam 4 tingkatan peran:

| Peran Pengguna | Label Tampilan Antarmuka | Deskripsi & Hak Akses |
|---|---|---|
| **Admin** | Administrator | • Manajemen akun operasional (`Pengelola` & `Perancang`) serta reset kata sandi (`/kelola-akun` & `/api/admin/*`)<br>• Pencarian Pasal, **Edit/Hapus Pasal**, dan **Tambah Peraturan via URL** pada antarmuka Web<br>• Akses Lihat (*Read-Only*) pada Jadwal Rapat Harmonisasi |
| **Pengelola** | Pengelola | • Pencarian Pasal & Filter Peraturan (Web & Mobile)<br>• **Kurasi Pasal (Edit & Hapus Pasal)** langsung dari hasil pencarian (Web)<br>• Manajemen Jadwal Rapat Harmonisasi (**Full CRUD**: Tambah, Ubah, Hapus pada Web & Mobile)<br>• Tambah Peraturan & Pasal via Tautan URL Crawler (Web & Mobile) |
| **Perancang** | Perancang | • Pencarian Pasal & Filter Peraturan (Web & Mobile)<br>• Manajemen Jadwal Rapat Harmonisasi (**Full CRUD**: Tambah, Ubah, Hapus pada Web & Mobile) |
| **Tamu** | Tamu (`Akses Publik`) | • Akses langsung Pencarian Pasal, Detail Status Peraturan, dan Tautan Dokumen PDF Asli tanpa harus login<br>• Dibatasi dari menu internal Jadwal Harmonisasi Web, Tambah Peraturan, Edit/Hapus Pasal, dan Administrasi Akun |

> **Kebijakan Keamanan Dokumen**: Dokumen PRD ini sengaja **tidak mencantumkan kredensial akun** (username/kata sandi) maupun kunci rahasia sistem. Pengelolaan kredensial sepenuhnya dilakukan pada basis data terenkripsi (`bcryptjs`) melalui Administrator sistem.

---

## 3. Spesifikasi Fitur Utama

### 3.1. Mesin Pencarian Pasal, Kurasi Pasal & Filter Peraturan (Web & Mobile)
- **Pencarian Real-Time**: Pencarian berbasis HTMX (`GET /search-results`, 5 hasil per halaman) pada Web serta REST API (`GET /api/search`, default 10 hasil per halaman, maksimal 50) pada Mobile yang memperbarui hasil secara instan.
- **Word-Boundary Keyword Highlighting**: Penyorotan kata kunci pencarian pada teks pasal secara presisi menggunakan regex (`<mark>`) tanpa merusak struktur elemen antarmuka.
- **Dukungan Pencarian Peraturan Kosong (`UNION ALL` Query)**: Peraturan yang baru diindeks tetapi belum memiliki pasal tetap muncul dalam hasil pencarian web dengan keterangan informatif dan tautan dokumen asli.
- **Edit & Hapus Pasal (Khusus Pengelola & Admin — Web)**:
  - Tombol **Edit** dan **Hapus** muncul pada kartu hasil pencarian (`result-card-{pasal_id}`) hanya untuk pengguna yang login sebagai `Pengelola` atau `Admin` (dilindungi middleware `requirePengelola`).
  - **Edit Pasal**: Mengklik **Edit** memanggil `GET /pencarian/edit-pasal-modal/:pasal_id` untuk menampilkan `EditPasalModal` berisi input `Nomor Pasal`, `Nomor Ayat` (opsional), dan `Teks Pasal`, lalu menyimpan perubahan melalui `POST /pencarian/edit-pasal/:pasal_id`.
  - **Hapus Pasal**: Mengklik **Hapus** menampilkan konfirmasi dialog (`hx-confirm`) dan menjalankan `POST /pencarian/hapus-pasal/:pasal_id` untuk menghapus pasal dari tabel `pasal` serta menghapus kartu dari tampilan secara langsung.
- **Filter Sektor & Wilayah**:
  - **Sektor Hukum**: Otonomi Daerah, Keuangan Daerah, Tata Ruang, Lingkungan Hidup, Pendidikan, Kesehatan, Ketenagakerjaan, Pertanahan, Perpajakan, Perdagangan, Pertanian, Perikanan, Infrastruktur, Pemerintahan, Hukum, serta opsi sektor terindeks lainnya dari basis data.
  - **Wilayah**: Nasional, Kalimantan Selatan, serta 13 Kabupaten/Kota se-Kalimantan Selatan.
- **Modal Interaktif Detil Status Peraturan (`StatusDetailModal`)**:
  - Menampilkan relasi status hukum lengkap yang dikelompokkan rapi (*Mencabut*, *Mencabut Sebagian*, *Diubah Dengan*, *Dicabut Dengan*, *Dicabut Sebagian Dengan*, *Mengubah*, *Diubah*, *Perubahan*, *Peraturan Terkait*).
  - Tautan regulasi relasi mengarah langsung ke portal resmi eksternal (BPK/JDIH) di tab baru dengan ikon indikator tautan luar.
  - **Sorotan Referensi Pasal Non-Clickable**: Penyebutan pasal di dalam teks `keterangan` (misalnya `"Pasal 238"`, `"Pasal 15"`, `"Pasal 21 s.d. Pasal 25"`, `"Pasal 1 angka 30"`) disorot menggunakan elemen `<span>` berwarna kuning-oranye (`background-color: #fef9c3; color: #92400e; font-weight: 700`) dan **tidak dijadikan tautan klik**, karena pasal rujukan tersebut belum tentu tersedia di dalam basis data sistem.
  - Dilengkapi tombol tutup (`✕`) di pojok kanan atas serta penutupan otomatis saat klik area backdrop/luar modal.
- **Tautan Dokumen PDF Asli**:
  - Tombol tautan langsung ke portal JDIH BPK / Pemda.
  - Indikator badge otomatis `Tautan Bermasalah` vs `Tautan Aktif` berdasarkan kolom `status_tautan`.
- **Antarmuka Header & Profil Sidebar yang Rapi (`src/views/layout.tsx`)**:
  - Header atas tidak menampilkan pill `"Mode Tamu (Akses Publik)"` agar tampilan tajuk tetap bersih dan konsisten untuk semua pengguna.
  - Profil pada footer sidebar menggunakan label ringkas (`Tamu` / `Akses Publik`, `Pengelola`, `Perancang`, `Administrator`) dengan pill peran seragam dan tombol `Masuk` / `Keluar`.

### 3.2. Manajemen Jadwal Rapat Harmonisasi
- **Agenda Rapat Terstruktur**: Menampilkan No, Jenis Rancangan (`Ranperda` / `Ranpergub`), Pokok Materi (`Tentang`), Hari/Tanggal, Jam (`WITA`), Nama Kompilator, Tim Pokja (`Pokja 1` / `Pokja 2`), dan Pembuat Agenda.
- **Dukungan Multi-Kompilator**: Checkbox pilihan tim perancang standar serta kolom entri manual untuk nama kompilator tambahan (dipisahkan koma).
- **Kontrol Hak Akses**: **Pengelola** dan **Perancang** memiliki kontrol CRUD penuh (Tambah, Ubah, Hapus di Web dan Mobile), sedangkan **Admin** memiliki akses baca (*Read-Only*), dan **Tamu** dibatasi dari akses agenda rapat internal pada Web.

### 3.3. Tambah Peraturan via Tautan (Web Crawler & Ingestion)
- Dapat diakses oleh **Pengelola** (serta **Admin** pada antarmuka Web melalui middleware `requirePengelola`).
- Crawler otomatis (`urlCrawler.ts`) mengekstrak metadata (`judul` dari meta `og:title`, `<h1>`, atau `<title>`), teks pasal berpola `"Pasal N"`, serta relasi status peraturan (khusus halaman JDIH BPK).
- Tersedia kolom opsional `teks_pasal_manual` untuk menyalin-tempel isi teks peraturan secara manual jika halaman sumber tidak menyediakan struktur HTML yang dapat di-parse otomatis, dengan tampilan formulir yang bersih tanpa teks bantuan berikon emoji dekoratif.

### 3.4. Aplikasi Mobile Terintegrasi (Flutter)
- Dikembangkan menggunakan **Flutter** multi-platform (Web Browser Chrome/Edge dan Android Emulator/Device).
- **Skeletonizer Shimmer Effect**: Seluruh proses pemuatan data (pencarian pasal, daftar pasal pada detail peraturan, jadwal rapat, dan daftar akun admin) menggunakan efek animasi *shimmer skeleton* (`skeletonizer ^3.0.0`).
- **Host Switcher Terintegrasi (`SettingsDialog`)**: Dialog pengaturan alamat backend API dengan preset cepat Web (`http://localhost:3000`) dan Emulator Android (`http://10.0.2.2:3000`), serta tombol **Uji Koneksi Server** (`/api/health`).
- **Fitur Mobile Lengkap**:
  - Tab navigasi dinamis sesuai peran (`HomeScreen`): Pencarian, Jadwal Rapat (dengan chip filter `Semua` / `Ranperda` / `Ranperkada`), tab khusus (`Kelola Akun` untuk Admin atau `Tambah Peraturan` untuk Pengelola), serta `Profil & Host`.
  - `PeraturanDetailScreen`: Membaca seluruh daftar pasal suatu peraturan, pencarian internal antar-pasal, tombol salin teks pasal ke clipboard, dan membuka dokumen asli eksternal.

### 3.5. Kelola Akun & Reset Kata Sandi (Khusus Admin)
- Antarmuka khusus **Admin** pada Web (`/kelola-akun`) dan Mobile (`KelolaAkunScreen`) untuk memperbarui kata sandi akun operasional tim (**Pengelola** dan **Perancang**).
- Validasi keamanan: kata sandi minimal 6 karakter, konfirmasi kecocokan kata sandi, pencatatan audit (`diubah_terakhir_oleh`, `tanggal_kata_sandi_diubah`), dan penyimpanan terenkripsi menggunakan algoritma `bcryptjs` (cost factor 10).

---

## 4. Cakupan Data Peraturan (56 Peraturan Terindeks)

Basis data awal (`database_dump_mysql.sql`) mencakup **56 Peraturan Perundang-Undangan** terverifikasi yang meliputi regulasi nasional dan daerah:

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
   |      HTMX + Custom CSS P3H         |      |  Android / Chrome Web / Skeleton   |
   +-----------------+------------------+      +-----------------+------------------+
                     |                                           |
                     | (HTML / HTMX SSR)                         | (JSON / REST API)
                     +--------------------+ ---------------------+
                                          |
                                          v
                     +-------------------------------------------+
                     |       Hono Web & API Server (Node.js)     |
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
- **Web Framework**: [Hono](https://hono.dev/) `^4.6.14` (SSR JSX & REST API)
- **Database Engine**: MySQL 8.x (`mysql2 ^3.11.3` dengan Full-Text Indexing)
- **Frontend Web**: HTMX 1.9.10 + Custom Vanilla CSS (`public/css/style.css`)
- **Mobile Framework**: Flutter & Dart `^3.11.5` (Material 3 Multi-platform)
- **Mobile UI Libraries**: `skeletonizer ^3.0.0`, `google_fonts ^8.2.1`, `http ^1.6.0`, `shared_preferences ^2.5.6`, `url_launcher ^6.3.3`, `intl ^0.20.3`
- **Web Scraper & Crawler**: `cheerio ^1.2.0` + `node-fetch ^3.3.2`
- **Security & Hashing**: `bcryptjs ^3.0.2` (Cost factor 10) + HTTP-Only Session Cookie & CORS Management

---

## 6. Spesifikasi Endpoint Web & REST API

### 6.1. REST API Endpoints (`/api/*` — Mobile & Integrasi)

| Method | Endpoint | Deskripsi | Akses / Catatan |
|---|---|---|---|
| `GET` | `/api/health` | Pemeriksaan status server dan konektivitas | Publik |
| `GET` | `/api/cron/recrawl` | Menjalankan verifikasi tautan dokumen peraturan (`runRecrawlCheck`) | Cron / Sistem |
| `POST` | `/api/auth/login` | Otentikasi pengguna dan pengembalian profil peran JSON | Publik |
| `GET` | `/api/search` | Pencarian peraturan/pasal (`q`, `sektor`, `wilayah`, `page`, `pageSize`) | Publik / Tamu |
| `GET` | `/api/peraturan/:id` | Mengambil detail peraturan beserta seluruh daftar pasalnya | Publik / Tamu |
| `GET` | `/api/jadwal` | Mengambil daftar agenda rapat harmonisasi | Terautentikasi di klien |
| `POST` | `/api/jadwal` | Menambahkan agenda jadwal rapat baru | Pengelola / Perancang |
| `PUT` | `/api/jadwal/:id` | Memperbarui data jadwal rapat harmonisasi | Pengelola / Perancang |
| `DELETE` | `/api/jadwal/:id` | Menghapus agenda rapat harmonisasi | Pengelola / Perancang |
| `GET` | `/api/admin/users` | Mengambil daftar metadata akun pengguna (tanpa hash/sandi) | Khusus Admin |
| `POST` | `/api/admin/reset-password` | Mereset kata sandi akun staf operasional (`Pengelola` / `Perancang`) | Khusus Admin |
| `POST` | `/api/tambah-peraturan` | Menjalankan crawler untuk mengindeks peraturan baru dari URL | Pengelola |

### 6.2. Web SSR & HTMX Routes Utama

| Method | Route | Deskripsi | Middleware RBAC |
|---|---|---|---|
| `GET` / `POST` | `/login`, `/tamu`, `/logout` | Autentikasi web SSR, mode tamu, dan keluar sesi | Publik |
| `GET` | `/`, `/pencarian`, `/search-results` | Halaman utama pencarian dan partial hasil HTMX | `allowGuestOrAuth` |
| `GET` | `/pencarian/status-modal/:peraturan_id` | Modal detail status relasi peraturan | `allowGuestOrAuth` |
| `GET` | `/pencarian/edit-pasal-modal/:pasal_id` | Modal edit pasal | `requirePengelola` (Pengelola & Admin) |
| `POST` | `/pencarian/edit-pasal/:pasal_id` | Menyimpan pembaruan nomor pasal, ayat, dan teks pasal | `requirePengelola` (Pengelola & Admin) |
| `POST` | `/pencarian/hapus-pasal/:pasal_id` | Menghapus baris pasal dari basis data | `requirePengelola` (Pengelola & Admin) |
| `GET` / `POST` | `/jadwal`, `/jadwal/modal/*`, `/jadwal/:id/*` | Halaman & aksi CRUD jadwal rapat harmonisasi | `requireStaff` (tulis: Pengelola & Perancang) |
| `GET` / `POST` | `/tambah-peraturan` | Formulir & eksekusi web crawler peraturan baru | `requirePengelola` (Pengelola & Admin) |
| `GET` / `POST` | `/kelola-akun` | Kelola akun dan reset kata sandi staf operasional | `requireAdmin` (Khusus Admin) |

---

## 7. Skema Database MySQL 8.x (DDL Resmi)

Database `p3h_kemenkum_kalsel` menggunakan 7 tabel terstruktur (`src/db/schema_mysql.sql`):

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

-- 3. Tabel Sumber Scraping
CREATE TABLE sumber_scraping (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama_sumber VARCHAR(150) NOT NULL,
    url_dasar TEXT NOT NULL,
    jadwal_crawl_terakhir DATETIME,
    jadwal_crawl_status_terakhir VARCHAR(50) DEFAULT 'belum_pernah'
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 4. Tabel Antrian Scraping
CREATE TABLE antrian_scraping (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sumber_scraping_id INT NOT NULL,
    status_batch VARCHAR(50) NOT NULL DEFAULT 'menunggu',
    halaman_terakhir_diproses INT DEFAULT 0,
    CONSTRAINT fk_antrian_sumber FOREIGN KEY (sumber_scraping_id) REFERENCES sumber_scraping(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 5. Tabel Log Kegagalan Crawl
CREATE TABLE log_kegagalan_crawl (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sumber_scraping_id INT NOT NULL,
    waktu_kegagalan DATETIME DEFAULT CURRENT_TIMESTAMP,
    pesan_error TEXT NOT NULL,
    CONSTRAINT fk_log_sumber FOREIGN KEY (sumber_scraping_id) REFERENCES sumber_scraping(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 6. Tabel Pengguna (Users & RBAC)
CREATE TABLE pengguna (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    kata_sandi_terenkripsi VARCHAR(255) NOT NULL,
    peran VARCHAR(50) NOT NULL,
    diubah_terakhir_oleh VARCHAR(50),
    tanggal_kata_sandi_diubah DATETIME DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 7. Tabel Jadwal Rapat Harmonisasi
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
```

---

## 8. Persyaratan Non-Fungsional (Non-Functional Requirements)

1. **Performa & Responsivitas**:
   - Pencarian pasal cepat dengan dukungan indeks Full-Text MySQL dan query `UNION ALL` berpaginasi.
   - Pemuatan antarmuka mobile responsif dengan transisi skeleton shimmer (`Skeletonizer`) tanpa *screen flickering*.
2. **Keamanan & Privasi**:
   - Penggunaan HTTP-Only Cookie (`SameSite=Lax`) untuk sesi web dan `SharedPreferences` pada client mobile.
   - Hashing kata sandi menggunakan `bcryptjs` dengan cost factor 10.
   - Pencegahan injeksi SQL melalui *parameterized queries* (`mysql2/promise`).
   - Kebijakan CORS terkelola untuk pertukaran data API.
   - Tidak ada kredensial akun, kata sandi, maupun nilai `.env` produksi yang dicantumkan pada kode dokumentasi (`README.md` / `PRD.md`).
3. **Ketersediaan & Aksesibilitas**:
   - Desain tata letak responsif untuk resolusi desktop, laptop, tablet, dan smartphone Android.
   - Skema warna elegan dan berwibawa mengacu pada identitas resmi Kementerian Hukum Republik Indonesia (Navy `#0b192c` / `#1E3A8A` dan Gold Accent `#d97706`).
   - Penataan antarmuka bersih tanpa emoji dekoratif sesuai standar tata kelola dokumen pemerintahan.
