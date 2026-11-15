# Sistem Pencarian Pasal — P3H Kanwil Kementerian Hukum Kalsel

Sistem pencarian pasal peraturan perundang-undangan dan manajemen harmonisasi regulasi daerah berbasis **Web (Laravel 13 + Blade + HTMX + Tailwind + MySQL 8.x)** dan **Mobile (Flutter + Skeletonizer)** di lingkungan Kantor Wilayah Kementerian Hukum Kalimantan Selatan (Divisi Peraturan Perundang-undangan dan Pembinaan Hukum / P3H).

---

## Fitur Utama

- **Antarmuka Web Modern & Sidebar Tetap** — Tata letak dashboard web dengan *fixed sidebar* (*Kementerian Hukum — Kalimantan Selatan*), *fixed top bar* penanda halaman & profil peran aktif tanpa duplikasi label, halaman login bernuansa *Sovereign Navy* (`#0b192c`), serta pemisahan sesi pegawai dan akses tamu publik.
- **Aplikasi Mobile Flutter Multi-Platform (Desain Flat Navy & Slate)** —
  - **Masuk Sistem & Host Switcher**: Login terintegrasi dengan opsi `Ingat Sesi Saya`, dialog `Lupa Sandi?`, akses cepat `Mode Tamu`, serta tombol pengaturan URL server dengan uji koneksi non-destruktif (`GET /api/health`).
  - **Pencarian Pasal Mobile**: Kotak pencarian + tombol `Cari`, riwayat pencarian lokal, sheet filter `Wilayah` & `Sektor`, pil sektor horizontal, opsi pengurutan (`Relevansi` / `Tahun Terbaru`), animasi loading `Skeletonizer`, pratinjau teks pasal dengan sorotan kata kunci, salin teks pasal, sheet `Status Hubungan`, tombol aksi Edit/Hapus, serta paginasi.
  - **Jadwal Harmonisasi & Cetak Mingguan**: Filter `Semua`, `Pokja 1`, dan `Pokja 2` lengkap dengan hitungan agenda, ringkasan agenda mingguan siap salin (`Cetak Mingguan`), form dialog berstandar waktu `HH:mm` (`WITA`), serta akses tambah/ubah/hapus untuk *Pengelola* dan *Perancang*.
  - **Kelola Akun & Keamanan (Admin)**: Banner protokol keamanan `bcryptjs`, formulir inline *Reset Kata Sandi Staf*, serta daftar akun interaktif dengan `Skeletonizer`.
  - **Tambah Peraturan & Profil Hak Akses**: Formulir indeksasi peraturan baru via URL crawler/teks manual, halaman profil pengguna dengan status server *real-time* & matriks hak akses RBAC, serta halaman detail peraturan dengan filter pasal internal.
- **Pencarian Pasal Real-Time & Query `UNION ALL`** — Pencarian berbasis HTMX (Web) dan REST API JSON (Mobile) dengan penyorotan kata kunci presisi, didukung query `UNION ALL` sehingga peraturan yang baru ditambahkan tanpa pasal tetap terindeks dan muncul dalam hasil (tanpa kotak keterangan tambahan; hanya judul peraturan dan tombol aksi).
- **Edit & Hapus Peraturan dan Pasal (Web & Mobile — Pengelola & Admin)** — Pengguna dengan peran **Pengelola** atau **Admin** dapat memperbarui maupun menghapus metadata/status **peraturan** (termasuk peraturan kosong tanpa pasal) serta isi **pasal** secara *real-time* pada antarmuka Web maupun Mobile (`PUT`/`DELETE` `/api/peraturan/:id` dan `/api/pasal/:id`).
- **Detil Status Relasi Hukum & Sorotan Referensi Pasal Non-Clickable** — Menampilkan relasi status hukum komprehensif (*Mencabut*, *Mencabut Sebagian*, *Mengubah*, *Dicabut Dengan*, *Dicabut Sebagian Dengan*, dan *Diubah Dengan*). Penyebutan pasal di dalam teks keterangan (misal `Pasal 238`) diberi **sorotan (*highlight*) kuning non-clickable** karena pasal rujukan belum tentu tersedia di dalam sistem, sedangkan tautan regulasi relasi membuka dokumen resmi eksternal.
- **Cakupan 86 Peraturan Terindeks & Verifikasi Tautan** — Terdiri dari UUD 1945, Undang-Undang, Perppu, Peraturan Pemerintah, hingga Perda Provinsi/Kabupaten/Kota se-Kalimantan Selatan dengan indikator `normal` / `tautan_bermasalah` serta runner pengecekan tautan (`php artisan peraturan:recrawl` / `GET /api/cron/recrawl`).
- **Hak Akses Berbasis Peran (RBAC)** —
  - **Admin** (`Administrator` — *Manajemen Sistem*): Kelola akun & reset kata sandi staf (`Pengelola` & `Perancang`), Tambah Peraturan via URL, Edit/Hapus Peraturan & Pasal, Pencarian Pasal, serta Jadwal Harmonisasi (*Read-Only*).
  - **Pengelola** (`Pengelola` — *Data & Jadwal*): Pencarian Pasal, Edit & Hapus Peraturan/Pasal, CRUD penuh Jadwal Harmonisasi Rapat, serta Tambah Peraturan via URL Crawler & teks manual.
  - **Perancang** (`Perancang` — *Tim Harmonisasi*): Pencarian Pasal & Filter Peraturan, serta CRUD penuh Jadwal Harmonisasi Rapat.
  - **Tamu** (`Tamu` — *Akses Publik*): Akses pencarian pasal, detail status peraturan, dan tautan dokumen sumber tanpa login.

> **Catatan Keamanan**: Dokumentasi ini sengaja tidak mencantumkan kredensial akun (username/kata sandi) maupun nilai konfigurasi rahasia.

---

## Cakupan Sektor & Peraturan (86 Peraturan Terindeks)

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
| Runtime | PHP `8.4+` (dengan Composer `2.8+`) |
| Web Framework | [Laravel](https://laravel.com/) `^13.0` (Arsitektur MVC: Eloquent ORM, Blade SSR, & REST API) |
| Database | MySQL 8.x (Full-Text Search Indexing & Eloquent / Query Builder) |
| Frontend Web | Blade Templates + HTMX 1.9 + Tailwind CSS + Custom CSS (`public/css/style.css`) |
| Mobile App | [Flutter](https://flutter.dev/) + Dart `^3.11` (Material 3, `google_fonts`, & `skeletonizer ^3.0`) |
| Crawler & Ingestion | Laravel `Http` Client (Guzzle) + `symfony/dom-crawler` + `symfony/css-selector` |
| Keamanan & Hashing | `bcrypt` (`Hash::make` / `password_verify`, kompatibel `$2b$`/`$2y$`) + Laravel Session & CSRF + CORS `/api/*` |
| Pengujian Otomatis | PHPUnit `^12.5` (`php artisan test`) + Flutter Widget Test |

---

## Struktur Proyek

> Panduan lengkap berfokus pemula (penjelasan pola **MVC** langkah demi langkah) tersedia di [`backend-laravel/README.md`](backend-laravel/README.md).

```
backend-laravel/               # Backend Utama (Laravel 13 — MVC + Blade + REST API)
├── app/
│   ├── Console/Commands/      # Perintah CLI (`php artisan peraturan:recrawl`)
│   ├── Http/
│   │   ├── Controllers/       # AuthController, SearchController, JadwalController, AdminController, TambahPeraturanController, Api/ApiController
│   │   └── Middleware/        # LoadUser (sesi/Tamu) & CheckRole (role:staff, role:pengelola, role:admin)
│   ├── Models/                # Eloquent Models (Peraturan, Pasal, JadwalRapat, Pengguna)
│   ├── Services/              # SearchService (UNION ALL), UrlCrawler, RecrawlService
│   └── Support/               # TeksHelper (highlight kata kunci <mark> & tautan rujukan)
├── config/
│   ├── p3h.php                # Konfigurasi daftar jenis peraturan, wilayah, sektor, kompilator
│   └── cors.php               # Konfigurasi CORS untuk endpoint `/api/*`
├── database/
│   ├── migrations/            # Skema tabel MySQL (`create_p3h_tables`)
│   └── seeders/               # Seeder akun awal (`DatabaseSeeder`)
├── public/                    # Aset statis (`css/style.css`, `js/tailwind-config.js`, `images/logo.png`)
├── resources/views/           # Template Blade (`layouts`, `auth`, `search`, `jadwal`, `peraturan`, `admin`, `errors`)
├── routes/
│   ├── web.php                # Rute halaman Web SSR & partial HTMX
│   └── api.php                # Rute REST API JSON (`/api/*`) untuk Flutter Mobile
└── tests/Feature/             # Pengujian fitur otomatis (`ExampleTest.php`)

mobile/                        # Aplikasi Mobile Flutter
├── lib/
│   ├── models/                # Model data (User, SearchItem, JadwalItem, UserAccount)
│   ├── screens/               # Splash, Login, Home, Search, Detail, Jadwal, Tambah, Kelola Akun, Profil, Settings
│   ├── services/              # ApiService (HTTP client + checkHealth override) & AuthService
│   ├── utils/                 # Konstanta palet & radius (constants.dart) & Material 3 theme (theme.dart)
│   ├── widgets/               # Dialog berbagi pakai (Edit & Hapus Peraturan / Pasal)
│   └── main.dart              # Entry point Flutter (P3HApp)
├── test/                      # Smoke test widget (widget_test.dart)
├── android/                   # Konfigurasi native Android (usesCleartextTraffic, Internet)
└── web/                       # Konfigurasi build & run browser web

src/                           # (Legacy) Kode backend Node.js/Hono sebelum migrasi ke Laravel
```

---

## Instalasi & Menjalankan Server Web (Backend Laravel)

### 1. Prasyarat
- **PHP** 8.2+ / 8.4+ dan **Composer** 2.x
- **MySQL** 8.x (misalnya via Laragon, XAMPP, atau MySQL Server standalone)
- **Flutter SDK** (opsional, untuk menjalankan aplikasi mobile)

### 2. Konfigurasi Environment
Masuk ke folder `backend-laravel` dan salin `.env.example` menjadi `.env`:
```bash
cd backend-laravel
cp .env.example .env
php artisan key:generate
```
Variabel penting di `backend-laravel/.env`:
- `DB_CONNECTION=mysql`
- `DB_HOST=127.0.0.1`, `DB_PORT=3306`, `DB_DATABASE=p3h_kemenkum_kalsel`, `DB_USERNAME=root`, `DB_PASSWORD=`
- `APP_TIMEZONE=Asia/Makassar`, `APP_LOCALE=id`

> **Catatan Keamanan**: Jangan pernah mengunggah atau menyertakan berkas `.env` maupun kredensial akun ke dalam repositori Git atau dokumentasi.

### 3. Persiapan Database MySQL
Buat database `p3h_kemenkum_kalsel` di MySQL 8.x, kemudian jalankan migrasi & seeder Laravel (atau impor data awal dari `database_dump_mysql.sql`):
```bash
cd backend-laravel
php artisan migrate
php artisan db:seed
```
> Jika ingin mengimpor seluruh 86 peraturan & 1.426 pasal awal beserta relasi statusnya, jalankan `setup_mysql.bat` dari root proyek.

### 4. Jalankan Server Laravel
Dari root proyek, Anda cukup menjalankan skrip pintas:
```bash
start_laravel.bat
```
Atau secara manual melalui terminal:
```bash
cd backend-laravel
php artisan serve --host=127.0.0.1 --port=3000
```
Server berjalan di `http://localhost:3000` (port `3000` digunakan agar langsung kompatibel dengan aplikasi mobile Flutter tanpa mengubah pengaturan port).

### 5. Verifikasi Tautan Dokumen (Recrawl Check) & Pengujian
Untuk menjalankan pemeriksaan status tautan dokumen peraturan melalui Artisan CLI:
```bash
cd backend-laravel
php artisan peraturan:recrawl
```
Atau panggil endpoint cron job: `GET /api/cron/recrawl`.

Untuk menjalankan pengujian otomatis (menggunakan database SQLite in-memory sehingga aman bagi data MySQL):
```bash
cd backend-laravel
php artisan test
```

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

### Verifikasi Kode & Pengujian Mobile:
```bash
cd mobile
flutter analyze
flutter test
```

> **Catatan Koneksi Server**:
> - Pada Web Browser, aplikasi otomatis terhubung ke `http://localhost:3000` (endpoint `/api/*` telah dilengkapi header CORS `Access-Control-Allow-Origin: *`).
> - Pada Emulator Android Studio, aplikasi otomatis terhubung ke `http://10.0.2.2:3000`.
> - Alamat host server dapat diubah dan diuji langsung melalui menu pengaturan (*Host Switcher*) baik dari halaman Login, ikon server pada AppBar, maupun layar Profil.

---

## Lisensi & Hak Cipta

Dikembangkan untuk mendukung tugas dan fungsi Kantor Wilayah Kementerian Hukum Kalimantan Selatan (Divisi Peraturan Perundang-undangan dan Pembinaan Hukum).
