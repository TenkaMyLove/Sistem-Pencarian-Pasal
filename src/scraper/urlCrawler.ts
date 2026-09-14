/**
 * urlCrawler.ts
 *
 * Crawls a single absolute URL provided by the Pengelola.
 * The URL is always treated as absolute — no base URL is added.
 *
 * Parsing strategy (generic, not BPK-specific):
 * 1. Fetch HTML from the provided URL.
 * 2. Try to extract judul from <title>, <h1>, or meta og:title.
 * 3. Try to extract pasal text using the pattern "Pasal N" found in the body.
 * 4. If BPK URL — also fetch status_detail_json from crawlStatusPeraturan logic.
 * 5. Save peraturan + pasal rows to DB.
 */

import fetch from 'node-fetch';
import * as cheerio from 'cheerio';
import { pool } from '../db/index.js';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8',
};

export interface ParsedPasal {
  nomor_pasal: string;
  nomor_ayat: string;
  teks_pasal: string;
}

export interface CrawlInput {
  url: string;
  jenis_peraturan: string;
  nomor: string;
  tahun: number;
  judul: string;
  wilayah: string;
  sektor: string;
  ditambahkan_oleh: string;
}

export interface CrawlResult {
  ok: boolean;
  judul: string;
  status_tautan: 'normal' | 'tautan_bermasalah';
  pasal_count: number;
  peraturan_id: number | null;
  error?: string;
  parsedPasal: ParsedPasal[];
}

/**
 * Try to extract a clean judul from the HTML page.
 * Priority: og:title meta → <h1> → <title> → fallback to manual input.
 */
function extractJudul($: cheerio.CheerioAPI, fallback: string): string {
  const og = $('meta[property="og:title"]').attr('content')?.trim();
  if (og && og.length > 5) return og;

  const h1 = $('h1').first().text().trim().replace(/\s+/g, ' ');
  if (h1.length > 5) return h1;

  const titleEl = $('title').text().trim().replace(/\s+/g, ' ');
  if (titleEl.length > 5) return titleEl;

  return fallback;
}

/**
 * Extract pasal items from page HTML.
 * Strategy 1: find heading/bold elements containing "Pasal N".
 * Strategy 2: scan full body text line by line.
 */
function extractPasal($: cheerio.CheerioAPI): ParsedPasal[] {
  const results: ParsedPasal[] = [];
  const pasalPattern = /^Pasal\s+(\d+[A-Z]?)$/i;

  // Strategy 1: heading elements
  const headings = $('h2, h3, h4, h5, b, strong, p').filter((_, el) => {
    return pasalPattern.test($(el).text().trim());
  });

  headings.each((_, el) => {
    const nomor = $(el).text().trim();
    const textParts: string[] = [];
    let sibling = $(el).next();
    let iters = 0;

    while (sibling.length && iters < 30) {
      iters++;
      const sibText = sibling.text().trim().replace(/\s+/g, ' ');
      if (pasalPattern.test(sibText)) break;
      if (sibText.length > 0) textParts.push(sibText);
      sibling = sibling.next();
    }

    const fullText = textParts.join(' ').trim();
    if (fullText.length > 10) {
      results.push({ nomor_pasal: nomor, nomor_ayat: '', teks_pasal: fullText });
    }
  });

  // Strategy 2: full page text scan
  if (results.length === 0) {
    const bodyText = $('body').text().replace(/\r/g, '').split('\n');
    let currentPasal = '';
    let currentLines: string[] = [];

    for (const rawLine of bodyText) {
      const line = rawLine.trim();
      if (pasalPattern.test(line)) {
        if (currentPasal && currentLines.length > 0) {
          const teks = currentLines.join(' ').replace(/\s+/g, ' ').trim();
          if (teks.length > 10) {
            results.push({ nomor_pasal: currentPasal, nomor_ayat: '', teks_pasal: teks });
          }
        }
        currentPasal = line;
        currentLines = [];
      } else if (currentPasal && line.length > 0) {
        currentLines.push(line);
      }
    }
    if (currentPasal && currentLines.length > 0) {
      const teks = currentLines.join(' ').replace(/\s+/g, ' ').trim();
      if (teks.length > 10) {
        results.push({ nomor_pasal: currentPasal, nomor_ayat: '', teks_pasal: teks });
      }
    }
  }

  return results.slice(0, 200);
}

/**
 * Try to parse STATUS PERATURAN (BPK-style) from the page.
 */
async function tryFetchStatusJson(url: string, html: string): Promise<{ json: any; summary: string } | null> {
  try {
    const $ = cheerio.load(html);

    const LABEL_TO_KEY: Record<string, string> = {
      'mencabut': 'mencabut',
      'mencabut sebagian': 'mencabut_sebagian',
      'diubah dengan': 'diubah_dengan',
      'dicabut dengan': 'dicabut_dengan',
      'dicabut sebagian dengan': 'dicabut_sebagian_dengan',
      'mengubah': 'mengubah',
      'ditetapkan': 'ditetapkan',
    };

    const result: Record<string, any[]> = {};

    $('div.col-12.fw-semibold.bg-light-primary').each((_, labelEl) => {
      const labelText = $(labelEl).text().trim().toLowerCase().replace(/\s*:\s*$/, '').trim();
      const key = LABEL_TO_KEY[labelText];
      if (!key) return;

      const itemsContainer = $(labelEl).closest('.row').next('.row');
      const items: any[] = [];

      itemsContainer.find('li.mb-4').each((_, li) => {
        const $a = $(li).find('a').first();
        const href = $a.attr('href') || '';
        const label = $a.text().trim();
        const fullUrl = href.startsWith('http') ? href : href ? `https://peraturan.bpk.go.id${href}` : '';
        if (label || fullUrl) items.push({ label, url: fullUrl });
      });

      if (items.length > 0) result[key] = items;
    });

    if (Object.keys(result).length === 0) return null;

    const summaryParts = Object.keys(result).map(k => `${k.replace(/_/g, ' ')}: ${result[k].length} peraturan`);
    return { json: result, summary: summaryParts.join('; ') };
  } catch {
    return null;
  }
}

/**
 * Main entry point: crawl a URL and save results to DB.
 */
export async function crawlFromUrl(input: CrawlInput): Promise<CrawlResult> {
  const { url, jenis_peraturan, nomor, tahun, judul: manualJudul, wilayah, sektor } = input;

  let statusTautan: 'normal' | 'tautan_bermasalah' = 'tautan_bermasalah';
  let finalJudul = manualJudul || url;
  let parsedPasal: ParsedPasal[] = [];
  let statusJson: any = {};
  let statusDetail = '';

  // 1. Fetch page
  let html = '';
  try {
    const res = await fetch(url, { headers: HEADERS, redirect: 'follow' });
    if (res.ok) {
      statusTautan = 'normal';
      html = await res.text();
    } else {
      console.warn(`[urlCrawler] HTTP ${res.status} for ${url}`);
    }
  } catch (err: any) {
    console.warn(`[urlCrawler] Fetch error: ${err?.message}`);
  }

  // 2. Parse HTML
  if (html) {
    const $ = cheerio.load(html);

    if (!manualJudul || manualJudul.trim() === '') {
      finalJudul = extractJudul($, url);
    }

    parsedPasal = extractPasal($);

    const statusData = await tryFetchStatusJson(url, html);
    if (statusData) {
      statusJson = statusData.json;
      statusDetail = statusData.summary;
    }
  }

  // 3. Save to DB
  const client = await pool.connect();
  let peraturanId: number | null = null;

  try {
    await client.query('BEGIN');

    const insReg = await client.query<{ id: number }>(`
      INSERT INTO peraturan
        (jenis_peraturan, nomor, tahun, judul, status, status_detail, status_detail_json,
         wilayah, sektor, url_dokumen_asli, status_tautan, tanggal_diambil, tanggal_dicek_terakhir)
      VALUES ($1, $2, $3, $4, 'berlaku', $5, $6::jsonb, $7, $8, $9, $10, NOW(), NOW())
      RETURNING id;
    `, [
      jenis_peraturan,
      nomor,
      tahun,
      finalJudul,
      statusDetail,
      JSON.stringify(statusJson),
      wilayah,
      sektor,
      url,
      statusTautan,
    ]);

    peraturanId = insReg.rows[0]?.id ?? null;

    if (peraturanId && parsedPasal.length > 0) {
      for (const p of parsedPasal) {
        await client.query(`
          INSERT INTO pasal (peraturan_id, nomor_pasal, nomor_ayat, teks_pasal)
          VALUES ($1, $2, $3, $4);
        `, [peraturanId, p.nomor_pasal, p.nomor_ayat || '', p.teks_pasal]);
      }
    }

    await client.query('COMMIT');
  } catch (err: any) {
    await client.query('ROLLBACK');
    console.error('[urlCrawler] DB error:', err?.message);
    return {
      ok: false,
      judul: finalJudul,
      status_tautan: statusTautan,
      pasal_count: 0,
      peraturan_id: null,
      parsedPasal: [],
      error: `Gagal menyimpan ke database: ${err?.message}`,
    };
  } finally {
    client.release();
  }

  return {
    ok: true,
    judul: finalJudul,
    status_tautan: statusTautan,
    pasal_count: parsedPasal.length,
    peraturan_id: peraturanId,
    parsedPasal,
  };
}
