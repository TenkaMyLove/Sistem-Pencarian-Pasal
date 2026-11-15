<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\JadwalRapat;
use App\Models\Pasal;
use App\Models\Pengguna;
use App\Models\Peraturan;
use App\Services\RecrawlService;
use App\Services\SearchService;
use App\Services\UrlCrawler;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Throwable;

/**
 * REST API untuk aplikasi mobile (Flutter). Semua respon berbentuk JSON:
 *   sukses: {"success": true, "data": ...}
 *   gagal : {"success": false, "message": "..."}
 *
 * Bentuk respon sengaja dibuat SAMA PERSIS dengan versi Node.js lama,
 * sehingga aplikasi mobile tidak perlu diubah.
 */
class ApiController extends Controller
{
    public function __construct(private SearchService $search)
    {
    }

    private function gagal(Throwable $e, string $default, int $status = 500): JsonResponse
    {
        return response()->json(['success' => false, 'message' => $e->getMessage() ?: $default], $status);
    }

    private function pesan(string $message, int $status): JsonResponse
    {
        return response()->json(['success' => false, 'message' => $message], $status);
    }

    // ------------------------------------------------------------------
    // 1. Health check
    // ------------------------------------------------------------------
    public function health(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'status' => 'ok',
            'app' => 'P3H Kemenkum Kalsel Mobile API',
            'timestamp' => now()->utc()->format('Y-m-d\TH:i:s.v\Z'),
        ]);
    }

    // ------------------------------------------------------------------
    // 2. Login
    // ------------------------------------------------------------------
    public function login(Request $request): JsonResponse
    {
        try {
            $username = trim((string) $request->input('username'));
            $kataSandi = trim((string) $request->input('kata_sandi'));

            if ($username === '' || $kataSandi === '') {
                return $this->pesan('Username dan kata sandi wajib diisi', 400);
            }

            $pengguna = Pengguna::whereRaw('LOWER(username) = ?', [strtolower($username)])->first();

            if (! $pengguna || ! $pengguna->cekKataSandi($kataSandi)) {
                return $this->pesan('Username atau kata sandi salah', 401);
            }

            return response()->json([
                'success' => true,
                'message' => 'Login berhasil',
                'user' => ['id' => $pengguna->id, 'username' => $pengguna->username, 'peran' => $pengguna->peran],
            ]);
        } catch (Throwable $e) {
            return $this->gagal($e, 'Internal server error');
        }
    }

    // ------------------------------------------------------------------
    // 3. Pencarian
    // ------------------------------------------------------------------
    public function cari(Request $request): JsonResponse
    {
        try {
            $pageSize = min(50, max(1, (int) $request->query('pageSize', 10) ?: 10));
            $hasil = $this->search->cari(
                (string) $request->query('q', ''),
                (string) $request->query('sektor', ''),
                (string) $request->query('wilayah', ''),
                max(1, (int) $request->query('page', 1)),
                $pageSize
            );

            // Kolom JSON kosong harus tampil sebagai {} (bukan [])
            foreach ($hasil['items'] as $item) {
                $item->status_detail_json = $item->status_detail_json ?: new \stdClass();
            }

            return response()->json([
                'success' => true,
                'data' => $hasil + ['filters' => $this->search->daftarFilter()],
            ]);
        } catch (Throwable $e) {
            return $this->gagal($e, 'Gagal memuat hasil pencarian');
        }
    }

    // ------------------------------------------------------------------
    // 4. Peraturan & pasal
    // ------------------------------------------------------------------
    public function detailPeraturan(string $id): JsonResponse
    {
        try {
            $peraturan = Peraturan::find($id);
            if (! $peraturan) {
                return $this->pesan('Peraturan tidak ditemukan', 404);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'peraturan' => $peraturan->toApiArray(),
                    'pasalList' => $peraturan->pasal()->orderBy('id')->get(),
                ],
            ]);
        } catch (Throwable $e) {
            return $this->gagal($e, 'Gagal memuat data peraturan');
        }
    }

    public function updatePeraturan(Request $request, string $id): JsonResponse
    {
        try {
            if (! ctype_digit($id) || (int) $id === 0) {
                return $this->pesan('ID peraturan tidak valid', 400);
            }

            $peraturan = Peraturan::find($id);
            if (! $peraturan) {
                return $this->pesan('Peraturan tidak ditemukan', 404);
            }

            $data = [
                'jenis_peraturan' => trim((string) $request->input('jenis_peraturan')),
                'nomor' => trim((string) $request->input('nomor')),
                'tahun' => (int) $request->input('tahun'),
                'judul' => trim((string) $request->input('judul')),
                'status' => trim((string) $request->input('status', 'berlaku')) ?: 'berlaku',
                'status_detail' => trim((string) $request->input('status_detail')),
                'wilayah' => trim((string) $request->input('wilayah', 'Nasional')) ?: 'Nasional',
                'sektor' => trim((string) $request->input('sektor', 'Lainnya')) ?: 'Lainnya',
                'url_dokumen_asli' => trim((string) $request->input('url_dokumen_asli')),
            ];

            if ($data['jenis_peraturan'] === '' || $data['nomor'] === '' || $data['tahun'] < 1900
                || $data['judul'] === '' || $data['url_dokumen_asli'] === '') {
                return $this->pesan('Jenis, nomor, tahun, judul, dan URL dokumen wajib diisi dengan benar', 400);
            }

            $peraturan->update($data);

            return response()->json(['success' => true, 'message' => 'Peraturan berhasil diperbarui']);
        } catch (Throwable $e) {
            return $this->gagal($e, 'Gagal memperbarui peraturan');
        }
    }

    public function hapusPeraturan(string $id): JsonResponse
    {
        try {
            if (! ctype_digit($id) || (int) $id === 0) {
                return $this->pesan('ID peraturan tidak valid', 400);
            }

            $peraturan = Peraturan::find($id);
            if (! $peraturan) {
                return $this->pesan('Peraturan tidak ditemukan', 404);
            }

            $peraturan->delete(); // pasal ikut terhapus (ON DELETE CASCADE)

            return response()->json(['success' => true, 'message' => 'Peraturan dan seluruh pasalnya berhasil dihapus']);
        } catch (Throwable $e) {
            return $this->gagal($e, 'Gagal menghapus peraturan');
        }
    }

    public function updatePasal(Request $request, string $id): JsonResponse
    {
        try {
            if (! ctype_digit($id) || (int) $id === 0) {
                return $this->pesan('ID pasal tidak valid', 400);
            }

            $pasal = Pasal::find($id);
            if (! $pasal) {
                return $this->pesan('Pasal tidak ditemukan', 404);
            }

            $data = [
                'nomor_pasal' => trim((string) $request->input('nomor_pasal')),
                'nomor_ayat' => trim((string) $request->input('nomor_ayat')),
                'teks_pasal' => trim((string) $request->input('teks_pasal')),
            ];

            if ($data['nomor_pasal'] === '' || $data['teks_pasal'] === '') {
                return $this->pesan('Nomor pasal dan teks pasal wajib diisi', 400);
            }

            $pasal->update($data);

            return response()->json(['success' => true, 'message' => 'Pasal berhasil diperbarui']);
        } catch (Throwable $e) {
            return $this->gagal($e, 'Gagal memperbarui pasal');
        }
    }

    public function hapusPasal(string $id): JsonResponse
    {
        try {
            if (! ctype_digit($id) || (int) $id === 0) {
                return $this->pesan('ID pasal tidak valid', 400);
            }

            $pasal = Pasal::find($id);
            if (! $pasal) {
                return $this->pesan('Pasal tidak ditemukan', 404);
            }

            $pasal->delete();

            return response()->json(['success' => true, 'message' => 'Pasal berhasil dihapus']);
        } catch (Throwable $e) {
            return $this->gagal($e, 'Gagal menghapus pasal');
        }
    }

    // ------------------------------------------------------------------
    // 5. Jadwal rapat harmonisasi
    // ------------------------------------------------------------------
    public function daftarJadwal(): JsonResponse
    {
        try {
            $items = JadwalRapat::orderBy('tanggal')->orderBy('jam')->get()
                ->makeHidden(['created_at', 'updated_at']);

            return response()->json(['success' => true, 'data' => $items]);
        } catch (Throwable $e) {
            return $this->gagal($e, 'Gagal memuat jadwal');
        }
    }

    public function tambahJadwal(Request $request): JsonResponse
    {
        try {
            if (! $request->filled(['jenis_rancangan', 'tentang', 'tanggal', 'jam'])) {
                return $this->pesan('Kolom jenis, tentang, tanggal, dan jam wajib diisi', 400);
            }

            $jadwal = JadwalRapat::create([
                'jenis_rancangan' => $request->input('jenis_rancangan'),
                'tentang' => $request->input('tentang'),
                'tanggal' => $request->input('tanggal'),
                'jam' => $request->input('jam'),
                'nama_kompilator' => (string) $request->input('nama_kompilator', ''),
                'tim_pokja' => (string) $request->input('tim_pokja', ''),
                'dibuat_oleh' => $request->input('dibuat_oleh') ?: 'Pengguna',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Jadwal berhasil ditambahkan',
                'insertedId' => $jadwal->id,
            ], 201);
        } catch (Throwable $e) {
            return $this->gagal($e, 'Gagal menambahkan jadwal');
        }
    }

    public function ubahJadwal(Request $request, string $id): JsonResponse
    {
        try {
            JadwalRapat::where('id', (int) $id)->update($request->only([
                'jenis_rancangan', 'tentang', 'tanggal', 'jam', 'nama_kompilator', 'tim_pokja',
            ]) + ['updated_at' => now()]);

            return response()->json(['success' => true, 'message' => 'Jadwal berhasil diperbarui']);
        } catch (Throwable $e) {
            return $this->gagal($e, 'Gagal memperbarui jadwal');
        }
    }

    public function hapusJadwal(string $id): JsonResponse
    {
        try {
            JadwalRapat::where('id', (int) $id)->delete();

            return response()->json(['success' => true, 'message' => 'Jadwal berhasil dihapus']);
        } catch (Throwable $e) {
            return $this->gagal($e, 'Gagal menghapus jadwal');
        }
    }

    // ------------------------------------------------------------------
    // 6. Manajemen pengguna (Admin)
    // ------------------------------------------------------------------
    public function daftarPengguna(): JsonResponse
    {
        try {
            $users = Pengguna::orderBy('id')
                ->get(['id', 'username', 'peran', 'diubah_terakhir_oleh', 'tanggal_kata_sandi_diubah']);

            return response()->json(['success' => true, 'data' => $users]);
        } catch (Throwable $e) {
            return $this->gagal($e, 'Gagal memuat pengguna');
        }
    }

    public function resetKataSandi(Request $request): JsonResponse
    {
        try {
            $target = $request->input('target_username');
            $baru = (string) $request->input('kata_sandi_baru');

            if (! $target || $baru === '') {
                return $this->pesan('Target username dan kata sandi baru wajib diisi', 400);
            }

            if (mb_strlen($baru) < 6) {
                return $this->pesan('Kata sandi minimal 6 karakter', 400);
            }

            Pengguna::where('username', $target)->update([
                'kata_sandi_terenkripsi' => Hash::make($baru),
                'diubah_terakhir_oleh' => $request->input('admin_username') ?: 'Admin',
                'tanggal_kata_sandi_diubah' => now(),
            ]);

            return response()->json(['success' => true, 'message' => "Kata sandi akun {$target} berhasil diperbarui"]);
        } catch (Throwable $e) {
            return $this->gagal($e, 'Gagal mereset kata sandi');
        }
    }

    // ------------------------------------------------------------------
    // 7. Tambah peraturan (crawler)
    // ------------------------------------------------------------------
    public function tambahPeraturan(Request $request, UrlCrawler $crawler): JsonResponse
    {
        try {
            if (! $request->filled(['url', 'jenis_peraturan', 'nomor', 'tahun'])) {
                return $this->pesan('URL, Jenis Peraturan, Nomor, dan Tahun wajib diisi', 400);
            }

            $result = $crawler->crawl([
                'url' => $request->input('url'),
                'jenis_peraturan' => $request->input('jenis_peraturan'),
                'nomor' => $request->input('nomor'),
                'tahun' => (int) $request->input('tahun'),
                'judul' => (string) $request->input('judul', ''),
                'wilayah' => $request->input('wilayah') ?: 'Nasional',
                'sektor' => $request->input('sektor') ?: 'Lainnya',
                'teks_manual' => (string) $request->input('teks_manual', ''),
            ]);

            return response()->json(['success' => true, 'data' => $result]);
        } catch (Throwable $e) {
            return $this->gagal($e, 'Gagal memproses crawling peraturan');
        }
    }

    // ------------------------------------------------------------------
    // 8. Pemicu cron (cPanel): pemeriksaan tautan berkala
    // ------------------------------------------------------------------
    public function cronRecrawl(RecrawlService $recrawl): JsonResponse
    {
        return response()->json([
            'message' => 'cPanel Cron Job execution completed',
            'result' => $recrawl->jalankan(),
        ]);
    }
}
