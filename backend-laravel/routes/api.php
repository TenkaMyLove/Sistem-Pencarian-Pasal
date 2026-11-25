<?php

use App\Http\Controllers\Api\ApiController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Rute API (otomatis berawalan /api)
|--------------------------------------------------------------------------
| Dipakai aplikasi mobile Flutter. Respon berupa JSON.
*/

Route::get('/health', [ApiController::class, 'health']);
Route::post('/auth/login', [ApiController::class, 'login']);

Route::get('/search', [ApiController::class, 'cari']);

Route::get('/peraturan/{id}', [ApiController::class, 'detailPeraturan']);
Route::put('/peraturan/{id}', [ApiController::class, 'updatePeraturan']);
Route::delete('/peraturan/{id}', [ApiController::class, 'hapusPeraturan']);

Route::put('/pasal/{id}', [ApiController::class, 'updatePasal']);
Route::delete('/pasal/{id}', [ApiController::class, 'hapusPasal']);

Route::get('/jadwal', [ApiController::class, 'daftarJadwal']);
Route::get('/jadwal/hari-ini', [ApiController::class, 'jadwalHariIni']);
Route::post('/jadwal', [ApiController::class, 'tambahJadwal']);
Route::put('/jadwal/{id}', [ApiController::class, 'ubahJadwal']);
Route::delete('/jadwal/{id}', [ApiController::class, 'hapusJadwal']);

Route::get('/admin/users', [ApiController::class, 'daftarPengguna']);
Route::post('/admin/reset-password', [ApiController::class, 'resetKataSandi']);

Route::post('/tambah-peraturan', [ApiController::class, 'tambahPeraturan']);

// Dipanggil oleh cPanel Cron Job
Route::get('/cron/recrawl', [ApiController::class, 'cronRecrawl']);
