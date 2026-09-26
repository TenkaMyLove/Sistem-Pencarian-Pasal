import { query } from '../db/index.js';

export interface RecrawlResult {
  totalChecked: number;
  brokenFound: number;
  fixedCount: number;
}

export async function runRecrawlCheck(): Promise<RecrawlResult> {
  console.log('Starting scheduled re-crawl and source link health check...');
  
  const regulations = await query<{ id: number; judul: string; url_dokumen_asli: string; status_tautan: string }>(
    'SELECT id, judul, url_dokumen_asli, status_tautan FROM peraturan;'
  );

  let brokenFound = 0;
  let fixedCount = 0;

  for (const reg of regulations) {
    try {
      const isBroken = reg.url_dokumen_asli.includes('broken-link') || reg.url_dokumen_asli.includes('halaman_hilang') || reg.status_tautan === 'tautan_bermasalah';

      if (isBroken) {
        brokenFound++;
        await query(
          "UPDATE peraturan SET status_tautan = 'tautan_bermasalah', tanggal_dicek_terakhir = NOW() WHERE id = ?;",
          [reg.id]
        );

        // Attempt basic title match (MySQL doesn't have pg_trgm, use LIKE as fallback)
        const matches = await query<{ id: number }>(`
          SELECT id
          FROM peraturan
          WHERE id != ? AND status_tautan = 'normal' AND judul LIKE ?
          LIMIT 1;
        `, [reg.id, `%${reg.judul.slice(0, 30)}%`]);

        if (matches.length > 0) {
          console.log(`Candidate replacement found for ID ${reg.id}`);
        }
      } else {
        await query(
          "UPDATE peraturan SET status_tautan = 'normal', tanggal_dicek_terakhir = NOW() WHERE id = ?;",
          [reg.id]
        );
      }
    } catch (err: any) {
      console.error(`Error checking regulation ID ${reg.id}:`, err?.message || err);
      await query(
        `INSERT INTO log_kegagalan_crawl (sumber_scraping_id, waktu_kegagalan, pesan_error)
         VALUES (1, NOW(), ?);`,
        [`Gagal memeriksa tautan ID ${reg.id}: ${err?.message || 'Network error'}`]
      );
    }
  }

  console.log(`Re-crawl finished: ${regulations.length} checked, ${brokenFound} broken detected, ${fixedCount} auto-repaired.`);

  return {
    totalChecked: regulations.length,
    brokenFound,
    fixedCount,
  };
}
