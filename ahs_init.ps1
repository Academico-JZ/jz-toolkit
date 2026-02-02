<#
.SYNOPSIS
    AHS Toolkit Bootstrap (ahs_init.ps1)
    Inicia o toolkit via Rede Local (UNC) ou GitHub Privado (ZIP).

.EXAMPLE
    # Via Rede Local:
    .\ahs_init.ps1 -Source LAN -Path "\\servidor\compartilhamento\ahs-toolkit"

    # Via GitHub Privado:
    .\ahs_init.ps1 -Source GitHub -Token "SEU_PAT_AQUI"
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("LAN", "GitHub", "Auto")]
    [string]$Source = "Auto",

    [Parameter(Mandatory=$false)]
    [string]$Path = "\\servidor\arquivos\AHS-Toolkit",

    [Parameter(Mandatory=$false)]
    [string]$Token = $null,

    [Parameter(Mandatory=$false)]
    [string]$Repo = "Academico-JZ/ahs-toolkit"
)

$TargetDir = Join-Path $env:TEMP "AHS-Toolkit-Temp"

function Start-MainToolkit {
    param([string]$BaseDir)
    $MainScript = Join-Path $BaseDir "AHS-Toolkit.ps1"
    if (Test-Path $MainScript) {
        Write-Host "[OK] Iniciando AHS Toolkit..." -ForegroundColor Green
        powershell -ExecutionPolicy Bypass -File $MainScript
    } else {
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
    } elseif ($Source -eq "LAN") {
        Write-Error "Caminho de rede nao acessivel: $Path"
        exit
    }
}

if ($Source -eq "Auto" -or $Source -eq "GitHub") {
    Write-Host "[*] Iniciando download via GitHub Privado..." -ForegroundColor Cyan
    
    if (-not $Token) {
        $Token = Read-Host "Digite seu Personal Access Token (PAT) do GitHub"
    }

    if (-not (Test-Path $TargetDir)) { New-Item -Path $TargetDir -ItemType Directory -Force }

    $ZipPath = Join-Path $TargetDir "repo.zip"
    $Url = "https://api.github.com/repos/$Repo/zipball/main"
    
    $Headers = @{
        "Authorization" = "token $Token"
        "Accept"        = "application/vnd.github.v3.raw"
    }

    try {
        Write-Host "[+] Baixando arquivos..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $Url -Headers $Headers -OutFile $ZipPath -ErrorAction Stop
        
        Write-Host "[+] Extraindo..." -ForegroundColor Gray
        Expand-Archive -Path $ZipPath -DestinationPath $TargetDir -Force
        
        $ExtractedFolder = Get-ChildItem -Path $TargetDir -Directory | Select-Object -First 1
        
        Start-MainToolkit -BaseDir $ExtractedFolder.FullName
    }
    catch {
        Write-Error "Falha ao baixar do GitHub. Verifique o Token e permissoes. Erro: $($_.Exception.Message)"
    }
    finally {
        if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    }
}
