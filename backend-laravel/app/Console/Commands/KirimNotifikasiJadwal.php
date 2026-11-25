<?php

namespace App\Console\Commands;

use App\Services\JadwalPushService;
use Illuminate\Console\Command;

class KirimNotifikasiJadwal extends Command
{
    // Dijadwalkan otomatis tiap menit mulai 08:00 WITA (routes/console.php), atau manual:
    //   php artisan jadwal:kirim-notifikasi
    protected $signature = 'jadwal:kirim-notifikasi';

    protected $description = 'Kirim Web Push untuk rapat harmonisasi hari ini (sekali per rapat)';

    public function handle(JadwalPushService $service): int
    {
        $hasil = $service->kirimHariIni();

        if ($hasil['rapat'] > 0 || $this->output->isVerbose()) {
            $this->info("[{$hasil['status']}] {$hasil['rapat']} rapat, {$hasil['terkirim']} terkirim, "
                ."{$hasil['gagal']} gagal, {$hasil['kedaluwarsa']} langganan kedaluwarsa dihapus.");
        }

        return self::SUCCESS;
    }
}
