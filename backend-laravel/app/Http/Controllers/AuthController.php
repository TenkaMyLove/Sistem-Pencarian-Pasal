<?php

namespace App\Http\Controllers;

use App\Models\Pengguna;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Contracts\View\View;

/**
 * Login, logout, dan akses tamu.
 * Data login disimpan di session Laravel: session('user') = [id, username, peran].
 */
class AuthController extends Controller
{
    public function showLogin(Request $request): View|RedirectResponse
    {
        $user = $request->session()->get('user');

        // Sudah login sebagai pegawai -> langsung ke aplikasi
        if ($user && $user['peran'] !== 'Tamu') {
            return redirect($user['peran'] === 'Admin' ? '/kelola-akun' : '/pencarian');
        }

        return view('auth.login', ['error' => null]);
    }

    public function login(Request $request): View|RedirectResponse
    {
        $username = trim((string) $request->input('username'));
        $kataSandi = trim((string) $request->input('kata_sandi'));

        if ($username === '' || $kataSandi === '') {
            return response()->view('auth.login', ['error' => 'Username dan kata sandi wajib diisi'], 400);
        }

        // Cari tanpa membedakan huruf besar/kecil
        $pengguna = Pengguna::whereRaw('LOWER(username) = ?', [strtolower($username)])->first();

        if (! $pengguna || ! $pengguna->cekKataSandi($kataSandi)) {
            return response()->view('auth.login', ['error' => 'Username atau kata sandi salah'], 401);
        }

        // Ganti ID session setelah login (mencegah session fixation)
        $request->session()->regenerate();
        $request->session()->put('user', [
            'id' => $pengguna->id,
            'username' => $pengguna->username,
            'peran' => $pengguna->peran,
        ]);

        return redirect($pengguna->peran === 'Admin' ? '/kelola-akun' : '/pencarian');
    }

    /** Masuk sebagai Tamu (publik, hanya bisa mencari pasal). */
    public function tamu(Request $request): RedirectResponse
    {
        $request->session()->put('user', [
            'id' => 0,
            'username' => 'Tamu / Publik',
            'peran' => 'Tamu',
        ]);

        return redirect('/pencarian');
    }

    public function logout(Request $request): RedirectResponse
    {
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/login');
    }
}
