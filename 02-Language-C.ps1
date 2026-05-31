# Перезапуск від імені адміністратора
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Перевірка доступності Install-Language
if (-not (Get-Command Install-Language -ErrorAction SilentlyContinue)) {
    Write-Host "Install-Language недоступна на цій системі" -ForegroundColor Red
    exit 1
}

Write-Host "Встановлюємо мовний пакет uk-UA..." -ForegroundColor Cyan
Install-Language uk-UA -CopyToSettings

Write-Host "Налаштовуємо список мов..." -ForegroundColor Cyan
# Англійська перша (за замовчуванням), українська друга
Set-WinUserLanguageList "en-US", "uk-UA" -Force

# Додаємо розширену українську розкладку
$LangList = Get-WinUserLanguageList
$UkLang = $LangList | Where-Object { $_.LanguageTag -eq "uk-UA" }
$UkLang.InputMethodTips.Clear()
$UkLang.InputMethodTips.Add("0422:00020422")
Set-WinUserLanguageList $LangList -Force

Write-Host "Налаштовуємо регіон та локаль..." -ForegroundColor Cyan
Set-WinUILanguageOverride -Language uk-UA   # Інтерфейс Ukrainian
Set-WinCultureFromLanguageListOptOut $False # Регіональний формат з списку мов
Set-Culture uk-UA                           # Формати дати, часу, валюти
Set-WinSystemLocale uk-UA                  # Системна локаль
Set-WinHomeLocation -GeoId 241             # Регіон Україна

Write-Host "Копіюємо налаштування на екран входу та нових користувачів..." -ForegroundColor Cyan
try {
    Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True
    Write-Host "  [OK] Скопійовано успішно" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Помилка копіювання: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nГотово. Перезавантажте систему для застосування змін." -ForegroundColor Green
Read-Host -Prompt "Натисніть Enter для виходу"