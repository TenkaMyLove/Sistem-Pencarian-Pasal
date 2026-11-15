# Product Requirement Document (PRD)
## Sistem Pencarian Pasal — P3H Kemenkum Kalsel

**Versi**: 3.3  
**Tanggal Pembaruan**: 11 November 2026  
**Status**: Approved & Production Ready  
**Target Pengguna**: Divisi Peraturan Perundang-undangan dan Pembinaan Hukum (P3H), Kantor Wilayah Kementerian Hukum Kalimantan Selatan  

---

## 1. Latar Belakang & Tujuan Produk

Dalam proses harmonisasi Rancangan Peraturan Daerah (Ranperda) dan Rancangan Peraturan Kepala Daerah (Ranperkada / Ranpergub) di lingkungan Kantor Wilayah Kementerian Hukum Kalimantan Selatan, tim Perancang Peraturan Perundang-undangan dan Pengelola Harmonisasi membutuhkan akses cepat, akurat, dan terintegrasi untuk mencari serta mengelola pasal-pasal rujukan dari berbagai tingkatan peraturan (UUD 1945, Undang-Undang, Peraturan Pemerintah Pengganti Undang-Undang, Peraturan Pemerintah, Peraturan Presiden, hingga Peraturan Daerah Provinsi dan Kabupaten/Kota se-Kalimantan Selatan).

### Tujuan Utama Produk:
1. **Mesin Pencari & Kurasi Data Hukum Real-Time**: Menyediakan pencarian pasal hukum yang instan, responsif, dan presisi (berbasis web HTMX tanpa *page reload* maupun aplikasi mobile Flutter), disertai kemampuan kurasi (Edit & Hapus peraturan maupun pasal) bagi Pengelola dan Admin.
2. **Keterhubungan Relasi Hukum Komprehensif**: Menyajikan relasi status hukum antar peraturan secara lengkap (*Mencabut*, *Dicabut Dengan*, *Diubah Dengan*, *Mengubah*, *Mencabut Sebagian*, dan *Dicabut Sebagian Dengan*) dengan penyorotan (*highlight*) referensi pasal non-clickable pada keterangan.
3. **Manajemen Agenda Rapat Harmonisasi**: Menyediakan agenda penjadwalan rapat harmonisasi Ranperda/Ranpergub berbasis Tim Pokja (`Pokja 1` / `Pokja 2`) dengan dukungan multi-kompilator, ringkasan jadwal mingguan siap salin, dan kontrol hak akses berbasis peran.
4. **Ekspansi Data Otomatis (Web Crawler)**: Menyediakan alat pengindeksan peraturan dan pasal baru secara langsung melalui URL resmi portal hukum (JDIH BPK / Pemda) maupun entri teks manual.
5. **Aksesibilitas Multi-Platform & Konsistensi Visual**: Mendukung dashboard web modern serta aplikasi mobile Flutter multi-platform (Web Browser Chrome/Edge & Android Emulator/Device) dengan sistem desain terpadu Sovereign Navy & Slate serta efek *skeletonizer*.
6. **Verifikasi Keabsahan Dokumen**: Memastikan tautan dokumen sumber mengarah langsung ke dokumen resmi terverifikasi dengan pemantauan status keaktifan tautan (*normal* vs *tautan_bermasalah*).

---

## 2. Pengguna & Peran (Role-Based Access Control / RBAC)

Sistem membagi akses pengguna ke dalam 4 tingkatan peran:

| Peran Pengguna | Label Tampilan Antarmuka | Deskripsi & Hak Akses |
|---|---|---|
| **Admin** | `Administrator` (*Manajemen Sistem*) | • Manajemen akun operasional (`Pengelola` & `Perancang`) serta reset kata sandi (`/kelola-akun`, `KelolaAkunScreen`, & `/api/admin/*`)<br>• Pencarian Pasal, **Edit/Hapus Peraturan & Pasal**, serta **Tambah Peraturan via URL** (Web & Mobile)<br>• Akses Lihat (*Read-Only*) pada Jadwal Rapat Harmonisasi |
| **Pengelola** | `Pengelola` (*Data & Jadwal*) | • Pencarian Pasal & Filter Peraturan (Web & Mobile)<br>• **Kurasi Peraturan & Pasal (Edit & Hapus Peraturan/Pasal)** pada Web & Mobile<br>• Manajemen Jadwal Rapat Harmonisasi (**Full CRUD**: Tambah, Ubah, Hapus pada Web & Mobile)<br>• Tambah Peraturan & Pasal via Tautan URL Crawler (Web & Mobile) |
| **Perancang** | `Perancang` (*Tim Harmonisasi*) | • Pencarian Pasal & Filter Peraturan (Web & Mobile)<br>• Manajemen Jadwal Rapat Harmonisasi (**Full CRUD**: Tambah, Ubah, Hapus pada Web & Mobile) |
| **Tamu** | `Tamu` (*Akses Publik*) | • Akses langsung Pencarian Pasal, Detail Status Peraturan, dan Tautan Dokumen Sumber Asli tanpa harus login<br>• Dibatasi dari menu internal Jadwal Harmonisasi, Tambah Peraturan, Edit/Hapus data, dan Administrasi Akun |

> **Kebijakan Keamanan Dokumen**: Dokumen PRD ini sengaja **tidak mencantumkan kredensial akun** (username/kata sandi) maupun kunci rahasia sistem. Pengelolaan kredensial sepenuhnya dilakukan pada basis data terenkripsi (`bcryptjs`) melalui Administrator sistem.

---

## 3. Spesifikasi Fitur Utama

### 3.1. Mesin Pencarian Pasal, Kurasi Pasal & Filter Peraturan (Web & Mobile)
- **Pencarian Real-Time**: Pencarian berbasis HTMX (`GET /search-results`, 5 hasil per halaman) pada Web serta REST API (`GET /api/search`, default 10 hasil per halaman, maksimal 50) pada Mobile yang memperbarui hasil secara instan.
- **Word-Boundary Keyword Highlighting**: Penyorotan kata kunci pencarian pada teks pasal secara presisi menggunakan regex (`<mark>` pada Web dan `TextSpan` sorotan kuning pada Mobile) tanpa merusak struktur elemen antarmuka.
- **Dukungan Pencarian Peraturan Kosong (`UNION ALL` Query)**: Peraturan yang baru diindeks tetapi belum memiliki pasal tetap muncul dalam hasil pencarian Web (`/search-results`) maupun Mobile (`/api/search`) tanpa kotak keterangan "Dokumen Peraturan Terindeks" (kotak disembunyikan bila tidak ada pasal), tetap dengan tombol detil status dan tautan dokumen asli. Pengekstrak PDF kini juga menghentikan pembacaan pada blok pengesahan (Ditetapkan/Diundangkan di ...), LAMPIRAN, dan PENJELASAN, serta membuang karakter kontrol dari font PDF rusak sehingga pasal penutup tidak lagi memuat teks sampah.
- **Edit & Hapus Peraturan dan Pasal (Web & Mobile — Pengelola & Admin)**:
  - Tombol **Edit Peraturan** dan **Hapus Peraturan** muncul pada **setiap kartu hasil pencarian** (termasuk peraturan dengan `pasal_id = NULL` pada Web / `pasal_id <= 0` pada Mobile) untuk peran `Pengelola` atau `Admin`, sedangkan aksi **Edit Pasal** dan **Hapus Pasal** tersedia saat item memiliki `pasal_id`. Pada Mobile tersedia lewat tombol ikon Edit (`#EEF2FF`) / Hapus (`#FEE2E2`) di setiap kartu `SearchScreen` (modal pilihan Pasal vs Peraturan) serta AppBar dan kartu pasal di `PeraturanDetailScreen`.
  - **Edit Peraturan**: Mengubah jenis (`jenis_peraturan`), nomor, tahun, judul (`judul`), status hukum, wilayah, sektor, URL dokumen (`url_dokumen_asli`), dan keterangan status melalui modal HTMX (`GET /pencarian/edit-peraturan-modal/:peraturan_id`, `POST /pencarian/edit-peraturan/:peraturan_id`) atau dialog Mobile (`PUT /api/peraturan/:id`).
  - **Hapus Peraturan**: Menghapus peraturan beserta seluruh pasalnya via relasi `ON DELETE CASCADE` (`POST /pencarian/hapus-peraturan/:peraturan_id` / `DELETE /api/peraturan/:id`) dengan pembaruan daftar otomatis (`HX-Trigger: refreshResults` di Web; refresh list di Mobile).
  - **Edit & Hapus Pasal**: Mengubah (`nomor_pasal`, `nomor_ayat`, `teks_pasal`) maupun menghapus pasal tertentu (`POST /pencarian/edit-pasal/:pasal_id`, `POST /pencarian/hapus-pasal/:pasal_id`, `PUT /api/pasal/:id`, `DELETE /api/pasal/:id`).
- **Filter Sektor & Wilayah + Fitur Pencarian Mobile**:
  - **Sektor Hukum**: Otonomi Daerah, Keuangan Daerah, Tata Ruang, Lingkungan Hidup, Pendidikan, Kesehatan, Ketenagakerjaan, Pertanahan, Perpajakan, Perdagangan, Pertanian, Perikanan, Infrastruktur, Pemerintahan, Hukum, serta opsi sektor terindeks lainnya dari basis data.
  - **Wilayah**: Nasional, Kalimantan Selatan, serta 13 Kabupaten/Kota se-Kalimantan Selatan.
  - **Riwayat & Pengurutan (Mobile)**: `SearchScreen` menyimpan riwayat pencarian lokal (`SharedPreferences` maksimal 15 entri) melalui tombol riwayat serta menyediakan pengurutan cepat (*Relevansi* vs *Tahun Terbaru*) dan pil horizontal dinamis.
- **Modal & Sheet Detil Status Peraturan (`StatusDetailModal` / Sheet `Status Hubungan`)**:
  - Menampilkan relasi status hukum lengkap yang dikelompokkan rapi (*Mencabut*, *Mencabut Sebagian*, *Diubah Dengan*, *Dicabut Dengan*, *Dicabut Sebagian Dengan*, *Mengubah*, *Diubah*, *Perubahan*, *Peraturan Terkait*).
  - Tautan regulasi relasi mengarah langsung ke portal resmi eksternal (BPK/JDIH) di tab baru dengan ikon indikator tautan luar.
  - **Sorotan Referensi Pasal Non-Clickable**: Penyebutan pasal di dalam teks `keterangan` (misalnya `"Pasal 238"`, `"Pasal 15"`, `"Pasal 21 s.d. Pasal 25"`, `"Pasal 1 angka 30"`) disorot menggunakan badge/elemen berwarna kuning (`background-color: #fef9c3` / `#FEF08A`) dan **tidak dijadikan tautan klik**, karena pasal rujukan tersebut belum tentu tersedia di dalam basis data sistem.
  - Dilengkapi tombol tutup (`✕`) serta penutupan otomatis saat klik area backdrop/luar modal (Web) atau dismissible bottom sheet (Mobile).
- **Tautan Dokumen PDF Asli**:
  - Tombol tautan langsung ke portal JDIH BPK / Pemda.
  - Indikator badge otomatis `Tautan Bermasalah` vs `Tautan Aktif` berdasarkan kolom `status_tautan`.
- **Antarmuka Dashboard Web & Navigasi (`src/views/layout.tsx`, `src/views/login.tsx`)**:
  - **Fixed Sidebar (`w-80`)**: Tetap menempel di sisi kiri layar sehingga daftar *Menu Yuridis* dan profil footer pengguna selalu terlihat meskipun daftar hasil pencarian panjang ke bawah.
  - **Fixed Top Header Bar**: Menampilkan judul halaman huruf kapital, lencana peran aktif (`displayName` & `displayRole`), serta tombol `Masuk`/`Keluar`, tanpa menampilkan pill `"Mode Tamu (Akses Publik)"`.
  - **Profil Peran Tanpa Duplikasi Kata**: Menampilkan label bersih (`Administrator / Manajemen Sistem`, `Pengelola / Data & Jadwal`, `Perancang / Tim Harmonisasi`, `Tamu / Akses Publik`).
  - **Halaman Masuk Web (`LoginView`)**: Latar penuh `#0b192c` (*Sovereign Navy*), tajuk Kementerian Hukum RI Kanwil Kalsel, kartu login terpusat dengan logo Pengayoman, opsi *Ingat sesi login pada perangkat kerja ini*, dan tautan publik *Akses Pencarian Pasal Publik Tanpa Login*.

### 3.2. Manajemen Jadwal Rapat Harmonisasi
- **Agenda Rapat Terstruktur**: Menampilkan Jenis Rancangan (`Ranperda` / `Ranpergub`), Pokok Materi (`Tentang`), Hari/Tanggal, Jam (`WITA`), Nama Kompilator, Tim Pokja (`Pokja 1` / `Pokja 2`), dan Pembuat Agenda.
- **Filter Pokja & Ringkasan Cetak Mingguan (Mobile)**: `JadwalScreen` menyediakan pil filter berhitungan (`Semua`, `Pokja 1`, `Pokja 2`) dengan normalisasi format Pokja I/II, banner total agenda ditampilkan, serta fitur `Cetak Mingguan` (modal ringkasan jadwal terformat siap salin ke clipboard).
- **Standardisasi Format Waktu & Multi-Kompilator**:
  - Web mendukung checkbox pilihan tim perancang standar serta entri manual nama kompilator tambahan.
  - Mobile (`JadwalFormDialog`) mengirimkan format jam `HH:mm` agar sesuai dengan kolom MySQL `TIME NOT NULL` dan menampilkannya secara konsisten dalam format `HH.mm WITA`.
- **Kontrol Hak Akses**: **Pengelola** dan **Perancang** memiliki kontrol CRUD penuh (Tambah, Ubah, Hapus di Web dan Mobile), sedangkan **Admin** memiliki akses baca (*Read-Only*), dan **Tamu** dibatasi dari akses agenda rapat internal.

### 3.3. Tambah Peraturan via Tautan (Web Crawler & Ingestion)
- Dapat diakses oleh **Pengelola** dan **Admin** pada antarmuka Web (`/tambah-peraturan`) dan Mobile (`TambahPeraturanScreen`).
- Crawler otomatis (`urlCrawler.ts`) mengekstrak metadata (`judul` dari meta `og:title`, `<h1>`, atau `<title>`), teks pasal berpola `"Pasal N"`, serta relasi status peraturan (khusus halaman JDIH BPK).
- Kolom opsional `teks_manual` (API) / `teks_pasal_manual` (Web form) memungkinkan salin-tempel isi teks peraturan secara manual jika halaman sumber tidak dapat di-parse otomatis, dengan antarmuka bersih tanpa teks bantuan berikon emoji dekoratif.

### 3.4. Aplikasi Mobile Terintegrasi (Flutter)
- Dikembangkan menggunakan **Flutter** multi-platform (Web Browser Chrome/Edge dan Android Emulator/Device) dengan sistem desain terpadu:
  - **Palet & Komponen**: Sovereign Navy (`#0B192C`), Slate (`#1E293B`), Administrative Blue (`#1D4ED8`), Soft Indigo (`#EEF2FF`), canvas terang `#F8FAFC`, input `#F1F5F9` borderless radius `10`, kartu putih berborder `#E2E8F0` radius `14`, serta font `Inter` (`google_fonts`).
  - **Splash Screen (`SplashScreen`)**: Tampilan navy dengan logo Pengayoman, inisialisasi sesi `AuthService`, serta pengelolaan `Timer` yang dibersihkan pada `dispose()`.
  - **Masuk Sistem (`LoginScreen`)**: Desain kartu putih di atas `#F8FAFC`, fitur *Ingat Sesi Saya*, dialog informasi *Lupa Sandi?*, akses *Mode Tamu*, dan tombol pengaturan host.
  - **Shell Utama (`HomeScreen`)**: AppBar navy dengan subjudul tab aktif, indikator koneksi server (`SettingsDialog`), avatar inisial menuju `ProfileScreen`, dan navigasi bawah 4 tab sesuai RBAC (`Pencarian`, `Jadwal Rapat`, `Tambah`, `Kelola Akun`; disembunyikan pada mode `Tamu`).
  - **Skeletonizer Shimmer Effect**: Seluruh proses pemuatan data pada `SearchScreen`, `PeraturanDetailScreen`, `JadwalScreen`, dan `KelolaAkunScreen` menggunakan efek animasi *shimmer skeleton* (`skeletonizer ^3.0.0`).
  - **Host Switcher Non-Destruktif (`SettingsDialog`)**: Preset cepat Web (`http://localhost:3000`) dan Emulator Android (`http://10.0.2.2:3000`), serta tombol **Uji Koneksi Server** menggunakan `ApiService.checkHealth({ baseUrlOverride })` sehingga pengujian URL tidak menimpa pengaturan tersimpan sebelum ditekan simpan.
  - **PeraturanDetailScreen**: Kartu metadata, kartu *Keterangan & Pasal Terdampak* dengan sorotan kuning non-clickable, pencarian/saring pasal internal, salin teks pasal, tautan dokumen eksternal, serta aksi Edit/Hapus peraturan & pasal untuk `Pengelola` dan `Admin`.
  - **ProfileScreen**: Kartu identitas pengguna bebas duplikasi label peran, status & konfigurasi server backend, daftar matriks hak akses RBAC peran aktif, serta tombol Keluar/Masuk.

### 3.5. Kelola Akun & Reset Kata Sandi (Khusus Admin)
- Antarmuka khusus **Admin** pada Web (`/kelola-akun`) dan Mobile (`KelolaAkunScreen`) untuk memperbarui kata sandi akun operasional tim (**Pengelola** dan **Perancang**).
- Pada Mobile, `KelolaAkunScreen` menyediakan banner informasi keamanan `bcryptjs cost factor 10`, kartu inline *Form Reset Kata Sandi Staf* (`Pilih Akun Target`, `Kata Sandi Baru`, `Konfirmasi Kata Sandi` dengan toggle visibilitas), serta *Daftar Akun Pengguna Sistem* interaktif yang otomatis memilih akun target saat ditekan.
- Validasi keamanan: kata sandi minimal 6 karakter, konfirmasi kecocokan kata sandi, pencatatan audit (`diubah_terakhir_oleh`, `tanggal_kata_sandi_diubah`), dan penyimpanan terenkripsi menggunakan algoritma `bcryptjs` (cost factor 10).

---

## 4. Cakupan Data Peraturan (86 Peraturan Terindeks)

Basis data awal (`database_dump_mysql.sql`) mencakup **86 Peraturan Perundang-Undangan** terverifikasi yang meliputi regulasi nasional dan daerah:

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
   |  HTMX + Tailwind + Custom CSS P3H  |      |  Android / Chrome Web / Skeleton   |
   +-----------------+------------------+      +-----------------+------------------+
                     |                                           |
                     | (HTML / HTMX SSR)                         | (JSON / REST API + CORS)
                     +--------------------+ ---------------------+
                                          |
                                          v
                     +-------------------------------------------+
                     |       Hono Web & API Server (Node.js)     |
                     |  - Middleware: Auth Cookie & /api/* CORS  |
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
- **Frontend Web**: HTMX 1.9.10 + Tailwind CSS + Custom Vanilla CSS (`public/css/style.css`)
- **Mobile Framework**: Flutter & Dart `^3.11.5` (Material 3 Multi-platform)
- **Mobile UI Libraries**: `skeletonizer ^3.0.0`, `google_fonts ^8.2.1`, `http ^1.6.0`, `shared_preferences ^2.5.6`, `url_launcher ^6.3.3`, `intl ^0.20.3`
- **Web Scraper & Crawler**: `cheerio ^1.2.0` + `node-fetch ^3.3.2`
- **Security & Hashing**: `bcryptjs ^3.0.2` (Cost factor 10) + HTTP-Only Session Cookie & Global `/api/*` CORS Middleware

---

## 6. Spesifikasi Endpoint Web & REST API

### 6.1. REST API Endpoints (`/api/*` — Mobile & Integrasi, dilindungi CORS Middleware)

| Method | Endpoint | Deskripsi | Akses / Catatan |
|---|---|---|---|
| `GET` | `/api/health` | Pemeriksaan status server & konektivitas (mengembalikan `200 OK` dengan header `Access-Control-Allow-Origin: *`) | Publik |
| `GET` | `/api/cron/recrawl` | Menjalankan verifikasi tautan dokumen peraturan (`runRecrawlCheck`) | Cron / Sistem |
| `POST` | `/api/auth/login` | Otentikasi pengguna dan pengembalian profil peran JSON | Publik |
| `GET` | `/api/search` | Pencarian peraturan/pasal termasuk peraturan kosong via `UNION ALL` (`q`, `sektor`, `wilayah`, `page`, `pageSize`) | Publik / Tamu |
| `GET` | `/api/peraturan/:id` | Mengambil detail peraturan beserta seluruh daftar pasalnya | Publik / Tamu |
| `PUT` | `/api/peraturan/:id` | Memperbarui metadata & status peraturan (`jenis_peraturan`, `nomor`, `tahun`, `judul`, `status`, `status_detail`, `wilayah`, `sektor`, `url_dokumen_asli`) | Pengelola / Admin |
| `DELETE` | `/api/peraturan/:id` | Menghapus peraturan beserta seluruh pasalnya (`ON DELETE CASCADE`) | Pengelola / Admin |
| `PUT` | `/api/pasal/:id` | Memperbarui `nomor_pasal`, `nomor_ayat`, dan `teks_pasal` | Pengelola / Admin |
| `DELETE` | `/api/pasal/:id` | Menghapus satu baris pasal | Pengelola / Admin |
| `GET` | `/api/jadwal` | Mengambil daftar agenda rapat harmonisasi | Staf terautentikasi |
| `POST` | `/api/jadwal` | Menambahkan agenda jadwal rapat baru (`jam` berformat `HH:mm`) | Pengelola / Perancang |
| `PUT` | `/api/jadwal/:id` | Memperbarui data jadwal rapat harmonisasi | Pengelola / Perancang |
| `DELETE` | `/api/jadwal/:id` | Menghapus agenda rapat harmonisasi | Pengelola / Perancang |
| `GET` | `/api/admin/users` | Mengambil daftar metadata akun pengguna (tanpa hash/sandi) | Khusus Admin |
| `POST` | `/api/admin/reset-password` | Mereset kata sandi akun staf operasional (`Pengelola` / `Perancang`) | Khusus Admin |
| `POST` | `/api/tambah-peraturan` | Menjalankan crawler untuk mengindeks peraturan baru dari URL & teks manual (`jenis_peraturan`, `judul`, `url`, `teks_manual`) | Pengelola / Admin |

### 6.2. Web SSR & HTMX Routes Utama

| Method | Route | Deskripsi | Middleware RBAC |
|---|---|---|---|
| `GET` / `POST` | `/login`, `/tamu`, `/logout` | Autentikasi web SSR, mode tamu, dan keluar sesi | Publik |
| `GET` | `/`, `/pencarian`, `/search-results` | Halaman utama pencarian dan partial hasil HTMX | `allowGuestOrAuth` |
| `GET` | `/pencarian/status-modal/:peraturan_id` | Modal detail status relasi peraturan | `allowGuestOrAuth` |
| `GET` | `/pencarian/edit-peraturan-modal/:peraturan_id` | Modal edit peraturan | `requirePengelola` (Pengelola & Admin) |
| `POST` | `/pencarian/edit-peraturan/:peraturan_id` | Menyimpan pembaruan metadata & status peraturan (`HX-Trigger: refreshResults`) | `requirePengelola` (Pengelola & Admin) |
| `POST` | `/pencarian/hapus-peraturan/:peraturan_id` | Menghapus peraturan beserta seluruh pasalnya (`HX-Trigger: refreshResults`) | `requirePengelola` (Pengelola & Admin) |
| `GET` | `/pencarian/edit-pasal-modal/:pasal_id` | Modal edit pasal | `requirePengelola` (Pengelola & Admin) |
| `POST` | `/pencarian/edit-pasal/:pasal_id` | Menyimpan pembaruan nomor pasal, ayat, dan teks pasal (`HX-Trigger: refreshResults`) | `requirePengelola` (Pengelola & Admin) |
| `POST` | `/pencarian/hapus-pasal/:pasal_id` | Menghapus baris pasal dari basis data (`HX-Trigger: refreshResults`) | `requirePengelola` (Pengelola & Admin) |
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
   - Pengujian `flutter analyze` bebas peringatan dan `flutter test` (`P3HApp smoke test`) berjalan tanpa sisa timer terbuka.
2. **Keamanan & Privasi**:
   - Penggunaan HTTP-Only Cookie (`SameSite=Lax`) untuk sesi web dan `SharedPreferences` pada client mobile.
   - Hashing kata sandi menggunakan `bcryptjs` dengan cost factor 10.
   - Pencegahan injeksi SQL melalui *parameterized queries* (`mysql2/promise`).
   - Middleware CORS aktif pada seluruh rute `/api/*` (`app.use('/api/*', cors(...))`) agar aplikasi Web & Flutter Web dapat mengakses `/api/health` maupun endpoint REST API lainnya dengan aman.
   - Tidak ada kredensial akun, kata sandi, maupun nilai `.env` produksi yang dicantumkan pada dokumentasi (`README.md` / `PRD.md`).
3. **Ketersediaan & Aksesibilitas**:
   - Desain tata letak responsif untuk resolusi desktop, laptop, tablet, dan smartphone Android.
   - Skema warna terstandarisasi mengacu pada identitas Kementerian Hukum Republik Indonesia (Sovereign Navy `#0B192C`, Administrative Blue `#1D4ED8`, Slate `#1E293B`).
   - Penataan antarmuka bersih tanpa emoji dekoratif sesuai standar tata kelola dokumen pemerintahan.
