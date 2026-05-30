# One command: backend (new window) + adb reverse + flutter (USB)
# From repo root:  .\scripts\dev-usb.ps1

. "$PSScriptRoot\_common.ps1"
$cfg = Get-DevConfig

Start-BackendWindow $cfg
Wait-BackendHealth -Port $cfg.ApiPort | Out-Null
Invoke-AdbReverse $cfg | Out-Null

$apiUrl = "http://127.0.0.1:$($cfg.ApiPort)"
Write-Host "Flutter API URL: $apiUrl" -ForegroundColor Cyan
Start-FlutterApp -ApiBaseUrl $apiUrl -Config $cfg
