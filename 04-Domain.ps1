# Перезапуск від імені адміністратора
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName Microsoft.VisualBasic

$NewName = [Microsoft.VisualBasic.Interaction]::InputBox("Введіть нову назву комп'ютера", "Перейменування", $env:COMPUTERNAME)

if ($NewName -eq "") {
    Write-Host "Назву не введено, скрипт зупинено" -ForegroundColor Red
    exit 1
}

Write-Host "Перейменовуємо та вводимо в домен..." -ForegroundColor Cyan

Add-Computer -DomainName "adsapience.com" -NewName $NewName -Credential (Get-Credential)

Write-Host "УВАГА: для застосування змін потрібно перезавантажити комп'ютер." -ForegroundColor Yellow

Read-Host -Prompt "Натисніть Enter для виходу"