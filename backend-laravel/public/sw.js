const CACHE_NAME = 'p3h-kalsel-v1';
const STATIC_ASSETS = [
  '/css/style.css',
  '/js/tailwind-config.js',
  '/js/quote-clamp.js',
  '/images/logo.png',
  '/images/icon-192.png',
  '/images/icon-512.png',
  '/images/apple-touch-icon.png',
  '/manifest.json',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(STATIC_ASSETS)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  // Cache-first untuk aset statis
  if (STATIC_ASSETS.includes(url.pathname)) {
    event.respondWith(
      caches.match(request).then((cached) =>
        cached || fetch(request).then((res) => {
          const copy = res.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
          return res;
        })
      )
    );
    return;
  }

  // Network-first untuk halaman dinamis & HTMX
  event.respondWith(
    fetch(request).catch(() =>
      caches.match(request).then(
        (cached) =>
          cached ||
          new Response(
            '<!DOCTYPE html><html lang="id"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Offline - P3H Kemenkum Kalsel</title><style>body{font-family:Inter,system-ui,sans-serif;background:#0e1c2f;color:#fff;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;padding:1.5rem;text-align:center}.box{max-width:360px;background:#fff;color:#0f172a;padding:2rem;border-radius:12px}h1{font-size:18px;margin:0 0 .5rem}p{font-size:14px;color:#475569;margin:0 0 1.25rem}button{background:#0e1c2f;color:#fff;border:0;padding:.75rem 1.25rem;border-radius:6px;font-weight:600;cursor:pointer}</style></head><body><div class="box"><h1>Koneksi Terputus</h1><p>Tidak dapat terhubung ke server P3H Kemenkum Kalsel. Periksa koneksi internet Anda lalu coba lagi.</p><button onclick="location.reload()">Muat Ulang</button></div></body></html>',
            { status: 503, headers: { 'Content-Type': 'text/html; charset=utf-8' } }
          )
      )
    )
  );
});
