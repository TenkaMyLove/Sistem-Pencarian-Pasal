<?php

namespace App\Services;

use App\Models\Peraturan;
use Illuminate\Support\Facades\DB;
use Throwable;

/**
 * Logika pencarian pasal. Dipakai bersama oleh halaman web (SearchController)
 * dan API mobile (Api\ApiController) — di versi Node.js kode ini ditulis dua kali.
 *
 * Hasil pencarian = gabungan (UNION) dua query:
 *  Q1: peraturan YANG PUNYA pasal  -> dicari pada isi pasal, judul, jenis, nomor
 *  Q2: peraturan TANPA pasal       -> dicari pada judul, jenis, nomor
 *      (agar peraturan baru yang pasalnya belum terambil tetap muncul)
 */
class SearchService
{
    private const SELECT_FIELDS = "
        pas.id AS pasal_id,
        COALESCE(pas.nomor_pasal, '—') AS nomor_pasal,
        COALESCE(pas.nomor_ayat, '') AS nomor_ayat,
        COALESCE(pas.teks_pasal, '(Belum ada teks pasal — peraturan berhasil diindeks tetapi isi pasal belum berhasil diekstrak. Kunjungi dokumen asli untuk membaca isinya.)') AS teks_pasal,
        per.id AS peraturan_id,
        per.jenis_peraturan,
        per.nomor,
        per.tahun,
        per.judul,
        per.status,
        per.status_detail,
        per.status_detail_json,
        per.wilayah,
        per.sektor,
        per.url_dokumen_asli,
        per.status_tautan";

    /**
     * @return array{items: array, totalCount: int, currentPage: int, pageSize: int, totalPages: int}
     */
    public function cari(string $q = '', string $sektor = '', string $wilayah = '', int $page = 1, int $pageSize = 5): array
    {
        // Lengkapi otomatis peraturan yang belum memiliki relasi JSON / judul lengkap akibat blokir jaringan cloud
        try {
            $perluDilengkapi = Peraturan::where('judul', 'like', 'http%')
                ->orWhereNull('status_detail_json')
                ->orWhere('status_detail_json', '[]')
                ->orWhere('status_detail_json', '{}')
                ->limit(10)
                ->get();

            if ($perluDilengkapi->isNotEmpty()) {
                $crawler = app(UrlCrawler::class);
                foreach ($perluDilengkapi as $per) {
                    $crawler->lengkapiPeraturanJikaPerlu($per);
                }
            }
        } catch (Throwable) {
        }

        $q = trim($q);
        $sektor = trim($sektor);
        $wilayah = trim($wilayah);

        // Filter sektor & wilayah berlaku untuk kedua query
        $filterSql = '';
        $filterParams = [];
        if ($sektor !== '') {
            $filterSql .= ' AND per.sektor = ?';
            $filterParams[] = $sektor;
        }
        if ($wilayah !== '') {
            $filterSql .= ' AND per.wilayah = ?';
            $filterParams[] = $wilayah;
        }

        $q1Where = '';
        $q2Where = '';
        $q1Params = $filterParams;
        $q2Params = $filterParams;

        if ($q !== '') {
            $like = '%'.$q.'%';
            $q1Where = ' AND (pas.teks_pasal LIKE ? OR pas.nomor_pasal LIKE ? OR per.judul LIKE ? OR per.jenis_peraturan LIKE ? OR per.nomor LIKE ?)';
            array_push($q1Params, $like, $like, $like, $like, $like);

            $q2Where = ' AND (per.judul LIKE ? OR per.jenis_peraturan LIKE ? OR per.nomor LIKE ?)';
            array_push($q2Params, $like, $like, $like);
        }

        $q1 = 'SELECT '.self::SELECT_FIELDS.'
               FROM pasal pas JOIN peraturan per ON pas.peraturan_id = per.id
               WHERE 1=1'.$filterSql.$q1Where;

        $q2 = 'SELECT '.self::SELECT_FIELDS.'
               FROM peraturan per LEFT JOIN pasal pas ON pas.peraturan_id = per.id
               WHERE pas.id IS NULL'.$filterSql.$q2Where;

        $unionSql = "$q1 UNION ALL $q2";
        $unionParams = array_merge($q1Params, $q2Params);

        // 1. Hitung total
        $totalCount = (int) DB::selectOne("SELECT COUNT(*) AS total FROM ($unionSql) AS combined", $unionParams)->total;
        $totalPages = max(1, (int) ceil($totalCount / $pageSize));
        $currentPage = min(max(1, $page), $totalPages);
        $offset = ($currentPage - 1) * $pageSize;

        // 2. Ambil data halaman ini
        $rows = DB::select(
            "SELECT * FROM ($unionSql) AS combined
             ORDER BY tahun DESC, peraturan_id DESC, pasal_id ASC LIMIT ? OFFSET ?",
            [...$unionParams, $pageSize, $offset]
        );

        // Kolom JSON dari MySQL berupa teks -> ubah jadi array PHP
        foreach ($rows as $row) {
            $row->status_detail_json = json_decode($row->status_detail_json ?? '{}', true) ?: [];
        }

        return [
            'items' => $rows,
            'totalCount' => $totalCount,
            'currentPage' => $currentPage,
            'pageSize' => $pageSize,
            'totalPages' => $totalPages,
        ];
    }

    /** Daftar sektor & wilayah yang tersedia, untuk dropdown filter. */
    public function daftarFilter(): array
    {
        return [
            'sektorList' => DB::table('peraturan')->whereNotNull('sektor')->where('sektor', '!=', '')
                ->distinct()->orderBy('sektor')->pluck('sektor')->all(),
            'wilayahList' => DB::table('peraturan')->whereNotNull('wilayah')->where('wilayah', '!=', '')
                ->distinct()->orderBy('wilayah')->pluck('wilayah')->all(),
        ];
    }
}
