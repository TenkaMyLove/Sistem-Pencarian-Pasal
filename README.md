# Sistem Pencarian Pasal — P3H Kanwil Kemenkumham Kalsel

Sistem pencarian pasal peraturan perundang-undangan berbasis web untuk mendukung percepatan dan efektivitas proses harmonisasi Rancangan Peraturan Daerah (Ranperda) dan Rancangan Peraturan Kepala Daerah (Ranperkada) di lingkungan Kantor Wilayah Kementerian Hukum Kalimantan Selatan (Divisi Peraturan Perundang-undangan dan Pembinaan Hukum).

---

## Fitur Utama

- **Pencarian Pasal Real-Time & Cepat** — Pencarian berbasis HTMX dengan penyorotan kata kunci (*keyword highlighting*) presisi menggunakan regex tanpa memuat ulang (*reload*) halaman.
- **Cakupan 56 Peraturan Terindeks** — Terdiri dari UUD 1945, Undang-Undang, Peraturan Pemerintah, Peraturan Pengganti UU (Perppu), hingga Peraturan Daerah Provinsi dan Kabupaten/Kota se-Kalimantan Selatan.
- **Filter Sektor & Wilayah** — Filter pencarian cepat berdasarkan sektor hukum (9+ Sektor) dan cakupan wilayah (Nasional, Provinsi Kalimantan Selatan, serta Kabupaten/Kota di Kalsel).
- **Detil Status Relasi Hukum** — Modal interaktif menampilkan status hukum komprehensif (*Berlaku*, *Mencabut*, *Dicabut Dengan*, *Diubah Dengan*, *Mengubah*, *Mencabut Sebagian*, dan *Dicabut Sebagian Dengan*).
- **Tautan Dokumen Asli Terverifikasi** — Tautan langsung "Lihat Dokumen PDF Asli" ke portal JDIH BPK (`peraturan.bpk.go.id`) dan JDIH Pemerintah Daerah dengan indikator keaktifan tautan (*normal* atau *tautan bermasalah*).
- **Tambah Peraturan & Pasal via Tautan (Web Crawler)** — Fitur scraper otomatis untuk mengindeks peraturan dan pasal baru langsung dari tautan portal hukum (JDIH BPK / web resmi).
- **Manajemen Jadwal Harmonisasi Rapat** —
  - Pencatatan agenda rapat mencakup Jenis Rancangan, Pokok Materi (Tentang), Hari/Tanggal, Jam (WITA), Nama Kompilator, Tim Pokja, dan Pembuat Agenda.
  - Dukungan **Multi-Kompilator** (dapat memilih beberapa perancang sekaligus maupun entri manual).
  - Tampilan aksi yang rapi dan terorganisir.
- **Hak Akses Berbasis Peran (RBAC)** —
  - **Admin**: Mengelola pengguna dan memperbarui kata sandi akun tim operasional.
  - **Pengelola**: Hak akses penuh (Pencarian Pasal, CRUD Jadwal Harmonisasi Rapat, dan Tambah Peraturan via URL).
  - **Perancang**: Hak akses operasional staf (Pencarian Pasal dan Jadwal Harmonisasi Rapat *Read-Only*).
  - **Tamu / Publik**: Akses cepat pencarian pasal tanpa harus login.

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
| Web Framework | [Hono](https://hono.dev/) (SSR JSX) |
| Database | MySQL 8.x (Full-Text Search Indexing & `mysql2`) |
| Frontend | HTMX + Vanilla CSS (Responsive & Modern) |
| Crawler & Ingestion | `cheerio` + Custom Link Crawler & Verifier |
| Type Safety & Compiler | TypeScript (`tsc`) + `tsx` |

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
│   ├── auth.tsx               # Login, Logout, dan Tamu / Publik
│   ├── search.tsx             # Mesin pencari pasal & modal detail status
│   ├── jadwal.tsx             # Manajemen jadwal rapat harmonisasi (CRUD)
│   ├── admin.tsx              # Manajemen akun & reset kata sandi (Admin)
│   └── tambah-peraturan.tsx   # Penambahan peraturan baru via URL scraper
├── scraper/
│   ├── urlCrawler.ts          # Ekstraktor teks & pasal peraturan dari link JDIH
│   ├── recrawl.ts             # Health check & verifikasi tautan dokumen
│   └── recrawlRunner.ts       # Runner jadwal verifikasi otomatis
├── views/
│   ├── layout.tsx             # Layout utama, sidebar, profil pengguna
│   ├── login.tsx              # Halaman login & pintasan mode tamu
│   ├── search.tsx             # Komponen pencarian pasal & detail relasi
│   ├── jadwal.tsx             # Tabel jadwal & modal formulir jadwal
│   ├── admin.tsx              # Tampilan administrasi akun pengguna
│   └── tambah-peraturan.tsx   # Antarmuka input URL peraturan baru
└── index.ts                   # Entry point server Hono
public/
├── css/style.css              # Tata letak & styling antarmuka
└── images/logo.png            # Logo Pengayoman Kemenkumham
```

---

## Instalasi & Menjalankan

### Prasyarat
- **Node.js** v20 atau v22+
- **MySQL** 8.x (Laragon, XAMPP, atau Native MySQL Server)
- **Git**

### Langkah Setup

```bash
# 1. Clone repository & install dependencies
git clone https://github.com/TenkaMyLove/Sistem-Pencarian-Pasal.git
cd Sistem-Pencarian-Pasal
npm install

# 2. Konfigurasi Lingkungan (.env)
cp .env.example .env
```

Buka file `.env` dan sesuaikan parameter koneksi database MySQL Anda:

```env
PORT=3000
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=p3h_kemenkum_kalsel
MYSQL_USER=root
MYSQL_PASSWORD=your_mysql_password
SESSION_SECRET=your_secure_session_secret
```

### 3. Setup Database MySQL

Buat database `p3h_kemenkum_kalsel` di MySQL, kemudian import data awal dari dump SQL:

- **Opsi A (Melalui Command Line / Laragon Batch Script):**
  ```bash
  # Jika menggunakan Laragon / MySQL CLI:
  setup_mysql.bat
  ```
  *Atau manual via command line:*
  ```bash
  mysql -u root -p p3h_kemenkum_kalsel < database_dump_mysql.sql
  ```

- **Opsi B (Melalui GUI Client):**
  Impor file `database_dump_mysql.sql` melalui phpMyAdmin, HeidiSQL, atau DBeaver ke dalam database `p3h_kemenkum_kalsel`.

- **Verifikasi Data Terimport:**
  Jalankan `check_mysql.bat` untuk memverifikasi jumlah data tabel `peraturan`, `pasal`, `pengguna`, dan `jadwal`.

### 4. Menjalankan Aplikasi

```bash
# Mode Pengembangan (Watch mode dengan tsx):
npm run dev

# Mode Produksi (Build ke dist & jalankan):
npm run build
npm run start
```

Aplikasi dapat diakses melalui peramban web di: `http://localhost:3000`.

---

## Peran & Akses Pengguna

| Peran | Deskripsi | Hak Akses |
|---|---|---|
| **Admin** | Administrator Sistem | Mengelola kata sandi akun staf melalui menu Kelola Akun. |
| **Pengelola** | Kompilator & Tim Harmonisasi | Pencarian pasal, CRUD penuh agenda rapat harmonisasi, dan tambah peraturan via tautan. |
| **Perancang** | Perancang Peraturan Perundang-Undangan | Pencarian pasal dan melihat agenda jadwal rapat (*Read-Only*). |
| **Tamu** | Pengguna Publik / Tamu | Pencarian pasal tanpa hak modifikasi jadwal maupun administrasi. |

> **Catatan Kredensial**: Informasi akun operasional dikelola secara internal oleh Administrator Kanwil Kemenkumham Kalsel. Untuk keamanan, kredensial pengguna tidak disertakan dalam dokumentasi publik.

---

## Lisensi & Hak Cipta

Dikembangkan untuk mendukung tugas dan fungsi Kantor Wilayah Kementerian Hukum Kalimantan Selatan.
