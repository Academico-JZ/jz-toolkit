# =================================================================
# SCRIPT DE AUDITORIA: HARDWARE + CONTA MICROSOFT (V4.4 - FINAL)
# =================================================================

# --- FUNÇÕES DE LIMPEZA ---
function Limpar-CPU ($RawCPU) {
    if (!$RawCPU) { return "---" }
    $Clean = $RawCPU -replace 'Intel|Core|AMD|Ryzen|Processor|CPU|\(R\)|\(TM\)|@.*|\d+th Gen', ''
    $Clean = $Clean -replace '\s+', ' '
    return $Clean.Trim()
}

function Limpar-SO ($RawSO) {
    if (!$RawSO) { return "---" }
    $Clean = $RawSO -replace 'Microsoft\s+', ''
    $Clean = $Clean -replace '\s+(Pro|Home|Enterprise|Education|LTSC).*', ''
    return $Clean.Trim()
}

# --- PARTE 1: Identidade e Emails ---
$UserName = $env:USERNAME
$FullName = "---"
$Email_Corp = "---"
$Email_MS = "---"
$TodosEmails = @()

# 1.1 - Coleta de Emails (Método Outlook V2.9 - Estável)
try {
    $OutlookBase = "HKCU:\Software\Microsoft\Office\16.0\Outlook"
    $DefProfile = (Get-ItemProperty $OutlookBase -ErrorAction SilentlyContinue).DefaultProfile
    if ($DefProfile) {
        $ProfilePath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\$DefProfile"
        if (Test-Path $ProfilePath) {
            $SubKeys = Get-ChildItem $ProfilePath -Recurse -ErrorAction SilentlyContinue
            foreach ($Key in $SubKeys) {
                $Props = Get-ItemProperty $Key.PSPath -ErrorAction SilentlyContinue
                @('Email', 'Account Name', 'POP3 User', 'SMTP Email Address') | ForEach-Object {
                    if ($Props.$_ -match '@') { $TodosEmails += $Props.$_.ToLower().Trim() }
                }
            }
        }
    }
}
catch {}

# Busca de Segurança para Emails (Microsoft Account)
try {
    Get-ChildItem "HKCU:\Software\Microsoft\OneDrive\Accounts", "HKCU:\Software\Microsoft\Office\16.0\Common\Identity\Identities" -ErrorAction SilentlyContinue | ForEach-Object {
        $P = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($P.EmailAddress) { $TodosEmails += $P.EmailAddress.ToLower().Trim() }
        if ($P.UserEmail) { $TodosEmails += $P.UserEmail.ToLower().Trim() }
    }
}
catch {}

$TodosEmails = $TodosEmails | Where-Object { $_ -match '@' } | Select-Object -Unique

# Atribuição de Emails
foreach ($Mail in $TodosEmails) {
    if ($Mail -like "*onmicrosoft.com*") { $Email_MS = $Mail }
}
if ($Email_MS -eq "---") {
    foreach ($Mail in $TodosEmails) { if ($Mail -ne $Email_Corp) { $Email_MS = $Mail; break } }
}

# 1.2 - IDENTIDADE REAL (Prioridade ONEDRIVE V4.1)
try {
    $OneDriveAcc = Get-ChildItem "HKCU:\Software\Microsoft\OneDrive\Accounts" -ErrorAction SilentlyContinue
    foreach ($Acc in $OneDriveAcc) {
        $P = Get-ItemProperty $Acc.PSPath -ErrorAction SilentlyContinue
        if ($P.UserName -and $P.UserName -match "\s+" -and $P.UserName -notmatch "Anne|Suporte|TECNICO") {
            if ($Email_MS -ne "---" -and $P.UserEmail -eq $Email_MS) {
                $FullName = $P.UserName
                break
            }
            if ($FullName -eq "---") { $FullName = $P.UserName }
        }
    }
}
catch {}

if ($FullName -eq "---") { $FullName = $env:USERNAME }

# --- PARTE 2: Lógica do SETOR ---
$SetorFinal = "---"
try {
    $CmdKeyOut = cmdkey /list | Out-String
    if ($CmdKeyOut -match "(?ms).*10\.0\.0\.1.*?(?:Usu.rio|User):\s*([^\s]+)") {
        $RawUser = $Matches[1].Trim()
        $SetorFinal = ($RawUser -split '\\')[-1].ToUpper()
    }
}
catch {}

# --- PARTE 4: Hardware ---
$BIOS = Get-CimInstance Win32_BIOS
$Sistema = Get-CimInstance Win32_ComputerSystem
$SO = Get-CimInstance Win32_OperatingSystem
$CPU = Get-CimInstance Win32_Processor
$Disco = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq 0 -or $_.MediaType -ne 'Unspecified' } | Select-Object -First 1

$Processador = Limpar-CPU $CPU.Name
$SO_Nome = Limpar-SO $SO.Caption

# --- PARTE 5: Montagem do Relatório ---
$Inventario = [PSCustomObject]@{
    'Marca'        = $Sistema.Manufacturer.Split(' ')[0]
    'Modelo'       = $Sistema.Model.Trim()
    'Tipo_Disco'   = $Disco.MediaType 
    'Espaco_GB'    = [math]::Round($Disco.Size / 1GB)
    'Memoria_GB'   = [math]::Round($Sistema.TotalPhysicalMemory / 1GB)
    'Processador'  = $Processador
    'SO'           = $SO_Nome
    'Usuario_Nome' = $FullName
    'Cidade'       = "Indeterminado"
    'Empresa'      = "JZ-Client"
    'Setor'        = $SetorFinal
    'Email_1'      = $Email_Corp
    'Email_2'      = $Email_MS
    'Serie'        = $BIOS.SerialNumber
}

# --- Exibir Resultado ---
Clear-Host
Write-Host "=== RELATORIO DE AUDITORIA (V4.4 - FINAL) ===" -ForegroundColor Cyan
$Inventario | Format-List
