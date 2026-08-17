import fetch from 'node-fetch';
import * as cheerio from 'cheerio';
import * as fs from 'fs';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8',
};

async function diagnose() {
  // Try BPK search with jenis filter j= and tahun filter t=
  // From the form we saw: action="/Search"
  // Let's try: ?q=Keuangan+Negara&j=Undang-Undang&t=2003
  const tests = [
    'https://peraturan.bpk.go.id/Search?q=Keuangan+Negara&j=Undang-Undang&t=2003',
    'https://peraturan.bpk.go.id/Search?q=Keuangan+Negara&Jenis=Undang-Undang&Tahun=2003',
    'https://peraturan.bpk.go.id/Search?q=17+2003+keuangan+negara',
    'https://peraturan.bpk.go.id/Tahun/2003', // Browse by year
    'https://peraturan.bpk.go.id/Jenis/1',    // Browse by jenis
  ];

  for (const url of tests) {
    console.log(`\nFetching: ${url}`);
    try {
      const res = await fetch(url, { headers: HEADERS, redirect: 'follow' });
      console.log(`Status: ${res.status}, Final URL: ${res.url}`);
      const html = await res.text();
      const $ = cheerio.load(html);

      // Count /Details/ links
      const details = $('a[href*="/Details/"]');
      console.log(`/Details/ links: ${details.length}`);
      details.each((i, el) => {
        if (i >= 5) return;
        const href = $(el).attr('href') || '';
        const text = $(el).text().trim().substring(0, 80);
        console.log(`  [${i}] ${href} | "${text}"`);
      });
    } catch (e) {
      console.error(`  Error: ${e}`);
    }
  }

  // Also inspect the search form inputs to understand filter params
  console.log('\n\n=== SEARCH FORM INPUTS ===');
  const mainRes = await fetch('https://peraturan.bpk.go.id/Search?q=Keuangan+Negara', { headers: HEADERS });
  const mainHtml = await mainRes.text();
  const $main = cheerio.load(mainHtml);
  $main('select, input[type=text], input[type=hidden]').each((_, el) => {
    const name = $main(el).attr('name') || '';
    const val = $main(el).attr('value') || '';
    const opts = $main(el).find('option').map((__, o) => `${$main(o).attr('value')}=${$main(o).text().trim()}`).get().slice(0, 5);
    if (name) console.log(`  ${el.tagName} name="${name}" value="${val}" options=[${opts.join(', ')}]`);
  });
}

diagnose().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
