# ==============================================================================
# TradeVision AI — One-Click Viva & Demo Launcher (PowerShell)
# ==============================================================================

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "              TRADEVISION AI — ONE-CLICK DEMO LAUNCHER" -ForegroundColor White
Write-Host "         Multi-Modal Equity Intelligence & Paper Trading Platform" -ForegroundColor DarkCyan
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Locate Python virtual environment
$PythonExe = "python"
if (Test-Path "$ScriptDir\backend\venv\Scripts\python.exe") {
    $PythonExe = "$ScriptDir\backend\venv\Scripts\python.exe"
} elseif (Test-Path "$ScriptDir\.venv\Scripts\python.exe") {
    $PythonExe = "$ScriptDir\.venv\Scripts\python.exe"
}

Write-Host "[*] Utilizing Python executable: $PythonExe" -ForegroundColor Green

# 2. Start FastAPI Backend in a new window
Write-Host "[*] Launching FastAPI Backend on http://127.0.0.1:8000..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$ScriptDir\backend'; & '$PythonExe' -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload"

# 3. Allow server 2 seconds to spin up
Start-Sleep -Seconds 2

# 4. Prompt for Launch Mode
Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " Select Frontend Launch Mode:" -ForegroundColor White
Write-Host "   [1] Instant Web (Opens Chrome IMMEDIATELY in 1 sec) - RECOMMENDED FOR VIVA" -ForegroundColor Green
Write-Host "   [2] Flutter Live Dev Server (Web-Server with Hot Reload)" -ForegroundColor Yellow
Write-Host "   [3] Open Swagger API Documentation (127.0.0.1:8000/docs)" -ForegroundColor Magenta
Write-Host "==============================================================================" -ForegroundColor Cyan

$choice = Read-Host "Enter selection [1, 2, or 3] (default is 1)"

if ($choice -eq "2") {
    Write-Host "[*] Launching Flutter Web Server on port 3000..." -ForegroundColor Green
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$ScriptDir\frontend'; flutter run -d web-server --web-port=3000"
    Start-Sleep -Seconds 8
    Start-Process "http://localhost:3000"
} elseif ($choice -eq "3") {
    Write-Host "[*] Opening Swagger Docs..." -ForegroundColor Green
    Start-Process "http://127.0.0.1:8000/docs"
} else {
    Write-Host "[*] Starting Instant Web Host on port 3000..." -ForegroundColor Green
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$ScriptDir\frontend\build\web'; & '$PythonExe' -m http.server 3000"
    Start-Sleep -Seconds 1
    Write-Host "[*] Launching TradeVision AI in Chrome..." -ForegroundColor Green
    Start-Process "http://localhost:3000"
}

Write-Host ""
Write-Host "[*] TradeVision AI launched! Frontend: http://localhost:3000 | Backend: http://127.0.0.1:8000" -ForegroundColor Cyan
