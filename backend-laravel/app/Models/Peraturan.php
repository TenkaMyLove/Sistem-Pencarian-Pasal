<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Model = representasi satu tabel database sebagai class PHP.
 * Class ini mewakili tabel `peraturan` (satu baris = satu peraturan).
 */
class Peraturan extends Model
{
    protected $table = 'peraturan';

    // Tabel ini tidak punya kolom created_at / updated_at
    public $timestamps = false;

    protected $fillable = [
        'jenis_peraturan', 'nomor', 'tahun', 'judul', 'status',
        'status_detail', 'status_detail_json', 'wilayah', 'sektor',
        'url_dokumen_asli', 'status_tautan', 'tanggal_diambil', 'tanggal_dicek_terakhir',
    ];

    // Kolom JSON otomatis diubah menjadi array PHP
    protected $casts = [
        'status_detail_json' => 'array',
    ];

    /** Satu peraturan punya banyak pasal. */
    public function pasal(): HasMany
    {
        return $this->hasMany(Pasal::class, 'peraturan_id');
    }

    /**
     * Bentuk array untuk respon API. Kolom JSON kosong harus tampil sebagai
     * objek `{}` (bukan `[]`) agar sama dengan perilaku API versi Node.js.
     */
    public function toApiArray(): array
    {
        $data = $this->attributesToArray();
        $data['status_detail_json'] = $this->status_detail_json ?: new \stdClass();

        return $data;
    }
}
