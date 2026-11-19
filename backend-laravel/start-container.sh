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

echo "Starting FrankenPHP server..."

# 6. Jalankan FrankenPHP sesuai entrypoint resmi Railpack
exec docker-php-entrypoint --config /Caddyfile --adapter caddyfile 2>&1
