# Product Requirement Document (PRD)
## Sistem Pencarian Pasal — P3H Kemenkum Kalsel

**Versi**: 2.0  
**Tanggal**: 19 Agustus 2026  
**Status**: Approved & Live  
**Target Pengguna**: Divisi Peraturan Perundang-undangan dan Pembinaan Hukum (P3H), Kantor Wilayah Kementerian Hukum Kalimantan Selatan  

---

## 1. Latar Belakang & Tujuan Produk

Dalam proses harmonisasi Rancangan Peraturan Daerah (Ranperda) dan Rancangan Peraturan Kepala Daerah (Ranperkada) di lingkungan Kantor Wilayah Kementerian Hukum Kalimantan Selatan, tim Perancang Peraturan Perundang-undangan dan Pengelola Harmonisasi membutuhkan akses cepat untuk mencari pasal-pasal relevan dari berbagai tingkat peraturan (UUD 1945, Undang-Undang, Peraturan Pemerintah, Peraturan Presiden, hingga Peraturan Daerah Provinsi/Kabupaten/Kota).

**Tujuan Utama Produk**:
1. Menyediakan mesin pencari pasal peraturan hukum real-time yang cepat, presisi, dan responsif tanpa *page reload*.
2. Menyajikan informasi status relasi hukum antar peraturan secara komprehensif (*Mencabut, Dicabut Dengan, Diubah Dengan, Mengubah, Mencabut Sebagian*).
3. Menyediakan manajemen agenda jadwal rapat harmonisasi Ranperda/Ranperkada yang teratur dengan dukungan multi-kompilator.
4. Menjamin keabsahan dokumen hukum melalui verifikasi otomatis tautan dokumen asli ke portal JDIH BPK (`peraturan.bpk.go.id`) dan JDIH Pemerintah Daerah.

---

## 2. Pengguna & Peran (Role-Based Access Control / RBAC)

Sistem membagi akses pengguna ke dalam 3 tingkat peran utama:

| Peran Pengguna | Deskripsi Peran | Hak Akses Fitur |
|---|---|---|
| **Admin** | Pengembang / Administrator Sistem | • Kelola Akun pengguna (`/kelola-akun`)<br>• Mengubah kata sandi akun `Pengelola` dan `Perancang` |
| **Pengelola** | Pengelola Rapat & Kompilator Harmonisasi | • Pencarian Pasal & Filter Peraturan<br>• Manajemen Jadwal Rapat Harmonisasi (**Full CRUD**: Tambah, Edit, Hapus) |
| **Perancang** | Perancang Peraturan Perundang-undangan | • Pencarian Pasal & Filter Peraturan<br>• Manajemen Jadwal Rapat Harmonisasi (**Read-Only**) |

---

## 3. Spesifikasi Fitur Utama

### 3.1. Mesin Pencarian Pasal & Filter Peraturan
- **Pencarian Real-Time**: Pencarian berbasis HTMX yang memperbarui hasil pencarian secara instan.
- **Word-Boundary Highlight**: Penyorotan kata kunci pencarian pada teks pasal menggunakan *word-boundary regex* presisi tanpa merusak struktur HTML.
- **Filter Sektor & Wilayah**:
  - **9 Sektor Hukum**: Otonomi & Pemda, Investasi & Perizinan, Keuangan Daerah, Tata Ruang & Bangunan, Lingkungan Hidup, Pajak & Retribusi Daerah, Ketenagakerjaan, Kesehatan, Pendidikan.
  - **Wilayah**: Nasional, Provinsi Kalimantan Selatan, serta 14 Kabupaten/Kota se-Kalsel.
- **Detil Status Relasi Hukum (`StatusDetailModal`)**:
  - Modal interaktif yang menampilkan relasi hukum lengkap tiap peraturan: *Mencabut*, *Dicabut Dengan*, *Diubah Dengan*, *Mengubah*, *Mencabut Sebagian*, dan *Dicabut Sebagian Dengan*.
- **Lihat Dokumen PDF Asli**:
  - Tombol tautan langsung yang terverifikasi HTTP 200 ke dokumen resmi di portal JDIH BPK / JDIH Daerah.
  - Indikator otomatis badge `Tautan Bermasalah` jika terjadi galat pada tautan sumber.

### 3.2. Manajemen Jadwal Rapat Harmonisasi
- **Tampilan Agenda Rapat**: Tabel terstruktur menampilkan No, Jenis Rancangan, Tentang (Pokok Materi), Hari/Tanggal, Jam (WITA), Nama Kompilator, Tim Pokja (Pokja 1 / Pokja 2), dan Aksi.
- **Multi-Kompilator**:
  - Opsi checkbox untuk memilih beberapa perancang/kompilator sekaligus (**Eryck**, **Kiki**, **Dian**, **Dame**, **Nizar**, **Wyra**, **Dudunk**, **Ryna**).
  - Field input tambahan untuk memasukkan nama kompilator custom lainnya.
- **Kontrol Hak Akses**:
  - **Pengelola**: Memiliki tombol "Tambah Jadwal Baru", "Edit", dan "Hapus".
  - **Perancang**: Tampilan *read-only* dengan alert informasi bahwa akun berada dalam mode baca.
- **Tata Letak Aksi Presisi**: Tombol aksi *Edit* dan *Hapus* disusun rata tengah secara horizontal (`inline-flex` dengan `white-space: nowrap`) untuk kerapian antarmuka.

### 3.3. Kelola Akun Pengguna (Khusus Admin)
- Antarmuka khusus untuk mengubah kata sandi akun `Pengelola` dan `Perancang`.
- Validasi konfirmasi kata sandi dan pemberitahuan perubahan berhasil.

### 3.4. Auto Re-crawl & Health Check Tautan
- Proses latar belakang (*scheduled background job*) setiap 24 jam untuk memeriksa keaktifan tautan dokumen asli (`status_tautan`).

---

## 4. Cakupan Data Peraturan (33 Peraturan & 105+ Pasal)

Sistem saat ini mencakup **33 Peraturan Perundang-Undangan** terverifikasi:

1. **UUD 1945**: Undang-Undang Dasar Negara Republik Indonesia Tahun 1945
2. **UU No. 12 Tahun 2011**: Pembentukan Peraturan Perundang-undangan
3. **UU No. 25 Tahun 2004**: Sistem Perencanaan Pembangunan Nasional
4. **UU No. 23 Tahun 2014**: Pemerintahan Daerah
5. **UU No. 9 Tahun 2015**: Perubahan Kedua atas UU No. 23 Tahun 2014
6. **UU No. 17 Tahun 2003**: Keuangan Negara
7. **UU No. 1 Tahun 2004**: Perbendaharaan Negara
8. **UU No. 28 Tahun 2009**: Pajak Daerah dan Retribusi Daerah
9. **UU No. 1 Tahun 2022**: Hubungan Keuangan Pusat dan Daerah (HKPD)
10. **UU No. 26 Tahun 2007**: Penataan Ruang
11. **UU No. 32 Tahun 2009**: Perlindungan dan Pengelolaan Lingkungan Hidup
12. **UU No. 25 Tahun 2007**: Penanaman Modal
13. **UU No. 6 Tahun 2023**: Penetapan Perppu Cipta Kerja Menjadi UU
14. **UU No. 13 Tahun 2003**: Ketenagakerjaan
15. **UU No. 36 Tahun 2009**: Kesehatan
16. **UU No. 17 Tahun 2023**: Kesehatan
17. **UU No. 20 Tahun 2003**: Sistem Pendidikan Nasional
18. **PP No. 43 Tahun 2014**: Peraturan Pelaksanaan UU Desa
19. **PP No. 18 Tahun 2016**: Perangkat Daerah
20. **PP No. 12 Tahun 2017**: Pembinaan dan Pengawasan Pemda
21. **PP No. 16 Tahun 2018**: Satuan Polisi Pamong Praja
22. **PP No. 17 Tahun 2018**: Kecamatan
23. **PP No. 12 Tahun 2019**: Pengelolaan Keuangan Daerah
24. **PP No. 5 Tahun 2021**: Perizinan Berusaha Berbasis Risiko (OSS RBA)
25. **PP No. 21 Tahun 2021**: Penyelenggaraan Penataan Ruang
26. **PP No. 22 Tahun 2021**: Penyelenggaraan PPLH
27. **Perppu No. 2 Tahun 2022**: Cipta Kerja
28. **Perda Prov. Kalsel No. 7 Tahun 2019**: Penyelenggaraan Jasa Konstruksi
29. **Perda Kota Banjarmasin No. 6 Tahun 2016**: Izin Mendirikan Bangunan
30. **Perda Kab. Tanah Laut No. 4 Tahun 2017**: RTRW 2017-2037
31. **Perda Kab. Tabalong No. 5 Tahun 2018**: Ketenagakerjaan
32. **Perda Kab. Banjar No. 3 Tahun 2020**: Pengelolaan Sampah
33. **Perda Kota Banjarbaru No. 2 Tahun 2021**: Pajak Daerah
34. **Perda Kab. Tapin No. 7 Tahun 2021**: Ketertiban Umum dan Ketenteraman Masyarakat

---

## 5. Arsitektur Teknis & Perangkat Lunak

```
                  +-----------------------------------+
                  |         Client Browser            |
                  |   HTMX + Custom Vanilla CSS       |
                  +-----------------+-----------------+
                                    |
                                    v (HTTP / REST / HTMX)
                  +-----------------+-----------------+
                  |      Hono Web Server (Node 22)    |
                  |  - Auth & RBAC Middleware         |
                  |  - Hono JSX SSR Engine            |
                  |  - Route Handlers (Search/Jadwal) |
                  +-----------------+-----------------+
                                    |
                                    v (SQL Queries)
                  +-----------------+-----------------+
                  |     PostgreSQL Database           |
                  |  - pg_trgm (Trigram Search)       |
                  |  - fuzzystrmatch (Similarity)     |
                  +-----------------------------------+
```

### Stack Teknologi:
- **Runtime**: Node.js v22 (ESM)
- **Web Framework**: [Hono](https://hono.dev/)
- **Templating**: Hono JSX (Server-Side Rendering)
- **Interactive Component**: HTMX
- **Database**: PostgreSQL dengan ekstensi `pg_trgm` dan `fuzzystrmatch`
- **Styling**: Vanilla CSS (Desain khusus Kemenkumham Kalsel)

---

## 6. Skema Database (Data Model)

Sistem menggunakan 7 tabel utama dalam database PostgreSQL `p3h_kemenkum_kalsel`:

```sql
-- 1. Tabel Peraturan
CREATE TABLE IF NOT EXISTS peraturan (
  id SERIAL PRIMARY KEY,
  jenis_peraturan VARCHAR(50) NOT NULL,
  nomor VARCHAR(50) NOT NULL,
  tahun INTEGER NOT NULL,
  judul TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'berlaku',
  status_detail TEXT DEFAULT '',
  status_detail_json JSONB DEFAULT '{}',
  wilayah VARCHAR(100) DEFAULT 'Nasional',
  sektor VARCHAR(100) DEFAULT 'Lainnya',
  url_dokumen_asli TEXT NOT NULL,
  status_tautan VARCHAR(20) DEFAULT 'normal',
  tanggal_diambil TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  tanggal_dicek_terakhir TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Tabel Pasal
CREATE TABLE IF NOT EXISTS pasal (
  id SERIAL PRIMARY KEY,
  peraturan_id INTEGER REFERENCES peraturan(id) ON DELETE CASCADE,
  nomor_pasal VARCHAR(50) NOT NULL,
  nomor_ayat VARCHAR(50) DEFAULT '',
  teks_pasal TEXT NOT NULL
);

-- 3. Tabel Jadwal Rapat Harmonisasi
CREATE TABLE IF NOT EXISTS jadwal_rapat_harmonisasi (
  id SERIAL PRIMARY KEY,
  jenis_rancangan VARCHAR(50) NOT NULL,
  tentang TEXT NOT NULL DEFAULT '',
  tanggal DATE NOT NULL,
  jam TIME NOT NULL,
  nama_kompilator VARCHAR(255) NOT NULL,
  tim_pokja VARCHAR(50) NOT NULL,
  dibuat_oleh VARCHAR(100) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Tabel Pengguna (Users)
CREATE TABLE IF NOT EXISTS pengguna (
  id SERIAL PRIMARY KEY,
  username VARCHAR(100) UNIQUE NOT NULL,
  kata_sandi_terenkripsi TEXT NOT NULL,
  peran VARCHAR(50) NOT NULL,
  diubah_terakhir_oleh VARCHAR(100),
  tanggal_kata_sandi_diubah TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Tabel Sumber Scraping
CREATE TABLE IF NOT EXISTS sumber_scraping (
  id SERIAL PRIMARY KEY,
  nama_sumber VARCHAR(100) NOT NULL,
  url_dasar TEXT NOT NULL,
  jadwal_crawl_terakhir TIMESTAMP WITH TIME ZONE,
  jadwal_crawl_status_terakhir VARCHAR(50)
);

-- 6. Tabel Antrian Scraping
CREATE TABLE IF NOT EXISTS antrian_scraping (
  id SERIAL PRIMARY KEY,
  sumber_scraping_id INTEGER REFERENCES sumber_scraping(id) ON DELETE CASCADE,
  status_batch VARCHAR(50) DEFAULT 'pending',
  halaman_terakhir_diproses INTEGER DEFAULT 1
);

-- 7. Tabel Log Kegagalan Crawl
CREATE TABLE IF NOT EXISTS log_kegagalan_crawl (
  id SERIAL PRIMARY KEY,
  sumber_scraping_id INTEGER REFERENCES sumber_scraping(id) ON DELETE CASCADE,
  waktu_kegagalan TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  pesan_error TEXT
);
```

---

## 7. Persyaratan Non-Fungsional (Non-Functional Requirements)

1. **Performa**:
   - Waktu respons pencarian pasal `< 200 ms` untuk hasil pencarian 50+ item.
   - Penggunaan memori server RAM `< 50 MB` pada Node.js runtime.
2. **Keamanan (Security)**:
   - Penggunaan HTTP-Only Session Cookies untuk autentikasi.
   - Hashing kata sandi menggunakan `bcrypt` dengan cost factor 10.
   - Tidak menampilkan atau menyimpan kata sandi dalam bentuk *plain text*.
3. **Ketersediaan & Aksesibilitas**:
   - Antarmuka responsif yang nyaman dibuka di perangkat desktop maupun laptop.
   - Penataan antarmuka bersih tanpa emoji sesuai arahan standar resmi instansi.
