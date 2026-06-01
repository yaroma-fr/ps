@echo off
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit
)
powershell.exe -Command "Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force"
powershell.exe -Command "Get-ChildItem "C:\Temp" -Recurse | Unblock-File"
powershell.exe -ExecutionPolicy Bypass -File "%~dp001-Power-AnyDesk.ps1"
pause