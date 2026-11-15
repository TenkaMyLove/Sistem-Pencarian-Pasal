<?php

namespace App\Console\Commands;

use App\Services\RecrawlService;
use Illuminate\Console\Command;

class RecrawlPeraturan extends Command
{
    // Dijalankan dengan:  php artisan peraturan:recrawl
    protected $signature = 'peraturan:recrawl';

    protected $description = 'Periksa kesehatan tautan seluruh peraturan (re-crawl berkala)';

    public function handle(RecrawlService $service): int
    {
        $this->info('Memulai pemeriksaan tautan peraturan...');

        $hasil = $service->jalankan();

        $this->info("Selesai: {$hasil['totalChecked']} diperiksa, {$hasil['brokenFound']} tautan bermasalah, {$hasil['fixedCount']} diperbaiki otomatis.");

        return self::SUCCESS;
    }
}
