<?php

/*
| Web Push (VAPID) untuk notifikasi jadwal rapat harmonisasi.
| Buat pasangan kunci sekali saja dengan:  php artisan webpush:vapid
| lalu isi VAPID_PUBLIC_KEY & VAPID_PRIVATE_KEY di .env (dan di variabel Railway).
| Jangan mengganti kunci setelah dipakai: semua perangkat harus mengaktifkan notifikasi ulang.
*/

return [
    'public_key' => env('VAPID_PUBLIC_KEY', ''),
    'private_key' => env('VAPID_PRIVATE_KEY', ''),

    // Kontak/identitas pengirim untuk layanan push (wajib "mailto:..." atau URL https).
    'subject' => env('VAPID_SUBJECT', env('APP_URL', '')),
];
