# Перезапуск від імені адміністратора
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$repoUrl = "https://github.com/yaroma-fr/ps/archive/refs/heads/main.zip"
$zipPath = "$env:TEMP\repo.zip"
$extractPath = "C:\Temp"

# Завантаження
Write-Host "Завантажую..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath -UseBasicParsing

# Розпакування
Write-Host "Розпаковую..." -ForegroundColor Yellow
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

# Видалення архіву
Remove-Item $zipPath -Force

Write-Host "Готово. Скрипти знаходяться в $extractPath" -ForegroundColor Green