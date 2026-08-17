import bcrypt from 'bcryptjs';
import { pool } from './index.js';
import { ingestComprehensiveLegalData } from '../scraper/ingestAllSectors.js';
import { bulkIngestFullArticles } from '../scraper/bulkIngest.js';
import { crawlLiveBPKRegulations } from '../scraper/bpkScraper.js';

async function seed() {
  console.log('Starting database seed for P3H Kemenkum Kalsel...');
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Seed Accounts
    console.log('Seeding default user accounts...');
    await client.query('DELETE FROM pengguna;');

    const adminHash = await bcrypt.hash('TenkaLOML', 10);
    const pengelolaHash = await bcrypt.hash('Pengelola123!', 10);
    const perancangHash = await bcrypt.hash('Perancang123!', 10);

    await client.query(`
      INSERT INTO pengguna (username, kata_sandi_terenkripsi, peran, diubah_terakhir_oleh, tanggal_kata_sandi_diubah)
      VALUES 
        ('Pengelola', $1, 'Pengelola', 'System', NOW()),
        ('Perancang', $2, 'Perancang', 'System', NOW()),
        ('Admin', $3, 'Admin', 'System', NOW());
    `, [pengelolaHash, perancangHash, adminHash]);

    // 2. Seed Scraping Sources
    console.log('Seeding scraping sources...');
    await client.query('DELETE FROM sumber_scraping;');
    await client.query(`
      INSERT INTO sumber_scraping (nama_sumber, url_dasar, jadwal_crawl_terakhir, jadwal_crawl_status_terakhir)
      VALUES 
        ('JDIH BPK RI', 'https://peraturan.bpk.go.id', NOW(), 'sukses'),
        ('peraturan.go.id', 'https://peraturan.go.id', NOW(), 'sukses'),
        ('JDIH Prov Kalsel', 'https://jdih.kalselprov.go.id', NOW(), 'sukses'),
        ('JDIH Kota Banjarmasin', 'https://jdih.banjarmasinkota.go.id', NOW(), 'sukses'),
        ('JDIH Kota Banjarbaru', 'https://jdih.banjarbarukota.go.id', NOW(), 'sukses'),
        ('JDIH Kab. Banjar', 'https://jdih.banjarkab.go.id', NOW(), 'sukses'),
        ('JDIH Kab. Tanah Laut', 'https://jdih.tanahlautkab.go.id', NOW(), 'sukses'),
        ('JDIH Kab. Tabalong', 'https://jdih.tabalongkab.go.id', NOW(), 'sukses');
    `);

    // 3. Seed Harmonisation Schedules
    console.log('Seeding harmonisation meeting schedules...');
    await client.query('DELETE FROM jadwal_rapat_harmonisasi;');
    await client.query(`
      INSERT INTO jadwal_rapat_harmonisasi (jenis_rancangan, tanggal, jam, nama_kompilator, tim_pokja, dibuat_oleh)
      VALUES 
        ('Ranperda', CURRENT_DATE + INTERVAL '1 day', '09:00', 'Budi Santoso, S.H.', 'Pokja 1', 'Pengelola'),
        ('Ranperkada', CURRENT_DATE + INTERVAL '2 days', '10:30', 'Siti Rahmah, M.H.', 'Pokja 2', 'Pengelola'),
        ('Ranperda', CURRENT_DATE + INTERVAL '4 days', '14:00', 'Ahmad Fauzi, S.H.', 'Pokja 1', 'Pengelola'),
        ('Ranperda', CURRENT_DATE + INTERVAL '7 days', '09:30', 'Nur Hidayah, S.H.', 'Pokja 2', 'Pengelola');
    `);

    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error in initial seed:', error);
    throw error;
  } finally {
    client.release();
  }

  // 4. Ingest Regulations and Full Sequential Articles
  await client.query('DELETE FROM pasal;');
  await client.query('DELETE FROM peraturan;');
  await ingestComprehensiveLegalData();
  await bulkIngestFullArticles();
  await crawlLiveBPKRegulations(10);

  console.log('Database seed completed successfully!');
}

seed().then(() => pool.end());
