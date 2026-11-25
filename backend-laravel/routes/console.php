<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Web Push jadwal rapat hari ini: mulai 08:00 WITA, dicek tiap menit agar rapat yang baru
// ditambahkan hari ini juga terkirim. Tiap rapat hanya dikirim sekali.
// Dijalankan oleh `php artisan schedule:work` (lihat start-container.sh di server).
Schedule::command('jadwal:kirim-notifikasi')
    ->everyMinute()
    ->between('08:00', '23:59')
    ->timezone('Asia/Makassar')
    ->withoutOverlapping(10);
