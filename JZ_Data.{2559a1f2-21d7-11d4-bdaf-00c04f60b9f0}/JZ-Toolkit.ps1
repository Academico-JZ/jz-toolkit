<#
.SYNOPSIS
    JZ-Toolkit - Unified SysAdmin Toolkit
    Versão simplificada para uso técnico geral.

.DESCRIPTION
    Consolidado de ferramentas administrativas para SRE e Suporte técnico.
    Recursos:
    - Montagem de Unidades Virtuais (S:/T:)
    - Otimização de Sistema e Hardware
    - Auditoria e Fixes Rápidos

.NOTES
    Versão: 3.0 (Versão Pública Sanitizada)
    Author: JZ Team
#>

# Configuration
$Config = @{
    VaultGUID = "{2559a1f2-21d7-11d4-bdaf-00c04f60b9f0}"
    DriveUtil = "S:"
    DriveSRE  = "T:"
    PathUtils = "$PSScriptRoot\Utilitarios"
    PathSRE   = "$PSScriptRoot\SysAdmin_Toolkit"
}

# --- Helper Functions ---

function Set-VaultState {
    param(
        [ValidateSet("Lock", "Unlock")]
        [string]$Mode
    )
    
    $Folders = @("Utilitarios", "SysAdmin_Toolkit")
    
    foreach ($Folder in $Folders) {
        $NormalPath = Join-Path $PSScriptRoot $Folder
        $LockedPath = Join-Path $PSScriptRoot "$Folder.$($Config.VaultGUID)"
        
        if ($Mode -eq "Lock") {
            if (Test-Path $NormalPath) {
                Rename-Item -LiteralPath $NormalPath -NewName "$Folder.$($Config.VaultGUID)" -Force
                $Item = Get-Item -LiteralPath $LockedPath
                $Item.Attributes = 'Hidden', 'System', 'Directory'
            }
        }
        else {
            if (Test-Path -LiteralPath $LockedPath) {
                $Item = Get-Item -LiteralPath $LockedPath
                $Item.Attributes = 'Directory'
                Rename-Item -LiteralPath $LockedPath -NewName $Folder -Force
            }
        }
    }
    
    if ($Mode -eq "Lock") {
        subst $Config.DriveUtil /D | Out-Null
        subst $Config.DriveSRE /D | Out-Null
        Write-Host "[LOCK] Pastas ocultas e drives removidos." -ForegroundColor Yellow
    }
    else {
        Mount-VirtualDrives
        Write-Host "[UNLOCK] Ambiente pronto e drives montados." -ForegroundColor Green
    }
}

function Mount-VirtualDrives {
    subst $Config.DriveUtil /D | Out-Null
    subst $Config.DriveSRE /D | Out-Null
    
    if (Test-Path $Config.PathUtils) {
        subst $Config.DriveUtil $Config.PathUtils | Out-Null
    }
    if (Test-Path $Config.PathSRE) {
        subst $Config.DriveSRE $Config.PathSRE | Out-Null
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "          JZ-TOOLKIT | SYSADMIN DASHBOARD V3.0" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  HOST: $env:COMPUTERNAME  | MODO: TECNICO | AMBIENTE: PRONTO" -ForegroundColor Gray
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  [ ENGENHARIA & AUDITORIA ]" -ForegroundColor Yellow
    Write-Host "  1. Dashboard Pro (Core Python)"
    Write-Host "  2. Auditoria de Hardware (Quick Report)"
    Write-Host ""
    Write-Host "  [ OTIMIZACAO & PERFORMANCE ]" -ForegroundColor Yellow
    Write-Host "  3. Otimizar Windows/SSD (Turbo)"
    Write-Host "  4. Otimizador Interativo (Manual)"
    Write-Host "  5. Limpeza Profunda (Caches/Temp)"
    Write-Host ""
    Write-Host "  [ REDE & UTILITARIOS ]" -ForegroundColor Yellow
    Write-Host "  6. Fix Conectividade WhatsApp"
    Write-Host "  7. Bloquear/Desbloquear WhatsApp Web"
    Write-Host ""
    Write-Host "  [ SISTEMA ]" -ForegroundColor Yellow
    Write-Host "  8. Reset AnyDesk"
    Write-Host "  9. Ativar Print Screen Classico"
    Write-Host ""
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "  [ A ] ADVANCED: Lock/Unlock Folders" -ForegroundColor Magenta
    Write-Host "  [ Q ] Sair" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# --- Main Execution ---

# 1. Garante que as pastas estao desbloqueadas e drives montados
Set-VaultState -Mode Unlock | Out-Null

# 2. Configura PATH para Python se existir
$env:PATH += ";$Config.DriveSRE\python_env"

# 3. Menu Loop
$Running = $true
while ($Running) {
    Show-Menu
    $Choice = Read-Host "> Selecione a operacao"
    
    switch ($Choice) {
        "1" { 
            Write-Host "[SRE] Iniciando..."
            if (Test-Path "$($Config.DriveSRE)\sre_core.py") {
                if (Get-Command python -ErrorAction SilentlyContinue) {
                    python "$($Config.DriveSRE)\sre_core.py"
                }
                else {
                    powershell -ExecutionPolicy Bypass -File "$($Config.DriveSRE)\sre_core_ps.ps1"
                }
            }
            Pause
        }
        "2" { powershell -ExecutionPolicy Bypass -File "$($Config.DriveUtil)\Sistema\Auditoria_Hardware_V2.ps1"; Pause }
        "3" { powershell -ExecutionPolicy Bypass -File "$($Config.DriveUtil)\Otimizadores\Otimizar_Windows_SSD.ps1"; Pause }
        "4" { powershell -ExecutionPolicy Bypass -File "$($Config.DriveUtil)\Otimizadores\OtimizadorInterativo.ps1"; Pause }
        "5" { cmd /c "$($Config.DriveUtil)\Otimizadores\LimpezaSilenciosa.BAT"; Pause }
        "6" { powershell -ExecutionPolicy Bypass -File "$($Config.DriveUtil)\WhatsApp\Fix-WhatsApp-Network.ps1"; Pause }
        "7" { 
            Clear-Host; Write-Host "[ WhatsApp Web Control ]"; Write-Host "[1] Bloquear"; Write-Host "[2] Desbloquear"; 
            $W = Read-Host ">"; 
            if ($W -eq '1') { cmd /c "$($Config.DriveUtil)\WhatsApp\Bloquear_Whatsapp\Bloquear_Whats_WEB.bat" }
            if ($W -eq '2') { cmd /c "$($Config.DriveUtil)\WhatsApp\Bloquear_Whatsapp\Desbloquear_Whats_WEB.bat" }
            Pause
        }
        "8" { cmd /c "$($Config.DriveUtil)\Sistema\reset_anydesk.bat"; Pause }
        "9" { 
            cmd /c "reg import `"$($Config.DriveUtil)\Sistema\ativar-print-classico.reg`""
            Write-Host "Registry importado."; Pause
        }
        { $_ -match "^a$|^l$" } {
            Clear-Host
            Write-Host "[ FOLDER LOCKER ]" -ForegroundColor Magenta
            Write-Host "[1] OCULTAR (Lock)"
            Write-Host "[2] MOSTRAR (Unlock)"
            $V = Read-Host ">"
            if ($V -eq '1') { Set-VaultState -Mode Lock; Start-Sleep 1; exit }
            if ($V -eq '2') { Set-VaultState -Mode Unlock; Pause }
        }
        "q" { $Running = $false }
        Default { Write-Warning "Opcao invalida"; Start-Sleep 1 }
    }
}

# Final Cleanup
subst $Config.DriveUtil /D | Out-Null
subst $Config.DriveSRE /D | Out-Null
