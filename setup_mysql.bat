@echo off
SET MYSQL=C:\laragon\bin\mysql\mysql-8.4.3-winx64\bin\mysql.exe
echo Mengimpor skema database...
%MYSQL% -u root p3h_kemenkum_kalsel < src\db\schema_mysql.sql
echo Mengimpor data peraturan & pasal...
%MYSQL% -u root p3h_kemenkum_kalsel < database_dump_mysql.sql
echo Data imported successfully.
