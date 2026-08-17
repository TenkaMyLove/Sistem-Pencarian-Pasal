-- P3H Kemenkum Kalsel Database Schema
-- Target: PostgreSQL 10.23

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

DROP TABLE IF EXISTS log_kegagalan_crawl CASCADE;
DROP TABLE IF EXISTS antrian_scraping CASCADE;
DROP TABLE IF EXISTS sumber_scraping CASCADE;
DROP TABLE IF EXISTS pasal CASCADE;
DROP TABLE IF EXISTS peraturan CASCADE;
DROP TABLE IF EXISTS jadwal_rapat_harmonisasi CASCADE;
DROP TABLE IF EXISTS pengguna CASCADE;

-- 1. Table: peraturan (Regulations)
CREATE TABLE peraturan (
    id SERIAL PRIMARY KEY,
    jenis_peraturan VARCHAR(100) NOT NULL,
    nomor VARCHAR(50) NOT NULL,
    tahun INT NOT NULL,
    judul TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'berlaku', -- berlaku, dicabut, diubah
    status_detail TEXT DEFAULT '',
    status_detail_json JSONB DEFAULT '{}'::jsonb, -- Detailed relationships: dicabut_sebagian_dengan, diubah_dengan, mencabut, mengubah
    wilayah VARCHAR(150) NOT NULL DEFAULT 'Nasional',
    sektor VARCHAR(100),
    url_dokumen_asli TEXT NOT NULL,
    status_tautan VARCHAR(50) NOT NULL DEFAULT 'normal', -- normal, tautan_bermasalah
    tanggal_diambil TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    tanggal_dicek_terakhir TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_peraturan_jenis ON peraturan(jenis_peraturan);
CREATE INDEX idx_peraturan_tahun ON peraturan(tahun);
CREATE INDEX idx_peraturan_wilayah ON peraturan(wilayah);
CREATE INDEX idx_peraturan_sektor ON peraturan(sektor);
CREATE INDEX idx_peraturan_judul_trgm ON peraturan USING gin (judul gin_trgm_ops);

-- 2. Table: pasal (Articles)
CREATE TABLE pasal (
    id SERIAL PRIMARY KEY,
    peraturan_id INT NOT NULL REFERENCES peraturan(id) ON DELETE CASCADE,
    nomor_pasal VARCHAR(50) NOT NULL,
    nomor_ayat VARCHAR(50),
    teks_pasal TEXT NOT NULL
);

CREATE INDEX idx_pasal_peraturan_id ON pasal(peraturan_id);
CREATE INDEX idx_pasal_nomor_pasal ON pasal(nomor_pasal);
CREATE INDEX idx_pasal_teks_trgm ON pasal USING gin (teks_pasal gin_trgm_ops);

-- 3. Table: sumber_scraping (Scraping Data Sources)
CREATE TABLE sumber_scraping (
    id SERIAL PRIMARY KEY,
    nama_sumber VARCHAR(150) NOT NULL,
    url_dasar TEXT NOT NULL,
    jadwal_crawl_terakhir TIMESTAMP WITH TIME ZONE,
    jadwal_crawl_status_terakhir VARCHAR(50) DEFAULT 'belum_pernah'
);

-- 4. Table: antrian_scraping (Scraping Queue)
CREATE TABLE antrian_scraping (
    id SERIAL PRIMARY KEY,
    sumber_scraping_id INT NOT NULL REFERENCES sumber_scraping(id) ON DELETE CASCADE,
    status_batch VARCHAR(50) NOT NULL DEFAULT 'menunggu',
    halaman_terakhir_diproses INT DEFAULT 0
);

-- 5. Table: log_kegagalan_crawl (Crawl Failure Logs)
CREATE TABLE log_kegagalan_crawl (
    id SERIAL PRIMARY KEY,
    sumber_scraping_id INT NOT NULL REFERENCES sumber_scraping(id) ON DELETE CASCADE,
    waktu_kegagalan TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    pesan_error TEXT NOT NULL
);

-- 6. Table: pengguna (System Users)
CREATE TABLE pengguna (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    kata_sandi_terenkripsi VARCHAR(255) NOT NULL,
    peran VARCHAR(50) NOT NULL,
    diubah_terakhir_oleh VARCHAR(50),
    tanggal_kata_sandi_diubah TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Table: jadwal_rapat_harmonisasi (Harmonisation Meeting Schedules)
CREATE TABLE jadwal_rapat_harmonisasi (
    id SERIAL PRIMARY KEY,
    jenis_rancangan VARCHAR(50) NOT NULL,
    tanggal DATE NOT NULL,
    jam TIME NOT NULL,
    nama_kompilator VARCHAR(150) NOT NULL,
    tim_pokja VARCHAR(50) NOT NULL,
    dibuat_oleh VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_jadwal_tanggal ON jadwal_rapat_harmonisasi(tanggal);
