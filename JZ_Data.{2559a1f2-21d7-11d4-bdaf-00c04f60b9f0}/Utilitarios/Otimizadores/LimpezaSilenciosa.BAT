@echo off
:: Limpeza automática de arquivos temporários

:: Apagar arquivos temporários do sistema
del /f /s /q "%SystemRoot%\Temp\*"
for /d %%x in ("%SystemRoot%\Temp\*") do rd /s /q "%%x"

:: Apagar arquivos temporários do usuário
del /f /s /q "%TEMP%\*"
for /d %%x in ("%TEMP%\*") do rd /s /q "%%x"

:: Apagar Prefetch
del /f /s /q "%SystemRoot%\Prefetch\*"

:: Opcional: Limpar Lixeira
PowerShell.exe -Command "Clear-RecycleBin -Force"

exit
