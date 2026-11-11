# Sistem Pencarian Pasal — P3H Kanwil Kementerian Hukum Kalsel

Sistem pencarian pasal peraturan perundang-undangan berbasis **Web (Hono + HTMX + MySQL 8.x)** dan **Mobile (Flutter + Skeletonizer)** untuk mendukung percepatan dan efektivitas proses harmonisasi Rancangan Peraturan Daerah (Ranperda) dan Rancangan Peraturan Kepala Daerah (Ranperkada / Ranpergub) di lingkungan Kantor Wilayah Kementerian Hukum Kalimantan Selatan (Divisi Peraturan Perundang-undangan dan Pembinaan Hukum / P3H).

---

## Fitur Utama

- **Pencarian Pasal Real-Time & Cepat** — Pencarian berbasis HTMX dengan penyorotan kata kunci (*keyword highlighting*) presisi menggunakan regex tanpa memuat ulang (*reload*) halaman, didukung query `UNION ALL` agar peraturan baru tanpa pasal tetap terindeks.
- **Edit & Hapus Pasal (Khusus Pengelola & Admin)** — Pengguna dengan peran **Pengelola** atau **Admin** dapat langsung mengubah (`Nomor Pasal`, `Nomor Ayat`, `Teks Pasal` melalui modal HTMX) maupun menghapus pasal tertentu pada kartu hasil pencarian web.
- **Cakupan 56 Peraturan Terindeks** — Terdiri dari UUD 1945, Undang-Undang, Perppu, Peraturan Pemerintah, hingga Peraturan Daerah Provinsi dan Kabupaten/Kota se-Kalimantan Selatan.
- **Filter Sektor & Wilayah** — Filter pencarian cepat berdasarkan sektor hukum dan cakupan wilayah (Nasional, Provinsi Kalimantan Selatan, serta Kabupaten/Kota di Kalsel).
- **Detil Status Relasi Hukum & Sorotan Referensi Pasal** — Modal interaktif menampilkan status hukum komprehensif (*Mencabut*, *Mencabut Sebagian*, *Mengubah*, *Dicabut Dengan*, *Dicabut Sebagian Dengan*, dan *Diubah Dengan*). Penyebutan pasal di dalam teks keterangan (misal `Pasal 238`) ditampilkan dengan **sorotan (*highlight*) kuning non-clickable** karena pasal yang dirujuk belum tentu tersedia di sistem, sedangkan tautan regulasi relasi membuka dokumen resmi JDIH.
- **Tautan Dokumen Asli Terverifikasi** — Tautan langsung ke portal JDIH BPK (`peraturan.bpk.go.id`) dan JDIH Pemerintah Daerah dengan indikator keaktifan tautan (`normal` atau `tautan_bermasalah`) serta runner pengecekan tautan (`npm run recrawl` / `/api/cron/recrawl`).
- **Tambah Peraturan & Pasal via Tautan (Web Crawler)** — Fitur ekstraktor otomatis untuk mengindeks peraturan dan pasal baru langsung dari tautan portal hukum resmi, dilengkapi kolom teks manual opsional.
- **Manajemen Jadwal Harmonisasi Rapat** —
  - Pencatatan agenda rapat mencakup Jenis Rancangan (Ranperda / Ranpergub), Pokok Materi (*Tentang*), Hari/Tanggal, Jam (WITA), Nama Kompilator, Tim Pokja (Pokja 1 / Pokja 2), dan Pembuat Agenda.
  - Dukungan **Multi-Kompilator** (memilih beberapa kompilator dari daftar tim maupun entri manual).
- **Kelola Akun Staf (Admin)** — Manajemen pembaruan kata sandi untuk akun operasional tim (**Pengelola** dan **Perancang**) dengan enkripsi `bcryptjs`. *(Demi keamanan, dokumentasi ini tidak mencantumkan kredensial atau kata sandi akun.)*
- **Hak Akses Berbasis Peran (RBAC)** —
  - **Admin** (`Administrator`): Mengelola & mereset kata sandi akun operasional tim (`Pengelola` dan `Perancang`), Tambah Peraturan via URL serta Edit/Hapus Pasal pada Web, Pencarian Pasal, dan Jadwal Harmonisasi (*Read-Only*).
  - **Pengelola** (`Pengelola`): Pencarian Pasal, Edit & Hapus Pasal (Web), CRUD penuh Jadwal Harmonisasi Rapat (Web & Mobile), serta Tambah Peraturan via URL Crawler (Web & Mobile).
  - **Perancang** (`Perancang`): Pencarian Pasal & Filter Peraturan, serta CRUD penuh Jadwal Harmonisasi Rapat (Web & Mobile).
  - **Tamu** (`Akses Publik`): Akses cepat pencarian pasal, detail status peraturan, dan tautan dokumen PDF asli tanpa harus login.
- **Versi Mobile Flutter Multi-Platform** — Dilengkapi aplikasi mobile Flutter dengan efek shimmer/loading modern menggunakan **Skeletonizer**, fitur baca seluruh pasal dalam satu peraturan, salin teks pasal, *Host Server Switcher*, dan siap dijalankan di browser (Chrome/Edge) maupun emulator Android Studio.

---

## Cakupan Sektor & Peraturan (56 Peraturan Terindeks)

| Sektor | Peraturan Terindeks |
|---|---|
| **Otonomi & Pemerintahan Daerah** | UUD 1945, UU 23/2014, UU 9/2015, UU 12/2011, UU 15/2019, UU 13/2022, UU 25/2004, UU 30/2014, UU 25/2009, UU 14/2008, UU 6/2014, UU 3/2024, PP 43/2014, PP 18/2016, PP 16/2018, PP 17/2018, PP 11/2019, PP 72/2019, Perda Tapin 7/2021 |
| **Investasi & Perizinan** | UU 25/2007, UU 11/2020, UU 6/2023 (Cipta Kerja), PP 5/2021 (OSS RBA), Perda Kalsel 7/2019 (Jasa Konstruksi) |
| **Keuangan Daerah** | UU 17/2003, UU 1/2004, PP 12/2017, PP 12/2019, PP 10/2021 |
| **Tata Ruang & Bangunan** | UU 26/2007, UU 28/2002, PP 21/2021, PP 16/2021, Perda Banjarmasin 6/2016 (IMB), Perda Tanah Laut 4/2017 (RTRW) |
| **Lingkungan Hidup** | UU 32/2009, UU 18/2008, PP 22/2021, Perda Banjar 3/2020 (Pengelolaan Sampah) |
| **Pajak & Retribusi Daerah** | UU 28/2009, UU 1/2022 (HKPD), Perda Banjarbaru 2/2021 |
| **Ketenagakerjaan** | UU 13/2003, PP 35/2021, PP 36/2021, Perda Tabalong 5/2018 |
| **Kesehatan** | UU 36/2009, UU 17/2023 |
| **Pendidikan** | UU 20/2003 (Sisdiknas) |
| **Hukum Pidana & Jasa Konstruksi** | UU 1/2023 (KUHP), UU 1/2026, UU 2/2017, PP 14/2021 |
| **Peraturan Daerah Kalsel Lainnya** | Perda Kalsel 6/2023, Perda Kalsel 11/2016, Perda Kalsel 11/2021 |

---

## Teknologi

| Layer | Stack |
|---|---|
| Runtime | Node.js (v20+ / v22+) (ESM) |
| Web Framework | [Hono](https://hono.dev/) `^4.6` (SSR JSX & REST API) |
| Database | MySQL 8.x (Full-Text Search Indexing & `mysql2 ^3.11`) |
| Frontend Web | HTMX 1.9 + Vanilla CSS (Responsive & Modern) |
| Mobile App | [Flutter](https://flutter.dev/) + Dart `^3.11` (Material 3 & `skeletonizer ^3.0`) |
| Crawler & Ingestion | `cheerio ^1.2` + `node-fetch ^3.3` + Custom Link Crawler & Verifier |
| Keamanan & Hashing | `bcryptjs ^3.0` + HTTP-Only Session Cookie + CORS Middleware |
| Type Safety & Compiler | TypeScript (`^5.7`) + `tsx` |

---

## Struktur Proyek

```
src/
├── db/
│   ├── index.ts               # MySQL connection pool (mysql2/promise)
│   ├── schema.sql             # Skema legacy (PostgreSQL)
│   └── schema_mysql.sql       # DDL skema MySQL 8.x (Fulltext, Relasi, Jadwal)
├── middleware/
│   └── auth.ts                # Session cookie & RBAC middleware
├── routes/
│   ├── api.ts                 # REST API endpoints untuk Flutter Mobile & Web
│   ├── auth.tsx               # Login, Logout, dan Akses Tamu
│   ├── search.tsx             # Pencarian pasal, modal detail status, serta edit/hapus pasal
│   ├── jadwal.tsx             # Manajemen jadwal rapat harmonisasi (CRUD)
│   ├── admin.tsx              # Manajemen akun & reset kata sandi staf (Admin)
│   └── tambah-peraturan.tsx   # Penambahan peraturan baru via URL scraper
├── scraper/
│   ├── urlCrawler.ts          # Ekstraktor teks & pasal peraturan dari link JDIH
│   ├── recrawl.ts             # Health check & verifikasi tautan dokumen
│   └── recrawlRunner.ts       # Runner CLI verifikasi tautan
├── views/
│   ├── layout.tsx             # Layout utama, sidebar, profil pengguna
│   ├── login.tsx              # Halaman login & pintasan masuk tamu
│   ├── search.tsx             # Kartu hasil pencarian, highlight pasal, modal status & edit pasal
│   ├── jadwal.tsx             # Tabel jadwal & modal formulir jadwal multi-kompilator
│   ├── admin.tsx              # Tampilan kelola akun pengguna
│   └── tambah-peraturan.tsx   # Antarmuka input URL peraturan baru & teks manual
└── index.ts                   # Entry point server Hono

mobile/                        # Aplikasi Mobile Flutter
├── lib/
│   ├── models/                # Model data (User, SearchItem, JadwalItem, UserAccount)
│   ├── screens/               # Halaman UI (Splash, Login, Home, Search, Detail, Jadwal, Tambah Peraturan, Admin, Profil, Settings)
│   ├── services/              # ApiService (HTTP client) & AuthService (SharedPreferences)
│   ├── utils/                 # Konstanta URL host & tema aplikasi
│   └── main.dart              # Entry point Flutter
├── android/                   # Konfigurasi native Android (usesCleartextTraffic, Internet)
└── web/                       # Konfigurasi build & run browser web

public/
├── css/style.css              # Tata letak & styling antarmuka web
├── images/logo.png            # Logo Pengayoman
└── favicon.ico                # Ikon aplikasi web
```

---

## Instalasi & Menjalankan Server Web (Backend)

### 1. Prasyarat
- **Node.js** v20+ atau v22+
- **MySQL** 8.x (misalnya via Laragon, XAMPP, atau MySQL Server standalone)
- **Flutter SDK** (opsional, untuk menjalankan aplikasi mobile)

### 2. Konfigurasi Environment
Salin berkas `.env.example` menjadi `.env`, lalu sesuaikan nilainya dengan konfigurasi MySQL lokal dan secret aplikasi Anda:
```bash
cp .env.example .env
```
Variabel yang dibutuhkan di `.env`:
- `PORT` — Port server HTTP (default `3000`)
- `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD` — Konfigurasi koneksi ke MySQL 8.x
- `SESSION_SECRET` — Kunci rahasia untuk sesi aplikasi

> **Catatan Keamanan**: Jangan pernah mengunggah atau menyertakan berkas `.env` maupun kredensial akun ke dalam repositori Git atau dokumentasi.

### 3. Persiapan Database MySQL
Buat database `p3h_kemenkum_kalsel` di MySQL 8.x, kemudian impor skema dan data awal menggunakan berkas SQL yang tersedia:
- Skema tabel: `src/db/schema_mysql.sql`
- Data awal peraturan & pasal: `database_dump_mysql.sql`
- Pada Windows (Laragon), dapat memanfaatkan skrip `setup_mysql.bat` setelah menyesuaikan path `mysql.exe` dan parameter koneksi lokal Anda.

### 4. Jalankan Server
```bash
npm install
npm run dev
```
Untuk build produksi:
```bash
npm run build
npm start
```
Server berjalan secara default di `http://localhost:3000`.

### 5. Verifikasi Tautan Dokumen (Recrawl Check)
Untuk menjalankan pemeriksaan status tautan dokumen peraturan:
```bash
npm run recrawl
```
Atau panggil endpoint cron job: `GET /api/cron/recrawl`.

---

## Menjalankan Aplikasi Mobile (Flutter)

Aplikasi mobile berada pada direktori `mobile`. Pastikan server backend sudah berjalan terlebih dahulu.

```bash
cd mobile
flutter pub get
```

### Jalankan di Web Browser (Chrome/Edge):
```bash
flutter run -d chrome
```

### Jalankan di Emulator Android Studio:
1. Nyalakan emulator Android Studio (AVD) Anda.
2. Jalankan perintah:
```bash
flutter run -d android
```

> **Catatan Koneksi Server**:
> - Pada Web Browser, aplikasi otomatis terhubung ke `http://localhost:3000`.
> - Pada Emulator Android Studio, aplikasi otomatis terhubung ke `http://10.0.2.2:3000`.
> - Alamat host server juga dapat diubah secara instan melalui menu pengaturan (*Host Switcher*) di dalam aplikasi, baik dari halaman Login maupun tab Profil & Host.

---

## Lisensi & Hak Cipta

Dikembangkan untuk mendukung tugas dan fungsi Kantor Wilayah Kementerian Hukum Kalimantan Selatan (Divisi Peraturan Perundang-undangan dan Pembinaan Hukum).
