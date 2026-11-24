# TradeVision AI -- Live Showdown Launch Script
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   TRADEVISION AI -- LAUNCHING LIVE SHOWDOWN" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan

$ScriptDir = $PSScriptRoot
if (Test-Path "$ScriptDir\.venv\Scripts\python.exe") {
    $PythonExe = "$ScriptDir\.venv\Scripts\python.exe"
} elseif (Test-Path "$ScriptDir\backend\venv\Scripts\python.exe") {
    $PythonExe = "$ScriptDir\backend\venv\Scripts\python.exe"
} else {
    $PythonExe = "python"
}

$BackendDir = "$ScriptDir\backend"
$FrontendDir = "$ScriptDir\frontend\build\web"

$ChromeExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $ChromeExe)) {
    if (Test-Path "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe") {
        $ChromeExe = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    } elseif (Test-Path "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") {
        $ChromeExe = "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    }
}

# 1. Start Backend in separate visible console window
Write-Host "[1/3] Starting FastAPI Backend on http://127.0.0.1:8000..." -ForegroundColor Green
$backendScript = "try { `$host.ui.RawUI.WindowTitle = 'TradeVision AI - FastAPI Backend (:8000)' } catch {}; Set-Location '$BackendDir'; & '$PythonExe' -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendScript

# 2. Start Frontend in separate visible console window
Write-Host "[2/3] Starting Flutter Web Host on http://localhost:3000..." -ForegroundColor Green
$frontendScript = "try { `$host.ui.RawUI.WindowTitle = 'TradeVision AI - Flutter Web Frontend (:3000)' } catch {}; Set-Location '$FrontendDir'; & '$PythonExe' -m http.server 3000"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendScript

Write-Host "Waiting 3 seconds for services to bind..." -ForegroundColor DarkGray
Start-Sleep -Seconds 3

# 3. Check connectivity
$backendOk = $false
$frontendOk = $false

try {
    $resB = Invoke-WebRequest -Uri "http://127.0.0.1:8000/docs" -UseBasicParsing -TimeoutSec 3
    if ($resB.StatusCode -eq 200) { $backendOk = $true }
} catch {
    $backendOk = $false
}

try {
    $resF = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 3
    if ($resF.StatusCode -eq 200) { $frontendOk = $true }
} catch {
    $frontendOk = $false
}

Write-Host "Backend Status (Port 8000): $(if ($backendOk) {'ONLINE (200 OK)'} else {'STARTING...'})" -ForegroundColor $(if ($backendOk) {'Green'} else {'Yellow'})
Write-Host "Frontend Status (Port 3000): $(if ($frontendOk) {'ONLINE (200 OK)'} else {'STARTING...'})" -ForegroundColor $(if ($frontendOk) {'Green'} else {'Yellow'})

# 4. Open in Chrome
Write-Host "[3/3] Opening Frontend, Swagger Docs, and Personal Repo in Chrome..." -ForegroundColor Cyan
if (Test-Path $ChromeExe) {
    Start-Process $ChromeExe -ArgumentList "http://localhost:3000", "http://127.0.0.1:8000/docs", "https://github.com/CodeWidKrish/TradeVision-AI"
} else {
    Start-Process "http://localhost:3000"
    Start-Process "http://127.0.0.1:8000/docs"
    Start-Process "https://github.com/CodeWidKrish/TradeVision-AI"
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "   SHOWDOWN LIVE: BOTH SERVICES RUNNING ON CHROME!" -ForegroundColor White
Write-Host "   Frontend:      http://localhost:3000" -ForegroundColor Yellow
Write-Host "   Backend Docs:  http://127.0.0.1:8000/docs" -ForegroundColor Yellow
Write-Host "   Personal Repo: https://github.com/CodeWidKrish/TradeVision-AI" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Green
