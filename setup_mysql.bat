@echo off
SET MYSQL=C:\laragon\bin\mysql\mysql-8.4.3-winx64\bin\mysql.exe
%MYSQL% -u root p3h_kemenkum_kalsel < database_dump_mysql.sql
echo Data imported successfully.
