@echo off
setlocal enabledelayedexpansion
title AHS TOOLKIT - CORPORATE GRID v5.0

set "ATTEMPTS=0"
set "REQUIRED_HASH=D71D6DB3C58F9958F4AFF3128CC50BCF9DB893F28E685FFD42420DA80A2C929A"
set "V_UTIL=S:"
set "V_SRE=T:"

:LOGIN_GATE
set /a ATTEMPTS+=1
if %ATTEMPTS% gtr 3 (
    echo.
    echo [ERROR] Numero de tentativas excedido. Segurança ativada.
    timeout /t 3 >nul
    exit /b
)

cls
echo ==============================================================================
echo   AHS INDUSTRIA ^| CONTROL CENTER
echo ==============================================================================
echo   ACESSO RESTRITO: SRE / TI DEPARTAMENTO
echo ------------------------------------------------------------------------------
echo.
echo   Tentativa %ATTEMPTS% de 3.
set "INPUT_HASH=EMPTY"
for /f "delims=" %%a in ('powershell -NoProfile -Command "$p = Read-Host -Prompt '   Digite a senha de acesso' -AsSecureString; if ($p) { $m = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($p); $s = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($m); $b = [System.Text.Encoding]::UTF8.GetBytes($s); $h = [System.Security.Cryptography.SHA256]::Create().ComputeHash($b); [System.BitConverter]::ToString($h).Replace('-', '') } else { write-host 'EMPTY' }"') do set "INPUT_HASH=%%a"

if /i not "%INPUT_HASH%"=="%REQUIRED_HASH%" (
    echo.
    echo   [!] SENHA INCORRETA OU ACESSO CANCELADO.
    timeout /t 2 >nul
    goto LOGIN_GATE
)

echo.
echo   [OK] Autenticação confirmada. Carregando ambiente...
timeout /t 1 >nul

:: Preparar caminhos
icacls "%~dp0Utilitarios" /remove:d "Todos" /t /c /q >nul 2>&1
attrib -h -s "%~dp0Utilitarios" /d /s >nul 2>&1

set "U_PATH="
set "S_PATH="
for /d %%i in ("%~dp0Utilitarios*") do set "U_PATH=%%~fi"
for /d %%i in ("%~dp0SysAdmin_Toolkit*") do set "S_PATH=%%~fi"

subst %V_UTIL% /D >nul 2>&1
if defined U_PATH (
    subst %V_UTIL% "%U_PATH%"
)

subst %V_SRE% /D >nul 2>&1
if defined S_PATH (
    subst %V_SRE% "%S_PATH%"
)

:MENU
cls
echo ==============================================================================
echo   AHS INDUSTRIA ^| SYSADMIN CONSOLE V5.0
echo ==============================================================================
echo   HOST: %COMPUTERNAME%   ^|   STATUS: SRE [ACTIVE]   ^|   MNT: [READY]
echo ------------------------------------------------------------------------------
echo.
echo   [ ENGENHARIA SRE ^& AUDITORIA ]
echo   1. Dashboard SRE Pro (Core Python)
echo   2. Auditoria de Hardware (Quick PS Report)
echo.
echo   [ OTIMIZACAO ^& PERFORMANCE ]
echo   3. Otimizar Windows/SSD (Turbo)
echo   4. Otimizador Interativo (Personalizado)
echo   5. Limpeza Profunda (Caches/Temp)
echo.
echo   [ REDE ^& COMUNICACAO ]
echo   6. Fix Conectividade WhatsApp
echo   7. Gestao WhatsApp Web (Bloqueio)
echo.
echo   [ SUPORTE ^& MANUTENCAO ]
echo   8. Reset AnyDesk (Manual ID Reset)
echo   9. Fix Print Screen Classico
echo.
echo ------------------------------------------------------------------------------
echo   [P] Abrir Toolkit (PowerShell)  ^|  [Q] Sair e Desmontar
echo ==============================================================================
set /p opt="> Selecione uma opcao: "

if "%opt%"=="1" goto RUN_SRE_PRO
if "%opt%"=="2" goto RUN_HW_AUDIT
if "%opt%"=="3" goto RUN_SSD
if "%opt%"=="4" goto RUN_INTERACTIVE
if "%opt%"=="5" goto RUN_CLEAN
if "%opt%"=="6" goto RUN_WPP_FIX
if "%opt%"=="7" goto MENU_WPP
if "%opt%"=="8" goto RUN_ANYDESK
if "%opt%"=="9" goto RUN_PRINT_FIX
if /i "%opt%"=="p" start powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0AHS-Toolkit.ps1" & goto MENU
if /i "%opt%"=="q" goto EXIT_CLEAN

echo.
echo [!] Selecao invalida.
timeout /t 2 >nul
goto MENU

:RUN_SRE_PRO
cls
echo [SRE] Iniciando Core Python...
if exist "%V_SRE%\python_env\python.exe" (
    "%V_SRE%\python_env\python.exe" "%V_SRE%\sre_core.py"
) else (
    where python >nul 2>&1 && python "%V_SRE%\sre_core.py" || echo [!] Python não encontrado.
)
pause
goto MENU

:RUN_HW_AUDIT
echo [i] Gerando auditoria...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%V_UTIL%\Sistema\Auditoria_Hardware_V2.ps1"
pause
goto MENU

:RUN_SSD
echo [i] Otimizando SSD...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%V_UTIL%\Otimizadores\Otimizar_Windows_SSD.ps1"
pause
goto MENU

:RUN_INTERACTIVE
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%V_UTIL%\Otimizadores\OtimizadorInterativo.ps1"
pause
goto MENU

:RUN_CLEAN
call "%V_UTIL%\Otimizadores\LimpezaSilenciosa.BAT"
pause
goto MENU

:RUN_WPP_FIX
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%V_UTIL%\WhatsApp\Fix-WhatsApp-Network.ps1"
pause
goto MENU

:RUN_ANYDESK
call "%V_UTIL%\Sistema\reset_anydesk.bat"
pause
goto MENU

:RUN_PRINT_FIX
echo [i] Aplicando correção de Print...
reg import "%V_UTIL%\Sistema\ativar-print-classico.reg"
pause
goto MENU

:MENU_WPP
cls
echo ==============================================================================
echo   GESTÃO WHATSAPP WEB
echo ==============================================================================
echo   [1] Aplicar Bloqueio
echo   [2] Remover Bloqueio
echo   [B] Voltar ao Menu
echo.
set /p wpp="> "
if "%wpp%"=="1" call "%V_UTIL%\WhatsApp\Bloquear_Whatsapp\Bloquear_Whats_WEB.bat"
if "%wpp%"=="2" call "%V_UTIL%\WhatsApp\Bloquear_Whatsapp\Desbloquear_Whats_WEB.bat"
goto MENU

:EXIT_CLEAN
echo   [i] Desmontando unidades virtuais e encerrando...
subst %V_UTIL% /D >nul 2>&1
subst %V_SRE% /D >nul 2>&1
timeout /t 1 >nul
exit
