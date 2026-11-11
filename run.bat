@echo off
chcp 65001 >nul
setlocal EnableExtensions
TITLE Orion Agro - Simulador 3D + Analise Agronomica
color 0A

REM ============================================================
REM  Orion Agro - inicia BACKEND (FastAPI :8000) + FRONTEND (:5501)
REM  Duplo clique neste arquivo (ou rode `run.bat` no CMD).
REM ============================================================

set "ROOT=%~dp0"
set "BACKEND_DIR=%ROOT%backend"
set "API_PORT=8000"
set "WEB_PORT=5501"

echo.
echo ============================================================
echo  Orion Agro - Simulador 3D de Talhoes + Analise Agronomica
echo  Iniciando backend (FastAPI) + frontend (estatico)
echo ============================================================
echo.

REM --- Python: testa de verdade cada candidato (3.11 a 3.13). O 3.14 ainda nao
REM     tem pacotes prontos para numpy/rasterio/pydantic fixados no requirements.
set "PY="
for %%V in (3.12 3.13 3.11) do (
    if not defined PY (
        py -%%V -c "import sys" >nul 2>&1 && set "PY=py -%%V"
    )
)
if not defined PY (
    python -c "import sys; sys.exit(0 if (3,11)<=sys.version_info[:2]<=(3,13) else 1)" >nul 2>&1 && set "PY=python"
)
if not defined PY (
    echo [ERRO] Nao encontrei um Python 3.11, 3.12 ou 3.13 funcionando.
    echo        O Python 3.14 nao serve para as dependencias do backend.
    echo        Instale o 3.12:  winget install Python.Python.3.12
    echo        ou baixe em https://www.python.org/downloads/release/python-3129/
    echo        ^(marque "Add python.exe to PATH"^) e rode este arquivo de novo.
    echo.
    pause
    exit /b 1
)
echo     Python encontrado: %PY%
echo.

REM --- 1. .env ---
echo [1/6] Validando arquivo de ambiente...
if not exist "%BACKEND_DIR%\.env.example" (
    echo [ERRO] backend\.env.example nao encontrado. Repositorio incompleto?
    pause
    exit /b 1
)
if not exist "%BACKEND_DIR%\.env" (
    copy /Y "%BACKEND_DIR%\.env.example" "%BACKEND_DIR%\.env" >nul
    if errorlevel 1 (
        echo [ERRO] Falha ao criar backend\.env a partir do .env.example.
        pause
        exit /b 1
    )
    echo     .env criado a partir do .env.example.
) else (
    echo     .env ja existe.
)
echo.

REM --- 2. Portas livres? (nao filtra por "LISTENING": no Windows pt-BR vem traduzido) ---
echo [2/6] Verificando portas %API_PORT% e %WEB_PORT%...
netstat -ano | findstr /R /C:":%API_PORT% *0\.0\.0\.0:0" /C:":%API_PORT% *\[::\]:0" >nul
if not errorlevel 1 (
    echo [ERRO] A porta %API_PORT% ja esta em uso. Feche o processo ou a janela "Orion Agro API" antiga.
    pause
    exit /b 1
)
netstat -ano | findstr /R /C:":%WEB_PORT% *0\.0\.0\.0:0" /C:":%WEB_PORT% *\[::\]:0" >nul
if not errorlevel 1 (
    echo [ERRO] A porta %WEB_PORT% ja esta em uso. Feche o processo ou a janela "Orion Agro Frontend" antiga.
    pause
    exit /b 1
)
echo     Portas livres.
echo.

REM --- 2b. Ambiente virtual (.venv) ---
set "VPY=%ROOT%.venv\Scripts\python.exe"
if not exist "%VPY%" (
    echo     Criando ambiente virtual .venv ...
    %PY% -m venv "%ROOT%.venv"
    if errorlevel 1 (
        echo [ERRO] Falha ao criar o ambiente virtual.
        pause
        exit /b 1
    )
)

REM --- 3. Dependencias ---
echo [3/6] Instalando/verificando dependencias do backend (1a vez demora)...
"%VPY%" -m pip install -r "%BACKEND_DIR%\requirements.txt" --quiet --disable-pip-version-check
if errorlevel 1 (
    echo [ERRO] Falha ao instalar dependencias. Verifique a internet e tente de novo.
    pause
    exit /b 1
)
echo     Dependencias ok.
echo.

REM --- 4. Backend em janela separada ---
echo [4/6] Iniciando backend FastAPI em http://localhost:%API_PORT% ...
start "Orion Agro API" /D "%BACKEND_DIR%" cmd /k ""%VPY%" -m uvicorn main:app --host 127.0.0.1 --port %API_PORT% --reload"

REM --- 5. Frontend em janela separada (serve a raiz do projeto) ---
echo [5/6] Iniciando frontend em http://localhost:%WEB_PORT% ...
start "Orion Agro Frontend" /D "%ROOT%" cmd /k ""%VPY%" -m http.server %WEB_PORT% --bind 127.0.0.1"

REM --- 6. Aguarda a API responder (ate ~40s) e abre o navegador ---
echo [6/6] Aguardando a API ficar pronta...
set /a TRIES=0
:waitapi
where curl >nul 2>&1
if errorlevel 1 (
    timeout /t 8 /nobreak >nul
    goto openbrowser
)
curl -s -o nul http://127.0.0.1:%API_PORT%/docs
if not errorlevel 1 goto openbrowser
set /a TRIES+=1
if %TRIES% GEQ 40 (
    echo     [AVISO] A API demorou a responder. Veja a janela "Orion Agro API" para erros.
    goto openbrowser
)
timeout /t 1 /nobreak >nul
goto waitapi

:openbrowser
start "" "http://localhost:%WEB_PORT%/fazendas.html"

echo.
echo ============================================================
echo  Aplicacao iniciada!
echo.
echo  Fazendas (gestao):    http://localhost:%WEB_PORT%/fazendas.html
echo  Analise agronomica:   http://localhost:%WEB_PORT%/analise.html
echo  Simulador 3D:         http://localhost:%WEB_PORT%/index.html
echo  Login / Cadastro:     http://localhost:%WEB_PORT%/auth.html
echo  API (Swagger):        http://localhost:%API_PORT%/docs
echo.
echo  Credenciais demo:     admin@orion.com / 123456
echo.
echo  Para encerrar: feche as janelas "Orion Agro API" e
echo  "Orion Agro Frontend" (ou CTRL+C em cada uma).
echo ============================================================
echo.
pause
endlocal
