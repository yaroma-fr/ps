# Перезапуск від імені адміністратора
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$url = "https://download.kerio.com/dwn/kerio-control-vpnclient-win64.exe"
$source = "C:\Temp\persistent.cfg"
$destination = "C:\Program Files (x86)\Kerio\VPN Client\persistent.cfg"

# Перевірка посилання
try {
    $request = [System.Net.WebRequest]::Create($url)
    $request.Method = "HEAD"
    $response = $request.GetResponse()
    $statusCode = [int]$response.StatusCode
    $response.Close()
} catch {
    $statusCode = 0
}

if ($statusCode -eq 200) {
    Write-Host "Посилання актуальне, завантажую..." -ForegroundColor Green

    (New-Object System.Net.WebClient).DownloadFile($url, "$env:TEMP\kerio-vpn.exe")
    Unblock-File -Path "$env:TEMP\kerio-vpn.exe"
    Start-Process "$env:TEMP\kerio-vpn.exe" -ArgumentList "/S" -Wait
    Write-Host "  [OK] Kerio VPN встановлено" -ForegroundColor Green

    # Копіюємо конфіг
    if (Test-Path $source) {
        Copy-Item -Path $source -Destination $destination -Force
        Write-Host "  [OK] persistent.cfg скопійовано" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Файл $source не знайдено" -ForegroundColor Red
    }
} else {
    Write-Host "Посилання недійсне або недоступне" -ForegroundColor Red
    Write-Host "Перевірте актуальне посилання на https://www.kerio.com/products/kerio-control/vpn-client" -ForegroundColor Yellow
}