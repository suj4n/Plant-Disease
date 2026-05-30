# First-time project setup
#   .\scripts\setup.ps1

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
$cfg = Get-DevConfig

Write-Host "=== Backend ===" -ForegroundColor Cyan
Set-Location $cfg.BackendDir
if (-not (Test-Path ".venv")) { py -3.11 -m venv .venv }
. .venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head

Write-Host "=== Flutter ===" -ForegroundColor Cyan
Set-Location $cfg.FlutterDir
flutter pub get

Write-Host "`nDone. Run: .\scripts\dev-usb.ps1  or  .\scripts\dev-wifi.ps1" -ForegroundColor Green
