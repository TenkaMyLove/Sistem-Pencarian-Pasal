<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Model;

/** Tabel `jadwal_rapat_harmonisasi` — agenda rapat harmonisasi Ranperda/Ranpergub. */
class JadwalRapat extends Model
{
    protected $table = 'jadwal_rapat_harmonisasi';

    protected $fillable = [
        'jenis_rancangan', 'tentang', 'tanggal', 'jam',
        'nama_kompilator', 'tim_pokja', 'dibuat_oleh',
    ];

    // `tanggal` jadi objek Carbon (mudah diformat), dan tampil "Y-m-d" di JSON
    protected $casts = [
        'tanggal' => 'date:Y-m-d',
    ];

    /**
     * Rapat hari ini (WITA) yang jamnya belum lewat — dipakai untuk notifikasi web & mobile.
     * Rapat dengan format jam yang tidak dikenali tetap ditampilkan sepanjang hari.
     */
    public static function aktifHariIni(): Collection
    {
        $now = now('Asia/Makassar');
        $jamSekarang = $now->format('H:i:s');

        return static::whereDate('tanggal', $now->toDateString())
            ->orderBy('jam')
            ->get()
            ->filter(function (self $item) use ($jamSekarang) {
                $jam = self::normalisasiJam($item->jam);

                return $jam === null || $jam >= $jamSekarang;
            })
            ->values();
    }

    /** "9.30 WITA" / "09:30" / "09:30:00" -> "09:30:00"; null bila format tidak dikenali. */
    public static function normalisasiJam(?string $jam): ?string
    {
        if (! preg_match('/(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?/', (string) $jam, $m)) {
            return null;
        }

        return sprintf('%02d:%02d:%02d', $m[1], $m[2], $m[3] ?? 0);
    }
}
