@echo off
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit
)
powershell.exe -Command "Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force"
if not exist "C:\temp" mkdir "C:\temp"
powershell.exe -Command "Get-ChildItem "C:\Temp" -Recurse | Unblock-File"
powershell.exe -ExecutionPolicy Bypass -File "%~dp099-Download_scrtips.ps1"
pause
