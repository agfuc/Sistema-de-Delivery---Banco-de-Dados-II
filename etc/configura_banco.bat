@echo off
setlocal enabledelayedexpansion
chcp 1252 >nul
cls

echo ===================================================
echo CONFIGURADOR AUTOMATICO DO BANCO - SISTEMA DELIVERY
echo ===================================================
echo.

:: Procura o psql
where psql >nul 2>nul
if %errorlevel% equ 0 (
    set "PSQL=psql"
) else (
    set "PSQL="
    for /L %%V in (18,-1,13) do (
        if exist "C:\Program Files\PostgreSQL\%%V\bin\psql.exe" (
            if not defined PSQL set "PSQL=C:\Program Files\PostgreSQL\%%V\bin\psql.exe"
        )
    )
    if not defined PSQL (
        echo [ERRO] psql.exe nao encontrado.
        pause
        exit /b 1
    )
)

echo [INFO] Usando: !PSQL!
echo.

set "BASE_DIR=%~dp0.."
set "SQL_DIR=%BASE_DIR%\sql"
set "ETC_DIR=%~dp0"

if not exist "!SQL_DIR!\criacao_banco.sql" (
    echo [ERRO] Nao encontrado: !SQL_DIR!\criacao_banco.sql
    pause
    exit /b 1
)

echo ===================================================
echo CREDENCIAIS DO POSTGRESQL
echo ===================================================
set /p "PG_HOST=Host [localhost]: "
if "!PG_HOST!"=="" set "PG_HOST=localhost"

set /p "PG_PORT=Porta [5432]: "
if "!PG_PORT!"=="" set "PG_PORT=5432"

set /p "PG_USER=Usuario [postgres]: "
if "!PG_USER!"=="" set "PG_USER=postgres"

if not defined PGPASSWORD (
    echo [ERRO] Configure PGPASSWORD no ambiente do processo usando um prompt seguro antes de executar.
    pause
    exit /b 1
)
echo.

echo ===================================================
echo [1/4] Recriando banco 'delivery'...
echo ===================================================
"!PSQL!" -h !PG_HOST! -p !PG_PORT! -U !PG_USER! -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'delivery' AND pid <> pg_backend_pid();" >nul 2>&1
"!PSQL!" -h !PG_HOST! -p !PG_PORT! -U !PG_USER! -d postgres -c "DROP DATABASE IF EXISTS delivery;" >nul 2>&1
"!PSQL!" -h !PG_HOST! -p !PG_PORT! -U !PG_USER! -d postgres -c "DROP ROLE IF EXISTS role_dba, role_cliente, role_restaurante, role_entregador;" >nul 2>&1
"!PSQL!" -h !PG_HOST! -p !PG_PORT! -U !PG_USER! -d postgres -c "DROP USER IF EXISTS usuario_dba, usuario_cliente, usuario_restaurante, usuario_entregador;" >nul 2>&1
"!PSQL!" -h !PG_HOST! -p !PG_PORT! -U !PG_USER! -d postgres -c "CREATE DATABASE delivery;"
if %errorlevel% neq 0 (
    echo [ERRO] Falha ao criar banco.
    set "PGPASSWORD="
    pause
    exit /b 1
)
echo [OK] Banco criado.

echo.
echo ===================================================
echo [2/4] Criando tabelas, roles, procedures e triggers...
echo ===================================================
"!PSQL!" -h !PG_HOST! -p !PG_PORT! -U !PG_USER! -d delivery -f "!SQL_DIR!\criacao_banco.sql"
if %errorlevel% neq 0 (
    echo [ERRO] Falha ao executar criacao_banco.sql.
    set "PGPASSWORD="
    pause
    exit /b 1
)
echo [OK] Estrutura criada.

echo.
echo ===================================================
echo [3/4] Corrigindo permissoes e populando dados...
echo ===================================================
"!PSQL!" -h !PG_HOST! -p !PG_PORT! -U !PG_USER! -d delivery -c "ALTER USER usuario_dba WITH BYPASSRLS;"
echo [OK] usuario_dba com BYPASSRLS.

"!PSQL!" -h !PG_HOST! -p !PG_PORT! -U !PG_USER! -d delivery -f "!SQL_DIR!\testes_banco.sql" >nul 2>&1
echo [OK] Script de testes executado.

echo.
echo ===================================================
echo [4/4] Inserindo dados essenciais garantidos...
echo ===================================================
"!PSQL!" -h !PG_HOST! -p !PG_PORT! -U !PG_USER! -d delivery -f "!ETC_DIR!seeds_manuais.sql"
echo [OK] Seeds inseridos.

echo.
echo ===================================================
echo RESUMO DO BANCO
echo ===================================================
"!PSQL!" -h !PG_HOST! -p !PG_PORT! -U !PG_USER! -d delivery -c "SELECT 'Pessoas' as tabela, COUNT(*) as registros FROM pessoa UNION ALL SELECT 'Restaurantes', COUNT(*) FROM restaurante UNION ALL SELECT 'Produtos', COUNT(*) FROM produto UNION ALL SELECT 'Entregadores', COUNT(*) FROM entregador;"

echo.
echo ===================================================
echo IDs atuais de restaurante e produtos:
echo ===================================================
"!PSQL!" -h !PG_HOST! -p !PG_PORT! -U !PG_USER! -d delivery -c "SELECT id, nome FROM restaurante; SELECT id, nome FROM produto;"

echo.
echo ===================================================
echo BANCO CONFIGURADO COM SUCESSO!
echo Para rodar o app: cd nosql-app e mvn exec:java
echo ===================================================

set "PGPASSWORD="
pause
