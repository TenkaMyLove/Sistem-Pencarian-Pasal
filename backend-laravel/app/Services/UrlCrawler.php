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

    /** Label pada halaman BPK  =>  kunci di kolom status_detail_json */
    private const LABEL_TO_KEY = [
        'mencabut' => 'mencabut',
        'mencabut sebagian' => 'mencabut_sebagian',
        'mencabut sebagian dengan' => 'mencabut_sebagian_dengan',
        'diubah' => 'diubah_dengan',
        'diubah dengan' => 'diubah_dengan',
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

    /**
     * @param  array  $input  url, jenis_peraturan, nomor, tahun, judul, wilayah, sektor, teks_manual (opsional)
     */
    public function crawl(array $input): array
    {
        $url = $input['url'];
        $manualJudul = trim($input['judul'] ?? '');

        $statusTautan = 'tautan_bermasalah';
        $finalJudul = $manualJudul !== '' ? $manualJudul : $url;
        $parsedPasal = [];
        $statusJson = [];
        $statusDetail = '';
        $statusPeraturan = 'berlaku';
        $crawler = null;

        // 1. Unduh halaman
        $html = '';
        try {
            $response = Http::withoutVerifying()->withHeaders([
                'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
                'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                'Accept-Language' => 'id-ID,id;q=0.9,en-US;q=0.8',
            ])->timeout(30)->get($url);

            if ($response->successful()) {
                $statusTautan = 'normal';
                $html = $response->body();
            }
        } catch (Throwable $e) {
            logger()->warning('[UrlCrawler] Gagal mengunduh '.$url.': '.$e->getMessage());
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

            $statusPeraturan = $this->tentukanStatus($crawler, $statusJson);
        }

        // Cadangan 1: pengguna menempel teks manual pada form
        $teksManual = trim($input['teks_manual'] ?? '');
        if (count($parsedPasal) === 0 && $teksManual !== '') {
            $parsedPasal = $this->ekstrakPasalDariTeks($teksManual);
        }

        // Cadangan 2: unduh berkas PDF resmi dari halaman BPK dan ekstrak pasalnya
        if (count($parsedPasal) === 0 && $crawler !== null) {
            $parsedPasal = $this->ekstrakPasalDariPdf($crawler, $url);
        }

        // Cadangan 3: jika PDF merupakan hasil pindaian gambar (0 pasal teks), gunakan Abstrak/Materi Pokok resmi BPK
        if (count($parsedPasal) === 0 && $crawler !== null) {
            $parsedPasal = $this->ekstrakAbstrakBpk($crawler);
        }

        // 3. Simpan ke database (satu transaksi: gagal satu = batal semua)
        try {
            $peraturan = DB::transaction(function () use ($input, $finalJudul, $statusPeraturan, $statusDetail, $statusJson, $statusTautan, $url, $parsedPasal) {
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

    private function tentukanStatus(Crawler $c, array $statusJson): string
    {
        if (! empty($statusJson['dicabut_dengan'])) {
            return 'dicabut';
        }

        $statusMeta = strtolower($this->ambilMetadataBpk($c, 'Status'));
        if (str_contains($statusMeta, 'tidak berlaku') || str_contains($statusMeta, 'dicabut')) {
            return 'dicabut';
        }

        if (! empty($statusJson['diubah_dengan']) || ! empty($statusJson['dicabut_sebagian_dengan'])) {
            return 'diubah';
        }

        return 'berlaku';
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

            $res = Http::withoutVerifying()->withHeaders([
                'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            ])->timeout(45)->get($pdfUrls[0]);

            if (! $res->successful()) {
                return [];
            }

            $body = $res->body();
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
