@echo off
cd /d "%~dp0backend-laravel"
echo Menjalankan Server Laravel P3H Kemenkum Kalsel di http://localhost:3000 ...
php artisan serve --host=127.0.0.1 --port=3000
