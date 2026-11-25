<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Minishlink\WebPush\VAPID;

class BuatKunciVapid extends Command
{
    //   php artisan webpush:vapid           -> tampilkan pasangan kunci baru
    //   php artisan webpush:vapid --write   -> simpan ke .env (hanya bila belum ada)
    protected $signature = 'webpush:vapid {--write : Simpan ke file .env bila VAPID belum diatur}';

    protected $description = 'Buat pasangan kunci VAPID untuk Web Push';

    public function handle(): int
    {
        $keys = VAPID::createVapidKeys();

        if (! $this->option('write')) {
            $this->line('VAPID_PUBLIC_KEY='.$keys['publicKey']);
            $this->line('VAPID_PRIVATE_KEY='.$keys['privateKey']);

            return self::SUCCESS;
        }

        $path = base_path('.env');
        $env = is_file($path) ? file_get_contents($path) : '';
        if (preg_match('/^VAPID_PRIVATE_KEY=\S+/m', $env)) {
            $this->warn('VAPID sudah diatur di .env — tidak diubah (mengganti kunci memutus semua langganan).');

            return self::SUCCESS;
        }

        $env = preg_replace('/^VAPID_(PUBLIC|PRIVATE)_KEY=.*\R?/m', '', $env);
        $env = rtrim($env)."\n\nVAPID_PUBLIC_KEY={$keys['publicKey']}\nVAPID_PRIVATE_KEY={$keys['privateKey']}\n";
        file_put_contents($path, $env);

        $this->info('Kunci VAPID disimpan ke .env. Salin VAPID_PUBLIC_KEY & VAPID_PRIVATE_KEY ke variabel server produksi.');

        return self::SUCCESS;
    }
}
