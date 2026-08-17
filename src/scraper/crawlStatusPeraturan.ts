/**
 * crawlStatusPeraturan.ts
 *
 * Crawls the BPK detail page for each regulation in the DB,
 * parses the "STATUS PERATURAN" section, and stores the structured
 * status relationships into status_detail_json.
 *
 * BPK detail page structure (discovered via HTML inspection):
 *   - Category label: div.col-12.fw-semibold.bg-light-primary  → "Mencabut :", "Diubah dengan :", etc.
 *   - Items in next sibling div: ol > li.mb-4
 *     - <a href="/Details/..."> → label + URL
 *     - text after <span class="text-muted">tentang</span> → judul
 *     - <span> after <br> → keterangan pasal
 *
 * Maps BPK category labels to our internal JSON keys:
 *   "Mencabut :"          → mencabut
 *   "Mencabut sebagian :" → mencabut_sebagian
 *   "Diubah dengan :"     → diubah_dengan
 *   "Dicabut dengan :"    → dicabut_dengan
 *   "Dicabut sebagian dengan :" → dicabut_sebagian_dengan
 *   "Mengubah :"          → mengubah
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

// Normalize BPK label text to our JSON key
const LABEL_TO_KEY: Record<string, string> = {
  'mencabut':                  'mencabut',
  'mencabut sebagian':         'mencabut_sebagian',
  'diubah dengan':             'diubah_dengan',
  'dicabut dengan':            'dicabut_dengan',
  'dicabut sebagian dengan':   'dicabut_sebagian_dengan',
  'mengubah':                  'mengubah',
  'ditetapkan':                'ditetapkan',
};

function normalizeLabel(raw: string): string | null {
  const clean = raw.toLowerCase().replace(/\s*:\s*$/, '').trim();
  return LABEL_TO_KEY[clean] || null;
}

export interface StatusItem {
  label: string;   // Short label e.g. "UU No. 28 Tahun 2009"
  judul: string;   // Full title e.g. "UU No. 28 Tahun 2009 tentang Pajak Daerah dan Retribusi Daerah"
  url: string;     // Full BPK URL
  keterangan?: string; // Optional pasal note
}

export type StatusDetailJson = Record<string, StatusItem[]>;

/**
 * Fetch and parse the STATUS PERATURAN section from a BPK detail page.
 */
async function fetchStatusPeraturan(detailUrl: string): Promise<StatusDetailJson | null> {
  try {
    const res = await fetch(detailUrl, { headers: HEADERS, redirect: 'follow' });
    if (!res.ok) {
      console.warn(`  HTTP ${res.status} for ${detailUrl}`);
      return null;
    }

    const html = await res.text();
    const $ = cheerio.load(html);

    const result: StatusDetailJson = {};

    // Find all category label divs inside STATUS PERATURAN container
    // Pattern: div.col-12.fw-semibold.bg-light-primary containing the label
    $('div.col-12.fw-semibold.bg-light-primary').each((_, labelEl) => {
      const labelText = $(labelEl).text().trim();
      const key = normalizeLabel(labelText);
      if (!key) return;

      // The items are in the next sibling .row > .col-lg-12 > ol > li
      const itemsContainer = $(labelEl).closest('.row').next('.row');
      const items: StatusItem[] = [];

      itemsContainer.find('li.mb-4').each((_, li) => {
        const $li = $(li);

        // Extract link and label
        const $a = $li.find('a').first();
        const href = $a.attr('href') || '';
        const linkLabel = $a.text().trim(); // e.g. "UU No. 28 Tahun 2009"

        const fullUrl = href.startsWith('http')
          ? href
          : href ? `https://peraturan.bpk.go.id${href}` : '';

        // Extract title: text after "tentang" span, before <br>
        // Clone li, remove the <a> and "tentang" span, get remaining text
        const $liClone = $li.clone();
        $liClone.find('a').remove();
        $liClone.find('span.text-muted').remove(); // "tentang" word

        // The keterangan is in <span> after <br>
        const keterangan = $liClone.find('span').not('.text-muted').text().trim()
          .replace(/\r\n/g, ' ').replace(/\s+/g, ' ').trim();

        // Get title text: everything before <br>
        // We reconstruct: linkLabel + " tentang " + topic
        const fullLiText = $li.text().trim().replace(/\s+/g, ' ');
        // Extract "tentang <title>" from full text after linkLabel
        const tentangIdx = fullLiText.indexOf('tentang');
        let titlePart = '';
        if (tentangIdx !== -1) {
          // Get text between "tentang" and keterangan (if keterangan exists)
          const afterTentang = fullLiText.substring(tentangIdx + 7).trim();
          if (keterangan && afterTentang.includes(keterangan.substring(0, 20))) {
            titlePart = afterTentang.substring(0, afterTentang.indexOf(keterangan.substring(0, 20))).trim();
          } else {
            titlePart = afterTentang;
          }
        }

        const judul = titlePart
          ? `${linkLabel} tentang ${titlePart}`
          : linkLabel;

        if (linkLabel || fullUrl) {
          items.push({
            label: linkLabel,
            judul: judul.replace(/\s+/g, ' ').trim(),
            url: fullUrl,
            ...(keterangan ? { keterangan } : {}),
          });
        }
      });

      if (items.length > 0) {
        result[key] = items;
      }
    });

    return Object.keys(result).length > 0 ? result : null;
  } catch (err) {
    console.warn(`  Fetch error: ${err}`);
    return null;
  }
}

export async function crawlStatusPeraturan() {
  console.log('\n=== CRAWLING STATUS PERATURAN FROM BPK DETAIL PAGES ===\n');

  // Get all regulations with BPK URLs from DB
  const client = await pool.connect();

  try {
    const regs = await client.query(`
      SELECT id, jenis_peraturan, nomor, tahun, judul, url_dokumen_asli
      FROM peraturan
      WHERE url_dokumen_asli LIKE '%peraturan.bpk.go.id%'
        AND url_dokumen_asli != ''
      ORDER BY tahun DESC, nomor;
    `);

    console.log(`Found ${regs.rows.length} BPK regulations to process.\n`);

    let updated = 0;
    let skipped = 0;

    for (const reg of regs.rows) {
      const label = `${reg.jenis_peraturan} No.${reg.nomor}/${reg.tahun}`;
      console.log(`--- ${label} ---`);
      console.log(`  URL: ${reg.url_dokumen_asli}`);

      await sleep(DELAY_MS);

      const statusJson = await fetchStatusPeraturan(reg.url_dokumen_asli);

      if (statusJson) {
        const categories = Object.keys(statusJson);
        const totalItems = Object.values(statusJson).reduce((sum, arr) => sum + arr.length, 0);
        console.log(`  Found: ${categories.join(', ')} (${totalItems} total items)`);

        // Build status_detail summary string
        const summaryParts = categories.map(cat => {
          const items = statusJson[cat];
          return `${cat.replace(/_/g, ' ')}: ${items.length} peraturan`;
        });

        await client.query(`
          UPDATE peraturan
          SET status_detail_json = $1::jsonb,
              status_detail = $2,
              tanggal_dicek_terakhir = NOW()
          WHERE id = $3;
        `, [JSON.stringify(statusJson), summaryParts.join('; '), reg.id]);

        console.log(`  DB updated.`);
        updated++;
      } else {
        console.log(`  No STATUS PERATURAN section found — skipping.`);
        skipped++;
      }
    }

    console.log(`\n=== DONE ===`);
    console.log(`Updated: ${updated} | Skipped (no status): ${skipped}`);

  } finally {
    client.release();
  }
}
