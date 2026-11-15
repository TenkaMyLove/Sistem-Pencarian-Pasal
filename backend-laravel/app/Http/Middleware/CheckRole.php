<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Pembatas hak akses berdasarkan peran. Dipakai di routes/web.php:
 *
 *   ->middleware('role:staff')      Pengelola / Perancang / Admin (Tamu ditolak)
 *   ->middleware('role:pengelola')  Pengelola atau Admin
 *   ->middleware('role:admin')      Admin saja
 */
class CheckRole
{
    public function handle(Request $request, Closure $next, string $level): Response
    {
        // Hanya akun yang benar-benar login yang ada di session (Tamu tidak dihitung)
        $user = $request->session()->get('user');

        if ($level === 'staff') {
            if (! $user || $user['peran'] === 'Tamu') {
                return redirect('/pencarian');
            }

            return $next($request);
        }

        if (! $user) {
            return redirect('/login');
        }

        if ($level === 'admin' && $user['peran'] !== 'Admin') {
            return response('<h3>403 Akses Ditolak: Halaman ini hanya dapat diakses oleh Admin.</h3>', 403);
        }

        if ($level === 'pengelola' && ! in_array($user['peran'], ['Pengelola', 'Admin'], true)) {
            return response('<h3>403 Akses Ditolak: Hanya akun Pengelola yang memiliki hak akses untuk fitur ini.</h3>', 403);
        }

        return $next($request);
    }
}
