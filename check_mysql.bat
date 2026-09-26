@echo off
SET MYSQL=C:\laragon\bin\mysql\mysql-8.4.3-winx64\bin\mysql.exe
%MYSQL% -u root p3h_kemenkum_kalsel -e "SELECT 'peraturan' AS tabel, COUNT(*) AS total FROM peraturan UNION ALL SELECT 'pasal', COUNT(*) FROM pasal UNION ALL SELECT 'pengguna', COUNT(*) FROM pengguna UNION ALL SELECT 'jadwal', COUNT(*) FROM jadwal_rapat_harmonisasi;"
