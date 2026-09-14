import fetch from 'node-fetch';
import * as cheerio from 'cheerio';
import pg from 'pg';
import dotenv from 'dotenv';
dotenv.config();

const { Client } = pg;
const client = new Client({ connectionString: process.env.DATABASE_URL });
await client.connect();

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8',
};

const LABEL_TO_KEY = {
  'mencabut':                  'mencabut',
  'mencabut sebagian':         'mencabut_sebagian',
  'diubah dengan':             'diubah_dengan',
  'dicabut dengan':            'dicabut_dengan',
  'dicabut sebagian dengan':   'dicabut_sebagian_dengan',
  'mengubah':                  'mengubah',
  'ditetapkan':                'ditetapkan',
};

function normalizeLabel(raw) {
  const clean = raw.toLowerCase().replace(/\s*:\s*$/, '').trim();
  return LABEL_TO_KEY[clean] || null;
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function fetchStatusPeraturan(detailUrl) {
  try {
    const res = await fetch(detailUrl, { headers: HEADERS, redirect: 'follow' });
    if (!res.ok) {
      console.warn(`  HTTP ${res.status} for ${detailUrl}`);
      return null;
    }

    const html = await res.text();
    const $ = cheerio.load(html);

    const result = {};

    $('div.col-12.fw-semibold.bg-light-primary').each((_, labelEl) => {
      const labelText = $(labelEl).text().trim();
      const key = normalizeLabel(labelText);
      if (!key) return;

      const itemsContainer = $(labelEl).closest('.row').next('.row');
      const items = [];

      itemsContainer.find('li').each((_, li) => {
        const $li = $(li);
        const $a = $li.find('a').first();
        const href = $a.attr('href') || '';
        const linkLabel = $a.text().trim();

        const fullUrl = href.startsWith('http')
          ? href
          : href ? `https://peraturan.bpk.go.id${href}` : '';

        const $liClone = $li.clone();
        $liClone.find('a').remove();
        $liClone.find('span.text-muted').remove();

        let keterangan = $liClone.find('span').not('.text-muted').text().trim()
          .replace(/\r\n/g, ' ').replace(/\s+/g, ' ').trim();

        const fullLiText = $li.text().trim().replace(/\s+/g, ' ');
        const tentangIdx = fullLiText.indexOf('tentang');
        let titlePart = '';
        if (tentangIdx !== -1) {
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
    console.warn(`  Fetch error: ${err.message}`);
    return null;
  }
}

// Get all regulations with BPK URLs
const regs = await client.query(`
  SELECT id, jenis_peraturan, nomor, tahun, judul, url_dokumen_asli, status_detail, status_detail_json
  FROM peraturan
  WHERE url_dokumen_asli LIKE '%peraturan.bpk.go.id%'
  ORDER BY id ASC;
`);

console.log(`Found ${regs.rows.length} BPK regulations to process.\n`);

let updated = 0;
let skipped = 0;

for (const reg of regs.rows) {
  const label = `${reg.jenis_peraturan} No. ${reg.nomor} Tahun ${reg.tahun}`;
  console.log(`Processing ID ${reg.id}: ${label}...`);

  const statusJson = await fetchStatusPeraturan(reg.url_dokumen_asli);

  if (statusJson && Object.keys(statusJson).length > 0) {
    const categories = Object.keys(statusJson);
    const totalItems = Object.values(statusJson).reduce((sum, arr) => sum + arr.length, 0);
    console.log(`  -> Found ${categories.join(', ')} (${totalItems} items)`);

    const summaryParts = categories.map((cat) => {
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

    updated++;
  } else {
    console.log(`  -> No status relations section found.`);
    skipped++;
  }

  await sleep(1000);
}

console.log(`\n=== FINISHED ===`);
console.log(`Updated: ${updated} | Skipped: ${skipped}`);

await client.end();
