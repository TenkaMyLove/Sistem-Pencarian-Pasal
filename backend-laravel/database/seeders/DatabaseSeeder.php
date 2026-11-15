<?php

namespace Database\Seeders;

use App\Models\Pengguna;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Seeder = mengisi data awal. Jalankan: php artisan db:seed
 * Hanya membuat akun yang BELUM ada, jadi aman dijalankan di database lama.
 *
 * PENTING: kata sandi di bawah hanya untuk demo/pengembangan — segera ganti
 * lewat menu Kelola Akun sebelum aplikasi dipakai sungguhan.
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $akun = [
            ['username' => 'Admin',     'peran' => 'Admin',     'kata_sandi' => 'admin123'],
            ['username' => 'Pengelola', 'peran' => 'Pengelola', 'kata_sandi' => 'pengelola123'],
            ['username' => 'Perancang', 'peran' => 'Perancang', 'kata_sandi' => 'perancang123'],
        ];

        foreach ($akun as $a) {
            Pengguna::firstOrCreate(
                ['username' => $a['username']],
                [
                    'peran' => $a['peran'],
                    'kata_sandi_terenkripsi' => Hash::make($a['kata_sandi']),
                    'diubah_terakhir_oleh' => 'System',
                    'tanggal_kata_sandi_diubah' => now(),
                ]
            );
        }
    }
}
