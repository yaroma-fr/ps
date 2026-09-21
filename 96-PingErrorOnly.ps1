$Target = "8.8.8.8"

$StartTime = Get-Date
$LastStatus = $StartTime

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Monitoring started: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Green
Write-Host "Target: $Target" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan

while ($true) {

    $Now = Get-Date

    $PingOK = Test-Connection -ComputerName $Target -Count 1 -Quiet

    # Якщо пінг не проходить
    if (-not $PingOK) {
        Write-Host "$($Now.ToString('yyyy-MM-dd HH:mm:ss'))  PING FAILED: $Target" -ForegroundColor Red
    }

    # Кожні 10 хвилин показуємо статус
    if (($Now - $LastStatus).TotalMinutes -ge 10) {

        if ($PingOK) {
            Write-Host "$($Now.ToString('yyyy-MM-dd HH:mm:ss'))  Monitoring active - PING OK: $Target" -ForegroundColor Green
        }
        else {
            Write-Host "$($Now.ToString('yyyy-MM-dd HH:mm:ss'))  Monitoring active - PING FAILED: $Target" -ForegroundColor Red
        }

        $LastStatus = $Now
    }

    Start-Sleep -Seconds 1
}