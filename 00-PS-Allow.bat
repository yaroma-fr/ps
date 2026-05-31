xcopy "%~dp0*.*" "C:\temp\" /Y
powershell.exe -Command "Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force"
powershell.exe -Command "Get-ChildItem "C:\Temp" -Recurse | Unblock-File"
pause