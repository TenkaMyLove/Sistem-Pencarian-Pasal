<?php

namespace App\Http\Controllers;

use App\Models\Pasal;
use App\Models\Peraturan;
use App\Services\SearchService;
use App\Services\UrlCrawler;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Contracts\View\View;

/**
 * Halaman Pencarian Pasal + semua modal (popup) HTMX-nya.
 *
 * HTMX: browser meminta potongan HTML (bukan satu halaman penuh) lalu
 * memasangnya ke bagian halaman yang tepat — itulah kenapa banyak method di sini
 * mengembalikan view "partial" (results, status-modal, edit-*-modal).
 */
class SearchController extends Controller
{
    public function __construct(private SearchService $search)
    {
    }

    /** GET /pencarian — halaman utama pencarian. */
    public function index(Request $request): View
    {
        $q = (string) $request->query('q', '');
        $searchData = $this->search->cari(
            $q,
            (string) $request->query('sektor', ''),
            (string) $request->query('wilayah', ''),
            (int) $request->query('page', 1),
            config('p3h.per_halaman')
        );

        return view('search.index', [
            'initialQuery' => $q,
            'searchData' => $searchData,
        ] + $this->search->daftarFilter());
    }

    /** GET /search-results — potongan HTML hasil pencarian (dipanggil HTMX). */
    public function results(Request $request): View
    {
        $q = (string) $request->query('q', '');
        $sektor = (string) $request->query('sektor', '');
        $wilayah = (string) $request->query('wilayah', '');
        $page = (int) ($request->query('page') ?? $request->query('active_page') ?? 1);

        return view('search.results', [
            'query' => $q,
            'sektor' => $sektor,
            'wilayah' => $wilayah,
            'searchData' => $this->search->cari($q, $sektor, $wilayah, $page, config('p3h.per_halaman')),
        ]);
    }

    /** GET /pencarian/status-modal/{id} — popup detail status peraturan. */
    public function statusModal(int $id, UrlCrawler $crawler): View
    {
        $peraturan = $crawler->lengkapiPeraturanJikaPerlu(Peraturan::findOrFail($id));

        return view('search.status-modal', ['peraturan' => $peraturan]);
    }

    // ---------------- Peraturan (khusus Pengelola) ----------------

    public function editPeraturanModal(int $id, UrlCrawler $crawler): View
    {
        $peraturan = $crawler->lengkapiPeraturanJikaPerlu(Peraturan::findOrFail($id));

        return view('search.edit-peraturan-modal', ['peraturan' => $peraturan, 'error' => null]);
    }

    public function updatePeraturan(Request $request, int $id, UrlCrawler $crawler): View|Response
    {
        $peraturan = Peraturan::findOrFail($id);

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
            // Tampilkan ulang modal dengan isian pengguna + pesan error
            return view('search.edit-peraturan-modal', [
                'peraturan' => (object) (['id' => $id] + $data),
                'error' => 'Jenis, nomor, tahun, judul, dan URL dokumen wajib diisi dengan benar.',
            ]);
        }

        // Jika pengguna menempel teks relasi BPK ("Dicabut dengan : ...") ke Keterangan Status, urai menjadi JSON terstruktur
        if ($data['status_detail'] !== '') {
            $parsedStatus = $crawler->ekstrakStatusDariTeks($data['status_detail']);
            if ($parsedStatus !== null) {
                $data['status_detail_json'] = $parsedStatus['json'];
                $data['status_detail'] = $parsedStatus['ringkasan'];
                $data['status'] = $crawler->tentukanStatus(null, $parsedStatus['json']);
            }
        }

        $peraturan->update($data);
        $crawler->lengkapiPeraturanJikaPerlu($peraturan);

        // Isi kosong + header HX-Trigger: memberi tahu halaman agar memuat ulang hasil pencarian
        return response('', 200)->header('HX-Trigger', 'refreshResults');
    }

    public function destroyPeraturan(int $id): Response
    {
        // ON DELETE CASCADE pada tabel pasal ikut menghapus seluruh pasalnya
        Peraturan::findOrFail($id)->delete();

        return response('', 200)->header('HX-Trigger', 'refreshResults');
    }

    // ---------------- Pasal (khusus Pengelola) ----------------

    public function editPasalModal(int $id): View
    {
        return view('search.edit-pasal-modal', ['pasal' => Pasal::findOrFail($id), 'error' => null]);
    }

    public function updatePasal(Request $request, int $id): View|Response
    {
        $pasal = Pasal::findOrFail($id);

        $data = [
            'nomor_pasal' => trim((string) $request->input('nomor_pasal')),
            'nomor_ayat' => trim((string) $request->input('nomor_ayat')),
            'teks_pasal' => trim((string) $request->input('teks_pasal')),
        ];

        if ($data['nomor_pasal'] === '' || $data['teks_pasal'] === '') {
            return view('search.edit-pasal-modal', [
                'pasal' => (object) (['id' => $id, 'peraturan_id' => $pasal->peraturan_id] + $data),
                'error' => 'Nomor pasal dan teks pasal tidak boleh kosong.',
            ]);
        }

        $pasal->update($data);

        return response('', 200)->header('HX-Trigger', 'refreshResults');
    }

    public function destroyPasal(int $id): Response
    {
        Pasal::findOrFail($id)->delete();

        return response('', 200)->header('HX-Trigger', 'refreshResults');
    }
}
