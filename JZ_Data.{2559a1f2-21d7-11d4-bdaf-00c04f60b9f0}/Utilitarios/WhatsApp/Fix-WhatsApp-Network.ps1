# WhatsApp Network Fix - Corrige erro "Sem conexão à internet"
# Execute como Administrador

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  CORREÇÃO DE CONEXÃO WHATSAPP" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
$autoRestartWpp = (Read-Host "Reiniciar o WhatsApp automaticamente ao concluir? (S/N) [S]") -notmatch "^[Nn]"

# 1. VERIFICA CONECTIVIDADE BÁSICA
Write-Host "[1/8] Testando conectividade com servidores WhatsApp..." -ForegroundColor Yellow

$testHosts = @(
    "web.whatsapp.com",
    "connect.facebook.net",
    "crashlogs.whatsapp.net"
)

foreach ($host in $testHosts) {
    try {
        $result = Test-NetConnection $host -Port 443 -ErrorAction SilentlyContinue
        if ($result.TcpTestSucceeded) {
            Write-Host "  ✓ $host : CONECTADO" -ForegroundColor Green
        }
        else {
            Write-Host "  ✗ $host : FALHOU (Porta 443 bloqueada)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  ✗ $host : INACESSÍVEL" -ForegroundColor Red
    }
}

# 2. LIBERAR WHATSAPP NO FIREWALL DO WINDOWS
Write-Host "[2/8] Configurando regras de firewall..." -ForegroundColor Yellow

$firewallRules = @(
    @{Name = "WhatsApp-HTTP"; Protocol = "TCP"; Port = "80, 443, 5222, 5223, 5228, 4244" },
    @{Name = "WhatsApp-UDP"; Protocol = "UDP"; Port = "3478, 45395, 50318, 59234" }
)

foreach ($rule in $firewallRules) {
    try {
        # Remove regras antigas
        Remove-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue
        
        # Cria nova regra de entrada
        New-NetFirewallRule -DisplayName $rule.Name -Direction Inbound -Protocol $rule.Protocol -LocalPort $rule.Port -Action Allow -Enabled True -ErrorAction SilentlyContinue
        
        # Cria regra de saída
        New-NetFirewallRule -DisplayName "$($rule.Name)-Out" -Direction Outbound -Protocol $rule.Protocol -LocalPort $rule.Port -Action Allow -Enabled True -ErrorAction SilentlyContinue
        
        Write-Host "  Regra criada: $($rule.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "  Erro na regra: $($rule.Name)" -ForegroundColor Red
    }
}

# 3. REMOVER CONFIGURAÇÕES DE PROXY (causa comum)
Write-Host "[3/8] Removendo configurações de proxy..." -ForegroundColor Yellow

# Desativa proxy automático
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL /t REG_SZ /d "" /f

# Limpa proxy manual
netsh winhttp reset proxy
netsh winhttp import proxy source=ie

Write-Host "  Configurações de proxy resetadas" -ForegroundColor Green

# 4. LIMPAR E ATUALIZAR DNS
Write-Host "[4/8] Limpando cache DNS..." -ForegroundColor Yellow

ipconfig /flushdns
ipconfig /registerdns
ipconfig /release
ipconfig /renew

# Define DNS públicos (Google e Cloudflare)
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
foreach ($adapter in $adapters) {
    try {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("8.8.8.8", "8.8.4.4", "1.1.1.1") -ErrorAction SilentlyContinue
        Write-Host "  DNS configurado para $($adapter.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "  Não foi possível configurar DNS para $($adapter.Name)" -ForegroundColor Red
    }
}

# 5. RESETAR CATEGORIA DE REDE DO WHATSAPP
Write-Host "[5/8] Resetando configurações de rede do app..." -ForegroundColor Yellow

# Para versão Microsoft Store
$package = Get-AppxPackage -Name "*WhatsApp*" -ErrorAction SilentlyContinue
if ($package) {
    $manifestPath = "$($package.InstallLocation)\AppxManifest.xml"
    if (Test-Path $manifestPath) {
        CheckNetIsolation.exe LoopbackExempt -a -n="$($package.PackageFamilyName)"
        Write-Host "  Loopback exempt configurado para UWP" -ForegroundColor Green
    }
}

# Para versão Desktop tradicional
$firewallApp = "$env:LOCALAPPDATA\WhatsApp\WhatsApp.exe"
if (Test-Path $firewallApp) {
    netsh advfirewall firewall delete rule name="WhatsApp Desktop" program="$firewallApp" dir=in
    netsh advfirewall firewall add rule name="WhatsApp Desktop" dir=in action=allow program="$firewallApp" enable=yes
    Write-Host "  Regra de firewall criada para Desktop" -ForegroundColor Green
}

# 6. CORRIGIR HOSTS FILE (remove bloqueios acidentais)
Write-Host "[6/8] Verificando arquivo hosts..." -ForegroundColor Yellow

$hostsPathLocal = "$env:windir\System32\drivers\etc\hosts"
$hostsContentLocal = Get-Content $hostsPathLocal -ErrorAction SilentlyContinue

# Remove linhas que bloqueiam WhatsApp/Facebook
$blockedDomainsList = @("whatsapp", "facebook", "fbcdn", "fbsbx")
$cleanHostsLocal = $hostsContentLocal | Where-Object { $_ -notmatch ($blockedDomainsList -join '|') }

if ($hostsContentLocal.Count -ne $cleanHostsLocal.Count) {
    # Faz backup
    Copy-Item $hostsPathLocal "$hostsPathLocal.backup-$(Get-Date -Format 'yyyyMMdd')" -Force
    # Salva novo arquivo
    $cleanHostsLocal | Set-Content $hostsPathLocal -Force
    Write-Host "  Arquivo hosts limpo (backup criado)" -ForegroundColor Green
}
else {
    Write-Host "  Arquivo hosts OK - sem bloqueios" -ForegroundColor Green
}

# 7. ATUALIZAR CERTIFICADOS SSL
Write-Host "[7/8] Atualizando certificados SSL..." -ForegroundColor Yellow

# Atualiza certificados raiz
certutil -generateSSTFromWU roots.sst
certutil -addstore -f root roots.sst
Remove-Item roots.sst -ErrorAction SilentlyContinue

# Reseta certificados do usuário
certutil -user -setreg chain\ChainCacheResyncFiletime @now
certutil -user -setreg chain\ChainCacheResyncFiletime @never

Write-Host "  Certificados atualizados" -ForegroundColor Green

# 8. TESTE FINAL DE CONEXÃO
Write-Host "[8/8] Executando teste final..." -ForegroundColor Yellow

Write-Host "`n  TESTANDO CONEXÃO COM WHATSAPP:" -ForegroundColor White
Write-Host "  --------------------------------" -ForegroundColor Gray

# Testa múltiplos endpoints críticos
$whatsappEndpointsList = @(
    @{Name = "WebSocket"; Host = "web.whatsapp.com"; Port = 443 },
    @{Name = "Media"; Host = "mmg.whatsapp.net"; Port = 443 },
    @{Name = "Chat"; Host = "chat.whatsapp.com"; Port = 443 },
    @{Name = "Updates"; Host = "updates.whatsapp.net"; Port = 443 }
)

foreach ($endpoint in $whatsappEndpointsList) {
    $test = Test-NetConnection $endpoint.Host -Port $endpoint.Port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    if ($test.TcpTestSucceeded) {
        Write-Host "  ✓ $($endpoint.Name) ($($endpoint.Host)): OK" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ $($endpoint.Name) ($($endpoint.Host)): FALHOU" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 200
}

# RESULTADO E AÇÕES MANUAIS
Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host "  AÇÕES MANUAIS (se necessário):" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

Write-Host "`nSe ainda sem conexão, execute ESTES PASSOS MANUAIS:`n" -ForegroundColor Yellow

Write-Host "1. CONFIGURAÇÕES DO WHATSAPP (no app):" -ForegroundColor White
Write-Host "   • Clique nos '...' → Configurações → Ajuda" -ForegroundColor Gray
Write-Host "   • Selecione 'Verificar conexão com a internet'" -ForegroundColor Gray

Write-Host "`n2. VERIFICAR VPN/ANTIVÍRUS:" -ForegroundColor White
Write-Host "   • Desative VPN temporariamente" -ForegroundColor Gray
Write-Host "   • Adicione exceção no antivírus para:" -ForegroundColor Gray
Write-Host "     C:\Users\$env:USERNAME\AppData\Local\WhatsApp\" -ForegroundColor Gray

Write-Host "`n3. USAR CONEXÃO ALTERNATIVA:" -ForegroundColor White
Write-Host "   • Tente hotspot pelo celular" -ForegroundColor Gray
Write-Host "   • Altere rede Wi-Fi/Ethernet" -ForegroundColor Gray

Write-Host "`n4. COMANDOS EXTRAS (execute se necessário):" -ForegroundColor White
Write-Host "   # Forçar reconexão TCP" -ForegroundColor Gray
Write-Host "   netsh int ip reset" -ForegroundColor Gray
Write-Host "   netsh winsock reset" -ForegroundColor Gray
Write-Host "   # Reiniciar pilha TCP/IP" -ForegroundColor Gray
Write-Host "   netsh int tcp set heuristics disabled" -ForegroundColor Gray
Write-Host "   netsh int tcp set global autotuninglevel=normal" -ForegroundColor Gray

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host "  LOG DE EXECUÇÃO SALVO EM:" -ForegroundColor Cyan
Write-Host "  %TEMP%\WhatsApp_Fix_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# Gera log
$finalLogPath = "$env:TEMP\WhatsApp_Fix_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
"=== WhatsApp Network Fix Log ===" | Out-File $finalLogPath
"Data: $(Get-Date)" | Out-File $finalLogPath -Append
"Usuário: $env:USERNAME" | Out-File $finalLogPath -Append
"Computador: $env:COMPUTERNAME" | Out-File $finalLogPath -Append
"`n" | Out-File $finalLogPath -Append

if ($autoRestartWpp) {
    Write-Host "`nReiniciando o WhatsApp..." -ForegroundColor Yellow
}
else {
    Write-Host "`nPressione qualquer tecla para reiniciar o WhatsApp..." -ForegroundColor Yellow
    pause
}

# Reinicia o WhatsApp
taskkill /F /IM WhatsApp.exe /IM WhatsAppDesktop.exe 2>$null
Start-Sleep -Seconds 3

# Tenta abrir novamente
$whatsappLaunchPaths = @(
    "$env:LOCALAPPDATA\WhatsApp\WhatsApp.exe",
    "$env:APPDATA\WhatsApp\WhatsApp.exe",
    "$env:USERPROFILE\AppData\Local\WhatsApp\WhatsApp.exe"
)

foreach ($path in $whatsappLaunchPaths) {
    if (Test-Path $path) {
        Start-Process $path
        Write-Host "`nWhatsApp reiniciado. Verifique a conexão!" -ForegroundColor Green
        break
    }
}

Write-Host "`nExecução concluída. Verifique se o erro persiste." -ForegroundColor Green
