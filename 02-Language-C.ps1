# Перезапуск від імені адміністратора
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Перейменування диску C: на "System"
Set-Volume -DriveLetter C -NewFileSystemLabel "System"

# Перевірка доступності Install-Language
if (-not (Get-Command Install-Language -ErrorAction SilentlyContinue)) {
    Write-Host "Install-Language недоступна на цій системі" -ForegroundColor Red
    exit 1
}

Write-Host "Встановлюємо мовний пакет uk-UA..." -ForegroundColor Cyan
Install-Language uk-UA -CopyToSettings

Write-Host "Налаштовуємо список мов..." -ForegroundColor Cyan
Set-WinUserLanguageList "en-US", "uk-UA" -Force
Start-Sleep -Seconds 2

# Додаємо розширену українську розкладку
$LangList = Get-WinUserLanguageList
$UkLang = $LangList | Where-Object { $_.LanguageTag -like "uk*" }

if ($null -eq $UkLang) {
    Write-Host "uk не знайдено в списку мов" -ForegroundColor Red
    Write-Host "Поточний список: $($LangList.LanguageTag -join ', ')" -ForegroundColor Yellow
    exit 1
}

$UkLang.InputMethodTips.Clear()
$UkLang.InputMethodTips.Add("0422:00020422")
Set-WinUserLanguageList $LangList -Force

Write-Host "  [OK] Список мов налаштовано" -ForegroundColor Green

Write-Host "Налаштовуємо регіон та локаль..." -ForegroundColor Cyan
Set-WinUILanguageOverride -Language uk-UA
Set-WinCultureFromLanguageListOptOut $False
Set-Culture uk-UA
Set-WinSystemLocale uk-UA
Set-WinHomeLocation -GeoId 241

# Примусово встановити регіональний формат через реєстр
$RegPath = "HKCU:\Control Panel\International"
Set-ItemProperty -Path $RegPath -Name "Locale"     -Value "00000422"
Set-ItemProperty -Path $RegPath -Name "LocaleName" -Value "uk-UA"
Set-ItemProperty -Path $RegPath -Name "sLanguage"  -Value "UKR"
Set-ItemProperty -Path $RegPath -Name "sCountry"   -Value "Ukraine"

Write-Host "  [OK] Регіон та локаль налаштовано" -ForegroundColor Green

Write-Host "Копіюємо налаштування на екран входу та нових користувачів..." -ForegroundColor Cyan
try {
    Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True
    Write-Host "  [OK] Скопійовано успішно" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Помилка копіювання: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nГотово. Перезавантажте систему для застосування змін." -ForegroundColor Green
Read-Host -Prompt "Натисніть Enter для виходу"