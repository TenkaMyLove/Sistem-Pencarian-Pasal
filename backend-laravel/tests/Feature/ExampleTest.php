<?php

namespace Tests\Feature;

use App\Models\JadwalRapat;
use App\Models\Pasal;
use App\Models\Peraturan;
use App\Services\UrlCrawler;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

/**
 * Pengujian otomatis (Feature Test) untuk aplikasi P3H Kemenkum Kalsel.
 * Jalankan dengan: php artisan test
 * Catatan: pengujian ini memakai database sementara di memori (lihat phpunit.xml),
 * sehingga data asli di MySQL tidak pernah tersentuh.
 */
class ExampleTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);

        $perda = Peraturan::create([
            'jenis_peraturan' => 'Perda',
            'nomor' => '6',
            'tahun' => 2023,
            'judul' => 'Peraturan Daerah Provinsi Kalimantan Selatan Nomor 6 Tahun 2023 tentang Rencana Tata Ruang Wilayah',
            'status' => 'berlaku',
            'status_detail' => 'mencabut: 1 peraturan',
            'status_detail_json' => [
                'mencabut' => [[
                    'label' => 'Perda Prov. Kalimantan Selatan No. 9 Tahun 2015',
                    'judul' => 'Perda No. 9 Tahun 2015 tentang RTRW',
                    'url' => 'https://peraturan.bpk.go.id',
                ]],
            ],
            'wilayah' => 'Kalimantan Selatan',
            'sektor' => 'Tata Ruang',
            'url_dokumen_asli' => 'https://peraturan.bpk.go.id',
            'status_tautan' => 'normal',
        ]);

        Pasal::create([
            'peraturan_id' => $perda->id,
            'nomor_pasal' => 'Pasal 1',
            'nomor_ayat' => 'Ayat (1)',
            'teks_pasal' => 'Dalam Peraturan Daerah ini yang dimaksud dengan tata ruang adalah wujud struktur ruang.',
        ]);

        JadwalRapat::create([
            'jenis_rancangan' => 'Ranperda',
            'tentang' => 'Rencana Tata Ruang Wilayah',
            'tanggal' => '2026-11-15',
            'jam' => '09:00:00',
            'nama_kompilator' => 'Eryck, Kiki',
            'tim_pokja' => 'Pokja 1',
            'dibuat_oleh' => 'Pengelola',
        ]);
    }

    public function test_halaman_utama_mengarahkan_ke_pencarian(): void
    {
        $this->get('/')->assertRedirect('/pencarian');
    }

    public function test_tamu_bisa_membuka_pencarian_dan_status_modal(): void
    {
        $peraturan = Peraturan::first();

        $this->get('/pencarian')
            ->assertOk()
            ->assertSee('Pencarian Pasal Peraturan')
            ->assertSee('Rencana Tata Ruang Wilayah');

        $this->get('/search-results?q=tata+ruang')
            ->assertOk()
            ->assertSee('<mark>tata</mark>', false);

        $this->get("/pencarian/status-modal/{$peraturan->id}")
            ->assertOk()
            ->assertSee('Detil Status Peraturan')
            ->assertSee('Perda No. 9 Tahun 2015 tentang RTRW');
    }

    public function test_hak_akses_peran_berfungsi(): void
    {
        // Tamu tidak boleh membuka jadwal, tambah peraturan, atau kelola akun
        $this->get('/jadwal')->assertRedirect('/pencarian');
        $this->get('/tambah-peraturan')->assertRedirect('/login');
        $this->get('/kelola-akun')->assertRedirect('/login');

        // Pengelola boleh membuka jadwal, tambah peraturan, dan kelola akun (reset kata sandi)
        $sesiPengelola = ['user' => ['id' => 1, 'username' => 'Pengelola', 'peran' => 'Pengelola']];
        $this->withSession($sesiPengelola)->get('/jadwal')->assertOk()->assertSee('Agenda Rapat Harmonisasi');
        $this->withSession($sesiPengelola)->get('/tambah-peraturan')->assertOk()->assertSee('Tambah Peraturan via Tautan');
        $this->withSession($sesiPengelola)->get('/kelola-akun')->assertOk()->assertSee('Kelola Akun Pengguna');

        // Perancang boleh membuka jadwal, tetapi ditolak di tambah peraturan & kelola akun
        $sesiPerancang = ['user' => ['id' => 2, 'username' => 'Perancang', 'peran' => 'Perancang']];
        $this->withSession($sesiPerancang)->get('/jadwal')->assertOk()->assertSee('Agenda Rapat Harmonisasi');
        $this->withSession($sesiPerancang)->get('/tambah-peraturan')->assertStatus(403);
        $this->withSession($sesiPerancang)->get('/kelola-akun')->assertStatus(403);
    }

    public function test_endpoint_api_utama_merespon_json_sesuai_kontrak(): void
    {
        $this->getJson('/api/health')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('status', 'ok');

        $this->postJson('/api/auth/login', ['username' => 'Pengelola', 'kata_sandi' => 'pengelola123'])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('user.peran', 'Pengelola');

        $this->getJson('/api/search?q=ruang')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.totalCount', 1);

        $this->getJson('/api/jadwal')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data');

        $this->getJson('/api/admin/users')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(2, 'data');
    }

    public function test_crawler_melengkapi_status_relasi_dari_db_lokal_saat_akses_bpk_diblokir_cloud(): void
    {
        Http::fake(['*' => Http::response('Forbidden', 403)]);

        Peraturan::create([
            'jenis_peraturan' => 'UU',
            'nomor' => '23',
            'tahun' => 2014,
            'judul' => 'Undang-Undang Nomor 23 Tahun 2014 tentang Pemerintahan Daerah',
            'status' => 'berlaku',
            'status_detail' => 'mencabut: 3 peraturan',
            'status_detail_json' => [
                'mencabut' => [
                    [
                        'url' => 'https://peraturan.bpk.go.id/Details/39043/uu-no-12-tahun-2008',
                        'judul' => 'UU No. 12 Tahun 2008 tentang Perubahan Kedua atas Undang-Undang Nomor 32 Tahun 2004 tentang Pemerintahan Daerah',
                        'label' => 'UU No. 12 Tahun 2008',
                    ],
                    [
                        'url' => 'https://peraturan.bpk.go.id/Details/40250/uu-no-8-tahun-2005',
                        'judul' => 'UU No. 8 Tahun 2005 tentang Penetapan Peraturan Pemerintah Pengganti Undang-Undang Nomor 3 Tahun 2005 tentang Perubahan atas Undang-Undang Nomor 32 Tahun 2004 tentang Pemerintahan Daerah Menjadi Undang-Undang',
                        'label' => 'UU No. 8 Tahun 2005',
                    ],
                    [
                        'url' => 'https://peraturan.bpk.go.id/Details/40768/uu-no-32-tahun-2004',
                        'judul' => 'UU No. 32 Tahun 2004 tentang Pemerintahan Daerah',
                        'label' => 'UU No. 32 Tahun 2004',
                    ],
                ],
            ],
            'wilayah' => 'Nasional',
            'sektor' => 'Otonomi Daerah',
            'url_dokumen_asli' => 'https://peraturan.bpk.go.id/Details/38685/uu-no-23-tahun-2014',
            'status_tautan' => 'normal',
        ]);

        Peraturan::create([
            'jenis_peraturan' => 'UU',
            'nomor' => '6',
            'tahun' => 2014,
            'judul' => 'Undang-Undang Nomor 6 Tahun 2014 tentang Desa',
            'status' => 'berlaku',
            'status_detail' => 'mencabut sebagian: 1 peraturan',
            'status_detail_json' => [
                'mencabut_sebagian' => [[
                    'url' => 'https://peraturan.bpk.go.id/Details/40768/uu-no-32-tahun-2004',
                    'judul' => 'UU No. 32 Tahun 2004 tentang Pemerintahan Daerah',
                    'label' => 'UU No. 32 Tahun 2004',
                    'keterangan' => 'Pasal 200 sampai dengan Pasal 216 Undang-Undang Nomor 32 Tahun 2004 tentang Pemerintahan Daerah dicabut.',
                ]],
            ],
            'wilayah' => 'Nasional',
            'sektor' => 'Otonomi Daerah',
            'url_dokumen_asli' => 'https://peraturan.bpk.go.id/Details/38582/uu-no-6-tahun-2014',
            'status_tautan' => 'normal',
        ]);

        $hasil = app(UrlCrawler::class)->crawl([
            'url' => 'https://peraturan.bpk.go.id/Details/40768/uu-no-32-tahun-2004',
            'jenis_peraturan' => 'UU',
            'nomor' => '32',
            'tahun' => 2004,
            'judul' => '',
            'wilayah' => 'Nasional',
            'sektor' => 'Otonomi Daerah',
        ]);

        $this->assertTrue($hasil['ok']);
        $uu32 = Peraturan::findOrFail($hasil['peraturan_id']);
        $this->assertSame('Undang-Undang Nomor 32 Tahun 2004 tentang Pemerintahan Daerah', $uu32->judul);
        $this->assertSame('dicabut', $uu32->status);
        $this->assertNotEmpty($uu32->status_detail_json['dicabut_dengan'] ?? []);
        $this->assertNotEmpty($uu32->status_detail_json['dicabut_sebagian_dengan'] ?? []);
        $this->assertCount(2, $uu32->status_detail_json['diubah_dengan'] ?? []);
        $this->assertNotEmpty($uu32->status_detail_json['mencabut'] ?? []);
    }
}
