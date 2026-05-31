Write-Host "Відключаємо режим сну"
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0

Write-Host "Встановлюємо AnyDesk"
winget install AnyDesk.AnyDesk --accept-source-agreements --accept-package-agreements

Read-Host -Prompt "Press Enter to exit..."
pause
