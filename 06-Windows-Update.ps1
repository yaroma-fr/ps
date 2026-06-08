<#
.SYNOPSIS
    Вмикає Microsoft Update та встановлює всі доступні оновлення Windows/Microsoft,
    включно з optional / preview / browse-only оновленнями.

.NOTES
    За замовчуванням драйвери НЕ встановлюються.
    Для драйверів запустити з параметром: -IncludeDrivers
#>

param(
    [switch]$IncludeDrivers = $true,
    [switch]$AutoReboot
)

# Перезапуск від імені адміністратора
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
	}

$ErrorActionPreference = "Stop"

$LogDir = "C:\Windows\Temp"
$LogFile = Join-Path $LogDir ("Install-AllMicrosoftUpdates-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

Start-Transcript -Path $LogFile -Append | Out-Null

try {
    Write-Host "=== Перевірка прав адміністратора ===" -ForegroundColor Cyan

    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)

    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Скрипт потрібно запускати від імені адміністратора."
    }

    Write-Host "OK: Скрипт запущено від адміністратора." -ForegroundColor Green

    Write-Host "`n=== Перевірка NuGet provider ===" -ForegroundColor Cyan

    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    }

    Write-Host "`n=== Перевірка модуля PSWindowsUpdate ===" -ForegroundColor Cyan

    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Host "PSWindowsUpdate не знайдено. Встановлюю..." -ForegroundColor Yellow
        Install-Module -Name PSWindowsUpdate -Force -AllowClobber
    }

    Import-Module PSWindowsUpdate -Force

    Write-Host "OK: PSWindowsUpdate імпортовано." -ForegroundColor Green

    Write-Host "`n=== Запуск необхідних служб Windows Update ===" -ForegroundColor Cyan

    $services = @(
        "wuauserv",
        "bits",
        "cryptsvc"
    )

    foreach ($svc in $services) {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue

        if ($null -ne $service) {
            if ($service.Status -ne "Running") {
                Write-Host "Запускаю службу $svc..." -ForegroundColor Yellow
                Start-Service -Name $svc
            }
        }
    }

    Write-Host "OK: Служби перевірено." -ForegroundColor Green

    Write-Host "`n=== Увімкнення Microsoft Update для інших продуктів Microsoft ===" -ForegroundColor Cyan

    $MicrosoftUpdateServiceId = "7971f918-a847-4430-9279-4a52d1efe18d"

    try {
        Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Host
    }
    catch {
        Write-Host "Add-WUServiceManager не спрацював, пробую через COM API..." -ForegroundColor Yellow

        $ServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager
        $ServiceManager.ClientApplicationID = "Enable Microsoft Update"

        # 7 = asfAllowPendingRegistration + asfAllowOnlineRegistration + asfRegisterServiceWithAU
        $ServiceManager.AddService2($MicrosoftUpdateServiceId, 7, "") | Out-Null
    }

    Write-Host "OK: Microsoft Update увімкнено / зареєстровано." -ForegroundColor Green

    Write-Host "`n=== Поточні джерела оновлень ===" -ForegroundColor Cyan
    Get-WUServiceManager | Format-Table -AutoSize | Out-Host

    Write-Host "`n=== Початковий пошук звичайних Software оновлень ===" -ForegroundColor Cyan

    $normalSoftwareUpdates = Get-WindowsUpdate `
        -MicrosoftUpdate `
        -UpdateType Software `
        -IsInstalled:$false `
        -IsHidden:$false `
        -Verbose

    if ($normalSoftwareUpdates) {
        Write-Host "`nЗнайдено звичайні Software оновлення:" -ForegroundColor Green
        $normalSoftwareUpdates | Format-Table -AutoSize | Out-Host

        Write-Host "`nВстановлюю звичайні Software оновлення..." -ForegroundColor Cyan

        Get-WindowsUpdate `
            -MicrosoftUpdate `
            -UpdateType Software `
            -IsInstalled:$false `
            -IsHidden:$false `
            -Install `
            -AcceptAll `
            -IgnoreReboot `
            -Verbose
    }
    else {
        Write-Host "Звичайних Software оновлень не знайдено." -ForegroundColor Yellow
    }

    Write-Host "`n=== Пошук optional / preview / browse-only Software оновлень ===" -ForegroundColor Cyan

    $optionalSoftwareUpdates = Get-WindowsUpdate `
        -MicrosoftUpdate `
        -BrowseOnly `
        -UpdateType Software `
        -IsInstalled:$false `
        -IsHidden:$false `
        -Verbose

    if ($optionalSoftwareUpdates) {
        Write-Host "`nЗнайдено optional / preview / browse-only Software оновлення:" -ForegroundColor Green
        $optionalSoftwareUpdates | Format-Table -AutoSize | Out-Host

        Write-Host "`nВстановлюю optional / preview / browse-only Software оновлення..." -ForegroundColor Cyan

        Get-WindowsUpdate `
            -MicrosoftUpdate `
            -BrowseOnly `
            -UpdateType Software `
            -IsInstalled:$false `
            -IsHidden:$false `
            -Install `
            -AcceptAll `
            -IgnoreReboot `
            -Verbose
    }
    else {
        Write-Host "Optional / preview / browse-only Software оновлень не знайдено." -ForegroundColor Yellow
    }

    if ($IncludeDrivers) {
        Write-Host "`n=== Пошук Driver оновлень ===" -ForegroundColor Cyan

        $driverUpdates = Get-WindowsUpdate `
            -MicrosoftUpdate `
            -UpdateType Driver `
            -IsInstalled:$false `
            -IsHidden:$false `
            -Verbose

        if ($driverUpdates) {
            Write-Host "`nЗнайдено Driver оновлення:" -ForegroundColor Green
            $driverUpdates | Format-Table -AutoSize | Out-Host

            Write-Host "`nВстановлюю Driver оновлення..." -ForegroundColor Cyan

            Get-WindowsUpdate `
                -MicrosoftUpdate `
                -UpdateType Driver `
                -IsInstalled:$false `
                -IsHidden:$false `
                -Install `
                -AcceptAll `
                -IgnoreReboot `
                -Verbose
        }
        else {
            Write-Host "Driver оновлень не знайдено." -ForegroundColor Yellow
        }

        Write-Host "`n=== Пошук optional / browse-only Driver оновлень ===" -ForegroundColor Cyan

        $optionalDriverUpdates = Get-WindowsUpdate `
            -MicrosoftUpdate `
            -BrowseOnly `
            -UpdateType Driver `
            -IsInstalled:$false `
            -IsHidden:$false `
            -Verbose

        if ($optionalDriverUpdates) {
            Write-Host "`nЗнайдено optional / browse-only Driver оновлення:" -ForegroundColor Green
            $optionalDriverUpdates | Format-Table -AutoSize | Out-Host

            Write-Host "`nВстановлюю optional / browse-only Driver оновлення..." -ForegroundColor Cyan

            Get-WindowsUpdate `
                -MicrosoftUpdate `
                -BrowseOnly `
                -UpdateType Driver `
                -IsInstalled:$false `
                -IsHidden:$false `
                -Install `
                -AcceptAll `
                -IgnoreReboot `
                -Verbose
        }
        else {
            Write-Host "Optional / browse-only Driver оновлень не знайдено." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "`nDriver оновлення пропущено. Для встановлення драйверів запусти скрипт з параметром -IncludeDrivers." -ForegroundColor Yellow
    }

    Write-Host "`n=== Перевірка статусу перезавантаження ===" -ForegroundColor Cyan

    $rebootRequired = Get-WURebootStatus -Silent

    if ($rebootRequired) {
        Write-Host "Потрібне перезавантаження." -ForegroundColor Yellow

        if ($AutoReboot) {
            Write-Host "Параметр -AutoReboot задано. Перезавантаження через 30 секунд..." -ForegroundColor Red
            shutdown.exe /r /t 30 /c "Windows Updates installed. Reboot required."
        }
        else {
            Write-Host "Перезавантаж комп'ютер вручну або запусти скрипт з -AutoReboot." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Перезавантаження не потрібне." -ForegroundColor Green
    }

    Write-Host "`n=== Готово ===" -ForegroundColor Green
    Write-Host "Лог: $LogFile" -ForegroundColor Cyan
}
catch {
    Write-Host "`nПОМИЛКА:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "Лог: $LogFile" -ForegroundColor Cyan
    exit 1
}
finally {
    Stop-Transcript | Out-Null
}

Read-Host -Prompt "Натисніть Enter для виходу"