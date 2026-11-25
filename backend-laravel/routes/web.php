<?php

use App\Http\Controllers\AdminController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\JadwalController;
use App\Http\Controllers\SearchController;
use App\Http\Controllers\TambahPeraturanController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Rute halaman web
|--------------------------------------------------------------------------
| Baca dari atas ke bawah: URL -> Controller@method yang menanganinya.
| middleware('role:...') = pembatas hak akses (lihat app/Http/Middleware/CheckRole.php)
*/

Route::redirect('/', '/pencarian');

// --- Login / logout (terbuka untuk semua) ---
Route::get('/login', [AuthController::class, 'showLogin']);
Route::post('/login', [AuthController::class, 'login']);
Route::get('/tamu', [AuthController::class, 'tamu']);
Route::get('/logout', [AuthController::class, 'logout']);

// --- Pencarian pasal (terbuka untuk semua, termasuk Tamu) ---
Route::get('/pencarian', [SearchController::class, 'index']);
Route::get('/search-results', [SearchController::class, 'results']);
Route::get('/pencarian/status-modal/{id}', [SearchController::class, 'statusModal']);

// --- Hanya Pengelola: ubah data, tambah peraturan, dan kelola akun ---
Route::middleware('role:pengelola')->group(function () {
    Route::get('/pencarian/edit-peraturan-modal/{id}', [SearchController::class, 'editPeraturanModal']);
    Route::post('/pencarian/edit-peraturan/{id}', [SearchController::class, 'updatePeraturan']);
    Route::post('/pencarian/hapus-peraturan/{id}', [SearchController::class, 'destroyPeraturan']);
    Route::get('/pencarian/edit-pasal-modal/{id}', [SearchController::class, 'editPasalModal']);
    Route::post('/pencarian/edit-pasal/{id}', [SearchController::class, 'updatePasal']);
    Route::post('/pencarian/hapus-pasal/{id}', [SearchController::class, 'destroyPasal']);

    Route::get('/tambah-peraturan', [TambahPeraturanController::class, 'form']);
    Route::post('/tambah-peraturan', [TambahPeraturanController::class, 'simpan']);

    Route::get('/kelola-akun', [AdminController::class, 'index']);
    Route::post('/kelola-akun', [AdminController::class, 'resetKataSandi']);
});

// --- Pegawai (Pengelola & Perancang): jadwal rapat harmonisasi ---
Route::middleware('role:staff')->group(function () {
    Route::get('/jadwal', [JadwalController::class, 'index']);
    Route::get('/jadwal/notifikasi-hari-ini', [JadwalController::class, 'notifikasiHariIni']);
    Route::get('/jadwal/modal/tambah', [JadwalController::class, 'modalTambah']);
    Route::get('/jadwal/modal/edit/{id}', [JadwalController::class, 'modalEdit']);
    Route::post('/jadwal', [JadwalController::class, 'store']);
    Route::post('/jadwal/{id}/edit', [JadwalController::class, 'update']);
    Route::post('/jadwal/{id}/delete', [JadwalController::class, 'destroy']);
});
