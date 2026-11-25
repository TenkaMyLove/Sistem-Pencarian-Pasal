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
        'notifikasi_terkirim_tanggal' => 'date:Y-m-d',
    ];

    // Kolom internal penanda Web Push — tidak perlu tampil di JSON
    protected $hidden = ['notifikasi_terkirim_tanggal'];

    /** "9.30 WITA" / "09:30:00" -> "09:30" untuk ditampilkan di notifikasi. */
    public function jamTampil(): string
    {
        return preg_match('/(\d{1,2})[:.](\d{2})/', (string) $this->jam, $m)
            ? sprintf('%02d:%s', $m[1], $m[2])
            : (string) $this->jam;
    }

    /**
     * Semua rapat hari ini (WITA) — dipakai untuk notifikasi web & mobile.
     * Rapat tetap ditampilkan sepanjang hari dan baru hilang ketika tanggal berganti.
     */
    public static function aktifHariIni(): Collection
    {
        return static::whereDate('tanggal', now('Asia/Makassar')->toDateString())
            ->orderBy('jam')
            ->get();
    }
}
