<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Tabel `pasal` — satu baris = satu pasal milik sebuah peraturan. */
class Pasal extends Model
{
    protected $table = 'pasal';

    public $timestamps = false;

    protected $fillable = ['peraturan_id', 'nomor_pasal', 'nomor_ayat', 'teks_pasal'];

    public function peraturan(): BelongsTo
    {
        return $this->belongsTo(Peraturan::class, 'peraturan_id');
    }
}
