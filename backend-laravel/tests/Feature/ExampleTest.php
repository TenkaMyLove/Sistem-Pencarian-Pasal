<?php

namespace Tests\Feature;

use App\Models\JadwalRapat;
use App\Models\Pasal;
use App\Models\Peraturan;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
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
}
