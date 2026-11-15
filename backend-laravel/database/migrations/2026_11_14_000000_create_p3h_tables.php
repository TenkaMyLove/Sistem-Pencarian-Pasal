<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/*
| Migration = "resep" untuk membuat tabel database lewat kode PHP.
| Dijalankan dengan: php artisan migrate
|
| Catatan: setiap tabel dicek dengan Schema::hasTable() agar migration ini
| aman dijalankan pada database lama (hasil migrasi dari Node.js) tanpa
| menimpa data yang sudah ada.
*/

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('peraturan')) {
            Schema::create('peraturan', function (Blueprint $table) {
                $table->id();
                $table->string('jenis_peraturan', 100);
                $table->string('nomor', 50);
                $table->integer('tahun');
                $table->text('judul');
                $table->string('status', 50)->default('berlaku'); // berlaku, dicabut, diubah
                $table->text('status_detail')->nullable();
                $table->json('status_detail_json')->nullable();   // relasi antar peraturan
                $table->string('wilayah', 150)->default('Nasional');
                $table->string('sektor', 100)->nullable();
                $table->text('url_dokumen_asli');
                $table->string('status_tautan', 50)->default('normal'); // normal, tautan_bermasalah
                $table->dateTime('tanggal_diambil')->useCurrent();
                $table->dateTime('tanggal_dicek_terakhir')->useCurrent();

                $table->index('jenis_peraturan', 'idx_peraturan_jenis');
                $table->index('tahun', 'idx_peraturan_tahun');
                $table->index('wilayah', 'idx_peraturan_wilayah');
                $table->index('sektor', 'idx_peraturan_sektor');
            });
        }

        if (! Schema::hasTable('pasal')) {
            Schema::create('pasal', function (Blueprint $table) {
                $table->id();
                $table->foreignId('peraturan_id')->constrained('peraturan')->cascadeOnDelete();
                $table->string('nomor_pasal', 50);
                $table->string('nomor_ayat', 50)->nullable();
                $table->text('teks_pasal');

                $table->index('nomor_pasal', 'idx_pasal_nomor_pasal');
            });
        }

        if (! Schema::hasTable('sumber_scraping')) {
            Schema::create('sumber_scraping', function (Blueprint $table) {
                $table->id();
                $table->string('nama_sumber', 150);
                $table->text('url_dasar');
                $table->dateTime('jadwal_crawl_terakhir')->nullable();
                $table->string('jadwal_crawl_status_terakhir', 50)->default('belum_pernah');
            });
        }

        if (! Schema::hasTable('antrian_scraping')) {
            Schema::create('antrian_scraping', function (Blueprint $table) {
                $table->id();
                $table->foreignId('sumber_scraping_id')->constrained('sumber_scraping')->cascadeOnDelete();
                $table->string('status_batch', 50)->default('menunggu');
                $table->integer('halaman_terakhir_diproses')->default(0);
            });
        }

        if (! Schema::hasTable('log_kegagalan_crawl')) {
            Schema::create('log_kegagalan_crawl', function (Blueprint $table) {
                $table->id();
                $table->foreignId('sumber_scraping_id')->constrained('sumber_scraping')->cascadeOnDelete();
                $table->dateTime('waktu_kegagalan')->useCurrent();
                $table->text('pesan_error');
            });
        }

        if (! Schema::hasTable('pengguna')) {
            Schema::create('pengguna', function (Blueprint $table) {
                $table->id();
                $table->string('username', 50)->unique();
                $table->string('kata_sandi_terenkripsi', 255);
                $table->string('peran', 50); // Admin, Pengelola, Perancang
                $table->string('diubah_terakhir_oleh', 50)->nullable();
                $table->dateTime('tanggal_kata_sandi_diubah')->useCurrent();
            });
        }

        if (! Schema::hasTable('jadwal_rapat_harmonisasi')) {
            Schema::create('jadwal_rapat_harmonisasi', function (Blueprint $table) {
                $table->id();
                $table->string('jenis_rancangan', 50);
                $table->text('tentang');
                $table->date('tanggal')->index('idx_jadwal_tanggal');
                $table->time('jam');
                $table->string('nama_kompilator', 150);
                $table->string('tim_pokja', 50);
                $table->string('dibuat_oleh', 50);
                $table->timestamps();
            });
        }

        // FULLTEXT index (khusus MySQL) untuk pencarian cepat — hanya dibuat jika belum ada
        $this->addFulltext('peraturan', 'judul', 'idx_peraturan_judul_ft');
        $this->addFulltext('pasal', 'teks_pasal', 'idx_pasal_teks_ft');
    }

    public function down(): void
    {
        Schema::dropIfExists('jadwal_rapat_harmonisasi');
        Schema::dropIfExists('pengguna');
        Schema::dropIfExists('log_kegagalan_crawl');
        Schema::dropIfExists('antrian_scraping');
        Schema::dropIfExists('sumber_scraping');
        Schema::dropIfExists('pasal');
        Schema::dropIfExists('peraturan');
    }

    private function addFulltext(string $table, string $column, string $indexName): void
    {
        if (Schema::getConnection()->getDriverName() !== 'mysql') {
            return;
        }

        $exists = collect(Schema::getIndexes($table))->contains(fn ($index) => $index['name'] === $indexName);

        if (! $exists) {
            Schema::table($table, fn (Blueprint $t) => $t->fullText($column, $indexName));
        }
    }
};
