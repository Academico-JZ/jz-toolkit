<#
.SYNOPSIS
    WhatsApp Network Fixer
    Diagnostics and repair for WhatsApp connectivity.
#>

Clear-Host
Write-Host "================================" -ForegroundColor Cyan
Write-Host "   AHS - WHATSAPP NETWORK FIX   " -ForegroundColor White
Write-Host "================================" -ForegroundColor Cyan

# 1. DNS Flush
ipconfig /flushdns | Out-Null
Write-Host "[1/4] DNS Flush: OK" -ForegroundColor Gray

# 2. Reset Proxy
netsh winhttp reset proxy | Out-Null
Write-Host "[2/4] Proxy Reset: OK" -ForegroundColor Gray

# 3. Connection Test
Write-Host "[3/4] Testando conexao com servidores WhatsApp..." -ForegroundColor Gray
$Servers = @("web.whatsapp.com", "mmg.whatsapp.net")
foreach ($S in $Servers) {
    if (Test-Connection -ComputerName $S -Count 1 -Quiet) {
        Write-Host "      $S: ACESSIVEL" -ForegroundColor Green
    } else {
        Write-Host "      $S: BLOQUEADO" -ForegroundColor Red
    }
}

# 4. App Restart
Write-Host "[4/4] Reiniciando aplicativo..." -ForegroundColor Gray
Stop-Process -Name WhatsApp -ErrorAction SilentlyContinue
Start-Sleep 1
& "C:\Program Files\WindowsApps\WhatsApp_*" # Exemplo
Write-Host "[OK] Processo concluido." -ForegroundColor Green
