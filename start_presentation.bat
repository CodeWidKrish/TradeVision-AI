@echo off
TITLE TradeVision AI - College Viva & Demo Launcher
COLOR 0B

echo ==============================================================================
echo               TRADEVISION AI - ONE-CLICK DEMO LAUNCHER
echo          Multi-Modal Equity Intelligence ^& Paper Trading Platform
echo ==============================================================================
echo.

cd /d "%~dp0"

:: 1. Check for Python virtual environment
set PYTHON_EXE=
if exist "backend\venv\Scripts\python.exe" (
    set PYTHON_EXE=backend\venv\Scripts\python.exe
) else if exist ".venv\Scripts\python.exe" (
    set PYTHON_EXE=.venv\Scripts\python.exe
) else (
    set PYTHON_EXE=python
)

echo [*] Detected Python environment: %PYTHON_EXE%

:: 2. Launch FastAPI Backend in a separate window
echo [*] Launching FastAPI Backend on http://127.0.0.1:8000 ...
start "TradeVision AI - Backend API" cmd /k "cd /d "%~dp0backend" && ..\%PYTHON_EXE% -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload"

:: 3. Give backend 2 seconds to initialize
timeout /t 2 /nobreak >nul

:: 4. Prompt for Launch Mode
echo.
echo ==============================================================================
echo  Select Frontend Launch Mode:
echo    [1] Instant Web (Opens in Chrome IMMEDIATELY in 1 sec) - RECOMMENDED FOR VIVA
echo    [2] Flutter Live Dev Server (Web-Server with Hot Reload)
echo    [3] Open Swagger API Documentation (127.0.0.1:8000/docs)
echo ==============================================================================
set /p TARGET_CHOICE="Enter selection [1, 2, or 3] (default is 1): "

if "%TARGET_CHOICE%"=="2" (
    echo.
    echo [*] Launching Flutter Web Server on port 3000...
    echo [*] Compiling web bundle in background; opening Chrome automatically...
    start "TradeVision AI - Flutter Web Server" cmd /k "cd /d "%~dp0frontend" && call flutter run -d web-server --web-port=3000"
    echo [*] Waiting 8 seconds for web server to initialize...
    timeout /t 8 /nobreak >nul
    start http://localhost:3000
) else if "%TARGET_CHOICE%"=="3" (
    echo.
    echo [*] Opening API Interactive Documentation...
    start http://127.0.0.1:8000/docs
) else (
    echo.
    echo [*] Starting Instant High-Performance Web Server on port 3000...
    start "TradeVision AI - Web Host" cmd /k "cd /d "%~dp0frontend\build\web" && ..\..\..\%PYTHON_EXE% -m http.server 3000"
    timeout /t 1 /nobreak >nul
    echo [*] Launching TradeVision AI in Google Chrome...
    start http://localhost:3000
)

echo.
echo ==============================================================================
echo [*] TradeVision AI services launched successfully!
echo [*] Backend:  http://127.0.0.1:8000
echo [*] Frontend: http://localhost:3000
echo ==============================================================================
pause
