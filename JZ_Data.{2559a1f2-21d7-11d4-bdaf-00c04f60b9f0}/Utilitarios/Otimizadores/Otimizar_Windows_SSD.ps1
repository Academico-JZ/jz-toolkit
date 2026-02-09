<#
.SYNOPSIS
    Script de Otimização do Windows focado em Performance e SSDs Antigos.
    Seguro para ambientes corporativos (não desativa rede, impressão ou updates essenciais).

.DESCRIPTION
    Este script realiza as seguintes ações:
    1. Cria um Ponto de Restauração (Segurança).
    2. Ajusta o Plano de Energia para Alta Performance.
    3. Executa TRIM no disco C: (Manutenção de SSD).
    4. Desativa o SysMain/Superfetch (Reduz uso de disco em SSDs).
    5. Desativa Telemetria básica.
    6. Ajusta efeitos visuais para 'Melhor Desempenho' via Registro.
    7. Limpeza básica de arquivos temporários e cache DNS.

    NÃO REALIZA:
    - Não desativa Windows Update (wuauserv).
    - Não desativa Spooler de Impressão.
    - Não desativa Compartilhamento de Arquivos.

.NOTES
    Requer privilégios de Administrador.
#>

# --- Verificação de Admin ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Este script precisa ser executado como Administrador!"
    Write-Warning "Por favor, clique com o botão direito e escolha 'Executar como Administrador'."
    Pause
    Exit
}

$ErrorActionPreference = "SilentlyContinue"
Clear-Host
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "      OTIMIZADOR DE WINDOWS (Foco: SSD & Performance)           " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. Criar Ponto de Restauracao ---
Write-Host "[1/6] Criando Ponto de Restauracao..." -ForegroundColor Yellow
$autoRestart = (Read-Host "Reiniciar automaticamente ao concluir (se necessario)? (S/N) [N]") -match "^[SsYy]"
try {
    Checkpoint-Computer -Description "Otimizacao_Automatica_$(Get-Date -Format 'yyyyMMdd')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-Host "      Sucesso: Ponto de restauracao criado." -ForegroundColor Green
}
catch {
    Write-Warning "      Falha ao criar ponto de restauracao. A Protecao do Sistema pode estar desativada."
    $confirmation = Read-Host "      Deseja continuar mesmo sem ponto de restauracao? (S/N)"
    if ($confirmation -ne 'S' -and $confirmation -ne 's') {
        Write-Host "Cancelado pelo usuario." -ForegroundColor Red
        Exit
    }
}

# --- 2. Plano de Energia ---
Write-Host "[2/6] Ajustando Energia para Alta Performance..." -ForegroundColor Yellow
# ID do plano High Performance: 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
if ($?) { Write-Host "      Sucesso: Plano de Energia definido." -ForegroundColor Green }

# Desativar suspensão seletiva USB (evita lags em periféricos)
# AC Setting
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-720d2938480 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
# DC Setting
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-720d2938480 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg -setactive SCHEME_CURRENT

# --- 3. Manutenção de SSD (TRIM & SysMain) ---
Write-Host "[3/6] Otimizando SSD e Disco..." -ForegroundColor Yellow

# Executar TRIM
Write-Host "      Executando TRIM no drive C:..." -ForegroundColor DarkGray
Optimize-Volume -DriveLetter C -ReTrim -Verbose | Out-Null
Write-Host "      TRIM concluído." -ForegroundColor Green

# Desativar SysMain (Superfetch) - Desnecessário em SSDs e causa muita leitura/escrita
$sysmain = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
if ($sysmain -and $sysmain.Status -eq 'Running') {
    Stop-Service "SysMain" -Force
    Set-Service "SysMain" -StartupType Disabled
    Write-Host "      Serviço SysMain (Superfetch) desativado (Bom para SSD)." -ForegroundColor Green
}
else {
    Write-Host "      SysMain já está parado ou inexistente." -ForegroundColor Gray
}

# Desativar Hibernação (Opcional - Economiza espaço em disco e escritas)
# Write-Host "      Desativando Hibernação para liberar espaço..." -ForegroundColor DarkGray
# powercfg -h off

# --- 4. Ajustes Visuais (Registro) ---
Write-Host "[4/6] Otimizando Efeitos Visuais (Menu Rápido)..." -ForegroundColor Yellow
$visualKey = "HKCU:\Control Panel\Desktop"
# MenuShowDelay - Tempo de espera para abrir menus (Padrão 400 -> 0)
Set-ItemProperty -Path $visualKey -Name "MenuShowDelay" -Value "0"
# Desativar animação de minimizar/maximizar
Set-ItemProperty -Path "$visualKey\WindowMetrics" -Name "MinAnimate" -Value "0"
Write-Host "      Ajustes de registro aplicados. (Reinicie para aplicar totalmente)" -ForegroundColor Green

# --- 5. Telemetria e Bloatware Leve ---
Write-Host "[5/6] Reduzindo Telemetria e Logs desnecessários..." -ForegroundColor Yellow
# Desativar 'Connected User Experiences and Telemetry' (DiagTrack)
$diagTrack = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
if ($diagTrack -and $diagTrack.Status -eq 'Running') {
    Stop-Service "DiagTrack" -Force
    Set-Service "DiagTrack" -StartupType Disabled
    Write-Host "      Telemetria (DiagTrack) parada." -ForegroundColor Green
}

# --- 6. Limpeza Final e Profunda ---
Write-Host "[6/6] Limpeza de Manutenção (Temp, Prefetch, Lixeira)..." -ForegroundColor Yellow

# 6.1 Flush DNS
ipconfig /flushdns | Out-Null
Write-Host "      [-] Cache DNS limpo." -ForegroundColor Green

# 6.2 Limpar Temp do Usuário
$userTemp = [System.Environment]::GetEnvironmentVariable("TEMP", "User")
Write-Host "      [-] Limpando Temp do Usuário ($userTemp)..." -ForegroundColor DarkGray
Get-ChildItem -Path $userTemp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

# 6.3 Limpar Temp do Sistema (Windows\Temp)
$sysTemp = "$env:SystemRoot\Temp"
Write-Host "      [-] Limpando Temp do Sistema ($sysTemp)..." -ForegroundColor DarkGray
Get-ChildItem -Path $sysTemp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

# 6.4 Limpar Prefetch
$envPrefetch = "$env:SystemRoot\Prefetch"
Write-Host "      [-] Limpando Prefetch ($envPrefetch)..." -ForegroundColor DarkGray
Get-ChildItem -Path $envPrefetch -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

# 6.5 Esvaziar Lixeira
Write-Host "      [-] Esvaziando Lixeira..." -ForegroundColor DarkGray
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "      Lixeira esvaziada." -ForegroundColor Green

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "      OTIMIZACAO CONCLUIDA!                                     " -ForegroundColor Cyan
if ($autoRestart) {
    Write-Host "      Reiniciando automaticamente em 5 segundos...               " -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Start-Sleep -Seconds 5
    Restart-Computer -Force
}
else {
    Write-Host "      Reinicie o computador para aplicar todas as mudancas.     " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Pause
}
