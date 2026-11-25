#!/bin/bash
set -e

echo "Starting Sistem Pencarian Pasal..."

# 1. Hapus cache config/route/event sisa build-time agar env runtime Railway terbaca
php artisan optimize:clear || true

# 2. Pastikan direktori storage & cache writable
mkdir -p storage/framework/{sessions,views,cache,testing} storage/logs bootstrap/cache
chmod -R a+rw storage bootstrap/cache || true

# 3. Buat symlink storage (abaikan jika sudah ada)
php artisan storage:link || true

# 4. Cache ulang config/route/view dengan env runtime yang sebenarnya
php artisan config:cache
php artisan route:cache
php artisan view:cache

# 5. Jalankan migrasi jika tidak di-skip (aman jika tabel sudah ada)
if [ "${RAILPACK_SKIP_MIGRATIONS:-false}" != "true" ]; then
    php artisan migrate --force || echo "Warning: migration skipped or already up to date"
fi

# 6. Scheduler Laravel di latar belakang (Web Push jadwal rapat tiap menit mulai 08:00 WITA).
#    Dijalankan ulang otomatis bila berhenti. Set DISABLE_SCHEDULER=true untuk mematikan.
if [ "${DISABLE_SCHEDULER:-false}" != "true" ]; then
    echo "Starting Laravel scheduler..."
    ( while true; do php artisan schedule:work 2>&1; echo "Scheduler stopped, restarting in 5s..."; sleep 5; done ) &
fi

echo "Starting FrankenPHP server..."

# 7. Jalankan FrankenPHP sesuai entrypoint resmi Railpack
exec docker-php-entrypoint --config /Caddyfile --adapter caddyfile 2>&1
