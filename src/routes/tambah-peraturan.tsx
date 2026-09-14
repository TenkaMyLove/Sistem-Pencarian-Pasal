import { Hono } from 'hono';
import { requirePengelola, Env } from '../middleware/auth.js';
import { TambahPeraturanView } from '../views/tambah-peraturan.js';
import { crawlFromUrl, CrawlResult } from '../scraper/urlCrawler.js';

export const tambahPeraturanRoutes = new Hono<Env>();

tambahPeraturanRoutes.use('/tambah-peraturan', requirePengelola);
tambahPeraturanRoutes.use('/tambah-peraturan/*', requirePengelola);

// GET /tambah-peraturan
tambahPeraturanRoutes.get('/tambah-peraturan', (c) => {
  const user = c.get('user');
  return c.html(<TambahPeraturanView user={user} />);
});

// POST /tambah-peraturan
tambahPeraturanRoutes.post('/tambah-peraturan', async (c) => {
  const user = c.get('user');
  const body = await c.req.parseBody();

  const url = String(body.url || '').trim();
  const jenis_peraturan = String(body.jenis_peraturan || '').trim();
  const nomor = String(body.nomor || '').trim();
  const tahun = parseInt(String(body.tahun || '0'), 10);
  const judul = String(body.judul || '').trim();
  const wilayah = String(body.wilayah || 'Nasional').trim();
  const sektor = String(body.sektor || 'Lainnya').trim();

  const formValues: Record<string, string> = {
    url, jenis_peraturan, nomor, tahun: String(tahun), judul, wilayah, sektor,
  };

  // Validate
  if (!url) {
    return c.html(
      <TambahPeraturanView user={user} error="URL peraturan wajib diisi." formValues={formValues} />,
      400
    );
  }

  if (!jenis_peraturan || !nomor || !tahun || tahun < 1900) {
    return c.html(
      <TambahPeraturanView user={user} error="Jenis peraturan, nomor, dan tahun wajib diisi dengan benar." formValues={formValues} />,
      400
    );
  }

  // Run crawler (synchronous — user waits for result)
  let result: CrawlResult;
  try {
    result = await crawlFromUrl({
      url,
      jenis_peraturan,
      nomor,
      tahun,
      judul,
      wilayah,
      sektor,
      ditambahkan_oleh: user.username,
    });
  } catch (err: any) {
    return c.html(
      <TambahPeraturanView
        user={user}
        error={`Terjadi kesalahan saat crawling: ${err?.message || 'Unknown error'}`}
        formValues={formValues}
      />,
      500
    );
  }

  // Render result
  return c.html(
    <TambahPeraturanView user={user} result={result} formValues={{ ...formValues, url: '', nomor: '' }} />
  );
});
