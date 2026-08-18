import pg from 'pg';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
import https from 'https';
import http from 'http';

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: resolve(__dirname, '.env') });

const { Pool } = pg;
const pool = new Pool({
  host: process.env.PGHOST || 'localhost',
  port: parseInt(process.env.PGPORT || '5432', 10),
  database: process.env.PGDATABASE || 'p3h_kemenkum_kalsel',
  user: process.env.PGUSER || 'postgres',
  password: process.env.PGPASSWORD || '',
});

function fetchUrl(url, timeout = 8000) {
  return new Promise((resolve) => {
    const lib = url.startsWith('https') ? https : http;
    const timer = setTimeout(() => resolve({ status: 'TIMEOUT', title: null, statusCode: null }), timeout);
    try {
      const req = lib.get(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html',
        },
        timeout,
      }, (res) => {
        clearTimeout(timer);
        if (res.statusCode === 301 || res.statusCode === 302 || res.statusCode === 303) {
          resolve({ status: 'REDIRECT', title: null, statusCode: res.statusCode, location: res.headers.location });
          res.resume();
          return;
        }
        if (res.statusCode !== 200) {
          resolve({ status: 'ERROR', title: null, statusCode: res.statusCode });
          res.resume();
          return;
        }
        let body = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => {
          body += chunk;
          if (body.length > 20000) { res.destroy(); }
        });
        res.on('end', () => {
          // Extract <title> tag
          const titleMatch = body.match(/<title[^>]*>([^<]+)<\/title>/i);
          const title = titleMatch ? titleMatch[1].trim() : null;
          // Also check for h1 or main heading
          const h1Match = body.match(/<h1[^>]*>([^<]+)<\/h1>/i);
          const h1 = h1Match ? h1Match[1].trim() : null;
          resolve({ status: 'OK', title, h1, statusCode: 200 });
        });
        res.on('error', () => resolve({ status: 'ERROR', title: null, statusCode: res.statusCode }));
      });
      req.on('error', (e) => { clearTimeout(timer); resolve({ status: 'ERROR', title: null, statusCode: null, error: e.message }); });
      req.on('timeout', () => { clearTimeout(timer); req.destroy(); resolve({ status: 'TIMEOUT', title: null, statusCode: null }); });
    } catch (e) {
      clearTimeout(timer);
      resolve({ status: 'ERROR', title: null, statusCode: null, error: e.message });
    }
  });
}

async function main() {
  const client = await pool.connect();
  try {
    const rows = await client.query(`
      SELECT id, jenis_peraturan, nomor, tahun, judul, url_dokumen_asli, wilayah
      FROM peraturan
      ORDER BY tahun, nomor;
    `);

    console.log(`\nAUDITING ${rows.rows.length} REGULATIONS...\n`);
    console.log('='.repeat(100));

    const results = [];

    for (const reg of rows.rows) {
      const url = reg.url_dokumen_asli;
      if (!url) {
        results.push({ ...reg, fetchStatus: 'NO_URL', fetchTitle: null });
        console.log(`[NO URL ] ${reg.jenis_peraturan} ${reg.nomor}/${reg.tahun}`);
        continue;
      }

      process.stdout.write(`Checking ${reg.jenis_peraturan} ${reg.nomor}/${reg.tahun} (${reg.wilayah})... `);
      const result = await fetchUrl(url);
      results.push({ ...reg, fetchStatus: result.status, fetchTitle: result.title, fetchH1: result.h1, statusCode: result.statusCode, location: result.location });

      if (result.status === 'OK') {
        console.log(`${result.statusCode} OK | Page title: "${result.title}"`);
      } else if (result.status === 'REDIRECT') {
        console.log(`REDIRECT ${result.statusCode} -> ${result.location}`);
      } else if (result.status === 'TIMEOUT') {
        console.log(`TIMEOUT`);
      } else {
        console.log(`ERROR ${result.statusCode} | ${result.error || ''}`);
      }
    }

    console.log('\n' + '='.repeat(100));
    console.log('SUMMARY\n');

    const broken = results.filter(r => r.fetchStatus !== 'OK' && r.fetchStatus !== 'REDIRECT');
    const redirects = results.filter(r => r.fetchStatus === 'REDIRECT');
    const ok = results.filter(r => r.fetchStatus === 'OK');

    console.log(`OK        : ${ok.length}`);
    console.log(`REDIRECT  : ${redirects.length}`);
    console.log(`BROKEN    : ${broken.length}\n`);

    if (broken.length > 0) {
      console.log('--- BROKEN LINKS ---');
      broken.forEach(r => {
        console.log(`  [${r.fetchStatus}] ${r.jenis_peraturan} No.${r.nomor}/${r.tahun} | ${r.judul.substring(0, 60)}...`);
        console.log(`           URL: ${r.url_dokumen_asli}`);
      });
    }

    if (redirects.length > 0) {
      console.log('\n--- REDIRECTS (may still be valid) ---');
      redirects.forEach(r => {
        console.log(`  ${r.jenis_peraturan} No.${r.nomor}/${r.tahun} -> ${r.location}`);
      });
    }

  } catch (e) {
    console.error('Fatal:', e.message);
  } finally {
    client.release();
    await pool.end();
  }
}

main();
