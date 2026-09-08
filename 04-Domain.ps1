# Перезапуск від імені адміністратора
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Start-Process powershell.exe `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs

    exit
}

# Підключення необхідних бібліотек
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

# Запит нової назви комп'ютера
$NewName = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Введіть нову назву комп'ютера",
    "Перейменування комп'ютера",
    $env:COMPUTERNAME
)

# Перевірка введення
if ([string]::IsNullOrWhiteSpace($NewName[System.Windows.Forms.MessageBox]::Show(
        "Назву комп'ютера не введено. Роботу скрипта скасовано.",
        "Скасовано",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    exit 1
}

try
{
    Write-Host "Запит облікових даних..." -ForegroundColor Cyan

    $Credential = Get-Credential -Message "Введіть облікові дані для приєднання до домену"

    Write-Host "Перейменування комп'ютера та приєднання до домену..." -ForegroundColor Cyan

    Add-Computer `
        -DomainName "adsapience.com" `
        -NewName $NewName `
        -Credential $Credential `
        -ErrorAction Stop

    Write-Host "Операцію успішно завершено." -ForegroundColor Green

    $Result = [System.Windows.Forms.MessageBox]::Show(
        "Комп'ютер успішно перейменовано та додано до домену ADSapience.`n`nПерезавантажити комп'ютер зараз?",
        "Потрібне перезавантаження",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($Result -eq [System.Windows.Forms.DialogResult]::Yes)
    {
        Write-Host "Перезавантаження..." -ForegroundColor Cyan
        Restart-Computer -Force
    }
    else
    {
        [System.Windows.Forms.MessageBox]::Show(
            "Перезавантаження відкладено. Виконайте його вручну для завершення приєднання до домену.",
            "Увага",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
}
catch
{
    $ErrorMessage = $_.Exception.Message

    Write-Host "Помилка: $ErrorMessage" -ForegroundColor Red

    [System.Windows.Forms.MessageBox]::Show(
        "Під час перейменування або приєднання до домену сталася помилка:`n`n$ErrorMessage",
        "Помилка",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )

    exit 1
}