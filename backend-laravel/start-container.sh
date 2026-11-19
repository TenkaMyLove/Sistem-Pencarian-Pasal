#!/usr/bin/env bash
set -e

# ============================================================
# Custom startup script for Railway (Railpack + FrankenPHP)
# ============================================================
# Railpack runs `php artisan config:cache` during BUILD time,
# but Railway env vars (DB_HOST, DB_PASSWORD, etc.) are NOT
# available at build time. So the cached config has wrong values.
# This script clears that stale cache at RUNTIME before starting.
# ============================================================

echo "🚀 Starting Sistem Pencarian Pasal..."

# 1. Clear the stale build-time config cache
echo "🔧 Clearing build-time config cache..."
php artisan config:clear
php artisan event:clear
php artisan route:clear

# 2. Re-cache config with actual runtime env vars
echo "🔧 Re-caching config with runtime environment variables..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# 3. Ensure storage directories exist and are writable
mkdir -p storage/framework/{sessions,views,cache,testing} storage/logs bootstrap/cache
chmod -R a+rw storage bootstrap/cache

# 4. Run migrations (unless explicitly skipped)
if [ "${RAILPACK_SKIP_MIGRATIONS:-false}" != "true" ]; then
    echo "🔧 Running database migrations..."
    php artisan migrate --force || echo "⚠️ Migration skipped (may already be up to date)"
fi

echo "✅ Setup complete, starting FrankenPHP..."

# 5. Start FrankenPHP (Caddy) — the default Railpack runtime
exec frankenphp run --config /etc/caddy/Caddyfile
