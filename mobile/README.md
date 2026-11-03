# P3H Kemenkumham Kalsel — Versi Mobile (Flutter)

Aplikasi mobile resmi **Sistem Pencarian Pasal untuk Harmonisasi Ranperda** pada Kantor Wilayah Kementerian Hukum Kalimantan Selatan (Divisi Peraturan Perundang-undangan dan Pembinaan Hukum).

Aplikasi ini dikembangkan menggunakan **Flutter** dan mendukung multi-platform penuh: **Web Browser (Chrome/Edge)** serta **Android Studio Emulator & Physical Device**.

---

## Fitur Utama Aplikasi Mobile

1. **Pencarian Pasal & Peraturan Real-Time**:
   - Pencarian cepat berdasarkan teks pasal, nomor pasal, jenis peraturan, dan judul.
   - Filter dropdown & chip berdasarkan **Sektor Hukum** (9+ Sektor) dan **Cakupan Wilayah** (Nasional, Provinsi Kalsel, dan Kabupaten/Kota se-Kalsel).
   - Tampilan badge status hukum peraturan (*Berlaku*, *Mengubah*, *Dicabut*).
   - Salin teks pasal langsung ke clipboard.
   - Buka dokumen PDF asli JDIH BPK / Pemda melalui peramban eksternal.
   - Paginasi data hasil pencarian.

2. **Skeletonizer Loading State**:
   - Seluruh pemuatan data (pencarian, daftar jadwal rapat, detail pasal peraturan, akun pengguna) menggunakan package **`skeletonizer`** untuk menghadirkan efek shimmer/skeleton yang halus dan modern.

3. **Detail Status Relasi Hukum**:
   - Menampilkan status relasi komprehensif peraturan (*Mencabut*, *Dicabut Dengan*, *Mengubah*, *Diubah Dengan*, *Mencabut Sebagian*, dll).
   - Menampilkan seluruh daftar pasal yang terdapat di dalam peraturan terkait beserta fitur pencarian internal pasal.

4. **Jadwal Rapat Harmonisasi**:
   - Daftar agenda rapat Ranperda & Ranperkada lengkap dengan Tanggal, Jam WITA, Tim Pokja, Kompilator, dan Pembuat Agenda.
   - Filter tab: *Semua*, *Ranperda*, dan *Ranperkada*.
   - CRUD Jadwal (Tambah, Edit, Hapus) untuk peran **Pengelola** dan **Perancang**.

5. **Web Crawler Tambah Peraturan via URL** *(Peran Pengelola)*:
   - Formulir input URL portal hukum resmi untuk mengindeks peraturan baru secara otomatis ke database.

6. **Kelola Akun & Reset Kata Sandi** *(Peran Admin)*:
   - Pengelolaan kata sandi untuk akun staf operasional (*Pengelola* dan *Perancang*).

7. **Mode Tamu / Publik & RBAC**:
   - Mode Tamu dapat langsung mencari dan membaca pasal tanpa login.
   - Login staf operasional dengan otentikasi peran (Admin, Pengelola, Perancang).

8. **Pengaturan Host & Alamat Server Fleksibel**:
   - Terdapat dialog pengaturan host API terintegrasi yang memudahkan pengalihan antara:
     - **Web Browser**: `http://localhost:3000`
     - **Android Studio Emulator**: `http://10.0.2.2:3000`
     - **Device Fisik / Jaringan LAN**: `http://<IP_KOMPUTER>:3000`
   - Dilengkapi tombol *Uji Koneksi Server* secara real-time.

---

## Konfigurasi Jaringan & Host Backend

Karena sistem backend Node.js (Hono) berjalan di mesin lokal Anda (port `3000`), Flutter menggunakan konfigurasi host otomatis:

| Platform | Host Default | Catatan |
|---|---|---|
| **Web Browser (Chrome)** | `http://localhost:3000` | Berjalan di mesin yang sama dengan backend. |
| **Android Studio Emulator** | `http://10.0.2.2:3000` | `10.0.2.2` adalah loopback khusus emulator Android untuk mengakses `localhost` komputer host. |
| **HP Android Fisik (USB / Wi-Fi)** | `http://192.168.x.x:3000` | Sesuaikan dengan IP LAN komputer Anda pada menu *Profil & Host* > *Ubah Pengaturan Host API*. |

> **Catatan Android:** Pengaturan `android:usesCleartextTraffic="true"` dan izin `android.permission.INTERNET` telah aktif di `AndroidManifest.xml` sehingga emulator Android dapat terhubung langsung ke HTTP server development tanpa kendala security policy.

---

## Cara Menjalankan

### 1. Jalankan Backend Server Terlebih Dahulu

Dari direktori root proyek (`E:\Project Magang Kanwil`):
```bash
npm run dev
```
Pastikan backend telah aktif dan MySQL berjalan di `http://localhost:3000`.

---

### 2. Membuka di Web Browser (Google Chrome / Edge)

Masuk ke direktori `mobile`:
```bash
cd mobile
flutter run -d chrome
```
*Aplikasi akan terbuka otomatis di jendela Google Chrome.*

---

### 3. Membuka di Emulator Android Studio

1. Buka **Android Studio** > jalankan salah satu **Android Virtual Device (AVD)** melalui *Device Manager*.
2. Atau jalankan emulator melalui terminal:
   ```bash
   flutter emulators --launch <nama_emulator>
   ```
3. Jalankan aplikasi mobile:
   ```bash
   cd mobile
   flutter run -d android
   ```
*Aplikasi akan ter-compile dan langsung berjalan di emulator Android Studio Anda.*

---

## Struktur Folder Mobile

```
mobile/
├── android/
│   └── app/src/main/AndroidManifest.xml    # Internet & cleartext traffic permissions
├── web/
│   └── index.html                          # Web viewport & meta settings
├── assets/
│   └── images/logo.png                     # Logo resmi Kemenkumham
├── lib/
│   ├── main.dart                           # Entry point aplikasi
│   ├── models/
│   │   ├── user.dart                       # Model pengguna & hak akses
│   │   ├── search_item.dart                # Model pasal & peraturan
│   │   ├── jadwal_item.dart                # Model jadwal rapat harmonisasi
│   │   └── user_account.dart               # Model akun admin
│   ├── services/
│   │   ├── api_service.dart                # Client REST API & pengelola Base URL
│   │   └── auth_service.dart               # Session, SharedPreferences, & auth state
│   ├── utils/
│   │   ├── constants.dart                  # Warna, URL default, & preferensi
│   │   └── theme.dart                      # Tema Material 3 dengan Plus Jakarta Sans
│   └── screens/
│       ├── splash_screen.dart              # Layar pembuka animasi
│       ├── login_screen.dart               # Login pegawai & pintasan mode tamu
│       ├── home_screen.dart                # Shell utama dengan Bottom Navigation
│       ├── search_screen.dart              # Pencarian pasal (dengan Skeletonizer)
│       ├── peraturan_detail_screen.dart    # Detail status relasi & daftar pasal (Skeletonizer)
│       ├── jadwal_screen.dart              # Daftar jadwal rapat harmonisasi (Skeletonizer)
│       ├── jadwal_form_dialog.dart         # Formulir tambah/ubah jadwal rapat
│       ├── tambah_peraturan_screen.dart    # Scraper peraturan baru via URL
│       ├── kelola_akun_screen.dart         # Admin manajemen akun & sandi
│       ├── profile_screen.dart             # Status host & hak akses pengguna
│       └── settings_dialog.dart            # Dialog ganti base URL API secara instan
└── pubspec.yaml                            # Dependencies: skeletonizer, http, url_launcher, dll
```
