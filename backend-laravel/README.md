# Panduan Backend Laravel — P3H Kemenkum Kalsel

Dokumen ini disusun agar arsitektur backend **P3H Kanwil Kementerian Hukum Kalimantan Selatan** mudah dipahami dan dijelaskan, termasuk kepada mahasiswa tingkat awal Ilmu Komputer / Informatika.

---

## 1. Pola Arsitektur: MVC (Model – View – Controller)

Laravel menggunakan pola **MVC** yang memisahkan kode menjadi 3 bagian utama. Bayangkan seperti sebuah **restoran**:

| Komponen | Analogi Restoran | Tugas di Aplikasi Ini | Lokasi Folder |
|---|---|---|---|
| **Route** (Rute) | Buku Menu | Mencocokkan alamat URL (mis. `/pencarian`) dengan Controller yang bertugas | `routes/web.php` & `routes/api.php` |
| **Controller** | Pelayan (*Waiter*) | Menerima permintaan dari browser/HP, meminta data ke Model/Service, lalu menyerahkannya ke View | `app/Http/Controllers/` |
| **Model** | Koki & Gudang Bahan | Berbicara langsung dengan tabel database MySQL (`peraturan`, `pasal`, `pengguna`, `jadwal_rapat_harmonisasi`) | `app/Models/` |
| **View** (Blade) | Piring Saji | Menyusun tampilan HTML yang dilihat pengguna di layar browser | `resources/views/` |

---

## 2. Alur Kerja Saat Pengguna Mencari Pasal (Step-by-Step)

Misalnya pengguna mengetik kata **`pajak`** di halaman pencarian:

1. **Browser / HTMX** mengirim permintaan `GET /search-results?q=pajak`.
2. **Route** (`routes/web.php`) membaca alamat tersebut dan mengarahkannya ke `SearchController@results`.
3. **Middleware** (`app/Http/Middleware/LoadUser.php`) mengecek session login. Jika belum login, pengguna otomatis diberi identitas **Tamu**.
4. **Controller** (`app/Http/Controllers/SearchController.php`) memanggil `SearchService->cari('pajak')`.
5. **Service & Database** (`app/Services/SearchService.php`) menjalankan query `UNION ALL` ke tabel `pasal` dan `peraturan` di MySQL, lalu mengembalikan daftar pasal yang cocok.
6. **View Blade** (`resources/views/search/results.blade.php`) mengubah data tersebut menjadi kartu HTML lengkap dengan sorotan `<mark>pajak</mark>` (dibantu `app/Support/TeksHelper.php`).
7. **Browser** langsung menampilkan hasilnya tanpa me-*reload* seluruh halaman berkat **HTMX**.

> **Bagaimana dengan aplikasi Mobile Flutter?**
> Prosesnya persis sama, hanya saja Flutter memanggil rute di `routes/api.php` (mis. `GET /api/search?q=pajak`) dan `ApiController` mengembalikan data dalam bentuk **JSON**, bukan HTML.

---

## 3. Peta File Penting (Yang Perlu Dibuka Saat Demo / Penjelasan)

```text
backend-laravel/
├── config/
│   └── p3h.php                         # Daftar pilihan jenis peraturan, wilayah, sektor, kompilator
├── routes/
│   ├── web.php                         # Daftar URL untuk website (HTML + HTMX)
│   └── api.php                         # Daftar URL untuk aplikasi mobile Flutter (JSON)
├── app/
│   ├── Models/                         # Representasi tabel MySQL sebagai class PHP (Eloquent ORM)
│   │   ├── Peraturan.php               # Tabel `peraturan` (memiliki banyak Pasal)
│   │   ├── Pasal.php                   # Tabel `pasal` (milik satu Peraturan)
│   │   ├── JadwalRapat.php             # Tabel `jadwal_rapat_harmonisasi`
│   │   └── Pengguna.php                # Tabel `pengguna` + verifikasi kata sandi bcrypt
│   ├── Http/
│   │   ├── Middleware/
│   │   │   ├── LoadUser.php            # Mengisi variabel $user di setiap halaman (default: Tamu)
│   │   │   └── CheckRole.php           # Pembatas hak akses (role:staff, role:pengelola, role:admin)
│   │   └── Controllers/
│   │       ├── AuthController.php      # Login, Logout, dan Mode Tamu
│   │       ├── SearchController.php    # Pencarian pasal, modal status, edit/hapus peraturan & pasal
│   │       ├── JadwalController.php    # CRUD Jadwal Rapat Harmonisasi
│   │       ├── TambahPeraturanController.php # Form tambah peraturan baru via URL crawler
│   │       ├── AdminController.php     # Kelola akun & reset kata sandi staf
│   │       └── Api/ApiController.php   # Semua endpoint JSON `/api/*` untuk Flutter
│   ├── Services/
│   │   ├── SearchService.php           # Logika query pencarian (dipakai bersama oleh Web & API)
│   │   ├── UrlCrawler.php              # Robot pengambil judul, pasal, dan status dari halaman JDIH/BPK
│   │   └── RecrawlService.php          # Pemeriksa kesehatan tautan peraturan
│   └── Support/
│       └── TeksHelper.php              # Penyorot kata kunci (<mark>) & pembuat link rujukan peraturan
├── database/
│   ├── migrations/
│   │   └── 2026_11_14_000000_create_p3h_tables.php # Skema tabel database MySQL
│   └── seeders/
│       └── DatabaseSeeder.php          # Pembuat akun awal (Admin, Pengelola, Perancang)
├── resources/views/                    # Template HTML (Blade)
│   ├── layouts/app.blade.php           # Kerangka utama (Sidebar + Topbar)
│   ├── auth/login.blade.php            # Halaman Login
│   ├── search/                         # Halaman pencarian, daftar hasil, dan popup modal
│   ├── jadwal/                         # Halaman tabel & modal jadwal rapat
│   ├── peraturan/tambah.blade.php      # Halaman tambah peraturan
│   └── admin/akun.blade.php            # Halaman kelola akun
└── tests/Feature/
    └── ExampleTest.php                 # Pengujian otomatis (Web + Hak Akses + API)
```

---

## 4. Perintah Penting (Terminal)

Jalankan perintah berikut dari dalam folder `backend-laravel`:

```bash
# 1. Menjalankan server di http://localhost:3000 (port yang sama dengan konfigurasi Flutter)
php artisan serve --port=3000

# 2. Membuat tabel database (aman, tidak menghapus tabel yang sudah ada)
php artisan migrate

# 3. Mengisi akun awal jika tabel pengguna masih kosong
php artisan db:seed

# 4. Melihat seluruh daftar URL / endpoint yang tersedia
php artisan route:list --except-vendor

# 5. Memeriksa kesehatan tautan dokumen peraturan (re-crawl)
php artisan peraturan:recrawl

# 6. Menjalankan pengujian otomatis (menggunakan database memori, aman bagi data MySQL)
php artisan test
```
