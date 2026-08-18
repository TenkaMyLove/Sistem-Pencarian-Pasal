# Sistem Pencarian Pasal — P3H Kemenkum Kalsel

Sistem pencarian pasal peraturan perundang-undangan berbasis web untuk mendukung proses harmonisasi Rancangan Peraturan Daerah (Ranperda) di lingkungan Kantor Wilayah Kementerian Hukum Kalimantan Selatan.

---

## Fitur Utama

- **Pencarian Pasal Real-Time** — Pencarian berbasis HTMX dengan keyword highlighting akurat (word-boundary regex) tanpa reload halaman.
- **Cakupan Peraturan Lengkap** — 33 Peraturan Perundang-Undangan (UUD 1945, UU, PP, Perppu, dan Perda) terbagi dalam 9 Sektor Hukum Utama.
- **Filter Sektor & Wilayah** — Filter pencarian cepat berdasarkan sektor hukum dan wilayah (Nasional, Provinsi Kalimantan Selatan, serta Kabupaten/Kota se-Kalsel).
- **Detil Status Peraturan** — Modal interaktif menampilkan status hukum komprehensif (`Berlaku`, `Mencabut`, `Dicabut Dengan`, `Diubah Dengan`, `Mengubah`, `Mencabut Sebagian`).
- **Tautan Dokumen Asli Terverifikasi** — Tautan langsung "Lihat Dokumen PDF Asli" ke portal JDIH BPK (`peraturan.bpk.go.id`) dan JDIH Pemerintah Daerah yang terkonfirmasi valid.
- **Manajemen Jadwal Harmonisasi Rapat** — 
  - Pencatatan lengkap mencakup Judul/Tentang, Tanggal, Waktu, Tempat, Pemohon, dan Kompilator.
  - Multi-Kompilator (dapat memilih lebih dari 1 perancang/kompilator sekaligus).
  - Hak akses berbasis peran: **Perancang** (Read-Only), **Kompilator/Pengelola** (Full CRUD).
- **Kelola Akun Peran** — Admin dapat mengelola pengguna dan peran (Admin, Pengelola/Kompilator, Perancang).

---

## Cakupan Sektor & Peraturan (33 Peraturan)

| Sektor | Peraturan Terindeks |
|---|---|
| **Otonomi & Pemda** | UUD 1945, UU 12/2011, UU 25/2004, UU 23/2014, UU 9/2015, PP 43/2014, PP 18/2016, PP 16/2018, PP 17/2018, Perda Tapin 7/2021 |
| **Investasi & Perizinan** | UU 25/2007, UU 6/2023 (Cipta Kerja), PP 5/2021 (OSS RBA), Perda Kalsel 7/2019 (Jasa Konstruksi) |
| **Keuangan Daerah** | UU 17/2003, UU 1/2004, PP 12/2017, PP 12/2019 |
| **Tata Ruang & Bangunan** | UU 26/2007, PP 21/2021, Perda Banjarmasin 6/2016 (IMB), Perda Tanah Laut 4/2017 (RTRW) |
| **Lingkungan Hidup** | UU 32/2009, PP 22/2021, Perda Banjar 3/2020 (Pengelolaan Sampah) |
| **Pajak & Retribusi** | UU 28/2009, UU 1/2022 (HKPD), Perda Banjarbaru 2/2021 |
| **Ketenagakerjaan** | UU 13/2003, Perda Tabalong 5/2018 |
| **Kesehatan** | UU 36/2009, UU 17/2023 |
| **Pendidikan** | UU 20/2003 (Sisdiknas) |

---

## Teknologi

| Layer | Stack |
|---|---|
| Runtime | Node.js 22 (ESM) |
| Framework | [Hono](https://hono.dev/) (SSR JSX) |
| Database | PostgreSQL (dengan ekstensi `pg_trgm` & `fuzzystrmatch`) |
| Frontend | HTMX + Vanilla CSS |
| Crawler | `cheerio` + custom link verification |
| Build | TypeScript (`tsc`) |

---

## Struktur Proyek

```
src/
├── db/
│   ├── index.ts          # PostgreSQL pool connection
│   ├── schema.sql        # DDL tabel peraturan, pasal, users, jadwal
│   └── seed.ts           # Seeder database
├── middleware/
│   └── auth.ts           # Session & RBAC middleware
├── routes/
│   ├── auth.tsx          # Authenticaton (Login/Logout)
│   ├── search.tsx        # Search engine + status modal (HTMX)
│   ├── jadwal.tsx        # Rapat harmonisasi CRUD
│   └── admin.tsx         # Manajemen akun pengguna
├── scraper/
│   ├── realCrawler.ts          # Verification & crawler URL BPK/Kemnaker
│   ├── crawlStatusPeraturan.ts # Parsing status relasi hukum peraturan
│   ├── ingestAllSectors.ts     # Ingestion data awal 9 sektor
│   └── expandRegulations.ts   # Ingestion ekspansi 33 peraturan
├── views/
│   ├── layout.tsx        # Shell Layout & Navbar
│   ├── search.tsx        # SearchView + StatusDetailModal
│   ├── jadwal.tsx        # JadwalView (Multi-kompilator & Read-Only Perancang)
│   └── admin.tsx         # AdminView (Kelola Pengguna)
└── index.ts              # Server entry point
public/
└── css/style.css         # Styling UI utama
```

---

## Instalasi & Menjalankan

### Prasyarat
- Node.js v22+
- PostgreSQL v14+ (Laragon / Native PostgreSQL)

### Langkah Setup

```bash
# 1. Clone repository & install dependencies
git clone https://github.com/TenkaMyLove/Sistem-Pencarian-Pasal.git
cd Sistem-Pencarian-Pasal
npm install

# 2. Buat database PostgreSQL
createdb p3h_kemenkum_kalsel

# 3. Konfigurasi Lingkungan (.env)
cp .env.example .env
# Sesuaikan PGUSER, PGPASSWORD, PGHOST, PGPORT, PGDATABASE, dan SESSION_SECRET

# 4. Jalankan seeder database & ekspansi peraturan
npx tsx src/db/seed.ts
npx tsx src/scraper/runExpand.ts

# 5. Build & Jalankan Aplikasi
npm run build
npm run start
```

Aplikasi dapat diakses di `http://localhost:3000`.

---

## Lisensi & Pengembangan

Dikembangkan untuk keperluan internal Kantor Wilayah Kementerian Hukum Kalimantan Selatan.
