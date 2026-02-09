<#
.SYNOPSIS
    JZ-Toolkit Bootstrap (jz_init.ps1)
    Inicia o toolkit via Rede Local (UNC) ou GitHub Público (ZIP).

.EXAMPLE
    # Via Rede Local:
    .\jz_init.ps1 -Source LAN -Path "\\servidor\compartilhamento\jz-toolkit"

    # Via GitHub Público:
    .\jz_init.ps1 -Source GitHub
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("LAN", "GitHub", "Auto")]
    [string]$Source = "Auto",

    [Parameter(Mandatory = $false)]
    [string]$Path = "\\servidor\arquivos\JZ-Toolkit",

    [Parameter(Mandatory = $false)]
    [string]$Repo = "Academico-JZ/jz-toolkit"
)

$TargetDir = Join-Path $env:TEMP "JZ-Toolkit-Temp"

function Start-MainToolkit {
    param([string]$BaseDir)
    $MainScript = Join-Path $BaseDir "JZ-Toolkit.ps1"
    if (Test-Path $MainScript) {
        Write-Host "[OK] Iniciando JZ-Toolkit..." -ForegroundColor Green
        powershell -ExecutionPolicy Bypass -File $MainScript
    }
    else {
        Write-Error "Script principal nao encontrado em: $MainScript"
    }
}

# --- Lógica de Execução ---

if ($Source -eq "Auto" -or $Source -eq "LAN") {
    Write-Host "[*] Verificando acesso a Rede Local..." -ForegroundColor Cyan
    if (Test-Path $Path) {
        Write-Host "[OK] Rede Local detectada." -ForegroundColor Green
        Start-MainToolkit -BaseDir $Path
        exit
    }
    elseif ($Source -eq "LAN") {
        Write-Error "Caminho de rede nao acessivel: $Path"
        exit
    }
}

if ($Source -eq "Auto" -or $Source -eq "GitHub") {
    Write-Host "[*] Iniciando download via GitHub..." -ForegroundColor Cyan
    
    if (-not (Test-Path $TargetDir)) { New-Item -Path $TargetDir -ItemType Directory -Force }

    $ZipPath = Join-Path $TargetDir "repo.zip"
    $Url = "https://github.com/$Repo/archive/refs/heads/main.zip"
    
    try {
        Write-Host "[+] Baixando arquivos..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $Url -OutFile $ZipPath -ErrorAction Stop
        
        Write-Host "[+] Extraindo..." -ForegroundColor Gray
        Expand-Archive -Path $ZipPath -DestinationPath $TargetDir -Force
        
        $ExtractedFolder = Get-ChildItem -Path $TargetDir -Directory | Select-Object -First 1
        
        Start-MainToolkit -BaseDir $ExtractedFolder.FullName
    }
    catch {
        Write-Error "Falha ao baixar do GitHub. Erro: $($_.Exception.Message)"
    }
    finally {
        if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    }
}
