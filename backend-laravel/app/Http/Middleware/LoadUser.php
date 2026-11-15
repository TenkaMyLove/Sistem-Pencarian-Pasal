<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\View;
use Symfony\Component\HttpFoundation\Response;

/**
 * Berjalan di SETIAP halaman web.
 * Tugasnya: mengambil data pengguna dari session. Jika belum login,
 * dianggap "Tamu". Hasilnya dibagikan ke semua view sebagai variabel $user.
 *
 * $user berbentuk array: ['id' => 1, 'username' => 'Admin', 'peran' => 'Admin']
 */
class LoadUser
{
    public const TAMU = ['id' => 0, 'username' => 'Tamu / Publik', 'peran' => 'Tamu'];

    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->session()->get('user', self::TAMU);

        // Dibaca oleh controller lewat $request->attributes->get('user')
        $request->attributes->set('user', $user);

        // Tersedia di semua file Blade sebagai $user
        View::share('user', $user);

        return $next($request);
    }
}
