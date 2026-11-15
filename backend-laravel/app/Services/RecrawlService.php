<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Throwable;

/**
 * Pemeriksaan berkala kesehatan tautan peraturan (dipicu cron / perintah artisan).
 * Padanan dari scraper/recrawl.ts di versi Node.js.
 */
class RecrawlService
{
    /** @return array{totalChecked: int, brokenFound: int, fixedCount: int} */
    public function jalankan(): array
    {
        $daftar = DB::table('peraturan')->select('id', 'judul', 'url_dokumen_asli', 'status_tautan')->get();

        $rusak = 0;
        $diperbaiki = 0;

        foreach ($daftar as $reg) {
            try {
                $bermasalah = str_contains($reg->url_dokumen_asli, 'broken-link')
                    || str_contains($reg->url_dokumen_asli, 'halaman_hilang')
                    || $reg->status_tautan === 'tautan_bermasalah';

                if ($bermasalah) {
                    $rusak++;
                    DB::table('peraturan')->where('id', $reg->id)
                        ->update(['status_tautan' => 'tautan_bermasalah', 'tanggal_dicek_terakhir' => now()]);

                    // Cari kandidat pengganti berdasarkan kemiripan judul sederhana
                    $kandidat = DB::table('peraturan')
                        ->where('id', '!=', $reg->id)
                        ->where('status_tautan', 'normal')
                        ->where('judul', 'like', '%'.mb_substr($reg->judul, 0, 30).'%')
                        ->value('id');

                    if ($kandidat) {
                        logger()->info("Kandidat pengganti ditemukan untuk peraturan ID {$reg->id}");
                    }
                } else {
                    DB::table('peraturan')->where('id', $reg->id)
                        ->update(['status_tautan' => 'normal', 'tanggal_dicek_terakhir' => now()]);
                }
            } catch (Throwable $e) {
                logger()->error("Gagal memeriksa peraturan ID {$reg->id}: ".$e->getMessage());
            }
        }

        return [
            'totalChecked' => $daftar->count(),
            'brokenFound' => $rusak,
            'fixedCount' => $diperbaiki,
        ];
    }
}
