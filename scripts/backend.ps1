# Backend only (current window)
#   .\scripts\backend.ps1

. "$PSScriptRoot\_common.ps1"
$cfg = Get-DevConfig

Set-Location $cfg.BackendDir
if (-not (Test-Path ".venv\Scripts\activate.ps1")) {
    Write-Host "First-time setup:" -ForegroundColor Yellow
    py -3.11 -m venv .venv
    . .venv\Scripts\activate
    pip install -r requirements.txt
    alembic upgrade head
} else {
    . .venv\Scripts\activate
}
uvicorn app.main:app --reload --host 0.0.0.0 --port $cfg.ApiPort
