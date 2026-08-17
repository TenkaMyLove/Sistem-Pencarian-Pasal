import fetch from 'node-fetch';
import * as cheerio from 'cheerio';
import * as fs from 'fs';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8',
};

async function diagnose() {
  // Fetch UU No. 1 Tahun 2022 detail page (user-verified URL)
  const url = 'https://peraturan.bpk.go.id/Details/195696/uu-no-1-tahun-2022';
  console.log(`Fetching: ${url}`);
  const res = await fetch(url, { headers: HEADERS, redirect: 'follow' });
  console.log(`Status: ${res.status}`);
  const html = await res.text();
  fs.writeFileSync('bpk_detail_debug.html', html, 'utf-8');
  console.log(`Saved ${html.length} bytes to bpk_detail_debug.html`);

  const $ = cheerio.load(html);

  // Find "Status Peraturan" section
  console.log('\n--- Searching for Status Peraturan ---');
  $('*').each((_, el) => {
    const text = $(el).text().trim();
    if (text.toLowerCase().includes('status peraturan') && text.length < 100) {
      console.log(`Tag: ${el.tagName}, Class: ${$(el).attr('class')}, Text: "${text}"`);
    }
  });

  // Find "Mencabut" mentions
  console.log('\n--- Searching for Mencabut text ---');
  $('*').each((_, el) => {
    const text = $(el).text().trim();
    if ((text.toLowerCase().includes('mencabut') || text.toLowerCase().includes('diubah dengan')) && text.length < 200) {
      const classes = $(el).attr('class') || '';
      console.log(`Tag: ${el.tagName}, Class: "${classes}", Text: "${text.substring(0, 120)}"`);
    }
  });

  // Find all table rows that might contain status
  console.log('\n--- Table rows sample ---');
  $('tr').each((i, el) => {
    if (i > 30) return;
    const text = $(el).text().trim().replace(/\s+/g, ' ').substring(0, 150);
    if (text.toLowerCase().includes('mencabut') || text.toLowerCase().includes('status') || text.toLowerCase().includes('diubah')) {
      console.log(`TR[${i}]: "${text}"`);
    }
  });
}

diagnose().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
