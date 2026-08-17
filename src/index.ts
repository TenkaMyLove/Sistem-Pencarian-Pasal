import { Hono } from 'hono';
import { serve } from '@hono/node-server';
import { serveStatic } from '@hono/node-server/serve-static';
import dotenv from 'dotenv';

import { authRoutes } from './routes/auth.js';
import { searchRoutes } from './routes/search.js';
import { jadwalRoutes } from './routes/jadwal.js';
import { adminRoutes } from './routes/admin.js';
import { runRecrawlCheck } from './scraper/recrawl.js';

dotenv.config();

const app = new Hono();

// Serve static assets from public directory (e.g. /css/style.css)
app.use('/css/*', serveStatic({ root: './public' }));
app.use('/favicon.ico', serveStatic({ path: './public/favicon.ico' }));

// Health check endpoint (Public)
app.get('/api/health', (c) => c.json({ status: 'ok', app: 'P3H Kemenkum Kalsel', timestamp: new Date() }));

// cPanel Cron Job Trigger Endpoint (Public - SCRP-7 / SCRP-10)
app.get('/api/cron/recrawl', async (c) => {
  const result = await runRecrawlCheck();
  return c.json({
    message: 'cPanel Cron Job execution completed',
    result,
  });
});

// Register feature routes
app.route('/', authRoutes);
app.route('/', searchRoutes);
app.route('/', jadwalRoutes);
app.route('/', adminRoutes);

// Fallback 404 Error Page
app.notFound((c) => {
  return c.html(`
    <html lang="id">
      <head>
        <title>404 - Halaman Tidak Ditemukan</title>
        <link rel="stylesheet" href="/css/style.css">
      </head>
      <body style="display:flex; align-items:center; justify-content:center; min-height:100vh;">
        <div class="empty-state">
          <h3>404 - Halaman Tidak Ditemukan</h3>
          <p>Halaman yang Anda cari tidak tersedia pada sistem P3H Kemenkum Kalsel.</p>
          <a href="/pencarian" class="btn-search" style="display:inline-flex; text-decoration:none; margin-top:1rem;">Kembali ke Utama</a>
        </div>
      </body>
    </html>
  `, 404);
});

const port = parseInt(process.env.PORT || '3000', 10);

console.log(`Server P3H Kemenkum Kalsel running at http://localhost:${port}`);

serve({
  fetch: app.fetch,
  port,
});
