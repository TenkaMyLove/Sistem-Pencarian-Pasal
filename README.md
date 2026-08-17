# Sistem Pencarian Pasal — P3H Kemenkum Kalsel

Sistem pencarian pasal peraturan perundang-undangan berbasis web untuk mendukung proses harmonisasi Rancangan Peraturan Daerah (Ranperda) di lingkungan Kantor Wilayah Kementerian Hukum Kalimantan Selatan.

---

## Fitur Utama

- **Pencarian Pasal Real-Time** — Pencarian berbasis HTMX dengan keyword highlighting akurat (word-boundary regex) tanpa reload halaman.
- **Filter Sektor & Wilayah** — Filter berdasarkan 9 sektor hukum dan 14 kabupaten/kota se-Kalimantan Selatan.
- **Paginasi Terstruktur** — Hasil pencarian dibatasi dalam scrollable container dengan paginasi bernomor.
- **Detil Status Peraturan** — Modal yang menampilkan hubungan hukum lengkap tiap peraturan: `Mencabut`, `Mencabut Sebagian`, `Dicabut Dengan`, `Dicabut Sebagian Dengan`, `Diubah Dengan`, `Mengubah`.
- **Tautan Dokumen Asli Terverifikasi** — Setiap peraturan dilengkapi tautan langsung ke halaman resmi JDIH BPK (`peraturan.bpk.go.id`) atau JDIH Kemnaker, diverifikasi HTTP 200.
- **Jadwal Harmonisasi** — Pengelola dapat menambah, mengedit, dan menghapus jadwal rapat harmonisasi Ranperda.
- **Kelola Akun** — Admin dapat mengatur akun Pengelola dan Perancang.
- **Auto Re-crawl** — Scheduled health check tautan sumber tiap 24 jam.

---

## Teknologi

| Layer | Stack |
|---|---|
| Runtime | Node.js 22 (ESM) |
| Framework | [Hono](https://hono.dev/) (SSR JSX) |
| Database | PostgreSQL |
| Frontend | HTMX + Vanilla CSS |
| Crawler | `node-fetch` + `cheerio` |
| Build | TypeScript (`tsc`) |

---

## Crawler JDIH BPK

Sistem menggunakan crawler nyata (bukan hardcoded) untuk mengambil data dari portal JDIH BPK:

1. **URL Dokumen** — Dicrawl via `peraturan.bpk.go.id/Search?nomor=N&tahun=YYYY`, divalidasi slug `jenis-no-N-tahun-YYYY`, diverifikasi HTTP 200.
2. **Status Peraturan** — Dicrawl dari halaman detail BPK, diparsing dari section `STATUS PERATURAN` (label `div.col-12.fw-semibold.bg-light-primary` → items `ol > li.mb-4`).

Menjalankan crawler:
```bash
# Crawl URL dokumen (BPK + Kemnaker)
npx tsx src/scraper/runCrawler.ts

# Crawl Status Peraturan dari halaman detail BPK
npx tsx src/scraper/runStatusCrawler.ts
```

---

## Struktur Proyek

```
src/
├── db/
│   ├── index.ts          # PostgreSQL pool
│   ├── schema.sql        # DDL tabel peraturan, pasal, users, jadwal
│   └── seed.ts           # Seeder utama
├── middleware/
│   └── auth.ts           # Session middleware
├── routes/
│   ├── auth.tsx          # Login/logout
│   ├── search.tsx        # Pencarian pasal + status modal (HTMX)
│   ├── jadwal.tsx        # Jadwal harmonisasi
│   └── admin.tsx         # Kelola akun
├── scraper/
│   ├── realCrawler.ts          # Crawler URL dokumen dari BPK/Kemnaker
│   ├── crawlStatusPeraturan.ts # Crawler Status Peraturan dari halaman detail BPK
│   ├── ingestAllSectors.ts     # Data awal 9 sektor + 14 wilayah Kalsel
│   └── runCrawler.ts / runStatusCrawler.ts  # Entry point runner
├── views/
│   ├── layout.tsx        # Layout utama
│   ├── search.tsx        # SearchView + StatusDetailModal
│   ├── jadwal.tsx        # JadwalView
│   └── admin.tsx         # AdminView
└── index.ts              # Entry point server
public/
└── css/style.css         # Stylesheet utama
```

---

## Instalasi & Menjalankan

### Prasyarat
- Node.js 22+
- PostgreSQL (Laragon / native)

### Setup

```bash
# 1. Install dependencies
npm install

# 2. Buat database PostgreSQL
createdb p3h_kemenkum_kalsel

# 3. Buat file .env
cp .env.example .env
# Isi DATABASE_URL dan SESSION_SECRET

# 4. Jalankan schema + seed
npx tsx src/db/seed.ts

# 5. Crawl URL dokumen dari JDIH BPK (opsional, sudah include dalam seed)
npx tsx src/scraper/runCrawler.ts

# 6. Crawl Status Peraturan dari halaman detail BPK
npx tsx src/scraper/runStatusCrawler.ts

# 7. Build dan jalankan server
npm run build
npm run start
```

Server berjalan di `http://localhost:3000`.

---

## Akun Default

| Role | Username | Password |
|---|---|---|
| Admin | TenkaLOML | (set saat seed) |
| Pengelola | Pengelola | Pengelola123! |
| Perancang | Perancang | Perancang123! |

---

## Sumber Data

Data pasal dan status peraturan bersumber dari:
- **JDIH BPK** — `https://peraturan.bpk.go.id`
- **JDIH Kemnaker** — `https://jdih.kemnaker.go.id`

URL dokumen asli tiap peraturan diverifikasi langsung via HTTP sebelum disimpan ke database.

---

## Lisensi

Proyek ini dikembangkan untuk keperluan internal Kantor Wilayah Kementerian Hukum Kalimantan Selatan.
