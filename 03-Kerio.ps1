$url = "https://download.kerio.com/dwn/kerio-control-vpnclient-win64.exe"

try {
    $response = Invoke-WebRequest -Uri $url -Method Head
    if ($response.StatusCode -eq 200) {
        Write-Host "Посилання актуальне, завантажую..." -ForegroundColor Green
        Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\kerio-vpn.exe" -UseBasicParsing
        Start-Process "$env:TEMP\kerio-vpn.exe" -Wait
    }
} catch {
    Write-Host "Посилання недійсне або недоступне: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Перевірте актуальне посилання на https://www.kerio.com/products/kerio-control/vpn-client" -ForegroundColor Yellow
}

$source = "C:\Temp\persistent.cfg"  # шлях до вашого файлу
$destination = "C:\Program Files (x86)\Kerio\VPN Client\persistent.cfg"

Copy-Item -Path $source -Destination $destination -Force