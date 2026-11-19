<?php

namespace App\Services;

use App\Models\Pasal;
use App\Models\Peraturan;
use DOMElement;
use DOMNode;
use DOMXPath;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Smalot\PdfParser\Config as PdfConfig;
use Smalot\PdfParser\Parser as PdfParser;
use Symfony\Component\DomCrawler\Crawler;
use Throwable;

/**
 * Crawler = "robot" yang membuka sebuah URL peraturan, lalu membaca isinya.
 *
 * Langkah:
 *  1. Unduh halaman HTML dari URL (apa adanya, URL dianggap absolut).
 *  2. Ambil judul resmi dari tabel metadata BPK / og:title / <h1> / <title>.
 *  3. Cari pasal dengan pola "Pasal N" pada isi halaman HTML.
 *  4. Jika halaman BPK: ambil juga "Status Peraturan" (mencabut, diubah, dst).
 *  5. Jika HTML tidak memuat teks pasal, coba ekstrak dari teks manual atau
 *     unduh berkas PDF resmi (/Download/...) pada halaman BPK dan urai pasalnya.
 *  6. Simpan peraturan + pasal ke database.
 */
class UrlCrawler
{
    private const PASAL_PATTERN = '/^Pasal\s+(\d+[A-Z]?|[Il])$/i';

    /** Rasio kata "aneh" (misal "4dalah", "pe;att:ran") mulai dari mana teks PDF dianggap hasil OCR berantakan. */
    private const AMBANG_TEKS_BERANTAKAN = 0.02;

    /** Label pada halaman BPK  =>  kunci di kolom status_detail_json */
    private const LABEL_TO_KEY = [
        'mencabut' => 'mencabut',
        'mencabut sebagian' => 'mencabut_sebagian',
        'mencabut sebagian dengan' => 'mencabut_sebagian_dengan',
        'diubah' => 'diubah_dengan',
        'diubah dengan' => 'diubah_dengan',
        'diubah sebagian' => 'diubah_dengan',
        'diubah sebagian dengan' => 'diubah_dengan',
        'dicabut' => 'dicabut_dengan',
        'dicabut dengan' => 'dicabut_dengan',
        'dicabut sebagian' => 'dicabut_sebagian_dengan',
        'dicabut sebagian dengan' => 'dicabut_sebagian_dengan',
        'mengubah' => 'mengubah',
        'mengubah sebagian' => 'mengubah',
        'ditetapkan' => 'ditetapkan',
        'menetapkan' => 'ditetapkan',
        'terkait' => 'peraturan_terkait',
        'peraturan terkait' => 'peraturan_terkait',
    ];

    /** Pemetaan relasi balik (inverse) ketika peraturan A merujuk peraturan B di database lokal */
    private const INVERSE_RELASI = [
        'mencabut' => 'dicabut_dengan',
        'mencabut_sebagian' => 'dicabut_sebagian_dengan',
        'mengubah' => 'diubah_dengan',
        'dicabut_dengan' => 'mencabut',
        'dicabut_sebagian_dengan' => 'mencabut_sebagian',
        'diubah_dengan' => 'mengubah',
    ];

    /**
     * Katalog cadangan metadata & relasi BPK untuk peraturan rujukan utama apabila
     * server cloud (Railway) diblokir dari mengakses peraturan.bpk.go.id secara langsung.
     */
    private const KATALOG_CADANGAN_BPK = [
        'UU|32|2004' => [
            'judul' => 'Undang-Undang Nomor 32 Tahun 2004 tentang Pemerintahan Daerah',
            'materi_pokok' => 'Dalam UU ini diatur mengenai pelaksanaan otonomi daerah di Indonesia. Dalam Otonomi daerah, daerah dibagi atas daerah-daerah provinsi dan daerah provinsi itu dibagi atas kabupaten dan kota yang masing-masing mempunyai pemerintahan daerah. Pembagian urusan pemerintahan dilaksanakan dengan cara pembagian urusan pemerintah pusat dan pemerintahan daerah. Pemerintahan daerah menyelenggarakan urusan pemerintahan yang menjadi kewenangannya, kecuali urusan pemerintahan yang oleh Undang-Undang ini ditentukan menjadi urusan Pemerintah pusat. Pokok-pokok pengaturan dalam UU ini antara lain: pembentukan daerah dan kawasan khusus; penyelenggaraan pemerintahan; kepegawaian daerah; peraturan daerah dan peraturan kepala daerah; perencanaan pembangunan daerah; dan keuangan daerah.',
            'relasi' => [
                'mencabut' => [
                    [
                        'label' => 'UU No. 22 Tahun 1999',
                        'judul' => 'UU No. 22 Tahun 1999 tentang Pemerintahan Daerah',
                        'url' => 'https://peraturan.bpk.go.id/Details/45329/uu-no-22-tahun-1999',
                    ],
                ],
            ],
        ],
        'UU|28|2009' => [
            'judul' => 'Undang-Undang Nomor 28 Tahun 2009 tentang Pajak Daerah dan Retribusi Daerah',
            'relasi' => [
                'mencabut' => [
                    [
                        'label' => 'UU No. 34 Tahun 2000',
                        'judul' => 'UU No. 34 Tahun 2000 tentang Perubahan atas Undang-Undang Republik Indonesia Nomor 18 Tahun 1997 tentang Pajak Daerah dan Retribusi Daerah',
                        'url' => 'https://peraturan.bpk.go.id/Details/45238/uu-no-34-tahun-2000',
                    ],
                    [
                        'label' => 'UU No. 18 Tahun 1997',
                        'judul' => 'UU No. 18 Tahun 1997 tentang Pajak Daerah dan Retribusi Daerah',
                        'url' => 'https://peraturan.bpk.go.id/Details/45992/uu-no-18-tahun-1997',
                    ],
                ],
            ],
        ],
        'UU|33|2004' => [
            'judul' => 'Undang-Undang Nomor 33 Tahun 2004 tentang Perimbangan Keuangan antara Pemerintah Pusat dan Pemerintahan Daerah',
            'relasi' => [
                'mencabut' => [
                    [
                        'label' => 'UU No. 25 Tahun 1999',
                        'judul' => 'UU No. 25 Tahun 1999 tentang Perimbangan Keuangan antara Pemerintah Pusat dan Daerah',
                        'url' => 'https://peraturan.bpk.go.id/Details/45335/uu-no-25-tahun-1999',
                    ],
                ],
            ],
        ],
    ];

    /**
     * @param  array  $input  url, jenis_peraturan, nomor, tahun, judul, wilayah, sektor, teks_manual (opsional)
     */
    public function crawl(array $input): array
    {
        $url = trim((string) ($input['url'] ?? ''));
        $manualJudul = trim((string) ($input['judul'] ?? ''));
        $teksManual = trim((string) ($input['teks_manual'] ?? ''));

        // Status tautan tidak lagi ditampilkan ke pengguna; kegagalan unduh otomatis tidak dianggap tautan rusak
        $statusTautan = 'normal';
        $finalJudul = $manualJudul !== '' ? $manualJudul : $url;
        $parsedPasal = [];
        $statusJson = [];
        $statusDetail = '';
        $statusPeraturan = 'berlaku';
        $crawler = null;

        // 1. Unduh halaman (mendukung CRAWLER_PROXY_URL ber-IP Indonesia untuk server cloud luar negeri)
        $html = $this->unduhUrl($url, 30);

        // Jika unduhan gagal namun pengguna menempel kode HTML halaman sumber ke kolom teks manual
        if ($html === '' && $teksManual !== '' && preg_match('/<(?:html|body|div|ol|li|meta)\b/i', $teksManual)) {
            $html = $teksManual;
        }

        // 2. Baca isi HTML
        if ($html !== '') {
            $crawler = new Crawler;
            $crawler->addHtmlContent($html, 'UTF-8');

            if ($manualJudul === '') {
                $finalJudul = $this->ekstrakJudul($crawler, $url);
            }

            $parsedPasal = $this->ekstrakPasal($crawler);

            $status = $this->ambilStatus($crawler);
            if ($status !== null) {
                $statusJson = $status['json'];
                $statusDetail = $status['ringkasan'];
            }
        }

        // Cadangan 1: pengguna menempel teks manual pada form (pasal & blok STATUS PERATURAN)
        if ($teksManual !== '') {
            if (count($parsedPasal) === 0) {
                $parsedPasal = $this->ekstrakPasalDariTeks($teksManual);
            }
            if (empty($statusJson)) {
                $statusDariTeks = $this->ekstrakStatusDariTeks($teksManual);
                if ($statusDariTeks !== null) {
                    $statusJson = $statusDariTeks['json'];
                    $statusDetail = $statusDariTeks['ringkasan'];
                }
            }
        }

        // Cadangan 2: deteksi relasi timbal-balik & tidak langsung dari database lokal + katalog BPK
        // (mengatasi pemblokiran akses peraturan.bpk.go.id dari IP server cloud seperti Railway)
        $hasilLokal = $this->inferDariDatabaseLokal($input, $finalJudul, $statusJson, $teksManual);
        $finalJudul = $hasilLokal['judul'];
        $statusJson = $hasilLokal['status_json'];

        // Cadangan 3: deteksi relasi Mengubah/Mencabut langsung dari pola judul ("Perubahan Atas ..." / "Pencabutan Atas ...")
        $inferred = $this->inferStatusDariJudulDanTeks($finalJudul, $teksManual, $input);
        if ($inferred !== null) {
            $statusJson = $this->gabungStatusJson($statusJson, $inferred['json']);
        }

        if (! empty($statusJson)) {
            $statusDetail = $this->bangunRingkasanStatus($statusJson);
        }

        $statusPeraturan = $this->tentukanStatus($crawler, $statusJson);

        // Materi Pokok / Abstrak resmi BPK: selalu disimpan bila ada (di urutan pertama).
        $materiPokok = $crawler !== null ? $this->ekstrakAbstrakBpk($crawler) : [];
        if (count($materiPokok) === 0 && $teksManual !== '') {
            $materiPokok = $this->ekstrakMateriPokokDariTeks($teksManual);
        }
        if (count($materiPokok) === 0 && $hasilLokal['materi_pokok'] !== '') {
            $materiPokok = [[
                'nomor_pasal' => 'Materi Pokok',
                'nomor_ayat' => '',
                'teks_pasal' => $hasilLokal['materi_pokok'],
            ]];
        }

        // Cadangan 4: unduh berkas PDF resmi dari halaman BPK dan ekstrak pasalnya.
        // Jika PDF berupa hasil pindaian (lapisan teks OCR BPK penuh salah baca) DAN Materi Pokok tersedia,
        // pasal hasil PDF dilewati supaya pencarian tidak berisi teks berantakan.
        if (count($parsedPasal) === 0 && $crawler !== null) {
            $dariPdf = $this->ekstrakPasalDariPdf($crawler, $url);
            if (count($materiPokok) > 0 && $this->skorTeksBerantakan($dariPdf) >= self::AMBANG_TEKS_BERANTAKAN) {
                $dariPdf = [];
            }
            $parsedPasal = $dariPdf;
        }

        if (count($materiPokok) > 0) {
            $parsedPasal = array_merge($materiPokok, $parsedPasal);
        }

        // 3. Simpan ke database (perbarui baris lama jika peraturan yang sama sebelumnya gagal terambil sempurna dari cloud)
        try {
            $peraturan = DB::transaction(function () use ($input, $finalJudul, $statusPeraturan, $statusDetail, $statusJson, $statusTautan, $url, $parsedPasal) {
                $existing = Peraturan::where('jenis_peraturan', $input['jenis_peraturan'])
                    ->where('nomor', $input['nomor'])
                    ->where('tahun', (int) $input['tahun'])
                    ->first();

                if ($existing && (empty($existing->status_detail_json) || str_starts_with(trim((string) $existing->judul), 'http'))) {
                    $existing->update([
                        'judul' => $finalJudul,
                        'status' => $statusPeraturan,
                        'status_detail' => $statusDetail !== '' ? $statusDetail : $existing->status_detail,
                        'status_detail_json' => ! empty($statusJson) ? $statusJson : ($existing->status_detail_json ?? []),
                        'wilayah' => $input['wilayah'] ?? $existing->wilayah ?? 'Nasional',
                        'sektor' => $input['sektor'] ?? $existing->sektor ?? 'Lainnya',
                        'url_dokumen_asli' => $url !== '' ? $url : $existing->url_dokumen_asli,
                        'status_tautan' => $statusTautan,
                        'tanggal_dicek_terakhir' => now(),
                    ]);

                    if (count($parsedPasal) > 0) {
                        $existing->pasal()->delete();
                        foreach ($parsedPasal as $p) {
                            Pasal::create([
                                'peraturan_id' => $existing->id,
                                'nomor_pasal' => $p['nomor_pasal'],
                                'nomor_ayat' => $p['nomor_ayat'] ?: '',
                                'teks_pasal' => $p['teks_pasal'],
                            ]);
                        }
                    }

                    return $existing;
                }

                $peraturan = Peraturan::create([
                    'jenis_peraturan' => $input['jenis_peraturan'],
                    'nomor' => $input['nomor'],
                    'tahun' => $input['tahun'],
                    'judul' => $finalJudul,
                    'status' => $statusPeraturan,
                    'status_detail' => $statusDetail,
                    'status_detail_json' => $statusJson,
                    'wilayah' => $input['wilayah'] ?? 'Nasional',
                    'sektor' => $input['sektor'] ?? 'Lainnya',
                    'url_dokumen_asli' => $url,
                    'status_tautan' => $statusTautan,
                    'tanggal_diambil' => now(),
                    'tanggal_dicek_terakhir' => now(),
                ]);

                foreach ($parsedPasal as $p) {
                    Pasal::create([
                        'peraturan_id' => $peraturan->id,
                        'nomor_pasal' => $p['nomor_pasal'],
                        'nomor_ayat' => $p['nomor_ayat'] ?: '',
                        'teks_pasal' => $p['teks_pasal'],
                    ]);
                }

                return $peraturan;
            });
        } catch (Throwable $e) {
            logger()->error('[UrlCrawler] DB error: '.$e->getMessage());

            return [
                'ok' => false,
                'judul' => $finalJudul,
                'status_tautan' => $statusTautan,
                'pasal_count' => 0,
                'peraturan_id' => null,
                'parsedPasal' => [],
                'error' => 'Gagal menyimpan ke database: '.$e->getMessage(),
            ];
        }

        return [
            'ok' => true,
            'judul' => $finalJudul,
            'status_tautan' => $statusTautan,
            'pasal_count' => count($parsedPasal),
            'peraturan_id' => $peraturan->id,
            'parsedPasal' => $parsedPasal,
        ];
    }

    /**
     * Lengkapi otomatis peraturan yang sudah terlanjur tersimpan tanpa relasi JSON atau berjudul URL
     * akibat pemblokiran jaringan dari server cloud.
     */
    public function lengkapiPeraturanJikaPerlu(Peraturan $peraturan): Peraturan
    {
        try {
            $jsonSaatIni = is_array($peraturan->status_detail_json) ? $peraturan->status_detail_json : [];
            $judulAdalahUrl = str_starts_with(trim((string) $peraturan->judul), 'http');

            if (! empty($jsonSaatIni) && ! $judulAdalahUrl) {
                return $peraturan;
            }

            $input = [
                'url' => (string) $peraturan->url_dokumen_asli,
                'jenis_peraturan' => (string) $peraturan->jenis_peraturan,
                'nomor' => (string) $peraturan->nomor,
                'tahun' => (int) $peraturan->tahun,
                'wilayah' => (string) $peraturan->wilayah,
                'sektor' => (string) $peraturan->sektor,
            ];

            $detailLama = trim((string) $peraturan->status_detail);
            $statusDariDetail = $detailLama !== '' ? $this->ekstrakStatusDariTeks($detailLama) : null;
            if ($statusDariDetail !== null) {
                $jsonSaatIni = $this->gabungStatusJson($jsonSaatIni, $statusDariDetail['json']);
            }

            $hasil = $this->inferDariDatabaseLokal($input, (string) $peraturan->judul, $jsonSaatIni, $detailLama);
            $judulBaru = $hasil['judul'];
            $jsonBaru = $hasil['status_json'];

            $inferred = $this->inferStatusDariJudulDanTeks($judulBaru, $detailLama, $input);
            if ($inferred !== null) {
                $jsonBaru = $this->gabungStatusJson($jsonBaru, $inferred['json']);
            }

            $perluSimpan = false;
            if ($judulAdalahUrl && $judulBaru !== '' && $judulBaru !== $peraturan->judul) {
                $peraturan->judul = $judulBaru;
                $perluSimpan = true;
            }

            if (! empty($jsonBaru) && empty($peraturan->status_detail_json)) {
                $peraturan->status_detail_json = $jsonBaru;
                $peraturan->status_detail = $this->bangunRingkasanStatus($jsonBaru);
                $peraturan->status = $this->tentukanStatus(null, $jsonBaru);
                $perluSimpan = true;
            }

            if ($perluSimpan) {
                $peraturan->save();
            }

            if ($hasil['materi_pokok'] !== '' && $peraturan->pasal()->count() === 0) {
                Pasal::create([
                    'peraturan_id' => $peraturan->id,
                    'nomor_pasal' => 'Materi Pokok',
                    'nomor_ayat' => '',
                    'teks_pasal' => $hasil['materi_pokok'],
                ]);
            }
        } catch (Throwable $e) {
            logger()->warning('[UrlCrawler] Gagal melengkapi peraturan #'.$peraturan->id.': '.$e->getMessage());
        }

        return $peraturan;
    }

    // ------------------------------------------------------------------
    // Pengunduh HTTP dengan dukungan Proxy / Relay Indonesia
    // ------------------------------------------------------------------

    /**
     * Unduh konten URL (HTML maupun PDF).
     * Jika CRAWLER_PROXY_URL dikonfigurasi (misal HTTP/SOCKS5 proxy Indonesia atau endpoint relay `?url={url}`),
     * permintaan dikirim melalui proxy tersebut terlebih dahulu agar tidak terblokir Geo-IP di server cloud,
     * lalu jatuh-balik (fallback) ke koneksi langsung bila diperlukan.
     */
    private function unduhUrl(string $targetUrl, int $timeout = 30): string
    {
        if ($targetUrl === '') {
            return '';
        }

        $headers = [
            'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'Accept' => 'text/html,application/xhtml+xml,application/xml,application/pdf;q=0.9,*/*;q=0.8',
            'Accept-Language' => 'id-ID,id;q=0.9,en-US;q=0.8',
        ];

        $rawProxies = trim((string) config('p3h.crawler_proxy_url', ''));
        $daftarProxy = $rawProxies !== ''
            ? array_values(array_filter(array_map('trim', explode(',', $rawProxies)), fn ($p) => $p !== ''))
            : [];

        // 1. Coba melalui tiap proxy / relay Indonesia yang dikonfigurasi
        foreach ($daftarProxy as $proxy) {
            try {
                // Mode A: Endpoint relay URL (contoh: https://relay-id.example.com/?url={url} atau ...?url=)
                if (str_contains($proxy, '{url}') || preg_match('/[?&]url=$/i', $proxy)) {
                    $relayUrl = str_contains($proxy, '{url}')
                        ? str_replace('{url}', rawurlencode($targetUrl), $proxy)
                        : $proxy.rawurlencode($targetUrl);

                    $res = Http::withoutVerifying()->withHeaders($headers)->timeout($timeout)->get($relayUrl);
                    if ($res->successful() && $res->body() !== '') {
                        return $res->body();
                    }
                    continue;
                }

                // Mode B: HTTP / HTTPS / SOCKS5 proxy standar (contoh: http://user:pass@ip:port atau socks5h://ip:port)
                $res = Http::withoutVerifying()
                    ->withHeaders($headers)
                    ->withOptions(['proxy' => $proxy])
                    ->timeout($timeout)
                    ->get($targetUrl);

                if ($res->successful() && $res->body() !== '') {
                    return $res->body();
                }
            } catch (Throwable $e) {
                logger()->warning('[UrlCrawler] Gagal mengunduh via proxy ('.$targetUrl.'): '.$e->getMessage());
            }
        }

        // 2. Koneksi langsung (atau fallback jika proxy tidak diatur / gagal)
        try {
            $res = Http::withoutVerifying()->withHeaders($headers)->timeout($timeout)->get($targetUrl);
            if ($res->successful()) {
                return $res->body();
            }
        } catch (Throwable $e) {
            logger()->warning('[UrlCrawler] Gagal mengunduh langsung '.$targetUrl.': '.$e->getMessage());
        }

        return '';
    }

    // ------------------------------------------------------------------
    // Judul
    // ------------------------------------------------------------------

    private function ekstrakJudul(Crawler $c, string $fallback): string
    {
        // 1. Cek baris metadata "Judul" pada halaman JDIH BPK
        $judulMetadata = $this->ambilMetadataBpk($c, 'Judul');
        if ($judulMetadata !== '' && mb_strlen($judulMetadata) > 5) {
            // Rapikan singkatan berulang seperti "Peraturan Pemerintah (PP) Nomor" -> "Peraturan Pemerintah Nomor"
            $bersih = preg_replace('/\s*\((?:UU|PP|Perpres|Permen|Permendagri|Permenkumham|Perda|Pergub|Perbup|Perwal|Inpres|Keppres|Kepmen|SE|Perppu)\)\s*/iu', ' ', $judulMetadata);

            return rtrim($this->rapikan((string) $bersih), '.');
        }

        // 2. Cek og:title
        $og = $c->filter('meta[property="og:title"]');
        if ($og->count() && mb_strlen(trim((string) $og->attr('content'))) > 5) {
            $teks = preg_replace('/\s*-\s*JDIH\s+BPK\s*$/iu', '', trim((string) $og->attr('content')));

            return rtrim($this->rapikan((string) $teks), '.');
        }

        // 3. Cek <h1>
        $h1 = $c->filter('h1');
        if ($h1->count()) {
            $teks = $this->rapikan($h1->first()->text('', false));
            if (mb_strlen($teks) > 5) {
                return $teks;
            }
        }

        // 4. Cek <title>
        $title = $c->filter('title');
        if ($title->count()) {
            $teks = $this->rapikan($title->first()->text('', false));
            $teks = preg_replace('/\s*(\||-)\s*(Database Peraturan\s*\|\s*)?JDIH\s+BPK.*$/iu', '', $teks);
            if (mb_strlen((string) $teks) > 5) {
                return trim((string) $teks);
            }
        }

        return $fallback;
    }

    private function ambilMetadataBpk(Crawler $c, string $namaKolom): string
    {
        foreach ($c->filter('div.row') as $row) {
            $kolom = [];
            foreach ($row->childNodes as $child) {
                if ($child instanceof DOMElement) {
                    $kolom[] = $this->rapikan($child->textContent);
                }
            }
            if (count($kolom) >= 2 && strcasecmp($kolom[0], $namaKolom) === 0) {
                return $kolom[1];
            }
        }

        return '';
    }

    public function tentukanStatus(?Crawler $c, array $statusJson): string
    {
        if (! empty($statusJson['dicabut_dengan'])) {
            return 'dicabut';
        }

        if ($c !== null) {
            $statusMeta = strtolower($this->ambilMetadataBpk($c, 'Status'));
            if (str_contains($statusMeta, 'tidak berlaku') || str_contains($statusMeta, 'dicabut')) {
                return 'dicabut';
            }
        }

        if (! empty($statusJson['diubah_dengan']) || ! empty($statusJson['dicabut_sebagian_dengan'])) {
            return 'diubah';
        }

        return 'berlaku';
    }

    /**
     * Lengkapi judul, relasi status_detail_json (Dicabut dengan, Dicabut sebagian dengan,
     * Diubah dengan, Mencabut, Mengubah), dan Materi Pokok dengan memindai grafik relasi
     * pada tabel `peraturan` lokal serta katalog cadangan BPK.
     *
     * @return array{judul: string, status_json: array, materi_pokok: string}
     */
    private function inferDariDatabaseLokal(array $input, string $judulSaatIni, array $statusJsonSaatIni, string $teksManual = ''): array
    {
        $jenis = trim((string) ($input['jenis_peraturan'] ?? ''));
        $nomor = ltrim(trim((string) ($input['nomor'] ?? '')), '0') ?: trim((string) ($input['nomor'] ?? ''));
        $tahun = (int) ($input['tahun'] ?? 0);
        $url = trim((string) ($input['url'] ?? ''));
        $wilayah = trim((string) ($input['wilayah'] ?? 'Nasional'));

        $judul = trim($judulSaatIni);
        $judulMasihUrl = $judul === '' || str_starts_with($judul, 'http');
        $statusJson = $statusJsonSaatIni;
        $materiPokok = '';

        // 1. Cek katalog cadangan BPK terlebih dahulu
        $kunciKatalog = strtoupper($jenis).'|'.$nomor.'|'.$tahun;
        if (isset(self::KATALOG_CADANGAN_BPK[$kunciKatalog])) {
            $kat = self::KATALOG_CADANGAN_BPK[$kunciKatalog];
            if ($judulMasihUrl && ! empty($kat['judul'])) {
                $judul = $kat['judul'];
                $judulMasihUrl = false;
            }
            if (! empty($kat['materi_pokok'])) {
                $materiPokok = $kat['materi_pokok'];
            }
            if (! empty($kat['relasi'])) {
                $statusJson = $this->gabungStatusJson($statusJson, $kat['relasi']);
            }
        }

        if ($jenis === '' || $nomor === '' || $tahun < 1900) {
            return ['judul' => $judul, 'status_json' => $statusJson, 'materi_pokok' => $materiPokok];
        }

        $bpkIdTarget = null;
        if (preg_match('#/Details/(\d+)#i', $url, $mId)) {
            $bpkIdTarget = $mId[1];
        }

        $polaJenis = $this->polaRegexJenis($jenis);
        $polaIdentitasAwal = '/^\s*'.$polaJenis.'\b[^0-9\n]*?\b(?:No\.?|Nomor)\s*0*'.preg_quote($nomor, '/').'\s+Tahun\s+'.$tahun.'\b(?:\s+tentang\s+(.+))?$/iu';
        $polaSasaranPerubahan = '/\bPerubahan\s+(?:(?:Pertama|Kedua|Ketiga|Keempat|Kelima)\s+)?Atas\s+'.$polaJenis.'\b[^.;\n]*?\b(?:No\.?|Nomor)\s*0*'.preg_quote($nomor, '/').'\s+Tahun\s+'.$tahun.'\b/iu';
        $polaSasaranPencabutan = '/\bPencabutan\s+(?:Atas\s+)?'.$polaJenis.'\b[^.;\n]*?\b(?:No\.?|Nomor)\s*0*'.preg_quote($nomor, '/').'\s+Tahun\s+'.$tahun.'\b/iu';

        // 2. Pindai seluruh peraturan yang sudah ada di database lokal
        try {
            $semuaPeraturan = Peraturan::all();
        } catch (Throwable) {
            $semuaPeraturan = collect();
        }

        foreach ($semuaPeraturan as $per) {
            // Lewati diri sendiri
            if (strcasecmp((string) $per->jenis_peraturan, $jenis) === 0
                && (ltrim((string) $per->nomor, '0') ?: (string) $per->nomor) === $nomor
                && (int) $per->tahun === $tahun) {
                continue;
            }

            $relJson = is_array($per->status_detail_json)
                ? $per->status_detail_json
                : (json_decode((string) ($per->status_detail_json ?? '{}'), true) ?: []);

            $labelPer = "{$per->jenis_peraturan} No. {$per->nomor} Tahun {$per->tahun}";
            $judulRingkasPer = $this->formatJudulRelasi($per->jenis_peraturan, (string) $per->nomor, (int) $per->tahun, (string) $per->judul);

            // 2a. Cek apakah judul peraturan $per sendiri merupakan Perubahan / Pencabutan atas peraturan target ini
            if (preg_match($polaSasaranPerubahan, (string) $per->judul)) {
                $statusJson = $this->gabungStatusJson($statusJson, [
                    'diubah_dengan' => [[
                        'label' => $labelPer,
                        'judul' => $judulRingkasPer,
                        'url' => (string) $per->url_dokumen_asli,
                    ]],
                ]);
            } elseif (preg_match($polaSasaranPencabutan, (string) $per->judul)) {
                $statusJson = $this->gabungStatusJson($statusJson, [
                    'dicabut_dengan' => [[
                        'label' => $labelPer,
                        'judul' => $judulRingkasPer,
                        'url' => (string) $per->url_dokumen_asli,
                    ]],
                ]);
            }

            // 2b. Pindai setiap daftar relasi di dalam status_detail_json milik $per
            foreach ($relJson as $relKey => $daftarItem) {
                if (! is_array($daftarItem)) {
                    continue;
                }

                $inverseKey = self::INVERSE_RELASI[$relKey] ?? null;

                foreach ($daftarItem as $item) {
                    if (! is_array($item)) {
                        continue;
                    }

                    $itemUrl = trim((string) ($item['url'] ?? ''));
                    $itemLabel = trim((string) ($item['label'] ?? ''));
                    $itemJudul = trim((string) ($item['judul'] ?? ''));
                    $bagianSebelumTentang = trim(preg_split('/\btentang\b/iu', $itemJudul)[0] ?? $itemLabel);

                    $cocokTarget = false;
                    if ($bpkIdTarget !== null && preg_match('#/Details/(\d+)#i', $itemUrl, $mItem) && $mItem[1] === $bpkIdTarget) {
                        $cocokTarget = true;
                    } elseif (preg_match($polaIdentitasAwal, $bagianSebelumTentang) || preg_match($polaIdentitasAwal, $itemLabel)) {
                        $cocokTarget = true;
                    }

                    if ($cocokTarget) {
                        // Ambil judul resmi ("tentang ...") bila judul target masih berupa URL
                        if ($judulMasihUrl && preg_match('/\btentang\s+(.+)$/iu', $itemJudul, $mTentang)) {
                            $judul = $this->formatJudulLengkap($jenis, $nomor, $tahun, $wilayah, trim($mTentang[1]));
                            $judulMasihUrl = false;
                        }

                        // Tambahkan relasi balik (misal $per mencabut target -> target dicabut_dengan $per)
                        if ($inverseKey !== null) {
                            $entriBalik = [
                                'label' => $labelPer,
                                'judul' => $judulRingkasPer,
                                'url' => (string) $per->url_dokumen_asli,
                            ];
                            if (! empty($item['keterangan'])) {
                                $entriBalik['keterangan'] = trim((string) $item['keterangan']);
                            }
                            $statusJson = $this->gabungStatusJson($statusJson, [
                                $inverseKey => [$entriBalik],
                            ]);
                        }
                        continue;
                    }

                    // 2c. Relasi tidak langsung: entri di dalam JSON menyebutkan "Perubahan ... atas <Target>"
                    if ($itemJudul !== '') {
                        if (preg_match($polaSasaranPerubahan, $itemJudul)) {
                            $statusJson = $this->gabungStatusJson($statusJson, [
                                'diubah_dengan' => [[
                                    'label' => $itemLabel !== '' ? $itemLabel : $itemJudul,
                                    'judul' => $itemJudul,
                                    'url' => $itemUrl,
                                ]],
                            ]);
                        } elseif (preg_match($polaSasaranPencabutan, $itemJudul)) {
                            $statusJson = $this->gabungStatusJson($statusJson, [
                                'dicabut_dengan' => [[
                                    'label' => $itemLabel !== '' ? $itemLabel : $itemJudul,
                                    'judul' => $itemJudul,
                                    'url' => $itemUrl,
                                ]],
                            ]);
                        }
                    }
                }
            }
        }

        // 3. Jika judul masih berupa URL, coba ambil "TENTANG ..." dari teks manual atau bentuk judul standar yang rapi
        if ($judulMasihUrl) {
            $tentangManual = '';
            if ($teksManual !== '' && preg_match('/\bTENTANG\s+([^\r\n.;]{4,160})/iu', $teksManual, $mT)) {
                $tentangManual = $this->rapikan($mT[1]);
            }
            $judul = $this->formatJudulLengkap($jenis, $nomor, $tahun, $wilayah, $tentangManual);
        }

        return [
            'judul' => $judul,
            'status_json' => $statusJson,
            'materi_pokok' => $materiPokok,
        ];
    }

    /**
     * Ekstrak blok "STATUS PERATURAN" (Dicabut dengan :, Dicabut sebagian dengan :,
     * Diubah dengan :, Mencabut :, Mengubah :) dari teks manual yang ditempel pengguna.
     *
     * @return array{json: array, ringkasan: string}|null
     */
    public function ekstrakStatusDariTeks(string $teks): ?array
    {
        if (trim($teks) === '') {
            return null;
        }

        $polaLabel = '/^\s*(?:[0-9]+\.\s*)?(Dicabut\s+sebagian\s+dengan|Dicabut\s+dengan|Dicabut\s+sebagian|Dicabut|Diubah\s+sebagian\s+dengan|Diubah\s+dengan|Diubah\s+sebagian|Diubah|Mencabut\s+sebagian\s+dengan|Mencabut\s+sebagian|Mencabut|Mengubah\s+sebagian|Mengubah|Ditetapkan\s+dengan|Ditetapkan|Menetapkan)\s*:?\s*(.*)$/iu';
        $polaBerhenti = '/^\s*(MATERI\s+POKOK\s+PERATURAN|ABSTRAK\s+PERATURAN|DETAIL\s+PERATURAN|FILE\s*\-\s*FILE\s+PERATURAN|Pasal\s+\d+\b|BAB\s+[IVXLCDM]+\b)/iu';
        $polaReg = '/^((?:UU|PP|Perpres|Permen|Permendagri|Permenkumham|Perda|Pergub|Perbup|Perwal|Perppu|Perpu|Inpres|Keppres|Kepmen)[^0-9\n]*?(?:No\.?|Nomor)\s*\d+\s+Tahun\s+\d{4})(?:\s+tentang\s+(.+))?$/iu';

        $hasil = [];
        $kunciAktif = null;
        $indexAktif = null;

        foreach (preg_split('/\r\n|\r|\n/', $teks) as $barisMentah) {
            $baris = $this->rapikan($barisMentah);
            if ($baris === '') {
                continue;
            }

            if (preg_match($polaBerhenti, $baris)) {
                $kunciAktif = null;
                $indexAktif = null;
                continue;
            }

            if (preg_match($polaLabel, $baris, $mLabel)) {
                $namaLabel = strtolower($this->rapikan($mLabel[1]));
                $kunciAktif = self::LABEL_TO_KEY[$namaLabel] ?? null;
                $indexAktif = null;

                $sisa = trim($mLabel[2] ?? '');
                if ($kunciAktif !== null && $sisa !== '') {
                    $entri = $this->uraiBarisItemStatus($sisa, $polaReg);
                    if ($entri !== null) {
                        $hasil[$kunciAktif][] = $entri;
                        $indexAktif = count($hasil[$kunciAktif]) - 1;
                    }
                }
                continue;
            }

            if ($kunciAktif === null) {
                continue;
            }

            // Buang penanda butir seperti "a.", "b.", "1.", "-", "•"
            $tanpaButir = trim((string) preg_replace('/^(?:[a-z0-9]{1,2}[\.\)]\s*|[\-\•\*]\s*)/iu', '', $baris));
            if ($tanpaButir === '') {
                continue;
            }
            $entri = $this->uraiBarisItemStatus($tanpaButir, $polaReg);
            if ($entri !== null) {
                $hasil[$kunciAktif][] = $entri;
                $indexAktif = count($hasil[$kunciAktif]) - 1;
            } elseif ($indexAktif !== null && isset($hasil[$kunciAktif][$indexAktif])) {
                // Baris keterangan di bawah item peraturan (misal: "Pasal 200 sampai dengan Pasal 216 ... dicabut")
                $ketLama = $hasil[$kunciAktif][$indexAktif]['keterangan'] ?? '';
                $hasil[$kunciAktif][$indexAktif]['keterangan'] = trim($ketLama.' '.$baris);
            }
        }

        if (empty($hasil)) {
            return null;
        }

        return [
            'json' => $hasil,
            'ringkasan' => $this->bangunRingkasanStatus($hasil),
        ];
    }

    private function uraiBarisItemStatus(string $teks, string $polaReg): ?array
    {
        if (! preg_match($polaReg, $teks, $m)) {
            return null;
        }

        $label = $this->rapikan($m[1]);
        $tentang = $this->rapikan($m[2] ?? '');
        $judul = $tentang !== '' ? "{$label} tentang {$tentang}" : $label;

        $url = '';
        if (preg_match('/^(UU|PP|Perpres|Permen|Permendagri|Permenkumham|Perda|Pergub|Perbup|Perwal|Perppu|Perpu|Inpres|Keppres|Kepmen)\b.*?(?:No\.?|Nomor)\s*0*(\d+)\s+Tahun\s+(\d{4})$/iu', $label, $mKode)) {
            $jenisCari = strtoupper($mKode[1]) === 'PERPU' ? 'Perppu' : $mKode[1];
            try {
                $lokal = Peraturan::whereRaw('LOWER(jenis_peraturan) = ?', [strtolower($jenisCari)])
                    ->where('nomor', $mKode[2])
                    ->where('tahun', (int) $mKode[3])
                    ->first();
                if ($lokal) {
                    $url = (string) $lokal->url_dokumen_asli;
                }
            } catch (Throwable) {
            }
        }

        return [
            'label' => $label,
            'judul' => $judul,
            'url' => $url,
        ];
    }

    private function ekstrakMateriPokokDariTeks(string $teks): array
    {
        if (preg_match('/MATERI\s+POKOK\s+PERATURAN\s*(?:Abstrak)?\s*(.+?)(?:CATATAN\s*:|STATUS\s+PERATURAN|FILE\s*\-\s*FILE|Pasal\s+1\b|$)/isu', $teks, $m)) {
            $bersih = $this->rapikan($m[1]);
            if (mb_strlen($bersih) > 30) {
                return [[
                    'nomor_pasal' => 'Materi Pokok',
                    'nomor_ayat' => '',
                    'teks_pasal' => $bersih,
                ]];
            }
        }

        return [];
    }

    /** Gabungkan dua struktur status_detail_json tanpa duplikasi item. */
    private function gabungStatusJson(array $utama, array $tambahan): array
    {
        foreach ($tambahan as $kunci => $daftar) {
            if (! is_array($daftar)) {
                continue;
            }
            if (! isset($utama[$kunci]) || ! is_array($utama[$kunci])) {
                $utama[$kunci] = [];
            }

            foreach ($daftar as $itemBaru) {
                if (! is_array($itemBaru)) {
                    continue;
                }
                $labelBaru = strtolower(trim((string) ($itemBaru['label'] ?? '')));
                $urlBaru = strtolower(trim((string) ($itemBaru['url'] ?? '')));
                $sudahAda = false;

                foreach ($utama[$kunci] as &$itemLama) {
                    $labelLama = strtolower(trim((string) ($itemLama['label'] ?? '')));
                    $urlLama = strtolower(trim((string) ($itemLama['url'] ?? '')));
                    if (($labelBaru !== '' && $labelBaru === $labelLama) || ($urlBaru !== '' && $urlBaru === $urlLama)) {
                        if (empty($itemLama['keterangan']) && ! empty($itemBaru['keterangan'])) {
                            $itemLama['keterangan'] = $itemBaru['keterangan'];
                        }
                        if (empty($itemLama['url']) && ! empty($itemBaru['url'])) {
                            $itemLama['url'] = $itemBaru['url'];
                        }
                        $sudahAda = true;
                        break;
                    }
                }
                unset($itemLama);

                if (! $sudahAda) {
                    $utama[$kunci][] = $itemBaru;
                }
            }
        }

        // Urutkan kunci sesuai urutan tampilan standar BPK
        $urutanKunci = ['dicabut_dengan', 'dicabut_sebagian_dengan', 'diubah_dengan', 'mencabut', 'mencabut_sebagian', 'mengubah', 'ditetapkan', 'peraturan_terkait'];
        $terurut = [];
        foreach ($urutanKunci as $k) {
            if (! empty($utama[$k])) {
                $terurut[$k] = $utama[$k];
            }
        }
        foreach ($utama as $k => $v) {
            if (! empty($v) && ! isset($terurut[$k])) {
                $terurut[$k] = $v;
            }
        }

        return $terurut;
    }

    public function bangunRingkasanStatus(array $statusJson): string
    {
        return collect($statusJson)
            ->filter(fn ($items) => is_array($items) && count($items) > 0)
            ->map(fn ($items, $k) => str_replace('_', ' ', $k).': '.count($items).' peraturan')
            ->implode('; ');
    }

    private function polaRegexJenis(string $jenis): string
    {
        return match (strtoupper(trim($jenis))) {
            'UU' => '(?:UU|Undang-Undang)',
            'PP' => '(?:PP|Peraturan\s+Pemerintah)',
            'PERPRES' => '(?:Perpres|Peraturan\s+Presiden)',
            'PERPPU', 'PERPU' => '(?:Perppu|Perpu|Peraturan\s+Pemerintah\s+Pengganti\s+Undang-Undang)',
            'PERDA' => '(?:Perda|Peraturan\s+Daerah)',
            'PERGUB' => '(?:Pergub|Peraturan\s+Gubernur)',
            'PERBUP' => '(?:Perbup|Peraturan\s+Bupati)',
            'PERWAL' => '(?:Perwal|Peraturan\s+Wali\s*Kota)',
            default => preg_quote($jenis, '/'),
        };
    }

    private function formatJudulLengkap(string $jenis, string $nomor, int $tahun, string $wilayah, string $tentang = ''): string
    {
        $namaJenis = match (strtoupper(trim($jenis))) {
            'UU' => 'Undang-Undang',
            'PP' => 'Peraturan Pemerintah',
            'PERPRES' => 'Peraturan Presiden',
            'PERPPU', 'PERPU' => 'Peraturan Pemerintah Pengganti Undang-Undang',
            'PERDA' => 'Peraturan Daerah'.($wilayah !== '' && strcasecmp($wilayah, 'Nasional') !== 0 ? ' '.$wilayah : ''),
            'PERGUB' => 'Peraturan Gubernur'.($wilayah !== '' && strcasecmp($wilayah, 'Nasional') !== 0 ? ' '.$wilayah : ''),
            'PERBUP' => 'Peraturan Bupati'.($wilayah !== '' && strcasecmp($wilayah, 'Nasional') !== 0 ? ' '.$wilayah : ''),
            'PERWAL' => 'Peraturan Wali Kota'.($wilayah !== '' && strcasecmp($wilayah, 'Nasional') !== 0 ? ' '.$wilayah : ''),
            default => $jenis,
        };

        $dasar = "{$namaJenis} Nomor {$nomor} Tahun {$tahun}";

        return $tentang !== '' ? "{$dasar} tentang {$tentang}" : $dasar;
    }

    private function formatJudulRelasi(string $jenis, string $nomor, int $tahun, string $judulLengkap): string
    {
        $label = "{$jenis} No. {$nomor} Tahun {$tahun}";
        if (preg_match('/\btentang\s+(.+)$/iu', $judulLengkap, $m)) {
            return "{$label} tentang ".trim($m[1]);
        }

        return $judulLengkap !== '' ? $judulLengkap : $label;
    }

    /**
     * Deteksi relasi "Mengubah" atau "Mencabut" dari judul / teks manual ketika halaman sumber
     * tidak dapat diunduh langsung dari server cloud, lalu tautkan ke peraturan di database lokal bila ada.
     */
    private function inferStatusDariJudulDanTeks(string $judul, string $teksManual, array $input): ?array
    {
        $sumber = trim($judul."\n".$teksManual);
        if ($sumber === '') {
            return null;
        }

        $relKey = null;
        $nomorTarget = null;
        $tahunTarget = null;
        $tentangTarget = '';

        if (preg_match('/\bPerubahan\s+(?:(?:Pertama|Kedua|Ketiga|Keempat|Kelima)\s+)?Atas\s+[^.;\n]*?\bNomor\s+(\d+)\s+Tahun\s+(\d{4})(?:\s+tentang\s+([^\n.;()]+))?/iu', $sumber, $m)) {
            $relKey = 'mengubah';
            $nomorTarget = trim($m[1]);
            $tahunTarget = (int) $m[2];
            $tentangTarget = trim($m[3] ?? '');
        } elseif (preg_match('/\bPencabutan\s+(?:Atas\s+)?[^.;\n]*?\bNomor\s+(\d+)\s+Tahun\s+(\d{4})(?:\s+tentang\s+([^\n.;()]+))?/iu', $sumber, $m)) {
            $relKey = 'mencabut';
            $nomorTarget = trim($m[1]);
            $tahunTarget = (int) $m[2];
            $tentangTarget = trim($m[3] ?? '');
        }

        if ($relKey === null || $nomorTarget === null || ! $tahunTarget) {
            return null;
        }

        $jenis = $input['jenis_peraturan'] ?? 'Perda';
        $wilayah = $input['wilayah'] ?? '';

        // Cari peraturan target di database lokal
        $lokal = Peraturan::where('jenis_peraturan', $jenis)
            ->where('nomor', $nomorTarget)
            ->where('tahun', $tahunTarget)
            ->first();

        $label = $lokal
            ? "{$lokal->jenis_peraturan} No. {$lokal->nomor} Tahun {$lokal->tahun}"
            : "{$jenis} ".($wilayah && $wilayah !== 'Nasional' ? "{$wilayah} " : '')."No. {$nomorTarget} Tahun {$tahunTarget}";

        $judulRelasi = $lokal
            ? $lokal->judul
            : $label.($tentangTarget !== '' ? " tentang {$tentangTarget}" : '');

        $urlRelasi = $lokal ? $lokal->url_dokumen_asli : ($input['url'] ?? '');

        // Ekstrak kalimat keterangan perubahan pasal dari teks manual bila ada
        $keterangan = '';
        if ($teksManual !== '' && preg_match('/((?:Beberapa\s+ketentuan|Ketentuan\s+Pasal)[^.]+(?:\.[^.]+){0,2})/iu', $teksManual, $km)) {
            $keterangan = $this->rapikan($km[1]);
        }

        $entry = [
            'label' => $label,
            'judul' => $judulRelasi,
            'url' => $urlRelasi,
        ];
        if ($keterangan !== '') {
            $entry['keterangan'] = $keterangan;
        }

        return [
            'json' => [$relKey => [$entry]],
            'ringkasan' => "{$relKey}: 1 peraturan",
        ];
    }

    // ------------------------------------------------------------------
    // Pasal (HTML, PDF BPK, dan Teks Polos)
    // ------------------------------------------------------------------

    /**
     * Strategi 1: cari elemen judul/tebal berisi "Pasal N", ambil teks saudara di bawahnya.
     * Strategi 2: bila gagal, pindai seluruh teks halaman baris per baris.
     */
    private function ekstrakPasal(Crawler $c): array
    {
        $hasil = [];

        // Strategi 1
        foreach ($c->filter('h2, h3, h4, h5, b, strong, p') as $node) {
            $nomor = $this->normalisasiNomorPasal(trim($node->textContent));
            if ($nomor === null) {
                continue;
            }

            $bagian = [];
            $sibling = $this->saudaraBerikut($node);
            $iterasi = 0;
            while ($sibling && $iterasi < 30) {
                $iterasi++;
                $teks = $this->rapikan($sibling->textContent);
                if ($this->normalisasiNomorPasal($teks) !== null) {
                    break;
                }
                if ($teks !== '') {
                    $bagian[] = $teks;
                }
                $sibling = $this->saudaraBerikut($sibling);
            }

            $penuh = trim(implode(' ', $bagian));
            if (mb_strlen($penuh) > 10) {
                $hasil[] = ['nomor_pasal' => $nomor, 'nomor_ayat' => '', 'teks_pasal' => $penuh];
            }
        }

        // Strategi 2
        if (count($hasil) === 0) {
            $body = $c->filter('body');
            if ($body->count()) {
                $hasil = $this->ekstrakPasalDariTeks($body->first()->text('', false));
            }
        }

        return array_slice($hasil, 0, 200);
    }

    /**
     * Unduh berkas PDF resmi (/Download/...) dari halaman BPK lalu ekstrak pasalnya.
     */
    private function ekstrakPasalDariPdf(Crawler $c, string $pageUrl): array
    {
        try {
            @ini_set('memory_limit', '512M');
            @set_time_limit(120);

            $pdfUrls = [];
            foreach ($c->filter('a[href^="/Download/"], a[href*="/Download/"]') as $a) {
                $href = trim((string) $a->getAttribute('href'));
                if ($href === '') {
                    continue;
                }
                $pdfUrls[] = str_starts_with($href, 'http')
                    ? $href
                    : 'https://peraturan.bpk.go.id'.(str_starts_with($href, '/') ? '' : '/').$href;
            }

            // Jika tautan itu sendiri langsung menuju PDF
            if (count($pdfUrls) === 0 && preg_match('/\.pdf(\?.*)?$/i', $pageUrl)) {
                $pdfUrls[] = $pageUrl;
            }

            $pdfUrls = array_values(array_unique($pdfUrls));
            if (count($pdfUrls) === 0) {
                return [];
            }

            $body = $this->unduhUrl($pdfUrls[0], 45);
            if ($body === '') {
                return [];
            }

            // Batasi ukuran PDF maksimal ~15 MB agar konsumsi memori tetap aman
            if (strlen($body) < 100 || strlen($body) > 15 * 1024 * 1024 || ! str_contains(substr($body, 0, 1024), '%PDF-')) {
                return [];
            }

            $config = new PdfConfig;
            $config->setRetainImageContent(false);
            $parser = new PdfParser([], $config);
            $pdf = $parser->parseContent($body);

            $pages = $pdf->getPages();
            $maxPages = min(count($pages), 80);
            $teksPdf = '';
            for ($i = 0; $i < $maxPages; $i++) {
                $teksPdf .= "\n".$pages[$i]->getText();
            }

            return $this->ekstrakPasalDariTeks($teksPdf);
        } catch (Throwable $e) {
            logger()->warning('[UrlCrawler] Gagal mengekstrak PDF: '.$e->getMessage());

            return [];
        }
    }

    /**
     * Skor kualitas teks hasil ekstraksi PDF: rasio kata "aneh" terhadap seluruh kata.
     * Kata aneh = huruf bercampur angka ("4dalah"), huruf kecil lalu kapital di tengah kata ("scrlan"→"sCrlan"),
     * atau tanda baca/simbol di tengah kata ("pe;att:ran"). Teks bersih ≈ 0–0,01; OCR buruk ≥ 0,02.
     *
     * @param  array<int, array{teks_pasal: string}>  $pasal
     */
    private function skorTeksBerantakan(array $pasal): float
    {
        $kata = preg_split('/\s+/u', trim(implode(' ', array_column($pasal, 'teks_pasal'))), -1, PREG_SPLIT_NO_EMPTY);
        if (count($kata) < 20) {
            return 0.0;
        }

        $aneh = 0;
        foreach ($kata as $k) {
            if (preg_match('/\p{L}\d|\d\p{L}|\p{Ll}\p{Lu}|\p{L}[.;:^<>|{}\[\]\\\\]\p{L}/u', $k)) {
                $aneh++;
            }
        }

        return $aneh / count($kata);
    }

    /**
     * Cadangan untuk PDF hasil scan gambar: ambil Materi Pokok / Abstrak resmi pada halaman BPK.
     */
    private function ekstrakAbstrakBpk(Crawler $c): array
    {
        try {
            foreach ($c->filter('.card-body, #abstrak .modal-body') as $el) {
                $teks = $this->rapikan($el->textContent);
                if (stripos($teks, 'MATERI POKOK PERATURAN') !== false) {
                    $bersih = trim((string) preg_replace('/^.*?MATERI POKOK PERATURAN\s*(Abstrak)?\s*/iu', '', $teks));
                    $bersih = trim((string) preg_replace('/\s*CATATAN\s*:.*$/iu', '', $bersih));
                    if (mb_strlen($bersih) > 30) {
                        return [[
                            'nomor_pasal' => 'Materi Pokok',
                            'nomor_ayat' => '',
                            'teks_pasal' => $bersih,
                        ]];
                    }
                }
            }
        } catch (Throwable) {
        }

        return [];
    }

    /**
     * Pindai teks polos baris per baris: baris "Pasal N" membuka pasal baru,
     * baris sesudahnya menjadi isi pasal tersebut. Dipakai untuk PDF & teks tempel manual.
     */
    public function ekstrakPasalDariTeks(string $teks): array
    {
        $hasil = [];
        $sudahAda = [];
        $pasalSaatIni = '';
        $baris = [];

        $simpan = function () use (&$hasil, &$sudahAda, &$pasalSaatIni, &$baris) {
            if ($pasalSaatIni !== '' && count($baris) > 0 && ! isset($sudahAda[$pasalSaatIni])) {
                $isi = $this->bersihkanTeksPasal($this->rapikan(implode(' ', $baris)));
                if (mb_strlen($isi) > 15) {
                    $sudahAda[$pasalSaatIni] = true;
                    $hasil[] = ['nomor_pasal' => $pasalSaatIni, 'nomor_ayat' => '', 'teks_pasal' => $isi];
                }
            }
        };

        foreach (preg_split('/\r\n|\r|\n/', $teks) as $mentah) {
            // Buang karakter kontrol non-cetak (biasa muncul dari font PDF rusak/terenkripsi)
            $line = trim((string) preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]+/u', '', $mentah));
            if ($line === '' || $this->barisRusakPdf($line)) {
                continue;
            }

            // Hentikan pembacaan jika sudah masuk bagian Penjelasan, Lampiran, atau blok pengesahan di akhir dokumen
            if (preg_match('/^(PENJELASAN(\s+ATAS)?|LAMPIRAN(\s+[IVXLCDM\d]+)?\b|(Agar\s+setiap\s+orang\s+mengetahuinya|Ditetapkan\s+di\s+|Diundangkan\s+di\s+))/iu', $line)) {
                if (preg_match('/^Agar\s+setiap\s+orang\s+mengetahuinya/iu', $line) && $pasalSaatIni !== '') {
                    // Jika kalimat "Agar setiap orang..." masih satu baris dengan akhir kalimat pengundangan, ambil kalimat sebelum blok tanda tangan
                    $potong = preg_split('/\b(Ditetapkan\s+di|Diundangkan\s+di)\b/iu', $line)[0] ?? '';
                    if (trim($potong) !== '') {
                        $baris[] = trim($potong);
                    }
                }
                $simpan();
                $pasalSaatIni = '';
                $baris = [];
                if (preg_match('/^(PENJELASAN(\s+ATAS)?|LAMPIRAN\b)/iu', $line)) {
                    break;
                }
                continue;
            }

            // Abaikan header/footer halaman PDF Setneg / Lembaran Negara
            if ($this->barisHeaderAtauFooterPdf($line)) {
                continue;
            }

            // Jika bertemu judul BAB / Bagian / Paragraf baru, tutup pasal sebelumnya
            if (preg_match('/^(BAB\s+[IVXLCDM]+|Bagian\s+(Kesatu|Kedua|Ketiga|Keempat|Kelima|Keenam|Ketujuh|Kedelapan|Kesembilan|Kesepuluh|Kesebelas|Keduabelas)|Paragraf\s+\d+)\b/iu', $line)) {
                $simpan();
                $pasalSaatIni = '';
                $baris = [];
                continue;
            }

            $nomorPasal = $this->normalisasiNomorPasal($line);
            if ($nomorPasal !== null) {
                $simpan();
                $pasalSaatIni = $nomorPasal;
                $baris = [];
            } elseif ($pasalSaatIni !== '') {
                $baris[] = $line;
            }
        }
        $simpan();

        return array_slice($hasil, 0, 200);
    }

    private function normalisasiNomorPasal(string $line): ?string
    {
        if (! preg_match(self::PASAL_PATTERN, $line, $m)) {
            return null;
        }
        $angka = strtoupper($m[1]);
        if ($angka === 'I' || $angka === 'L') {
            $angka = '1';
        }

        return 'Pasal '.$angka;
    }

    private function barisHeaderAtauFooterPdf(string $line): bool
    {
        return (bool) preg_match(
            '/^(\-\s*\d+\s*\-|SK\s+No\s+[0-9A-Z\s]+|PRES\s*I\s*DEN|PRE\s*S\s*I\s*DEN|REPUBLIK\s+INDONES[IT]A|SALINAN|LEMBARAN\s+(NEGARA|DAERAH)|TAMBAHAN\s+LEMBARAN\s+(NEGARA|DAERAH)|NOREG\s+PERATURAN|.*\.\s*\.\s*\.)$/iu',
            $line
        );
    }

    /**
     * Deteksi baris hasil ekstraksi font PDF yang rusak / terenkripsi
     * (misal deretan token "19L1<T 81GT +9NL>6OM>T" atau dominan simbol aneh).
     */
    private function barisRusakPdf(string $line): bool
    {
        if (preg_match('/([A-Z0-9]{2,}[<>+*#@$%&][A-Z0-9<>+*#@$%&;:\'\-]{2,}\s*){3,}/', $line)) {
            return true;
        }

        $len = mb_strlen($line);
        if ($len > 20) {
            $simbolAneh = preg_match_all('/[<>*#@$%&^~`|\\\\]/', $line);
            if ($simbolAneh !== false && ($simbolAneh / $len) > 0.12) {
                return true;
            }
        }

        return false;
    }

    /**
     * Bersihkan isi teks pasal dari blok tanda tangan/pengundangan di akhir pasal penutup,
     * karakter kontrol non-cetak, serta sisa kata sambung halaman di ujung pasal.
     */
    public function bersihkanTeksPasal(string $isi): string
    {
        // 1. Buang karakter kontrol non-cetak
        $isi = (string) preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]+/u', '', $isi);

        // 2. Jika pasal penutup memuat kalimat "Agar setiap orang mengetahuinya...",
        //    potong tepat setelah kalimat "Lembaran Negara/Daerah ... ." (sebelum Diundangkan / Ditetapkan)
        if (preg_match('/^(.*?\bAgar\s+(?:setiap|semua)\s+orang\s+(?:dapat\s+)?mengetahuinya\b.*?Lembaran\s+(?:Negara|Daerah)\s+[^.]+?\.)\s*(?:Diundangkan|Ditetapkan|Disahkan|LAMPIRAN|PENJELASAN|\bNOREG\b).*$/isu', $isi, $m)) {
            $isi = $m[1];
        } else {
            // Atau potong langsung mulai dari "Ditetapkan di ..." / "Diundangkan di ..." di akhir pasal
            $isi = (string) preg_replace('/\s*\b(Ditetapkan\s+di\s+|Diundangkan\s+di\s+|NOREG\s+PERATURAN\s+).*$/isu', '', $isi);
        }

        // 3. Buang ekor teks yang rusak (gibberish PDF font encoding) bila masih tersisa
        $isi = (string) preg_replace('/\s*([A-Z0-9]{2,}[<>+*#@$%&][A-Z0-9<>+*#@$%&;:\'\-]{1,}\s*){2,}.*$/su', '', $isi);

        // 4. Bersihkan sisa kata sambung halaman di ujung pasal (misal "Pasal" atau "Paragraf")
        $isi = trim((string) preg_replace('/\s+(Pasal|Paragraf|Bagian|BAB)\s*$/iu', '', $isi));

        return $this->rapikan($isi);
    }

    // ------------------------------------------------------------------
    // Status peraturan (khusus halaman BPK)
    // ------------------------------------------------------------------

    /** @return array{json: array, ringkasan: string}|null */
    private function ambilStatus(Crawler $c): ?array
    {
        try {
            $hasil = [];

            foreach ($c->filter('div.col-12.fw-semibold.bg-light-primary') as $labelEl) {
                $label = strtolower(trim(preg_replace('/\s*:\s*$/', '', trim($labelEl->textContent))));
                $key = self::LABEL_TO_KEY[$label] ?? null;
                if (! $key) {
                    continue;
                }

                // Struktur BPK: .row (label) lalu .row berikutnya berisi daftar <li>
                $barisLabel = $this->leluhurDenganKelas($labelEl, 'row');
                $barisItem = $barisLabel ? $this->saudaraBerikut($barisLabel) : null;
                if (! $barisItem || ! $this->punyaKelas($barisItem, 'row')) {
                    continue;
                }

                $xpath = new DOMXPath($barisItem->ownerDocument);
                $items = [];

                foreach ($xpath->query(".//li[contains(concat(' ', normalize-space(@class), ' '), ' mb-4 ')]", $barisItem) as $li) {
                    $a = $xpath->query('.//a', $li)->item(0);
                    $href = $a ? $a->getAttribute('href') : '';
                    $judulLink = $a ? trim($a->textContent) : '';
                    $fullUrl = str_starts_with($href, 'http') ? $href : ($href !== '' ? 'https://peraturan.bpk.go.id'.$href : '');

                    // Keterangan = <span> tepat setelah <br>
                    $keterangan = '';
                    $spanSetelahBr = $xpath->query('.//br/following-sibling::*[1][self::span]', $li)->item(0);
                    if ($spanSetelahBr) {
                        $keterangan = trim($spanSetelahBr->textContent);
                    } else {
                        foreach ($xpath->query(".//span[not(contains(concat(' ', normalize-space(@class), ' '), ' text-muted '))]", $li) as $span) {
                            $t = trim($span->textContent);
                            if ($t !== '' && $t !== $judulLink) {
                                $keterangan = $t;
                            }
                        }
                    }

                    // Judul bersih: salin <li>, buang keterangan & <br>
                    $salinan = $li->cloneNode(true);
                    $xpSalinan = new DOMXPath($li->ownerDocument);
                    foreach (iterator_to_array($xpSalinan->query('.//br/following-sibling::*[1][self::span]', $salinan)) as $n) {
                        $n->parentNode?->removeChild($n);
                    }
                    foreach (iterator_to_array($xpSalinan->query('.//br', $salinan)) as $n) {
                        $n->parentNode?->removeChild($n);
                    }
                    $judul = $this->rapikan($salinan->textContent);

                    $item = [
                        'label' => $judulLink !== '' ? $judulLink : $judul,
                        'judul' => $judul !== '' ? $judul : $judulLink,
                        'url' => $fullUrl,
                    ];
                    if ($keterangan !== '') {
                        $item['keterangan'] = $keterangan;
                    }
                    if ($judulLink !== '' || $fullUrl !== '' || $judul !== '') {
                        $items[] = $item;
                    }
                }

                if (count($items) > 0) {
                    $hasil[$key] = $items;
                }
            }

            if (count($hasil) === 0) {
                return null;
            }

            $ringkasan = collect($hasil)
                ->map(fn ($items, $k) => str_replace('_', ' ', $k).': '.count($items).' peraturan')
                ->implode('; ');

            return ['json' => $hasil, 'ringkasan' => $ringkasan];
        } catch (Throwable) {
            return null;
        }
    }

    // ------------------------------------------------------------------
    // Alat bantu DOM
    // ------------------------------------------------------------------

    private function rapikan(string $teks): string
    {
        return trim(preg_replace('/\s+/u', ' ', $teks));
    }

    /** Elemen saudara berikutnya (melewati teks/komentar). */
    private function saudaraBerikut(DOMNode $node): ?DOMElement
    {
        $n = $node->nextSibling;
        while ($n && ! ($n instanceof DOMElement)) {
            $n = $n->nextSibling;
        }

        return $n;
    }

    private function punyaKelas(DOMNode $node, string $kelas): bool
    {
        return $node instanceof DOMElement
            && in_array($kelas, preg_split('/\s+/', trim($node->getAttribute('class'))), true);
    }

    private function leluhurDenganKelas(DOMNode $node, string $kelas): ?DOMElement
    {
        $n = $node;
        while ($n) {
            if ($this->punyaKelas($n, $kelas)) {
                return $n;
            }
            $n = $n->parentNode;
        }

        return null;
    }
}
