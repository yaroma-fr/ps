#Requires -Version 5.1

# ==========================================
# Запуск від імені адміністратора
# ==========================================
$IsAdmin = (
    New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )
).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdmin)
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
# Лог
# ==========================================
$LogFile = "$env:TEMP\SoftwareInstall_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message)

    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    "$Time - $Message" | Out-File `
        -FilePath $LogFile `
        -Append `
        -Encoding UTF8
}

Write-Log "=== Старт ==="

# ==========================================
# Перевірка Winget
# ==========================================
try {
    Get-Command winget -ErrorAction Stop | Out-Null
}
catch {

    [System.Windows.Forms.MessageBox]::Show(
        "Winget не знайдено.`nВстановіть App Installer з Microsoft Store.",
        "Помилка",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )

    exit 1
}

# ==========================================
# Оновлення Winget
# ==========================================
$UpdateWinget = [System.Windows.Forms.MessageBox]::Show(
    "Оновити Winget перед встановленням програм?",
    "Winget",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
)

if ($UpdateWinget -eq [System.Windows.Forms.DialogResult]::Yes)
{
    try {

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
# Програми
# ==========================================
$Apps = @(
    @{ Name = "7-Zip";                  Id = "7zip.7zip" }
    @{ Name = "Google Chrome";          Id = "Google.Chrome" }
    @{ Name = "VLC";                    Id = "VideoLAN.VLC" }
    @{ Name = "PDF24 Creator";          Id = "geeksoftwareGmbH.PDF24Creator" }
    @{ Name = "IrfanView";              Id = "IrfanSkiljan.IrfanView" }
    @{ Name = "IrfanView Plugins";      Id = "IrfanSkiljan.IrfanView.Plugins" }
    @{ Name = "HP Support Assistant";   Id = "HPInc.HPSupportAssistant" }
    @{ Name = "Intel Driver Assistant"; Id = "Intel.IntelDriverAndSupportAssistant" }
    @{ Name = "Microsoft 365 Apps";     Id = "Microsoft.Office" }
    @{ Name = "Zoom Workplace";         Id = "Zoom.Zoom.EXE" }
)

# ==========================================
# GUI
# ==========================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Виберіть програми для встановлення"
$form.Width = 500
$form.Height = 540
$form.StartPosition = "CenterScreen"
$form.MaximizeBox = $false

$list = New-Object System.Windows.Forms.CheckedListBox
$list.Location = New-Object System.Drawing.Point(10,10)
$list.Size = New-Object System.Drawing.Size(460,380)
$list.CheckOnClick = $true

foreach ($app in $Apps) {
    [void]$list.Items.Add($app.Name,$true)
}

$form.Controls.Add($list)

$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Вибрати все"
$btnSelectAll.Width = 120
$btnSelectAll.Height = 35
$btnSelectAll.Location = New-Object System.Drawing.Point(10,410)

$btnSelectAll.Add_Click({
    for ($i=0; $i -lt $list.Items.Count; $i++)
    {
        $list.SetItemChecked($i,$true)
    }
})

$form.Controls.Add($btnSelectAll)

$btnClearAll = New-Object System.Windows.Forms.Button
$btnClearAll.Text = "Зняти все"
$btnClearAll.Width = 120
$btnClearAll.Height = 35
$btnClearAll.Location = New-Object System.Drawing.Point(140,410)

$btnClearAll.Add_Click({
    for ($i=0; $i -lt $list.Items.Count; $i++)
    {
        $list.SetItemChecked($i,$false)
    }
})

$form.Controls.Add($btnClearAll)

$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "Встановити"
$btnInstall.Width = 120
$btnInstall.Height = 35
$btnInstall.Location = New-Object System.Drawing.Point(350,410)

$btnInstall.Add_Click({
    $form.Tag = "Install"
    $form.Close()
})

$form.Controls.Add($btnInstall)

$form.Topmost = $true

[void]$form.ShowDialog()

if ($form.Tag -ne "Install")
{
    exit
}

# ==========================================
# Обрані програми
# ==========================================
$SelectedApps = foreach ($Item in $list.CheckedItems)
{
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
# Встановлення програм
# ==========================================
function Install-App {

    param(
        [string]$Name,
        [string]$Id
    )

    Write-Host ""
    Write-Host "Встановлюємо $Name..." -ForegroundColor Cyan

    Write-Log "Початок встановлення $Name"

    try {

        $Installed = winget list `
            --id $Id `
            --exact 2>$null

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
            Write-Host "[FAIL] $Name (Код $LASTEXITCODE)" -ForegroundColor Red
            Write-Log "[FAIL] $Name (Код $LASTEXITCODE)"
        }
    }
    catch
    {
        Write-Host "[ERROR] $Name - $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "[ERROR] $Name - $($_.Exception.Message)"
    }
}

foreach ($App in $SelectedApps)
{
    Install-App `
        -Name $App.Name `
        -Id $App.Id
}

Write-Log "=== Завершено ==="

$LogContent = Get-Content $LogFile -ErrorAction SilentlyContinue

$InstalledCount = ($LogContent | Select-String "\[OK\]").Count
$SkippedCount   = ($LogContent | Select-String "\[SKIP\]").Count
$FailedCount    = ($LogContent | Select-String "\[FAIL\]|\[ERROR\]").Count

$Summary = @"
Встановлення завершено.

Успішно: $InstalledCount
Пропущено: $SkippedCount
Помилок: $FailedCount

Лог:
$LogFile
"@

[System.Windows.Forms.MessageBox]::Show(
    $Summary,
    "Готово",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
)
# Активація Windows та Office:
irm https://get.activated.win | iex
Read-Host "Натисніть Enter для виходу"
