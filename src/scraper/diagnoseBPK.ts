import fetch from 'node-fetch';
import * as fs from 'fs';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8',
};

async function diagnose() {
  // 1. Check BPK search page structure
  const bpkSearch = 'https://peraturan.bpk.go.id/Search?q=UU+Nomor+17+Tahun+2003';
  console.log(`Fetching: ${bpkSearch}`);
  const res = await fetch(bpkSearch, { headers: HEADERS, redirect: 'follow' });
  console.log(`Status: ${res.status}`);
  const html = await res.text();
  fs.writeFileSync('bpk_search_debug.html', html, 'utf-8');
  console.log(`Saved ${html.length} bytes to bpk_search_debug.html`);

  // Print first 3000 chars to see structure
  console.log('\n--- HTML SAMPLE (first 3000 chars) ---');
  console.log(html.substring(0, 3000));

  // Also check if there's a JSON/API endpoint
  console.log('\n--- Checking for /Details/ links ---');
  const detailMatches = html.match(/href="[^"]*\/Details\/[^"]*"/g) || [];
  console.log(`Found ${detailMatches.length} /Details/ href matches:`);
  detailMatches.slice(0, 10).forEach(m => console.log(' ', m));

  // Check all hrefs
  const allHrefs = html.match(/href="[^"]{5,}"/g) || [];
  console.log(`\nTotal hrefs: ${allHrefs.length}`);
  console.log('Sample hrefs:');
  allHrefs.slice(0, 20).forEach(h => console.log(' ', h));
}

diagnose().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
