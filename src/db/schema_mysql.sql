-- P3H Kemenkum Kalsel Database Schema
-- Target: MySQL 8.x

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS log_kegagalan_crawl;
DROP TABLE IF EXISTS antrian_scraping;
DROP TABLE IF EXISTS sumber_scraping;
DROP TABLE IF EXISTS pasal;
DROP TABLE IF EXISTS peraturan;
DROP TABLE IF EXISTS jadwal_rapat_harmonisasi;
DROP TABLE IF EXISTS pengguna;

SET FOREIGN_KEY_CHECKS = 1;

-- 1. Table: peraturan (Regulations)
CREATE TABLE peraturan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    jenis_peraturan VARCHAR(100) NOT NULL,
    nomor VARCHAR(50) NOT NULL,
    tahun INT NOT NULL,
    judul TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'berlaku',  -- berlaku, dicabut, diubah
    status_detail TEXT,
    status_detail_json JSON,                        -- Detailed relationships
    wilayah VARCHAR(150) NOT NULL DEFAULT 'Nasional',
    sektor VARCHAR(100),
    url_dokumen_asli TEXT NOT NULL,
    status_tautan VARCHAR(50) NOT NULL DEFAULT 'normal', -- normal, tautan_bermasalah
    tanggal_diambil DATETIME DEFAULT CURRENT_TIMESTAMP,
    tanggal_dicek_terakhir DATETIME DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE INDEX idx_peraturan_jenis ON peraturan(jenis_peraturan);
CREATE INDEX idx_peraturan_tahun ON peraturan(tahun);
CREATE INDEX idx_peraturan_wilayah ON peraturan(wilayah);
CREATE INDEX idx_peraturan_sektor ON peraturan(sektor);
CREATE FULLTEXT INDEX idx_peraturan_judul_ft ON peraturan(judul);

-- 2. Table: pasal (Articles)
CREATE TABLE pasal (
    id INT AUTO_INCREMENT PRIMARY KEY,
    peraturan_id INT NOT NULL,
    nomor_pasal VARCHAR(50) NOT NULL,
    nomor_ayat VARCHAR(50),
    teks_pasal TEXT NOT NULL,
    CONSTRAINT fk_pasal_peraturan FOREIGN KEY (peraturan_id) REFERENCES peraturan(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE INDEX idx_pasal_peraturan_id ON pasal(peraturan_id);
CREATE INDEX idx_pasal_nomor_pasal ON pasal(nomor_pasal);
CREATE FULLTEXT INDEX idx_pasal_teks_ft ON pasal(teks_pasal);

-- 3. Table: sumber_scraping (Scraping Data Sources)
CREATE TABLE sumber_scraping (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama_sumber VARCHAR(150) NOT NULL,
    url_dasar TEXT NOT NULL,
    jadwal_crawl_terakhir DATETIME,
    jadwal_crawl_status_terakhir VARCHAR(50) DEFAULT 'belum_pernah'
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 4. Table: antrian_scraping (Scraping Queue)
CREATE TABLE antrian_scraping (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sumber_scraping_id INT NOT NULL,
    status_batch VARCHAR(50) NOT NULL DEFAULT 'menunggu',
    halaman_terakhir_diproses INT DEFAULT 0,
    CONSTRAINT fk_antrian_sumber FOREIGN KEY (sumber_scraping_id) REFERENCES sumber_scraping(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 5. Table: log_kegagalan_crawl (Crawl Failure Logs)
CREATE TABLE log_kegagalan_crawl (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sumber_scraping_id INT NOT NULL,
    waktu_kegagalan DATETIME DEFAULT CURRENT_TIMESTAMP,
    pesan_error TEXT NOT NULL,
    CONSTRAINT fk_log_sumber FOREIGN KEY (sumber_scraping_id) REFERENCES sumber_scraping(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 6. Table: pengguna (System Users)
CREATE TABLE pengguna (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    kata_sandi_terenkripsi VARCHAR(255) NOT NULL,
    peran VARCHAR(50) NOT NULL,
    diubah_terakhir_oleh VARCHAR(50),
    tanggal_kata_sandi_diubah DATETIME DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 7. Table: jadwal_rapat_harmonisasi (Harmonisation Meeting Schedules)
CREATE TABLE jadwal_rapat_harmonisasi (
    id INT AUTO_INCREMENT PRIMARY KEY,
    jenis_rancangan VARCHAR(50) NOT NULL,
    tentang TEXT NOT NULL,
    tanggal DATE NOT NULL,
    jam TIME NOT NULL,
    nama_kompilator VARCHAR(150) NOT NULL,
    tim_pokja VARCHAR(50) NOT NULL,
    dibuat_oleh VARCHAR(50) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE INDEX idx_jadwal_tanggal ON jadwal_rapat_harmonisasi(tanggal);
