<?php

namespace App\Services;

use App\Models\JadwalRapat;
use App\Models\Pengguna;
use App\Models\PushSubscription;
use Illuminate\Support\Facades\Log;
use Minishlink\WebPush\WebPush;

/**
 * Mengirim Web Push "Rapat Harmonisasi Hari Ini" ke semua perangkat Pengelola/Perancang
 * yang mengaktifkan notifikasi — tetap sampai walau browser/PWA sedang tertutup.
 *
 * Aman dipanggil berulang (dijadwalkan tiap menit mulai 08:00 WITA): setiap rapat hanya
 * dikirim sekali per hari, ditandai lewat kolom `notifikasi_terkirim_tanggal`.
 * Rapat yang ditambahkan setelah 08:00 untuk hari ini ikut terkirim pada menit berikutnya.
 */
class JadwalPushService
{
    public const JAM_MULAI = '08:00';

    public const PERAN_PENERIMA = ['Pengelola', 'Perancang'];

    public static function aktif(): bool
    {
        return filled(config('webpush.public_key')) && filled(config('webpush.private_key'));
    }

    /** @return array{status: string, rapat: int, terkirim: int, gagal: int, kedaluwarsa: int} */
    public function kirimHariIni(): array
    {
        $hasil = ['status' => 'ok', 'rapat' => 0, 'terkirim' => 0, 'gagal' => 0, 'kedaluwarsa' => 0];

        if (! self::aktif()) {
            return ['status' => 'VAPID belum diatur'] + $hasil;
        }

        $now = now('Asia/Makassar');
        if ($now->format('H:i') < self::JAM_MULAI) {
            return ['status' => 'belum jam kerja'] + $hasil;
        }

        $hariIni = $now->toDateString();
        $rapat = JadwalRapat::whereDate('tanggal', $hariIni)
            ->where(fn ($q) => $q->whereNull('notifikasi_terkirim_tanggal')
                ->orWhereDate('notifikasi_terkirim_tanggal', '!=', $hariIni))
            ->orderBy('jam')
            ->get();

        if ($rapat->isEmpty()) {
            return $hasil;
        }

        // Tandai dulu agar tidak terkirim ganda bila proses berjalan bersamaan.
        // toBase(): jangan ikut mengubah updated_at.
        JadwalRapat::whereIn('id', $rapat->pluck('id'))->toBase()
            ->update(['notifikasi_terkirim_tanggal' => $hariIni]);
        $hasil['rapat'] = $rapat->count();

        $langganan = PushSubscription::whereIn(
            'pengguna_id',
            Pengguna::whereIn('peran', self::PERAN_PENERIMA)->select('id'),
        )->get();

        if ($langganan->isEmpty()) {
            return $hasil;
        }

        $webPush = new WebPush(
            ['VAPID' => [
                'subject' => config('webpush.subject'),
                'publicKey' => config('webpush.public_key'),
                'privateKey' => config('webpush.private_key'),
            ]],
            [
                // Kedaluwarsa tengah malam WITA: perangkat yang baru menyala besok tidak menerima jadwal kemarin
                'TTL' => max(60, (int) $now->diffInSeconds($now->copy()->endOfDay(), true)),
                'urgency' => 'high',
            ],
        );

        foreach ($rapat as $item) {
            $payload = json_encode([
                'title' => 'Rapat Harmonisasi Hari Ini',
                'body' => $item->jamTampil().' WITA — '.$item->jenis_rancangan.': '.$item->tentang,
                'tag' => 'jadwal-'.$item->id,
                'tanggal' => $hariIni,
                'url' => '/jadwal',
            ], JSON_UNESCAPED_UNICODE);

            foreach ($langganan as $sub) {
                $webPush->queueNotification($sub->untukWebPush(), $payload, ['topic' => 'jadwal-'.$item->id]);
            }
        }

        foreach ($webPush->flush() as $report) {
            if ($report->isSuccess()) {
                $hasil['terkirim']++;

                continue;
            }

            if ($report->isSubscriptionExpired()) {
                // Perangkat mencabut izin / uninstall — hapus agar tidak dicoba lagi
                PushSubscription::where('endpoint_hash', PushSubscription::hashEndpoint($report->getEndpoint()))->delete();
                $hasil['kedaluwarsa']++;

                continue;
            }

            $hasil['gagal']++;
            Log::warning('Web Push jadwal gagal: '.$report->getReason());
        }

        // Semua pengiriman gagal (mis. jaringan server terputus): batalkan penanda agar dicoba lagi menit berikutnya
        if ($hasil['terkirim'] === 0 && $hasil['gagal'] > 0) {
            JadwalRapat::whereIn('id', $rapat->pluck('id'))->toBase()
                ->update(['notifikasi_terkirim_tanggal' => null]);
            $hasil['status'] = 'gagal, dicoba lagi';
        }

        return $hasil;
    }
}
