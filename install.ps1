# ==============================================================================
# JZ-Toolkit - Web Installer (Robust Edition)
# ==============================================================================
# Uso: iex (irm t.ly/TI-JZ)
# ==============================================================================

$RepoUrl = "https://github.com/Academico-JZ/jz-toolkit/archive/refs/heads/main.zip"
$TargetDir = "$env:TEMP\JZ-Toolkit-Install"

Write-Host "`n[*] Iniciando JZ-Toolkit Web Installer..." -ForegroundColor Cyan

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
    Start-Sleep -Milliseconds 500 # Pequena pausa para o Windows sincronizar o sistema de arquivos
    
    # 4. Busca Super Robusta
    # Procura por JZ-Toolkit.ps1, jz-toolkit.ps1 ou qualquer coisa que termine em Toolkit.ps1
    Write-Host "[*] Localizando script de inicializacao..." -ForegroundColor Gray
    $FoundFiles = Get-ChildItem -Path $TargetDir -Filter "*Toolkit.ps1" -Recurse
    
    if ($FoundFiles.Count -eq 0) {
        Write-Host "`n[!] ERRO CRITICO: Arquivo 'JZ-Toolkit.ps1' nao encontrado no repositorio." -ForegroundColor Red
        Write-Host "[?] Arquivos encontrados no pacote:" -ForegroundColor Yellow
        Get-ChildItem -Path $TargetDir -Recurse | Select-Object -ExpandProperty FullName | Write-Host -ForegroundColor Gray
        throw "Verifique se o arquivo foi enviado corretamente para o GitHub."
    }

    $BootScript = $FoundFiles[0].FullName

    if (Test-Path $BootScript) {
        Write-Host "[OK] Toolkit Localizado em: $($FoundFiles[0].Name)" -ForegroundColor Green
        Write-Host "[*] Iniciando..." -ForegroundColor Gray
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$BootScript`"" -Verb RunAs
    }
}
catch {
    Write-Error "`n[!] Falha na Execucao: $($_.Exception.Message)"
}
