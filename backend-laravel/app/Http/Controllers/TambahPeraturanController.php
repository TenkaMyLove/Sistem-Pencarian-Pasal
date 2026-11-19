<?php

namespace App\Http\Controllers;

use App\Services\UrlCrawler;
use Illuminate\Contracts\View\View;
use Illuminate\Http\Request;
use Throwable;

/** Tambah Peraturan via URL (Khusus Pengelola). */
class TambahPeraturanController extends Controller
{
    public function __construct(private UrlCrawler $crawler)
    {
    }

    /** GET /tambah-peraturan */
    public function form(): View
    {
        return view('peraturan.tambah', ['result' => null, 'formValues' => [], 'error' => null]);
    }

    /** POST /tambah-peraturan */
    public function simpan(Request $request)
    {
        // Beri waktu cukup saat mengunduh & mengekstrak PDF peraturan dari portal JDIH/BPK
        @set_time_limit(90);

        $url = trim((string) $request->input('url'));
        $jenis = trim((string) $request->input('jenis_peraturan'));
        $nomor = trim((string) $request->input('nomor'));
        $tahun = (int) $request->input('tahun');
        $judul = trim((string) $request->input('judul'));
        $wilayah = trim((string) $request->input('wilayah', 'Nasional')) ?: 'Nasional';
        $sektor = trim((string) $request->input('sektor', 'Lainnya')) ?: 'Lainnya';
        $teksManual = trim((string) $request->input('teks_pasal_manual'));

        // Isian yang dikembalikan ke form bila ada masalah
        $formValues = [
            'url' => $url, 'jenis_peraturan' => $jenis, 'nomor' => $nomor, 'tahun' => (string) $tahun,
            'judul' => $judul, 'wilayah' => $wilayah, 'sektor' => $sektor, 'teks_pasal_manual' => $teksManual,
        ];

        if ($url === '') {
            return response()->view('peraturan.tambah', ['result' => null, 'formValues' => $formValues, 'error' => 'URL peraturan wajib diisi.'], 400);
        }

        if ($jenis === '' || $nomor === '' || $tahun < 1900) {
            return response()->view('peraturan.tambah', ['result' => null, 'formValues' => $formValues, 'error' => 'Jenis peraturan, nomor, dan tahun wajib diisi dengan benar.'], 400);
        }

        try {
            $result = $this->crawler->crawl([
                'url' => $url,
                'jenis_peraturan' => $jenis,
                'nomor' => $nomor,
                'tahun' => $tahun,
                'judul' => $judul,
                'wilayah' => $wilayah,
                'sektor' => $sektor,
                'teks_manual' => $teksManual,
            ]);
        } catch (Throwable $e) {
            return response()->view('peraturan.tambah', [
                'result' => null,
                'formValues' => $formValues,
                'error' => 'Terjadi kesalahan saat crawling: '.$e->getMessage(),
            ], 500);
        }

        // Kosongkan url & nomor agar siap menambah peraturan berikutnya
        return view('peraturan.tambah', [
            'result' => $result,
            'formValues' => array_merge($formValues, ['url' => '', 'nomor' => '', 'teks_pasal_manual' => '']),
            'error' => null,
        ]);
    }
}
