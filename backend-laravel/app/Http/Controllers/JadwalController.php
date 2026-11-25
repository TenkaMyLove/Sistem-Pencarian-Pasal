<?php

namespace App\Http\Controllers;

use App\Models\JadwalRapat;
use Illuminate\Contracts\View\View;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

/**
 * Jadwal Rapat Harmonisasi.
 * Semua pegawai (staff) boleh melihat; hanya Pengelola & Perancang yang boleh mengubah.
 */
class JadwalController extends Controller
{
    private function bolehUbah(Request $request): bool
    {
        return in_array($request->attributes->get('user')['peran'], ['Pengelola', 'Perancang'], true);
    }

    private function ditolak(): Response
    {
        return response('<div class="alert alert-danger">Akses ditolak.</div>', 403);
    }

    private function daftar()
    {
        return JadwalRapat::orderBy('tanggal')->orderBy('jam')->get();
    }

    private function tabel(): View
    {
        return view('jadwal.table', ['jadwalList' => $this->daftar()]);
    }

    private function dataForm(Request $request): array
    {
        return [
            'jenis_rancangan' => (string) $request->input('jenis_rancangan'),
            'tentang' => (string) $request->input('tentang'),
            'tanggal' => (string) $request->input('tanggal'),
            'jam' => (string) $request->input('jam'),
            'nama_kompilator' => (string) $request->input('nama_kompilator'),
            'tim_pokja' => (string) $request->input('tim_pokja'),
        ];
    }

    /** GET /jadwal */
    public function index(): View
    {
        return view('jadwal.index', ['jadwalList' => $this->daftar()]);
    }

    /** GET /jadwal/notifikasi-hari-ini — semua rapat hari ini (JSON untuk notifikasi web/PWA) */
    public function notifikasiHariIni(): JsonResponse
    {
        $now = now('Asia/Makassar');

        return response()->json([
            'success' => true,
            'data' => JadwalRapat::aktifHariIni()->makeHidden(['created_at', 'updated_at']),
            'tanggal' => $now->toDateString(),
            'jam_server' => $now->format('H:i:s'),
        ]);
    }

    /** GET /jadwal/modal/tambah — popup form kosong */
    public function modalTambah(Request $request): View|Response
    {
        if (! $this->bolehUbah($request)) {
            return $this->ditolak();
        }

        return view('jadwal.modal', ['editItem' => null]);
    }

    /** GET /jadwal/modal/edit/{id} — popup form berisi data lama */
    public function modalEdit(Request $request, int $id): View|Response
    {
        if (! $this->bolehUbah($request)) {
            return $this->ditolak();
        }

        $item = JadwalRapat::find($id);
        if (! $item) {
            return response('<div class="alert alert-danger">Jadwal tidak ditemukan</div>', 404);
        }

        return view('jadwal.modal', ['editItem' => $item]);
    }

    /** POST /jadwal */
    public function store(Request $request): View|Response
    {
        if (! $this->bolehUbah($request)) {
            return $this->ditolak();
        }

        JadwalRapat::create($this->dataForm($request) + [
            'dibuat_oleh' => $request->attributes->get('user')['username'],
        ]);

        return $this->tabel();
    }

    /** POST /jadwal/{id}/edit */
    public function update(Request $request, int $id): View|Response
    {
        if (! $this->bolehUbah($request)) {
            return $this->ditolak();
        }

        JadwalRapat::where('id', $id)->update($this->dataForm($request) + ['updated_at' => now()]);

        return $this->tabel();
    }

    /** POST /jadwal/{id}/delete */
    public function destroy(Request $request, int $id): View|Response
    {
        if (! $this->bolehUbah($request)) {
            return $this->ditolak();
        }

        JadwalRapat::where('id', $id)->delete();

        return $this->tabel();
    }
}
