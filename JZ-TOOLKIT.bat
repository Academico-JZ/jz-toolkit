@echo off
title JZ-TOOLKIT - SYSADMIN DASHBOARD
:: ==============================================================================
:: JZ-TOOLKIT - LAUNCHER UNIFICADO E OTIMIZADO
:: ==============================================================================
:: Este é o único arquivo que deve ficar visível.
:: Coloque os scripts dentro da pasta: JZ_Data.{2559a1f2-21d7-11d4-bdaf-00c04f60b9f0}
:: ==============================================================================

set "GUID={2559a1f2-21d7-11d4-bdaf-00c04f60b9f0}"
set "DATA_FOLDER=JZ_Data.%GUID%"
set "SCRIPT_NAME=JZ-Toolkit.ps1"

:: Verificando se estamos na rede local (Exemplo de Servidor)
if exist "\\10.0.0.1\compartilhamento\TI\%DATA_FOLDER%\%SCRIPT_NAME%" (
    set "FINAL_PATH=\\10.0.0.1\compartilhamento\TI\%DATA_FOLDER%"
) else (
    set "FINAL_PATH=%~dp0%DATA_FOLDER%"
)

if not exist "%FINAL_PATH%\%SCRIPT_NAME%" (
    echo [!] ERRO: Pasta de dados camuflada nao encontrada.
    echo Certifique-se de que a pasta '%DATA_FOLDER%' existe.
    pause
    exit /b
)

:: Chama o PowerShell em modo bypass selecionando o script principal
powershell -ExecutionPolicy Bypass -File "%FINAL_PATH%\%SCRIPT_NAME%"
