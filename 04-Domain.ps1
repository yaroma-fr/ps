$NewName = [Microsoft.VisualBasic.Interaction]::InputBox("Введіть нову назву комп'ютера", "Перейменування", $env:COMPUTERNAME)

if ($NewName -eq "") {
    Write-Host "Назву не введено, скрипт зупинено" -ForegroundColor Red
    exit 1
}

Add-Computer -DomainName "your.domain.com" -NewName $NewName -Credential (Get-Credential) -Restart