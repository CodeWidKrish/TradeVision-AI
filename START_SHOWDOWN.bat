@echo off
title TradeVision AI - One-Click Showdown Launcher
color 0b
echo ==============================================================================
echo                 TRADEVISION AI -- LIVE SHOWDOWN LAUNCHER
echo ==============================================================================
echo.

set SCRIPT_DIR=%~dp0
set PYTHON_EXE=
if exist "%SCRIPT_DIR%.venv\Scripts\python.exe" (
    set PYTHON_EXE=%SCRIPT_DIR%.venv\Scripts\python.exe
) else if exist "%SCRIPT_DIR%backend\venv\Scripts\python.exe" (
    set PYTHON_EXE=%SCRIPT_DIR%backend\venv\Scripts\python.exe
) else (
    set PYTHON_EXE=python
)

set CHROME_EXE=C:\Program Files\Google\Chrome\Application\chrome.exe
if not exist "%CHROME_EXE%" (
    if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
        set CHROME_EXE=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
    ) else if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" (
        set CHROME_EXE=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe
    )
)

echo [*] Detected Python Environment: %PYTHON_EXE%
echo [*] Starting FastAPI Backend on http://127.0.0.1:8000...
start "TradeVision Backend (FastAPI :8000)" cmd /k "cd /d "%SCRIPT_DIR%backend" && "%PYTHON_EXE%" -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload"

echo [*] Starting Flutter Web Host on http://localhost:3000...
start "TradeVision Frontend Web (:3000)" cmd /k "cd /d "%SCRIPT_DIR%frontend\build\web" && "%PYTHON_EXE%" -m http.server 3000"

echo [*] Waiting 3 seconds for servers to initialize...
timeout /t 3 /nobreak >nul

echo [*] Opening Live App, Swagger Docs, and GitHub in Chrome...
if exist "%CHROME_EXE%" (
    start "" "%CHROME_EXE%" "http://localhost:3000" "http://127.0.0.1:8000/docs" "https://github.com/CodeWidKrish/TradeVision-AI"
) else (
    start http://localhost:3000
    start http://127.0.0.1:8000/docs
    start https://github.com/CodeWidKrish/TradeVision-AI
)

echo.
echo ==============================================================================
echo ALL SERVICES ARE LIVE!
echo   - Frontend:      http://localhost:3000
echo   - Backend Docs:  http://127.0.0.1:8000/docs
echo   - Personal Repo: https://github.com/CodeWidKrish/TradeVision-AI
echo ==============================================================================
echo.
pause
