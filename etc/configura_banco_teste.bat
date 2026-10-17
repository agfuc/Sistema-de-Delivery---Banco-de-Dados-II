@echo off
cls
echo ===================================================
echo 1. RECRIANDO O BANCO DE DADOS...
echo ===================================================
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U postgres -d postgres -c "DROP DATABASE IF EXISTS delivery;"
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U postgres -d postgres -c "CREATE DATABASE delivery;"

echo.
echo ===================================================
echo 2. CRIANDO TABELAS E POPULANDO DADOS...
echo ===================================================
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U postgres -d delivery -f "..\sql\criacao_banco.sql"
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U postgres -d delivery -f "..\sql\testes_banco.sql"

echo.
echo ===================================================
echo FINALIZADO COM SUCESSO!
echo ===================================================
pause