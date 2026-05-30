# One command: backend (new window) + flutter (Wi‑Fi, no adb)
# From repo root:  .\scripts\dev-wifi.ps1

. "$PSScriptRoot\_common.ps1"
$cfg = Get-DevConfig

Start-BackendWindow $cfg
Wait-BackendHealth -Port $cfg.ApiPort | Out-Null

$apiUrl = "http://$($cfg.LanIp):$($cfg.ApiPort)"
Write-Host "Flutter API URL: $apiUrl (phone must be on same Wi‑Fi)" -ForegroundColor Cyan
Start-FlutterApp -ApiBaseUrl $apiUrl -Config $cfg
