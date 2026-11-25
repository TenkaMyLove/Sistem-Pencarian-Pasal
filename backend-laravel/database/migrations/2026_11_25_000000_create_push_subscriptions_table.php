<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/*
| Web Push (notifikasi jadwal rapat walau browser/PWA tertutup):
|  - push_subscriptions : "alamat" push tiap perangkat/browser pegawai yang mengaktifkan notifikasi
|  - jadwal_rapat_harmonisasi.notifikasi_terkirim_tanggal : penanda agar push tiap rapat hanya dikirim sekali
*/

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('push_subscriptions')) {
            Schema::create('push_subscriptions', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('pengguna_id')->nullable()->index();
                $table->text('endpoint');
                $table->string('endpoint_hash', 64)->unique(); // sha256(endpoint) — endpoint terlalu panjang untuk di-index
                $table->string('public_key', 255)->nullable();  // p256dh
                $table->string('auth_token', 255)->nullable();  // auth
                $table->string('content_encoding', 20)->default('aes128gcm');
                $table->string('user_agent', 255)->nullable();
                $table->timestamps();
            });
        }

        if (Schema::hasTable('jadwal_rapat_harmonisasi') && ! Schema::hasColumn('jadwal_rapat_harmonisasi', 'notifikasi_terkirim_tanggal')) {
            Schema::table('jadwal_rapat_harmonisasi', function (Blueprint $table) {
                $table->date('notifikasi_terkirim_tanggal')->nullable();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('push_subscriptions');

        if (Schema::hasColumn('jadwal_rapat_harmonisasi', 'notifikasi_terkirim_tanggal')) {
            Schema::table('jadwal_rapat_harmonisasi', function (Blueprint $table) {
                $table->dropColumn('notifikasi_terkirim_tanggal');
            });
        }
    }
};
