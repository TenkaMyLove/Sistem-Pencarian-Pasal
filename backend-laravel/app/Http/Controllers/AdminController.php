<?php

namespace App\Http\Controllers;

use App\Models\Pengguna;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

/** Kelola Akun (khusus Pengelola): reset kata sandi akun Pengelola / Perancang. */
class AdminController extends Controller
{
    private function tampil(int $status = 200, ?string $message = null, ?string $error = null)
    {
        return response()->view('admin.akun', [
            'userAccounts' => Pengguna::where('peran', '!=', 'Admin')->orderBy('id')->get(),
            'message' => $message,
            'error' => $error,
        ], $status);
    }

    /** GET /kelola-akun */
    public function index()
    {
        return $this->tampil();
    }

    /** POST /kelola-akun */
    public function resetKataSandi(Request $request)
    {
        $target = trim((string) $request->input('target_username'));
        $baru = trim((string) $request->input('kata_sandi_baru'));
        $konfirmasi = trim((string) $request->input('konfirmasi_kata_sandi'));

        if ($target === '' || $baru === '' || $konfirmasi === '') {
            return $this->tampil(400, error: 'Seluruh kolom formulir wajib diisi.');
        }

        if (! in_array($target, config('p3h.akun_operasional'), true)) {
            return $this->tampil(400, error: 'Hanya kata sandi akun Pengelola atau Perancang yang dapat diubah.');
        }

        if (mb_strlen($baru) < 6) {
            return $this->tampil(400, error: 'Kata sandi baru minimal harus 6 karakter.');
        }

        if ($baru !== $konfirmasi) {
            return $this->tampil(400, error: 'Konfirmasi kata sandi baru tidak cocok.');
        }

        $pengubah = $request->session()->get('user.username', 'Pengelola');

        Pengguna::where('username', $target)->update([
            'kata_sandi_terenkripsi' => Hash::make($baru),
            'diubah_terakhir_oleh' => $pengubah,
            'tanggal_kata_sandi_diubah' => now(),
        ]);

        return $this->tampil(message: "Kata sandi akun {$target} berhasil diperbarui! Pengguna akun tersebut kini dapat login dengan kata sandi baru.");
    }
}
