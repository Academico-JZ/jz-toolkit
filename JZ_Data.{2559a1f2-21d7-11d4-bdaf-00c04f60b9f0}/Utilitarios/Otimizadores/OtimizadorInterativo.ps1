<#
.SYNOPSIS
    Otimizador Interativo do Windows - Responda S ou N para cada acao
    Versao totalmente interativa, sem necessidade de editar codigo
#>

# =========== CONFIGURACAO INICIAL ===========
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[X] Execute como Administrador!" -ForegroundColor Red
    pause
    exit 1
}

$ErrorActionPreference = "SilentlyContinue"
Clear-Host

# =========== FUNCAO DE CONFIRMACAO ===========
function Ask-YesNo {
    param(
        [string]$Question,
        [string]$Category,
        [bool]$Default = $true
    )
    
    Write-Host ""
    Write-Host "[$Category]" -ForegroundColor Yellow
    $defaultText = if ($Default) { "(S/N) [S]" } else { "(S/N) [N]" }
    
    do {
        $response = Read-Host "$Question $defaultText"
        
        if ([string]::IsNullOrWhiteSpace($response)) {
            return $Default
        }
        
        $response = $response.Trim().ToUpper()
        
        if ($response -eq "S" -or $response -eq "SIM" -or $response -eq "Y" -or $response -eq "YES") {
            return $true
        }
        if ($response -eq "N" -or $response -eq "NAO" -or $response -eq "NO") {
            return $false
        }
        
        Write-Host "[!] Resposta invalida! Digite S (Sim) ou N (Nao)" -ForegroundColor Red
    } while ($true)
}

# =========== MENU PRINCIPAL ===========
function Show-MainMenu {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "            OTIMIZADOR INTERATIVO DO WINDOWS                    " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "--- Responda S (Sim) ou N (Nao) para cada opcao ---" -ForegroundColor Yellow
    Write-Host "    Pressione ENTER para usar o valor padrao entre [ ]" -ForegroundColor White
    Write-Host ""
}

# =========== FUNCOES DE ACAO ===========
function Invoke-CreateRestorePoint {
    Write-Host "`n[*] Criando ponto de restauracao..." -ForegroundColor Cyan
    try {
        $date = Get-Date -Format "yyyyMMdd_HHmm"
        Checkpoint-Computer -Description "Otimizacao_$date" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "[OK] Ponto de restauracao criado com sucesso" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[!] Nao foi possivel criar ponto de restauracao" -ForegroundColor Yellow
        Write-Host "    Motivo: $_" -ForegroundColor Gray
        $confirm = Read-Host "    Deseja continuar mesmo assim? (S/N) [S]"
        if ($confirm -eq "" -or $confirm -match "^[SsYy]") { return $true }
        return $false
    }
}

function Invoke-CleanTempFiles {
    Write-Host "`n[*] Limpando arquivos temporarios..." -ForegroundColor Cyan
    $paths = @("$env:TEMP\*", "$env:USERPROFILE\AppData\Local\Temp\*", "$env:WINDIR\Temp\*", "$env:SystemRoot\Temp\*")
    $totalFreed = 0
    $totalFiles = 0
    foreach ($path in $paths) {
        if (Test-Path $path) {
            try {
                $items = Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue
                $count = ($items | Measure-Object).Count
                $size = ($items | Measure-Object -Property Length -Sum).Sum
                if ($count -gt 0) {
                    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                    $totalFreed += $size
                    $totalFiles += $count
                    Write-Host "   Limpo: $(Split-Path $path -Leaf) ($count arquivos)" -ForegroundColor Gray
                }
            }
            catch { }
        }
    }
    Write-Host "[OK] Temporarios limpos: $totalFiles arquivos ($([math]::Round($totalFreed/1MB, 2)) MB)" -ForegroundColor Green
}

function Invoke-CleanPrefetch {
    Write-Host "`n[*] Limpando Prefetch..." -ForegroundColor Cyan
    $prefetchPath = "$env:WINDIR\Prefetch"
    if (Test-Path $prefetchPath) {
        try {
            $files = Get-ChildItem "$prefetchPath\*.pf" -Force | Sort-Object LastWriteTime -Descending
            if ($files.Count -gt 100) {
                $toKeep = $files | Select-Object -First 100
                $toRemove = $files | Where-Object { $_.FullName -notin $toKeep.FullName }
                $removeCount = $toRemove.Count
                foreach ($file in $toRemove) { Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue }
                Write-Host "[OK] Prefetch limpo: $removeCount arquivos antigos removidos" -ForegroundColor Green
            }
            else {
                Write-Host "[i] Prefetch: $($files.Count) arquivos (mantidos)" -ForegroundColor Gray
              }
        }
        catch { }
    }
}

function Invoke-CleanRecycleBin {
    Write-Host "`n[*] Esvaziando Lixeira..." -ForegroundColor Cyan
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        Write-Host "[OK] Lixeira esvaziada" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Nao foi possivel esvaziar a lixeira" -ForegroundColor Yellow
    }
}

function Invoke-SSDOptimizations {
    Write-Host "`n[*] Otimizando SSD/NVMe..." -ForegroundColor Cyan
    try {
        $disk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq 0 }
        if ($disk.MediaType -ne "SSD" -and $disk.BusType -ne "NVMe") {
            Write-Host "[i] Disco nao e SSD/NVMe - otimizacoes ignoradas" -ForegroundColor Gray
            return
        }
        Optimize-Volume -DriveLetter C -ReTrim -Verbose -ErrorAction SilentlyContinue | Out-Null
        $sysmain = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
        if ($sysmain -and $sysmain.Status -eq 'Running') {
            Stop-Service "SysMain" -Force
            Set-Service "SysMain" -StartupType Disabled
            Write-Host "   SysMain/SuperFetch desativado" -ForegroundColor Gray
        }
        Write-Host "[OK] Otimizacoes SSD aplicadas" -ForegroundColor Green
    }
    catch { }
}

function Invoke-SFCScan {
    Write-Host "`n[*] Executando SFC /scannow (Isso pode demorar)..." -ForegroundColor Cyan
    sfc /scannow
    Write-Host "[OK] SFC concluido" -ForegroundColor Green
}

function Invoke-CHKDSKCheck {
    Write-Host "`n[*] Verificando disco com CHKDSK..." -ForegroundColor Cyan
    $volume = Get-Volume -DriveLetter C -ErrorAction SilentlyContinue
    if ($volume -and $volume.HealthStatus -ne "Healthy") {
        Write-Host "[!] Disco reporta problemas" -ForegroundColor Yellow
        $confirm = Read-Host "    Agendar CHKDSK na proxima reinicializacao? (S/N) [S]"
        if ($confirm -eq "" -or $confirm -match "^[SsYy]") {
            chkdsk C: /f /r
            Write-Host "[OK] CHKDSK agendado. Reinicie para executar." -ForegroundColor Green
            $global:RestartNeeded = $true
        }
    }
    else {
        Write-Host "[OK] Disco aparentemente saudavel" -ForegroundColor Green
    }
}

function Invoke-PowerPlan {
    Write-Host "`n[*] Configurando plano de energia..." -ForegroundColor Cyan
    $schemes = powercfg /l
    if ($schemes -match "e9a42b02-d5df-448d-aa00-03f14749eb61") {
        powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61
        Write-Host "[OK] Plano: Ultimate Performance" -ForegroundColor Green
    }
    else {
        powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        Write-Host "[OK] Plano: High Performance" -ForegroundColor Green
    }
}

function Invoke-NetworkOptimizations {
    Write-Host "`n[*] Otimizando rede..." -ForegroundColor Cyan
    ipconfig /flushdns | Out-Null
    netsh int tcp set global autotuninglevel=normal
    netsh int tcp set global rss=enabled
    Write-Host "[OK] Otimizacoes de rede aplicadas" -ForegroundColor Green
}

function Invoke-VisualOptimizations {
    Write-Host "`n[*] Otimizando efeitos visuais..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0"
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0"
    Write-Host "[OK] Efeitos visuais otimizados" -ForegroundColor Green
}

function Invoke-DisableTelemetry {
    Write-Host "`n[*] Desativando telemetria..." -ForegroundColor Cyan
    $diagTrack = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
    if ($diagTrack -and $diagTrack.Status -eq 'Running') {
        Stop-Service "DiagTrack" -Force
        Set-Service "DiagTrack" -StartupType Disabled
        Write-Host "[OK] Telemetria desativada" -ForegroundColor Green
    }
}

function Invoke-RegistryCleanup {
    Write-Host "`n[*] Limpando registro..." -ForegroundColor Cyan
    $regPaths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs")
    foreach ($path in $regPaths) {
        if (Test-Path $path) { Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue }
    }
    Write-Host "[OK] Registro limpo" -ForegroundColor Green
}

# =========== FLUXO PRINCIPAL ===========
Show-MainMenu

$createRestore = Ask-YesNo -Question "Criar ponto de restauracao antes das mudancas?" -Category "Seguranca"
$cleanTemp = Ask-YesNo -Question "Limpar arquivos temporarios (TEMP)?" -Category "Limpeza"
$cleanPrefetch = Ask-YesNo -Question "Limpar arquivos Prefetch antigos?" -Category "Limpeza"
$cleanRecycleBin = Ask-YesNo -Question "Esvaziar lixeira?" -Category "Limpeza"
$optimizeSSD = Ask-YesNo -Question "Otimizar SSD/NVMe (TRIM + SuperFetch)?" -Category "SSD"
$runSFC = Ask-YesNo -Question "Executar SFC /scannow (Verifica integridade)?" -Category "Integridade"
$runCHKDSK = Ask-YesNo -Question "Verificar disco com CHKDSK?" -Category "Integridade" -Default $false
$setPowerPlan = Ask-YesNo -Question "Configurar plano de Alta Performance?" -Category "Desempenho"
$optimizeNetwork = Ask-YesNo -Question "Otimizar configuracoes de rede?" -Category "Desempenho"
$optimizeVisual = Ask-YesNo -Question "Otimizar efeitos visuais (Menu Rapido)?" -Category "Desempenho"
$disableTelemetry = Ask-YesNo -Question "Desativar telemetria do Windows?" -Category "Privacidade" -Default $false
$cleanRegistry = Ask-YesNo -Question "Limpar chaves temporarias do registro?" -Category "Registro"
$autoRestart = Ask-YesNo -Question "Reiniciar automaticamente ao concluir (se necessario)?" -Category "Finalizacao" -Default $false

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "RESUMO DAS ACOES SELECIONADAS:" -ForegroundColor Cyan
$actionsSummary = @()
if ($createRestore) { $actionsSummary += "[v] Ponto de restauracao" }
if ($cleanTemp) { $actionsSummary += "[v] Limpar TEMP" }
if ($cleanPrefetch) { $actionsSummary += "[v] Limpar Prefetch" }
if ($cleanRecycleBin) { $actionsSummary += "[v] Esvaziar lixeira" }
if ($optimizeSSD) { $actionsSummary += "[v] Otimizar SSD" }
if ($runSFC) { $actionsSummary += "[v] Executar SFC" }
if ($runCHKDSK) { $actionsSummary += "[v] Verificar CHKDSK" }
if ($setPowerPlan) { $actionsSummary += "[v] Plano de energia" }
if ($optimizeNetwork) { $actionsSummary += "[v] Otimizar rede" }
if ($optimizeVisual) { $actionsSummary += "[v] Otimizar visual" }
if ($disableTelemetry) { $actionsSummary += "[v] Desativar telemetria" }
if ($cleanRegistry) { $actionsSummary += "[v] Limpar registro" }
if ($autoRestart) { $actionsSummary += "[v] Reiniciar automaticamente" }
foreach ($action in $actionsSummary) { Write-Host "   $action" -ForegroundColor Green }

Write-Host "`n" + "="*60 -ForegroundColor Cyan
$confirm = Read-Host "Executar estas otimizacoes agora? (S/N) [S]"
if ($confirm -ne "" -and $confirm -match "^[Nn]") { Write-Host "Cancelado."; pause; exit 0 }

# --- Execucao ---
$startTime = Get-Date
if ($createRestore) { 
    if (-not (Invoke-CreateRestorePoint)) {
        if ((Read-Host "Continuar sem ponto de restauracao? (S/N) [S]") -match "^[Nn]") { exit 0 }
    }
}
if ($cleanTemp) { Invoke-CleanTempFiles }
if ($cleanPrefetch) { Invoke-CleanPrefetch }
if ($cleanRecycleBin) { Invoke-CleanRecycleBin }
if ($optimizeSSD) { Invoke-SSDOptimizations }
if ($runSFC) { Invoke-SFCScan }
if ($runCHKDSK) { Invoke-CHKDSKCheck }
if ($setPowerPlan) { Invoke-PowerPlan }
if ($optimizeNetwork) { Invoke-NetworkOptimizations }
if ($optimizeVisual) { Invoke-VisualOptimizations }
if ($disableTelemetry) { Invoke-DisableTelemetry }
if ($cleanRegistry) { Invoke-RegistryCleanup }

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "OTIMIZACAO CONCLUIDA!" -ForegroundColor Green
$duration = (Get-Date) - $startTime
Write-Host "Tempo total: $($duration.TotalMinutes.ToString('0.0')) minutos"

if ($global:RestartNeeded) {
    Write-Host "`n[!] REINICIALIZACAO NECESSARIA (CHKDSK agendado)" -ForegroundColor Red
    if ($autoRestart -or (Read-Host "Reiniciar agora? (S/N) [N]") -match "^[SsYy]") { 
        Write-Host "Reiniciando..." -ForegroundColor Yellow
        Restart-Computer -Force 
    }
}
else {
    Write-Host "`n[i] Otimizacao concluida. Recomendamos reiniciar para aplicar tudo." -ForegroundColor Yellow
    if ($autoRestart) {
        Write-Host "Reiniciando automaticamente conforme solicitado..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        Restart-Computer -Force
    }
    elseif ((Read-Host "Reiniciar agora? (S/N) [N]") -match "^[SsYy]") { 
        Restart-Computer -Force 
    }
}
pause
