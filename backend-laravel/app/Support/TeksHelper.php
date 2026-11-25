<?php

namespace App\Support;

use Illuminate\Support\HtmlString;

/**
 * Fungsi bantu (helper) untuk menampilkan teks di halaman Pencarian.
 *
 * Dipindahkan dari src/views/search.tsx supaya file Blade tetap sederhana.
 *
 * KEAMANAN (XSS): semua teks dari database di-escape dulu dengan e() sebelum
 * ditempeli tag HTML buatan kita (<mark>, <span>, <a>). Hasilnya dibungkus
 * HtmlString supaya Blade tahu itu sudah aman dan boleh dicetak dengan {!! !!}.
 */
class TeksHelper
{
    /** Path ikon (stroke 2, viewBox 24x24) — sama persis dengan konstanta ICON di versi lama. */
    private const IKON = [
        'search'   => 'M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z',
        'edit'     => 'M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z',
        'pencil'   => 'M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z',
        'trash'    => 'M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16',
        'external' => 'M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14',
        'close'           => 'M6 18L18 6M6 6l12 12',
        'notifications'   => 'M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9',
        'check'           => 'M5 13l4 4L19 7',
        'list'            => 'M4 6h16M4 12h16M4 18h7',
        'find_in_page'    => 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z',
        'event_available' => 'M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z',
        'post_add'        => 'M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z',
        'manage_accounts' => 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z',
        'person'          => 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z',
        'login'           => 'M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1',
        'logout'          => 'M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1',
        'download'        => 'M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4',
        'menu'            => 'M4 6h16M4 12h16M4 18h16',
        'share'           => 'M4 12v7a2 2 0 002 2h12a2 2 0 002-2v-7M16 6l-4-4m0 0L8 6m4-4v13',
        'smartphone'      => 'M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z',
    ];

    /** Ikon SVG inline. Contoh: {!! TeksHelper::ikon('search', 20) !!} */
    public static function ikon(string $nama, int $ukuran = 16): HtmlString
    {
        $d = self::IKON[$nama] ?? '';

        return new HtmlString(
            '<svg width="' . $ukuran . '" height="' . $ukuran . '" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">'
            . '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="' . e($d) . '"></path>'
            . '</svg>'
        );
    }

    /**
     * Ubah data status_detail_json (bisa array, string JSON, atau null) menjadi array.
     * Padanan parseStatusJson() di versi lama.
     */
    public static function parseStatusJson(mixed $raw): array
    {
        if (is_string($raw)) {
            $hasil = json_decode($raw, true);

            return is_array($hasil) ? $hasil : [];
        }

        return is_array($raw) ? $raw : [];
    }

    /**
     * Beri <mark> pada kata kunci di dalam teks (padanan highlightText()).
     * Aturan: kata < 3 huruf harus cocok utuh (\b..\b); kata >= 3 huruf cocok di awal kata (\b..).
     */
    public static function sorot(?string $teks, ?string $kataKunci): HtmlString
    {
        $teks = (string) preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]+/u', '', (string) $teks);
        $kataKunci = trim((string) $kataKunci);

        if ($kataKunci === '') {
            return new HtmlString(e($teks));
        }

        // Pecah kata kunci berdasarkan spasi
        $kata = preg_split('/\s+/u', $kataKunci, -1, PREG_SPLIT_NO_EMPTY);
        if (! $kata) {
            return new HtmlString(e($teks));
        }

        // Susun pola regex: tiap kata di-quote supaya karakter spesial (. * + ? dll) aman
        $pola = array_map(function ($t) {
            $aman = preg_quote($t, '/');

            return mb_strlen($t) < 3 ? '\b' . $aman . '\b' : '\b' . $aman;
        }, $kata);

        // Tanda kurung = "capture group" sehingga potongan yang cocok ikut tersimpan di hasil split
        $potongan = preg_split('/(' . implode('|', $pola) . ')/iu', $teks, -1, PREG_SPLIT_DELIM_CAPTURE);
        if ($potongan === false) {
            return new HtmlString(e($teks));
        }

        $html = '';
        foreach ($potongan as $bagian) {
            $cocok = false;
            $kecil = mb_strtolower($bagian);
            foreach ($kata as $t) {
                $tKecil = mb_strtolower($t);
                if (mb_strlen($t) < 3 ? $kecil === $tKecil : ($kecil !== '' && str_starts_with($kecil, $tKecil))) {
                    $cocok = true;
                    break;
                }
            }
            $html .= $cocok ? '<mark>' . e($bagian) . '</mark>' : e($bagian);
        }

        return new HtmlString($html);
    }

    /**
     * Tandai sebutan pasal ("Pasal 15", "Pasal 21 s.d. Pasal 25", "Pasal 1 angka 30")
     * dengan <span class="pasal-ref"> (bukan link). Padanan renderKeteranganWithLinks().
     */
    public static function keterangan(?string $teks): HtmlString
    {
        return new HtmlString(self::tandaiPasal((string) $teks));
    }

    /**
     * Ubah rujukan peraturan ("PP No. 5 Tahun 2020") menjadi link pencarian,
     * sedangkan sebutan pasal ditandai <span class="pasal-ref">. Padanan linkifyRegRefs().
     */
    public static function tautkanPeraturan(?string $teks): HtmlString
    {
        $teks = (string) $teks;
        $pola = '/((?:UU|PP|Perpres|Permen|Perda|Pergub|Perbup|Perwal|Perppu|Inpres|Keppres|Kepmen)\b[^;.\n]*?No\.?\s*\d+\s+Tahun\s+\d{4})/u';

        $html = '';
        $terakhir = 0;

        if (preg_match_all($pola, $teks, $m, PREG_OFFSET_CAPTURE)) {
            foreach ($m[0] as $i => [$cocok, $posisi]) {
                if ($posisi > $terakhir) {
                    $html .= self::tandaiPasal(substr($teks, $terakhir, $posisi - $terakhir));
                }
                $ref = trim($m[1][$i][0]);
                $html .= '<a href="/pencarian?q=' . rawurlencode($ref) . '" target="_blank" rel="noopener noreferrer"'
                    . ' title="' . e('Cari "' . $ref . '" di sistem') . '" class="reg-link">' . e($ref) . '</a>';
                $terakhir = $posisi + strlen($cocok);
            }
        }

        if ($terakhir < strlen($teks)) {
            $html .= self::tandaiPasal(substr($teks, $terakhir));
        }

        return new HtmlString($html);
    }

    /**
     * Daftar nomor halaman ringkas: 1 ... n-1 n n+1 ... last
     * Nilai null = tampilkan "...". Padanan pageWindow().
     *
     * @return array<int, int|null>
     */
    public static function jendelaHalaman(int $sekarang, int $total): array
    {
        $angka = array_unique([1, $total, $sekarang - 1, $sekarang, $sekarang + 1]);
        $angka = array_values(array_filter($angka, fn ($n) => $n >= 1 && $n <= $total));
        sort($angka);

        $hasil = [];
        foreach ($angka as $i => $n) {
            if ($i > 0 && $n - $angka[$i - 1] > 1) {
                $hasil[] = null;
            }
            $hasil[] = $n;
        }

        return $hasil;
    }

    /** Escape teks lalu bungkus sebutan "Pasal N ..." dengan span. Mengembalikan string HTML aman. */
    private static function tandaiPasal(string $teks): string
    {
        if ($teks === '') {
            return '';
        }

        $pola = '/(Pasal\s+\d+(?:\s*(?:s\.d\.|sampai dengan|-)\s*(?:Pasal\s*)?\d+)?(?:\s+ayat\s*\(\d+\))?(?:\s+huruf\s+[a-z])?(?:\s+angka\s+\d+)?)/iu';
        $potongan = preg_split($pola, $teks, -1, PREG_SPLIT_DELIM_CAPTURE);
        if ($potongan === false) {
            return e($teks);
        }

        $html = '';
        foreach ($potongan as $bagian) {
            $html .= preg_match('/^Pasal\s+\d+/iu', trim($bagian))
                ? '<span class="pasal-ref">' . e($bagian) . '</span>'
                : e($bagian);
        }

        return $html;
    }
}
