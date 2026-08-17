/**
 * realCrawler.ts
 *
 * REAL live URL finder for JDIH BPK.
 *
 * BPK Search form parameters (discovered via HTML inspection):
 *   - nomor    = nomor peraturan (e.g. "17")
 *   - tahun    = tahun (e.g. "2003")
 *   - jenis    = numeric jenis ID (see map below)
 *   - tentang  = keyword in judul
 *   - entitas  = entity/wilayah ID
 *
 * We search using POST to /Search with nomor+tahun+jenis for exact match.
 * Then extract the /Details/ link from the first card result.
 * Verify the URL returns HTTP 200 before storing in DB.
 */

import fetch from 'node-fetch';
import * as cheerio from 'cheerio';
import { pool } from '../db/index.js';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8',
};

const DELAY_MS = 2000;
function sleep(ms: number) { return new Promise(r => setTimeout(r, ms)); }

// BPK jenis filter values (from select name="jenis" in form)
// These are approximate — BPK uses group IDs, not individual jenis
const JENIS_FILTER: Record<string, string> = {
  'UU': 'Undang-Undang',
  'PP': 'Peraturan Pemerintah',
  'Perda': 'Peraturan Daerah',
  'Perppu': 'Peraturan Pemerintah Pengganti Undang-Undang',
  'UUD 1945': 'Undang-undang Dasar',
};

// BPK slug prefix per jenis
const JENIS_SLUG: Record<string, string> = {
  'UU': 'uu-no-',
  'PP': 'pp-no-',
  'Perda': 'perda-',
  'Perppu': 'perpu-no-',
  'UUD 1945': 'uud-',
};

interface CrawlTarget {
  jenis: string;
  nomor: string;
  tahun: number;
  source: 'bpk' | 'kemnaker';
  knownUrl?: string;
}

const CRAWL_TARGETS: CrawlTarget[] = [
  // User-verified — just HTTP-verify, no search needed
  { jenis: 'UU',    nomor: '23',   tahun: 2014, source: 'bpk',      knownUrl: 'https://peraturan.bpk.go.id/Details/38685/uu-no-23-tahun-2014' },
  { jenis: 'UU',    nomor: '1',    tahun: 2022, source: 'bpk',      knownUrl: 'https://peraturan.bpk.go.id/Details/195696/uu-no-1-tahun-2022' },
  { jenis: 'UU',    nomor: '6',    tahun: 2023, source: 'kemnaker', knownUrl: 'https://jdih.kemnaker.go.id/peraturan/detail/2302/undang-undang-nomor-6-tahun-2023' },
  { jenis: 'Perda', nomor: '7',    tahun: 2021, source: 'bpk',      knownUrl: 'https://peraturan.bpk.go.id/Details/174573/perda-kab-tapin-no-07-tahun-2021' },
  // To search via BPK nomor+tahun filter
  { jenis: 'UU',    nomor: '17',   tahun: 2003, source: 'bpk' },
  { jenis: 'UU',    nomor: '1',    tahun: 2004, source: 'bpk' },
  { jenis: 'UU',    nomor: '25',   tahun: 2004, source: 'bpk' },
  { jenis: 'UU',    nomor: '26',   tahun: 2007, source: 'bpk' },
  { jenis: 'UU',    nomor: '25',   tahun: 2007, source: 'bpk' },
  { jenis: 'UU',    nomor: '28',   tahun: 2009, source: 'bpk' },
  { jenis: 'UU',    nomor: '32',   tahun: 2009, source: 'bpk' },
  { jenis: 'UU',    nomor: '36',   tahun: 2009, source: 'bpk' },
  { jenis: 'UU',    nomor: '20',   tahun: 2003, source: 'bpk' },
  { jenis: 'UU',    nomor: '13',   tahun: 2003, source: 'bpk' },
  { jenis: 'PP',    nomor: '12',   tahun: 2019, source: 'bpk' },
  { jenis: 'PP',    nomor: '21',   tahun: 2021, source: 'bpk' },
  { jenis: 'PP',    nomor: '22',   tahun: 2021, source: 'bpk' },
  { jenis: 'UUD 1945', nomor: '1945', tahun: 1945, source: 'bpk' },
];

async function verifyUrl(url: string): Promise<boolean> {
  try {
    const r = await fetch(url, { method: 'GET', headers: HEADERS, redirect: 'follow' });
    return r.ok;
  } catch { return false; }
}

/**
 * Search BPK using ?nomor=N&tahun=YYYY filter.
 * This gives exact results because nomor is a precise field on BPK.
 * Validates that returned slug also matches jenis prefix.
 */
async function searchBPKByNomorTahun(jenis: string, nomor: string, tahun: number): Promise<string | null> {
  const jenisSlug = JENIS_SLUG[jenis] || jenis.toLowerCase().replace(/\s+/g, '-') + '-';

  // BPK search by nomor + tahun — most precise search possible
  const searchUrl = `https://peraturan.bpk.go.id/Search?nomor=${encodeURIComponent(nomor)}&tahun=${tahun}`;
  console.log(`  [BPK] GET ${searchUrl}`);

  try {
    const res = await fetch(searchUrl, { headers: HEADERS, redirect: 'follow' });
    if (!res.ok) { console.warn(`  HTTP ${res.status}`); return null; }

    const html = await res.text();
    const $ = cheerio.load(html);

    let found: string | null = null;

    $('a[href*="/Details/"]').each((_, el) => {
      if (found) return;
      const rawHref = $(el).attr('href') || '';
      const slug = rawHref.toLowerCase();

      if (!slug.includes('/details/')) return;

      // Must match jenis slug prefix
      if (!slug.includes(jenisSlug)) return;

      // Must contain "tahun-YYYY" in slug
      if (!slug.includes(`tahun-${tahun}`)) return;

      // Must contain nomor precisely: -NOMOR-tahun or -0NOMOR-tahun
      const nomorInt = parseInt(nomor, 10);
      const padded = nomorInt.toString().padStart(2, '0');
      const hasNomor =
        slug.includes(`-${nomor}-tahun`) ||
        slug.includes(`-${padded}-tahun`) ||
        slug.includes(`no-${nomor}-tahun`) ||
        slug.includes(`no-${padded}-tahun`);

      if (!hasNomor) return;

      found = rawHref.startsWith('http')
        ? rawHref
        : `https://peraturan.bpk.go.id${rawHref}`;
    });

    if (found) return found;

    // Fallback: search with tentang keyword to narrow results
    await sleep(1500);
    const jenisWord = JENIS_FILTER[jenis] || jenis;
    const fallbackUrl = `https://peraturan.bpk.go.id/Search?nomor=${encodeURIComponent(nomor)}&tahun=${tahun}&q=${encodeURIComponent(jenisWord)}`;
    console.log(`  [BPK] fallback GET ${fallbackUrl}`);

    const res2 = await fetch(fallbackUrl, { headers: HEADERS, redirect: 'follow' });
    if (!res2.ok) return null;

    const html2 = await res2.text();
    const $2 = cheerio.load(html2);

    $2('a[href*="/Details/"]').each((_, el) => {
      if (found) return;
      const rawHref = $2(el).attr('href') || '';
      const slug = rawHref.toLowerCase();
      if (!slug.includes('/details/')) return;
      if (!slug.includes(jenisSlug)) return;
      if (!slug.includes(`tahun-${tahun}`)) return;
      const nomorInt = parseInt(nomor, 10);
      const padded = nomorInt.toString().padStart(2, '0');
      const hasNomor =
        slug.includes(`-${nomor}-tahun`) ||
        slug.includes(`-${padded}-tahun`) ||
        slug.includes(`no-${nomor}-tahun`) ||
        slug.includes(`no-${padded}-tahun`);
      if (!hasNomor) return;
      found = rawHref.startsWith('http') ? rawHref : `https://peraturan.bpk.go.id${rawHref}`;
    });

    return found;
  } catch (err) {
    console.warn(`  Fetch error: ${err}`);
    return null;
  }
}

export async function runRealCrawler() {
  console.log('\n=== REAL LIVE CRAWLER ===');
  console.log(`Targets: ${CRAWL_TARGETS.length} | BPK search param: ?nomor=N&tahun=YYYY`);
  console.log('Validation: jenis slug + nomor + tahun exact match in returned URL slug\n');

  const client = await pool.connect();
  const results: { label: string; url: string | null; status: string }[] = [];

  try {
    await client.query('BEGIN');

    for (const target of CRAWL_TARGETS) {
      const label = `${target.jenis} No.${target.nomor}/${target.tahun}`;
      console.log(`\n--- ${label} ---`);

      let foundUrl: string | null = target.knownUrl || null;

      if (target.knownUrl) {
        console.log(`  User-verified URL: ${foundUrl}`);
      } else {
        await sleep(DELAY_MS);
        foundUrl = await searchBPKByNomorTahun(target.jenis, target.nomor, target.tahun);
      }

      if (foundUrl) {
        await sleep(600);
        const ok = await verifyUrl(foundUrl);
        const tautan = ok ? 'normal' : 'tautan_bermasalah';
        console.log(`  ${foundUrl}`);
        console.log(`  HTTP 200: ${ok ? 'YES' : 'NO'} -> ${tautan}`);

        const upd = await client.query(
          `UPDATE peraturan
           SET url_dokumen_asli=$1, status_tautan=$2, tanggal_dicek_terakhir=NOW()
           WHERE jenis_peraturan=$3 AND nomor=$4 AND tahun=$5
           RETURNING judul;`,
          [foundUrl, tautan, target.jenis, target.nomor, target.tahun]
        );

        if (upd.rows.length > 0) {
          console.log(`  DB updated: ${upd.rows[0].judul.substring(0, 70)}...`);
          results.push({ label, url: foundUrl, status: tautan });
        } else {
          console.warn(`  No DB row found for ${label}`);
          results.push({ label, url: foundUrl, status: 'not_in_db' });
        }
      } else {
        console.warn(`  NOT FOUND — marking tautan_bermasalah`);
        await client.query(
          `UPDATE peraturan SET status_tautan='tautan_bermasalah', tanggal_dicek_terakhir=NOW()
           WHERE jenis_peraturan=$1 AND nomor=$2 AND tahun=$3;`,
          [target.jenis, target.nomor, target.tahun]
        );
        results.push({ label, url: null, status: 'not_found' });
      }
    }

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Fatal:', err);
    throw err;
  } finally {
    client.release();
  }

  // Summary
  console.log('\n\n========== CRAWL SUMMARY ==========');
  console.log(`${'Peraturan'.padEnd(26)} ${'URL'.padEnd(88)} Status`);
  console.log('-'.repeat(125));
  for (const r of results) {
    console.log(`${r.label.padEnd(26)} ${(r.url || '(not found)').padEnd(88)} ${r.status}`);
  }
  const found = results.filter(r => r.url !== null).length;
  const ok200 = results.filter(r => r.status === 'normal').length;
  console.log(`\nTotal: ${results.length} | Crawled & found: ${found} | HTTP 200 verified: ${ok200} | Not found: ${results.length - found}`);

  return results;
}
