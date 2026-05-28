# --- Налаштування ---
#$Url = "https://your-server/scripts.zip"
#$ZipPath = "$env:TEMP\scripts.zip"
#$Dest = "C:\Scripts"

Write-Host "Downloading scripts..."

# Завантаження
#Invoke-WebRequest $Url -OutFile $ZipPath

Write-Host "Extracting..."

# Розпакування
#Expand-Archive $ZipPath -DestinationPath $Dest -Force

Write-Host "Done."