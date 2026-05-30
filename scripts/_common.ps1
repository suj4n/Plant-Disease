$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")

function Get-DevConfig {
    $configPath = Join-Path $ScriptDir "config.ps1"
    if (-not (Test-Path $configPath)) {
        Write-Host "Missing scripts\config.ps1 — copying from config.example.ps1" -ForegroundColor Yellow
        Copy-Item (Join-Path $ScriptDir "config.example.ps1") $configPath
        Write-Host "Edit scripts\config.ps1 (set LanIp) then run again." -ForegroundColor Yellow
    }
    . $configPath
    return @{
        RepoRoot   = $RepoRoot
        BackendDir = Join-Path $RepoRoot "backend"
        FlutterDir = Join-Path $RepoRoot "flutter"
        LanIp      = $LanIp
        ApiPort    = $ApiPort
        AdbPath    = $AdbPath
    }
}

function Start-BackendWindow {
    param($Config)
    $cmd = @"
cd '$($Config.BackendDir)'
if (-not (Test-Path '.venv\Scripts\activate.ps1')) {
  Write-Host 'Run: py -3.11 -m venv .venv; .venv\Scripts\pip install -r requirements.txt; alembic upgrade head' -ForegroundColor Red
  pause
  exit 1
}
. .venv\Scripts\activate
Write-Host 'PlantDoc API — http://127.0.0.1:$($Config.ApiPort)' -ForegroundColor Green
uvicorn app.main:app --reload --host 0.0.0.0 --port $($Config.ApiPort)
"@
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $cmd
    Write-Host "Backend starting in a new window…" -ForegroundColor Cyan
}

function Wait-BackendHealth {
    param([int]$Port = 8000, [int]$MaxWaitSeconds = 90)
    $url = "http://127.0.0.1:$Port/health"
    $deadline = (Get-Date).AddSeconds($MaxWaitSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2
            if ($r.StatusCode -eq 200) {
                Write-Host "Backend ready." -ForegroundColor Green
                return $true
            }
        } catch { Start-Sleep -Seconds 2 }
    }
    Write-Host "Backend not ready yet — Flutter may fail until /health works." -ForegroundColor Yellow
    return $false
}

function Invoke-AdbReverse {
    param($Config)
    if (-not (Test-Path $Config.AdbPath)) {
        Write-Host "adb not found at $($Config.AdbPath). Install Android SDK platform-tools or fix AdbPath in config.ps1." -ForegroundColor Red
        return $false
    }
    & $Config.AdbPath devices | Out-Host
    & $Config.AdbPath reverse "tcp:$($Config.ApiPort)" "tcp:$($Config.ApiPort)"
    Write-Host "adb reverse tcp:$($Config.ApiPort) tcp:$($Config.ApiPort) OK" -ForegroundColor Green
    return $true
}

function Start-FlutterApp {
    param(
        [string]$ApiBaseUrl,
        $Config
    )
    Push-Location $Config.FlutterDir
    try {
        flutter pub get | Out-Null
        flutter run --dart-define=API_BASE_URL=$ApiBaseUrl
    } finally {
        Pop-Location
    }
}
