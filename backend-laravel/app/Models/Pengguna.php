<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/** Tabel `pengguna` — akun yang bisa login (Pengelola, Perancang). */
class Pengguna extends Model
{
    protected $table = 'pengguna';

    public $timestamps = false;

    protected $fillable = [
        'username', 'kata_sandi_terenkripsi', 'peran',
        'diubah_terakhir_oleh', 'tanggal_kata_sandi_diubah',
    ];

    // Jangan pernah ikut tampil saat model diubah jadi JSON
    protected $hidden = ['kata_sandi_terenkripsi'];

    protected $casts = [
        'tanggal_kata_sandi_diubah' => 'datetime',
    ];

    /**
     * Cek kata sandi. Memakai password_verify bawaan PHP karena hash lama dari
     * Node.js (bcryptjs) berformat $2b$, yang tetap kompatibel dengan PHP.
     */
    public function cekKataSandi(string $kataSandi): bool
    {
        return password_verify($kataSandi, $this->kata_sandi_terenkripsi);
    }
}
