#Requires -Version 5.1

# ==========================================
# Запуск від імені адміністратора
# ==========================================
if (-not ([Security.Principal.WindowsPrincipal]
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs

    exit
}

# ==========================================
# Підключення бібліотек
# ==========================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==========================================
# Логування
# ==========================================
$LogFile = "$env:TEMP\SoftwareInstall_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message)

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    "$TimeStamp - $Message" |
        Out-File -FilePath $LogFile -Append -Encoding UTF8
}

Write-Log "=== Початок роботи ==="

# ==========================================
# Перевірка Winget
# ==========================================
try {
    Get-Command winget -ErrorAction Stop | Out-Null

    Write-Host "Winget знайдено" -ForegroundColor Green
    Write-Log "Winget знайдено"
}
catch {
    [System.Windows.Forms.MessageBox]::Show(
        "Winget не знайдено.`n`nВстановіть App Installer із Microsoft Store.",
        "Помилка",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )

    Write-Log "Winget не знайдено"

    exit 1
}

# ==========================================
# Оновлення Winget
# ==========================================
$WingetUpdate = [System.Windows.Forms.MessageBox]::Show(
    "Оновити Winget перед встановленням програм?",
    "Оновлення Winget",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
)

if ($WingetUpdate -eq [System.Windows.Forms.DialogResult]::Yes)
{
    try {
        Write-Host "Оновлення Winget..." -ForegroundColor Cyan

        winget upgrade Microsoft.AppInstaller `
            --accept-source-agreements `
            --accept-package-agreements

        Write-Log "Winget оновлено"
    }
    catch {
        Write-Log "Помилка оновлення Winget: $($_.Exception.Message)"
    }
}

# ==========================================
# Список програм
# ==========================================
$Apps = @(
    @{ Name = "7-Zip";                   Id = "7zip.7zip" }
    @{ Name = "Google Chrome";           Id = "Google.Chrome" }
    @{ Name = "VLC";                     Id = "VideoLAN.VLC" }
    @{ Name = "PDF24 Creator";           Id = "geeksoftwareGmbH.PDF24Creator" }
    @{ Name = "IrfanView";               Id = "IrfanSkiljan.IrfanView" }
    @{ Name = "IrfanView Plugins";       Id = "IrfanSkiljan.IrfanView.Plugins" }
    @{ Name = "HP Support Assistant";    Id = "HPInc.HPSupportAssistant" }
    @{ Name = "Intel Driver Assistant";  Id = "Intel.IntelDriverAndSupportAssistant" }
    @{ Name = "Microsoft 365 Apps";      Id = "Microsoft.Office" }
)

# ==========================================
# GUI вибору програм
# ==========================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Вибір програм для встановлення"
$form.Size = New-Object System.Drawing.Size(500,550)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$list = New-Object System.Windows.Forms.CheckedListBox
$list.Location = New-Object System.Drawing.Point(10,10)
$list.Size = New-Object System.Drawing.Size(460,380)
$list.CheckOnClick = $true

foreach ($App in $Apps) {
    [void]$list.Items.Add($App.Name, $true)
}

$form.Controls.Add($list)

# Вибрати все
$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Вибрати все"
$btnSelectAll.Size = New-Object System.Drawing.Size(120,35)
$btnSelectAll.Location = New-Object System.Drawing.Point(10,410)

$btnSelectAll.Add_Click({
    for ($i = 0; $i -lt $list.Items.Count; $i++) {
        $list.SetItemChecked($i, $true)
    }
})

$form.Controls.Add($btnSelectAll)

# Зняти все
$btnClearAll = New-Object System.Windows.Forms.Button
$btnClearAll.Text = "Зняти все"
$btnClearAll.Size = New-Object System.Drawing.Size(120,35)
$btnClearAll.Location = New-Object System.Drawing.Point(140,410)

$btnClearAll.Add_Click({
    for ($i = 0; $i -lt $list.Items.Count; $i++) {
        $list.SetItemChecked($i, $false)
    }
})

$form.Controls.Add($btnClearAll)

# Встановити
$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "Встановити"
$btnInstall.Size = New-Object System.Drawing.Size(120,35)
$btnInstall.Location = New-Object System.Drawing.Point(350,410)

$btnInstall.Add_Click({
    $form.Tag = "Install"
    $form.Close()
})

$form.Controls.Add($btnInstall)

[void]$form.ShowDialog()

if ($form.Tag -ne "Install") {
    Write-Log "Встановлення скасовано користувачем"
    exit
}

# ==========================================
# Формування списку вибраних програм
# ==========================================
$SelectedApps = foreach ($Item in $list.CheckedItems) {
    $Apps | Where-Object { $_.Name -eq $Item }
}

if (-not $SelectedApps)
{
    [System.Windows.Forms.MessageBox]::Show(
        "Не вибрано жодної програми.",
        "Увага",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    exit
}

# ==========================================
# Функція встановлення
# ==========================================
function Install-App {

    param(
        [string]$Name,
        [string]$Id
    )

    Write-Host ""
    Write-Host "Встановлюємо $Name..." -ForegroundColor Cyan
    Write-Log "Початок встановлення: $Name"

    try {

        $Installed = winget list --id $Id --exact 2>$null

        if ($Installed -match $Id)
        {
            Write-Host "[SKIP] $Name вже встановлено" -ForegroundColor Yellow
            Write-Log "[SKIP] $Name вже встановлено"
            return
        }

        winget install `
            --id $Id `
            --exact `
            --silent `
            --accept-source-agreements `
            --accept-package-agreements

        if ($LASTEXITCODE -eq 0)
        {
            Write-Host "[OK] $Name встановлено" -ForegroundColor Green
            Write-Log "[OK] $Name встановлено"
        }
        else
        {
            Write-Host "[FAIL] $Name. Код: $LASTEXITCODE" -ForegroundColor Red
            Write-Log "[FAIL] $Name. Код: $LASTEXITCODE"
        }
    }
    catch
    {
        Write-Host "[ERROR] $Name : $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "[ERROR] $Name : $($_.Exception.Message)"
    }
}

# ==========================================
# Встановлення
# ==========================================
foreach ($App in $SelectedApps)
{
    Install-App `
        -Name $App.Name `
        -Id $App.Id
}

# ==========================================
# Завершення
# ==========================================
Write-Log "=== Завершено ==="

[System.Windows.Forms.MessageBox]::Show(
    "Встановлення завершено.`n`nЛог збережено:`n$LogFile",
    "Готово",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
)

Write-Host ""
Write-Host "Встановлення завершено!" -ForegroundColor Green
Write-Host "Лог: $LogFile" -ForegroundColor Yellow
# Активація Windows та Office:
irm https://get.activated.win | iex