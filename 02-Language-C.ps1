# Перезапуск від імені адміністратора
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Перевірка доступності Install-Language
if (-not (Get-Command Install-Language -ErrorAction SilentlyContinue)) {
    Write-Host "Install-Language недоступна" -ForegroundColor Red
    exit 1
}

# 1. Перейменування диску
Set-Volume -DriveLetter C -NewFileSystemLabel "System"

# 2. Встановлюємо базовий український мовний пакет
Install-Language uk-UA -CopyToSettings

# 3. Застосовуємо список мов
Set-WinUserLanguageList "en-US", "uk-UA" -Force

# 4. Додаємо розширену українську розкладку
$LangList = Get-WinUserLanguageList
$UkLang = $LangList | Where-Object { $_.LanguageTag -eq "uk-UA" }
$UkLang.InputMethodTips.Clear()
$UkLang.InputMethodTips.Add("0422:00020422")
Set-WinUserLanguageList $LangList -Force

# 5. Регіон та локаль
Set-WinUILanguageOverride -Language uk-UA
Set-Culture uk-UA
Set-WinSystemLocale uk-UA
Set-WinHomeLocation -GeoId 241

# 6. Копіюємо налаштування на екран входу та нових користувачів
try {
    Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True
} catch {
    Write-Host "Помилка копіювання: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "Готово. Перезавантажте систему." -ForegroundColor Green