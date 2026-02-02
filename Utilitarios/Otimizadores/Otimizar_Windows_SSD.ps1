<#
.SYNOPSIS
    Windows/SSD Turbo Optimizer for AHS Industry
    Optimizes performance, disables telemetry, and cleans temp files.
#>

# Create restore point
Checkpoint-Computer -Description "AHS_Toolkit_Optimization" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue

# Power Plan (High Performance)
powercfg /setactive 8c5e7fda-e8bf-4a35-9a85-ada5406d0465

# Services Optimization
$Services = @("SysMain", "DiagTrack", "dmwappushservice", "WSearch")
foreach ($Svc in $Services) {
    Stop-Service -Name $Svc -ErrorAction SilentlyContinue
    Set-Service -Name $Svc -StartupType Disabled -ErrorAction SilentlyContinue
}

# Disk Cleanup
Write-Host "Limpando arquivos temporarios..." -ForegroundColor Gray
$TempFolders = @($env:TEMP, "C:\Windows\Temp", "C:\Windows\Prefetch")
foreach ($Folder in $TempFolders) {
    Remove-Item -Path "$Folder\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# Optimization for SSD (TRIM)
Optimize-Volume -DriveLetter C -ReTrim -Verbose

Write-Host "[OK] Otimizacao concluida." -ForegroundColor Green
