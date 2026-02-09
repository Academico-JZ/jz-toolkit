# ==============================================================================
# JZ-Toolkit - Web Installer (Official v3.0)
# ==============================================================================
# Uso: iex (irm t.ly/TI-JZ)
# ==============================================================================

$RepoUrl = "https://github.com/Academico-JZ/jz-toolkit/archive/refs/heads/main.zip"
$TargetDir = "$env:TEMP\JZ-Toolkit-Install"

Write-Host "`n[*] Iniciando JZ-Toolkit Web Installer v3.0..." -ForegroundColor Cyan

try {
    # 1. Limpeza total do cache para evitar conflitos de versões antigas
    if (Test-Path $TargetDir) { 
        Write-Host "[*] Limpando instalacoes anteriores..." -ForegroundColor Gray
        Remove-Item $TargetDir -Recurse -Force -ErrorAction SilentlyContinue 
    }
    New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
    
    $ZipPath = "$TargetDir\toolkit.zip"

    # 2. Download
    Write-Host "[*] Baixando arquivos do GitHub..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $RepoUrl -OutFile $ZipPath -ErrorAction Stop

    # 3. Extracao
    Write-Host "[*] Extraindo pacote..." -ForegroundColor Gray
    Expand-Archive -Path $ZipPath -DestinationPath $TargetDir -Force
    Start-Sleep -Milliseconds 500
    
    # 4. Busca Especifica (Evita carregar AHS-Toolkit.ps1 legado)
    Write-Host "[*] Localizando script v3.0..." -ForegroundColor Gray
    $FoundFiles = Get-ChildItem -Path $TargetDir -Filter "JZ-Toolkit.ps1" -Recurse
    
    if ($FoundFiles.Count -eq 0) {
        Write-Host "`n[!] ERRO: 'JZ-Toolkit.ps1' nao encontrado no repositorio." -ForegroundColor Red
        throw "Abortando. Verifique o repositorio publico."
    }

    $BootScript = $FoundFiles[0].FullName
    Write-Host "[OK] Localizado: $($FoundFiles[0].Name)" -ForegroundColor Green
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$BootScript`"" -Verb RunAs
}
catch {
    Write-Error "`n[!] Falha na Execucao: $($_.Exception.Message)"
}
