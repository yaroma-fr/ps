# Перезапуск від імені адміністратора
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Install-App {
    param($Name, $Id)
    Write-Host "Встановлюємо $Name..." -ForegroundColor Cyan
    winget install $Id --accept-source-agreements --accept-package-agreements --silent
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] $Name встановлено" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Помилка встановлення $Name (код: $LASTEXITCODE)" -ForegroundColor Red
    }
}

$apps = @(
    @{ Name = "7-Zip";               Id = "7zip.7zip" },
    @{ Name = "VLC";                 Id = "VideoLAN.VLC" },
    @{ Name = "PDF24";               Id = "geeksoftwareGmbH.PDF24Creator" },
    @{ Name = "Google Chrome";       Id = "Google.Chrome" },
    @{ Name = "HP Support Assistant";Id = "HP.HPSupportAssistant" },
    @{ Name = "IrfanView";           Id = "IrfanSkiljan.IrfanView" },
    @{ Name = "IrfanView Plugins";   Id = "IrfanSkiljan.IrfanView.Plugins" },
    @{ Name = "IrfanView Мова UA";   Id = "IrfanSkiljan.IrfanView.LanguagePack.Ukrainian" },
    @{ Name = "Ghostscript";         Id = "ArtifexSoftware.GhostScript" },
    @{ Name = "Intel Driver & Support Assistant"; Id = "Intel.IntelDriverAndSupportAssistant" },
    @{ Name = "Microsoft Office 365";Id = "Microsoft.Office" }
)

foreach ($app in $apps) {
    Install-App -Name $app.Name -Id $app.Id
}

Write-Host "`nВстановлення завершено!" -ForegroundColor Green
Read-Host -Prompt "Натисніть Enter для виходу"