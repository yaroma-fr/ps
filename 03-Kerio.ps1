# Перезапуск від імені адміністратора
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$url = "https://download.kerio.com/dwn/kerio-control-vpnclient-win64.msi"
$msiPath = "$env:TEMP\kerio-control-vpnclient.msi"
$source = "$PSScriptRoot\persistent.cfg"
$destination = "C:\Program Files (x86)\Kerio\VPN Client\persistent.cfg"

# 1. Перевірка посилання та завантаження
Write-Host "Перевіряємо посилання..." -ForegroundColor Cyan
try {
    $request = [System.Net.WebRequest]::Create($url)
    $request.Method = "HEAD"
    $response = $request.GetResponse()
    $statusCode = [int]$response.StatusCode
    $response.Close()
} catch {
    $statusCode = 0
}

if ($statusCode -ne 200) {
    Write-Host "  [FAIL] Посилання недійсне або недоступне" -ForegroundColor Red
    Write-Host "  Перевірте актуальне посилання на https://www.kerio.com/products/kerio-control/vpn-client" -ForegroundColor Yellow
    exit 1
}

Write-Host "  [OK] Посилання актуальне, завантажую..." -ForegroundColor Green
(New-Object System.Net.WebClient).DownloadFile($url, $msiPath)
Unblock-File -Path $msiPath
Write-Host "  [OK] Завантажено" -ForegroundColor Green

# 2. Тихе встановлення через MSI
Write-Host "Встановлюємо Kerio Control VPN Client..." -ForegroundColor Cyan
Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait
Write-Host "  [OK] Встановлено" -ForegroundColor Green

# 3. Зупинка служби
Write-Host "Зупиняємо службу VPN..." -ForegroundColor Cyan
Stop-Service -Name "Kerio Control VPN Client Service" -Force
Write-Host "  [OK] Службу зупинено" -ForegroundColor Green

# 4. Копіювання конфігурації
Write-Host "Копіюємо persistent.cfg..." -ForegroundColor Cyan
if (Test-Path $source) {
    Copy-Item -Path $source -Destination $destination -Force
    Write-Host "  [OK] persistent.cfg скопійовано" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Файл $source не знайдено" -ForegroundColor Red
}

# 5. Запуск служби
Write-Host "Запускаємо службу VPN..." -ForegroundColor Cyan
Start-Service -Name "Kerio Control VPN Client Service"
Write-Host "  [OK] Службу запущено" -ForegroundColor Green

Write-Host "`nГотово!" -ForegroundColor Green
Read-Host -Prompt "Натисніть Enter для виходу"