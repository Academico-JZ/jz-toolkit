<#
.SYNOPSIS
    AHS Industry & Services - Unified SysAdmin Toolkit
    Replaces: MENU_DE_FERRAMENTAS.bat, Vault_Locker.bat, Launcher.bat

.DESCRIPTION
    Consolidated administrative toolkit for SRE/IT Access.
    Features:
    - Secure Login Gate (SHA256)
    - Vault/Locker (Folder Camouflage)
    - Virtual Drive Mounting (S:/T:)
    - System Optimization & Audit Tools

.NOTES
    Version: 2.0 (PowerShell Migration)
    Author: AHS SRE Team (Migrated by AI)
    Hash: D71D6DB3C58F9958F4AFF3128CC50BCF9DB893F28E685FFD42420DA80A2C929A
#>

param(
    [Switch]$SkipLogin
)

# Configuration
$Config = @{
    Hash        = "D71D6DB3C58F9958F4AFF3128CC50BCF9DB893F28E685FFD42420DA80A2C929A"
    MaxAttempts = 3
    VaultGUID   = "{2559a1f2-21d7-11d4-bdaf-00c04f60b9f0}"
    DriveUtil   = "S:"
    DriveSRE    = "T:"
    PathUtils   = "$PSScriptRoot\Utilitarios"
    PathSRE     = "$PSScriptRoot\SysAdmin_Toolkit"
}

# --- Helper Functions ---

function Get-UserHash {
    param([SecureString]$SecurePassword)
    if (-not $SecurePassword) { return $null }
    
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    try {
        $String = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        $Bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
        $HashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($Bytes)
        return [System.BitConverter]::ToString($HashBytes).Replace('-', '')
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
}

function Test-AccessCredentials {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "          AHS INDUSTRIA - ACESSO RESTRITO (SRE/IT)              " -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $Attempts = 0
    while ($Attempts -lt $Config.MaxAttempts) {
        $Attempts++
        Write-Host "Tentativa $Attempts de $($Config.MaxAttempts)." -ForegroundColor Gray
        
        try {
            $InputPass = Read-Host -Prompt "Digite a senha de acesso" -AsSecureString
            $InputHash = Get-UserHash -SecurePassword $InputPass
            
            if ($InputHash -eq $Config.Hash) {
                Write-Host "[OK] Acesso concedido." -ForegroundColor Green
                Start-Sleep -Seconds 1
                return $true
            }
        }
        catch {
            # Handle empty input or cancel
        }

        Write-Host "[!] SENHA INCORRETA." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
    
    Write-Host "[!] Numero de tentativas excedido." -ForegroundColor Red
    Start-Sleep -Seconds 2
    return $false
}

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
            # Check for normal folder and rename to locked
            if (Test-Path $NormalPath) {
                Rename-Item -LiteralPath $NormalPath -NewName "$Folder.$($Config.VaultGUID)" -Force
                # Set hidden/system attributes
                $Item = Get-Item -LiteralPath $LockedPath
                $Item.Attributes = 'Hidden', 'System', 'Directory'
            }
        }
        else {
            # Unlock
            if (Test-Path -LiteralPath $LockedPath) {
                # Remove attributes first
                $Item = Get-Item -LiteralPath $LockedPath
                $Item.Attributes = 'Directory'
                Rename-Item -LiteralPath $LockedPath -NewName $Folder -Force
            }
        }
    }
    
    if ($Mode -eq "Lock") {
        # Unmount drives
        subst $Config.DriveUtil /D | Out-Null
        subst $Config.DriveSRE /D | Out-Null
        Write-Host "[LOCK] Pastas camufladas e drives desmontados." -ForegroundColor Yellow
    }
    else {
        # Remount
        Mount-VirtualDrives
        Write-Host "[UNLOCK] Pastas restauradas e drives montados." -ForegroundColor Green
    }
}

function Mount-VirtualDrives {
    # Unmount first to be safe
    subst $Config.DriveUtil /D | Out-Null
    subst $Config.DriveSRE /D | Out-Null
    
    $U_Exists = Test-Path $Config.PathUtils
    $S_Exists = Test-Path $Config.PathSRE
    
    if ($U_Exists) {
        subst $Config.DriveUtil $Config.PathUtils | Out-Null
    }
    if ($S_Exists) {
        subst $Config.DriveSRE $Config.PathSRE | Out-Null
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "          AHS INDUSTRIA | SYSADMIN TOOLKIT V2.5" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  HOST: $env:COMPUTERNAME  | STATUS: SRE [ACTIVE] | MNT [READY]" -ForegroundColor Gray
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  [ ENGENHARIA SRE & AUDITORIA ]" -ForegroundColor Yellow
    Write-Host "  1. Dashboard SRE Pro (Core Python)"
    Write-Host "  2. Auditoria de Hardware (Quick Report)"
    Write-Host ""
    Write-Host "  [ OTIMIZACAO & PERFORMANCE ]" -ForegroundColor Yellow
    Write-Host "  3. Otimizar Windows/SSD (Turbo)"
    Write-Host "  4. Otimizador Interativo (Manual)"
    Write-Host "  5. Limpeza Profunda (Caches/Temp)"
    Write-Host ""
    Write-Host "  [ REDE & COMUNICACAO ]" -ForegroundColor Yellow
    Write-Host "  6. Fix Conectividade WhatsApp"
    Write-Host "  7. Bloquear/Desbloquear WhatsApp Web"
    Write-Host ""
    Write-Host "  [ SUPORTE & SISTEMA ]" -ForegroundColor Yellow
    Write-Host "  8. Reset AnyDesk (Manual Reset)"
    Write-Host "  9. Fix Print Screen Classico"
    Write-Host ""
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "  [ A ] ADVANCED: Lock/Unlock Vault" -ForegroundColor Magenta
    Write-Host "  [ Q ] Sair do Console" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# --- Main Execution ---

# 1. Login Gate
if (-not $SkipLogin) {
    if (-not (Test-AccessCredentials)) { exit }
}

# 2. Initial Unlock & Mount
Set-VaultState -Mode Unlock | Out-Null

# 3. Warning if Python not found
$env:PATH += ";$Config.DriveSRE\python_env"

# 4. Menu Loop
$Running = $true
while ($Running) {
    Show-Menu
    $Choice = Read-Host "> Selecione a operacao"
    
    switch ($Choice) {
        "1" { 
            Write-Host "[SRE] Iniciando Core..."
            if (Test-Path "$($Config.DriveSRE)\sre_core.py") {
                if (Get-Command python -ErrorAction SilentlyContinue) {
                    python "$($Config.DriveSRE)\sre_core.py"
                }
                else {
                    Write-Warning "Python nao encontrado. Tentando fallback PowerShell..."
                    powershell -ExecutionPolicy Bypass -File "$($Config.DriveSRE)\sre_core_ps.ps1"
                }
            }
            else {
                if (Test-Path "$($Config.DriveSRE)\sre_core_ps.ps1") {
                    powershell -ExecutionPolicy Bypass -File "$($Config.DriveSRE)\sre_core_ps.ps1"
                }
                else {
                    Write-Error "Arquivo sre_core.py ou sre_core_ps.ps1 nao encontrado em $($Config.DriveSRE)."
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
            Write-Host "[ VAULT LOCKER ]" -ForegroundColor Magenta
            Write-Host "[1] TRANCAR (Sair e Ocultar)"
            Write-Host "[2] DESTRANCAR (Restaurar)"
            $V = Read-Host ">"
            if ($V -eq '1') { Set-VaultState -Mode Lock; Start-Sleep 1; exit }
            if ($V -eq '2') { Set-VaultState -Mode Unlock; Pause }
        }
        "q" { $Running = $false }
        Default { Write-Warning "Opcao invalida"; Start-Sleep 1 }
    }
}

# Cleanup
subst $Config.DriveUtil /D | Out-Null
subst $Config.DriveSRE /D | Out-Null
