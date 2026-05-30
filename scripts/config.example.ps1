# Copy to config.ps1 and edit once (config.ps1 is gitignored).
#   Copy-Item config.example.ps1 config.ps1

$LanIp = "192.168.1.75"   # Your PC IPv4 from ipconfig
$ApiPort = 8000
$AdbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
