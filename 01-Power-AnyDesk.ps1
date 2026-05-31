$repoUrl = "https://github.com/yaroma-fr/ps/archive/refs/heads/main.zip"
$zipPath = "$env:TEMP\repo.zip"
$extractPath = "C:\Temp"

# Завантаження
Write-Host "Завантажую..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath -UseBasicParsing

# Розпакування
Write-Host "Розпаковую..." -ForegroundColor Yellow
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

# Видалення архіву
Remove-Item $zipPath -Force

Write-Host "Готово. Скрипти знаходяться в $extractPath" -ForegroundColor Green

function Write-Status {
    param($Message, $Color = "Cyan")
    Write-Host "`n[ $(Get-Date -Format 'HH:mm:ss') ] $Message" -ForegroundColor $Color
}

function Write-OK   { Write-Host "  [OK] $args" -ForegroundColor Green }
function Write-FAIL { Write-Host "  [FAIL] $args" -ForegroundColor Red }

# ─── Режим сну ───────────────────────────────────────────────
Write-Status "Відключаємо режим сну..."

$sleepCommands = @(
    "standby-timeout-ac",
    "standby-timeout-dc",
    "hibernate-timeout-ac",
    "hibernate-timeout-dc"
)

foreach ($cmd in $sleepCommands) {
    powercfg /change $cmd 0 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-OK "$cmd = 0"
    } else {
        Write-FAIL "$cmd не вдалося змінити"
    }
}

# Перевірка результату
$acSleep = (powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String "AC Power").ToString().Trim()
$dcSleep = (powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String "DC Power").ToString().Trim()
Write-Host "  Перевірка: $acSleep" -ForegroundColor Gray
Write-Host "  Перевірка: $dcSleep" -ForegroundColor Gray

# ─── AnyDesk ─────────────────────────────────────────────────
Write-Status "Встановлюємо AnyDesk..."

winget install AnyDesk.AnyDesk --accept-source-agreements --accept-package-agreements

if ($LASTEXITCODE -eq 0) {
    Write-OK "AnyDesk встановлено успішно"
} else {
    Write-FAIL "Помилка встановлення AnyDesk (код: $LASTEXITCODE)"
}

# Перевірка чи AnyDesk справді є в системі
$anydesk = Get-Command "AnyDesk.exe" -ErrorAction SilentlyContinue
if ($anydesk) {
    Write-OK "AnyDesk знайдено: $($anydesk.Source)"
} else {
    $anydeskPath = "${env:ProgramFiles(x86)}\AnyDesk\AnyDesk.exe"
    if (Test-Path $anydeskPath) {
        Write-OK "AnyDesk знайдено: $anydeskPath"
    } else {
        Write-FAIL "AnyDesk не знайдено в системі"
    }
}

# ─── Підсумок ────────────────────────────────────────────────
Write-Status "Готово!" "Green"
Read-Host -Prompt "`nНатисніть Enter для виходу"