# Перевірка прав адміністратора
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Запустіть скрипт від імені адміністратора" -ForegroundColor Red
    exit 1
}

# 0. Перевірка доступності Install-Language
if (-not (Get-Command Install-Language -ErrorAction SilentlyContinue)) {
    Write-Host "Install-Language недоступна" -ForegroundColor Red
    exit 1
}

# 1. Перейменування диску
Set-Volume -DriveLetter C -NewFileSystemLabel "System"

# 2. Встановлюємо базовий український мовний пакет
Install-Language uk-UA -CopyToSettings

# 3. Створюємо список мов
$NewList = New-Object 'System.Collections.Generic.List[Microsoft.InternationalSettings.Commands.WinUserLanguage]'

# 4. Англійська (США) — перша (за замовчуванням)
$EnLang = New-Object Microsoft.InternationalSettings.Commands.WinUserLanguage("en-US")
$NewList.Add($EnLang)

# 5. Українська з розширеною розкладкою
$UkLang = New-Object Microsoft.InternationalSettings.Commands.WinUserLanguage("uk-UA")
$UkLang.InputMethodTips.Clear()
$UkLang.InputMethodTips.Add("0422:00020422")
$NewList.Add($UkLang)

# 6. Застосовуємо список
Set-WinUserLanguageList -LanguageList $NewList -Force

# 7. Регіон та локаль
Set-WinUILanguageOverride -Language uk-UA
Set-Culture uk-UA
Set-WinSystemLocale uk-UA
Set-WinHomeLocation -GeoId 241

# 8. Копіюємо налаштування на екран входу та нових користувачів
try {
    Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True
} catch {
    Write-Host "Помилка копіювання: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "Готово. Перезавантажте систему." -ForegroundColor Green
