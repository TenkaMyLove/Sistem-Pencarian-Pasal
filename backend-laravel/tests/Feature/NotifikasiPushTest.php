<?php

namespace Tests\Feature;

use App\Models\JadwalRapat;
use App\Models\Pengguna;
use App\Models\PushSubscription;
use App\Services\JadwalPushService;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Minishlink\WebPush\VAPID;
use Tests\TestCase;

/**
 * Web Push jadwal rapat: langganan perangkat & pengiriman notifikasi.
 * Catatan Windows: bila muncul "Unable to create the key", jalankan dengan
 * OPENSSL_CONF=<folder PHP>\extras\ssl\openssl.cnf
 */
class NotifikasiPushTest extends TestCase
{
    use RefreshDatabase;

    private array $sesiPerancang;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);

        $perancang = Pengguna::where('peran', 'Perancang')->firstOrFail();
        $this->sesiPerancang = ['user' => ['id' => $perancang->id, 'username' => $perancang->username, 'peran' => 'Perancang']];

        $vapid = VAPID::createVapidKeys();
        config(['webpush.public_key' => $vapid['publicKey'], 'webpush.private_key' => $vapid['privateKey'], 'webpush.subject' => 'https://p3h.example.com']);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    /** Kunci p256dh asli (titik EC P-256 tak terkompresi) agar payload bisa dienkripsi. */
    private function langgananPalsu(string $endpoint): array
    {
        $details = openssl_pkey_get_details(openssl_pkey_new(['curve_name' => 'prime256v1', 'private_key_type' => OPENSSL_KEYTYPE_EC]));
        $b64 = fn (string $s) => rtrim(strtr(base64_encode($s), '+/', '-_'), '=');

        return [
            'endpoint' => $endpoint,
            'keys' => ['p256dh' => $b64("\x04".$details['ec']['x'].$details['ec']['y']), 'auth' => $b64(random_bytes(16))],
            'contentEncoding' => 'aes128gcm',
        ];
    }

    private function rapatHariIni(): JadwalRapat
    {
        return JadwalRapat::create([
            'jenis_rancangan' => 'Ranperda', 'tentang' => 'Ketertiban Umum',
            'tanggal' => now('Asia/Makassar')->toDateString(), 'jam' => '09.30 WITA',
            'nama_kompilator' => 'x', 'tim_pokja' => 'Pokja I', 'dibuat_oleh' => 'tes',
        ]);
    }

    public function test_pegawai_bisa_berlangganan_dan_berhenti(): void
    {
        $data = $this->langgananPalsu('https://fcm.googleapis.com/fcm/send/abc');

        $this->withSession($this->sesiPerancang)->postJson('/notifikasi/langganan', $data)->assertOk()->assertJson(['success' => true]);
        // Kirim ulang (pindah halaman) tidak membuat baris ganda
        $this->withSession($this->sesiPerancang)->postJson('/notifikasi/langganan', $data)->assertOk();

        $this->assertSame(1, PushSubscription::count());
        $this->assertSame($this->sesiPerancang['user']['id'], PushSubscription::first()->pengguna_id);

        $this->postJson('/notifikasi/berhenti', ['endpoint' => $data['endpoint']])->assertOk();
        $this->assertSame(0, PushSubscription::count());
    }

    public function test_tamu_tidak_bisa_berlangganan_dan_endpoint_wajib_https(): void
    {
        $this->postJson('/notifikasi/langganan', $this->langgananPalsu('https://fcm.googleapis.com/fcm/send/abc'))->assertRedirect('/pencarian');
        $this->withSession($this->sesiPerancang)->postJson('/notifikasi/langganan', $this->langgananPalsu('http://evil.test/x'))->assertStatus(422);
        $this->assertSame(0, PushSubscription::count());
    }

    public function test_tidak_mengirim_sebelum_jam_kerja_atau_tanpa_vapid(): void
    {
        $rapat = $this->rapatHariIni();

        Carbon::setTestNow(now('Asia/Makassar')->setTime(7, 59));
        $this->assertSame('belum jam kerja', app(JadwalPushService::class)->kirimHariIni()['status']);

        Carbon::setTestNow(now('Asia/Makassar')->setTime(8, 0));
        config(['webpush.private_key' => '']);
        $this->assertSame('VAPID belum diatur', app(JadwalPushService::class)->kirimHariIni()['status']);

        $this->assertNull($rapat->fresh()->notifikasi_terkirim_tanggal);
    }

    public function test_tiap_rapat_hanya_ditandai_sekali_per_hari_dan_rapat_lain_hari_diabaikan(): void
    {
        Carbon::setTestNow(now('Asia/Makassar')->setTime(8, 1));
        $rapat = $this->rapatHariIni();
        $besok = JadwalRapat::create(['tanggal' => now('Asia/Makassar')->addDay()->toDateString()] + $rapat->only([
            'jenis_rancangan', 'tentang', 'jam', 'nama_kompilator', 'tim_pokja', 'dibuat_oleh',
        ]));

        $hasil = app(JadwalPushService::class)->kirimHariIni();
        $this->assertSame(1, $hasil['rapat']);
        $this->assertSame(now('Asia/Makassar')->toDateString(), $rapat->fresh()->notifikasi_terkirim_tanggal->toDateString());
        $this->assertNull($besok->fresh()->notifikasi_terkirim_tanggal);

        $this->assertSame(0, app(JadwalPushService::class)->kirimHariIni()['rapat']);
    }

    public function test_bila_semua_pengiriman_gagal_rapat_dicoba_lagi(): void
    {
        Carbon::setTestNow(now('Asia/Makassar')->setTime(8, 1));
        $rapat = $this->rapatHariIni();

        // Port tertutup -> koneksi ditolak (gagal sementara, bukan langganan kedaluwarsa)
        $data = $this->langgananPalsu('https://127.0.0.1:9/push');
        $this->withSession($this->sesiPerancang)->postJson('/notifikasi/langganan', $data)->assertOk();

        $hasil = app(JadwalPushService::class)->kirimHariIni();

        $this->assertSame(1, $hasil['gagal']);
        $this->assertSame('gagal, dicoba lagi', $hasil['status']);
        $this->assertNull($rapat->fresh()->notifikasi_terkirim_tanggal);
        $this->assertSame(1, PushSubscription::count());
    }

    public function test_jadwal_hari_ini_tetap_tampil_setelah_jam_rapat_lewat(): void
    {
        Carbon::setTestNow(now('Asia/Makassar')->setTime(16, 0));
        $this->rapatHariIni(); // jam 09.30 sudah lewat

        $this->getJson('/api/jadwal/hari-ini')->assertOk()->assertJsonCount(1, 'data')
            ->assertJsonMissingPath('data.0.notifikasi_terkirim_tanggal');
    }
}
